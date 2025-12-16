import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/config/retry_config.dart';

void main() {
  group('RetryConfig', () {
    group('constructor', () {
      test('creates config with default values', () {
        const config = RetryConfig();

        expect(config.maxAttempts, equals(3));
        expect(config.initialDelay, equals(const Duration(seconds: 1)));
        expect(config.maxDelay, equals(const Duration(seconds: 30)));
        expect(config.backoffMultiplier, equals(2.0));
        expect(config.jitterFactor, equals(0.1));
        expect(
          config.retryableStatusCodes,
          equals(RetryConfig.defaultRetryableStatusCodes),
        );
      });

      test('creates config with custom values', () {
        const config = RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 500),
          maxDelay: Duration(seconds: 60),
          backoffMultiplier: 1.5,
          jitterFactor: 0.2,
          retryableStatusCodes: {500, 502},
        );

        expect(config.maxAttempts, equals(5));
        expect(config.initialDelay, equals(const Duration(milliseconds: 500)));
        expect(config.maxDelay, equals(const Duration(seconds: 60)));
        expect(config.backoffMultiplier, equals(1.5));
        expect(config.jitterFactor, equals(0.2));
        expect(config.retryableStatusCodes, equals({500, 502}));
      });
    });

    group('preset configurations', () {
      test('defaults preset has expected values', () {
        const config = RetryConfig.defaults;

        expect(config.maxAttempts, equals(3));
        expect(config.initialDelay, equals(const Duration(seconds: 1)));
        expect(config.maxDelay, equals(const Duration(seconds: 30)));
        expect(config.backoffMultiplier, equals(2.0));
        expect(config.jitterFactor, equals(0.1));
      });

      test('noRetry preset disables retries', () {
        const config = RetryConfig.noRetry;

        expect(config.maxAttempts, equals(0));
      });

      test('aggressive preset has higher attempts and shorter delays', () {
        const config = RetryConfig.aggressive;

        expect(config.maxAttempts, equals(5));
        expect(config.initialDelay, equals(const Duration(milliseconds: 500)));
        expect(config.maxDelay, equals(const Duration(seconds: 60)));
        expect(config.backoffMultiplier, equals(1.5));
      });
    });

    group('defaultRetryableStatusCodes', () {
      test('contains expected status codes', () {
        expect(
          RetryConfig.defaultRetryableStatusCodes,
          equals({429, 500, 502, 503, 504}),
        );
      });

      test('includes rate limit code (429)', () {
        expect(RetryConfig.defaultRetryableStatusCodes.contains(429), isTrue);
      });

      test('includes server error codes (5xx)', () {
        expect(RetryConfig.defaultRetryableStatusCodes.contains(500), isTrue);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(502), isTrue);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(503), isTrue);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(504), isTrue);
      });

      test('does not include client error codes (4xx)', () {
        expect(RetryConfig.defaultRetryableStatusCodes.contains(400), isFalse);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(401), isFalse);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(403), isFalse);
        expect(RetryConfig.defaultRetryableStatusCodes.contains(404), isFalse);
      });
    });

    group('getDelayForAttempt', () {
      group('exponential backoff', () {
        test('calculates correct delay for first attempt (attempt 0)', () {
          const config = RetryConfig(
            jitterFactor: 0, // Disable jitter for predictable testing
          );

          final delay = config.getDelayForAttempt(0);

          expect(delay, equals(const Duration(seconds: 1)));
        });

        test('calculates correct delay for second attempt (attempt 1)', () {
          const config = RetryConfig(
            jitterFactor: 0,
          );

          final delay = config.getDelayForAttempt(1);

          expect(delay, equals(const Duration(seconds: 2)));
        });

        test('calculates correct delay for third attempt (attempt 2)', () {
          const config = RetryConfig(
            jitterFactor: 0,
          );

          final delay = config.getDelayForAttempt(2);

          expect(delay, equals(const Duration(seconds: 4)));
        });

        test('calculates correct delay with multiplier 1.5', () {
          const config = RetryConfig(
            backoffMultiplier: 1.5,
            jitterFactor: 0,
          );

          expect(
            config.getDelayForAttempt(0),
            equals(const Duration(milliseconds: 1000)),
          );
          expect(
            config.getDelayForAttempt(1),
            equals(const Duration(milliseconds: 1500)),
          );
          expect(
            config.getDelayForAttempt(2),
            equals(const Duration(milliseconds: 2250)),
          );
        });

        test('calculates correct delay with custom initial delay', () {
          const config = RetryConfig(
            initialDelay: Duration(milliseconds: 500),
            jitterFactor: 0,
          );

          expect(
            config.getDelayForAttempt(0),
            equals(const Duration(milliseconds: 500)),
          );
          expect(
            config.getDelayForAttempt(1),
            equals(const Duration(milliseconds: 1000)),
          );
          expect(
            config.getDelayForAttempt(2),
            equals(const Duration(milliseconds: 2000)),
          );
        });
      });

      group('max delay cap', () {
        test('caps delay at maxDelay', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            jitterFactor: 0,
          );

          // Attempt 0: 10s
          // Attempt 1: 20s
          // Attempt 2: 40s -> capped at 30s
          expect(
            config.getDelayForAttempt(2),
            equals(const Duration(seconds: 30)),
          );
        });

        test('all subsequent attempts stay at maxDelay', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            jitterFactor: 0,
          );

          expect(
            config.getDelayForAttempt(3),
            equals(const Duration(seconds: 30)),
          );
          expect(
            config.getDelayForAttempt(10),
            equals(const Duration(seconds: 30)),
          );
        });
      });

      group('jitter', () {
        test('adds jitter within expected range', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            backoffMultiplier: 1, // No backoff for easier testing
            maxDelay: Duration(seconds: 60),
          );

          // With 10% jitter, delay should be between 9s and 11s
          const minExpected = Duration(milliseconds: 9000);
          const maxExpected = Duration(milliseconds: 11000);

          // Run multiple times to verify jitter is applied
          for (var i = 0; i < 100; i++) {
            final delay = config.getDelayForAttempt(0);
            expect(delay.inMilliseconds >= minExpected.inMilliseconds, isTrue);
            expect(delay.inMilliseconds <= maxExpected.inMilliseconds, isTrue);
          }
        });

        test('uses provided random instance', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            backoffMultiplier: 1,
            maxDelay: Duration(seconds: 60),
          );

          // Use seeded random for deterministic results
          final random1 = Random(42);
          final random2 = Random(42);

          final delay1 = config.getDelayForAttempt(0, random1);
          final delay2 = config.getDelayForAttempt(0, random2);

          expect(delay1, equals(delay2));
        });

        test('no jitter when jitterFactor is 0', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            backoffMultiplier: 1,
            jitterFactor: 0,
            maxDelay: Duration(seconds: 60),
          );

          // Should always return exactly the same value
          for (var i = 0; i < 10; i++) {
            final delay = config.getDelayForAttempt(0);
            expect(delay, equals(const Duration(seconds: 10)));
          }
        });

        test('larger jitter factor produces wider variance', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 10),
            backoffMultiplier: 1,
            jitterFactor: 0.5, // ±50%
            maxDelay: Duration(seconds: 60),
          );

          // With 50% jitter, delay should be between 5s and 15s
          const minExpected = Duration(milliseconds: 5000);
          const maxExpected = Duration(milliseconds: 15000);

          for (var i = 0; i < 100; i++) {
            final delay = config.getDelayForAttempt(0);
            expect(delay.inMilliseconds >= minExpected.inMilliseconds, isTrue);
            expect(delay.inMilliseconds <= maxExpected.inMilliseconds, isTrue);
          }
        });
      });

      group('edge cases', () {
        test('returns zero for negative attempt', () {
          const config = RetryConfig(jitterFactor: 0);

          expect(config.getDelayForAttempt(-1), equals(Duration.zero));
          expect(config.getDelayForAttempt(-100), equals(Duration.zero));
        });

        test('handles very large attempt numbers', () {
          const config = RetryConfig(
            jitterFactor: 0,
          );

          // Very large attempt should just return maxDelay
          final delay = config.getDelayForAttempt(100);
          expect(delay, equals(const Duration(seconds: 30)));
        });

        test('handles backoff multiplier of 1.0', () {
          const config = RetryConfig(
            initialDelay: Duration(seconds: 5),
            backoffMultiplier: 1,
            jitterFactor: 0,
            maxDelay: Duration(seconds: 60),
          );

          // All attempts should have same delay
          expect(config.getDelayForAttempt(0), equals(const Duration(seconds: 5)));
          expect(config.getDelayForAttempt(1), equals(const Duration(seconds: 5)));
          expect(config.getDelayForAttempt(5), equals(const Duration(seconds: 5)));
        });
      });
    });

    group('shouldRetryStatusCode', () {
      test('returns true for retryable status codes', () {
        const config = RetryConfig();

        expect(config.shouldRetryStatusCode(429), isTrue);
        expect(config.shouldRetryStatusCode(500), isTrue);
        expect(config.shouldRetryStatusCode(502), isTrue);
        expect(config.shouldRetryStatusCode(503), isTrue);
        expect(config.shouldRetryStatusCode(504), isTrue);
      });

      test('returns false for non-retryable status codes', () {
        const config = RetryConfig();

        expect(config.shouldRetryStatusCode(200), isFalse);
        expect(config.shouldRetryStatusCode(400), isFalse);
        expect(config.shouldRetryStatusCode(401), isFalse);
        expect(config.shouldRetryStatusCode(403), isFalse);
        expect(config.shouldRetryStatusCode(404), isFalse);
        expect(config.shouldRetryStatusCode(422), isFalse);
      });

      test('uses custom retryable status codes', () {
        const config = RetryConfig(
          retryableStatusCodes: {400, 401},
        );

        expect(config.shouldRetryStatusCode(400), isTrue);
        expect(config.shouldRetryStatusCode(401), isTrue);
        expect(config.shouldRetryStatusCode(429), isFalse);
        expect(config.shouldRetryStatusCode(500), isFalse);
      });

      test('empty retryable codes returns false for all', () {
        const config = RetryConfig(
          retryableStatusCodes: {},
        );

        expect(config.shouldRetryStatusCode(429), isFalse);
        expect(config.shouldRetryStatusCode(500), isFalse);
        expect(config.shouldRetryStatusCode(200), isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated maxAttempts', () {
        const original = RetryConfig();
        final copy = original.copyWith(maxAttempts: 10);

        expect(copy.maxAttempts, equals(10));
        expect(copy.initialDelay, equals(original.initialDelay));
        expect(copy.maxDelay, equals(original.maxDelay));
        expect(copy.backoffMultiplier, equals(original.backoffMultiplier));
        expect(copy.jitterFactor, equals(original.jitterFactor));
        expect(copy.retryableStatusCodes, equals(original.retryableStatusCodes));
      });

      test('creates copy with updated initialDelay', () {
        const original = RetryConfig();
        final copy = original.copyWith(
          initialDelay: const Duration(milliseconds: 500),
        );

        expect(copy.maxAttempts, equals(original.maxAttempts));
        expect(copy.initialDelay, equals(const Duration(milliseconds: 500)));
      });

      test('creates copy with updated maxDelay', () {
        const original = RetryConfig();
        final copy = original.copyWith(
          maxDelay: const Duration(seconds: 120),
        );

        expect(copy.maxDelay, equals(const Duration(seconds: 120)));
      });

      test('creates copy with updated backoffMultiplier', () {
        const original = RetryConfig();
        final copy = original.copyWith(backoffMultiplier: 3);

        expect(copy.backoffMultiplier, equals(3.0));
      });

      test('creates copy with updated jitterFactor', () {
        const original = RetryConfig();
        final copy = original.copyWith(jitterFactor: 0.5);

        expect(copy.jitterFactor, equals(0.5));
      });

      test('creates copy with updated retryableStatusCodes', () {
        const original = RetryConfig();
        final copy = original.copyWith(retryableStatusCodes: {418, 503});

        expect(copy.retryableStatusCodes, equals({418, 503}));
      });

      test('creates copy with all fields updated', () {
        const original = RetryConfig();
        final copy = original.copyWith(
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 200),
          maxDelay: const Duration(seconds: 60),
          backoffMultiplier: 1.5,
          jitterFactor: 0.2,
          retryableStatusCodes: {500},
        );

        expect(copy.maxAttempts, equals(5));
        expect(copy.initialDelay, equals(const Duration(milliseconds: 200)));
        expect(copy.maxDelay, equals(const Duration(seconds: 60)));
        expect(copy.backoffMultiplier, equals(1.5));
        expect(copy.jitterFactor, equals(0.2));
        expect(copy.retryableStatusCodes, equals({500}));
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = RetryConfig(
          
        );
        const config2 = RetryConfig(
          
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different maxAttempts are not equal', () {
        const config1 = RetryConfig();
        const config2 = RetryConfig(maxAttempts: 5);

        expect(config1, isNot(equals(config2)));
      });

      test('different initialDelay are not equal', () {
        const config1 = RetryConfig();
        const config2 = RetryConfig(initialDelay: Duration(seconds: 2));

        expect(config1, isNot(equals(config2)));
      });

      test('different retryableStatusCodes are not equal', () {
        const config1 = RetryConfig(retryableStatusCodes: {500});
        const config2 = RetryConfig(retryableStatusCodes: {502});

        expect(config1, isNot(equals(config2)));
      });

      test('same retryableStatusCodes in different order are equal', () {
        const config1 = RetryConfig(retryableStatusCodes: {500, 502, 503});
        const config2 = RetryConfig(retryableStatusCodes: {503, 500, 502});

        expect(config1, equals(config2));
      });

      test('identical configs are equal', () {
        const config = RetryConfig();

        expect(identical(config, config), isTrue);
        expect(config == config, isTrue);
      });
    });
  });
}
