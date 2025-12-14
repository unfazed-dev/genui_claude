/// Custom exception hierarchy for Anthropic API operations.
///
/// Provides structured error handling with categorized exceptions
/// for different failure modes, enabling appropriate retry and
/// error handling strategies.
library;

/// Base exception for all Anthropic API errors.
///
/// Provides common properties for error context and debugging.
sealed class AnthropicException implements Exception {
  const AnthropicException({
    required this.message,
    this.requestId,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error message.
  final String message;

  /// Request ID for tracking and debugging.
  final String? requestId;

  /// HTTP status code if applicable.
  final int? statusCode;

  /// The original error that caused this exception.
  final Object? originalError;

  /// Stack trace from the original error.
  final StackTrace? stackTrace;

  /// Whether this error is potentially recoverable with retry.
  bool get isRetryable;

  /// Returns the exception type name for display.
  String get typeName;

  @override
  String toString() {
    final buffer = StringBuffer('$typeName: $message');
    if (requestId != null) buffer.write(' [requestId: $requestId]');
    if (statusCode != null) buffer.write(' [status: $statusCode]');
    return buffer.toString();
  }
}

/// Exception for network-related failures.
///
/// Includes DNS failures, connection refused, socket errors, etc.
/// These are typically retryable after a delay.
final class NetworkException extends AnthropicException {
  const NetworkException({
    required super.message,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(statusCode: null);

  @override
  bool get isRetryable => true;

  @override
  String get typeName => 'NetworkException';
}

/// Exception for request timeout.
///
/// The request took longer than the configured timeout.
/// May be retryable depending on the operation.
final class TimeoutException extends AnthropicException {
  const TimeoutException({
    required super.message,
    required this.timeout,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(statusCode: null);

  /// The timeout duration that was exceeded.
  final Duration timeout;

  @override
  bool get isRetryable => true;

  @override
  String get typeName => 'TimeoutException';
}

/// Exception for authentication/authorization failures.
///
/// HTTP 401 (Unauthorized) or 403 (Forbidden).
/// Not retryable without credential changes.
final class AuthenticationException extends AnthropicException {
  const AuthenticationException({
    required super.message,
    required int super.statusCode,
    super.requestId,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get typeName => 'AuthenticationException';
}

/// Exception for rate limit exceeded.
///
/// HTTP 429 (Too Many Requests).
/// Retryable after waiting for the specified delay.
final class RateLimitException extends AnthropicException {
  const RateLimitException({
    required super.message,
    super.requestId,
    super.originalError,
    super.stackTrace,
    this.retryAfter,
  }) : super(statusCode: 429);

  /// Suggested wait time before retrying.
  ///
  /// Parsed from the Retry-After header if present.
  final Duration? retryAfter;

  @override
  bool get isRetryable => true;

  @override
  String get typeName => 'RateLimitException';
}

/// Exception for validation errors in the request.
///
/// HTTP 400 (Bad Request) or similar client errors.
/// Not retryable without changing the request.
final class ValidationException extends AnthropicException {
  const ValidationException({
    required super.message,
    required int super.statusCode,
    super.requestId,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get typeName => 'ValidationException';
}

/// Exception for server-side errors.
///
/// HTTP 5xx errors (500, 502, 503, 504).
/// Typically retryable after a delay.
final class ServerException extends AnthropicException {
  const ServerException({
    required super.message,
    required int super.statusCode,
    super.requestId,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  String get typeName => 'ServerException';
}

/// Exception for stream processing errors.
///
/// Errors during SSE parsing or stream handling.
/// May be retryable depending on the cause.
final class StreamException extends AnthropicException {
  const StreamException({
    required super.message,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(statusCode: null);

  @override
  bool get isRetryable => false;

  @override
  String get typeName => 'StreamException';
}

/// Exception when the circuit breaker is open.
///
/// The circuit breaker has tripped due to repeated failures.
/// Retryable after the circuit breaker recovery period.
final class CircuitBreakerOpenException extends AnthropicException {
  const CircuitBreakerOpenException({
    required super.message,
    super.requestId,
    this.recoveryTime,
  }) : super(statusCode: null);

  /// When the circuit breaker will attempt recovery.
  final DateTime? recoveryTime;

  @override
  bool get isRetryable => true;

  @override
  String get typeName => 'CircuitBreakerOpenException';
}

/// Factory for creating appropriate exceptions from HTTP responses.
///
/// Provides static methods for creating exceptions from HTTP responses
/// and parsing retry-after headers.
class ExceptionFactory {
  // Private constructor to prevent instantiation
  const ExceptionFactory._();

  /// Creates an appropriate exception based on HTTP status code.
  static AnthropicException fromHttpStatus({
    required int statusCode,
    required String body,
    String? requestId,
    Duration? retryAfter,
  }) {
    return switch (statusCode) {
      401 || 403 => AuthenticationException(
          message: 'Authentication failed: $body',
          statusCode: statusCode,
          requestId: requestId,
        ),
      429 => RateLimitException(
          message: 'Rate limit exceeded: $body',
          requestId: requestId,
          retryAfter: retryAfter,
        ),
      400 || 422 => ValidationException(
          message: 'Validation error: $body',
          statusCode: statusCode,
          requestId: requestId,
        ),
      >= 500 && < 600 => ServerException(
          message: 'Server error: $body',
          statusCode: statusCode,
          requestId: requestId,
        ),
      _ => ValidationException(
          message: 'HTTP $statusCode: $body',
          statusCode: statusCode,
          requestId: requestId,
        ),
    };
  }

  /// Parses Retry-After header value to Duration.
  ///
  /// Supports both seconds (integer) and HTTP-date formats.
  static Duration? parseRetryAfter(String? value) {
    if (value == null || value.isEmpty) return null;

    // Try parsing as seconds
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    // Try parsing as HTTP-date (RFC 7231)
    try {
      final date = DateTime.parse(value);
      final delay = date.difference(DateTime.now());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    }
  }
}
