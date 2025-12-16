# Performance Tuning Guide

Optimize genui_claude for best performance in production.

## Table of Contents

- [Overview](#overview)
- [Timeout Configuration](#timeout-configuration)
- [Retry Configuration](#retry-configuration)
- [Circuit Breaker Tuning](#circuit-breaker-tuning)
- [Stream Optimization](#stream-optimization)
- [Memory Management](#memory-management)
- [History Pruning](#history-pruning)
- [Metrics & Monitoring](#metrics--monitoring)

---

## Overview

Performance optimization involves balancing:
- **Latency**: Time to first response
- **Reliability**: Successful completion rate
- **Resource Usage**: Memory and network efficiency

---

## Timeout Configuration

### Request Timeout

Controls how long to wait for the initial HTTP response.

```dart
// Direct mode (default: 60s)
final config = ClaudeConfig(
  timeout: Duration(seconds: 60),
);

// Proxy mode (default: 120s)
final proxyConfig = ProxyConfig(
  timeout: Duration(seconds: 120),
);
```

**Recommendations:**

| Scenario | Timeout | Rationale |
|----------|---------|-----------|
| Simple queries | 30-60s | Quick responses expected |
| Complex generation | 90-120s | Allow time for UI generation |
| Large context | 120-180s | Processing takes longer |

### Stream Inactivity Timeout

Detects stalled streams when no data arrives within the timeout.

```dart
final handler = ProxyModeHandler(
  endpoint: endpoint,
  streamInactivityTimeout: Duration(seconds: 60), // default
);
```

**Recommendations:**

| Network Quality | Timeout |
|-----------------|---------|
| Fast/stable | 30-45s |
| Average | 60s (default) |
| Slow/unstable | 90-120s |

---

## Retry Configuration

Configure exponential backoff for transient failures.

### Parameters

```dart
final retryConfig = RetryConfig(
  maxAttempts: 3,           // Total retry attempts
  initialDelay: Duration(seconds: 1),  // First retry delay
  maxDelay: Duration(seconds: 30),     // Maximum delay cap
  backoffMultiplier: 2.0,   // Exponential factor
  jitterFactor: 0.1,        // ±10% randomness
  retryableStatusCodes: {429, 500, 502, 503, 504},
);
```

### Delay Calculation

```
delay = min(initialDelay × backoffMultiplier^attempt, maxDelay) ± jitter
```

Example with defaults:
- Attempt 0: 1s ± 0.1s
- Attempt 1: 2s ± 0.2s
- Attempt 2: 4s ± 0.4s

### Presets

```dart
// Default: Balanced
RetryConfig.defaults

// No retries
RetryConfig.noRetry

// Aggressive: More retries, longer waits
RetryConfig.aggressive
```

### Recommendations by Use Case

| Use Case | maxAttempts | initialDelay | maxDelay |
|----------|-------------|--------------|----------|
| Interactive UI | 2-3 | 500ms | 10s |
| Background tasks | 5 | 1s | 60s |
| Critical operations | 3 | 1s | 30s |

---

## Circuit Breaker Tuning

Prevent cascading failures when the service is degraded.

### Parameters

```dart
final config = CircuitBreakerConfig(
  failureThreshold: 5,      // Failures before opening
  recoveryTimeout: Duration(seconds: 30),  // Time before half-open
  halfOpenSuccessThreshold: 2,  // Successes to close
);
```

### State Machine

```
CLOSED → (5 failures) → OPEN → (30s wait) → HALF-OPEN → (2 successes) → CLOSED
                                              ↓ (1 failure)
                                            OPEN
```

### Presets

```dart
// Default: Balanced
CircuitBreakerConfig.defaults  // 5 failures, 30s recovery, 2 successes

// Strict: Fast failure detection
CircuitBreakerConfig.strict    // 3 failures, 15s recovery, 1 success

// Lenient: More tolerance
CircuitBreakerConfig.lenient   // 10 failures, 60s recovery, 3 successes
```

### Recommendations

| Environment | Preset | Rationale |
|-------------|--------|-----------|
| Development | `lenient` | More tolerance for testing |
| Staging | `defaults` | Balanced behavior |
| Production | `defaults` or `strict` | Fast failure detection |

### Integration with Metrics

```dart
final collector = MetricsCollector();
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults,
  metricsCollector: collector,
);

// Monitor state changes
collector.eventStream
  .whereType<CircuitBreakerStateChangeEvent>()
  .listen((event) {
    if (event.newState == CircuitState.open) {
      alertOps('Circuit breaker opened!');
    }
  });
```

---

## Stream Optimization

### Enable Streaming (Default)

Streaming is enabled by default and provides progressive UI rendering.

```dart
// Already enabled - no configuration needed
final config = ClaudeConfig(
  enableStreaming: true, // default
);
```

### First Token Latency

Track time to first token for latency optimization:

```dart
collector.eventStream.listen((event) {
  if (event is RequestSuccessEvent && event.firstTokenMs != null) {
    print('First token: ${event.firstTokenMs}ms');
  }
});
```

### Optimize for Streaming

1. **Use smaller chunks**: Don't buffer on proxy
2. **Disable response compression**: Can add latency
3. **Use HTTP/2**: Better multiplexing

---

## Memory Management

### Long Conversations

For long conversations, memory usage can grow significantly.

```dart
// Limit history sent to Claude
final proxyConfig = ProxyConfig(
  includeHistory: true,
  maxHistoryMessages: 20, // Limit to last 20 messages
);
```

### Dispose Resources

Always dispose generators when done:

```dart
@override
void dispose() {
  generator.dispose();
  super.dispose();
}
```

### Widget Memory

For catalog widgets that hold state:

```dart
CatalogItem(
  name: 'heavy_widget',
  widgetBuilder: (context) {
    // Avoid heavy initialization in builder
    // Use lazy loading or caching
    return HeavyWidget(
      data: context.data,
      // Use keys for proper widget recycling
      key: ValueKey(context.surfaceId),
    );
  },
)
```

---

## History Pruning

### Automatic Pruning

Use `maxHistoryMessages` to automatically limit context:

```dart
final proxyConfig = ProxyConfig(
  includeHistory: true,
  maxHistoryMessages: 20,
);
```

### Manual Pruning with MessageConverter

```dart
// Prune to last N messages while preserving pairs
final prunedMessages = MessageConverter.pruneHistory(
  messages: allMessages,
  maxMessages: 20,
);
```

### Pruning Strategy

The pruner:
1. Keeps the most recent messages
2. Ensures user-assistant pairs stay together
3. Preserves system context

### Recommendations

| Context | maxHistoryMessages | Rationale |
|---------|-------------------|-----------|
| Simple Q&A | 10 | Minimal context needed |
| Multi-turn dialog | 20 | Balance context/cost |
| Complex workflows | 30-40 | Needs more history |
| Stateless | 0 | No history needed |

---

## Metrics & Monitoring

### Enable Metrics Collection

```dart
final collector = MetricsCollector(
  enabled: true,
  aggregationEnabled: true,
);

final handler = ProxyModeHandler(
  endpoint: endpoint,
  metricsCollector: collector,
);
```

### Key Metrics to Monitor

```dart
final stats = collector.stats;

// Availability
print('Success rate: ${stats.successRate}%');

// Latency
print('Avg latency: ${stats.averageLatencyMs}ms');
print('P50 latency: ${stats.p50LatencyMs}ms');
print('P95 latency: ${stats.p95LatencyMs}ms');
print('P99 latency: ${stats.p99LatencyMs}ms');

// Errors
print('Failed requests: ${stats.failedRequests}');
print('Rate limits: ${stats.rateLimitEvents}');
print('Circuit breaker opens: ${stats.circuitBreakerOpens}');
```

### Alerting Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Success rate | < 99% | < 95% |
| P95 latency | > 5s | > 10s |
| Circuit breaker opens | > 0/hour | > 3/hour |
| Rate limits | > 10/hour | > 50/hour |

### Export to Monitoring Systems

```dart
// DataDog
collector.eventStream.listen((event) {
  datadog.trackCustomEvent(event.eventType, event.toMap());
});

// Firebase
collector.eventStream.listen((event) {
  FirebaseAnalytics.instance.logEvent(
    name: 'claude_${event.eventType}',
    parameters: event.toMap().cast<String, Object>(),
  );
});

// Periodic stats export
Timer.periodic(Duration(minutes: 1), (_) {
  final stats = collector.stats;
  monitoring.recordGauge('claude.success_rate', stats.successRate);
  monitoring.recordGauge('claude.p95_latency', stats.p95LatencyMs);
});
```

---

## Production Configuration Example

```dart
// Create metrics collector
final metricsCollector = MetricsCollector();

// Create circuit breaker with metrics
final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults,
  name: 'claude-api',
  metricsCollector: metricsCollector,
);

// Create optimized generator
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://api.example.com/claude'),
  authToken: authToken,
  proxyConfig: ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
    maxHistoryMessages: 20,
  ),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
  ),
  circuitBreaker: circuitBreaker,
  streamInactivityTimeout: Duration(seconds: 60),
  metricsCollector: metricsCollector,
);

// Monitor metrics
metricsCollector.eventStream.listen((event) {
  // Send to your monitoring system
});
```

---

## Performance Checklist

- [ ] Use proxy mode in production
- [ ] Configure appropriate timeouts
- [ ] Enable retry with exponential backoff
- [ ] Configure circuit breaker
- [ ] Limit conversation history
- [ ] Enable metrics collection
- [ ] Set up alerting on key metrics
- [ ] Dispose resources properly
- [ ] Test under load before deployment
