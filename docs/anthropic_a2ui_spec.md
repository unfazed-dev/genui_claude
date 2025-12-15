# anthropic_a2ui

## Technical Specification Document

**Pure Dart Package for Claude API to A2UI Protocol Conversion**

Version 1.0.0 | December 2025

---

| Field | Value |
|-------|-------|
| Document Owner | unfazed-dev (github.com/unfazed-dev) |
| Package Type | Pure Dart (no Flutter dependency) |
| Target Environments | Flutter, Dart CLI, Server-side Dart, Edge Functions |
| License | MIT |
| Repository | github.com/unfazed-dev/anthropic_genui (monorepo) |
| Package Path | packages/anthropic_a2ui |

---

## 1. Executive Summary

The anthropic_a2ui package provides a pure Dart implementation for converting between Anthropic's Claude API responses and the A2UI (Agent-to-UI) protocol messages. This package serves as the foundational layer for integrating Claude's language model capabilities with generative UI frameworks.

By maintaining zero Flutter dependencies, this package can be deployed across multiple environments including Flutter applications, Dart command-line tools, server-side Dart applications, and edge computing functions such as Supabase Edge Functions or Cloudflare Workers.

---

## 2. Problem Statement

### 2.1 Current Landscape

The Flutter GenUI SDK provides excellent support for generative UI through its ContentGenerator abstraction. However, the existing implementations are limited to Google's ecosystem:

- genui_firebase_ai - Firebase/Gemini integration
- genui_google_generative_ai - Direct Gemini API
- genui_a2ui - Generic A2UI server connection

### 2.2 Gap Analysis

There is no existing solution for using Anthropic's Claude models with the GenUI framework. This creates a significant limitation for developers who prefer Claude's capabilities or require vendor diversity in their AI implementations.

### 2.3 Solution Overview

This package bridges the gap by providing protocol-level conversion between Claude's tool_use responses and A2UI messages, enabling seamless integration with any A2UI-compatible renderer including Flutter's GenUI SDK.

---

## 3. Architecture

### 3.1 Design Principles

- **Pure Dart:** No Flutter SDK dependency enables broad deployment
- **Single Responsibility:** Focused solely on protocol conversion
- **Streaming First:** Built for real-time progressive UI rendering
- **Type Safety:** Comprehensive Dart type definitions
- **Testability:** All components independently testable

### 3.2 System Context

The package operates as a middleware layer between the Claude API and UI rendering systems:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Consumer Applications                         │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Flutter App    │  Dart Server    │  Edge Function              │
│  (genui_anthropic)│  (API backend)  │  (Supabase/Cloudflare)     │
└────────┬────────┴────────┬────────┴──────────┬──────────────────┘
         │                 │                   │
         └─────────────────┴───────────────────┘
                           │
              ┌────────────▼────────────┐
              │    anthropic_a2ui       │
              │  ┌──────────────────┐   │
              │  │ Tool Converter   │   │
              │  │ Message Parser   │   │
              │  │ Stream Handler   │   │
              │  └──────────────────┘   │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  anthropic_sdk_dart     │
              │  (Claude API Client)    │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │   Anthropic Claude API  │
              └─────────────────────────┘
```

### 3.3 Component Overview

| Component | Responsibility | Key Classes |
|-----------|---------------|-------------|
| Tool Converter | Converts A2UI tool schemas to Claude tool definitions | A2uiToolConverter, ClaudeToolSchema |
| Message Parser | Parses Claude responses into A2UI messages | ClaudeA2uiParser, A2uiMessageData |
| Stream Handler | Manages SSE streaming and progressive parsing | ClaudeStreamHandler, StreamConfig |
| Models | Type-safe data structures | SurfaceUpdateData, DataModelUpdateData |

---

## 4. Data Models

### 4.1 A2UI Message Types

The A2UI protocol defines several message types for UI orchestration. This package provides Dart representations of each:

#### 4.1.1 BeginRenderingData

Signals the start of a UI generation sequence.

```dart
class BeginRenderingData extends A2uiMessageData {
  final String surfaceId;
  final String? parentSurfaceId;
  final Map<String, dynamic>? metadata;
  
  BeginRenderingData({
    required this.surfaceId,
    this.parentSurfaceId,
    this.metadata,
  });
}
```

#### 4.1.2 SurfaceUpdateData

Contains the widget tree definition for a UI surface.

```dart
class SurfaceUpdateData extends A2uiMessageData {
  final String surfaceId;
  final List<WidgetNode> widgets;
  final bool append;
  
  SurfaceUpdateData({
    required this.surfaceId,
    required this.widgets,
    this.append = false,
  });
}

class WidgetNode {
  final String type;
  final Map<String, dynamic> properties;
  final List<WidgetNode>? children;
  final String? dataBinding;
}
```

#### 4.1.3 DataModelUpdateData

Updates bound data values that widgets observe.

```dart
class DataModelUpdateData extends A2uiMessageData {
  final Map<String, dynamic> updates;
  final String? scope;
  
  DataModelUpdateData({
    required this.updates,
    this.scope,
  });
}
```

#### 4.1.4 DeleteSurfaceData

Removes a UI surface from the rendering tree.

```dart
class DeleteSurfaceData extends A2uiMessageData {
  final String surfaceId;
  final bool cascade;
  
  DeleteSurfaceData({
    required this.surfaceId,
    this.cascade = true,
  });
}
```

### 4.2 Tool Schema Types

#### 4.2.1 A2uiToolSchema

Represents a UI tool that can be converted to Claude's tool format.

```dart
class A2uiToolSchema {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final List<String>? requiredFields;
  
  /// Convert to Claude API tool format
  ClaudeTool toClaudeTool() => ClaudeTool(
    name: name,
    description: description,
    inputSchema: InputSchema.fromJson(inputSchema),
  );
}
```

---

## 5. Core APIs

### 5.1 A2uiToolConverter

Handles bidirectional conversion between A2UI tool schemas and Claude tool definitions.

```dart
class A2uiToolConverter {
  /// Convert A2UI tools to Claude format
  static List<Tool> toClaudeTools(List<A2uiToolSchema> schemas) {
    return schemas.map((schema) => Tool(
      name: schema.name,
      description: _enhanceDescription(schema),
      inputSchema: Schema.object(
        properties: _convertProperties(schema.inputSchema),
        required: schema.requiredFields,
      ),
    )).toList();
  }
  
  /// Generate system prompt supplement for tool usage
  static String generateToolInstructions(List<A2uiToolSchema> schemas) {
    final buffer = StringBuffer();
    buffer.writeln('Available UI tools:');
    for (final schema in schemas) {
      buffer.writeln('- ${schema.name}: ${schema.description}');
    }
    return buffer.toString();
  }
  
  /// Validate tool response against schema
  static ValidationResult validateToolInput(
    String toolName,
    Map<String, dynamic> input,
    List<A2uiToolSchema> schemas,
  );
}
```

### 5.2 ClaudeA2uiParser

Parses Claude API responses into A2UI message streams.

```dart
class ClaudeA2uiParser {
  /// Parse a single tool_use block
  static A2uiMessageData? parseToolUse(ToolUseBlock block) {
    return switch (block.name) {
      'begin_rendering' => BeginRenderingData.fromJson(block.input),
      'surface_update' => SurfaceUpdateData.fromJson(block.input),
      'data_model_update' => DataModelUpdateData.fromJson(block.input),
      'delete_surface' => DeleteSurfaceData.fromJson(block.input),
      _ => null, // Unknown tool, skip
    };
  }
  
  /// Parse complete message response
  static ParseResult parseMessage(Message message) {
    final a2uiMessages = <A2uiMessageData>[];
    final textBlocks = <String>[];
    
    for (final block in message.content) {
      if (block is ToolUseBlock) {
        final parsed = parseToolUse(block);
        if (parsed != null) a2uiMessages.add(parsed);
      } else if (block is TextBlock) {
        textBlocks.add(block.text);
      }
    }
    
    return ParseResult(
      a2uiMessages: a2uiMessages,
      textContent: textBlocks.join('\n'),
      hasToolUse: a2uiMessages.isNotEmpty,
    );
  }
  
  /// Stream parser for real-time processing
  static Stream<A2uiMessageData> parseStream(
    Stream<MessageStreamEvent> events,
  ) async* {
    // Implementation handles delta events
  }
}
```

### 5.3 ClaudeStreamHandler

Manages streaming connections and provides progressive message delivery.

```dart
class ClaudeStreamHandler {
  final AnthropicClient _client;
  final StreamConfig config;
  
  ClaudeStreamHandler(this._client, {this.config = const StreamConfig()});
  
  /// Create a streaming request and parse responses
  Stream<StreamEvent> streamRequest({
    required List<Message> messages,
    required List<Tool> tools,
    required String systemPrompt,
    String model = 'claude-sonnet-4-20250514',
  }) async* {
    final stream = _client.messages.stream(
      CreateMessageRequest(
        model: Model.model(model),
        maxTokens: config.maxTokens,
        system: systemPrompt,
        messages: messages,
        tools: tools,
      ),
    );
    
    await for (final event in stream) {
      if (event is ContentBlockDelta) {
        // Handle partial content
        yield StreamEvent.delta(event);
      } else if (event is ContentBlockStop) {
        // Parse complete block
        final parsed = ClaudeA2uiParser.parseToolUse(event.block);
        if (parsed != null) {
          yield StreamEvent.a2uiMessage(parsed);
        }
      } else if (event is MessageStop) {
        yield StreamEvent.complete();
      }
    }
  }
}

class StreamConfig {
  final int maxTokens;
  final Duration timeout;
  final int retryAttempts;
  
  const StreamConfig({
    this.maxTokens = 4096,
    this.timeout = const Duration(seconds: 60),
    this.retryAttempts = 3,
  });
}
```

---

## 6. Error Handling

### 6.1 Exception Hierarchy

```dart
sealed class A2uiException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  
  A2uiException(this.message, [this.stackTrace]);
}

class ToolConversionException extends A2uiException {
  final String toolName;
  final Map<String, dynamic>? invalidSchema;
  
  ToolConversionException(super.message, this.toolName, [this.invalidSchema]);
}

class MessageParseException extends A2uiException {
  final String? rawContent;
  final String? expectedFormat;
  
  MessageParseException(super.message, [this.rawContent, this.expectedFormat]);
}

class StreamException extends A2uiException {
  final int? httpStatusCode;
  final bool isRetryable;
  
  StreamException(super.message, {this.httpStatusCode, this.isRetryable = false});
}

class ValidationException extends A2uiException {
  final List<ValidationError> errors;
  
  ValidationException(super.message, this.errors);
}
```

### 6.2 Error Recovery Strategies

| Error Type | Recovery Strategy | Implementation |
|------------|-------------------|----------------|
| Network timeout | Exponential backoff retry | StreamHandler.retryWithBackoff() |
| Malformed response | Skip block, log warning | Parser returns null for invalid |
| Unknown tool | Ignore and continue | Switch default case returns null |
| Rate limit (429) | Queue with delay | RateLimitHandler middleware |
| Invalid schema | Throw with details | ValidationException with errors |

---

## 7. Testing Strategy

### 7.1 Unit Tests

Each component has comprehensive unit test coverage:

```dart
// test/tool_converter_test.dart
void main() {
  group('A2uiToolConverter', () {
    test('converts simple schema to Claude tool', () {
      final schema = A2uiToolSchema(
        name: 'surface_update',
        description: 'Update UI surface',
        inputSchema: {
          'surfaceId': {'type': 'string'},
          'widgets': {'type': 'array'},
        },
      );
      
      final tool = A2uiToolConverter.toClaudeTools([schema]).first;
      
      expect(tool.name, equals('surface_update'));
      expect(tool.inputSchema.properties, contains('surfaceId'));
    });
    
    test('handles nested object schemas', () { /* ... */ });
    test('validates required fields', () { /* ... */ });
  });
}
```

### 7.2 Integration Tests

Integration tests verify end-to-end message flow with mocked API responses:

```dart
// test/integration/stream_handler_test.dart
void main() {
  group('ClaudeStreamHandler integration', () {
    late MockAnthropicClient mockClient;
    late ClaudeStreamHandler handler;
    
    setUp(() {
      mockClient = MockAnthropicClient();
      handler = ClaudeStreamHandler(mockClient);
    });
    
    test('processes streaming tool_use response', () async {
      mockClient.stubStreamResponse(mockToolUseStream);
      
      final events = await handler.streamRequest(
        messages: [Message.user('Generate a form')],
        tools: testTools,
        systemPrompt: 'You are a UI generator',
      ).toList();
      
      expect(events.whereType<A2uiMessageEvent>(), hasLength(2));
      expect(events.last, isA<CompleteEvent>());
    });
  });
}
```

### 7.3 Coverage Requirements

| Component | Min Coverage | Target |
|-----------|--------------|--------|
| A2uiToolConverter | 90% | 95% |
| ClaudeA2uiParser | 90% | 95% |
| ClaudeStreamHandler | 85% | 90% |
| Data Models | 95% | 100% |
| Overall Package | 90% | 95% |

---

## 8. Dependencies

### 8.1 Runtime Dependencies

```yaml
dependencies:
  anthropic_sdk_dart: ^0.3.0    # Claude API client
  json_annotation: ^4.8.0        # JSON serialization
  meta: ^1.9.0                   # Annotations
  collection: ^1.18.0            # Collection utilities
```

### 8.2 Dev Dependencies

```yaml
dev_dependencies:
  test: ^1.24.0                  # Testing framework
  mockito: ^5.4.0                # Mocking
  build_runner: ^2.4.0           # Code generation
  json_serializable: ^6.7.0      # JSON code gen
  coverage: ^1.6.0               # Coverage reporting
```

### 8.3 Environment Constraints

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  # Note: No Flutter SDK constraint - pure Dart package
```

---

## 9. File Structure

### 9.1 Monorepo Structure

```
anthropic_genui/                          # Monorepo root
├── packages/
│   ├── anthropic_a2ui/                   # This package
│   │   └── ...
│   └── genui_anthropic/                  # Flutter package (depends on this)
│       └── ...
├── example/
│   └── demo_app/                         # Shared example app
├── melos.yaml                            # Monorepo tooling
├── README.md
└── LICENSE
```

### 9.2 Package Structure

```
packages/anthropic_a2ui/
├── lib/
│   ├── anthropic_a2ui.dart              # Public API exports
│   └── src/
│       ├── converter/
│       │   ├── tool_converter.dart      # A2UI ↔ Claude tool conversion
│       │   └── schema_mapper.dart       # JSON Schema mapping utilities
│       ├── parser/
│       │   ├── message_parser.dart      # Response parsing
│       │   ├── stream_parser.dart       # SSE stream parsing
│       │   └── block_handlers.dart      # Content block handlers
│       ├── stream/
│       │   ├── stream_handler.dart      # Stream management
│       │   ├── retry_policy.dart        # Retry logic
│       │   └── rate_limiter.dart        # Rate limit handling
│       ├── models/
│       │   ├── a2ui_message.dart        # Message types
│       │   ├── tool_schema.dart         # Tool definitions
│       │   ├── widget_node.dart         # Widget tree nodes
│       │   ├── stream_event.dart        # Stream event types
│       │   └── parse_result.dart        # Parser results
│       ├── exceptions/
│       │   └── exceptions.dart          # Exception hierarchy
│       └── utils/
│           ├── json_utils.dart          # JSON helpers
│           └── validation.dart          # Input validation
├── test/
│   ├── converter/
│   │   └── tool_converter_test.dart
│   ├── parser/
│   │   ├── message_parser_test.dart
│   │   └── stream_parser_test.dart
│   ├── stream/
│   │   └── stream_handler_test.dart
│   ├── models/
│   │   └── a2ui_message_test.dart
│   ├── integration/
│   │   └── end_to_end_test.dart
│   └── fixtures/
│       └── mock_responses.dart
├── example/
│   ├── basic_usage.dart
│   ├── streaming_example.dart
│   └── server_side_example.dart
├── pubspec.yaml
├── analysis_options.yaml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

---

## 10. Usage Examples

### 10.1 Basic Usage

```dart
import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

void main() async {
  final client = AnthropicClient(apiKey: 'your-api-key');
  
  // Define catalog tools
  final catalogTools = [
    A2uiToolSchema(
      name: 'user_card',
      description: 'Display a user profile card',
      inputSchema: {
        'type': 'object',
        'properties': {
          'userId': {'type': 'string'},
          'showAvatar': {'type': 'boolean'},
        },
        'required': ['userId'],
      },
    ),
  ];
  
  // Convert to Claude tools
  final claudeTools = A2uiToolConverter.toClaudeTools(catalogTools);
  
  // Make API request
  final response = await client.messages.create(
    CreateMessageRequest(
      model: Model.claudeSonnet4_20250514,
      maxTokens: 4096,
      tools: claudeTools,
      messages: [Message.user('Show me user 123')],
    ),
  );
  
  // Parse response
  final result = ClaudeA2uiParser.parseMessage(response);
  
  for (final message in result.a2uiMessages) {
    print('A2UI Message: $message');
  }
}
```

### 10.2 Streaming Usage

```dart
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

void main() async {
  final client = AnthropicClient(apiKey: apiKey);
  final handler = ClaudeStreamHandler(client);
  
  await for (final event in handler.streamRequest(
    messages: [Message.user('Generate a dashboard')],
    tools: A2uiToolConverter.toClaudeTools(catalogTools),
    systemPrompt: 'Generate UI using available tools',
  )) {
    switch (event) {
      case A2uiMessageEvent(:final message):
        handleA2uiMessage(message);
      case TextDeltaEvent(:final text):
        appendTextResponse(text);
      case CompleteEvent():
        finishRendering();
      case ErrorEvent(:final error):
        handleError(error);
    }
  }
}
```

### 10.3 Server-Side (Edge Function)

```dart
// Supabase Edge Function example
import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:supabase_functions/supabase_functions.dart';

void main() {
  SupabaseFunctions.run((request) async {
    final body = await request.json();
    final messages = (body['messages'] as List).map(Message.fromJson).toList();
    final tools = (body['tools'] as List).map(A2uiToolSchema.fromJson).toList();
    
    final client = AnthropicClient(
      apiKey: Deno.env.get('ANTHROPIC_API_KEY')!,
    );
    
    final handler = ClaudeStreamHandler(client);
    
    return Response.stream(
      handler.streamRequest(
        messages: messages,
        tools: A2uiToolConverter.toClaudeTools(tools),
        systemPrompt: body['systemPrompt'],
      ).map((event) => event.toJson()),
    );
  });
}
```

---

## 11. Performance Considerations

### 11.1 Memory Management

- Stream processing avoids buffering entire responses in memory
- Lazy parsing - only parse blocks as they arrive
- Reusable parser instances to minimize allocations

### 11.2 Latency Optimization

- Progressive emission of A2UI messages as tool_use blocks complete
- Connection pooling for multiple requests
- Parallel tool validation (where applicable)

### 11.3 Benchmarks

| Operation | Typical Latency | Memory |
|-----------|-----------------|--------|
| Tool schema conversion (10 tools) | < 1ms | ~50KB |
| Parse single tool_use block | < 0.5ms | ~10KB |
| Stream event processing | < 0.1ms/event | ~2KB/event |
| Full response parse (typical) | < 5ms | ~200KB |

---

## 12. Security Considerations

### 12.1 API Key Handling

This package does not store or manage API keys directly. Consumers are responsible for secure key management. Recommended patterns:

- Environment variables for server-side usage
- Secure storage (e.g., flutter_secure_storage) for mobile
- Backend proxy for production Flutter apps (never embed keys in client)

### 12.2 Input Validation

All inputs are validated before processing:

- Tool schemas validated against JSON Schema draft-07
- Widget tree depth limits prevent stack overflow
- String length limits on property values

---

## 13. Roadmap

### 13.1 Version 1.0.0 (Initial Release)

- Core tool conversion functionality
- Message parsing for all A2UI types
- Basic streaming support
- Comprehensive documentation and examples

### 13.2 Version 1.1.0

- Advanced streaming with partial widget rendering
- Built-in rate limiting
- Caching layer for repeated tool definitions

### 13.3 Version 1.2.0

- Multi-modal support (images in tool responses)
- Tool result handling helpers
- Conversation context management

---

## 14. Appendix

### 14.1 A2UI Protocol Reference

For complete A2UI protocol specification, refer to the official documentation (when publicly available). This package implements the protocol as used by Flutter GenUI SDK version 0.5.x.

### 14.2 Claude API Reference

For Claude API documentation including tool use capabilities, see: https://docs.anthropic.com/claude/docs/tool-use

### 14.3 Related Packages

- genui_anthropic - Flutter ContentGenerator using this package (same monorepo)
- anthropic_sdk_dart - Dart client for Claude API
- genui - Flutter GenUI SDK core package

### 14.4 Monorepo Development

This package is developed as part of the anthropic_genui monorepo. For local development:

```bash
# Clone the monorepo
git clone https://github.com/unfazed-dev/anthropic_genui.git
cd anthropic_genui

# Install Melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run tests across all packages
melos test

# Publish packages (maintainers only)
melos publish
```
