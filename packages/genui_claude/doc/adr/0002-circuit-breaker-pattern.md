# ADR-0002: Circuit Breaker Pattern

## Status

Accepted

## Context

When the Claude API becomes unavailable or degraded, clients can experience:
1. **Resource exhaustion**: Threads/connections blocked waiting for timeouts
2. **Cascading failures**: Slow responses cause upstream timeouts
3. **Thundering herd**: All clients retry simultaneously when service recovers
4. **Poor user experience**: Long waits with no feedback

The retry mechanism alone (ADR-0004) doesn't solve these problems because:
- It still attempts requests to a known-failing service
- Multiple retries multiply the load on an already struggling service
- Users wait through all retry attempts before seeing an error

## Decision

Implement the Circuit Breaker pattern with three states:

```
       ┌──────────┐
       │  CLOSED  │ ◄─────────────────────┐
       └────┬─────┘                        │
            │ (failureThreshold failures)  │ (halfOpenSuccessThreshold successes)
            ▼                              │
       ┌──────────┐      (recoveryTimeout) │
       │   OPEN   │ ────────────────► ┌────┴─────┐
       └──────────┘                   │ HALF-OPEN │
            ▲                         └────┬─────┘
            │ (any failure)                │
            └──────────────────────────────┘
```

**States:**
- **CLOSED**: Normal operation, requests pass through
- **OPEN**: Fail fast, requests rejected immediately with CircuitBreakerOpenException
- **HALF-OPEN**: Test recovery with limited requests

**Configuration:**
```dart
CircuitBreakerConfig(
  failureThreshold: 5,           // Failures before opening
  recoveryTimeout: Duration(seconds: 30),  // Wait before half-open
  halfOpenSuccessThreshold: 2,   // Successes to close
)
```

**Presets for common scenarios:**
- `defaults`: Balanced (5/30s/2)
- `strict`: Aggressive failure detection (3/15s/1)
- `lenient`: More tolerant (10/60s/3)

**Integration:**
```dart
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults,
  name: 'claude-api',
  metricsCollector: collector,
);

// In handler
breaker.checkState();  // Throws if open
try {
  await makeRequest();
  breaker.recordSuccess();
} catch (e) {
  breaker.recordFailure();
  rethrow;
}
```

## Consequences

### Positive

1. **Fast failure**: Users get immediate feedback when service is down
2. **Service protection**: Reduces load on degraded services
3. **Automatic recovery**: Self-heals when service returns
4. **Configurable**: Tunable for different reliability requirements
5. **Observable**: State changes emit metrics for monitoring
6. **No external dependencies**: Pure Dart implementation

### Negative

1. **Complexity**: Additional state to manage and test
2. **False positives**: Brief outages can trigger circuit open
3. **Cold start**: New circuit breakers start closed, may not protect initially
4. **Coordination**: Multiple instances don't share state

### Trade-offs

| Setting | Higher Value | Lower Value |
|---------|-------------|-------------|
| failureThreshold | More tolerance, slower detection | Faster detection, more false positives |
| recoveryTimeout | Less load on recovering service | Faster recovery detection |
| halfOpenSuccessThreshold | More confidence in recovery | Faster full recovery |

### Alternatives Considered

1. **External circuit breaker (e.g., Envoy)**: Rejected due to mobile deployment target
2. **Timeout-only**: Doesn't provide fail-fast or recovery testing
3. **Rate limiting**: Complements but doesn't replace circuit breaking

## References

- [Martin Fowler - Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Microsoft - Circuit Breaker Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
- [Release It! by Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/)
