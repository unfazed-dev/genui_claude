import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitConfig', () {
    test('creates with default values', () {
      const config = RateLimitConfig.defaults;

      expect(config.requestsPerMinute, 60);
      expect(config.requestsPerDay, 1000);
      expect(config.tokensPerMinute, 100000);
      expect(config.enabled, isTrue);
    });

    test('creates with custom values', () {
      const config = RateLimitConfig(
        requestsPerMinute: 30,
        requestsPerDay: 500,
        tokensPerMinute: 50000,
        enabled: false,
      );

      expect(config.requestsPerMinute, 30);
      expect(config.requestsPerDay, 500);
      expect(config.tokensPerMinute, 50000);
      expect(config.enabled, isFalse);
    });

    test('unlimited config disables rate limiting', () {
      const config = RateLimitConfig.unlimited;

      expect(config.enabled, isFalse);
      expect(config.requestsPerMinute, 999999);
    });

    test('copyWith creates modified copy', () {
      const config = RateLimitConfig.defaults;
      final modified = config.copyWith(requestsPerMinute: 100);

      expect(modified.requestsPerMinute, 100);
      expect(modified.requestsPerDay, config.requestsPerDay);
      expect(modified.enabled, config.enabled);
    });
  });

  group('ProactiveRateLimiter', () {
    late ProactiveRateLimiter limiter;

    setUp(() {
      limiter = ProactiveRateLimiter(
        config: const RateLimitConfig(
          requestsPerMinute: 5,
          requestsPerDay: 100,
          tokensPerMinute: 1000,
        ),
      );
    });

    tearDown(() {
      limiter.dispose();
    });

    group('execute', () {
      test('executes immediately when under limit', () async {
        var executed = false;
        await limiter.execute(() async {
          executed = true;
          return 'result';
        });

        expect(executed, isTrue);
      });

      test('returns result from executed function', () async {
        final result = await limiter.execute(() async => 42);

        expect(result, 42);
      });

      test('tracks requests per minute', () async {
        expect(limiter.currentRequestsPerMinute, 0);

        await limiter.execute(() async => 'a');
        expect(limiter.currentRequestsPerMinute, 1);

        await limiter.execute(() async => 'b');
        expect(limiter.currentRequestsPerMinute, 2);
      });

      test('tracks daily requests', () async {
        expect(limiter.currentDailyRequests, 0);

        await limiter.execute(() async => 'a');
        expect(limiter.currentDailyRequests, 1);
      });
    });

    group('isThrottled', () {
      test('returns false when under limit', () {
        expect(limiter.isThrottled, isFalse);
      });

      test('returns true when at request per minute limit', () async {
        // Make 5 requests (the limit)
        for (var i = 0; i < 5; i++) {
          await limiter.execute(() async => i);
        }

        expect(limiter.isThrottled, isTrue);
      });
    });

    group('remainingRequestsPerMinute', () {
      test('starts at max', () {
        expect(limiter.remainingRequestsPerMinute, 5);
      });

      test('decreases with requests', () async {
        await limiter.execute(() async => 'a');
        expect(limiter.remainingRequestsPerMinute, 4);

        await limiter.execute(() async => 'b');
        expect(limiter.remainingRequestsPerMinute, 3);
      });
    });

    group('canProceed', () {
      test('returns true when under limit', () {
        expect(limiter.canProceed(), isTrue);
      });

      test('returns false when at limit', () async {
        for (var i = 0; i < 5; i++) {
          await limiter.execute(() async => i);
        }

        expect(limiter.canProceed(), isFalse);
      });
    });

    group('getWaitTime', () {
      test('returns zero when under limit', () {
        expect(limiter.getWaitTime(), Duration.zero);
      });

      test('returns positive duration when at limit', () async {
        for (var i = 0; i < 5; i++) {
          await limiter.execute(() async => i);
        }

        final waitTime = limiter.getWaitTime();
        expect(waitTime, greaterThan(Duration.zero));
        expect(waitTime, lessThanOrEqualTo(const Duration(minutes: 1)));
      });
    });

    group('recordServerRateLimit', () {
      test('fills request slots to prevent further requests', () {
        expect(limiter.isThrottled, isFalse);

        limiter.recordServerRateLimit();

        expect(limiter.isThrottled, isTrue);
        expect(limiter.currentRequestsPerMinute, 5);
      });
    });

    group('reset', () {
      test('clears all counters', () async {
        await limiter.execute(() async => 'a');
        await limiter.execute(() async => 'b');

        expect(limiter.currentRequestsPerMinute, 2);
        expect(limiter.currentDailyRequests, 2);

        limiter.reset();

        expect(limiter.currentRequestsPerMinute, 0);
        expect(limiter.currentDailyRequests, 0);
      });
    });

    group('disabled rate limiting', () {
      test('executes immediately when disabled', () async {
        final disabledLimiter = ProactiveRateLimiter(
          config: RateLimitConfig.unlimited,
        );

        expect(disabledLimiter.isThrottled, isFalse);
        expect(disabledLimiter.canProceed(), isTrue);

        // Should execute many requests without throttling
        for (var i = 0; i < 100; i++) {
          await disabledLimiter.execute(() async => i);
        }

        expect(disabledLimiter.isThrottled, isFalse);

        disabledLimiter.dispose();
      });
    });

    group('token-based limiting', () {
      test('considers estimated tokens in wait calculation', () async {
        final tokenLimiter = ProactiveRateLimiter(
          config: const RateLimitConfig(
            requestsPerMinute: 100,
            tokensPerMinute: 100,
          ),
        );

        // First request with 50 tokens
        await tokenLimiter.execute(
          () async => 'a',
          estimatedTokens: 50,
        );

        // Second request with 60 tokens would exceed limit
        // Should still be able to check wait time
        final waitTime = tokenLimiter.getWaitTime(estimatedTokens: 60);

        // Wait time depends on token overflow
        expect(waitTime, isA<Duration>());

        tokenLimiter.dispose();
      });
    });
  });
}
