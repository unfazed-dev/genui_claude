---
name: genui-claude
description: Claude AI integration for Flutter GenUI SDK with A2UI protocol, streaming handlers, Supabase edge functions, and production deployment patterns. Use when building Claude-powered generative UIs, deploying GenUI backends, or integrating Claude with widget catalogs.
---

# GenUI Claude

Flutter SDK for Claude-powered generative UI. Enables Claude to dynamically generate and render interactive widgets at runtime using the A2UI (Agent-to-UI) protocol.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GENUI CLAUDE FLOW                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Flutter App                                                            │
│  ───────────                                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ClaudeContentGenerator                                       │   │
│  │  ├── Direct Mode (dev)  → anthropic_sdk_dart → Claude API       │   │
│  │  └── Proxy Mode (prod)  → HTTP → Your Backend → Claude API      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│           │                                                             │
│           ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Three Concurrent Streams                                        │   │
│  │  ├── a2uiMessageStream  → UI generation (surfaces, widgets)     │   │
│  │  ├── textResponseStream → Conversational text                   │   │
│  │  └── errorStream        → Error handling                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│           │                                                             │
│           ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  GenUI Rendering                                                 │   │
│  │  ├── GenUiManager     → Manages surfaces and catalogs           │   │
│  │  ├── GenUiSurface     → Renders widget trees                    │   │
│  │  └── Catalog          → Maps tool calls to Flutter widgets      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Mode Decision Tree

```
Is this production deployment?
│
├── NO → Use Direct Mode
│        • API key in environment variable
│        • Quick prototyping
│        • Local development
│
└── YES → Use Proxy Mode
          • Deploy Supabase Edge Function (see references/supabase-edge.md)
          • API key stays on server
          • User auth tokens for access control
```

## Quick Start: Direct Mode (Development)

```dart
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ClaudeContentGenerator _generator;
  late final GenUiConversation _conversation;

  @override
  void initState() {
    super.initState();

    // 1. Create content generator (direct mode)
    _generator = ClaudeContentGenerator(
      apiKey: const String.fromEnvironment('CLAUDE_API_KEY'),
      model: 'claude-sonnet-4-20250514',
      systemInstruction: '''
You are a UI assistant. Generate interactive widgets when appropriate.
Use the available tools to create forms, cards, and interactive components.
''',
    );

    // 2. Create GenUI manager with catalog
    final genUiManager = GenUiManager(catalog: MyCatalog());

    // 3. Create conversation
    _conversation = GenUiConversation(
      contentGenerator: _generator,
      genUiManager: genUiManager,
      onSurfaceAdded: (update) => setState(() {}),
      onTextResponse: (text) => print('Text: $text'),
      onError: (error) => print('Error: $error'),
    );
  }

  void _sendMessage(String text) {
    _conversation.sendRequest(UserMessage.text(text));
  }

  @override
  void dispose() {
    _generator.dispose();
    _conversation.dispose();
    super.dispose();
  }
}
```

## Quick Start: Proxy Mode (Production)

```dart
// 1. Deploy backend first (see references/supabase-edge.md)

// 2. Create generator with proxy endpoint
_generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-project.supabase.co/functions/v1/claude-genui'),
  authToken: userAuthToken,  // User's JWT token
  proxyConfig: ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
    maxHistoryMessages: 20,
  ),
);
```

## A2UI Protocol Essentials

Claude uses four control tools to generate UI:

| Tool | Purpose |
|------|---------|
| `begin_rendering` | Signals start of UI generation for a surface |
| `surface_update` | Updates widget tree with components |
| `data_model_update` | Updates bound data values |
| `delete_surface` | Removes a UI surface |

**Message Flow:**
1. User sends message → Claude receives with tool schemas
2. Claude calls `begin_rendering` with unique `surfaceId`
3. Claude calls `surface_update` with widget tree
4. GenUI renders widgets from catalog

## Stream Handling

```dart
// Listen to all three streams
_generator.a2uiMessageStream.listen((message) {
  // Handle: BeginRendering, SurfaceUpdate, DataModelUpdate, SurfaceDeletion
  switch (message) {
    case BeginRendering(:final surfaceId):
      print('New surface: $surfaceId');
    case SurfaceUpdate(:final surfaceId, :final components):
      print('Updated $surfaceId with ${components.length} widgets');
    // ...
  }
});

_generator.textResponseStream.listen((text) {
  // Handle streaming text chunks
  print('Text chunk: $text');
});

_generator.errorStream.listen((error) {
  // Handle errors
  print('Error: ${error.error}');
});

// Check processing state
ValueListenableBuilder<bool>(
  valueListenable: _generator.isProcessing,
  builder: (_, isProcessing, __) {
    return isProcessing ? CircularProgressIndicator() : SendButton();
  },
);
```

## Widget Catalog Integration

Convert your catalog to Claude tools:

```dart
import 'package:genui_claude/genui_claude.dart';

// Your widget catalog
final catalog = Catalog(components: [
  CatalogItem(
    name: 'info_card',
    dataSchema: S.object(
      description: 'Display information in a card',
      properties: {
        'title': S.string(description: 'Card title'),
        'content': S.string(description: 'Card content'),
      },
      required: ['title', 'content'],
    ),
    widgetBuilder: (context) => InfoCardWidget(...),
  ),
]);

// Convert to Claude tools (automatic in GenUiConversation)
final widgetTools = CatalogToolBridge.fromCatalog(catalog);
final allTools = CatalogToolBridge.withA2uiTools(widgetTools);
// Result: [begin_rendering, surface_update, data_model_update, delete_surface, info_card]
```

See [references/widget-tools.md](references/widget-tools.md) for schema conversion details.

## Testing

Use handler injection for testing:

```dart
class MockApiHandler implements ApiHandler {
  final _events = <Map<String, dynamic>>[];

  void stubResponse(List<Map<String, dynamic>> events) {
    _events.addAll(events);
  }

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    for (final event in _events) {
      yield event;
    }
  }

  @override
  void dispose() {}
}

// In tests
final mockHandler = MockApiHandler();
mockHandler.stubResponse([
  {'type': 'content_block_start', 'content_block': {'type': 'tool_use', 'name': 'begin_rendering'}},
  // ... more events
]);

final generator = ClaudeContentGenerator.withHandler(
  handler: mockHandler,
  systemInstruction: 'Test instruction',
);
```

See [test/helpers/mock_generators.dart](../../packages/genui_claude/test/helpers/mock_generators.dart) for complete mock implementation.

## Common Issues

| Issue | Solution |
|-------|----------|
| Widgets not rendering | Verify catalog item names match tool calls from Claude |
| API key exposed | Use proxy mode for production |
| Request timeout | Increase `ClaudeConfig.timeout` or `ProxyConfig.timeout` |
| Stream errors | Check `errorStream` for detailed error messages |
| History too large | Configure `ProxyConfig.maxHistoryMessages` |
| Concurrent requests | Check `isProcessing` before calling `sendRequest` |

## Configuration Reference

**Direct Mode:**
```dart
// Custom configuration
ClaudeConfig(
  maxTokens: 4096,           // Max response tokens
  timeout: Duration(seconds: 60),
  retryAttempts: 3,
  enableStreaming: true,
  headers: {'X-Custom': 'value'},
)

// Pre-defined
ClaudeConfig.defaults  // 4096 tokens, 60s timeout, 3 retries
```

**Proxy Mode:**
```dart
// Custom configuration
ProxyConfig(
  timeout: Duration(seconds: 120),
  retryAttempts: 3,
  includeHistory: true,
  maxHistoryMessages: 20,
  headers: {'X-Custom': 'value'},
)

// Pre-defined
ProxyConfig.defaults  // 120s timeout, history enabled
```

## Resilience & Observability

### Circuit Breaker

Prevents cascading failures with three states: closed (normal), open (failing fast), half-open (testing recovery).

| Config | Failures | Recovery | Use Case |
|--------|----------|----------|----------|
| `CircuitBreakerConfig.defaults` | 5 | 30s | Standard apps |
| `CircuitBreakerConfig.lenient` | 10 | 60s | High-tolerance |
| `CircuitBreakerConfig.strict` | 3 | 15s | Critical paths |

### Retry Configuration

Built-in retry strategies with exponential backoff and jitter:

| Config | Attempts | Initial Delay | Use Case |
|--------|----------|---------------|----------|
| `RetryConfig.defaults` | 3 | 1s | Standard |
| `RetryConfig.aggressive` | 5 | 500ms | User-facing |
| `RetryConfig.noRetry` | 0 | - | Testing |

### Metrics

```dart
final collector = MetricsCollector();
collector.eventStream.listen((event) {
  // RequestStartEvent, RequestSuccessEvent, RequestFailureEvent
  // RetryAttemptEvent, RateLimitEvent, CircuitBreakerStateChangeEvent
  analytics.track(event.eventType, event.toMap());
});
```

See [references/resilience-patterns.md](references/resilience-patterns.md) for comprehensive resilience documentation.

## References

- [API Patterns](references/api-patterns.md) - Handler patterns, stream processing, message conversion
- [Widget Tools](references/widget-tools.md) - CatalogToolBridge, A2UI control tools, schema conversion
- [Resilience Patterns](references/resilience-patterns.md) - Circuit breaker, retry, metrics, production checklist
- [Supabase Edge Functions](references/supabase-edge.md) - Backend deployment, security patterns
- [Standalone Usage](references/standalone-usage.md) - Pure Dart (a2ui_claude) for CLI, server, edge functions
