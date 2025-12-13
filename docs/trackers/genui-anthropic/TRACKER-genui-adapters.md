# TRACKER: GenUI Adapters and Bridges Implementation

## Status: PLANNING

## Overview

Implementation of adapter and bridge classes that connect anthropic_a2ui types to GenUI SDK types. This includes A2uiMessageAdapter for message conversion and CatalogToolBridge for tool catalog extraction.

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### A2uiMessageAdapter (lib/src/adapter/message_adapter.dart)

#### Main Conversion Method
- [ ] Create A2uiMessageAdapter class
- [ ] Implement toGenUiMessage(A2uiMessageData) static method
- [ ] Use exhaustive pattern matching on A2uiMessageData:
  ```dart
  static A2uiMessage toGenUiMessage(A2uiMessageData data) {
    return switch (data) {
      BeginRenderingData d => ...,
      SurfaceUpdateData d => ...,
      DataModelUpdateData d => ...,
      DeleteSurfaceData d => ...,
    };
  }
  ```

#### BeginRenderingData Conversion
- [ ] Map to A2uiMessage.beginRendering()
- [ ] Pass surfaceId
- [ ] Pass parentSurfaceId (if present)
- [ ] Handle metadata (if GenUI supports it)

#### SurfaceUpdateData Conversion
- [ ] Map to A2uiMessage.surfaceUpdate()
- [ ] Pass surfaceId
- [ ] Convert widgets list using _toGenUiWidget()
- [ ] Handle append flag

#### DataModelUpdateData Conversion
- [ ] Map to A2uiMessage.dataModelUpdate()
- [ ] Pass updates map
- [ ] Handle scope (if GenUI supports it)

#### DeleteSurfaceData Conversion
- [ ] Map to A2uiMessage.deleteSurface()
- [ ] Pass surfaceId
- [ ] Handle cascade flag

#### Widget Node Conversion
- [ ] Implement _toGenUiWidget(WidgetNode) private static method
- [ ] Create GenUiWidget with:
  - [ ] type from node.type
  - [ ] properties from node.properties
  - [ ] children via recursive mapping
  - [ ] dataBinding from node.dataBinding
- [ ] Handle null children gracefully

### CatalogToolBridge (lib/src/adapter/tool_bridge.dart)

#### Catalog Extraction Methods
- [ ] Create CatalogToolBridge class
- [ ] Implement fromCatalog(GenUiManager) static method
  - [ ] Extract catalog.items from manager
  - [ ] Map each CatalogItem to Tool
- [ ] Implement fromItems(List<CatalogItem>) static method
  - [ ] Direct mapping of CatalogItem list to Tool list
  - [ ] Convert inputSchema to Claude format

#### Tool Conversion Logic
- [ ] Map CatalogItem.name to Tool.name
- [ ] Map CatalogItem.description to Tool.description
- [ ] Convert CatalogItem.inputSchema to Tool.inputSchema
- [ ] Use A2uiToolConverter from anthropic_a2ui for schema conversion

#### A2UI Control Tools
- [ ] Create A2uiControlTools class/constant
- [ ] Define begin_rendering tool:
  ```dart
  Tool(
    name: 'begin_rendering',
    description: 'Signal the start of UI generation for a surface',
    inputSchema: {...},
  )
  ```
- [ ] Define surface_update tool
- [ ] Define data_model_update tool
- [ ] Define delete_surface tool
- [ ] Implement A2uiControlTools.all getter

#### Combined Tool List
- [ ] Implement withA2uiTools(List<Tool>) static method
- [ ] Prepend A2UI control tools to widget tools
- [ ] Return combined list

### MessageConverter (lib/src/utils/message_converter.dart)

#### GenUI to Claude Message Conversion
- [ ] Create MessageConverter class
- [ ] Implement toClaudeMessages(List<GenUiMessage>) static method
- [ ] Handle user messages:
  - [ ] Extract text content
  - [ ] Convert to Claude Message.user()
- [ ] Handle assistant messages:
  - [ ] Extract text content
  - [ ] Include tool_use blocks if present
  - [ ] Convert to Claude Message.assistant()
- [ ] Handle system messages (if applicable)

#### Conversation History Management
- [ ] Implement pruneHistory(List<Message>, int maxMessages) method
- [ ] Keep most recent N messages
- [ ] Preserve conversation coherence (user-assistant pairs)
- [ ] Always include system context

#### Image Handling (Future)
- [ ] Placeholder for image message conversion
- [ ] Convert base64/URL images to Claude format

## Files

### Adapter
- `lib/src/adapter/message_adapter.dart` - A2UI message bridging
- `lib/src/adapter/tool_bridge.dart` - Catalog to tools conversion
- `lib/src/adapter/a2ui_control_tools.dart` - A2UI tool definitions
- `lib/src/adapter/adapter.dart` (barrel export)

### Utils
- `lib/src/utils/message_converter.dart` - GenUI Message conversion
- `lib/src/utils/utils.dart` (barrel export)

## Dependencies

- genui (A2uiMessage, GenUiWidget, GenUiManager, CatalogItem, Message types)
- anthropic_a2ui (A2uiMessageData, WidgetNode, BeginRenderingData, etc.)
- anthropic_sdk_dart (Tool, Message types)

## Notes

### Type Mapping Reference

| anthropic_a2ui | genui |
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

### CatalogToolBridge Tests
- [ ] Extract tools from GenUiManager
- [ ] Extract tools from CatalogItem list
- [ ] Schema conversion for primitive types
- [ ] Schema conversion for arrays
- [ ] Schema conversion for nested objects
- [ ] Combine with A2UI control tools
- [ ] Handle empty catalog

### MessageConverter Tests
- [ ] Convert user text message
- [ ] Convert assistant text message
- [ ] Convert conversation with multiple turns
- [ ] Prune history to max messages
- [ ] Preserve user-assistant pairs when pruning

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
