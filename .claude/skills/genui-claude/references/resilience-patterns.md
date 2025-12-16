# Resilience Patterns

Production-ready patterns for reliable GenUI applications.

## Circuit Breaker

Prevents cascading failures by fast-failing when a service is unhealthy.

### States

```
┌─────────────────────────────────────────────────────────────┐
│                     CIRCUIT BREAKER                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   CLOSED ──────(failures >= threshold)──────> OPEN          │
│     ↑                                           │            │
│     │                                           │            │
│     │                              (recovery timeout)        │
│     │                                           │            │
│     │                                           ↓            │
│     └────────(success)──────────────── HALF-OPEN            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

- **Closed**: Normal operation, requests flow through
- **Open**: Failing fast, requests rejected immediately with `CircuitBreakerOpenException`
- **Half-Open**: Testing recovery with limited requests

### Configuration

```dart
// In proxy mode
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  circuitBreakerConfig: CircuitBreakerConfig(
    failureThreshold: 5,           // Failures before opening
    recoveryTimeout: Duration(seconds: 30), // Time before half-open
    halfOpenSuccessThreshold: 2,   // Successes to close
  ),
);
```

### Pre-defined Configurations

| Config | Failure Threshold | Recovery Timeout | Use Case |
|--------|-------------------|------------------|----------|
| `CircuitBreakerConfig.defaults` | 5 | 30s | Standard applications |
| `CircuitBreakerConfig.lenient` | 10 | 60s | High-tolerance scenarios |
| `CircuitBreakerConfig.strict` | 3 | 15s | Critical user paths |

```dart
// Use pre-defined config
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  circuitBreakerConfig: CircuitBreakerConfig.strict,
);
```

### State Monitoring (Observable)

The `circuitBreakerState` property is a `ValueListenable<CircuitBreakerState>` that enables reactive UI updates:

**Flutter Widget Integration:**

```dart
// Use ValueListenableBuilder for reactive UI
ValueListenableBuilder<CircuitBreakerState>(
  valueListenable: _generator.circuitBreakerState,
  builder: (context, state, child) {
    return switch (state) {
      CircuitBreakerState.closed => SendButton(enabled: true),
      CircuitBreakerState.open => DisabledButton(
        message: 'Service unavailable',
      ),
      CircuitBreakerState.halfOpen => SendButton(
        enabled: true,
        showRetryIndicator: true,
      ),
    };
  },
)
```

**Direct Listener Pattern:**

```dart
// For non-widget code (services, controllers)
void initialize() {
  _generator.circuitBreakerState.addListener(_onCircuitBreakerStateChange);
}

void _onCircuitBreakerStateChange() {
  final state = _generator.circuitBreakerState.value;
  switch (state) {
    case CircuitBreakerState.closed:
      log('Circuit closed - normal operation');
    case CircuitBreakerState.open:
      showUserWarning('Service temporarily unavailable');
      disableSendButton();
    case CircuitBreakerState.halfOpen:
      log('Testing service recovery...');
  }
}

void dispose() {
  _generator.circuitBreakerState.removeListener(_onCircuitBreakerStateChange);
}
```

**Stream-based Monitoring (via Metrics):**

```dart
// For analytics and logging
collector.eventStream
  .whereType<CircuitBreakerStateChangeEvent>()
  .listen((event) {
    log('Circuit: ${event.previousState} → ${event.newState}');
    analytics.event('circuit_breaker', {
      'from': event.previousState.name,
      'to': event.newState.name,
    });
  });
```

### Handling Circuit Open

```dart
try {
  await generator.sendRequest(message);
} on CircuitBreakerOpenException {
  // Circuit is open, show graceful degradation
  showMessage('The AI service is temporarily unavailable. Please try again later.');
}
```

## Retry Strategy

Automatic retries with exponential backoff and jitter.

### Exponential Backoff

Delays increase exponentially to avoid overwhelming a recovering service:

```
Attempt 1: 1s (base)
Attempt 2: 2s (1s × 2.0)
Attempt 3: 4s (2s × 2.0)
+ jitter: ±10% random variation
```

The jitter prevents thundering herd when many clients retry simultaneously.

### Configuration

```dart
const config = RetryConfig(
  maxAttempts: 3,                    // Total attempts (1 initial + 2 retries)
  initialDelay: Duration(seconds: 1), // First retry delay
  maxDelay: Duration(seconds: 30),   // Cap on delay
  backoffMultiplier: 2.0,            // Exponential growth factor
  jitterFactor: 0.1,                 // ±10% random jitter
  retryableStatusCodes: {429, 500, 502, 503, 504},
);

final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  retryConfig: config,
);
```

### Pre-defined Configurations

| Config | Max Attempts | Initial Delay | Use Case |
|--------|--------------|---------------|----------|
| `RetryConfig.defaults` | 3 | 1s | Standard applications |
| `RetryConfig.aggressive` | 5 | 500ms | User-facing, faster recovery |
| `RetryConfig.noRetry` | 0 | - | Testing, disable retries |

```dart
// Aggressive retries for better UX
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  retryConfig: RetryConfig.aggressive,
);
```

### Rate Limit Handling (429)

When Claude returns a 429 rate limit response, the `Retry-After` header is respected:

```dart
// Handled automatically by ProxyModeHandler
// The exception provides the suggested wait time:

catch (e) {
  if (e is RateLimitException) {
    final waitTime = e.retryAfter ?? Duration(seconds: 60);
    showMessage('Rate limited. Please wait ${waitTime.inSeconds}s');
  }
}
```

### Retryable vs Non-Retryable Errors

| Error Type | Retryable | Reason |
|------------|-----------|--------|
| `NetworkException` | Yes | Transient network issues |
| `TimeoutException` | Yes | Server may be slow |
| `RateLimitException` | Yes | Wait and retry |
| `ServerException` (5xx) | Yes | Server issues |
| `AuthenticationException` | No | Invalid credentials |
| `BadRequestException` | No | Invalid request format |

## Metrics Collector

Stream-based observability for monitoring and analytics.

### Event Types

| Event | When Emitted | Key Data |
|-------|--------------|----------|
| `RequestStartEvent` | Request initiated | requestId |
| `RequestSuccessEvent` | Request completed | requestId, latency |
| `RequestFailureEvent` | Request failed | requestId, error, latency |
| `RetryAttemptEvent` | Retry triggered | requestId, attemptNumber, delay |
| `RateLimitEvent` | 429 response | requestId, retryAfter |
| `CircuitBreakerStateChangeEvent` | State changed | previousState, newState |
| `StreamInactivityEvent` | Stream timeout | requestId, inactiveFor |

### Basic Integration

```dart
final collector = MetricsCollector();

// Stream all events
collector.eventStream.listen((event) {
  log('Metric: ${event.eventType}');
});

// Pass to generator
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  metricsCollector: collector,
);
```

### Analytics Integration

```dart
collector.eventStream.listen((event) {
  switch (event) {
    case RequestStartEvent(:final requestId):
      analytics.startTimer('claude_request', id: requestId);

    case RequestSuccessEvent(:final latency, :final requestId):
      analytics.timing('claude_request', latency.inMilliseconds);
      analytics.increment('claude_success');

    case RequestFailureEvent(:final error, :final requestId):
      analytics.error('claude_error', error.typeName);
      analytics.increment('claude_failure');

    case RetryAttemptEvent(:final attemptNumber):
      analytics.increment('claude_retry');

    case RateLimitEvent(:final retryAfter):
      analytics.increment('claude_rate_limit');
      analytics.gauge('rate_limit_wait', retryAfter?.inSeconds ?? 60);

    case CircuitBreakerStateChangeEvent(:final newState):
      analytics.event('circuit_breaker', state: newState.name);

    case StreamInactivityEvent(:final inactiveFor):
      analytics.warning('stream_inactive', duration: inactiveFor.inSeconds);
  }
});
```

### Aggregated Statistics

```dart
// Get summary statistics
final stats = collector.statistics;

print('Total requests: ${stats.totalRequests}');
print('Success rate: ${stats.successRate}%');
print('Avg latency: ${stats.averageLatency}ms');
print('Total retries: ${stats.totalRetries}');
print('Rate limits: ${stats.rateLimitCount}');
```

### Filtering Events

```dart
// Only success/failure events
collector.eventStream
  .where((e) => e is RequestSuccessEvent || e is RequestFailureEvent)
  .listen(handleCompletion);

// Only errors
collector.eventStream
  .whereType<RequestFailureEvent>()
  .listen((e) => reportError(e.error));

// Circuit breaker changes only
collector.eventStream
  .whereType<CircuitBreakerStateChangeEvent>()
  .listen(updateCircuitBreakerUI);
```

### Disable for Testing

```dart
// Disable metrics collection entirely
final collector = MetricsCollector(enabled: false);

// Or simply don't pass a collector
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: endpoint,
  // metricsCollector: null - no metrics
);
```

## Stream Inactivity Timeout

Prevents hanging connections when Claude streams stop unexpectedly.

### How It Works

```dart
// ProxyModeHandler monitors stream activity
// Default: 30 seconds without data triggers timeout

// When timeout occurs:
// 1. StreamInactivityEvent is emitted
// 2. Stream is closed
// 3. TimeoutException may be thrown if configured
```

### Monitoring Inactivity

```dart
collector.eventStream
  .whereType<StreamInactivityEvent>()
  .listen((event) {
    log('Stream inactive for ${event.inactiveFor.inSeconds}s');
    showLoadingIndicator(); // Visual feedback
  });
```

### Configuration

Stream inactivity is handled internally by the handler. The `ProxyConfig.timeout` affects overall request timeout, while stream inactivity is a separate mechanism for detecting stalled streams.

## Exception Hierarchy

All exceptions extend the sealed `ClaudeException` base class, enabling exhaustive pattern matching:

```dart
void handleError(ClaudeException exception) {
  switch (exception) {
    case NetworkException(:final message):
      showError('Network error: $message');
      if (exception.isRetryable) scheduleRetry();

    case TimeoutException(:final timeout):
      showError('Request timed out after ${timeout.inSeconds}s');

    case AuthenticationException(:final statusCode):
      if (statusCode == 401) promptLogin();
      else showError('Access denied');

    case RateLimitException(:final retryAfter):
      final wait = retryAfter ?? Duration(seconds: 60);
      showError('Rate limited. Try again in ${wait.inSeconds}s');

    case BadRequestException(:final message):
      log('Bad request: $message'); // Developer error
      showError('Something went wrong');

    case ServerException(:final statusCode):
      showError('Server error ($statusCode). Please try again.');

    case CircuitBreakerOpenException():
      showError('Service temporarily unavailable');
  }
}
```

### Common Properties

All exceptions include:

```dart
abstract class ClaudeException implements Exception {
  String get message;           // Human-readable message
  String? get requestId;        // Request ID for debugging
  int? get statusCode;          // HTTP status code (if applicable)
  Object? get originalError;    // Underlying error
  StackTrace? get stackTrace;   // Stack trace
  bool get isRetryable;         // Whether retry might succeed
  String get typeName;          // Exception type name for logging
}
```

## Production Checklist

### Security
- [ ] Use proxy mode (API key stays on server)
- [ ] Validate user auth tokens server-side
- [ ] Set appropriate CORS headers

### Resilience
- [ ] Configure circuit breaker for your SLA
- [ ] Set retry config appropriate for your use case
- [ ] Handle `CircuitBreakerOpenException` in UI
- [ ] Implement graceful degradation for rate limits

### Observability
- [ ] Connect metrics to monitoring (DataDog, Firebase, etc.)
- [ ] Set up alerts for high error rates
- [ ] Monitor circuit breaker state changes
- [ ] Track stream inactivity events

### Performance
- [ ] Set reasonable timeouts (60-120s for proxy)
- [ ] Configure `maxHistoryMessages` to limit token usage
- [ ] Use `RetryConfig.aggressive` for user-facing features

### Testing
- [ ] Test circuit breaker behavior with mock handler
- [ ] Verify retry logic with intentional failures
- [ ] Test rate limit handling
- [ ] Validate metrics are emitted correctly
