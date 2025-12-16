# ADR-0001: Sealed Exception Hierarchy

## Status

Accepted

## Context

The genui_claude package needs to handle various failure modes when communicating with the Claude API:
- Network connectivity issues
- Request timeouts
- Authentication failures
- Rate limiting
- Validation errors
- Server errors
- Stream parsing errors
- Circuit breaker interventions

Without a structured exception system:
1. Callers cannot distinguish between retryable and non-retryable errors
2. Error handling code becomes verbose with instanceof checks
3. New error types can be added without updating handlers (incomplete handling)
4. Request tracking across distributed systems is difficult

## Decision

Implement a sealed exception hierarchy with exhaustive handling:

```dart
sealed class ClaudeException implements Exception {
  final String message;
  final String? requestId;
  final int? statusCode;
  final Object? originalError;
  final StackTrace? stackTrace;
  bool get isRetryable;
  String get typeName;
}

class NetworkException extends ClaudeException { ... }
class TimeoutException extends ClaudeException { ... }
class AuthenticationException extends ClaudeException { ... }
class RateLimitException extends ClaudeException { ... }
class ValidationException extends ClaudeException { ... }
class ServerException extends ClaudeException { ... }
class StreamException extends ClaudeException { ... }
class CircuitBreakerOpenException extends ClaudeException { ... }
```

Key design choices:
1. **Sealed class**: Dart's sealed classes ensure exhaustive switch handling
2. **isRetryable property**: Built-in retry decision without external logic
3. **requestId**: Enable end-to-end request tracing
4. **ExceptionFactory**: Centralized HTTP status to exception mapping
5. **Retry-After parsing**: RateLimitException parses RFC 7231 headers

## Consequences

### Positive

1. **Exhaustive handling**: Compiler enforces all exception types are handled
2. **Simplified retry logic**: `if (e.isRetryable)` instead of type checks
3. **Request correlation**: requestId enables distributed tracing
4. **Type safety**: No stringly-typed error identification
5. **Consistent UI messaging**: `typeName` provides user-friendly error categories
6. **Testability**: Each exception type can be tested independently

### Negative

1. **API surface**: 8 exception classes to understand
2. **Migration**: Adding new exception types requires updating all handlers
3. **Coupling**: Code catching ClaudeException is coupled to this hierarchy

### Risks Mitigated

- Unhandled error types (sealed class forces handling)
- Retry storms (isRetryable prevents retrying auth failures)
- Lost context (requestId, originalError, stackTrace preserved)
- Rate limit violations (RateLimitException.retryAfter honored)

## References

- [Dart Sealed Classes](https://dart.dev/language/class-modifiers#sealed)
- [RFC 7231 Retry-After](https://tools.ietf.org/html/rfc7231#section-7.1.3)
