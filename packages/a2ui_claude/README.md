# a2ui_claude

Pure Dart package for converting between Claude API responses and A2UI (Agent-to-UI) protocol messages.

## Features

- **Tool Conversion**: Convert A2UI tool schemas to Claude API tool format
- **Message Parsing**: Parse Claude responses into strongly-typed A2UI messages
- **Stream Handling**: Process SSE streams with progressive parsing
- **Type Safety**: Sealed classes with exhaustive pattern matching
- **Pure Dart**: Zero Flutter dependencies - works in CLI, server, and edge functions

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  a2ui_claude: ^1.0.0
```

## Quick Start

### Tool Conversion

Convert A2UI tool schemas to Claude's tool format:

```dart
import 'package:a2ui_claude/a2ui_claude.dart';

final schemas = [
  A2uiToolSchema(
    name: 'surface_update',
    description: 'Updates widgets in a UI surface',
    inputSchema: {
      'type': 'object',
      'properties': {
        'surfaceId': {'type': 'string'},
        'widgets': {'type': 'array'},
      },
    },
    requiredFields: ['surfaceId', 'widgets'],
  ),
];

// Convert to Claude format
final claudeTools = A2uiToolConverter.toClaudeTools(schemas);

// Generate system prompt instructions
final instructions = A2uiToolConverter.generateToolInstructions(schemas);
```

### Message Parsing

Parse Claude responses into A2UI messages:

```dart
final response = await claudeClient.createMessage(...);
final result = ClaudeA2uiParser.parseMessage(response);

// Access parsed content
print('Text: ${result.textContent}');
print('Has tool use: ${result.hasToolUse}');

// Handle A2UI messages with pattern matching
for (final message in result.a2uiMessages) {
  switch (message) {
    case BeginRenderingData(:final surfaceId):
      print('Begin rendering: $surfaceId');
    case SurfaceUpdateData(:final surfaceId, :final widgets):
      print('Update $surfaceId with ${widgets.length} widgets');
    case DataModelUpdateData(:final updates):
      print('Data update: ${updates.keys}');
    case DeleteSurfaceData(:final surfaceId):
      print('Delete: $surfaceId');
  }
}
```

### Stream Processing

Handle streaming responses:

```dart
final handler = ClaudeStreamHandler(
  config: StreamConfig(
    maxTokens: 8192,
    timeout: Duration(seconds: 120),
  ),
);

await for (final event in handler.streamRequest(messageStream: stream)) {
  switch (event) {
    case TextDeltaEvent(:final text):
      stdout.write(text);
    case A2uiMessageEvent(:final message):
      handleA2uiMessage(message);
    case CompleteEvent():
      print('Done!');
    case ErrorEvent(:final error):
      print('Error: ${error.message}');
    case DeltaEvent(:final data):
      // Raw delta for custom processing
      break;
  }
}

handler.dispose();
```

### Input Validation

Validate tool inputs before sending to Claude:

```dart
final result = A2uiToolConverter.validateToolInput(
  'surface_update',
  {'surfaceId': 'main'},  // Missing required 'widgets'
  schemas,
);

if (!result.isValid) {
  for (final error in result.errors) {
    print('${error.field}: ${error.message}');
  }
}
```

## A2UI Message Types

| Type | Description |
|------|-------------|
| `BeginRenderingData` | Signals start of UI generation |
| `SurfaceUpdateData` | Contains widget tree for a surface |
| `DataModelUpdateData` | Updates bound data values |
| `DeleteSurfaceData` | Removes a UI surface |

## Stream Event Types

| Type | Description |
|------|-------------|
| `TextDeltaEvent` | Text content chunk |
| `A2uiMessageEvent` | Parsed A2UI message |
| `DeltaEvent` | Raw delta data |
| `CompleteEvent` | Stream completed |
| `ErrorEvent` | Error occurred |

## Configuration

### StreamConfig

```dart
StreamConfig(
  maxTokens: 4096,      // Max response tokens
  timeout: Duration(seconds: 60),  // Connection timeout
  retryAttempts: 3,     // Retry count for transient failures
)
```

### Rate Limiting

```dart
final rateLimiter = RateLimiter();

// Execute with rate limit awareness
final result = await rateLimiter.execute(() => apiCall());

// Handle 429 responses
rateLimiter.recordRateLimit(
  statusCode: 429,
  retryAfter: RateLimiter.parseRetryAfter(headers['retry-after']),
);

// Check status
if (rateLimiter.isRateLimited) {
  print('Currently rate limited');
}

rateLimiter.dispose();
```

## Exception Handling

All exceptions extend `A2uiException`:

```dart
try {
  // ... operations
} on ToolConversionException catch (e) {
  print('Tool error: ${e.toolName} - ${e.message}');
} on MessageParseException catch (e) {
  print('Parse error: ${e.message}');
} on StreamException catch (e) {
  print('Stream error: ${e.message}');
  if (e.isRetryable) {
    // Retry the request
  }
} on ValidationException catch (e) {
  for (final error in e.errors) {
    print('${error.field}: ${error.message}');
  }
}
```

## Deployment Targets

This package is pure Dart with no Flutter dependencies:

- Flutter apps (via genui_claude)
- Dart CLI applications
- Server-side Dart (shelf, dart_frog)
- Edge functions (Supabase, Cloudflare Workers)

## Examples

See the [example](example/) directory:

- [basic_usage.dart](example/basic_usage.dart) - Tool conversion and message parsing
- [streaming_example.dart](example/streaming_example.dart) - Stream processing
- [server_side_example.dart](example/server_side_example.dart) - Server-side usage

## Performance

Optimized for real-time UI generation:

| Operation | Target | Typical |
|-----------|--------|---------|
| Tool conversion (10 tools) | < 1ms | ~0.3ms |
| Message parsing | < 5ms | ~1ms |
| Stream event processing | < 0.1ms/event | ~0.05ms |

## Related Packages

- [genui_claude](../genui_claude/) - Flutter widgets for A2UI rendering
- [anthropic_sdk_dart](https://pub.dev/packages/anthropic_sdk_dart) - Claude API client

## License

MIT License - see LICENSE file for details.
