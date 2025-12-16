# GenUI SDK vs genui_claude: Deep-Dive Comparison

This document provides a comprehensive comparison between the GenUI SDK (`genui: ^0.5.1`) and the `genui_claude` package, detailing how each GenUI SDK feature is implemented.

## Overview

| Package | Purpose | Version |
|---------|---------|---------|
| `genui` | Flutter SDK for generative UI with LLM backends | ^0.5.1 |
| `genui_claude` | ContentGenerator implementation for Claude AI | 0.1.0 |

The `genui_claude` package implements the GenUI SDK's `ContentGenerator` interface, enabling Claude-powered generative UI in Flutter applications.

## Quick Reference

### Compatibility Matrix

| GenUI SDK Feature | genui_claude Support | Notes |
|-------------------|------------------------|-------|
| `ContentGenerator` interface | Full | All properties and methods |
| `a2uiMessageStream` | Full | Broadcast stream |
| `textResponseStream` | Full | Broadcast stream |
| `errorStream` | Full | Broadcast stream |
| `isProcessing` | Full | ValueListenable<bool> |
| `sendRequest()` | Full | Supports history |
| `dispose()` | Full | Cleans up all resources |
| `BeginRendering` | Full | `root` configurable, defaults to `'root'` |
| `SurfaceUpdate` | Full | Component conversion with UUID ids |
| `DataModelUpdate` | Full | `surfaceId` uses `globalSurfaceId` when scope is null |
| `SurfaceDeletion` | Full | Full support |
| `UserMessage` | Full | Text and multipart |
| `AiTextMessage` | Full | Text responses |
| `AiUiMessage` | Full | Tool calls converted |
| `ToolResponseMessage` | Full | Multiple results supported |
| `InternalMessage` | Partial | Extracted for system context |
| `UserUiInteractionMessage` | Full | Treated as user message |

### Version Compatibility

```yaml
# pubspec.yaml
dependencies:
  genui: ^0.5.1
  genui_claude: ^0.1.0
```

---

## Interface Mapping

### ContentGenerator Interface

The `ClaudeContentGenerator` class implements the `ContentGenerator` interface from GenUI SDK.

#### Properties

| GenUI Property | genui_claude Implementation |
|----------------|--------------------------------|
| `a2uiMessageStream` | `StreamController<A2uiMessage>.broadcast().stream` |
| `textResponseStream` | `StreamController<String>.broadcast().stream` |
| `errorStream` | `StreamController<ContentGeneratorError>.broadcast().stream` |
| `isProcessing` | `ValueNotifier<bool>` |

#### Methods

| GenUI Method | genui_claude Implementation |
|--------------|--------------------------------|
| `sendRequest(message, {history})` | Converts to Claude API format, streams via `ClaudeStreamHandler` |
| `dispose()` | Closes all streams, disposes handler and stream handler |

#### Implementation Details

```dart
// genui_claude/lib/src/content_generator/claude_content_generator.dart

class ClaudeContentGenerator implements ContentGenerator {
  // Stream controllers are broadcast streams
  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;
}
```

---

## A2uiMessage Types

The `A2uiMessageAdapter` class converts a2ui_claude messages to GenUI `A2uiMessage` types.

### BeginRendering

**GenUI SDK Definition:**
```dart
class BeginRendering extends A2uiMessage {
  final String surfaceId;
  final String root;
  final Map<String, dynamic>? styles;
}
```

**genui_claude Mapping:**
```dart
a2ui.BeginRenderingData(:final surfaceId, :final root, :final metadata) =>
  BeginRendering(
    surfaceId: surfaceId,      // Direct mapping
    root: root ?? 'root',      // Uses provided root or defaults to 'root'
    styles: metadata,          // metadata -> styles
  ),
```

**Tool Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surfaceId` | string | ✅ | Unique identifier for the UI surface being rendered |
| `parentSurfaceId` | string | ❌ | Parent surface ID for nested UI hierarchies |
| `root` | string | ❌ | Root element ID for hierarchical rendering (defaults to `'root'`) |

**How `root` Works:**

The `root` parameter identifies which element in your widget tree should be the parent container for rendered components. This is application-specific - your GenUI catalog implementation decides what each value means:

```dart
// Example: In your GenUI catalog builder
Widget build(BuildContext context, BeginRendering begin) {
  switch (begin.root) {
    case 'root':
      return MainContent(surfaceId: begin.surfaceId);
    case 'sidebar':
      return SidebarPanel(surfaceId: begin.surfaceId);
    case 'modal':
      return ModalOverlay(surfaceId: begin.surfaceId);
    default:
      return DefaultContainer(surfaceId: begin.surfaceId);
  }
}
```

Common values: `'root'`, `'main'`, `'sidebar'`, `'modal'`, `'header'`, `'footer'` - but any string is valid.

### SurfaceUpdate

**GenUI SDK Definition:**
```dart
class SurfaceUpdate extends A2uiMessage {
  final String surfaceId;
  final List<Component> components;
}
```

**genui_claude Mapping:**
```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

a2ui.SurfaceUpdateData(:final surfaceId, :final widgets) =>
  SurfaceUpdate(
    surfaceId: surfaceId,                          // Direct mapping
    components: widgets.map(_toComponent).toList(), // WidgetNode -> Component
  ),

// Component conversion
static Component _toComponent(a2ui.WidgetNode node) {
  return Component(
    id: node.id ?? _uuid.v4(),              // Uses provided id or generates UUID
    componentProperties: {
      node.type: node.properties,           // Type is a KEY wrapping properties
    },
  );
}
```

**Tool Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surfaceId` | string | ✅ | The surface ID to update |
| `widgets` | array | ✅ | Array of widget definitions to render |
| `append` | boolean | ❌ | If `true`, append widgets; if `false`, replace existing |

**Widget Item Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | ❌ | Unique instance ID (auto-generated UUID if not provided) |
| `type` | string | ✅ | Widget type name matching your catalog (e.g., `"Text"`, `"Button"`) |
| `properties` | object | ❌ | Widget configuration properties |
| `children` | array | ❌ | Child widgets for container types |
| `dataBinding` | string | ❌ | Data binding path for reactive updates |

**Component Structure:**

Each `Component` in the GenUI SDK has:
- **`id`**: Unique instance identifier (from `widget.id` or auto-generated UUID)
- **`componentProperties`**: Map where the widget type is the key: `{type: properties}`
- **`type` getter**: Returns `componentProperties.keys.first` (the widget type)

This structure enables:
- Multiple components with the same type but different IDs
- Widget catalog matching by the type key in `componentProperties`

### DataModelUpdate

**GenUI SDK Definition:**
```dart
class DataModelUpdate extends A2uiMessage {
  final String surfaceId;
  final Object contents;
}
```

**genui_claude Mapping:**
```dart
/// Surface ID used for global/unscoped data model updates.
const String globalSurfaceId = '__global_scope__';

a2ui.DataModelUpdateData(:final updates, :final scope) => DataModelUpdate(
  surfaceId: scope ?? globalSurfaceId,  // scope -> surfaceId, uses globalSurfaceId for unscoped
  contents: updates,                     // updates -> contents
),
```

**Tool Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `updates` | object | ✅ | Key-value pairs of data updates to apply |
| `scope` | string | ❌ | Surface ID scope for the update (uses `globalSurfaceId` if not provided) |

**Global Scope Handling:**

When `scope` is null, `surfaceId` is set to the `globalSurfaceId` constant (`'__global_scope__'`). This constant is exported from the package:

```dart
import 'package:genui_claude/genui_claude.dart';

generator.a2uiMessageStream.listen((message) {
  if (message is DataModelUpdate) {
    if (message.surfaceId == globalSurfaceId) {
      // Handle global/app-wide data update
      updateGlobalState(message.contents);
    } else {
      // Handle surface-specific data update
      updateSurfaceState(message.surfaceId, message.contents);
    }
  }
});
```

### SurfaceDeletion

**GenUI SDK Definition:**
```dart
class SurfaceDeletion extends A2uiMessage {
  final String surfaceId;
}
```

**genui_claude Mapping:**
```dart
a2ui.DeleteSurfaceData(:final surfaceId) => SurfaceDeletion(
  surfaceId: surfaceId,  // Direct mapping
),
```

**Tool Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surfaceId` | string | ✅ | The surface ID to delete |
| `cascade` | boolean | ❌ | If `true`, also delete all child surfaces |

---

## ChatMessage Types

The `MessageConverter` class converts GenUI `ChatMessage` types to Claude API format.

### Conversion Table

| GenUI Message Type | Claude API Role | Claude API Content |
|--------------------|-----------------|-------------------|
| `UserMessage` | `user` | Text string or content blocks |
| `UserUiInteractionMessage` | `user` | Text string or content blocks |
| `AiTextMessage` | `assistant` | Text string |
| `AiUiMessage` | `assistant` | Content blocks with tool_use |
| `ToolResponseMessage` | `user` | Content blocks with tool_result |
| `InternalMessage` | (skipped) | Extracted for system context |

### UserMessage Conversion

```dart
// GenUI
UserMessage.text('Hello, Claude!')

// Claude API format
{
  'role': 'user',
  'content': 'Hello, Claude!'
}

// With image
UserMessage([
  TextPart('Describe this image'),
  ImagePart(base64: '...', mimeType: 'image/png'),
])

// Claude API format
{
  'role': 'user',
  'content': [
    {'type': 'text', 'text': 'Describe this image'},
    {'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/png', 'data': '...'}}
  ]
}
```

### AiTextMessage Conversion

```dart
// GenUI
AiTextMessage.text('Hello! How can I help?')

// Claude API format
{
  'role': 'assistant',
  'content': 'Hello! How can I help?'
}
```

### AiUiMessage Conversion (with Tool Calls)

```dart
// GenUI
AiUiMessage([
  TextPart('Let me render that'),
  ToolCallPart(id: 'call-1', toolName: 'surface_update', arguments: {...}),
])

// Claude API format
{
  'role': 'assistant',
  'content': [
    {'type': 'text', 'text': 'Let me render that'},
    {'type': 'tool_use', 'id': 'call-1', 'name': 'surface_update', 'input': {...}}
  ]
}
```

### ToolResponseMessage Conversion

```dart
// GenUI
ToolResponseMessage([
  ToolResultPart(callId: 'call-1', result: 'Success'),
])

// Claude API format
{
  'role': 'user',
  'content': [
    {'type': 'tool_result', 'tool_use_id': 'call-1', 'content': 'Success'}
  ]
}
```

### InternalMessage Handling

```dart
// GenUI
InternalMessage('System context information')

// Claude API format: SKIPPED
// Extracted separately via MessageConverter.extractSystemContext()
```

---

## Behavioral Differences

### Stream Semantics

| Behavior | GenUI SDK Expectation | genui_claude Implementation |
|----------|----------------------|--------------------------------|
| Stream type | Broadcast | Broadcast (multiple listeners supported) |
| Stream lifetime | Until dispose | Until dispose |
| Event ordering | Preserved | Preserved |
| Backpressure | Standard Dart stream | Standard Dart stream |

### Error Handling

| Scenario | GenUI SDK Expectation | genui_claude Implementation |
|----------|----------------------|--------------------------------|
| API error | `ContentGeneratorError` on `errorStream` | Exception wrapped in `ContentGeneratorError` |
| Network error | `ContentGeneratorError` on `errorStream` | `NetworkException` wrapped in `ContentGeneratorError` |
| Concurrent request | Error emitted | "Request already in progress" error |
| Post-dispose | Streams closed | Streams closed, new subscriptions get done |

### State Management

| State | GenUI SDK Expectation | genui_claude Implementation |
|-------|----------------------|--------------------------------|
| Initial `isProcessing` | `false` | `false` |
| During `sendRequest` | `true` | `true` |
| After completion | `false` | `false` |
| After error | `false` | `false` (in finally block) |

---

## Design Notes

### 1. BeginRendering.root Default Value

The `root` property defaults to `'root'` when not specified. This matches common conventions where most applications use a single root element. The value can be customized by including the `root` parameter in the `begin_rendering` tool call.

### 2. DataModelUpdate Global Scope

When `scope` is null in `data_model_update`, `surfaceId` is set to the `globalSurfaceId` constant (`'__global_scope__'`). This constant is exported from the package, allowing applications to identify and handle global data updates.

### 3. Component ID and Type Structure

Each `Component` has:
- **`id`**: A unique instance identifier (provided via WidgetNode.id or auto-generated UUID)
- **`componentProperties`**: A map where the widget type is the key: `{type: properties}`
- **`type` getter**: Returns `componentProperties.keys.first` (the widget type)

This structure matches the GenUI SDK's widget catalog pattern where:
- Multiple components can have the same type but different ids
- The catalog matches widgets by the type key in componentProperties

---

## Code Examples

### Basic Usage

```dart
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

// Create generator (implements ContentGenerator)
final generator = ClaudeContentGenerator(
  apiKey: 'your-api-key',
  model: 'claude-sonnet-4-20250514',
);

// Subscribe to streams
generator.textResponseStream.listen((text) {
  print('Text: $text');
});

generator.a2uiMessageStream.listen((message) {
  if (message is SurfaceUpdate) {
    print('Widgets: ${message.components}');
  }
});

generator.errorStream.listen((error) {
  print('Error: ${error.error}');
});

// Send request
await generator.sendRequest(UserMessage.text('Hello!'));

// Clean up
generator.dispose();
```

### With GenUiConversation

```dart
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

final conversation = GenUiConversation(
  contentGenerator: ClaudeContentGenerator(apiKey: 'key'),
  catalog: MyCatalog(),
);

// Use conversation widget
GenUiConversationWidget(conversation: conversation)
```

### Proxy Mode for Production

```dart
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: 'user-session-token',
);
```

### Error Handling

```dart
generator.errorStream.listen((error) {
  final exception = error.error;

  if (exception is NetworkException) {
    // Handle network error
  } else if (exception is RateLimitException) {
    // Handle rate limit (check retryAfter)
  } else if (exception is AuthenticationException) {
    // Handle auth error
  }
});
```

---

## Test Verification Reference

The following test files verify GenUI SDK equivalence:

### Interface Compliance
- [interface_compliance_test.dart](../test/genui_equivalence/interface_compliance_test.dart)
  - Type system compliance
  - Stream type compliance
  - isProcessing behavior
  - sendRequest method
  - dispose method
  - ChatMessage handling

### Streaming Behavior
- [streaming_behavior_test.dart](../test/genui_equivalence/streaming_behavior_test.dart)
  - Stream cancellation semantics
  - Stream completion semantics
  - Event ordering
  - Multiple listeners
  - Backpressure handling

### Message Conversion
- [message_conversion_edge_cases_test.dart](../test/genui_equivalence/message_conversion_edge_cases_test.dart)
  - Multi-part messages
  - Unicode handling
  - Empty content
  - Long content

### A2UI Tool Integration
- [a2ui_tool_integration_test.dart](../test/genui_equivalence/a2ui_tool_integration_test.dart)
  - begin_rendering tool
  - surface_update tool
  - data_model_update tool
  - delete_surface tool
  - Multi-tool sequences

### Widget/Component Handling
- [widget_component_test.dart](../test/genui_equivalence/widget_component_test.dart)
  - WidgetNode to Component conversion
  - Property type preservation
  - Edge cases

### Configuration
- [configuration_modes_test.dart](../test/genui_equivalence/configuration_modes_test.dart)
  - Direct mode
  - Proxy mode
  - Configuration immutability

### State Management
- [state_management_test.dart](../test/genui_equivalence/state_management_test.dart)
  - isProcessing lifecycle
  - Concurrent request handling
  - Post-dispose behavior

### Error Handling
- [error_edge_cases_test.dart](../test/genui_equivalence/error_edge_cases_test.dart)
  - Mid-stream errors
  - Malformed responses
  - Error recovery

### Integration Scenarios
- [integration_scenarios_test.dart](../test/genui_equivalence/integration_scenarios_test.dart)
  - Multiple conversations
  - Large payloads
  - Real-world flows

---

## Appendix: A2UI Protocol Tools

The Claude model uses these tools to generate UI:

| Tool | Purpose | Output |
|------|---------|--------|
| `begin_rendering` | Start a new surface | `BeginRendering` |
| `surface_update` | Add/update widgets | `SurfaceUpdate` |
| `data_model_update` | Update data model | `DataModelUpdate` |
| `delete_surface` | Remove a surface | `SurfaceDeletion` |

These tools are defined in the [a2ui_claude](../../../a2ui_claude) package and automatically registered when using `ClaudeContentGenerator`.
