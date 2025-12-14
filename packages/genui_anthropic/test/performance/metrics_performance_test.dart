import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

void main() {
  group('MetricsCollector Performance', () {
    test('handles high-throughput event emission', () async {
      final collector = MetricsCollector();
      final events = <MetricsEvent>[];
      collector.eventStream.listen(events.add);

      final stopwatch = Stopwatch()..start();
      const eventCount = 10000;

      // Emit many events rapidly
      for (var i = 0; i < eventCount; i++) {
        collector.recordRequestStart(
          requestId: 'req-$i',
          endpoint: 'https://api.example.com',
          model: 'claude-sonnet-4',
        );
      }

      // Allow stream to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      stopwatch.stop();

      // All events should be received
      expect(events.length, equals(eventCount));

      // Performance: should process 10k events in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      collector.dispose();
    });

    test('statistics aggregation is efficient', () async {
      final collector = MetricsCollector();

      // Record many requests
      const requestCount = 1000;
      for (var i = 0; i < requestCount; i++) {
        collector
          ..recordRequestStart(
            requestId: 'req-$i',
            endpoint: 'https://api.example.com',
          )
          ..recordRequestSuccess(
            requestId: 'req-$i',
            duration: Duration(milliseconds: 100 + (i % 500)),
          );
      }

      final stopwatch = Stopwatch()..start();

      // Access statistics many times
      for (var i = 0; i < 1000; i++) {
        final stats = collector.stats;
        // ignore: unused_local_variable
        final successRate = stats.successRate;
        // ignore: unused_local_variable
        final p95Latency = stats.p95LatencyMs;
      }

      stopwatch.stop();

      // Stats access should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      collector.dispose();
    });

    test('disabled collector has minimal overhead', () async {
      final enabledCollector = MetricsCollector();
      final disabledCollector = MetricsCollector(enabled: false);

      const iterations = 10000;

      // Time enabled collector
      final enabledStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        enabledCollector.recordRequestStart(
          requestId: 'req-$i',
          endpoint: 'https://api.example.com',
        );
      }
      enabledStopwatch.stop();

      // Time disabled collector
      final disabledStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        disabledCollector.recordRequestStart(
          requestId: 'req-$i',
          endpoint: 'https://api.example.com',
        );
      }
      disabledStopwatch.stop();

      // Disabled should be faster
      expect(
        disabledStopwatch.elapsedMilliseconds,
        lessThan(enabledStopwatch.elapsedMilliseconds),
      );

      enabledCollector.dispose();
      disabledCollector.dispose();
    });

    test('percentile calculation handles large datasets', () async {
      final collector = MetricsCollector();

      // Record enough requests to test percentile windowing
      const requestCount = 2000; // Exceeds _maxLatencies (1000)
      for (var i = 0; i < requestCount; i++) {
        collector
          ..recordRequestStart(
            requestId: 'req-$i',
            endpoint: 'https://api.example.com',
          )
          ..recordRequestSuccess(
            requestId: 'req-$i',
            duration: Duration(milliseconds: i % 1000),
          );
      }

      final stopwatch = Stopwatch()..start();

      // Calculate percentiles
      for (var i = 0; i < 100; i++) {
        // ignore: unused_local_variable
        final p50Latency = collector.stats.p50LatencyMs;
        // ignore: unused_local_variable
        final p95Latency = collector.stats.p95LatencyMs;
        // ignore: unused_local_variable
        final p99Latency = collector.stats.p99LatencyMs;
      }

      stopwatch.stop();

      // Percentile calculation should be reasonable
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      collector.dispose();
    });
  });

  group('CircuitBreaker Performance', () {
    test('state checks are fast', () async {
      final breaker = CircuitBreaker(
        name: 'perf-test',
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 100000;

      for (var i = 0; i < iterations; i++) {
        try {
          breaker.checkState();
        } on CircuitBreakerOpenException {
          // Expected when open
        }
      }

      stopwatch.stop();

      // State checks should be very fast
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('recording success/failure is fast', () async {
      final breaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          failureThreshold: 1000000, // High threshold to prevent opening
        ),
        name: 'perf-test',
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 100000;

      for (var i = 0; i < iterations; i++) {
        if (i.isEven) {
          breaker.recordSuccess();
        } else {
          breaker.recordFailure();
        }
      }

      stopwatch.stop();

      // Recording should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('state transitions are handled correctly under load', () async {
      final breaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          recoveryTimeout: Duration(milliseconds: 100),
        ),
        name: 'transition-test',
      );

      // Trigger open state
      for (var i = 0; i < 5; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, equals(CircuitState.open));

      // Wait for recovery timeout
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Check state transitions to half-open
      expect(breaker.allowsRequest, isTrue);
      expect(breaker.state, equals(CircuitState.halfOpen));

      // Success in half-open
      breaker
        ..recordSuccess()
        ..recordSuccess();

      // Should close
      expect(breaker.state, equals(CircuitState.closed));
    });
  });

  group('RetryConfig Performance', () {
    test('delay calculation is consistent', () async {
      const config = RetryConfig(
        maxAttempts: 5,
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 100000;

      for (var i = 0; i < iterations; i++) {
        // ignore: unused_local_variable
        final _ = config.getDelayForAttempt(i % 5);
      }

      stopwatch.stop();

      // Delay calculation should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('jitter produces varied results', () async {
      const config = RetryConfig(
        maxAttempts: 5,
      );

      final delays = <int>{};
      for (var i = 0; i < 100; i++) {
        delays.add(config.getDelayForAttempt(0).inMilliseconds);
      }

      // With 10% jitter on 1000ms, expect some variation
      expect(delays.length, greaterThan(1));
    });
  });

  group('Exception Creation Performance', () {
    test('ExceptionFactory is efficient', () async {
      final stopwatch = Stopwatch()..start();
      const iterations = 10000;

      for (var i = 0; i < iterations; i++) {
        // ignore: unused_local_variable
        final _ = ExceptionFactory.fromHttpStatus(
          statusCode: 500 + (i % 100),
          body: 'Error message $i',
          requestId: 'req-$i',
        );
      }

      stopwatch.stop();

      // Exception creation should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('RetryAfter parsing is efficient', () async {
      final stopwatch = Stopwatch()..start();
      const iterations = 10000;

      for (var i = 0; i < iterations; i++) {
        // ignore: unused_local_variable
        final _ = ExceptionFactory.parseRetryAfter('$i');
      }

      stopwatch.stop();

      // Parsing should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
