import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'handler_performance_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late Uri testEndpoint;

  setUp(() {
    mockClient = MockClient();
    testEndpoint = Uri.parse('https://api.example.com/chat');
  });

  group('Handler Performance', () {
    group('ProxyModeHandler initialization', () {
      test('handler creation is fast', () {
        final stopwatch = Stopwatch()..start();
        const iterations = 1000;

        for (var i = 0; i < iterations; i++) {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );
          handler.dispose();
        }

        stopwatch.stop();

        // Handler creation should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        // Average: less than 1ms per handler
        expect(
          stopwatch.elapsedMicroseconds / iterations,
          lessThan(1000),
        );
      });

      test('handler with full config creation is fast', () {
        final stopwatch = Stopwatch()..start();
        const iterations = 500;

        for (var i = 0; i < iterations; i++) {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            authToken: 'test-token-$i',
            config: const ProxyConfig(
              timeout: Duration(seconds: 180),
              retryAttempts: 5,
              includeHistory: false,
              maxHistoryMessages: 50,
            ),
            retryConfig: const RetryConfig(
              maxAttempts: 5,
              initialDelay: Duration(milliseconds: 500),
            ),
            circuitBreaker: CircuitBreaker(name: 'test-$i'),
            metricsCollector: MetricsCollector(),
          );
          handler.dispose();
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('SSE stream parsing performance', () {
      test('parses high-volume SSE events efficiently', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Generate a large SSE response with many events
        final buffer = StringBuffer()
          ..write('data: {"type": "message_start"}\n\n');
        const eventCount = 1000;
        for (var i = 0; i < eventCount; i++) {
          buffer.write(
            'data: {"type": "content_block_delta", "index": $i, "delta": {"text": "chunk$i"}}\n\n',
          );
        }
        buffer.write('data: {"type": "message_stop"}\n\n');

        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(buffer.toString())),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final stopwatch = Stopwatch()..start();
        final events = await handler.createStream(request).toList();
        stopwatch.stop();

        // Should parse all events
        expect(events.length, equals(eventCount + 2)); // start + deltas + stop

        // Should be fast (less than 1 second for 1000 events)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        handler.dispose();
      });

      test('handles large content blocks efficiently', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Generate SSE with large content blocks
        final largeText = 'x' * 50000; // 50KB of text
        final buffer = StringBuffer()
          ..write('data: {"type": "message_start"}\n\n');
        for (var i = 0; i < 10; i++) {
          buffer.write(
            'data: {"type": "content_block_delta", "delta": {"text": "$largeText"}}\n\n',
          );
        }
        buffer.write('data: {"type": "message_stop"}\n\n');

        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(buffer.toString())),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final stopwatch = Stopwatch()..start();
        final events = await handler.createStream(request).toList();
        stopwatch.stop();

        expect(events.length, equals(12)); // start + 10 deltas + stop

        // Should handle large content in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        handler.dispose();
      });

      test('handles chunked SSE efficiently', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Create multiple small chunks simulating chunked transfer
        final chunks = <List<int>>[];
        chunks.add(utf8.encode('data: {"type": "message_start"}\n\n'));
        for (var i = 0; i < 100; i++) {
          chunks.add(
            utf8.encode(
              'data: {"type": "content_block_delta", "index": $i}\n\n',
            ),
          );
        }
        chunks.add(utf8.encode('data: {"type": "message_stop"}\n\n'));

        final mockResponse = http.StreamedResponse(
          Stream.fromIterable(chunks),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final stopwatch = Stopwatch()..start();
        final events = await handler.createStream(request).toList();
        stopwatch.stop();

        expect(events.length, equals(102));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        handler.dispose();
      });
    });

    group('request serialization performance', () {
      test('ApiRequest creation is fast', () {
        final stopwatch = Stopwatch()..start();
        const iterations = 10000;

        for (var i = 0; i < iterations; i++) {
          // ignore: unused_local_variable
          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
              {'role': 'assistant', 'content': 'Hi there!'},
              {'role': 'user', 'content': 'How are you?'},
            ],
            maxTokens: 4096,
            systemInstruction: 'You are a helpful assistant.',
          );
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('ApiRequest with tools creation is fast', () {
        final stopwatch = Stopwatch()..start();
        const iterations = 1000;

        final tools = [
          for (var i = 0; i < 10; i++)
            {
              'name': 'tool_$i',
              'description': 'Description for tool $i',
              'input_schema': {
                'type': 'object',
                'properties': {
                  'param1': {'type': 'string'},
                  'param2': {'type': 'number'},
                },
              },
            },
        ];

        for (var i = 0; i < iterations; i++) {
          // ignore: unused_local_variable
          final request = ApiRequest(
            messages: const [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 4096,
            tools: tools,
          );
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });

  group('Configuration Performance', () {
    group('copyWith operations', () {
      test('AnthropicConfig copyWith is fast', () {
        const config = AnthropicConfig.defaults;
        final stopwatch = Stopwatch()..start();
        const iterations = 100000;

        for (var i = 0; i < iterations; i++) {
          // Use i + 1 to ensure maxTokens is always > 0 (required by validation)
          // ignore: unused_local_variable
          final copy = config.copyWith(maxTokens: i + 1);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('ProxyConfig copyWith is fast', () {
        const config = ProxyConfig.defaults;
        final stopwatch = Stopwatch()..start();
        const iterations = 100000;

        for (var i = 0; i < iterations; i++) {
          // ignore: unused_local_variable
          final copy = config.copyWith(maxHistoryMessages: i);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('RetryConfig copyWith is fast', () {
        const config = RetryConfig.defaults;
        final stopwatch = Stopwatch()..start();
        const iterations = 100000;

        for (var i = 0; i < iterations; i++) {
          // ignore: unused_local_variable
          final copy = config.copyWith(maxAttempts: i % 10);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('CircuitBreakerConfig copyWith is fast', () {
        const config = CircuitBreakerConfig.defaults;
        final stopwatch = Stopwatch()..start();
        const iterations = 100000;

        for (var i = 0; i < iterations; i++) {
          // Use (i % 100) + 1 to ensure failureThreshold is always > 0 (required by validation)
          // ignore: unused_local_variable
          final copy = config.copyWith(failureThreshold: (i % 100) + 1);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('preset access', () {
      test('preset configurations are accessed instantly', () {
        final stopwatch = Stopwatch()..start();
        const iterations = 100000;

        for (var i = 0; i < iterations; i++) {
          // Access all presets - this just verifies they're constants
          // ignore: unused_local_variable
          const a = AnthropicConfig.defaults;
          // ignore: unused_local_variable
          const b = ProxyConfig.defaults;
          // ignore: unused_local_variable
          const c = RetryConfig.defaults;
          // ignore: unused_local_variable
          const d = RetryConfig.aggressive;
          // ignore: unused_local_variable
          const e = RetryConfig.noRetry;
          // ignore: unused_local_variable
          const f = CircuitBreakerConfig.defaults;
          // ignore: unused_local_variable
          const g = CircuitBreakerConfig.strict;
          // ignore: unused_local_variable
          const h = CircuitBreakerConfig.lenient;
        }

        stopwatch.stop();

        // Preset access should be instantaneous
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });

  group('Concurrent Operations Performance', () {
    test('handles concurrent stream creation', () async {
      // Create multiple handlers
      final handlers = List.generate(
        10,
        (i) => ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        ),
      );

      const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        ),
      );

      const request = ApiRequest(
        messages: [{'role': 'user', 'content': 'Hello'}],
        maxTokens: 1024,
      );

      final stopwatch = Stopwatch()..start();

      // Start all streams concurrently
      final futures = handlers.map((h) => h.createStream(request).toList());
      await Future.wait(futures);

      stopwatch.stop();

      // Concurrent streams should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      for (final handler in handlers) {
        handler.dispose();
      }
    });

    test('metrics collector handles concurrent events', () async {
      final collector = MetricsCollector();
      final stopwatch = Stopwatch()..start();

      // Simulate concurrent event recording
      await Future.wait([
        for (var i = 0; i < 100; i++)
          Future(() {
            collector.recordRequestStart(
              requestId: 'req-$i',
              endpoint: 'https://api.example.com',
            );
          }),
        for (var i = 0; i < 100; i++)
          Future(() {
            collector.recordRequestSuccess(
              requestId: 'req-$i',
              duration: Duration(milliseconds: 100 + i),
            );
          }),
      ]);

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      collector.dispose();
    });
  });
}
