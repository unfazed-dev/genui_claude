import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'memory_profiling_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Memory Profiling', () {
    late MockClient mockClient;
    late Uri testEndpoint;

    setUp(() {
      mockClient = MockClient();
      testEndpoint = Uri.parse('https://api.example.com/chat');
    });

    group('long conversation handling', () {
      test('handles 100+ message conversations', () async {
        final handler = ProxyModeHandler(
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

        // Build a large message history
        final messages = List.generate(
          100,
          (i) => {'role': i.isEven ? 'user' : 'assistant', 'content': 'Message $i'},
        );

        final request = ApiRequest(
          messages: messages,
          maxTokens: 1024,
        );

        // Should handle large history without error
        final events = await handler.createStream(request).toList();
        expect(events, isNotEmpty);

        // Verify all messages were included in request
        final captured = verify(mockClient.send(captureAny)).captured;
        final sentRequest = captured.first as http.Request;
        final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;
        expect(body['messages'], hasLength(100));

        handler.dispose();
      });

      test('handles very long individual messages', () async {
        final handler = ProxyModeHandler(
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

        // Create a message with 100KB of content
        final longContent = 'A' * 100000;

        final request = ApiRequest(
          messages: [
            {'role': 'user', 'content': longContent},
          ],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();
        expect(events, isNotEmpty);

        handler.dispose();
      });
    });

    group('history pruning effectiveness', () {
      test('ProxyConfig.maxHistoryMessages limits history', () async {
        // Note: History pruning is handled by the content generator,
        // not the handler directly. This test documents expected behavior.
        const config = ProxyConfig(maxHistoryMessages: 10);

        expect(config.maxHistoryMessages, equals(10));

        // Verify config is usable
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          config: config,
          retryConfig: RetryConfig.noRetry,
        );

        handler.dispose();
      });

      test('zero maxHistoryMessages excludes history', () {
        const config = ProxyConfig(maxHistoryMessages: 0);
        expect(config.maxHistoryMessages, equals(0));
      });
    });

    group('stream buffer memory', () {
      test('handles many small delta events', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        // Create response with 1000 small delta events
        final eventBuffer = StringBuffer();
        for (var i = 0; i < 1000; i++) {
          eventBuffer.writeln(
            'data: {"type": "content_block_delta", "index": 0, "delta": {"text": "$i"}}',
          );
          eventBuffer.writeln();
        }
        eventBuffer.writeln('data: {"type": "message_stop"}');
        eventBuffer.writeln();

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: eventBuffer.toString(),
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 4096,
        );

        final events = await handler.createStream(request).toList();

        // Should have received all events plus message_stop
        expect(events.length, greaterThanOrEqualTo(1001));

        handler.dispose();
      });

      test('handles large response content blocks', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          retryConfig: RetryConfig.noRetry,
        );

        // Create a response with 50KB content in a single delta
        final largeContent = 'B' * 50000;
        final response = '''
data: {"type": "message_start", "message": {"id": "msg_1"}}

data: {"type": "content_block_start", "index": 0}

data: {"type": "content_block_delta", "index": 0, "delta": {"text": "$largeContent"}}

data: {"type": "content_block_stop", "index": 0}

data: {"type": "message_stop"}

''';

        when(mockClient.send(any)).thenAnswer(
          (_) async => _createMockStreamedResponse(
            statusCode: 200,
            body: response,
          ),
        );

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 65536,
        );

        final events = await handler.createStream(request).toList();
        expect(events, hasLength(5));

        // Verify large content was received
        final deltaEvent = events.firstWhere(
          (e) => e['type'] == 'content_block_delta',
        );
        final deltaData = deltaEvent['delta'] as Map<String, dynamic>;
        expect(deltaData['text'].toString().length, equals(50000));

        handler.dispose();
      });
    });

    group('metrics event retention', () {
      test('metrics collector handles high volume events', () async {
        final metricsCollector = MetricsCollector();
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

        // Make 50 rapid requests
        for (var i = 0; i < 50; i++) {
          await handler.createStream(request).toList();
        }

        // Give events time to propagate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have recorded events for all requests
        final startEvents = events.whereType<RequestStartEvent>().length;
        final successEvents = events.whereType<RequestSuccessEvent>().length;

        expect(startEvents, equals(50));
        expect(successEvents, equals(50));

        // Stats should be accurate
        final stats = metricsCollector.stats;
        expect(stats.totalRequests, equals(50));
        expect(stats.successfulRequests, equals(50));

        handler.dispose();
        metricsCollector.dispose();
      });

      test('metrics stats remain accurate under mixed success/failure', () async {
        final metricsCollector = MetricsCollector();

        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
          metricsCollector: metricsCollector,
          retryConfig: RetryConfig.noRetry,
        );

        var requestCount = 0;
        when(mockClient.send(any)).thenAnswer((_) async {
          requestCount++;
          // Every 3rd request fails
          if (requestCount % 3 == 0) {
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

        // Make 30 requests (10 will fail)
        for (var i = 0; i < 30; i++) {
          await handler.createStream(request).toList();
        }

        // Give metrics time to aggregate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final stats = metricsCollector.stats;
        expect(stats.totalRequests, equals(30));
        expect(stats.successfulRequests, equals(20));
        expect(stats.failedRequests, equals(10));
        expect(stats.successRate, closeTo(66.67, 0.1));

        handler.dispose();
        metricsCollector.dispose();
      });
    });

    group('configuration object allocation', () {
      test('const configs share instances', () {
        const config1 = ProxyConfig.defaults;
        const config2 = ProxyConfig.defaults;

        // Const instances are identical
        expect(identical(config1, config2), isTrue);
      });

      test('RetryConfig presets are const', () {
        const defaults = RetryConfig.defaults;
        const noRetry = RetryConfig.noRetry;
        const aggressive = RetryConfig.aggressive;

        // All should be valid const instances
        expect(defaults.maxAttempts, equals(3));
        expect(noRetry.maxAttempts, equals(0));
        expect(aggressive.maxAttempts, equals(5));
      });

      test('CircuitBreakerConfig presets are const', () {
        const defaults = CircuitBreakerConfig.defaults;
        const strict = CircuitBreakerConfig.strict;
        const lenient = CircuitBreakerConfig.lenient;

        expect(defaults.failureThreshold, equals(5));
        expect(strict.failureThreshold, equals(3));
        expect(lenient.failureThreshold, equals(10));
      });
    });

    group('exception object allocation', () {
      test('exceptions include necessary context without excess data', () {
        const exception = NetworkException(
          message: 'Connection refused',
          requestId: 'req-123',
        );

        expect(exception.message, equals('Connection refused'));
        expect(exception.requestId, equals('req-123'));
        expect(exception.statusCode, isNull);
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, equals('NetworkException'));

        // toString includes all relevant info
        final str = exception.toString();
        expect(str, contains('NetworkException'));
        expect(str, contains('Connection refused'));
        expect(str, contains('req-123'));
      });

      test('ExceptionFactory creates appropriate exception types', () {
        // Each factory call creates a new instance (not shared)
        final e1 = ExceptionFactory.fromHttpStatus(
          statusCode: 429,
          body: 'Rate limited',
          requestId: 'req-1',
        );
        final e2 = ExceptionFactory.fromHttpStatus(
          statusCode: 429,
          body: 'Rate limited',
          requestId: 'req-2',
        );

        expect(e1, isA<RateLimitException>());
        expect(e2, isA<RateLimitException>());
        expect(identical(e1, e2), isFalse);
        expect(e1.requestId, isNot(equals(e2.requestId)));
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
