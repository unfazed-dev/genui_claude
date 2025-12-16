# GenUI Claude

**Claude-powered generative UI for Flutter and Dart**

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-0175C2?logo=dart)](https://dart.dev)

Build AI applications where Claude dynamically generates interactive UI components at runtime. Create chatbots with rich interfaces, AI agents that compose forms on-the-fly, and intelligent assistants that render data visualizations—all powered by natural language.

## What is This?

GenUI Claude bridges Claude AI with Flutter's [GenUI SDK](https://pub.dev/packages/genui), enabling **generative user interfaces**—UI that Claude creates dynamically based on user intent rather than predefined templates.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Your Application                            │
│                                                                     │
│   User: "Show me a login form"                                      │
│                              │                                      │
│                              ▼                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │              ClaudeContentGenerator                         │   │
│   │                                                             │   │
│   │  ┌─────────────────┐    ┌────────────────────────────────┐  │   │
│   │  │ genui_claude    │───▶│       a2ui_claude              │  │   │
│   │  │ (Flutter)       │    │ (Protocol Conversion)          │  │   │
│   │  └─────────────────┘    └────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Claude generates A2UI messages:                            │   │
│   │  • BeginRendering → SurfaceUpdate → widgets...              │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Rendered UI:  ┌──────────────────────┐                     │   │
│   │                │  Login               │                     │   │
│   │                │  ┌────────────────┐  │                     │   │
│   │                │  │ Email          │  │                     │   │
│   │                │  └────────────────┘  │                     │   │
│   │                │  ┌────────────────┐  │                     │   │
│   │                │  │ Password       │  │                     │   │
│   │                │  └────────────────┘  │                     │   │
│   │                │  [ Sign In ]         │                     │   │
│   │                └──────────────────────┘                     │   │
│   └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Use Cases

- **AI Chat with Rich UI**: Chatbots that render interactive components, not just text
- **Dynamic Forms**: AI agents that generate forms based on context
- **Data Visualization**: Claude-driven charts, tables, and dashboards
- **Adaptive Interfaces**: UI that evolves based on user conversation
- **Rapid Prototyping**: Describe UI in natural language, see it rendered instantly

## Packages

| Package | Description | Platform |
|---------|-------------|----------|
| [`genui_claude`](packages/genui_claude) | Flutter `ContentGenerator` for Claude-powered GenUI. Features dual-mode architecture, streaming, circuit breaker, metrics, and comprehensive error handling. | Flutter |
| [`a2ui_claude`](packages/a2ui_claude) | Pure Dart A2UI protocol conversion. Converts between Claude API responses and A2UI messages. No Flutter dependency. | Dart (any) |

## Quick Start

### Flutter Application

```dart
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

// 1. Create your widget catalog
final genUiManager = GenUiManager(catalog: MyCatalog());

// 2. Create the content generator
final contentGenerator = ClaudeContentGenerator(
  apiKey: 'your-api-key',  // Use env vars in production!
  systemInstruction: 'You are a helpful assistant that generates UI.',
);

// 3. Create the conversation
final conversation = GenUiConversation(
  contentGenerator: contentGenerator,
  genUiManager: genUiManager,
  onSurfaceAdded: (update) => handleNewSurface(update),
  onTextResponse: (text) => updateTextMessage(text),
);

// 4. Send requests
conversation.sendRequest(UserMessage.text('Create a contact form'));
```

### Pure Dart (Backend, CLI, Edge Functions)

```dart
import 'package:a2ui_claude/a2ui_claude.dart';

// Parse Claude responses into A2UI messages
final result = ClaudeA2uiParser.parseMessage(response);

for (final message in result.a2uiMessages) {
  switch (message) {
    case BeginRenderingData(:final surfaceId):
      print('Begin: $surfaceId');
    case SurfaceUpdateData(:final surfaceId, :final widgets):
      print('Update $surfaceId with ${widgets.length} widgets');
    case DataModelUpdateData(:final updates):
      print('Data: ${updates.keys}');
    case DeleteSurfaceData(:final surfaceId):
      print('Delete: $surfaceId');
  }
}
```

## Installation

### From Git (Current)

```yaml
# pubspec.yaml
dependencies:
  # For Flutter apps
  genui: ^0.5.1
  genui_claude:
    git:
      url: https://github.com/unfazed-dev/genui_claude.git
      path: packages/genui_claude

  # For pure Dart (CLI, server, edge functions)
  a2ui_claude:
    git:
      url: https://github.com/unfazed-dev/genui_claude.git
      path: packages/a2ui_claude
```

## Architecture

### Direct vs Proxy Mode

Choose the right mode for your deployment:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Which Mode Should I Use?                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Development / Prototyping?                                        │
│        │                                                            │
│        ├── YES ──▶  Direct Mode                                     │
│        │           • API key in app (ok for dev)                    │
│        │           • Simplest setup                                 │
│        │           • Quick iteration                                │
│        │                                                            │
│        └── NO ───▶  Production?                                     │
│                         │                                           │
│                         └── YES ──▶  Proxy Mode                     │
│                                      • API key on backend (secure)  │
│                                      • Full resilience features     │
│                                      • Rate limiting control        │
│                                      • Usage tracking               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Direct Mode** (Development):
```dart
final generator = ClaudeContentGenerator(
  apiKey: 'your-api-key',
  systemInstruction: 'You generate UI.',
);
```

**Proxy Mode** (Production):
```dart
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: userAuthToken,
  proxyConfig: const ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
  ),
);
```

### Package Relationship

```
┌──────────────────────────────────────────────────────────────────┐
│                      genui_claude                                │
│                      (Flutter Package)                           │
│                                                                  │
│  • ClaudeContentGenerator (main entry point)                     │
│  • A2uiMessageAdapter (message conversion)                       │
│  • CatalogToolBridge (catalog → Claude tools)                    │
│  • CircuitBreaker, Retry, Metrics                                │
│                                                                  │
│                            │                                     │
│                            │ depends on                          │
│                            ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    a2ui_claude                             │  │
│  │                    (Pure Dart Package)                     │  │
│  │                                                            │  │
│  │  • A2uiToolConverter (tool schema conversion)              │  │
│  │  • ClaudeA2uiParser (response parsing)                     │  │
│  │  • ClaudeStreamHandler (SSE streaming)                     │  │
│  │  • A2UI message types (sealed classes)                     │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Key Features

### Streaming Support
Real-time progressive UI rendering as Claude generates responses:
```dart
contentGenerator.a2uiMessageStream.listen((message) {
  // UI updates progressively as Claude responds
});
```

### Production Resilience
Built-in circuit breaker and retry with exponential backoff:
```dart
const config = ClaudeConfig(
  retryAttempts: 3,
  // Circuit breaker prevents cascade failures
);
```

### Type-Safe Errors
Sealed exception hierarchy with exhaustive pattern matching:
```dart
try {
  await generator.sendRequest(...);
} on RateLimitException catch (e) {
  // Handle rate limiting
} on NetworkException catch (e) {
  if (e.isRetryable) { /* retry */ }
}
```

### Observability
Built-in metrics collection:
```dart
globalMetricsCollector.eventStream.listen((event) {
  print('${event.eventType}: ${event.toMap()}');
});

final stats = globalMetricsCollector.stats;
print('Success rate: ${stats.successRate}%');
```

## Creating a Widget Catalog

Define the widgets Claude can generate:

```dart
class MyCatalog extends Catalog {
  MyCatalog() : super(_items);

  static final List<CatalogItem> _items = [
    CatalogItem(
      name: 'info_card',
      dataSchema: S.object(
        description: 'A card displaying information',
        properties: {
          'title': S.string(description: 'Card title'),
          'content': S.string(description: 'Card content'),
        },
        required: ['title', 'content'],
      ),
      widgetBuilder: (context) {
        final props = context.data as Map<String, dynamic>? ?? {};
        return InfoCard(
          title: props['title'] ?? '',
          content: props['content'] ?? '',
        );
      },
    ),
    // Add more widgets...
  ];
}
```

## Documentation

### genui_claude (Flutter)
- [README](packages/genui_claude/README.md) - Quick start and overview
- [API Reference](packages/genui_claude/doc/API_REFERENCE.md) - Complete class documentation
- [Examples](packages/genui_claude/doc/EXAMPLES.md) - Practical code examples
- [Production Guide](packages/genui_claude/doc/PRODUCTION_GUIDE.md) - Deployment and hardening

### a2ui_claude (Pure Dart)
- [README](packages/a2ui_claude/README.md) - Quick start and API overview
- [Examples](packages/a2ui_claude/example/) - Tool conversion, parsing, streaming

## Development

This repository uses [Melos](https://melos.invertase.dev/) for monorepo management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap (install deps, link packages)
melos bootstrap

# Run tests
melos run test

# Run analyzer
melos run analyze
```

## License

BSD-3-Clause License - see [LICENSE](LICENSE) for details.

---

Authored and orchestrated by **Evan Pierre Louis - (unfazed-dev)**, with pair programming powered by [Claude Code](https://claude.com/claude-code) from Anthropic.
