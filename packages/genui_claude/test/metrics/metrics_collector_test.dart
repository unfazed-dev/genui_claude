import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:genui_claude/src/metrics/metrics_event.dart';
import 'package:genui_claude/src/resilience/circuit_breaker.dart';

void main() {
  group('MetricsCollector', () {
    late MetricsCollector collector;

    setUp(() {
      collector = MetricsCollector();
    });

    tearDown(() {
      collector.dispose();
    });

    group('constructor', () {
      test('creates collector with default enabled state', () {
        final c = MetricsCollector();
        expect(c.enabled, isTrue);
        expect(c.aggregationEnabled, isTrue);
        c.dispose();
      });

      test('creates collector with disabled state', () {
        final c = MetricsCollector(enabled: false);
        expect(c.enabled, isFalse);
        c.dispose();
      });

      test('creates collector with disabled aggregation', () {
        final c = MetricsCollector(aggregationEnabled: false);
        expect(c.aggregationEnabled, isFalse);
        c.dispose();
      });
    });

    group('event streaming', () {
      test('emits events on eventStream', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRequestStart(
          requestId: 'test-1',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        expect(events.first, isA<RequestStartEvent>());
      });

      test('stream is broadcast', () async {
        final events1 = <MetricsEvent>[];
        final events2 = <MetricsEvent>[];

        collector.eventStream.listen(events1.add);
        collector.eventStream.listen(events2.add);

        collector.recordRequestStart(
          requestId: 'test-1',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events1.length, equals(1));
        expect(events2.length, equals(1));
      });

      test('does not emit events when disabled', () async {
        final c = MetricsCollector(enabled: false);
        final events = <MetricsEvent>[];
        c.eventStream.listen(events.add);

        c.recordRequestStart(
          requestId: 'test-1',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
        c.dispose();
      });
    });

    group('recordCircuitBreakerStateChange', () {
      test('emits CircuitBreakerStateChangeEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordCircuitBreakerStateChange(
          circuitName: 'test-circuit',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
          failureCount: 5,
          requestId: 'req-123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as CircuitBreakerStateChangeEvent;
        expect(event.circuitName, equals('test-circuit'));
        expect(event.previousState, equals(CircuitState.closed));
        expect(event.newState, equals(CircuitState.open));
        expect(event.failureCount, equals(5));
        expect(event.requestId, equals('req-123'));
      });

      test('updates stats for circuit breaker events', () {
        collector.recordCircuitBreakerStateChange(
          circuitName: 'test',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
        );

        expect(collector.stats.circuitBreakerEvents, equals(1));
        expect(collector.stats.circuitBreakerOpens, equals(1));
      });

      test('does not increment opens for non-open transitions', () {
        collector.recordCircuitBreakerStateChange(
          circuitName: 'test',
          previousState: CircuitState.open,
          newState: CircuitState.halfOpen,
        );

        expect(collector.stats.circuitBreakerEvents, equals(1));
        expect(collector.stats.circuitBreakerOpens, equals(0));
      });
    });

    group('recordRetryAttempt', () {
      test('emits RetryAttemptEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRetryAttempt(
          attempt: 1,
          maxAttempts: 3,
          delay: const Duration(seconds: 2),
          reason: 'Server error',
          statusCode: 500,
          requestId: 'req-123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as RetryAttemptEvent;
        expect(event.attempt, equals(1));
        expect(event.maxAttempts, equals(3));
        expect(event.delayMs, equals(2000));
        expect(event.reason, equals('Server error'));
        expect(event.statusCode, equals(500));
      });

      test('updates stats for retries', () {
        collector.recordRetryAttempt(
          attempt: 1,
          maxAttempts: 3,
          delay: const Duration(seconds: 1),
          reason: 'test',
        );

        expect(collector.stats.totalRetries, equals(1));
      });
    });

    group('recordRequestStart', () {
      test('emits RequestStartEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRequestStart(
          requestId: 'req-123',
          endpoint: 'https://api.example.com/chat',
          model: 'claude-3-opus',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as RequestStartEvent;
        expect(event.requestId, equals('req-123'));
        expect(event.endpoint, equals('https://api.example.com/chat'));
        expect(event.model, equals('claude-3-opus'));
      });

      test('updates stats for request start', () {
        collector.recordRequestStart(
          requestId: 'req-1',
          endpoint: 'test',
        );

        expect(collector.stats.totalRequests, equals(1));
        expect(collector.stats.activeRequests, equals(1));
      });

      test('tracks multiple active requests', () {
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        collector.recordRequestStart(requestId: 'req-2', endpoint: 'test');
        collector.recordRequestStart(requestId: 'req-3', endpoint: 'test');

        expect(collector.stats.totalRequests, equals(3));
        expect(collector.stats.activeRequests, equals(3));
      });
    });

    group('recordRequestSuccess', () {
      test('emits RequestSuccessEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRequestSuccess(
          requestId: 'req-123',
          duration: const Duration(milliseconds: 1500),
          totalRetries: 1,
          firstTokenLatency: const Duration(milliseconds: 200),
          tokensReceived: 150,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as RequestSuccessEvent;
        expect(event.requestId, equals('req-123'));
        expect(event.durationMs, equals(1500));
        expect(event.totalRetries, equals(1));
        expect(event.firstTokenMs, equals(200));
        expect(event.tokensReceived, equals(150));
      });

      test('updates stats for successful requests', () {
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        collector.recordRequestSuccess(
          requestId: 'req-1',
          duration: const Duration(milliseconds: 100),
        );

        expect(collector.stats.successfulRequests, equals(1));
        expect(collector.stats.activeRequests, equals(0));
      });

      test('records latency for success', () {
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        collector.recordRequestSuccess(
          requestId: 'req-1',
          duration: const Duration(milliseconds: 100),
        );

        expect(collector.stats.averageLatencyMs, equals(100.0));
      });
    });

    group('recordRequestFailure', () {
      test('emits RequestFailureEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRequestFailure(
          requestId: 'req-123',
          duration: const Duration(milliseconds: 500),
          errorType: 'ServerException',
          errorMessage: 'Internal server error',
          statusCode: 500,
          totalRetries: 3,
          isRetryable: true,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as RequestFailureEvent;
        expect(event.requestId, equals('req-123'));
        expect(event.durationMs, equals(500));
        expect(event.errorType, equals('ServerException'));
        expect(event.errorMessage, equals('Internal server error'));
        expect(event.statusCode, equals(500));
        expect(event.isRetryable, isTrue);
      });

      test('updates stats for failed requests', () {
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        collector.recordRequestFailure(
          requestId: 'req-1',
          duration: const Duration(milliseconds: 100),
          errorType: 'Error',
          errorMessage: 'test',
        );

        expect(collector.stats.failedRequests, equals(1));
        expect(collector.stats.activeRequests, equals(0));
      });
    });

    group('recordRateLimit', () {
      test('emits RateLimitEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordRateLimit(
          retryAfter: const Duration(seconds: 30),
          retryAfterHeader: '30',
          requestId: 'req-123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as RateLimitEvent;
        expect(event.retryAfterMs, equals(30000));
        expect(event.retryAfterHeader, equals('30'));
        expect(event.requestId, equals('req-123'));
      });

      test('updates stats for rate limit events', () {
        collector.recordRateLimit();

        expect(collector.stats.rateLimitEvents, equals(1));
      });
    });

    group('recordLatency', () {
      test('emits LatencyEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordLatency(
          operation: 'database_query',
          duration: const Duration(milliseconds: 50),
          metadata: {'table': 'users'},
          requestId: 'req-123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as LatencyEvent;
        expect(event.operation, equals('database_query'));
        expect(event.durationMs, equals(50));
        expect(event.metadata, equals({'table': 'users'}));
      });
    });

    group('recordStreamInactivity', () {
      test('emits StreamInactivityEvent', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.recordStreamInactivity(
          timeout: const Duration(seconds: 60),
          lastActivity: const Duration(seconds: 75),
          requestId: 'req-123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        final event = events.first as StreamInactivityEvent;
        expect(event.timeoutMs, equals(60000));
        expect(event.lastActivityMs, equals(75000));
      });

      test('updates stats for stream inactivity', () {
        collector.recordStreamInactivity(
          timeout: const Duration(seconds: 60),
          lastActivity: const Duration(seconds: 75),
        );

        expect(collector.stats.streamInactivityEvents, equals(1));
      });
    });

    group('stats', () {
      group('successRate', () {
        test('returns 100 when no requests completed', () {
          expect(collector.stats.successRate, equals(100.0));
        });

        test('returns correct rate with mixed results', () {
          // 2 successes, 1 failure = 66.67% success rate
          collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-1',
            duration: const Duration(milliseconds: 100),
          );

          collector.recordRequestStart(requestId: 'req-2', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-2',
            duration: const Duration(milliseconds: 100),
          );

          collector.recordRequestStart(requestId: 'req-3', endpoint: 'test');
          collector.recordRequestFailure(
            requestId: 'req-3',
            duration: const Duration(milliseconds: 100),
            errorType: 'Error',
            errorMessage: 'test',
          );

          expect(
            collector.stats.successRate,
            closeTo(66.67, 0.01),
          );
        });

        test('returns 100 when all requests succeed', () {
          collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-1',
            duration: const Duration(milliseconds: 100),
          );

          expect(collector.stats.successRate, equals(100.0));
        });

        test('returns 0 when all requests fail', () {
          collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
          collector.recordRequestFailure(
            requestId: 'req-1',
            duration: const Duration(milliseconds: 100),
            errorType: 'Error',
            errorMessage: 'test',
          );

          expect(collector.stats.successRate, equals(0.0));
        });
      });

      group('averageLatencyMs', () {
        test('returns 0 when no latencies recorded', () {
          expect(collector.stats.averageLatencyMs, equals(0.0));
        });

        test('returns correct average', () {
          collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-1',
            duration: const Duration(milliseconds: 100),
          );

          collector.recordRequestStart(requestId: 'req-2', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-2',
            duration: const Duration(milliseconds: 200),
          );

          collector.recordRequestStart(requestId: 'req-3', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-3',
            duration: const Duration(milliseconds: 300),
          );

          // (100 + 200 + 300) / 3 = 200
          expect(collector.stats.averageLatencyMs, equals(200.0));
        });
      });

      group('percentile latencies', () {
        test('returns 0 when no latencies recorded', () {
          expect(collector.stats.p50LatencyMs, equals(0));
          expect(collector.stats.p95LatencyMs, equals(0));
          expect(collector.stats.p99LatencyMs, equals(0));
        });

        test('calculates percentiles correctly', () {
          // Add 10 latencies: 100, 200, 300, ..., 1000
          for (var i = 1; i <= 10; i++) {
            final requestId = 'req-$i';
            collector.recordRequestStart(
                requestId: requestId, endpoint: 'test',);
            collector.recordRequestSuccess(
              requestId: requestId,
              duration: Duration(milliseconds: i * 100),
            );
          }

          // p50 should be around the middle values (400-600ms range)
          expect(collector.stats.p50LatencyMs, inInclusiveRange(400, 600));
          // p95 should be around the higher values
          expect(collector.stats.p95LatencyMs, greaterThanOrEqualTo(800));
          // p99 should be near the highest value
          expect(collector.stats.p99LatencyMs, greaterThanOrEqualTo(900));
        });
      });

      group('toMap', () {
        test('returns all stats as map', () {
          collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
          collector.recordRequestSuccess(
            requestId: 'req-1',
            duration: const Duration(milliseconds: 100),
          );

          final map = collector.stats.toMap();

          expect(map['total_requests'], equals(1));
          expect(map['active_requests'], equals(0));
          expect(map['successful_requests'], equals(1));
          expect(map['failed_requests'], equals(0));
          expect(map['success_rate'], equals(100.0));
          expect(map['average_latency_ms'], equals(100.0));
          expect(map.containsKey('p50_latency_ms'), isTrue);
          expect(map.containsKey('p95_latency_ms'), isTrue);
          expect(map.containsKey('p99_latency_ms'), isTrue);
        });
      });
    });

    group('resetStats', () {
      test('resets all stats to initial values', () {
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        collector.recordRequestSuccess(
          requestId: 'req-1',
          duration: const Duration(milliseconds: 100),
        );
        collector.recordRetryAttempt(
          attempt: 1,
          maxAttempts: 3,
          delay: const Duration(seconds: 1),
          reason: 'test',
        );
        collector.recordRateLimit();
        collector.recordCircuitBreakerStateChange(
          circuitName: 'test',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
        );
        collector.recordStreamInactivity(
          timeout: const Duration(seconds: 60),
          lastActivity: const Duration(seconds: 75),
        );

        expect(collector.stats.totalRequests, greaterThan(0));

        collector.resetStats();

        expect(collector.stats.totalRequests, equals(0));
        expect(collector.stats.activeRequests, equals(0));
        expect(collector.stats.successfulRequests, equals(0));
        expect(collector.stats.failedRequests, equals(0));
        expect(collector.stats.totalRetries, equals(0));
        expect(collector.stats.rateLimitEvents, equals(0));
        expect(collector.stats.circuitBreakerEvents, equals(0));
        expect(collector.stats.circuitBreakerOpens, equals(0));
        expect(collector.stats.streamInactivityEvents, equals(0));
        expect(collector.stats.averageLatencyMs, equals(0.0));
      });
    });

    group('aggregation disabled', () {
      test('does not update stats when aggregation disabled', () {
        final c = MetricsCollector(aggregationEnabled: false);

        c.recordRequestStart(requestId: 'req-1', endpoint: 'test');
        c.recordRequestSuccess(
          requestId: 'req-1',
          duration: const Duration(milliseconds: 100),
        );

        expect(c.stats.totalRequests, equals(0));
        expect(c.stats.successfulRequests, equals(0));

        c.dispose();
      });

      test('still emits events when aggregation disabled', () async {
        final c = MetricsCollector(aggregationEnabled: false);
        final events = <MetricsEvent>[];
        c.eventStream.listen(events.add);

        c.recordRequestStart(requestId: 'req-1', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(1));
        c.dispose();
      });
    });

    group('dispose', () {
      test('closes event stream', () async {
        var streamClosed = false;
        collector.eventStream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        collector.dispose();

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(streamClosed, isTrue);
      });

      test('does not emit events after dispose', () async {
        final events = <MetricsEvent>[];
        collector.eventStream.listen(events.add);

        collector.dispose();

        // Try to record after dispose
        collector.recordRequestStart(requestId: 'req-1', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(events, isEmpty);
      });
    });

    group('globalMetricsCollector', () {
      test('returns default collector', () {
        expect(globalMetricsCollector, isNotNull);
        expect(globalMetricsCollector.enabled, isTrue);
      });

      test('returns test collector when set', () {
        final testCollector = MetricsCollector(enabled: false);
        testMetricsCollector = testCollector;

        expect(globalMetricsCollector, equals(testCollector));
        expect(globalMetricsCollector.enabled, isFalse);

        testMetricsCollector = null;
        testCollector.dispose();
      });
    });
  });

  group('MetricsEvent subclasses', () {
    group('CircuitBreakerStateChangeEvent', () {
      test('has correct eventType', () {
        final event = CircuitBreakerStateChangeEvent(
          timestamp: DateTime.now(),
          circuitName: 'test',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
        );

        expect(event.eventType, equals('circuit_breaker_state_change'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = CircuitBreakerStateChangeEvent(
          timestamp: timestamp,
          circuitName: 'test-circuit',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
          failureCount: 5,
          requestId: 'req-123',
        );

        final map = event.toMap();

        expect(map['event_type'], equals('circuit_breaker_state_change'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['circuit_name'], equals('test-circuit'));
        expect(map['previous_state'], equals('closed'));
        expect(map['new_state'], equals('open'));
        expect(map['failure_count'], equals(5));
        expect(map['request_id'], equals('req-123'));
      });

      test('toMap excludes null fields', () {
        final event = CircuitBreakerStateChangeEvent(
          timestamp: DateTime.now(),
          circuitName: 'test',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
        );

        final map = event.toMap();

        expect(map.containsKey('failure_count'), isFalse);
        expect(map.containsKey('request_id'), isFalse);
      });
    });

    group('RetryAttemptEvent', () {
      test('has correct eventType', () {
        final event = RetryAttemptEvent(
          timestamp: DateTime.now(),
          attempt: 1,
          maxAttempts: 3,
          delayMs: 1000,
          reason: 'test',
        );

        expect(event.eventType, equals('retry_attempt'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = RetryAttemptEvent(
          timestamp: timestamp,
          attempt: 2,
          maxAttempts: 5,
          delayMs: 2000,
          reason: 'Server error',
          statusCode: 500,
          requestId: 'req-123',
        );

        final map = event.toMap();

        expect(map['event_type'], equals('retry_attempt'));
        expect(map['attempt'], equals(2));
        expect(map['max_attempts'], equals(5));
        expect(map['delay_ms'], equals(2000));
        expect(map['reason'], equals('Server error'));
        expect(map['status_code'], equals(500));
      });
    });

    group('RequestStartEvent', () {
      test('has correct eventType', () {
        final event = RequestStartEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          endpoint: 'test',
        );

        expect(event.eventType, equals('request_start'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = RequestStartEvent(
          timestamp: timestamp,
          requestId: 'req-123',
          endpoint: 'https://api.example.com/chat',
          model: 'claude-3-opus',
        );

        final map = event.toMap();

        expect(map['event_type'], equals('request_start'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['request_id'], equals('req-123'));
        expect(map['endpoint'], equals('https://api.example.com/chat'));
        expect(map['model'], equals('claude-3-opus'));
      });

      test('toMap excludes null model', () {
        final event = RequestStartEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          endpoint: 'test',
        );

        final map = event.toMap();

        expect(map.containsKey('model'), isFalse);
      });
    });

    group('RequestSuccessEvent', () {
      test('has correct eventType', () {
        final event = RequestSuccessEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 100,
        );

        expect(event.eventType, equals('request_success'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = RequestSuccessEvent(
          timestamp: timestamp,
          requestId: 'req-123',
          durationMs: 1500,
          totalRetries: 2,
          firstTokenMs: 200,
          tokensReceived: 150,
        );

        final map = event.toMap();

        expect(map['event_type'], equals('request_success'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['request_id'], equals('req-123'));
        expect(map['duration_ms'], equals(1500));
        expect(map['total_retries'], equals(2));
        expect(map['first_token_ms'], equals(200));
        expect(map['tokens_received'], equals(150));
      });

      test('toMap excludes null optional fields', () {
        final event = RequestSuccessEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 100,
        );

        final map = event.toMap();

        expect(map.containsKey('total_retries'), isFalse);
        expect(map.containsKey('first_token_ms'), isFalse);
        expect(map.containsKey('tokens_received'), isFalse);
      });
    });

    group('RequestFailureEvent', () {
      test('has correct eventType', () {
        final event = RequestFailureEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 100,
          errorType: 'Error',
          errorMessage: 'test',
        );

        expect(event.eventType, equals('request_failure'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = RequestFailureEvent(
          timestamp: timestamp,
          requestId: 'req-123',
          durationMs: 500,
          errorType: 'ServerException',
          errorMessage: 'Internal server error',
          statusCode: 500,
          totalRetries: 3,
          isRetryable: true,
        );

        final map = event.toMap();

        expect(map['event_type'], equals('request_failure'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['request_id'], equals('req-123'));
        expect(map['duration_ms'], equals(500));
        expect(map['error_type'], equals('ServerException'));
        expect(map['error_message'], equals('Internal server error'));
        expect(map['status_code'], equals(500));
        expect(map['total_retries'], equals(3));
        expect(map['is_retryable'], isTrue);
      });

      test('toMap excludes null optional fields', () {
        final event = RequestFailureEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 100,
          errorType: 'Error',
          errorMessage: 'test',
        );

        final map = event.toMap();

        expect(map.containsKey('status_code'), isFalse);
        expect(map.containsKey('total_retries'), isFalse);
        expect(map.containsKey('is_retryable'), isFalse);
      });
    });

    group('RateLimitEvent', () {
      test('has correct eventType', () {
        final event = RateLimitEvent(
          timestamp: DateTime.now(),
        );

        expect(event.eventType, equals('rate_limit'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = RateLimitEvent(
          timestamp: timestamp,
          requestId: 'req-123',
          retryAfterMs: 30000,
          retryAfterHeader: '30',
        );

        final map = event.toMap();

        expect(map['event_type'], equals('rate_limit'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['request_id'], equals('req-123'));
        expect(map['retry_after_ms'], equals(30000));
        expect(map['retry_after_header'], equals('30'));
      });

      test('toMap excludes null optional fields', () {
        final event = RateLimitEvent(
          timestamp: DateTime.now(),
        );

        final map = event.toMap();

        expect(map.containsKey('request_id'), isFalse);
        expect(map.containsKey('retry_after_ms'), isFalse);
        expect(map.containsKey('retry_after_header'), isFalse);
      });
    });

    group('LatencyEvent', () {
      test('has correct eventType', () {
        final event = LatencyEvent(
          timestamp: DateTime.now(),
          operation: 'test',
          durationMs: 100,
        );

        expect(event.eventType, equals('latency'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = LatencyEvent(
          timestamp: timestamp,
          operation: 'database_query',
          durationMs: 50,
          requestId: 'req-123',
          metadata: const {'table': 'users', 'query_type': 'select'},
        );

        final map = event.toMap();

        expect(map['event_type'], equals('latency'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['request_id'], equals('req-123'));
        expect(map['operation'], equals('database_query'));
        expect(map['duration_ms'], equals(50));
        expect(map['metadata'],
            equals({'table': 'users', 'query_type': 'select'}),);
      });

      test('toMap excludes null optional fields', () {
        final event = LatencyEvent(
          timestamp: DateTime.now(),
          operation: 'test',
          durationMs: 100,
        );

        final map = event.toMap();

        expect(map.containsKey('request_id'), isFalse);
        expect(map.containsKey('metadata'), isFalse);
      });
    });

    group('StreamInactivityEvent', () {
      test('has correct eventType', () {
        final event = StreamInactivityEvent(
          timestamp: DateTime.now(),
          timeoutMs: 60000,
          lastActivityMs: 75000,
        );

        expect(event.eventType, equals('stream_inactivity'));
      });

      test('toMap includes all fields', () {
        final timestamp = DateTime.now();
        final event = StreamInactivityEvent(
          timestamp: timestamp,
          timeoutMs: 60000,
          lastActivityMs: 75000,
          requestId: 'req-123',
        );

        final map = event.toMap();

        expect(map['event_type'], equals('stream_inactivity'));
        expect(map['timestamp'], equals(timestamp.toIso8601String()));
        expect(map['timeout_ms'], equals(60000));
        expect(map['last_activity_ms'], equals(75000));
        expect(map['request_id'], equals('req-123'));
      });

      test('toMap excludes null requestId', () {
        final event = StreamInactivityEvent(
          timestamp: DateTime.now(),
          timeoutMs: 60000,
          lastActivityMs: 75000,
        );

        final map = event.toMap();

        expect(map.containsKey('request_id'), isFalse);
      });
    });
  });
}
