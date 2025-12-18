# genui_claude

[![Test Coverage](https://img.shields.io/badge/coverage-view%20report-blue)](coverage/html/index.html)

Flutter ContentGenerator implementation for Claude AI, enabling Claude-powered generative UI with the [GenUI SDK](https://pub.dev/packages/genui).

## Features

- **Claude-Powered GenUI**: Integrate Claude AI with Flutter's GenUI SDK
- **Direct & Proxy Modes**: Development-friendly direct API access or production-ready backend proxy
- **Streaming Support**: Real-time progressive UI rendering as Claude generates responses
- **Type-Safe Adapters**: Convert between a2ui_claude and GenUI message formats
- **Catalog Tool Bridge**: Automatically convert GenUI catalogs to Claude tool schemas
- **Production Resilience**: Circuit breaker pattern, retry with exponential backoff and jitter
- **Observability**: Built-in metrics collection with event streaming and aggregated statistics
- **Type-Safe Errors**: Sealed exception hierarchy with exhaustive pattern matching
- **Data Binding Engine**: Two-way binding between widgets and data models with path expressions
- **Tool Search**: Dynamic tool discovery for large catalogs with keyword-based search

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  genui: ^0.5.1
  genui_claude:
    git:
      url: https://github.com/unfazed-dev/genui_claude.git
      path: packages/genui_claude
```

## Quick Start

### Basic Usage (Development)

```dart
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

// Create the GenUI manager with your catalog
final genUiManager = GenUiManager(catalog: MyCatalog());

// Create the content generator with direct API access
final contentGenerator = ClaudeContentGenerator(
  apiKey: 'your-api-key', // Use environment variable in production!
  systemInstruction: 'You are a helpful assistant that generates UI.',
);

// Create the conversation
final conversation = GenUiConversation(
  contentGenerator: contentGenerator,
  genUiManager: genUiManager,
  onSurfaceAdded: (update) {
    // Handle new UI surface
  },
  onTextResponse: (text) {
    // Handle text responses
  },
);

// Send a request
conversation.sendRequest(UserMessage.text('Create a login form'));
```

### Production Usage (Backend Proxy)

```dart
// Use proxy mode for production - API key stays on your backend
final contentGenerator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: userAuthToken,
  proxyConfig: const ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
    maxHistoryMessages: 20,
  ),
);
```

## Architecture

### System Context

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Flutter Application                            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    GenUiConversation                          │  │
│  │  ┌─────────────────┐  ┌────────────────────────────────────┐  │  │
│  │  │  GenUiManager   │  │  ClaudeContentGenerator         │  │  │
│  │  │  (Catalog)      │  │  ┌──────────────────────────────┐  │  │  │
│  │  │                 │  │  │  a2ui_claude              │  │  │  │
│  │  │  - Widgets      │──│  │  - Tool Conversion           │  │  │  │
│  │  │  - Data Model   │  │  │  - Message Parsing           │  │  │  │
│  │  │  - Surfaces     │  │  │  - Stream Handling           │  │  │  │
│  │  └─────────────────┘  │  └──────────────────────────────┘  │  │  │
│  │                       └──────────────┬─────────────────────┘  │  │
│  └──────────────────────────────────────┼────────────────────────┘  │
│                                         │                            │
│  ┌──────────────────────────────────────▼────────────────────────┐  │
│  │                     GenUiSurface Widgets                      │  │
│  │  (Rendered UI based on A2UI messages)                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
           ┌────────▼────────┐           ┌─────────▼─────────┐
           │  Direct Mode    │           │   Proxy Mode      │
           │  (Development)  │           │   (Production)    │
           │                 │           │                   │
           │  Claude API     │           │  Your Backend     │
           │  (api.anthropic │           │  → Claude API     │
           │   .com)         │           │                   │
           └─────────────────┘           └───────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| `ClaudeContentGenerator` | Main ContentGenerator implementation for Claude |
| `A2uiMessageAdapter` | Converts a2ui_claude messages to GenUI format |
| `CatalogToolBridge` | Converts GenUI catalog items to Claude tool schemas |
| `A2uiControlTools` | Pre-defined A2UI control tools (begin_rendering, surface_update, etc.) |
| `MessageConverter` | Converts GenUI ChatMessages to Claude API format |

## Configuration

### ClaudeConfig (Direct Mode)

```dart
const config = ClaudeConfig(
  maxTokens: 4096,         // Maximum tokens in response
  timeout: Duration(seconds: 60),  // Request timeout
  retryAttempts: 3,        // Retry attempts for transient failures
  enableStreaming: true,   // Enable streaming responses
  headers: {'X-Custom': 'header'},  // Custom HTTP headers
);
```

### ProxyConfig (Proxy Mode)

```dart
const config = ProxyConfig(
  timeout: Duration(seconds: 120),  // Request timeout
  retryAttempts: 3,        // Retry attempts
  includeHistory: true,    // Send conversation history
  maxHistoryMessages: 20,  // Maximum history messages to include
  headers: {'X-Custom': 'header'},  // Custom HTTP headers
);
```

## Creating a Widget Catalog

Define widgets that Claude can generate:

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
          'icon': S.string(description: 'Icon name'),
        },
        required: ['title', 'content'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return InfoCard(
          title: props['title'] ?? '',
          content: props['content'] ?? '',
          icon: props['icon'],
        );
      },
    ),
    // Add more catalog items...
  ];
}
```

## Tool Bridge Usage

Convert your catalog to Claude tools:

```dart
// From catalog items
final widgetTools = CatalogToolBridge.fromItems(MyCatalog.items);

// From a Catalog instance
final widgetTools = CatalogToolBridge.fromCatalog(myCatalog);

// Include A2UI control tools
final allTools = CatalogToolBridge.withA2uiTools(widgetTools);
```

## Supabase Edge Function Template

For production deployments, use a backend proxy. Example Supabase Edge Function:

```typescript
// supabase/functions/claude-genui/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Anthropic from 'npm:@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: Deno.env.get('CLAUDE_API_KEY')!,
})

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 })
  }

  const { messages, tools, systemPrompt } = await req.json()

  const stream = await anthropic.messages.stream({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 4096,
    system: systemPrompt,
    messages,
    tools,
  })

  return new Response(
    new ReadableStream({
      async start(controller) {
        for await (const event of stream) {
          controller.enqueue(
            new TextEncoder().encode(JSON.stringify(event) + '\n')
          )
        }
        controller.close()
      },
    }),
    {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    }
  )
})
```

## Documentation

### Guides
- [API Reference](doc/API_REFERENCE.md) - Complete API documentation with all classes, methods, and properties
- [Examples](doc/EXAMPLES.md) - Practical code examples, patterns, and troubleshooting guide
- [Production Guide](doc/PRODUCTION_GUIDE.md) - Deployment and production hardening guide
- [FAQ](doc/FAQ.md) - Frequently asked questions and troubleshooting

### Configuration & Tuning
- [Performance Tuning](doc/PERFORMANCE_TUNING.md) - Optimization guide for timeouts, retries, and circuit breaker
- [Debug Logging](doc/DEBUG_LOGGING.md) - Logging configuration guide
- [Catalog Patterns](doc/CATALOG_PATTERNS.md) - Best practices for widget catalogs

### Production
- [Security Best Practices](doc/SECURITY_BEST_PRACTICES.md) - Security guidelines for production deployments
- [Monitoring Integration](doc/MONITORING_INTEGRATION.md) - Integrate metrics with DataDog, Firebase, etc.
- [Migration Guide](doc/MIGRATION_GUIDE.md) - Version migration instructions and helpers
- [Coverage Matrix](doc/COVERAGE_MATRIX.md) - Test coverage overview and CI/CD setup

## Testing

Run tests:

```bash
flutter test
```

Run tests with coverage:

```bash
./tool/coverage.sh          # Run tests with coverage
./tool/coverage.sh --html   # Generate HTML report
./tool/coverage.sh --open   # Generate and open HTML report
```

## Related Packages

- [genui](https://pub.dev/packages/genui) - Flutter GenUI SDK
- [a2ui_claude](../a2ui_claude) - A2UI protocol conversion (Dart)

## License

MIT License - see [LICENSE](LICENSE) for details.
