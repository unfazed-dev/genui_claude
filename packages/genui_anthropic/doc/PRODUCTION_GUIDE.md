# Production Deployment Guide

This guide covers production hardening features and best practices for deploying `genui_anthropic` in production environments.

## Production Features

### 1. Exception Hierarchy

The package provides a structured exception hierarchy for precise error handling:

```dart
import 'package:genui_anthropic/genui_anthropic.dart';

// All exceptions extend AnthropicException
sealed class AnthropicException {
  String get message;
  String? get requestId;
  int? get statusCode;
  bool get isRetryable;
}

// Specific exception types:
// - NetworkException: DNS, connection errors (retryable)
// - TimeoutException: Request/stream timeout (retryable)
// - AuthenticationException: 401/403 errors (not retryable)
// - RateLimitException: 429 errors (retryable with delay)
// - ValidationException: 400/422 errors (not retryable)
// - ServerException: 5xx errors (retryable)
// - StreamException: SSE parsing errors (not retryable)
// - CircuitBreakerOpenException: Circuit breaker tripped (retryable after recovery)
```

### 2. Retry Configuration

Configure automatic retry with exponential backoff:

```dart
final handler = ProxyModeHandler(
  endpoint: Uri.parse('https://api.example.com/chat'),
  retryConfig: RetryConfig(
    maxAttempts: 3,              // Retry up to 3 times
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,     // Exponential backoff
    jitterFactor: 0.1,          // ±10% randomness
    retryableStatusCodes: {429, 500, 502, 503, 504},
  ),
);

// Built-in presets:
RetryConfig.defaults       // Standard retry settings
RetryConfig.noRetry        // Disable retries
RetryConfig.aggressive     // More retries, shorter delays
```

### 3. Circuit Breaker

Prevent cascading failures with the circuit breaker pattern:

```dart
final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig(
    failureThreshold: 5,              // Open after 5 failures
    recoveryTimeout: Duration(seconds: 30),
    halfOpenSuccessThreshold: 2,      // Close after 2 successes
  ),
  name: 'claude-api',
);

final handler = ProxyModeHandler(
  endpoint: Uri.parse('https://api.example.com/chat'),
  circuitBreaker: circuitBreaker,
);

// Monitor circuit breaker state
print('State: ${circuitBreaker.state}');       // closed, open, halfOpen
print('Failures: ${circuitBreaker.failureCount}');
```

### 4. Rate Limit Handling

Automatic detection and handling of rate limits:

```dart
// Rate limits (HTTP 429) are automatically detected
// - Retry-After header is parsed and respected
// - Falls back to exponential backoff if no header

// RateLimitException provides retry delay:
try {
  await handler.createStream(request).toList();
} on RateLimitException catch (e) {
  print('Rate limited, retry after: ${e.retryAfter}');
}
```

### 5. Request ID Tracking

Every request gets a unique ID for debugging:

```dart
await for (final event in handler.createStream(request)) {
  // All events include _requestId for correlation
  final requestId = event['_requestId'];
  print('[$requestId] Event: ${event['type']}');
}

// Exceptions also include request ID:
try {
  await handler.createStream(request).toList();
} on AnthropicException catch (e) {
  print('Request ${e.requestId} failed: ${e.message}');
}
```

### 6. Stream Inactivity Timeout

Detect stalled streams that stop sending data:

```dart
final handler = ProxyModeHandler(
  endpoint: Uri.parse('https://api.example.com/chat'),
  streamInactivityTimeout: Duration(seconds: 60),
);

// Throws TimeoutException if no data received for 60 seconds
```

## Configuration Examples

### Development Mode

```dart
final generator = AnthropicContentGenerator(
  apiKey: 'your-api-key',
  model: 'claude-sonnet-4-20250514',
  config: AnthropicConfig(
    maxTokens: 4096,
    timeout: Duration(seconds: 60),
    retryAttempts: 3,
  ),
);
```

### Production Mode (Recommended)

```dart
final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults,
  name: 'claude-proxy',
);

final generator = AnthropicContentGenerator.proxy(
  endpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: userJwtToken,
  config: ProxyConfig(
    timeout: Duration(seconds: 120),
    maxHistoryMessages: 20,
  ),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
  ),
  circuitBreaker: circuitBreaker,
  streamInactivityTimeout: Duration(seconds: 60),
);
```

## Error Handling Best Practices

```dart
Future<void> handleChat(String message) async {
  try {
    final response = await generator.sendRequest(
      ChatMessage.user(TextPart(message)),
      history,
    );
  } on AuthenticationException catch (e) {
    // Token expired - redirect to login
    await refreshToken();
    // Retry once with new token
  } on RateLimitException catch (e) {
    // Show user-friendly message
    showMessage('Too many requests. Please wait ${e.retryAfter?.inSeconds ?? 30}s');
  } on CircuitBreakerOpenException catch (e) {
    // Service is down
    showMessage('Service temporarily unavailable');
  } on AnthropicException catch (e) {
    if (e.isRetryable) {
      // Retries exhausted, show retry option
      showRetryButton();
    } else {
      // Non-recoverable error
      showError(e.message);
    }
  }
}
```

## Monitoring Recommendations

### Logging Configuration

```dart
import 'package:logging/logging.dart';

// Configure logging levels
Logger.root.level = Level.INFO;
Logger.root.onRecord.listen((record) {
  // Send to your logging service
  logService.log(
    level: record.level.name,
    logger: record.loggerName,
    message: record.message,
    error: record.error,
    stackTrace: record.stackTrace,
  );
});
```

### Metrics to Track

1. **Request metrics**
   - Total requests
   - Success/failure rate
   - Latency (p50, p95, p99)

2. **Error metrics**
   - Error rate by type (timeout, rate limit, auth, server)
   - Retry counts
   - Circuit breaker state changes

3. **Resource metrics**
   - Active connections
   - Token usage (from response)

## Deployment Checklist

- [ ] Use proxy mode (keep API keys server-side)
- [ ] Configure appropriate timeouts
- [ ] Set up retry configuration
- [ ] Enable circuit breaker for high-traffic apps
- [ ] Configure logging for production
- [ ] Set up error tracking/alerting
- [ ] Test error scenarios before launch
- [ ] Monitor rate limit usage
- [ ] Plan for graceful degradation

## Security Considerations

1. **Never expose API keys in client code** - Use proxy mode
2. **Validate auth tokens** on your backend proxy
3. **Rate limit per user** on your backend
4. **Log request IDs** for audit trails
5. **Sanitize error messages** shown to users
