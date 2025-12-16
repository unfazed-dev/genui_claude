#!/usr/bin/env dart
/// Resilience Pattern Tester for GenUI Claude
///
/// Tests circuit breaker behavior, retry logic, and metrics collection
/// with simulated failure scenarios. Useful for understanding how
/// the resilience patterns work before integrating them.
///
/// Usage:
///   dart run .claude/skills/genui-claude/scripts/test_resilience.dart
///
/// Options:
///   --circuit-breaker  Test circuit breaker state transitions
///   --retry            Test exponential backoff retry
///   --rate-limit       Test rate limit handling
///   --metrics          Test metrics event generation
///   --all              Run all tests (default)

import 'dart:async';
import 'dart:io';
import 'dart:math';

/// Circuit breaker states
enum CircuitState { closed, open, halfOpen }

/// Simulates circuit breaker behavior matching genui_claude implementation
class MockCircuitBreaker {
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _halfOpenSuccesses = 0;
  final int failureThreshold;
  final Duration recoveryTimeout;
  final int halfOpenSuccessThreshold;
  DateTime? _openedAt;

  MockCircuitBreaker({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(seconds: 30),
    this.halfOpenSuccessThreshold = 2,
  });

  CircuitState get state => _state;

  void recordSuccess() {
    if (_state == CircuitState.halfOpen) {
      _halfOpenSuccesses++;
      print('  Half-open success: $_halfOpenSuccesses/$halfOpenSuccessThreshold');
      if (_halfOpenSuccesses >= halfOpenSuccessThreshold) {
        _state = CircuitState.closed;
        _failureCount = 0;
        _halfOpenSuccesses = 0;
        print('  Circuit CLOSED after successful recovery');
      }
    } else if (_state == CircuitState.closed) {
      // Reset failure count on success
      _failureCount = 0;
    }
  }

  void recordFailure() {
    _failureCount++;
    if (_state == CircuitState.halfOpen) {
      // Any failure in half-open reopens the circuit
      _state = CircuitState.open;
      _openedAt = DateTime.now();
      _halfOpenSuccesses = 0;
      print('  Circuit REOPENED from half-open state');
    } else if (_failureCount >= failureThreshold && _state == CircuitState.closed) {
      _state = CircuitState.open;
      _openedAt = DateTime.now();
      print('  Circuit OPEN after $_failureCount consecutive failures');
    } else {
      print('  Failure recorded: $_failureCount/$failureThreshold');
    }
  }

  bool canExecute() {
    if (_state == CircuitState.closed) return true;
    if (_state == CircuitState.open) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= recoveryTimeout) {
        _state = CircuitState.halfOpen;
        print('  Circuit HALF-OPEN - testing recovery...');
        return true;
      }
      return false;
    }
    return true; // halfOpen allows requests
  }
}

/// Simulates retry with exponential backoff and jitter
class RetrySimulator {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor;
  final Random _random = Random();

  RetrySimulator({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
  });

  Duration getDelay(int attempt) {
    // Calculate base delay with exponential backoff
    final baseDelayMs = initialDelay.inMilliseconds *
        pow(backoffMultiplier, attempt).toInt();

    // Apply max delay cap
    final cappedDelayMs = baseDelayMs.clamp(0, maxDelay.inMilliseconds);

    // Apply jitter (±jitterFactor)
    final jitterRange = cappedDelayMs * jitterFactor;
    final jitter = (_random.nextDouble() * 2 - 1) * jitterRange;
    final finalDelayMs = (cappedDelayMs + jitter).round();

    return Duration(milliseconds: finalDelayMs);
  }

  Future<bool> executeWithRetry(Future<bool> Function() operation) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        final delay = getDelay(attempt - 1);
        print('  Retry ${attempt + 1}/$maxAttempts after ${delay.inMilliseconds}ms');
        await Future.delayed(Duration(milliseconds: 10)); // Simulated delay
      }

      try {
        final result = await operation();
        if (result) {
          print('  Success on attempt ${attempt + 1}');
          return true;
        }
      } catch (e) {
        print('  Attempt ${attempt + 1} failed: $e');
      }
    }
    return false;
  }
}

/// Metrics event types matching genui_claude implementation
enum MetricEventType {
  requestStart,
  requestSuccess,
  requestFailure,
  retryAttempt,
  rateLimit,
  circuitBreakerStateChange,
  streamInactivity,
}

/// Mock metrics event
class MockMetricsEvent {
  final MetricEventType type;
  final String? requestId;
  final Duration? latency;
  final String? error;
  final int? retryAttempt;
  final Duration? retryAfter;
  final CircuitState? newState;
  final DateTime timestamp;

  MockMetricsEvent({
    required this.type,
    this.requestId,
    this.latency,
    this.error,
    this.retryAttempt,
    this.retryAfter,
    this.newState,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer('${type.name}');
    if (requestId != null) buffer.write(' [requestId: $requestId]');
    if (latency != null) buffer.write(' [latency: ${latency!.inMilliseconds}ms]');
    if (error != null) buffer.write(' [error: $error]');
    if (retryAttempt != null) buffer.write(' [attempt: $retryAttempt]');
    if (retryAfter != null) buffer.write(' [retryAfter: ${retryAfter!.inSeconds}s]');
    if (newState != null) buffer.write(' [state: ${newState!.name}]');
    return buffer.toString();
  }
}

/// Mock metrics collector
class MockMetricsCollector {
  final _events = <MockMetricsEvent>[];
  final _controller = StreamController<MockMetricsEvent>.broadcast();

  Stream<MockMetricsEvent> get eventStream => _controller.stream;
  List<MockMetricsEvent> get events => List.unmodifiable(_events);

  void emit(MockMetricsEvent event) {
    _events.add(event);
    _controller.add(event);
    print('  METRIC: $event');
  }

  Map<String, dynamic> get statistics {
    final successes = _events.where((e) => e.type == MetricEventType.requestSuccess).length;
    final failures = _events.where((e) => e.type == MetricEventType.requestFailure).length;
    final total = successes + failures;
    final retries = _events.where((e) => e.type == MetricEventType.retryAttempt).length;
    final rateLimits = _events.where((e) => e.type == MetricEventType.rateLimit).length;

    final latencies = _events
        .where((e) => e.latency != null)
        .map((e) => e.latency!.inMilliseconds)
        .toList();
    final avgLatency = latencies.isEmpty
        ? 0
        : latencies.reduce((a, b) => a + b) ~/ latencies.length;

    return {
      'totalRequests': total,
      'successes': successes,
      'failures': failures,
      'successRate': total > 0 ? (successes / total * 100).toStringAsFixed(1) : '0.0',
      'retries': retries,
      'rateLimits': rateLimits,
      'avgLatencyMs': avgLatency,
    };
  }

  void dispose() {
    _controller.close();
  }
}

void main(List<String> args) async {
  print('GenUI Claude Resilience Pattern Tester');
  print('==========================================');
  print('');
  print('This script demonstrates the resilience patterns used in genui_claude.');
  print('');

  final runAll = args.isEmpty || args.contains('--all');

  if (runAll || args.contains('--circuit-breaker')) {
    await testCircuitBreaker();
  }

  if (runAll || args.contains('--retry')) {
    await testRetry();
  }

  if (runAll || args.contains('--rate-limit')) {
    await testRateLimit();
  }

  if (runAll || args.contains('--metrics')) {
    await testMetrics();
  }

  print('');
  print('All tests completed.');
  print('');
  print('Available options:');
  print('  --circuit-breaker  Test circuit breaker state transitions');
  print('  --retry            Test exponential backoff retry');
  print('  --rate-limit       Test rate limit handling');
  print('  --metrics          Test metrics event generation');
  print('  --all              Run all tests (default)');
}

Future<void> testCircuitBreaker() async {
  print('');
  print('TEST: Circuit Breaker');
  print('=====================');
  print('');
  print('Circuit breaker prevents cascading failures by fast-failing');
  print('when a service is unhealthy.');
  print('');

  final breaker = MockCircuitBreaker(
    failureThreshold: 3,
    recoveryTimeout: Duration(seconds: 2),
    halfOpenSuccessThreshold: 2,
  );

  print('Configuration:');
  print('  - Failure threshold: 3');
  print('  - Recovery timeout: 2s');
  print('  - Half-open success threshold: 2');
  print('');
  print('Initial state: ${breaker.state.name}');
  print('');

  // Simulate failures to open the circuit
  print('Simulating failures...');
  for (var i = 1; i <= 4; i++) {
    if (breaker.canExecute()) {
      print('Request $i: Executing...');
      breaker.recordFailure();
    } else {
      print('Request $i: BLOCKED - Circuit is open');
    }
  }

  print('');
  print('Current state: ${breaker.state.name}');
  print('');

  // Wait for recovery timeout
  print('Waiting for recovery timeout (2s)...');
  await Future.delayed(Duration(milliseconds: 100)); // Simulated wait
  print('(Simulated wait complete)');
  print('');

  // Simulate recovery
  // Force state to half-open for demo
  breaker._state = CircuitState.halfOpen;
  print('Circuit is now: ${breaker.state.name}');
  print('');

  print('Simulating recovery...');
  if (breaker.canExecute()) {
    print('Recovery request 1: Executing...');
    breaker.recordSuccess();
  }
  if (breaker.canExecute()) {
    print('Recovery request 2: Executing...');
    breaker.recordSuccess();
  }

  print('');
  print('Final state: ${breaker.state.name}');
  print('');
}

Future<void> testRetry() async {
  print('');
  print('TEST: Exponential Backoff Retry');
  print('================================');
  print('');
  print('Retry strategy uses exponential backoff with jitter to prevent');
  print('thundering herd when many clients retry simultaneously.');
  print('');

  final retry = RetrySimulator(
    maxAttempts: 4,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
    jitterFactor: 0.1,
  );

  print('Configuration:');
  print('  - Max attempts: 4');
  print('  - Initial delay: 1s');
  print('  - Max delay: 30s');
  print('  - Backoff multiplier: 2.0');
  print('  - Jitter factor: ±10%');
  print('');

  print('Delay progression (without jitter):');
  for (var i = 0; i < 4; i++) {
    final baseDelay = 1000 * pow(2.0, i).toInt();
    final actualDelay = retry.getDelay(i);
    print('  Attempt ${i + 1}: ~${baseDelay}ms (actual: ${actualDelay.inMilliseconds}ms with jitter)');
  }
  print('');

  print('Simulating operation that fails twice then succeeds...');
  var attemptCount = 0;
  final success = await retry.executeWithRetry(() async {
    attemptCount++;
    if (attemptCount < 3) {
      throw Exception('Simulated failure');
    }
    return true;
  });

  print('');
  print('Result: ${success ? "SUCCESS" : "FAILURE"} after $attemptCount attempts');
  print('');
}

Future<void> testRateLimit() async {
  print('');
  print('TEST: Rate Limit Handling');
  print('=========================');
  print('');
  print('When Claude returns 429 (rate limit), the Retry-After header');
  print('is respected before retrying.');
  print('');

  print('Scenario: 429 response with Retry-After: 5s');
  print('');
  print('Simulating rate limit detection...');
  print('  Received: HTTP 429 Too Many Requests');
  print('  Header: Retry-After: 5');
  print('');
  print('Expected behavior:');
  print('  1. RateLimitException thrown with retryAfter: 5s');
  print('  2. Client should wait 5 seconds');
  print('  3. Retry the request');
  print('');

  print('Code pattern:');
  print('''
  try {
    await generator.sendRequest(message);
  } on RateLimitException catch (e) {
    final waitTime = e.retryAfter ?? Duration(seconds: 60);
    showMessage('Rate limited. Retrying in \${waitTime.inSeconds}s...');
    await Future.delayed(waitTime);
    // Retry automatically or let user retry
  }
''');
  print('');
}

Future<void> testMetrics() async {
  print('');
  print('TEST: Metrics Collection');
  print('========================');
  print('');
  print('MetricsCollector provides a stream of events for monitoring');
  print('and analytics integration.');
  print('');

  final collector = MockMetricsCollector();

  print('Simulating a request lifecycle with retries...');
  print('');

  // Simulate request lifecycle
  final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

  collector.emit(MockMetricsEvent(
    type: MetricEventType.requestStart,
    requestId: requestId,
  ));

  collector.emit(MockMetricsEvent(
    type: MetricEventType.retryAttempt,
    requestId: requestId,
    retryAttempt: 1,
  ));

  collector.emit(MockMetricsEvent(
    type: MetricEventType.rateLimit,
    requestId: requestId,
    retryAfter: Duration(seconds: 5),
  ));

  collector.emit(MockMetricsEvent(
    type: MetricEventType.retryAttempt,
    requestId: requestId,
    retryAttempt: 2,
  ));

  collector.emit(MockMetricsEvent(
    type: MetricEventType.requestSuccess,
    requestId: requestId,
    latency: Duration(milliseconds: 1234),
  ));

  print('');
  print('Aggregated Statistics:');
  final stats = collector.statistics;
  print('  Total requests: ${stats['totalRequests']}');
  print('  Successes: ${stats['successes']}');
  print('  Failures: ${stats['failures']}');
  print('  Success rate: ${stats['successRate']}%');
  print('  Total retries: ${stats['retries']}');
  print('  Rate limits: ${stats['rateLimits']}');
  print('  Avg latency: ${stats['avgLatencyMs']}ms');
  print('');

  print('Integration example:');
  print('''
  collector.eventStream.listen((event) {
    switch (event) {
      case RequestSuccessEvent(:final latency):
        analytics.timing('claude_request', latency);
      case RequestFailureEvent(:final error):
        analytics.error('claude_error', error.typeName);
      case RateLimitEvent(:final retryAfter):
        analytics.increment('rate_limits');
    }
  });
''');
  print('');

  collector.dispose();
}
