import 'dart:math';

import 'package:flutter/foundation.dart';

/// Configuration for retry behavior with exponential backoff.
///
/// Provides customizable retry logic for transient failures,
/// with support for exponential backoff and jitter.
@immutable
class RetryConfig {
  /// Creates a retry configuration.
  ///
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay before first retry (default: 1 second)
  /// - [maxDelay]: Maximum delay between retries (default: 30 seconds)
  /// - [backoffMultiplier]: Multiplier for exponential backoff (default: 2.0)
  /// - [jitterFactor]: Random jitter factor 0.0-1.0 (default: 0.1)
  /// - [retryableStatusCodes]: HTTP status codes that should trigger retry
  ///
  /// Throws [AssertionError] if:
  /// - [maxAttempts] is negative
  /// - [backoffMultiplier] is less than 1.0
  /// - [jitterFactor] is not between 0.0 and 1.0
  ///
  /// Note: Duration values ([initialDelay], [maxDelay]) cannot be validated
  /// at construction time due to const constructor constraints.
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.retryableStatusCodes = defaultRetryableStatusCodes,
  })  : assert(maxAttempts >= 0, 'maxAttempts cannot be negative'),
        assert(backoffMultiplier >= 1.0, 'backoffMultiplier must be at least 1.0'),
        assert(jitterFactor >= 0.0, 'jitterFactor cannot be negative'),
        assert(jitterFactor <= 1.0, 'jitterFactor cannot be greater than 1.0');

  /// Maximum number of retry attempts.
  ///
  /// A value of 3 means up to 4 total attempts (1 initial + 3 retries).
  final int maxAttempts;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  ///
  /// The exponential backoff will not exceed this value.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  ///
  /// Each retry delay is multiplied by this factor.
  /// For example, with multiplier 2.0 and initial delay 1s:
  /// - 1st retry: 1s
  /// - 2nd retry: 2s
  /// - 3rd retry: 4s
  final double backoffMultiplier;

  /// Random jitter factor (0.0-1.0).
  ///
  /// Adds randomness to prevent thundering herd problem.
  /// A value of 0.1 means ±10% variation.
  final double jitterFactor;

  /// HTTP status codes that should trigger a retry.
  final Set<int> retryableStatusCodes;

  /// Default retryable HTTP status codes.
  ///
  /// Includes:
  /// - 429: Too Many Requests (rate limited)
  /// - 500: Internal Server Error
  /// - 502: Bad Gateway
  /// - 503: Service Unavailable
  /// - 504: Gateway Timeout
  static const Set<int> defaultRetryableStatusCodes = {429, 500, 502, 503, 504};

  /// Default configuration.
  static const RetryConfig defaults = RetryConfig();

  /// No retries configuration.
  static const RetryConfig noRetry = RetryConfig(maxAttempts: 0);

  /// Aggressive retry configuration for critical operations.
  static const RetryConfig aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 60),
    backoffMultiplier: 1.5,
  );

  /// Calculates the delay for a given attempt number.
  ///
  /// Uses exponential backoff with optional jitter.
  /// [attempt] is 0-indexed (0 = first retry).
  Duration getDelayForAttempt(int attempt, [Random? random]) {
    if (attempt < 0) return Duration.zero;

    // Calculate base delay with exponential backoff
    final baseDelayMs =
        initialDelay.inMilliseconds * pow(backoffMultiplier, attempt);

    // Cap at max delay
    final cappedDelayMs = min(baseDelayMs, maxDelay.inMilliseconds);

    // Add jitter
    if (jitterFactor > 0) {
      final rand = random ?? Random();
      final jitterRange = cappedDelayMs * jitterFactor;
      final jitter = (rand.nextDouble() * 2 - 1) * jitterRange;
      return Duration(milliseconds: (cappedDelayMs + jitter).round());
    }

    return Duration(milliseconds: cappedDelayMs.round());
  }

  /// Checks if a status code should trigger a retry.
  bool shouldRetryStatusCode(int statusCode) {
    return retryableStatusCodes.contains(statusCode);
  }

  /// Creates a copy with the given fields replaced.
  RetryConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    double? jitterFactor,
    Set<int>? retryableStatusCodes,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      jitterFactor: jitterFactor ?? this.jitterFactor,
      retryableStatusCodes: retryableStatusCodes ?? this.retryableStatusCodes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetryConfig &&
        other.maxAttempts == maxAttempts &&
        other.initialDelay == initialDelay &&
        other.maxDelay == maxDelay &&
        other.backoffMultiplier == backoffMultiplier &&
        other.jitterFactor == jitterFactor &&
        setEquals(other.retryableStatusCodes, retryableStatusCodes);
  }

  @override
  int get hashCode {
    return Object.hash(
      maxAttempts,
      initialDelay,
      maxDelay,
      backoffMultiplier,
      jitterFactor,
      Object.hashAll(retryableStatusCodes),
    );
  }
}
