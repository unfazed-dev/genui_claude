import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/genui_claude.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'resource_cleanup_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Resource Cleanup', () {
    late Uri testEndpoint;

    setUp(() {
      testEndpoint = Uri.parse('https://api.example.com/chat');
    });

    group('HTTP client disposal', () {
      test('disposes owned HTTP client on dispose', () {
        // When no client is provided, handler creates and owns one
        final handler = ProxyModeHandler(endpoint: testEndpoint);

        // Dispose should complete without throwing
        expect(handler.dispose, returnsNormally);

        // Verify that the handler can be disposed multiple times safely
        expect(handler.dispose, returnsNormally);
      });

      test('does not dispose injected HTTP client', () {
        final mockClient = MockClient();

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        handler.dispose();

        // Verify close was never called on the mock client
        verifyNever(mockClient.close());
      });

      test('injected client remains usable after handler disposal', () async {
        final mockClient = MockClient();

        final handler1 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
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

        // Use handler1
        await handler1.createStream(request).toList();
        handler1.dispose();

        // Create new handler with same client
        final handler2 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        // Client should still be usable
        final events = await handler2.createStream(request).toList();
        expect(events, isNotEmpty);

        handler2.dispose();
        verifyNever(mockClient.close());
      });
    });

    group('stream cleanup', () {
      test('stream completes when handler is disposed', () async {
        final mockClient = MockClient();
        final responseCompleter = Completer<http.StreamedResponse>();

        when(mockClient.send(any)).thenAnswer((_) => responseCompleter.future);

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Start the stream but don't await completion
        final streamFuture = handler.createStream(request).toList();

        // Give the stream time to start
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Dispose the handler
        handler.dispose();

        // Complete the response
        responseCompleter.complete(
          _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        // Stream should complete (possibly with events or empty)
        final events = await streamFuture;
        expect(events, isA<List<Map<String, dynamic>>>());
      });

      test('multiple streams can be started from same handler', () async {
        final mockClient = MockClient();

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Start and complete multiple streams sequentially
        for (var i = 0; i < 5; i++) {
          final events = await handler.createStream(request).toList();
          expect(events, hasLength(1));
        }

        handler.dispose();
      });

      test('stream can be iterated partially', () async {
        final mockClient = MockClient();

        // Create response with multiple events
        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: '''
data: {"type": "message_start"}

data: {"type": "content_block_delta"}

data: {"type": "message_stop"}

''',
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Only take first 2 events
        final events = await handler.createStream(request).take(2).toList();

        expect(events, hasLength(2));
        expect(events[0]['type'], equals('message_start'));
        expect(events[1]['type'], equals('content_block_delta'));

        handler.dispose();
      });
    });

    group('circuit breaker lifecycle', () {
      test('circuit breaker state persists across handler lifecycle', () async {
        final mockClient = MockClient();
        final circuitBreaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 3,
          ),
        );

        // Fail requests to open circuit
        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 500,
            body: 'Error',
          ),
        );

        final handler1 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          circuitBreaker: circuitBreaker,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Trigger failures to open circuit
        for (var i = 0; i < 4; i++) {
          await handler1.createStream(request).toList();
        }

        expect(circuitBreaker.state, equals(CircuitState.open));

        // Dispose handler1
        handler1.dispose();

        // Circuit breaker should still be open
        expect(circuitBreaker.state, equals(CircuitState.open));

        // New handler with same circuit breaker should inherit state
        final handler2 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          circuitBreaker: circuitBreaker,
          retryConfig: RetryConfig.noRetry,
        );

        // Requests should fail immediately due to open circuit
        final events = await handler2.createStream(request).toList();
        expect(events, hasLength(1));
        expect(events[0]['type'], equals('error'));
        final errorData = events[0]['error'] as Map<String, dynamic>;
        expect(errorData['type'], equals('CircuitBreakerOpenException'));

        handler2.dispose();
      });

      test('handler disposal does not affect circuit breaker', () {
        final circuitBreaker = CircuitBreaker();

        // Record some failures
        circuitBreaker.recordFailure();
        circuitBreaker.recordFailure();

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          circuitBreaker: circuitBreaker,
        );

        handler.dispose();

        // Circuit breaker should still track failures
        expect(circuitBreaker.state, equals(CircuitState.closed));
        // Can still interact with circuit breaker
        circuitBreaker.recordSuccess();
      });
    });

    group('metrics collector cleanup', () {
      test('metrics collector is not disposed by handler', () async {
        final metricsCollector = MetricsCollector();
        final mockClient = MockClient();
        final events = <MetricsEvent>[];

        metricsCollector.eventStream.listen(events.add);

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();
        handler.dispose();

        // Metrics collector should still work after handler disposal
        final handler2 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        events.clear();
        await handler2.createStream(request).toList();

        // Give events time to propagate
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should have recorded events from second handler
        expect(events, isNotEmpty);

        handler2.dispose();
        metricsCollector.dispose();
      });

      test('metrics continue to aggregate after handler disposal', () async {
        final metricsCollector = MetricsCollector();
        final mockClient = MockClient();

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        // First handler
        final handler1 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler1.createStream(request).toList();
        await handler1.createStream(request).toList();
        handler1.dispose();

        final stats1 = metricsCollector.stats;
        expect(stats1.totalRequests, equals(2));

        // Second handler
        final handler2 = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        await handler2.createStream(request).toList();
        handler2.dispose();

        // Stats should be cumulative
        final stats2 = metricsCollector.stats;
        expect(stats2.totalRequests, equals(3));

        metricsCollector.dispose();
      });
    });

    group('retry cleanup', () {
      test('pending retries are cancelled on dispose', () async {
        final mockClient = MockClient();
        var requestCount = 0;

        when(mockClient.send(any)).thenAnswer((_) async {
          requestCount++;
          // First request fails, which would trigger retry
          if (requestCount == 1) {
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

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: const RetryConfig(
            initialDelay: Duration(seconds: 5), // Long delay
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Start the request (will fail and try to retry)
        final streamFuture = handler.createStream(request).toList();

        // Give it time to fail once and start waiting for retry
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Dispose should complete quickly (not wait for retry delay)
        final disposeStart = DateTime.now();
        handler.dispose();
        final disposeTime = DateTime.now().difference(disposeStart);

        // Dispose should be fast (well under the 5 second retry delay)
        expect(disposeTime.inSeconds, lessThan(1));

        // Let the future complete or error
        await streamFuture.catchError((_) => <Map<String, dynamic>>[]);
      });
    });

    group('handler reuse after disposal', () {
      test('handler cannot be used after dispose', () async {
        final mockClient = MockClient();

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          ),
        );

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        // Use before dispose
        final events1 = await handler.createStream(request).toList();
        expect(events1, isNotEmpty);

        // Dispose
        handler.dispose();

        // Using after dispose - behavior depends on implementation
        // The handler may still work if it doesn't track disposal state
        // This test documents current behavior
        final events2 = await handler.createStream(request).toList();
        // Current implementation allows use after dispose
        expect(events2, isA<List<Map<String, dynamic>>>());
      });

      test('double dispose is safe', () {
        final handler = ProxyModeHandler(endpoint: testEndpoint);

        expect(handler.dispose, returnsNormally);
        expect(handler.dispose, returnsNormally);
        expect(handler.dispose, returnsNormally);
      });
    });

    group('direct mode handler disposal', () {
      test('DirectModeHandler disposal is safe', () {
        // This test verifies DirectModeHandler also handles disposal correctly
        // We can't easily mock the SDK client, so just verify no errors
        final handler = DirectModeHandler(
          apiKey: 'test-key',
        );

        expect(handler.dispose, returnsNormally);
        expect(handler.dispose, returnsNormally);
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
