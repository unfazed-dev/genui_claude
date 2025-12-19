import 'dart:async';
import 'dart:io';

import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

void main() {
  group('RetryPolicy', () {
    group('constructor', () {
      test('creates with default values', () {
        const policy = RetryPolicy.defaults;

        expect(policy.maxAttempts, 3);
        expect(policy.initialDelay, const Duration(milliseconds: 500));
        expect(policy.maxDelay, const Duration(seconds: 30));
        expect(policy.backoffMultiplier, 2.0);
      });

      test('creates with custom values', () {
        const policy = RetryPolicy(
          maxAttempts: 5,
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(minutes: 1),
          backoffMultiplier: 1.5,
        );

        expect(policy.maxAttempts, 5);
        expect(policy.initialDelay, const Duration(seconds: 1));
        expect(policy.maxDelay, const Duration(minutes: 1));
        expect(policy.backoffMultiplier, 1.5);
      });

      test('defaults static constant matches default constructor', () {
        const defaultPolicy = RetryPolicy.defaults;

        expect(defaultPolicy.maxAttempts, 3);
        expect(defaultPolicy.initialDelay, const Duration(milliseconds: 500));
        expect(defaultPolicy.maxDelay, const Duration(seconds: 30));
        expect(defaultPolicy.backoffMultiplier, 2.0);
      });
    });

    group('shouldRetry', () {
      const policy = RetryPolicy.defaults;

      test('returns false when max attempts exceeded', () {
        const error = StreamException('test', isRetryable: true);

        expect(policy.shouldRetry(error, 3), isFalse);
        expect(policy.shouldRetry(error, 4), isFalse);
      });

      test('returns true for retryable StreamException', () {
        const error = StreamException('test', isRetryable: true);

        expect(policy.shouldRetry(error, 0), isTrue);
        expect(policy.shouldRetry(error, 1), isTrue);
        expect(policy.shouldRetry(error, 2), isTrue);
      });

      test('returns false for non-retryable StreamException', () {
        const error = StreamException('test');

        expect(policy.shouldRetry(error, 0), isFalse);
      });

      test('returns true for SocketException', () {
        const error = SocketException('Connection failed');

        expect(policy.shouldRetry(error, 0), isTrue);
      });

      test('returns true for TimeoutException', () {
        final error = TimeoutException('Request timeout');

        expect(policy.shouldRetry(error, 0), isTrue);
      });

      test('returns true for HttpException', () {
        const error = HttpException('HTTP error');

        expect(policy.shouldRetry(error, 0), isTrue);
      });

      test('returns false for generic Exception', () {
        final error = Exception('Generic error');

        expect(policy.shouldRetry(error, 0), isFalse);
      });

      test('returns false for FormatException', () {
        const error = FormatException('Format error');

        expect(policy.shouldRetry(error, 0), isFalse);
      });
    });

    group('getDelay', () {
      test('calculates exponential backoff', () {
        const policy = RetryPolicy(
          initialDelay: Duration(milliseconds: 100),
          maxDelay: Duration(seconds: 10),
        );

        // delay = initialDelay * (multiplier * attempt)
        expect(policy.getDelay(1), const Duration(milliseconds: 200));
        expect(policy.getDelay(2), const Duration(milliseconds: 400));
        expect(policy.getDelay(3), const Duration(milliseconds: 600));
      });

      test('caps at maxDelay', () {
        const policy = RetryPolicy(
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 5),
        );

        // Would be 1s * (2 * 10) = 20s, but capped at 5s
        expect(policy.getDelay(10), const Duration(seconds: 5));
      });

      test('returns exact maxDelay when calculated equals maxDelay', () {
        const policy = RetryPolicy(
          initialDelay: Duration(seconds: 1),
          backoffMultiplier: 2.5,
          maxDelay: Duration(milliseconds: 2500),
        );

        // 1s * (2.5 * 1) = 2.5s = maxDelay
        expect(policy.getDelay(1), const Duration(milliseconds: 2500));
      });

      test('handles first attempt (attempt = 0)', () {
        const policy = RetryPolicy(
          initialDelay: Duration(milliseconds: 100),
        );

        // 100ms * (2.0 * 0) = 0ms
        expect(policy.getDelay(0), Duration.zero);
      });
    });

    group('retryWithBackoff', () {
      test('succeeds on first attempt without retry', () async {
        const policy = RetryPolicy.defaults;
        var callCount = 0;

        final result = await policy.retryWithBackoff(() async {
          callCount++;
          return 'success';
        });

        expect(result, 'success');
        expect(callCount, 1);
      });

      test('retries on retryable error and succeeds', () async {
        const policy = RetryPolicy(
          initialDelay: Duration(milliseconds: 10),
        );
        var callCount = 0;

        final result = await policy.retryWithBackoff(() async {
          callCount++;
          if (callCount < 2) {
            throw const SocketException('Connection failed');
          }
          return 'success';
        });

        expect(result, 'success');
        expect(callCount, 2);
      });

      test('throws after max attempts exhausted', () async {
        const policy = RetryPolicy(
          initialDelay: Duration(milliseconds: 10),
        );
        var callCount = 0;

        await expectLater(
          policy.retryWithBackoff(() async {
            callCount++;
            throw const SocketException('Connection failed');
          }),
          throwsA(isA<SocketException>()),
        );

        expect(callCount, 3);
      });

      test('does not retry non-retryable errors', () async {
        const policy = RetryPolicy.defaults;
        var callCount = 0;

        await expectLater(
          policy.retryWithBackoff(() async {
            callCount++;
            throw const FormatException('Invalid format');
          }),
          throwsA(isA<FormatException>()),
        );

        expect(callCount, 1);
      });

      test('retries StreamException with isRetryable flag', () async {
        const policy = RetryPolicy(
          initialDelay: Duration(milliseconds: 10),
        );
        var callCount = 0;

        final result = await policy.retryWithBackoff(() async {
          callCount++;
          if (callCount < 2) {
            throw const StreamException('Rate limited', isRetryable: true);
          }
          return 'success';
        });

        expect(result, 'success');
        expect(callCount, 2);
      });

      test('does not retry StreamException without isRetryable flag', () async {
        const policy = RetryPolicy.defaults;
        var callCount = 0;

        await expectLater(
          policy.retryWithBackoff(() async {
            callCount++;
            throw const StreamException('Permanent error');
          }),
          throwsA(isA<StreamException>()),
        );

        expect(callCount, 1);
      });
    });
  });
}
