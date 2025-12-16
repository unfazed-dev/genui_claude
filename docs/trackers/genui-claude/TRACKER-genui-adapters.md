# TRACKER: GenUI Adapters and Bridges Implementation

## Status: COMPLETE

## Overview

Implementation of adapter and bridge classes that connect a2ui_claude types to GenUI SDK types. This includes A2uiMessageAdapter for message conversion, CatalogToolBridge for tool catalog extraction, A2uiControlTools for A2UI control tool definitions, and MessageConverter for conversation history conversion.

**Parent Tracker:** [TRACKER-genui-claude-package.md](./TRACKER-genui-claude-package.md)

## Tasks

### A2uiMessageAdapter (lib/src/adapter/message_adapter.dart) ✅

#### Main Conversion Method ✅
- [x] Create A2uiMessageAdapter class
- [x] Implement toGenUiMessage(A2uiMessageData) static method
- [x] Use exhaustive pattern matching on A2uiMessageData:
  ```dart
  static A2uiMessage toGenUiMessage(a2ui.A2uiMessageData data) {
    return switch (data) {
      a2ui.BeginRenderingData(:final surfaceId, :final metadata) =>
        BeginRendering(surfaceId: surfaceId, root: 'root', styles: metadata),
      a2ui.SurfaceUpdateData(:final surfaceId, :final widgets) =>
        SurfaceUpdate(surfaceId: surfaceId, components: widgets.map(_toComponent).toList()),
      a2ui.DataModelUpdateData(:final updates, :final scope) =>
        DataModelUpdate(surfaceId: scope ?? 'default', contents: updates),
      a2ui.DeleteSurfaceData(:final surfaceId) =>
        SurfaceDeletion(surfaceId: surfaceId),
    };
  }
  ```

#### BeginRenderingData Conversion ✅
- [x] Map to BeginRendering
- [x] Pass surfaceId
- [x] Pass metadata as styles

#### SurfaceUpdateData Conversion ✅
- [x] Map to SurfaceUpdate
- [x] Pass surfaceId
- [x] Convert widgets list using _toComponent()

#### DataModelUpdateData Conversion ✅
- [x] Map to DataModelUpdate
- [x] Pass updates as contents
- [x] Map scope to surfaceId (with 'default' fallback)

#### DeleteSurfaceData Conversion ✅
- [x] Map to SurfaceDeletion
- [x] Pass surfaceId

#### Widget Node Conversion ✅
- [x] Implement _toComponent(WidgetNode) private static method
- [x] Create Component with:
  - [x] id from node.type
  - [x] componentProperties from node.properties

#### Batch Conversion ✅
- [x] Implement toGenUiMessages(List<A2uiMessageData>) static method

### CatalogToolBridge (lib/src/adapter/catalog_tool_bridge.dart) ✅

#### Catalog Extraction Methods ✅
- [x] Create CatalogToolBridge class
- [x] Implement fromCatalog(Catalog) static method
  - [x] Extract catalog.items
  - [x] Map each CatalogItem to A2uiToolSchema
- [x] Implement fromItems(List<CatalogItem>) static method
  - [x] Direct mapping of CatalogItem list to A2uiToolSchema list
  - [x] Convert dataSchema to Claude format

#### Tool Conversion Logic ✅
- [x] Map CatalogItem.name to A2uiToolSchema.name
- [x] Map CatalogItem.description to A2uiToolSchema.description
- [x] Convert CatalogItem.dataSchema to A2uiToolSchema.inputSchema
- [x] Schema type conversion for object, string, integer, number, boolean, array types

### A2uiControlTools (lib/src/adapter/a2ui_control_tools.dart) ✅

#### A2UI Control Tools ✅
- [x] Create A2uiControlTools class
- [x] Define begin_rendering tool with surfaceId, parentSurfaceId
- [x] Define surface_update tool with surfaceId, widgets, append
- [x] Define data_model_update tool with updates, scope
- [x] Define delete_surface tool with surfaceId, cascade
- [x] Implement A2uiControlTools.all getter

#### Combined Tool List ✅
- [x] Implement withA2uiTools(List<A2uiToolSchema>) static method
- [x] Prepend A2UI control tools to widget tools
- [x] Return combined list

### MessageConverter (lib/src/utils/message_converter.dart) ✅

#### GenUI to Claude Message Conversion ✅
- [x] Create MessageConverter class
- [x] Implement toClaudeMessages(List<ChatMessage>) static method
- [x] Handle user messages:
  - [x] Extract text content
  - [x] Convert to Claude format with role: 'user'
- [x] Handle assistant messages:
  - [x] Extract text content
  - [x] Include tool_use blocks if present
  - [x] Convert to Claude format with role: 'assistant'
- [x] Handle tool response messages (ToolResponseMessage)
- [x] Skip InternalMessage (used for system context separately)

#### Conversation History Management ✅
- [x] Implement pruneHistory(messages, maxMessages) method
- [x] Keep most recent N messages
- [x] Preserve conversation coherence (user-assistant pairs)
- [x] Implement extractSystemContext for InternalMessage extraction

#### Image Handling ✅
- [x] Support ImagePart in content blocks
- [x] Convert base64/URL images to Claude format

## Files

### Adapter ✅
- `lib/src/adapter/message_adapter.dart` ✅ - A2UI message bridging
- `lib/src/adapter/catalog_tool_bridge.dart` ✅ - Catalog to A2uiToolSchema conversion
- `lib/src/adapter/a2ui_control_tools.dart` ✅ - A2UI control tool definitions

### Utils ✅
- `lib/src/utils/message_converter.dart` ✅ - GenUI ChatMessage to Claude format conversion

## Dependencies

- genui (A2uiMessage, GenUiWidget, GenUiManager, CatalogItem, Message types)
- a2ui_claude (A2uiMessageData, WidgetNode, BeginRenderingData, etc.)
- anthropic_sdk_dart (Tool, Message types)

## Notes

### Type Mapping Reference

| a2ui_claude | genui |
|----------------|-------|
| A2uiMessageData | A2uiMessage |
| BeginRenderingData | A2uiMessage.beginRendering |
| SurfaceUpdateData | A2uiMessage.surfaceUpdate |
| DataModelUpdateData | A2uiMessage.dataModelUpdate |
| DeleteSurfaceData | A2uiMessage.deleteSurface |
| WidgetNode | GenUiWidget |

### A2UI Control Tools Schema

```dart
// begin_rendering
{
  'type': 'object',
  'properties': {
    'surfaceId': {'type': 'string'},
    'parentSurfaceId': {'type': 'string'},
  },
  'required': ['surfaceId'],
}

// surface_update
{
  'type': 'object',
  'properties': {
    'surfaceId': {'type': 'string'},
    'widgets': {
      'type': 'array',
      'items': {'type': 'object'},
    },
    'append': {'type': 'boolean'},
  },
  'required': ['surfaceId', 'widgets'],
}

// data_model_update
{
  'type': 'object',
  'properties': {
    'updates': {'type': 'object'},
    'scope': {'type': 'string'},
  },
  'required': ['updates'],
}

// delete_surface
{
  'type': 'object',
  'properties': {
    'surfaceId': {'type': 'string'},
    'cascade': {'type': 'boolean'},
  },
  'required': ['surfaceId'],
}
```

### Catalog to Tool Mapping

```dart
// CatalogItem example
CatalogItem(
  name: 'user_card',
  description: 'Display user profile card',
  inputSchema: {
    'type': 'object',
    'properties': {
      'userId': {'type': 'string'},
    },
    'required': ['userId'],
  },
  builder: (context, properties, dataModel) => ...,
)

// Becomes Tool
Tool(
  name: 'user_card',
  description: 'Display user profile card',
  inputSchema: Schema.object(
    properties: {
      'userId': Schema.string(),
    },
    required: ['userId'],
  ),
)
```

### Error Handling

- Invalid widget types -> Log warning, skip widget
- Missing required properties -> Use defaults or skip
- Malformed schemas -> Throw ToolConversionException
- Null children -> Return empty list

### Performance Considerations

- Cache converted tools (widget tools don't change per session)
- Lazy widget conversion (convert as needed)
- Avoid deep copying large widget trees

## Test Coverage Requirements

| Component | Min Coverage |
|-----------|--------------|
| A2uiMessageAdapter | 95% |
| CatalogToolBridge | 90% |
| A2uiControlTools | 100% |
| MessageConverter | 90% |

## Test Cases

### A2uiMessageAdapter Tests
- [ ] Convert BeginRenderingData with all fields
- [ ] Convert BeginRenderingData with only required fields
- [ ] Convert SurfaceUpdateData with flat widgets
- [ ] Convert SurfaceUpdateData with nested widgets (3+ levels)
- [ ] Convert DataModelUpdateData with various value types
- [ ] Convert DeleteSurfaceData with cascade true/false
- [ ] Widget conversion with null children
- [ ] Widget conversion with dataBinding

### CatalogToolBridge Tests ✅
- [x] Extract tools from Catalog
- [x] Extract tools from CatalogItem list
- [x] Schema conversion for primitive types (string, integer, number, boolean)
- [x] Schema conversion for nested objects
- [x] Combine with A2UI control tools
- [x] Handle empty catalog

### A2uiControlTools Tests ✅
- [x] All control tools defined (4 tools)
- [x] begin_rendering has correct schema and required fields
- [x] surface_update has correct schema and required fields
- [x] data_model_update has correct schema and required fields
- [x] delete_surface has correct schema and required fields

### MessageConverter Tests ✅
- [x] Convert user text message
- [x] Convert assistant text message
- [x] Convert conversation with multiple turns
- [x] Handle ToolCallPart in assistant messages
- [x] Handle ToolResponseMessage
- [x] Prune history to max messages
- [x] Preserve user-assistant pairs when pruning
- [x] Extract system context from InternalMessages

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
| 2025-12-14 | Updated status: A2uiMessageAdapter complete. CatalogToolBridge and MessageConverter not started. |
| 2025-12-14 | COMPLETE: Implemented CatalogToolBridge, A2uiControlTools, and MessageConverter with full test coverage. 53 tests passing. |
