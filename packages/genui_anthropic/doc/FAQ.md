# Frequently Asked Questions

Common questions and troubleshooting for genui_anthropic.

## Table of Contents

- [General](#general)
- [Setup & Configuration](#setup--configuration)
- [Proxy Mode](#proxy-mode)
- [Error Handling](#error-handling)
- [Streaming](#streaming)
- [Widget Catalogs](#widget-catalogs)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)

---

## General

### What is genui_anthropic?

genui_anthropic is a Flutter package that implements the GenUI SDK's `ContentGenerator` interface for Anthropic's Claude AI. It enables Claude to generate dynamic, interactive UIs in Flutter applications using the A2UI (Anthropic to UI) protocol.

### What's the difference between Direct and Proxy modes?

| Feature | Direct Mode | Proxy Mode |
|---------|-------------|------------|
| API Key Location | Client-side | Server-side |
| Use Case | Development, prototyping | Production |
| Retry Logic | SDK-managed | Full control |
| Circuit Breaker | Not available | Available |
| Security | API key exposed | API key secure |

### Which Claude models are supported?

Any Claude model that supports tool use:
- `claude-sonnet-4-20250514` (recommended)
- `claude-opus-4-20250514`
- Other Claude 3+ models

---

## Setup & Configuration

### How do I get started?

```dart
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

// Development mode
final generator = AnthropicContentGenerator(
  apiKey: 'your-api-key',
  model: 'claude-sonnet-4-20250514',
);

// Production mode
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: userToken,
);
```

### How do I configure timeouts?

```dart
// Direct mode
final config = AnthropicConfig(
  timeout: Duration(seconds: 60),
  maxTokens: 4096,
);

final generator = AnthropicContentGenerator(
  apiKey: apiKey,
  config: config,
);

// Proxy mode
final proxyConfig = ProxyConfig(
  timeout: Duration(seconds: 120),
);

final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: endpoint,
  proxyConfig: proxyConfig,
);
```

### How do I set custom headers?

```dart
final config = AnthropicConfig(
  headers: {
    'X-Custom-Header': 'value',
    'X-Request-Source': 'mobile-app',
  },
);
```

---

## Proxy Mode

### Why should I use proxy mode in production?

1. **Security**: API key stays on your server
2. **Control**: Add custom authentication, rate limiting, logging
3. **Resilience**: Full retry and circuit breaker control
4. **Flexibility**: Transform requests/responses as needed

### What should my proxy endpoint return?

Your proxy should:
1. Accept JSON with `messages`, `tools`, `max_tokens`, `system` fields
2. Add your API key server-side
3. Forward to Claude API
4. Stream SSE responses back unchanged

Example response format (Server-Sent Events):
```
data: {"type": "message_start", "message": {...}}

data: {"type": "content_block_start", ...}

data: {"type": "content_block_delta", ...}
```

### How do I handle authentication in proxy mode?

```dart
// Client-side: Send auth token
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://api.example.com/claude'),
  authToken: await getJwtToken(), // Bearer token
);

// Server-side: Validate token before forwarding
```

---

## Error Handling

### What exceptions can be thrown?

| Exception | HTTP Status | Retryable | When |
|-----------|-------------|-----------|------|
| `NetworkException` | - | Yes | Connection/DNS failures |
| `TimeoutException` | - | Yes | Request/stream timeout |
| `AuthenticationException` | 401, 403 | No | Invalid API key |
| `RateLimitException` | 429 | Yes | Rate limit hit |
| `ValidationException` | 400, 422 | No | Invalid request |
| `ServerException` | 5xx | Yes | Claude API errors |
| `StreamException` | - | No | SSE parsing error |
| `CircuitBreakerOpenException` | - | Yes | Circuit breaker open |

### How do I handle errors in my UI?

```dart
final generator = AnthropicContentGenerator.proxy(...);

// Listen to error stream
generator.errorStream.listen((error) {
  final exception = error['exception'] as AnthropicException?;

  if (exception is AuthenticationException) {
    // Redirect to login
  } else if (exception is RateLimitException) {
    // Show "please wait" message
  } else if (exception?.isRetryable == true) {
    // Show retry button
  } else {
    // Show generic error
  }
});
```

### How do I implement retry logic?

```dart
// Retry is automatic in proxy mode with RetryConfig
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: endpoint,
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
    jitterFactor: 0.1, // ±10% randomness
  ),
);
```

---

## Streaming

### Why aren't I receiving stream events?

1. **Check your proxy**: Ensure it returns `Content-Type: text/event-stream`
2. **Check for errors**: Listen to `errorStream` for exceptions
3. **Check circuit breaker**: It may be open due to failures
4. **Check timeout**: Stream may have timed out due to inactivity

### How do I handle stream inactivity?

The default stream inactivity timeout is 60 seconds. If no data is received for this duration, a `TimeoutException` is thrown.

```dart
// Customize timeout
final handler = ProxyModeHandler(
  endpoint: endpoint,
  streamInactivityTimeout: Duration(seconds: 90),
);
```

### How do I show a loading indicator?

```dart
// Use the isProcessing ValueListenable
ValueListenableBuilder<bool>(
  valueListenable: generator.isProcessing,
  builder: (context, isProcessing, child) {
    if (isProcessing) {
      return CircularProgressIndicator();
    }
    return child!;
  },
  child: YourContent(),
);
```

---

## Widget Catalogs

### How do I create a widget catalog?

```dart
class MyCatalog extends Catalog {
  MyCatalog() : super(_items);

  static final List<CatalogItem> _items = [
    CatalogItem(
      name: 'button',
      dataSchema: S.object(
        description: 'A clickable button',
        properties: {
          'label': S.string(description: 'Button text'),
          'onTap': S.string(description: 'Action identifier'),
        },
        required: ['label'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        return ElevatedButton(
          onPressed: () => context.onAction(data['onTap'] ?? 'click'),
          child: Text(data['label'] ?? ''),
        );
      },
    ),
  ];
}
```

### How do I convert my catalog to Claude tools?

```dart
// Convert catalog items to tool schemas
final tools = CatalogToolBridge.fromCatalog(myCatalog);

// Include A2UI control tools
final allTools = CatalogToolBridge.withA2uiTools(tools);
```

### Why isn't Claude using my widget?

1. **Check the schema**: Ensure `description` is clear and helpful
2. **Check required fields**: Mark essential fields as required
3. **Test the schema**: Validate JSON schema is correct
4. **Prompt engineering**: Guide Claude to use specific widgets in system instruction

---

## Performance

### How do I reduce latency?

1. **Use streaming**: Already enabled by default
2. **Limit history**: Set `maxHistoryMessages` in `ProxyConfig`
3. **Use smaller models**: `claude-sonnet` is faster than `claude-opus`
4. **Optimize prompts**: Shorter system instructions = faster first token

### How do I monitor performance?

```dart
// Use the metrics collector
globalMetricsCollector.eventStream.listen((event) {
  print('${event.eventType}: ${event.toMap()}');
});

// Access statistics
final stats = globalMetricsCollector.stats;
print('Success rate: ${stats.successRate}%');
print('P95 latency: ${stats.p95LatencyMs}ms');
```

---

## Troubleshooting

### "Circuit breaker is open" error

The circuit breaker opens after multiple failures to prevent cascading failures.

**Solution:**
1. Wait for recovery timeout (default: 30s)
2. Fix the underlying issue (API key, network, etc.)
3. Call `circuitBreaker.reset()` to manually reset

### "Stream inactivity timeout" error

No data received within the timeout period.

**Possible causes:**
1. Network issues
2. Proxy not streaming correctly
3. Claude taking too long to respond

**Solutions:**
1. Increase `streamInactivityTimeout`
2. Check proxy SSE implementation
3. Check network connectivity

### "Authentication failed" error

**Possible causes:**
1. Invalid or expired API key
2. Invalid auth token (proxy mode)
3. Missing Authorization header

**Solutions:**
1. Verify API key is correct
2. Refresh auth token
3. Check proxy authentication logic

### "Rate limit exceeded" error

You've hit Claude API rate limits.

**Solutions:**
1. Implement backoff (automatic with `RetryConfig`)
2. Reduce request frequency
3. Contact Anthropic for higher limits

### Widget not rendering

**Possible causes:**
1. Invalid widget data from Claude
2. Missing catalog item
3. Widget builder throwing exception

**Debug steps:**
1. Listen to `a2uiMessageStream` and log events
2. Check widget name matches catalog
3. Wrap widget builder in try-catch

```dart
generator.a2uiMessageStream.listen((message) {
  print('A2UI: ${message.toMap()}');
});
```

---

## Still Need Help?

- Check the [API Reference](API_REFERENCE.md)
- Review [Examples](EXAMPLES.md)
- Read the [Production Guide](PRODUCTION_GUIDE.md)
- File an issue on GitHub
