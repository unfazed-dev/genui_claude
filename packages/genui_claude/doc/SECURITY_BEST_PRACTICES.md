# Security Best Practices

This guide outlines security best practices for using the `genui_claude` package in production applications.

## Table of Contents

1. [API Key Protection](#api-key-protection)
2. [Authentication Token Handling](#authentication-token-handling)
3. [Rate Limiting and Abuse Prevention](#rate-limiting-and-abuse-prevention)
4. [Input Validation](#input-validation)
5. [Error Message Sanitization](#error-message-sanitization)
6. [CORS Configuration](#cors-configuration)
7. [Audit Logging](#audit-logging)
8. [Dependency Security](#dependency-security)

---

## API Key Protection

### Critical Rule: Never Expose API Keys in Client Code

The Claude API key is a sensitive credential that provides full access to your account. **Never include it in client-side code.**

### Development vs. Production Modes

```dart
// DEVELOPMENT ONLY - Direct Mode (Never use in production!)
// Use this only for local development and prototyping
final generator = ClaudeContentGenerator(
  apiKey: String.fromEnvironment('CLAUDE_API_KEY'),
  catalog: myCatalog,
);

// PRODUCTION - Proxy Mode (Recommended)
// API key stays secure on your backend server
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-api.com/claude'),
  authToken: userAuthToken, // User-specific auth, not API key
  catalog: myCatalog,
);
```

### Backend Proxy Implementation

Your backend should:

1. Store the Claude API key securely (environment variables, secret manager)
2. Authenticate users before forwarding requests
3. Add the API key to outbound requests server-side
4. Never return the API key in any response

Example Supabase Edge Function:

```typescript
// supabase/functions/claude-genui/index.ts
import "jsr:@anthropic-ai/sdk";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");

Deno.serve(async (req) => {
  // Verify user authentication
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  // Validate JWT and get user context
  const user = await validateAuth(authHeader);
  if (!user) {
    return new Response("Forbidden", { status: 403 });
  }

  // Forward to Claude API with server-side key
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": CLAUDE_API_KEY!, // Server-side only
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json",
    },
    body: await req.text(),
  });

  return response;
});
```

---

## Authentication Token Handling

### User Token Best Practices

```dart
// Configure with user-specific auth token
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: proxyUri,
  authToken: await authService.getCurrentToken(),
  catalog: catalog,
);
```

### Token Lifecycle Management

1. **Short-lived tokens**: Use JWTs with reasonable expiration (15-60 minutes)
2. **Refresh mechanism**: Implement token refresh before expiration
3. **Secure storage**: Use platform-specific secure storage (Keychain, Keystore)
4. **Revocation**: Support token revocation for compromised sessions

### Backend Token Validation

```typescript
async function validateAuth(authHeader: string): Promise<User | null> {
  const token = authHeader.replace("Bearer ", "");

  try {
    // Verify JWT signature and expiration
    const payload = await verifyJWT(token, JWT_SECRET);

    // Optional: Check token revocation list
    if (await isTokenRevoked(payload.jti)) {
      return null;
    }

    return payload.user;
  } catch {
    return null;
  }
}
```

---

## Rate Limiting and Abuse Prevention

### Client-Side Configuration

```dart
// Configure retry and circuit breaker for resilience
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: proxyUri,
  authToken: authToken,
  config: const ProxyConfig(
    retryAttempts: 3,
    timeout: Duration(seconds: 120),
  ),
  retryConfig: const RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
  ),
  circuitBreaker: CircuitBreaker(
    config: CircuitBreakerConfig.defaults,
  ),
  catalog: catalog,
);
```

### Backend Rate Limiting

Implement rate limiting on your proxy:

```typescript
const rateLimiter = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const limit = rateLimiter.get(userId);

  if (!limit || now > limit.resetAt) {
    rateLimiter.set(userId, { count: 1, resetAt: now + 60000 }); // 1 minute window
    return true;
  }

  if (limit.count >= 10) { // 10 requests per minute
    return false;
  }

  limit.count++;
  return true;
}
```

### Handling Rate Limit Responses

```dart
// The package automatically handles rate limiting
generator.errorStream.listen((error) {
  if (error.error is RateLimitException) {
    final rateLimit = error.error as RateLimitException;
    // Show user-friendly message
    showMessage('Please wait ${rateLimit.retryAfter?.inSeconds ?? 60} seconds');
  }
});
```

---

## Input Validation

### Message Content Validation

```dart
// Validate user input before sending
String sanitizeInput(String input) {
  // Remove excessive whitespace
  input = input.trim().replaceAll(RegExp(r'\s+'), ' ');

  // Enforce maximum length
  if (input.length > 10000) {
    input = input.substring(0, 10000);
  }

  return input;
}

// Use validated input
await generator.sendRequest(
  userMessage: sanitizeInput(userInput),
);
```

### Backend Input Validation

```typescript
function validateRequest(body: any): boolean {
  // Validate message structure
  if (!Array.isArray(body.messages)) return false;

  for (const msg of body.messages) {
    // Check role
    if (!['user', 'assistant'].includes(msg.role)) return false;

    // Check content length
    if (typeof msg.content !== 'string') return false;
    if (msg.content.length > 100000) return false;
  }

  // Validate max_tokens
  if (body.max_tokens > 65536) return false;

  return true;
}
```

---

## Error Message Sanitization

### Never Expose Internal Details

The package sanitizes error messages, but your backend should also:

```typescript
// BAD - Exposes internal details
return new Response(JSON.stringify({
  error: `Database error: ${err.message}`,
  stack: err.stack,
}), { status: 500 });

// GOOD - Generic error message
return new Response(JSON.stringify({
  error: 'An internal error occurred. Please try again.',
  request_id: requestId, // For debugging correlation
}), { status: 500 });
```

### Client-Side Error Handling

```dart
generator.errorStream.listen((error) {
  // Log full error internally
  logger.error('ContentGenerator error', error: error.error, stackTrace: error.stackTrace);

  // Show sanitized message to user
  final userMessage = _getUserFriendlyMessage(error.error);
  showSnackBar(userMessage);
});

String _getUserFriendlyMessage(Object error) {
  if (error is NetworkException) {
    return 'Network error. Please check your connection.';
  }
  if (error is TimeoutException) {
    return 'Request timed out. Please try again.';
  }
  if (error is RateLimitException) {
    return 'Too many requests. Please wait a moment.';
  }
  if (error is AuthenticationException) {
    return 'Session expired. Please log in again.';
  }
  return 'Something went wrong. Please try again.';
}
```

---

## CORS Configuration

### Backend CORS Setup

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://your-app.com', // Specific origin
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Request-ID',
  'Access-Control-Max-Age': '86400',
};

// Handle preflight
if (req.method === 'OPTIONS') {
  return new Response(null, { headers: corsHeaders });
}

// Include CORS headers in response
return new Response(body, {
  headers: {
    ...corsHeaders,
    'Content-Type': 'text/event-stream',
  },
});
```

### Security Considerations

1. **Specific origins**: Never use `*` in production
2. **Credentials**: Only allow if necessary
3. **Exposed headers**: Limit to required headers only

---

## Audit Logging

### Request ID Tracking

The package includes request IDs for tracing:

```dart
// Request IDs are included in all events
generator.errorStream.listen((error) {
  // Extract request ID for correlation
  final requestId = extractRequestId(error);
  logger.error('Request $requestId failed', error: error.error);
});
```

### Backend Logging

```typescript
const requestId = req.headers.get('X-Request-ID') || crypto.randomUUID();

// Log request
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  request_id: requestId,
  user_id: user.id,
  action: 'claude_request',
  model: body.model,
  max_tokens: body.max_tokens,
}));

// Log response
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  request_id: requestId,
  status: response.status,
  duration_ms: Date.now() - startTime,
}));
```

### Metrics Collection

```dart
// Use the built-in metrics collector
final metricsCollector = MetricsCollector(enabled: true);

metricsCollector.eventStream.listen((event) {
  // Forward to your analytics/monitoring service
  analytics.track(event.toMap());
});

final generator = ClaudeContentGenerator.proxy(
  // ... other config
  metricsCollector: metricsCollector,
);
```

---

## Dependency Security

### Keep Dependencies Updated

```yaml
# pubspec.yaml - Use caret constraints for security updates
dependencies:
  genui_claude: ^0.1.0
  http: ^1.2.0
```

### Security Scanning

1. Run `dart pub outdated` regularly
2. Review security advisories for dependencies
3. Use `dart pub audit` when available
4. Monitor GitHub security alerts

### Lockfile Management

```bash
# Commit pubspec.lock for reproducible builds
git add pubspec.lock

# Update dependencies regularly
dart pub upgrade --major-versions

# Review changes before committing
git diff pubspec.lock
```

---

## Summary Checklist

- [ ] **Never** expose API keys in client code
- [ ] Use proxy mode for all production deployments
- [ ] Implement user authentication on your proxy
- [ ] Configure rate limiting per user
- [ ] Validate all input before processing
- [ ] Sanitize error messages shown to users
- [ ] Configure CORS with specific origins
- [ ] Enable request ID tracking for debugging
- [ ] Set up metrics collection and monitoring
- [ ] Keep dependencies updated
- [ ] Review security advisories regularly

---

## Additional Resources

- [Production Guide](./PRODUCTION_GUIDE.md)
- [Monitoring Integration](./MONITORING_INTEGRATION.md)
- [API Reference](./API_REFERENCE.md)
- [Anthropic Security Documentation](https://docs.anthropic.com/en/docs/security)
