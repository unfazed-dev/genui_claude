# ADR-0003: Dual Mode Architecture

## Status

Accepted

## Context

Applications using the Claude API have different requirements in development vs production:

**Development needs:**
- Quick setup without backend infrastructure
- Easy debugging with direct API access
- Rapid prototyping and experimentation

**Production needs:**
- API key security (not exposed on client)
- Custom authentication and authorization
- Request logging and auditing
- Rate limiting and cost control
- Additional request/response transformation

A single approach cannot satisfy both needs optimally.

## Decision

Implement a dual-mode architecture with a common interface:

```
┌─────────────────────────────────────────────────────┐
│            ClaudeContentGenerator                │
│                                                     │
│  ┌─────────────────┐    ┌────────────────────────┐ │
│  │   Direct Mode   │    │      Proxy Mode        │ │
│  │   (Development) │    │     (Production)       │ │
│  ├─────────────────┤    ├────────────────────────┤ │
│  │ - API key on    │    │ - API key on server    │ │
│  │   client        │    │ - Custom auth          │ │
│  │ - SDK retry     │    │ - Full retry control   │ │
│  │ - Quick setup   │    │ - Circuit breaker      │ │
│  └────────┬────────┘    └───────────┬────────────┘ │
│           │                         │              │
│           ▼                         ▼              │
│  ┌─────────────────┐    ┌────────────────────────┐ │
│  │DirectModeHandler│    │  ProxyModeHandler      │ │
│  │ (claude_sdk)    │    │  (http + SSE)          │ │
│  └────────┬────────┘    └───────────┬────────────┘ │
└───────────┼─────────────────────────┼──────────────┘
            │                         │
            ▼                         ▼
    ┌───────────────┐         ┌───────────────┐
    │  Claude API   │         │ Your Backend  │
    │ (Direct)      │         │  → Claude API │
    └───────────────┘         └───────────────┘
```

**Constructors:**
```dart
// Development
ClaudeContentGenerator(
  apiKey: 'sk-ant-...',
  model: 'claude-sonnet-4-20250514',
)

// Production
ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://backend.com/api/claude'),
  authToken: userJwtToken,
)

// Testing
ClaudeContentGenerator.withHandler(
  handler: mockHandler,
)
```

**Handler abstraction:**
```dart
abstract class ApiHandler {
  Stream<Map<String, dynamic>> createStream(ApiRequest request);
  void dispose();
}
```

Both modes implement the same `ApiHandler` interface, enabling:
- Consistent behavior from application perspective
- Easy testing with mock handlers
- Swapping modes without code changes

## Consequences

### Positive

1. **Appropriate security**: API key exposure only in development
2. **Flexibility**: Choose mode based on deployment target
3. **Same API**: Application code works with either mode
4. **Production features**: Proxy mode gets full resilience features
5. **Testability**: Handler abstraction enables mocking
6. **Progressive adoption**: Start with direct mode, migrate to proxy

### Negative

1. **Feature asymmetry**: Proxy mode has more features (circuit breaker, retry control)
2. **Backend requirement**: Production requires implementing proxy endpoint
3. **Two code paths**: Both modes need testing and maintenance
4. **Configuration complexity**: Different config classes per mode

### Migration Path

```dart
// 1. Start with direct mode
final generator = ClaudeContentGenerator(apiKey: '...');

// 2. Migrate to proxy mode
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://...'),
  authToken: await getAuthToken(),
);

// Application code unchanged:
generator.sendRequest(message);
generator.a2uiMessageStream.listen(...);
```

### Backend Requirements

Proxy endpoints must:
1. Accept JSON with `messages`, `tools`, `max_tokens`, `system`
2. Add Claude API key server-side
3. Forward to Claude API with streaming
4. Return SSE stream unchanged

Example (TypeScript/Supabase):
```typescript
serve(async (req) => {
  const body = await req.json();
  const stream = await anthropic.messages.stream({
    ...body,
    model: 'claude-sonnet-4-20250514',
  });
  return new Response(stream.toReadableStream(), {
    headers: { 'Content-Type': 'text/event-stream' },
  });
});
```

## Alternatives Considered

1. **Proxy-only**: Rejected because it complicates development
2. **Direct-only**: Rejected due to API key exposure in production
3. **Environment-based switching**: Rejected for explicit control preference

## References

- [OWASP API Security](https://owasp.org/www-project-api-security/)
- [Backend for Frontend pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/backends-for-frontends)
