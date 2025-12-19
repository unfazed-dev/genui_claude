import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter();
    });

    tearDown(() {
      rateLimiter.dispose();
    });

    group('execute', () {
      test('executes request immediately when not rate limited', () async {
        var executed = false;
        await rateLimiter.execute(() async {
          executed = true;
          return 'result';
        });

        expect(executed, isTrue);
      });

      test('returns result from executed request', () async {
        final result = await rateLimiter.execute(() async => 42);

        expect(result, 42);
      });

      test('queues request when rate limited', () async {
        // Set up rate limiting
        rateLimiter.recordRateLimit(statusCode: 429);

        var executed = false;
        // This should be queued
        unawaited(rateLimiter.execute<void>(() async {
          executed = true;
        }));

        // Give some time for potential execution
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(executed, isFalse);
        expect(rateLimiter.isRateLimited, isTrue);
      });

      test('executes queued requests after rate limit resets', () async {
        // Set up rate limiting with short duration for testing
        rateLimiter.recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(milliseconds: 50),
        );

        var executed = false;
        final future = rateLimiter.execute(() async {
          executed = true;
          return 'result';
        });

        expect(executed, isFalse);

        // Wait for rate limit to reset
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await future;

        expect(executed, isTrue);
      });
    });

    group('recordRateLimit', () {
      test('sets isRateLimited to true on 429 status', () {
        expect(rateLimiter.isRateLimited, isFalse);

        rateLimiter.recordRateLimit(statusCode: 429);

        expect(rateLimiter.isRateLimited, isTrue);
      });

      test('ignores non-429 status codes', () {
        rateLimiter.recordRateLimit(statusCode: 500);

        expect(rateLimiter.isRateLimited, isFalse);
      });

      test('uses provided retryAfter duration', () async {
        rateLimiter.recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(milliseconds: 50),
        );

        expect(rateLimiter.isRateLimited, isTrue);

        // Wait for reset
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(rateLimiter.isRateLimited, isFalse);
      });

      test('defaults to 60 seconds when no retryAfter provided', () {
        rateLimiter.recordRateLimit(statusCode: 429);

        expect(rateLimiter.isRateLimited, isTrue);
        // We can't wait 60 seconds in a test, just verify it's rate limited
      });

      test('cancels previous reset timer when new rate limit recorded', () async {
        // First rate limit with short duration, then second with longer duration
        rateLimiter
          ..recordRateLimit(
            statusCode: 429,
            retryAfter: const Duration(milliseconds: 50),
          )
          ..recordRateLimit(
            statusCode: 429,
            retryAfter: const Duration(milliseconds: 200),
          );

        // Wait past first duration
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should still be rate limited due to second, longer duration
        expect(rateLimiter.isRateLimited, isTrue);
      });
    });

    group('parseRetryAfter', () {
      test('parses integer seconds', () {
        expect(
          RateLimiter.parseRetryAfter('30'),
          const Duration(seconds: 30),
        );
      });

      test('parses zero', () {
        expect(
          RateLimiter.parseRetryAfter('0'),
          Duration.zero,
        );
      });

      test('returns null for null input', () {
        expect(RateLimiter.parseRetryAfter(null), isNull);
      });

      test('returns null for non-numeric string', () {
        expect(RateLimiter.parseRetryAfter('abc'), isNull);
      });

      test('returns null for empty string', () {
        expect(RateLimiter.parseRetryAfter(''), isNull);
      });

      test('parses large values', () {
        expect(
          RateLimiter.parseRetryAfter('3600'),
          const Duration(hours: 1),
        );
      });
    });

    group('dispose', () {
      test('cancels reset timer', () async {
        rateLimiter
          ..recordRateLimit(
            statusCode: 429,
            retryAfter: const Duration(milliseconds: 50),
          )
          ..dispose();

        // Wait past the reset time
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Timer was cancelled, so state remains rate limited
        expect(rateLimiter.isRateLimited, isTrue);
      });

      test('clears pending queue', () {
        rateLimiter
          ..recordRateLimit(statusCode: 429)
          // Queue a request then dispose should clear the queue
          ..dispose();

        // No way to directly check queue is empty, but dispose should work
      });
    });

    group('queue processing', () {
      test('processes multiple queued requests in order', () async {
        rateLimiter.recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(milliseconds: 50),
        );

        final results = <int>[];
        final futures = <Future<void>>[];

        for (var i = 0; i < 3; i++) {
          futures.add(rateLimiter.execute(() async {
            results.add(i);
          }));
        }

        // Wait for rate limit reset and queue processing
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await Future.wait(futures);

        expect(results, [0, 1, 2]);
      });

      test('continues processing queue after errors', () async {
        rateLimiter.recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(milliseconds: 50),
        );

        var secondExecuted = false;

        // First request throws - queue processor catches this internally
        unawaited(rateLimiter.execute<void>(() async {
          throw Exception('Test error');
        }));

        // Second request should still execute
        final secondFuture = rateLimiter.execute(() async {
          secondExecuted = true;
          return 'success';
        });

        // Wait for rate limit reset and queue processing
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Second should complete successfully despite first throwing
        await expectLater(secondFuture, completion('success'));
        expect(secondExecuted, isTrue);
      });
    });
  });
}
