import 'package:flutter/foundation.dart';
import 'package:genui_anthropic/src/resilience/circuit_breaker.dart';

/// Base class for all metrics events.
///
/// All metrics events share common properties for tracking and correlation.
@immutable
sealed class MetricsEvent {
  /// Creates a metrics event.
  const MetricsEvent({
    required this.timestamp,
    this.requestId,
  });

  /// When this event occurred.
  final DateTime timestamp;

  /// Optional request ID for correlation.
  final String? requestId;

  /// Event type name for serialization/logging.
  String get eventType;

  /// Converts the event to a map for logging/serialization.
  Map<String, dynamic> toMap();
}

// =============================================================================
// Circuit Breaker Events
// =============================================================================

/// Emitted when the circuit breaker changes state.
@immutable
class CircuitBreakerStateChangeEvent extends MetricsEvent {
  /// Creates a circuit breaker state change event.
  const CircuitBreakerStateChangeEvent({
    required super.timestamp,
    required this.circuitName, required this.previousState, required this.newState, super.requestId,
    this.failureCount,
  });

  /// Name of the circuit breaker.
  final String circuitName;

  /// Previous state before the change.
  final CircuitState previousState;

  /// New state after the change.
  final CircuitState newState;

  /// Current failure count (if applicable).
  final int? failureCount;

  @override
  String get eventType => 'circuit_breaker_state_change';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        if (requestId != null) 'request_id': requestId,
        'circuit_name': circuitName,
        'previous_state': previousState.name,
        'new_state': newState.name,
        if (failureCount != null) 'failure_count': failureCount,
      };
}

// =============================================================================
// Retry Events
// =============================================================================

/// Emitted when a retry attempt is made.
@immutable
class RetryAttemptEvent extends MetricsEvent {
  /// Creates a retry attempt event.
  const RetryAttemptEvent({
    required super.timestamp,
    required this.attempt, required this.maxAttempts, required this.delayMs, required this.reason, super.requestId,
    this.statusCode,
  });

  /// Current attempt number (0-indexed).
  final int attempt;

  /// Maximum number of attempts configured.
  final int maxAttempts;

  /// Delay before this retry in milliseconds.
  final int delayMs;

  /// Reason for the retry.
  final String reason;

  /// HTTP status code that triggered the retry (if applicable).
  final int? statusCode;

  @override
  String get eventType => 'retry_attempt';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        if (requestId != null) 'request_id': requestId,
        'attempt': attempt,
        'max_attempts': maxAttempts,
        'delay_ms': delayMs,
        'reason': reason,
        if (statusCode != null) 'status_code': statusCode,
      };
}

// =============================================================================
// Request Lifecycle Events
// =============================================================================

/// Emitted when a request starts.
@immutable
class RequestStartEvent extends MetricsEvent {
  /// Creates a request start event.
  const RequestStartEvent({
    required super.timestamp,
    required super.requestId,
    required this.endpoint,
    this.model,
  });

  /// The endpoint being called.
  final String endpoint;

  /// The model being used (if known).
  final String? model;

  @override
  String get eventType => 'request_start';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        'request_id': requestId,
        'endpoint': endpoint,
        if (model != null) 'model': model,
      };
}

/// Emitted when a request completes successfully.
@immutable
class RequestSuccessEvent extends MetricsEvent {
  /// Creates a request success event.
  const RequestSuccessEvent({
    required super.timestamp,
    required super.requestId,
    required this.durationMs,
    this.totalRetries,
    this.firstTokenMs,
    this.tokensReceived,
  });

  /// Total duration of the request in milliseconds.
  final int durationMs;

  /// Total number of retries that occurred.
  final int? totalRetries;

  /// Time to first token in milliseconds (for streaming).
  final int? firstTokenMs;

  /// Total tokens received (if known).
  final int? tokensReceived;

  @override
  String get eventType => 'request_success';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        'request_id': requestId,
        'duration_ms': durationMs,
        if (totalRetries != null) 'total_retries': totalRetries,
        if (firstTokenMs != null) 'first_token_ms': firstTokenMs,
        if (tokensReceived != null) 'tokens_received': tokensReceived,
      };
}

/// Emitted when a request fails.
@immutable
class RequestFailureEvent extends MetricsEvent {
  /// Creates a request failure event.
  const RequestFailureEvent({
    required super.timestamp,
    required super.requestId,
    required this.durationMs,
    required this.errorType,
    required this.errorMessage,
    this.statusCode,
    this.totalRetries,
    this.isRetryable,
  });

  /// Total duration before failure in milliseconds.
  final int durationMs;

  /// Type of error that occurred.
  final String errorType;

  /// Error message.
  final String errorMessage;

  /// HTTP status code (if applicable).
  final int? statusCode;

  /// Total retries attempted before failure.
  final int? totalRetries;

  /// Whether the error was retryable.
  final bool? isRetryable;

  @override
  String get eventType => 'request_failure';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        'request_id': requestId,
        'duration_ms': durationMs,
        'error_type': errorType,
        'error_message': errorMessage,
        if (statusCode != null) 'status_code': statusCode,
        if (totalRetries != null) 'total_retries': totalRetries,
        if (isRetryable != null) 'is_retryable': isRetryable,
      };
}

// =============================================================================
// Rate Limit Events
// =============================================================================

/// Emitted when rate limiting is encountered.
@immutable
class RateLimitEvent extends MetricsEvent {
  /// Creates a rate limit event.
  const RateLimitEvent({
    required super.timestamp,
    super.requestId,
    this.retryAfterMs,
    this.retryAfterHeader,
  });

  /// Time to wait before retrying in milliseconds.
  final int? retryAfterMs;

  /// Raw Retry-After header value.
  final String? retryAfterHeader;

  @override
  String get eventType => 'rate_limit';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        if (requestId != null) 'request_id': requestId,
        if (retryAfterMs != null) 'retry_after_ms': retryAfterMs,
        if (retryAfterHeader != null) 'retry_after_header': retryAfterHeader,
      };
}

// =============================================================================
// Latency Events
// =============================================================================

/// Emitted to record latency measurements.
@immutable
class LatencyEvent extends MetricsEvent {
  /// Creates a latency event.
  const LatencyEvent({
    required super.timestamp,
    required this.operation, required this.durationMs, super.requestId,
    this.metadata,
  });

  /// The operation being measured.
  final String operation;

  /// Duration in milliseconds.
  final int durationMs;

  /// Additional metadata about the measurement.
  final Map<String, dynamic>? metadata;

  @override
  String get eventType => 'latency';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        if (requestId != null) 'request_id': requestId,
        'operation': operation,
        'duration_ms': durationMs,
        if (metadata != null) 'metadata': metadata,
      };
}

// =============================================================================
// Stream Events
// =============================================================================

/// Emitted when stream inactivity is detected.
@immutable
class StreamInactivityEvent extends MetricsEvent {
  /// Creates a stream inactivity event.
  const StreamInactivityEvent({
    required super.timestamp,
    required this.timeoutMs, required this.lastActivityMs, super.requestId,
  });

  /// Configured timeout in milliseconds.
  final int timeoutMs;

  /// Time since last activity in milliseconds.
  final int lastActivityMs;

  @override
  String get eventType => 'stream_inactivity';

  @override
  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        if (requestId != null) 'request_id': requestId,
        'timeout_ms': timeoutMs,
        'last_activity_ms': lastActivityMs,
      };
}
