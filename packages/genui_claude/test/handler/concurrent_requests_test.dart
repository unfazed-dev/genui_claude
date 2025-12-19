import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/genui_claude.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'concurrent_requests_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Concurrent Request Handling', () {
    late MockClient mockClient;
    late Uri testEndpoint;
    late MetricsCollector metricsCollector;

    setUp(() {
      mockClient = MockClient();
      testEndpoint = Uri.parse('https://api.example.com/chat');
      metricsCollector = MetricsCollector();
    });

    tearDown(() {
      metricsCollector.dispose();
    });

    group('multiple simultaneous streams', () {
      test('handles multiple concurrent createStream calls', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        var callCount = 0;
        when(mockClient.send(any)).thenAnswer((_) async {
          callCount++;
          final responseId = callCount;
          // Simulate varying response times
          await Future<void>.delayed(
            Duration(milliseconds: 50 * responseId),
          );
          return _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop", "id": $responseId}\n\n',
          );
        });

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Launch 5 concurrent requests
        final futures = List.generate(5, (_) {
          return handler.createStream(request).toList();
        });

        final results = await Future.wait(futures);

        // All requests should complete
        expect(results, hasLength(5));
        for (final events in results) {
          expect(events, hasLength(1));
          expect(events[0]['type'], equals('message_stop'));
        }

        // Verify all 5 requests were made
        verify(mockClient.send(any)).called(5);

        handler.dispose();
      });

      test('streams operate independently without interference', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        var requestIndex = 0;
        when(mockClient.send(any)).thenAnswer((_) async {
          requestIndex++;
          final idx = requestIndex;
          return _createMockStreamedResponse(
            statusCode: 200,
            body: '''
data: {"type": "message_start", "stream": $idx}

data: {"type": "content_block_delta", "stream": $idx, "delta": {"text": "Response $idx"}}

data: {"type": "message_stop", "stream": $idx}

''',
          );
        });

        const request1 = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Request 1'},
          ],
          maxTokens: 1024,
        );

        const request2 = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Request 2'},
          ],
          maxTokens: 2048,
        );

        // Start both streams
        final stream1Future = handler.createStream(request1).toList();
        final stream2Future = handler.createStream(request2).toList();

        final results = await Future.wait([stream1Future, stream2Future]);

        // Each stream should have its own events
        expect(results[0], hasLength(3));
        expect(results[1], hasLength(3));

        // Events should be from different streams
        expect(results[0][0]['stream'], isNot(equals(results[1][0]['stream'])));

        handler.dispose();
      });

      test('one failing stream does not affect others', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        var requestCount = 0;
        when(mockClient.send(any)).thenAnswer((_) async {
          requestCount++;
          if (requestCount == 2) {
            // Second request fails
            return _createMockStreamedResponse(
              statusCode: 500,
              body: 'Internal Server Error',
            );
          }
          return _createMockStreamedResponse(
            statusCode: 200,
            body:
                'data: {"type": "message_stop", "request": $requestCount}\n\n',
          );
        });

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Launch 3 concurrent requests
        final futures = List.generate(3, (_) {
          return handler.createStream(request).toList();
        });

        final results = await Future.wait(futures);

        // All should complete (some with errors, some with success)
        expect(results, hasLength(3));

        // Count successes and failures
        var successCount = 0;
        var errorCount = 0;
        for (final events in results) {
          if (events.isNotEmpty && events[0]['type'] == 'error') {
            errorCount++;
          } else {
            successCount++;
          }
        }

        expect(errorCount, equals(1));
        expect(successCount, equals(2));

        handler.dispose();
      });
    });

    group('circuit breaker under concurrent load', () {
      test('tracks failures correctly across concurrent requests', () async {
        final circuitBreaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 3,
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          circuitBreaker: circuitBreaker,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        // All requests fail
        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 500,
            body: 'Server Error',
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Launch 5 concurrent failing requests
        final futures = List.generate(5, (_) {
          return handler.createStream(request).toList();
        });

        await Future.wait(futures);

        // Circuit breaker should be open after threshold exceeded
        expect(circuitBreaker.state, equals(CircuitState.open));

        handler.dispose();
      });

      test('rejects requests immediately when circuit is open', () async {
        final circuitBreaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 2,
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          circuitBreaker: circuitBreaker,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        // First batch of requests fail to open the circuit
        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 500,
            body: 'Server Error',
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Trigger failures to open circuit
        await handler.createStream(request).toList();
        await handler.createStream(request).toList();
        await handler.createStream(request).toList();

        expect(circuitBreaker.state, equals(CircuitState.open));

        // Reset mock to track calls after circuit opens
        reset(mockClient);

        // Now launch concurrent requests - they should fail fast
        final futures = List.generate(5, (_) {
          return handler.createStream(request).toList();
        });

        final results = await Future.wait(futures);

        // All should return circuit breaker errors
        for (final events in results) {
          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['type'], equals('CircuitBreakerOpenException'));
        }

        // No actual HTTP calls should have been made
        verifyNever(mockClient.send(any));

        handler.dispose();
      });
    });

    group('metrics collection with concurrent requests', () {
      test('records all concurrent request events', () async {
        final events = <MetricsEvent>[];
        metricsCollector.eventStream.listen(events.add);

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Launch 3 concurrent requests
        final futures = List.generate(3, (_) {
          return handler.createStream(request).toList();
        });

        await Future.wait(futures);

        // Give events time to propagate
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should have start and success events for each request
        final startEvents = events.whereType<RequestStartEvent>().toList();
        final successEvents = events.whereType<RequestSuccessEvent>().toList();

        expect(startEvents, hasLength(3));
        expect(successEvents, hasLength(3));

        // Each request should have unique request ID
        final startIds = startEvents.map((e) => e.requestId).toSet();
        final successIds = successEvents.map((e) => e.requestId).toSet();

        expect(startIds, hasLength(3));
        expect(successIds, hasLength(3));

        handler.dispose();
      });

      test('metrics stats are accurate under concurrent load', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        var requestCount = 0;
        when(mockClient.send(any)).thenAnswer((_) async {
          requestCount++;
          // Every other request fails
          if (requestCount.isEven) {
            return _createMockStreamedResponse(
              statusCode: 500,
              body: 'Error',
            );
          }
          return _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
        });

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Launch 10 concurrent requests
        final futures = List.generate(10, (_) {
          return handler.createStream(request).toList();
        });

        await Future.wait(futures);

        // Give metrics time to aggregate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final stats = metricsCollector.stats;

        expect(stats.totalRequests, equals(10));
        expect(stats.successfulRequests, equals(5));
        expect(stats.failedRequests, equals(5));
        expect(stats.successRate, closeTo(50.0, 1.0));

        handler.dispose();
      });
    });

    group('dispose during active requests', () {
      test('dispose completes gracefully during active stream', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        // Create a slow response
        final completer = Completer<http.StreamedResponse>();
        when(mockClient.send(any)).thenAnswer((_) => completer.future);

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Start a request but don't await it
        final streamFuture = handler.createStream(request).toList();

        // Small delay to ensure request is in-flight
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Dispose should complete without throwing
        expect(handler.dispose, returnsNormally);

        // Complete the pending request to clean up
        completer.complete(
          _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        // Let the stream complete
        await streamFuture.catchError((_) => <Map<String, dynamic>>[]);
      });

      test('multiple active streams handle dispose correctly', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        // Create completers for controlling response timing
        final completers = List.generate(
          3,
          (_) => Completer<http.StreamedResponse>(),
        );
        var requestIndex = 0;
        when(mockClient.send(any)).thenAnswer((_) {
          final idx = requestIndex++;
          return completers[idx % completers.length].future;
        });

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Start multiple requests
        final streamFutures = List.generate(3, (_) {
          return handler.createStream(request).toList();
        });

        // Small delay to ensure requests are in-flight
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Dispose should complete without throwing
        expect(handler.dispose, returnsNormally);

        // Complete all pending requests
        for (final completer in completers) {
          if (!completer.isCompleted) {
            completer.complete(
              _createMockStreamedResponse(
                statusCode: 200,
                body: 'data: {"type": "message_stop"}\n\n',
              ),
            );
          }
        }

        // Let streams complete (with error handling)
        await Future.wait(
          streamFutures.map(
            (f) => f.catchError((_) => <Map<String, dynamic>>[]),
          ),
        );
      });
    });

    group('resource contention with shared HTTP client', () {
      test('handles concurrent requests with shared client', () async {
        // Single shared client for multiple handlers
        final sharedClient = mockClient;

        final handler1 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: sharedClient,
          retryConfig: RetryConfig.noRetry,
        );

        final handler2 = ProxyModeHandler(
          endpoint: Uri.parse('https://api2.example.com/chat'),
          client: sharedClient,
          retryConfig: RetryConfig.noRetry,
        );

        when(sharedClient.send(any)).thenAnswer((invocation) async {
          final request = invocation.positionalArguments[0] as http.BaseRequest;
          final host = request.url.host;
          return _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop", "host": "$host"}\n\n',
          );
        });

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Use both handlers concurrently
        final results = await Future.wait([
          handler1.createStream(request).toList(),
          handler2.createStream(request).toList(),
        ]);

        expect(results[0], hasLength(1));
        expect(results[1], hasLength(1));

        // Both handlers should work
        expect(results[0][0]['host'], equals('api.example.com'));
        expect(results[1][0]['host'], equals('api2.example.com'));

        // Don't dispose - handlers don't own the client
        handler1.dispose();
        handler2.dispose();

        // Verify client was NOT closed (since it was provided)
        verifyNever(sharedClient.close());
      });
    });
  });
}

/// Helper to create a mock StreamedResponse.
http.StreamedResponse _createMockStreamedResponse({
  required int statusCode,
  required String body,
}) {
  final controller = StreamController<List<int>>()
    ..add(utf8.encode(body))
    ..close();

  return http.StreamedResponse(
    controller.stream,
    statusCode,
  );
}
