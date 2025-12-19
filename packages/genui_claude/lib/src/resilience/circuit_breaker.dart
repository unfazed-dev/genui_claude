import 'package:flutter/foundation.dart';
import 'package:genui_claude/src/exceptions/claude_exceptions.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:logging/logging.dart';

final _log = Logger('CircuitBreaker');

/// Circuit breaker states.
enum CircuitState {
  /// Circuit is closed (normal operation).
  closed,

  /// Circuit is open (failing fast).
  open,

  /// Circuit is half-open (testing recovery).
  halfOpen,
}

/// Configuration for circuit breaker behavior.
@immutable
class CircuitBreakerConfig {
  /// Creates a circuit breaker configuration.
  ///
  /// Throws [AssertionError] if:
  /// - [failureThreshold] is less than 1
  /// - [halfOpenSuccessThreshold] is less than 1
  ///
  /// Note: [recoveryTimeout] cannot be validated at construction time due to
  /// const constructor constraints.
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(seconds: 30),
    this.halfOpenSuccessThreshold = 2,
  })  : assert(failureThreshold > 0, 'failureThreshold must be at least 1'),
        assert(halfOpenSuccessThreshold > 0,
            'halfOpenSuccessThreshold must be at least 1',);

  /// Number of failures before opening the circuit.
  final int failureThreshold;

  /// Time to wait before attempting recovery (half-open).
  final Duration recoveryTimeout;

  /// Number of successes in half-open state before closing.
  final int halfOpenSuccessThreshold;

  /// Default configuration.
  static const CircuitBreakerConfig defaults = CircuitBreakerConfig();

  /// Lenient configuration with higher thresholds.
  static const CircuitBreakerConfig lenient = CircuitBreakerConfig(
    failureThreshold: 10,
    recoveryTimeout: Duration(seconds: 60),
    halfOpenSuccessThreshold: 3,
  );

  /// Strict configuration with lower thresholds.
  static const CircuitBreakerConfig strict = CircuitBreakerConfig(
    failureThreshold: 3,
    recoveryTimeout: Duration(seconds: 15),
    halfOpenSuccessThreshold: 1,
  );

  /// Creates a copy with the given fields replaced.
  CircuitBreakerConfig copyWith({
    int? failureThreshold,
    Duration? recoveryTimeout,
    int? halfOpenSuccessThreshold,
  }) {
    return CircuitBreakerConfig(
      failureThreshold: failureThreshold ?? this.failureThreshold,
      recoveryTimeout: recoveryTimeout ?? this.recoveryTimeout,
      halfOpenSuccessThreshold:
          halfOpenSuccessThreshold ?? this.halfOpenSuccessThreshold,
    );
  }
}

/// Circuit breaker for preventing cascading failures.
///
/// Implements the circuit breaker pattern to fail fast when
/// a service is unavailable, preventing resource exhaustion.
///
/// States:
/// - **Closed**: Normal operation, requests pass through
/// - **Open**: Failing fast, requests are rejected immediately
/// - **Half-Open**: Testing recovery, limited requests allowed
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker();
///
/// try {
///   breaker.checkState(); // Throws if open
///   final result = await makeRequest();
///   breaker.recordSuccess();
///   return result;
/// } catch (e) {
///   breaker.recordFailure();
///   rethrow;
/// }
/// ```
///
/// With metrics:
/// ```dart
/// final breaker = CircuitBreaker(
///   metricsCollector: globalMetricsCollector,
/// );
/// ```
class CircuitBreaker {
  /// Creates a circuit breaker with the given configuration.
  CircuitBreaker({
    CircuitBreakerConfig config = CircuitBreakerConfig.defaults,
    this.name = 'default',
    MetricsCollector? metricsCollector,
  })  : _config = config,
        _metricsCollector = metricsCollector;

  final CircuitBreakerConfig _config;
  final MetricsCollector? _metricsCollector;

  /// Name for logging and identification.
  final String name;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _halfOpenSuccessCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _openedAt;

  /// Current circuit state.
  CircuitState get state => _state;

  /// Current failure count.
  int get failureCount => _failureCount;

  /// Time of the last recorded failure.
  DateTime? get lastFailureTime => _lastFailureTime;

  /// Whether the circuit allows requests.
  bool get allowsRequest {
    _updateStateIfNeeded();
    return _state != CircuitState.open;
  }

  /// Checks if request is allowed, throws if circuit is open.
  ///
  /// Throws [CircuitBreakerOpenException] if the circuit is open.
  void checkState() {
    _updateStateIfNeeded();

    if (_state == CircuitState.open) {
      final recoveryTime = _openedAt?.add(_config.recoveryTimeout);
      throw CircuitBreakerOpenException(
        message: 'Circuit breaker [$name] is open',
        recoveryTime: recoveryTime,
      );
    }
  }

  /// Records a successful operation.
  ///
  /// In half-open state, increments success count.
  /// After enough successes, closes the circuit.
  void recordSuccess() {
    switch (_state) {
      case CircuitState.closed:
        // Reset failure count on success
        _failureCount = 0;
      case CircuitState.halfOpen:
        _halfOpenSuccessCount++;
        _log.fine(
          '[$name] Half-open success $_halfOpenSuccessCount/${_config.halfOpenSuccessThreshold}',
        );
        if (_halfOpenSuccessCount >= _config.halfOpenSuccessThreshold) {
          _close();
        }
      case CircuitState.open:
        // Shouldn't happen, but handle gracefully
        _log.warning('[$name] Success recorded while open');
    }
  }

  /// Records a failed operation.
  ///
  /// Increments failure count. If threshold is reached,
  /// opens the circuit.
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    switch (_state) {
      case CircuitState.closed:
        if (_failureCount >= _config.failureThreshold) {
          _open();
        } else {
          _log.fine(
            '[$name] Failure $_failureCount/${_config.failureThreshold}',
          );
        }
      case CircuitState.halfOpen:
        // Any failure in half-open state reopens the circuit
        _log.info('[$name] Failure in half-open state, reopening');
        _open();
      case CircuitState.open:
        // Already open, just update timestamp
        break;
    }
  }

  /// Manually resets the circuit breaker to closed state.
  void reset() {
    _log.info('[$name] Circuit manually reset');
    _state = CircuitState.closed;
    _failureCount = 0;
    _halfOpenSuccessCount = 0;
    _lastFailureTime = null;
    _openedAt = null;
  }

  /// Updates state based on time elapsed.
  void _updateStateIfNeeded() {
    if (_state == CircuitState.open && _openedAt != null) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= _config.recoveryTimeout) {
        _halfOpen();
      }
    }
  }

  void _open() {
    final previousState = _state;
    _log.warning('[$name] Circuit opened after $_failureCount failures');
    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _halfOpenSuccessCount = 0;
    _emitStateChangeMetric(previousState, CircuitState.open);
  }

  void _halfOpen() {
    final previousState = _state;
    _log.info('[$name] Circuit entering half-open state');
    _state = CircuitState.halfOpen;
    _halfOpenSuccessCount = 0;
    _emitStateChangeMetric(previousState, CircuitState.halfOpen);
  }

  void _close() {
    final previousState = _state;
    _log.info('[$name] Circuit closed after successful recovery');
    _state = CircuitState.closed;
    _failureCount = 0;
    _halfOpenSuccessCount = 0;
    _openedAt = null;
    _emitStateChangeMetric(previousState, CircuitState.closed);
  }

  void _emitStateChangeMetric(CircuitState previous, CircuitState current) {
    _metricsCollector?.recordCircuitBreakerStateChange(
      circuitName: name,
      previousState: previous,
      newState: current,
      failureCount: _failureCount,
    );
  }
}
