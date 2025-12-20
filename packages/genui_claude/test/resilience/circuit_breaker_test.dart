import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/exceptions/claude_exceptions.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:genui_claude/src/metrics/metrics_event.dart';
import 'package:genui_claude/src/resilience/circuit_breaker.dart';

void main() {
  group('CircuitBreakerConfig', () {
    group('constructor', () {
      test('creates config with default values', () {
        const config = CircuitBreakerConfig();

        expect(config.failureThreshold, equals(5));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 30)));
        expect(config.halfOpenSuccessThreshold, equals(2));
      });

      test('creates config with custom values', () {
        const config = CircuitBreakerConfig(
          failureThreshold: 10,
          recoveryTimeout: Duration(seconds: 60),
          halfOpenSuccessThreshold: 5,
        );

        expect(config.failureThreshold, equals(10));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 60)));
        expect(config.halfOpenSuccessThreshold, equals(5));
      });
    });

    group('preset configurations', () {
      test('defaults preset has expected values', () {
        const config = CircuitBreakerConfig.defaults;

        expect(config.failureThreshold, equals(5));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 30)));
        expect(config.halfOpenSuccessThreshold, equals(2));
      });

      test('lenient preset has higher thresholds', () {
        const config = CircuitBreakerConfig.lenient;

        expect(config.failureThreshold, equals(10));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 60)));
        expect(config.halfOpenSuccessThreshold, equals(3));
      });

      test('strict preset has lower thresholds', () {
        const config = CircuitBreakerConfig.strict;

        expect(config.failureThreshold, equals(3));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 15)));
        expect(config.halfOpenSuccessThreshold, equals(1));
      });

      test('sla999 preset is optimized for 99.9% availability', () {
        const config = CircuitBreakerConfig.sla999;

        expect(config.failureThreshold, equals(3));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 15)));
        expect(config.halfOpenSuccessThreshold, equals(1));
      });

      test('sla9999 preset is optimized for 99.99% availability', () {
        const config = CircuitBreakerConfig.sla9999;

        expect(config.failureThreshold, equals(2));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 10)));
        expect(config.halfOpenSuccessThreshold, equals(2));
      });

      test('highAvailability preset has strictest thresholds', () {
        const config = CircuitBreakerConfig.highAvailability;

        expect(config.failureThreshold, equals(1));
        expect(config.recoveryTimeout, equals(const Duration(seconds: 5)));
        expect(config.halfOpenSuccessThreshold, equals(3));
      });

      test('SLA presets are progressively stricter', () {
        const sla999 = CircuitBreakerConfig.sla999;
        const sla9999 = CircuitBreakerConfig.sla9999;
        const ha = CircuitBreakerConfig.highAvailability;

        // Failure threshold decreases with stricter SLA
        expect(sla9999.failureThreshold, lessThan(sla999.failureThreshold));
        expect(ha.failureThreshold, lessThan(sla9999.failureThreshold));

        // Recovery timeout decreases with stricter SLA
        expect(sla9999.recoveryTimeout, lessThan(sla999.recoveryTimeout));
        expect(ha.recoveryTimeout, lessThan(sla9999.recoveryTimeout));

        // Success threshold increases with stricter SLA (more validation)
        expect(
          sla9999.halfOpenSuccessThreshold,
          greaterThanOrEqualTo(sla999.halfOpenSuccessThreshold),
        );
        expect(
          ha.halfOpenSuccessThreshold,
          greaterThan(sla9999.halfOpenSuccessThreshold),
        );
      });
    });

    group('copyWith', () {
      test('creates copy with updated failure threshold', () {
        const original = CircuitBreakerConfig();
        final copy = original.copyWith(failureThreshold: 10);

        expect(copy.failureThreshold, equals(10));
        expect(copy.recoveryTimeout, equals(original.recoveryTimeout));
        expect(
          copy.halfOpenSuccessThreshold,
          equals(original.halfOpenSuccessThreshold),
        );
      });

      test('creates copy with updated recovery timeout', () {
        const original = CircuitBreakerConfig();
        final copy = original.copyWith(
          recoveryTimeout: const Duration(seconds: 120),
        );

        expect(copy.failureThreshold, equals(original.failureThreshold));
        expect(copy.recoveryTimeout, equals(const Duration(seconds: 120)));
        expect(
          copy.halfOpenSuccessThreshold,
          equals(original.halfOpenSuccessThreshold),
        );
      });

      test('creates copy with updated half-open success threshold', () {
        const original = CircuitBreakerConfig();
        final copy = original.copyWith(halfOpenSuccessThreshold: 5);

        expect(copy.failureThreshold, equals(original.failureThreshold));
        expect(copy.recoveryTimeout, equals(original.recoveryTimeout));
        expect(copy.halfOpenSuccessThreshold, equals(5));
      });

      test('creates copy with all fields updated', () {
        const original = CircuitBreakerConfig();
        final copy = original.copyWith(
          failureThreshold: 7,
          recoveryTimeout: const Duration(seconds: 45),
          halfOpenSuccessThreshold: 3,
        );

        expect(copy.failureThreshold, equals(7));
        expect(copy.recoveryTimeout, equals(const Duration(seconds: 45)));
        expect(copy.halfOpenSuccessThreshold, equals(3));
      });
    });
  });

  group('CircuitBreaker', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          recoveryTimeout: Duration(milliseconds: 100),
        ),
        name: 'test-breaker',
      );
    });

    group('initial state', () {
      test('starts in closed state', () {
        expect(breaker.state, equals(CircuitState.closed));
      });

      test('starts with zero failure count', () {
        expect(breaker.failureCount, equals(0));
      });

      test('allows requests initially', () {
        expect(breaker.allowsRequest, isTrue);
      });

      test('checkState does not throw initially', () {
        expect(() => breaker.checkState(), returnsNormally);
      });

      test('lastFailureTime is null initially', () {
        expect(breaker.lastFailureTime, isNull);
      });
    });

    group('state transitions', () {
      group('closed to open', () {
        test('remains closed below failure threshold', () {
          breaker.recordFailure();
          breaker.recordFailure();

          expect(breaker.state, equals(CircuitState.closed));
          expect(breaker.failureCount, equals(2));
        });

        test('opens at failure threshold', () {
          breaker.recordFailure();
          breaker.recordFailure();
          breaker.recordFailure();

          expect(breaker.state, equals(CircuitState.open));
          expect(breaker.failureCount, equals(3));
        });

        test('rejects requests when open', () {
          // Trigger opening
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          expect(breaker.allowsRequest, isFalse);
        });

        test('checkState throws when open', () {
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          expect(
            () => breaker.checkState(),
            throwsA(isA<CircuitBreakerOpenException>()),
          );
        });

        test('thrown exception includes recovery time', () {
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          try {
            breaker.checkState();
            fail('Should have thrown');
          } on CircuitBreakerOpenException catch (e) {
            expect(e.recoveryTime, isNotNull);
            expect(e.message, contains('test-breaker'));
          }
        });
      });

      group('open to half-open', () {
        test('transitions to half-open after recovery timeout', () async {
          // Trigger opening
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }
          expect(breaker.state, equals(CircuitState.open));

          // Wait for recovery timeout
          await Future<void>.delayed(const Duration(milliseconds: 150));

          // Check state (triggers transition)
          expect(breaker.allowsRequest, isTrue);
          expect(breaker.state, equals(CircuitState.halfOpen));
        });

        test('allows limited requests in half-open state', () async {
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          await Future<void>.delayed(const Duration(milliseconds: 150));

          // Should allow request and transition to half-open
          expect(breaker.allowsRequest, isTrue);
          expect(breaker.state, equals(CircuitState.halfOpen));
        });
      });

      group('half-open to closed', () {
        test('closes after enough successes in half-open state', () async {
          // Open the circuit
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          // Wait for half-open
          await Future<void>.delayed(const Duration(milliseconds: 150));
          breaker.allowsRequest; // Trigger transition

          expect(breaker.state, equals(CircuitState.halfOpen));

          // Record successes (threshold is 2)
          breaker.recordSuccess();
          expect(breaker.state, equals(CircuitState.halfOpen));

          breaker.recordSuccess();
          expect(breaker.state, equals(CircuitState.closed));
        });

        test('resets failure count when closed from half-open', () async {
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          await Future<void>.delayed(const Duration(milliseconds: 150));
          breaker.allowsRequest;

          breaker.recordSuccess();
          breaker.recordSuccess();

          expect(breaker.state, equals(CircuitState.closed));
          expect(breaker.failureCount, equals(0));
        });
      });

      group('half-open to open', () {
        test('reopens on failure in half-open state', () async {
          // Open the circuit
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          // Wait for half-open
          await Future<void>.delayed(const Duration(milliseconds: 150));
          breaker.allowsRequest;

          expect(breaker.state, equals(CircuitState.halfOpen));

          // Failure in half-open state should reopen
          breaker.recordFailure();

          expect(breaker.state, equals(CircuitState.open));
        });

        test('reopens even after some successes in half-open', () async {
          for (var i = 0; i < 3; i++) {
            breaker.recordFailure();
          }

          await Future<void>.delayed(const Duration(milliseconds: 150));
          breaker.allowsRequest;

          breaker.recordSuccess(); // One success
          breaker.recordFailure(); // Then failure

          expect(breaker.state, equals(CircuitState.open));
        });
      });
    });

    group('recordSuccess', () {
      test('resets failure count in closed state', () {
        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.failureCount, equals(2));

        breaker.recordSuccess();
        expect(breaker.failureCount, equals(0));
      });

      test('increments success count in half-open state', () async {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }

        await Future<void>.delayed(const Duration(milliseconds: 150));
        breaker.allowsRequest;

        breaker.recordSuccess();
        expect(breaker.state, equals(CircuitState.halfOpen));
      });

      test('handles success when unexpectedly in open state', () {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }

        // This shouldn't happen in practice but should be handled gracefully
        expect(() => breaker.recordSuccess(), returnsNormally);
      });
    });

    group('recordFailure', () {
      test('increments failure count', () {
        expect(breaker.failureCount, equals(0));

        breaker.recordFailure();
        expect(breaker.failureCount, equals(1));

        breaker.recordFailure();
        expect(breaker.failureCount, equals(2));
      });

      test('updates lastFailureTime', () {
        expect(breaker.lastFailureTime, isNull);

        final before = DateTime.now();
        breaker.recordFailure();
        final after = DateTime.now();

        expect(breaker.lastFailureTime, isNotNull);
        expect(
          breaker.lastFailureTime!
              .isAfter(before.subtract(const Duration(milliseconds: 1))),
          isTrue,
        );
        expect(
          breaker.lastFailureTime!
              .isBefore(after.add(const Duration(milliseconds: 1))),
          isTrue,
        );
      });

      test('updates timestamp when already open', () {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }

        final firstOpenTime = breaker.lastFailureTime;

        breaker.recordFailure();

        expect(breaker.lastFailureTime!.isAfter(firstOpenTime!), isTrue);
      });
    });

    group('reset', () {
      test('resets to closed state', () {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }
        expect(breaker.state, equals(CircuitState.open));

        breaker.reset();

        expect(breaker.state, equals(CircuitState.closed));
      });

      test('resets failure count', () {
        breaker.recordFailure();
        breaker.recordFailure();

        breaker.reset();

        expect(breaker.failureCount, equals(0));
      });

      test('resets lastFailureTime', () {
        breaker.recordFailure();
        expect(breaker.lastFailureTime, isNotNull);

        breaker.reset();

        expect(breaker.lastFailureTime, isNull);
      });

      test('allows requests after reset', () {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }
        expect(breaker.allowsRequest, isFalse);

        breaker.reset();

        expect(breaker.allowsRequest, isTrue);
      });
    });

    group('metrics integration', () {
      late MetricsCollector collector;
      late List<MetricsEvent> events;

      setUp(() {
        events = [];
        collector = MetricsCollector();
        collector.eventStream.listen(events.add);

        breaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 2,
            recoveryTimeout: Duration(milliseconds: 50),
            halfOpenSuccessThreshold: 1,
          ),
          name: 'metrics-test',
          metricsCollector: collector,
        );
      });

      tearDown(() {
        collector.dispose();
      });

      test('emits event when circuit opens', () async {
        breaker.recordFailure();
        breaker.recordFailure();

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stateChanges = events.whereType<CircuitBreakerStateChangeEvent>();
        expect(stateChanges.length, equals(1));

        final event = stateChanges.first;
        expect(event.circuitName, equals('metrics-test'));
        expect(event.previousState, equals(CircuitState.closed));
        expect(event.newState, equals(CircuitState.open));
        expect(event.failureCount, equals(2));
      });

      test('emits event when circuit transitions to half-open', () async {
        breaker.recordFailure();
        breaker.recordFailure();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        breaker.allowsRequest; // Trigger transition

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stateChanges =
            events.whereType<CircuitBreakerStateChangeEvent>().toList();
        expect(stateChanges.length, equals(2));

        final halfOpenEvent = stateChanges[1];
        expect(halfOpenEvent.previousState, equals(CircuitState.open));
        expect(halfOpenEvent.newState, equals(CircuitState.halfOpen));
      });

      test('emits event when circuit closes from half-open', () async {
        breaker.recordFailure();
        breaker.recordFailure();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        breaker.allowsRequest;

        breaker.recordSuccess(); // Half-open success threshold is 1

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stateChanges =
            events.whereType<CircuitBreakerStateChangeEvent>().toList();
        expect(stateChanges.length, equals(3));

        final closeEvent = stateChanges[2];
        expect(closeEvent.previousState, equals(CircuitState.halfOpen));
        expect(closeEvent.newState, equals(CircuitState.closed));
      });
    });

    group('edge cases', () {
      test('handles rapid state transitions', () async {
        // Open
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }
        expect(breaker.state, equals(CircuitState.open));

        // Wait and transition to half-open
        await Future<void>.delayed(const Duration(milliseconds: 150));
        breaker.allowsRequest;
        expect(breaker.state, equals(CircuitState.halfOpen));

        // Fail again
        breaker.recordFailure();
        expect(breaker.state, equals(CircuitState.open));

        // Wait and transition to half-open again
        await Future<void>.delayed(const Duration(milliseconds: 150));
        breaker.allowsRequest;
        expect(breaker.state, equals(CircuitState.halfOpen));

        // Succeed twice
        breaker.recordSuccess();
        breaker.recordSuccess();
        expect(breaker.state, equals(CircuitState.closed));
      });

      test('multiple checkState calls in open state all throw', () {
        for (var i = 0; i < 3; i++) {
          breaker.recordFailure();
        }

        expect(
          () => breaker.checkState(),
          throwsA(isA<CircuitBreakerOpenException>()),
        );
        expect(
          () => breaker.checkState(),
          throwsA(isA<CircuitBreakerOpenException>()),
        );
      });

      test('works with default config', () {
        final defaultBreaker = CircuitBreaker();

        expect(defaultBreaker.state, equals(CircuitState.closed));
        expect(defaultBreaker.name, equals('default'));
      });

      test('works without metrics collector', () {
        final noMetricsBreaker = CircuitBreaker(
          config: const CircuitBreakerConfig(failureThreshold: 1),
        );

        noMetricsBreaker.recordFailure();

        expect(noMetricsBreaker.state, equals(CircuitState.open));
      });
    });
  });
}
