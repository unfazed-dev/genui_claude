# Standalone Usage (Pure Dart)

The `anthropic_a2ui` package is a **pure Dart package** with zero Flutter dependencies. It can be used in CLI applications, server-side Dart, edge functions, and anywhere Dart runs.

## Package Overview

```
anthropic_genui monorepo:
├── anthropic_a2ui        ← Pure Dart (this document)
│   ├── A2UI protocol messages
│   ├── Claude stream handler
│   ├── Tool conversion utilities
│   └── Works everywhere Dart runs
│
└── genui_anthropic       ← Flutter integration
    ├── ContentGenerator implementation
    ├── Direct/Proxy mode handlers
    └── Requires Flutter
```

## Installation

For non-Flutter projects, add only `anthropic_a2ui`:

```yaml
dependencies:
  anthropic_a2ui: ^1.0.0
  http: ^1.0.0  # For HTTP requests
```

## Core Components

### ClaudeStreamHandler

Processes Claude SSE streams and extracts A2UI messages:

```dart
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

final handler = ClaudeStreamHandler();

// Process a raw SSE stream from Claude
await for (final event in handler.streamRequest(
  messageStream: rawClaudeEventStream,
)) {
  switch (event) {
    case TextDeltaEvent(:final text):
      // Text chunk from Claude
      stdout.write(text);

    case A2uiMessageEvent(:final message):
      // A2UI protocol message
      switch (message) {
        case BeginRenderingData(:final surfaceId):
          print('Starting surface: $surfaceId');
        case SurfaceUpdateData(:final surfaceId, :final widgets):
          print('Widgets for $surfaceId: ${widgets.length}');
        case DataModelUpdateData(:final updates):
          print('Data update: $updates');
        case DeleteSurfaceData(:final surfaceId):
          print('Deleting surface: $surfaceId');
      }

    case DeltaEvent(:final data):
      // Raw delta data (for debugging)
      print('Delta: $data');

    case CompleteEvent():
      print('Stream complete');

    case ErrorEvent(:final error):
      print('Error: ${error.message}');
  }
}
```

### Stream Event Types

The `ClaudeStreamHandler` emits these sealed event types:

| Event | Description | Properties |
|-------|-------------|------------|
| `TextDeltaEvent` | Text content chunk | `String text` |
| `A2uiMessageEvent` | Parsed A2UI message | `A2uiMessageData message` |
| `DeltaEvent` | Raw delta data | `Map<String, dynamic> data` |
| `CompleteEvent` | Stream finished | - |
| `ErrorEvent` | Error occurred | `A2uiException error` |

### A2UI Message Types

```dart
sealed class A2uiMessageData { }

class BeginRenderingData extends A2uiMessageData {
  final String surfaceId;
  final String? parentSurfaceId;
  final String? root;  // Defaults to 'root'
  final Map<String, dynamic>? metadata;
}

class SurfaceUpdateData extends A2uiMessageData {
  final String surfaceId;
  final List<WidgetNode> widgets;
  final bool append;  // Append vs replace
}

class DataModelUpdateData extends A2uiMessageData {
  final Map<String, dynamic> updates;
  final String? scope;
}

class DeleteSurfaceData extends A2uiMessageData {
  final String surfaceId;
}
```

## CLI Application Example

```dart
#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';
import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null) {
    print('Set ANTHROPIC_API_KEY environment variable');
    exit(1);
  }

  final prompt = args.join(' ');
  if (prompt.isEmpty) {
    print('Usage: dart run cli.dart <prompt>');
    exit(1);
  }

  // Build A2UI tools
  final tools = A2uiControlTools.all;

  // Make streaming request to Claude
  final client = http.Client();
  final request = http.Request(
    'POST',
    Uri.parse('https://api.anthropic.com/v1/messages'),
  );
  request.headers.addAll({
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
    'accept': 'text/event-stream',
  });
  request.body = jsonEncode({
    'model': 'claude-sonnet-4-20250514',
    'max_tokens': 4096,
    'stream': true,
    'system': 'You are a UI assistant. Use the available tools to generate UI.',
    'tools': tools.map((t) => t.toJson()).toList(),
    'messages': [
      {'role': 'user', 'content': prompt}
    ],
  });

  final response = await client.send(request);

  // Parse SSE stream
  final eventStream = response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .where((line) => line.startsWith('data: '))
      .map((line) => line.substring(6))
      .where((data) => data != '[DONE]')
      .map((data) => jsonDecode(data) as Map<String, dynamic>);

  // Process with ClaudeStreamHandler
  final handler = ClaudeStreamHandler();
  await for (final event in handler.streamRequest(messageStream: eventStream)) {
    switch (event) {
      case TextDeltaEvent(:final text):
        stdout.write(text);
      case A2uiMessageEvent(:final message):
        print('\n[A2UI] ${message.runtimeType}');
      case CompleteEvent():
        print('\n--- Done ---');
      case ErrorEvent(:final error):
        stderr.writeln('Error: ${error.message}');
      default:
        break;
    }
  }

  client.close();
}
```

## Server-Side Usage (shelf/dart_frog)

### With shelf

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

void main() async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_handleRequest);

  await io.serve(handler, 'localhost', 8080);
  print('Server running on http://localhost:8080');
}

Future<Response> _handleRequest(Request request) async {
  if (request.method != 'POST') {
    return Response.notFound('Not found');
  }

  final body = await request.readAsString();
  final data = jsonDecode(body) as Map<String, dynamic>;

  // Process with anthropic_a2ui
  final tools = A2uiControlTools.all;

  // Forward to Claude and stream back
  // ... (implementation depends on your backend architecture)

  return Response.ok(
    'Processed',
    headers: {'content-type': 'application/json'},
  );
}
```

### With dart_frog

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;

  // Use anthropic_a2ui for tool conversion
  final widgetSchemas = data['widgets'] as List;
  final tools = widgetSchemas.map((s) =>
    A2uiToolSchema.fromJson(s as Map<String, dynamic>)
  ).toList();

  final allTools = A2uiControlTools.withWidgetTools(tools);

  // Generate tool instructions for system prompt
  final instructions = A2uiToolConverter.generateToolInstructions(allTools);

  return Response.json({
    'tools': allTools.map((t) => t.toJson()).toList(),
    'instructions': instructions,
  });
}
```

## Edge Functions (Supabase/Deno)

While Supabase Edge Functions use TypeScript, you can use `anthropic_a2ui` in Dart-based edge function platforms or compile to JavaScript:

### Dart Edge Function Pattern

```dart
// Using dart2js compiled output or Dart-native edge platform
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

Future<Map<String, dynamic>> handleEdgeRequest(
  Map<String, dynamic> request,
  Map<String, String> env,
) async {
  final apiKey = env['ANTHROPIC_API_KEY']!;
  final messages = request['messages'] as List;
  final widgetSchemas = request['tools'] as List?;

  // Build tools
  final widgetTools = widgetSchemas?.map((s) =>
    A2uiToolSchema.fromJson(s as Map<String, dynamic>)
  ).toList() ?? [];

  final allTools = A2uiControlTools.withWidgetTools(widgetTools);

  // Forward to Claude...
  // Return SSE stream...

  return {'status': 'ok'};
}
```

## Tool Conversion Utilities

### A2uiToolConverter

Convert schemas and validate inputs:

```dart
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

// Convert widget schemas to Claude tool format
final widgetSchemas = [
  A2uiToolSchema(
    name: 'info_card',
    description: 'Display an information card',
    inputSchema: {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'content': {'type': 'string'},
      },
      'required': ['title', 'content'],
    },
  ),
];

// Convert to Claude API format
final claudeTools = A2uiToolConverter.toClaudeTools(widgetSchemas);

// Generate system prompt instructions
final instructions = A2uiToolConverter.generateToolInstructions(widgetSchemas);
// Returns: "Available widgets: info_card (Display an information card)..."

// Validate tool input against schema
final validation = A2uiToolConverter.validateToolInput(
  'info_card',
  {'title': 'Hello'},  // Missing 'content'
  widgetSchemas,
);
if (!validation.isValid) {
  print('Validation errors: ${validation.errors}');
}
```

### A2uiControlTools

Pre-defined A2UI control tools:

```dart
// Get all control tools
final controlTools = A2uiControlTools.all;
// [begin_rendering, surface_update, data_model_update, delete_surface]

// Combine with widget tools
final allTools = A2uiControlTools.withWidgetTools(myWidgetSchemas);

// Individual tools
final beginRendering = A2uiControlTools.beginRendering;
final surfaceUpdate = A2uiControlTools.surfaceUpdate;
final dataModelUpdate = A2uiControlTools.dataModelUpdate;
final deleteSurface = A2uiControlTools.deleteSurface;
```

## Parsing A2UI Messages

### From Claude Response

```dart
import 'package:anthropic_a2ui/anthropic_a2ui.dart';

// Parse a tool_use content block from Claude
final toolUse = {
  'type': 'tool_use',
  'id': 'toolu_123',
  'name': 'surface_update',
  'input': {
    'surfaceId': 'card_1',
    'widgets': [
      {'type': 'info_card', 'properties': {'title': 'Hello'}}
    ],
  },
};

// Parse to A2UI message
final message = A2uiMessageParser.parseToolUse(toolUse);
if (message != null) {
  switch (message) {
    case SurfaceUpdateData(:final surfaceId, :final widgets):
      print('Update $surfaceId with ${widgets.length} widgets');
    // ... handle other message types
  }
}
```

### From JSON

```dart
// Parse from raw JSON
final json = {
  'type': 'begin_rendering',
  'surfaceId': 'card_1',
  'metadata': {'source': 'user'},
};

final message = A2uiMessageParser.fromJson(json);
```

## Comparison: anthropic_a2ui vs genui_anthropic

| Feature | anthropic_a2ui | genui_anthropic |
|---------|---------------|-----------------|
| Flutter required | No | Yes |
| Stream processing | Yes (ClaudeStreamHandler) | Yes (via handler) |
| Tool conversion | Yes (A2uiToolConverter) | Yes (CatalogToolBridge) |
| A2UI messages | Yes | Yes (adapts to GenUI types) |
| HTTP handling | Manual | Built-in (Direct/Proxy) |
| Resilience | Manual | Built-in (circuit breaker, retry) |
| Use case | CLI, servers, edge | Flutter apps |

## When to Use anthropic_a2ui Directly

- **CLI tools** that interact with Claude
- **Server-side Dart** applications (shelf, dart_frog, conduit)
- **Edge functions** in Dart-compatible platforms
- **Custom integrations** where you need full control
- **Non-Flutter** Dart applications

## When to Use genui_anthropic

- **Flutter applications** with GenUI SDK
- **Production apps** needing resilience patterns
- **Rapid development** with pre-built handlers
- **Standard use cases** with Direct/Proxy modes
