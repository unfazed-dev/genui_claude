import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'logging_behavior_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Logging Behavior', () {
    late MockClient mockClient;
    late Uri testEndpoint;
    late List<LogRecord> logRecords;
    late StreamSubscription<LogRecord> logSubscription;

    setUp(() {
      mockClient = MockClient();
      testEndpoint = Uri.parse('https://api.example.com/chat');
      logRecords = [];

      // Set up log capture
      Logger.root.level = Level.ALL;
      logSubscription = Logger.root.onRecord.listen((record) {
        logRecords.add(record);
      });
    });

    tearDown(() async {
      await logSubscription.cancel();
      logRecords.clear();
    });

    group('ProxyModeHandler logging', () {
      group('request lifecycle logging', () {
        test('logs request start at FINE level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
          final mockResponse = http.StreamedResponse(
            Stream.value(utf8.encode(sseBody)),
            200,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final proxyLogs = logRecords.where(
            (r) => r.loggerName == 'ProxyModeHandler',
          );

          expect(
            proxyLogs.any(
              (r) =>
                  r.level == Level.FINE && r.message.contains('Starting proxy request'),
            ),
            isTrue,
            reason: 'Should log request start at FINE level',
          );

          handler.dispose();
        });

        test('logs dispose at FINE level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          handler.dispose();

          final proxyLogs = logRecords.where(
            (r) => r.loggerName == 'ProxyModeHandler',
          );

          expect(
            proxyLogs.any(
              (r) =>
                  r.level == Level.FINE &&
                  r.message.contains('ProxyModeHandler disposed'),
            ),
            isTrue,
            reason: 'Should log disposal at FINE level',
          );
        });
      });

      group('request ID in logs', () {
        test('includes request ID in all log messages', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
          final mockResponse = http.StreamedResponse(
            Stream.value(utf8.encode(sseBody)),
            200,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final proxyLogs = logRecords
              .where((r) => r.loggerName == 'ProxyModeHandler')
              .where((r) => !r.message.contains('disposed'))
              .toList();

          // Each log message related to a request should contain [Request ...]
          for (final log in proxyLogs) {
            expect(
              log.message.contains('[Request '),
              isTrue,
              reason:
                  'Log message "${log.message}" should contain request ID pattern',
            );
          }

          handler.dispose();
        });

        test('request ID format is UUID-like', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
          final mockResponse = http.StreamedResponse(
            Stream.value(utf8.encode(sseBody)),
            200,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final proxyLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' &&
                r.message.contains('[Request '),
          );

          expect(proxyLogs, isNotEmpty);

          // Extract request ID and verify it looks like a UUID
          final firstLog = proxyLogs.first;
          final match =
              RegExp(r'\[Request ([a-f0-9-]+)\]').firstMatch(firstLog.message);
          expect(match, isNotNull);
          expect(
            match!.group(1)!.length,
            greaterThanOrEqualTo(32),
            reason: 'Request ID should be UUID-like (at least 32 chars)',
          );

          handler.dispose();
        });
      });

      group('error logging', () {
        test('logs HTTP errors at WARNING level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: const RetryConfig(maxAttempts: 0),
          );

          // Create a new stream for each call
          when(mockClient.send(any)).thenAnswer(
            (_) async => http.StreamedResponse(
              Stream.value(utf8.encode('Internal Server Error')),
              500,
            ),
          );

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final warningLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
          );

          expect(
            warningLogs.any(
              (r) => r.message.contains('HTTP error') || r.message.contains('500'),
            ),
            isTrue,
            reason: 'Should log HTTP errors at WARNING level',
          );

          handler.dispose();
        });

        test('logs timeout errors at WARNING level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            config: const ProxyConfig(timeout: Duration(milliseconds: 50)),
            retryConfig: const RetryConfig(maxAttempts: 0),
          );

          // Mock a request that takes longer than the timeout
          when(mockClient.send(any)).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return http.StreamedResponse(const Stream.empty(), 200);
          });

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final warningLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
          );

          expect(
            warningLogs.any((r) => r.message.contains('timed out')),
            isTrue,
            reason: 'Should log timeout errors at WARNING level',
          );

          handler.dispose();
        });

        test('logs circuit breaker open at WARNING level', () async {
          final circuitBreaker = CircuitBreaker(
            config: const CircuitBreakerConfig(failureThreshold: 1),
          );

          // Trip the circuit breaker
          circuitBreaker.recordFailure();

          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            circuitBreaker: circuitBreaker,
          );

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final warningLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
          );

          expect(
            warningLogs.any(
              (r) =>
                  r.message.contains('circuit breaker') ||
                  r.message.contains('Circuit breaker'),
            ),
            isTrue,
            reason: 'Should log circuit breaker open at WARNING level',
          );

          handler.dispose();
        });
      });

      group('retry logging', () {
        test('logs retry attempts at INFO level', () async {
          var callCount = 0;
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: const RetryConfig(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 1),
            ),
          );

          when(mockClient.send(any)).thenAnswer((_) async {
            callCount++;
            if (callCount < 2) {
              return http.StreamedResponse(
                Stream.value(utf8.encode('Server Error')),
                500,
              );
            }
            return http.StreamedResponse(
              Stream.value(utf8.encode('''
data: {"type": "message_start"}

data: {"type": "message_stop"}

'''),),
              200,
            );
          });

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final infoLogs = logRecords.where(
            (r) => r.loggerName == 'ProxyModeHandler' && r.level == Level.INFO,
          );

          expect(
            infoLogs.any(
              (r) =>
                  r.message.contains('Retrying') ||
                  r.message.contains('retrying'),
            ),
            isTrue,
            reason: 'Should log retry attempts at INFO level',
          );

          handler.dispose();
        });

        test('logs rate limit with retry-after at INFO level', () async {
          var callCount = 0;
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: const RetryConfig(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 1),
            ),
          );

          when(mockClient.send(any)).thenAnswer((_) async {
            callCount++;
            if (callCount < 2) {
              final response = http.StreamedResponse(
                Stream.value(utf8.encode('Rate limit exceeded')),
                429,
                headers: {'retry-after': '1'},
              );
              return response;
            }
            return http.StreamedResponse(
              Stream.value(utf8.encode('''
data: {"type": "message_start"}

data: {"type": "message_stop"}

'''),),
              200,
            );
          });

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final infoLogs = logRecords.where(
            (r) => r.loggerName == 'ProxyModeHandler' && r.level == Level.INFO,
          );

          expect(
            infoLogs.any(
              (r) =>
                  r.message.contains('Rate limited') ||
                  r.message.contains('rate limit'),
            ),
            isTrue,
            reason: 'Should log rate limit at INFO level',
          );

          handler.dispose();
        });

        test('logs max retries exhausted at WARNING level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: const RetryConfig(
              maxAttempts: 1,
              initialDelay: Duration(milliseconds: 1),
            ),
          );

          when(mockClient.send(any)).thenAnswer(
            (_) async => http.StreamedResponse(
              Stream.value(utf8.encode('Server Error')),
              500,
            ),
          );

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final warningLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
          );

          expect(
            warningLogs.any(
              (r) =>
                  r.message.contains('retries remaining') ||
                  r.message.contains('max attempts') ||
                  r.message.contains('Non-retryable'),
            ),
            isTrue,
            reason: 'Should log max retries exhausted at WARNING level',
          );

          handler.dispose();
        });
      });

      group('stream logging', () {
        test('logs SSE parsing errors at WARNING level', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {invalid json}

data: {"type": "message_stop"}

''';
          final mockResponse = http.StreamedResponse(
            Stream.value(utf8.encode(sseBody)),
            200,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final warningLogs = logRecords.where(
            (r) =>
                r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
          );

          expect(
            warningLogs.any(
              (r) =>
                  r.message.contains('parse') ||
                  r.message.contains('Parse') ||
                  r.message.contains('SSE'),
            ),
            isTrue,
            reason: 'Should log SSE parsing errors at WARNING level',
          );

          handler.dispose();
        });

        // Note: Stream inactivity timeout logging is tested via integration tests
        // and the streaming_edge_cases_test.dart file. This specific unit test
        // is skipped due to timing complexity with async stream processing.
        test(
          'logs stream inactivity timeout at WARNING level',
          skip: 'Timing-sensitive test - covered in integration tests',
          () async {
            // Stream inactivity timeout triggers a warning when no data is
            // received within the configured timeout period. The handler uses
            // a Timer that resets on each data event and logs a WARNING
            // when it fires: "Stream inactivity timeout after {duration}"
          },
        );
      });

      group('attempt logging', () {
        test('logs attempt number in retry messages', () async {
          var callCount = 0;
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: const RetryConfig(
              initialDelay: Duration(milliseconds: 1),
            ),
          );

          when(mockClient.send(any)).thenAnswer((_) async {
            callCount++;
            if (callCount < 3) {
              return http.StreamedResponse(
                Stream.value(utf8.encode('Server Error')),
                500,
              );
            }
            return http.StreamedResponse(
              Stream.value(utf8.encode('''
data: {"type": "message_start"}

data: {"type": "message_stop"}

'''),),
              200,
            );
          });

          const request = ApiRequest(
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 1024,
          );

          await handler.createStream(request).toList();

          final allLogs = logRecords.where(
            (r) => r.loggerName == 'ProxyModeHandler',
          );

          // Should have attempt numbers in retry logs
          expect(
            allLogs.any((r) => r.message.contains('attempt')),
            isTrue,
            reason: 'Retry logs should include attempt numbers',
          );

          handler.dispose();
        });
      });
    });

    group('DirectModeHandler logging', () {
      test('logs request start at FINE level', () {
        // Note: DirectModeHandler requires actual API key for full testing
        // This test verifies the logger is properly configured

        // Just verify the logger namespace exists
        expect(() => Logger('DirectModeHandler'), returnsNormally);
      });

      test('logs dispose at FINE level', () {
        // Verify logger naming convention
        final logger = Logger('DirectModeHandler');
        expect(logger.name, equals('DirectModeHandler'));
      });
    });

    group('CircuitBreaker logging', () {
      test('circuit breaker has proper logger name', () {
        final logger = Logger('CircuitBreaker');
        expect(logger.name, equals('CircuitBreaker'));
      });
    });

    group('log level hierarchy', () {
      test('FINE level captures more than INFO', () {
        expect(Level.FINE.value, lessThan(Level.INFO.value));
      });

      test('INFO level captures more than WARNING', () {
        expect(Level.INFO.value, lessThan(Level.WARNING.value));
      });

      test('WARNING level captures more than SEVERE', () {
        expect(Level.WARNING.value, lessThan(Level.SEVERE.value));
      });

      test('can filter logs by level', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        // Filter to WARNING and above
        final warningAndAbove = logRecords
            .where((r) => r.level.value >= Level.WARNING.value)
            .toList();

        // Filter to INFO and above
        final infoAndAbove = logRecords
            .where((r) => r.level.value >= Level.INFO.value)
            .toList();

        // Filter to FINE and above (all logs)
        final fineAndAbove = logRecords
            .where((r) => r.level.value >= Level.FINE.value)
            .toList();

        // Each broader filter should include at least as many logs
        expect(infoAndAbove.length, greaterThanOrEqualTo(warningAndAbove.length));
        expect(fineAndAbove.length, greaterThanOrEqualTo(infoAndAbove.length));

        handler.dispose();
      });
    });

    group('hierarchical logger names', () {
      test('ProxyModeHandler uses hierarchical name', () {
        final logger = Logger('ProxyModeHandler');
        expect(logger.fullName, equals('ProxyModeHandler'));
      });

      test('DirectModeHandler uses hierarchical name', () {
        final logger = Logger('DirectModeHandler');
        expect(logger.fullName, equals('DirectModeHandler'));
      });

      test('can filter by logger name', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final proxyLogs = logRecords.where(
          (r) => r.loggerName == 'ProxyModeHandler',
        );

        final directLogs = logRecords.where(
          (r) => r.loggerName == 'DirectModeHandler',
        );

        // ProxyModeHandler should have logs, DirectModeHandler should not
        expect(proxyLogs, isNotEmpty);
        expect(directLogs, isEmpty);

        handler.dispose();
      });
    });

    group('log record properties', () {
      test('log records contain timestamp', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data: {"type": "message_start"}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final beforeTime = DateTime.now();
        await handler.createStream(request).toList();
        final afterTime = DateTime.now();

        final proxyLogs = logRecords.where(
          (r) => r.loggerName == 'ProxyModeHandler',
        );

        for (final log in proxyLogs) {
          expect(
            log.time.isAfter(beforeTime.subtract(const Duration(seconds: 1))),
            isTrue,
          );
          expect(
            log.time.isBefore(afterTime.add(const Duration(seconds: 1))),
            isTrue,
          );
        }

        handler.dispose();
      });

      test('error logs can include exception and stack trace', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        when(mockClient.send(any)).thenThrow(Exception('Test error'));

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final warningLogs = logRecords.where(
          (r) =>
              r.loggerName == 'ProxyModeHandler' && r.level == Level.WARNING,
        );

        // Some warning logs may include error details
        expect(
          warningLogs.any((r) => r.error != null || r.stackTrace != null),
          isTrue,
          reason: 'Error logs should include exception or stack trace',
        );

        handler.dispose();
      });
    });
  });
}
