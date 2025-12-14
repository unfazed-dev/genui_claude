# ADR-0004: Retry with Exponential Backoff

## Status

Accepted

## Context

Transient failures are common when calling external APIs:
- Network glitches
- Rate limiting (HTTP 429)
- Temporary server errors (HTTP 5xx)
- Connection timeouts

Without retry logic:
1. Users see errors for recoverable failures
2. Single network hiccup fails the entire request
3. Rate limits cause immediate failure instead of waiting

Naive retry approaches cause problems:
- **Fixed delay**: Doesn't adapt to load, causes thundering herd
- **Immediate retry**: Amplifies load on struggling services
- **Unlimited retries**: Never fails, resource exhaustion

## Decision

Implement exponential backoff with jitter for proxy mode retries:

**Formula:**
```
delay = min(initialDelay × backoffMultiplier^attempt, maxDelay) ± jitter
```

**Configuration:**
```dart
RetryConfig(
  maxAttempts: 3,           // Total retry attempts
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  backoffMultiplier: 2.0,   // Exponential factor
  jitterFactor: 0.1,        // ±10% randomness
  retryableStatusCodes: {429, 500, 502, 503, 504},
)
```

**Example delays (defaults):**
| Attempt | Base Delay | With Jitter (±10%) |
|---------|------------|-------------------|
| 0 | 1s | 0.9s - 1.1s |
| 1 | 2s | 1.8s - 2.2s |
| 2 | 4s | 3.6s - 4.4s |
| 3 | 8s | 7.2s - 8.8s |

**Presets:**
```dart
// Default: Balanced retry
RetryConfig.defaults

// No retries: For testing or when retry is handled elsewhere
RetryConfig.noRetry

// Aggressive: More attempts, longer tolerance
RetryConfig.aggressive  // 5 attempts, 1.5x multiplier, 60s max
```

**Rate limit handling:**
```dart
on RateLimitException catch (e) {
  // Use Retry-After header if available
  final delay = e.retryAfter ?? config.getDelayForAttempt(attempt);
  await Future.delayed(delay);
}
```

**Integration with isRetryable:**
```dart
on AnthropicException catch (e) {
  if (!e.isRetryable || attempt >= maxAttempts) {
    yield errorEvent;
    return;
  }
  // Retry
}
```

## Consequences

### Positive

1. **Resilience**: Recovers from transient failures automatically
2. **Adaptive**: Exponential backoff reduces load on failing services
3. **Fair**: Jitter prevents thundering herd
4. **Respectful**: Honors Retry-After headers
5. **Bounded**: maxAttempts and maxDelay prevent infinite retries
6. **Configurable**: Tune for different reliability requirements

### Negative

1. **Latency**: Retries add delay to failing requests
2. **Complexity**: Additional state and configuration
3. **Resource usage**: Holding connections during backoff
4. **User experience**: Users wait during retries (but with isProcessing feedback)

### Trade-offs

| Setting | Higher Value | Lower Value |
|---------|-------------|-------------|
| maxAttempts | More resilient, longer worst-case | Faster failure |
| initialDelay | Less load on service | Faster recovery |
| maxDelay | Better for long outages | Faster total failure |
| backoffMultiplier | Faster backoff growth | More even distribution |
| jitterFactor | Better thundering herd prevention | More predictable |

### Retry Decision Matrix

| Error Type | Retryable | Rationale |
|------------|-----------|-----------|
| NetworkException | Yes | Transient connectivity |
| TimeoutException | Yes | May succeed on retry |
| RateLimitException | Yes | Wait and retry |
| ServerException (5xx) | Yes | Transient server issues |
| AuthenticationException | No | Won't help |
| ValidationException | No | Client error |
| StreamException | No | Likely data issue |
| CircuitBreakerOpen | Yes* | After recovery timeout |

### Direct vs Proxy Mode

| Feature | Direct Mode | Proxy Mode |
|---------|-------------|------------|
| Retry control | SDK-managed | Full control |
| Configuration | `retryAttempts` | Full `RetryConfig` |
| Jitter | SDK implementation | Configurable |
| Rate limit | SDK handling | Custom with metrics |

## Alternatives Considered

1. **Linear backoff**: Rejected for thundering herd susceptibility
2. **No retry**: Rejected for poor UX on transient failures
3. **Queue-based retry**: Over-engineered for mobile client
4. **SDK-only retry**: Insufficient control in proxy mode

## References

- [AWS Exponential Backoff](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Google Cloud Retry Strategy](https://cloud.google.com/storage/docs/retry-strategy)
- [RFC 7231 Retry-After](https://tools.ietf.org/html/rfc7231#section-7.1.3)
