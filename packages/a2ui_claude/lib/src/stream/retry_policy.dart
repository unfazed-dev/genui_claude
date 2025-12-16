import 'dart:async';
import 'dart:io';

import 'package:a2ui_claude/src/exceptions/exceptions.dart';

/// Configures retry behavior for failed requests.
class RetryPolicy {

  /// Creates a retry policy.
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Initial delay before first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Default retry policy.
  static const RetryPolicy defaults = RetryPolicy();

  /// Determines if an error should trigger a retry.
  bool shouldRetry(Exception error, int attempt) {
    if (attempt >= maxAttempts) return false;

    if (error is StreamException) {
      return error.isRetryable;
    }

    // Retry network-related errors using proper type checking
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException;
  }

  /// Calculates the delay before the next retry attempt.
  Duration getDelay(int attempt) {
    final delay = initialDelay * (backoffMultiplier * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Executes a function with retry logic.
  Future<T> retryWithBackoff<T>(Future<T> Function() operation) async {
    var attempt = 0;
    while (true) {
      try {
        return await operation();
      } on Exception catch (e) {
        attempt++;
        if (!shouldRetry(e, attempt)) {
          rethrow;
        }
        await Future<void>.delayed(getDelay(attempt));
      }
    }
  }
}
