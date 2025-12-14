import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui_anthropic/src/metrics/metrics_event.dart';
import 'package:genui_anthropic/src/resilience/circuit_breaker.dart';

/// Collects and streams metrics events for monitoring and observability.
///
/// The [MetricsCollector] provides a centralized way to collect metrics
/// from various components (handlers, circuit breakers, retry logic) and
/// expose them through a stream for external monitoring systems.
///
/// ## Usage
///
/// ```dart
/// // Create a collector
/// final collector = MetricsCollector();
///
/// // Listen to metrics events
/// collector.eventStream.listen((event) {
///   // Send to your monitoring system
///   analytics.track(event.eventType, event.toMap());
/// });
///
/// // Inject into handlers
/// final handler = ProxyModeHandler(
///   endpoint: Uri.parse('https://api.example.com'),
///   metricsCollector: collector,
/// );
///
/// // Access aggregated statistics
/// print('Success rate: ${collector.stats.successRate}%');
/// print('Avg latency: ${collector.stats.averageLatencyMs}ms');
/// ```
///
/// ## Integration with Monitoring Systems
///
/// The collector is designed to integrate with various monitoring backends:
///
/// ```dart
/// // DataDog
/// collector.eventStream.listen((event) {
///   datadog.trackEvent(event.eventType, event.toMap());
/// });
///
/// // Firebase Analytics
/// collector.eventStream.listen((event) {
///   FirebaseAnalytics.instance.logEvent(
///     name: event.eventType,
///     parameters: event.toMap(),
///   );
/// });
///
/// // Custom logging
/// collector.eventStream.listen((event) {
///   logger.info('Metrics: ${event.toMap()}');
/// });
/// ```
class MetricsCollector {
  /// Creates a metrics collector.
  ///
  /// Set [enabled] to false to disable metrics collection entirely.
  /// This is useful for reducing overhead in performance-critical scenarios.
  MetricsCollector({
    this.enabled = true,
    this.aggregationEnabled = true,
  });

  /// Whether metrics collection is enabled.
  final bool enabled;

  /// Whether to maintain aggregated statistics.
  final bool aggregationEnabled;

  final _eventController = StreamController<MetricsEvent>.broadcast();
  final _stats = _MetricsStats();

  /// Stream of metrics events.
  ///
  /// Subscribe to this stream to receive all metrics events as they occur.
  /// The stream is broadcast, so multiple listeners can subscribe.
  Stream<MetricsEvent> get eventStream => _eventController.stream;

  /// Aggregated statistics from collected metrics.
  MetricsStats get stats => _stats;

  /// Records a circuit breaker state change.
  void recordCircuitBreakerStateChange({
    required String circuitName,
    required CircuitState previousState,
    required CircuitState newState,
    int? failureCount,
    String? requestId,
  }) {
    if (!enabled) return;

    final event = CircuitBreakerStateChangeEvent(
      timestamp: DateTime.now(),
      circuitName: circuitName,
      previousState: previousState,
      newState: newState,
      failureCount: failureCount,
      requestId: requestId,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._circuitBreakerEvents++;
      if (newState == CircuitState.open) {
        _stats._circuitBreakerOpens++;
      }
    }
  }

  /// Records a retry attempt.
  void recordRetryAttempt({
    required int attempt,
    required int maxAttempts,
    required Duration delay,
    required String reason,
    int? statusCode,
    String? requestId,
  }) {
    if (!enabled) return;

    final event = RetryAttemptEvent(
      timestamp: DateTime.now(),
      attempt: attempt,
      maxAttempts: maxAttempts,
      delayMs: delay.inMilliseconds,
      reason: reason,
      statusCode: statusCode,
      requestId: requestId,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._totalRetries++;
    }
  }

  /// Records a request start.
  void recordRequestStart({
    required String requestId,
    required String endpoint,
    String? model,
  }) {
    if (!enabled) return;

    final event = RequestStartEvent(
      timestamp: DateTime.now(),
      requestId: requestId,
      endpoint: endpoint,
      model: model,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._totalRequests++;
      _stats._activeRequests++;
      _stats._requestStartTimes[requestId] = DateTime.now();
    }
  }

  /// Records a successful request.
  void recordRequestSuccess({
    required String requestId,
    required Duration duration,
    int? totalRetries,
    Duration? firstTokenLatency,
    int? tokensReceived,
  }) {
    if (!enabled) return;

    final event = RequestSuccessEvent(
      timestamp: DateTime.now(),
      requestId: requestId,
      durationMs: duration.inMilliseconds,
      totalRetries: totalRetries,
      firstTokenMs: firstTokenLatency?.inMilliseconds,
      tokensReceived: tokensReceived,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._successfulRequests++;
      _stats._activeRequests--;
      _stats._requestStartTimes.remove(requestId);
      _stats._recordLatency(duration.inMilliseconds);
    }
  }

  /// Records a failed request.
  void recordRequestFailure({
    required String requestId,
    required Duration duration,
    required String errorType,
    required String errorMessage,
    int? statusCode,
    int? totalRetries,
    bool? isRetryable,
  }) {
    if (!enabled) return;

    final event = RequestFailureEvent(
      timestamp: DateTime.now(),
      requestId: requestId,
      durationMs: duration.inMilliseconds,
      errorType: errorType,
      errorMessage: errorMessage,
      statusCode: statusCode,
      totalRetries: totalRetries,
      isRetryable: isRetryable,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._failedRequests++;
      _stats._activeRequests--;
      _stats._requestStartTimes.remove(requestId);
      _stats._recordLatency(duration.inMilliseconds);
    }
  }

  /// Records a rate limit event.
  void recordRateLimit({
    Duration? retryAfter,
    String? retryAfterHeader,
    String? requestId,
  }) {
    if (!enabled) return;

    final event = RateLimitEvent(
      timestamp: DateTime.now(),
      retryAfterMs: retryAfter?.inMilliseconds,
      retryAfterHeader: retryAfterHeader,
      requestId: requestId,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._rateLimitEvents++;
    }
  }

  /// Records a latency measurement.
  void recordLatency({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? requestId,
  }) {
    if (!enabled) return;

    final event = LatencyEvent(
      timestamp: DateTime.now(),
      operation: operation,
      durationMs: duration.inMilliseconds,
      metadata: metadata,
      requestId: requestId,
    );

    _emit(event);
  }

  /// Records a stream inactivity event.
  void recordStreamInactivity({
    required Duration timeout,
    required Duration lastActivity,
    String? requestId,
  }) {
    if (!enabled) return;

    final event = StreamInactivityEvent(
      timestamp: DateTime.now(),
      timeoutMs: timeout.inMilliseconds,
      lastActivityMs: lastActivity.inMilliseconds,
      requestId: requestId,
    );

    _emit(event);

    if (aggregationEnabled) {
      _stats._streamInactivityEvents++;
    }
  }

  /// Resets all aggregated statistics.
  void resetStats() {
    _stats._reset();
  }

  /// Disposes of the collector and closes the event stream.
  void dispose() {
    _eventController.close();
  }

  void _emit(MetricsEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
}

/// Aggregated metrics statistics.
///
/// Provides summary statistics from collected metrics events.
/// Access via [MetricsCollector.stats].
abstract class MetricsStats {
  /// Total number of requests started.
  int get totalRequests;

  /// Number of currently active requests.
  int get activeRequests;

  /// Number of successful requests.
  int get successfulRequests;

  /// Number of failed requests.
  int get failedRequests;

  /// Total number of retry attempts.
  int get totalRetries;

  /// Number of rate limit events.
  int get rateLimitEvents;

  /// Number of circuit breaker state change events.
  int get circuitBreakerEvents;

  /// Number of times circuit breaker opened.
  int get circuitBreakerOpens;

  /// Number of stream inactivity events.
  int get streamInactivityEvents;

  /// Success rate as a percentage (0-100).
  double get successRate;

  /// Average latency in milliseconds.
  double get averageLatencyMs;

  /// 50th percentile (median) latency in milliseconds.
  int get p50LatencyMs;

  /// 95th percentile latency in milliseconds.
  int get p95LatencyMs;

  /// 99th percentile latency in milliseconds.
  int get p99LatencyMs;

  /// Converts statistics to a map.
  Map<String, dynamic> toMap();
}

class _MetricsStats implements MetricsStats {
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _totalRetries = 0;
  int _rateLimitEvents = 0;
  int _circuitBreakerEvents = 0;
  int _circuitBreakerOpens = 0;
  int _streamInactivityEvents = 0;

  final List<int> _latencies = [];
  final Map<String, DateTime> _requestStartTimes = {};

  // Keep last 1000 latencies for percentile calculation
  static const _maxLatencies = 1000;

  void _recordLatency(int latencyMs) {
    _latencies.add(latencyMs);
    if (_latencies.length > _maxLatencies) {
      _latencies.removeAt(0);
    }
  }

  void _reset() {
    _totalRequests = 0;
    _activeRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
    _totalRetries = 0;
    _rateLimitEvents = 0;
    _circuitBreakerEvents = 0;
    _circuitBreakerOpens = 0;
    _streamInactivityEvents = 0;
    _latencies.clear();
    _requestStartTimes.clear();
  }

  @override
  int get totalRequests => _totalRequests;

  @override
  int get activeRequests => _activeRequests;

  @override
  int get successfulRequests => _successfulRequests;

  @override
  int get failedRequests => _failedRequests;

  @override
  int get totalRetries => _totalRetries;

  @override
  int get rateLimitEvents => _rateLimitEvents;

  @override
  int get circuitBreakerEvents => _circuitBreakerEvents;

  @override
  int get circuitBreakerOpens => _circuitBreakerOpens;

  @override
  int get streamInactivityEvents => _streamInactivityEvents;

  @override
  double get successRate {
    final completed = _successfulRequests + _failedRequests;
    if (completed == 0) return 100;
    return (_successfulRequests / completed) * 100;
  }

  @override
  double get averageLatencyMs {
    if (_latencies.isEmpty) return 0;
    return _latencies.reduce((a, b) => a + b) / _latencies.length;
  }

  @override
  int get p50LatencyMs => _percentile(50);

  @override
  int get p95LatencyMs => _percentile(95);

  @override
  int get p99LatencyMs => _percentile(99);

  int _percentile(int p) {
    if (_latencies.isEmpty) return 0;
    final sorted = List<int>.from(_latencies)..sort();
    final index = ((p / 100) * (sorted.length - 1)).round();
    return sorted[index];
  }

  @override
  Map<String, dynamic> toMap() => {
        'total_requests': _totalRequests,
        'active_requests': _activeRequests,
        'successful_requests': _successfulRequests,
        'failed_requests': _failedRequests,
        'total_retries': _totalRetries,
        'rate_limit_events': _rateLimitEvents,
        'circuit_breaker_events': _circuitBreakerEvents,
        'circuit_breaker_opens': _circuitBreakerOpens,
        'stream_inactivity_events': _streamInactivityEvents,
        'success_rate': successRate,
        'average_latency_ms': averageLatencyMs,
        'p50_latency_ms': p50LatencyMs,
        'p95_latency_ms': p95LatencyMs,
        'p99_latency_ms': p99LatencyMs,
      };
}

/// Global metrics collector instance.
///
/// Use this for convenience when you don't need multiple collectors.
/// For testing or isolated metrics, create a new [MetricsCollector] instance.
///
/// Example:
/// ```dart
/// // Enable global metrics
/// globalMetricsCollector.eventStream.listen((event) {
///   print('Metrics: ${event.toMap()}');
/// });
///
/// // Access stats
/// print('Success rate: ${globalMetricsCollector.stats.successRate}%');
/// ```
@visibleForTesting
MetricsCollector? testMetricsCollector;

/// The global metrics collector instance.
///
/// Returns the test collector if set, otherwise returns the default instance.
MetricsCollector get globalMetricsCollector =>
    testMetricsCollector ?? _defaultCollector;

final _defaultCollector = MetricsCollector();
