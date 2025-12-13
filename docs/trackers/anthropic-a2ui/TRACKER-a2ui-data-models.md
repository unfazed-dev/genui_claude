# TRACKER: A2UI Data Models Implementation

## Status: PLANNING

## Overview

Implementation of all data model classes for the anthropic_a2ui package. These models provide type-safe Dart representations of A2UI protocol messages, tool schemas, widget nodes, and stream events.

**Parent Tracker:** [TRACKER-anthropic-a2ui-package.md](./TRACKER-anthropic-a2ui-package.md)

## Tasks

### A2UI Message Types (lib/src/models/a2ui_message.dart)

#### Base Class
- [ ] Create `A2uiMessageData` sealed class
  ```dart
  sealed class A2uiMessageData {
    const A2uiMessageData();
    Map<String, dynamic> toJson();
  }
  ```

#### BeginRenderingData
- [ ] Implement BeginRenderingData class
- [ ] Properties:
  - [ ] surfaceId (required String)
  - [ ] parentSurfaceId (optional String)
  - [ ] metadata (optional Map<String, dynamic>)
- [ ] Add fromJson factory constructor
- [ ] Add toJson method
- [ ] Add equality and hashCode overrides

#### SurfaceUpdateData
- [ ] Implement SurfaceUpdateData class
- [ ] Properties:
  - [ ] surfaceId (required String)
  - [ ] widgets (required List<WidgetNode>)
  - [ ] append (bool, default false)
- [ ] Add fromJson factory constructor
- [ ] Add toJson method
- [ ] Add equality and hashCode overrides

#### DataModelUpdateData
- [ ] Implement DataModelUpdateData class
- [ ] Properties:
  - [ ] updates (required Map<String, dynamic>)
  - [ ] scope (optional String)
- [ ] Add fromJson factory constructor
- [ ] Add toJson method
- [ ] Add equality and hashCode overrides

#### DeleteSurfaceData
- [ ] Implement DeleteSurfaceData class
- [ ] Properties:
  - [ ] surfaceId (required String)
  - [ ] cascade (bool, default true)
- [ ] Add fromJson factory constructor
- [ ] Add toJson method
- [ ] Add equality and hashCode overrides

### Widget Node (lib/src/models/widget_node.dart)

- [ ] Implement WidgetNode class
- [ ] Properties:
  - [ ] type (required String)
  - [ ] properties (required Map<String, dynamic>)
  - [ ] children (optional List<WidgetNode>)
  - [ ] dataBinding (optional String)
- [ ] Add fromJson factory constructor (recursive for children)
- [ ] Add toJson method
- [ ] Add copyWith method for immutable updates
- [ ] Add equality and hashCode overrides

### Tool Schema (lib/src/models/tool_schema.dart)

- [ ] Implement A2uiToolSchema class
- [ ] Properties:
  - [ ] name (required String)
  - [ ] description (required String)
  - [ ] inputSchema (required Map<String, dynamic>)
  - [ ] requiredFields (optional List<String>)
- [ ] Add fromJson factory constructor
- [ ] Add toJson method
- [ ] Add toClaudeTool() conversion method
- [ ] Add equality and hashCode overrides

### Stream Events (lib/src/models/stream_event.dart)

- [ ] Create StreamEvent sealed class hierarchy:
  ```dart
  sealed class StreamEvent {
    const StreamEvent();
  }

  class DeltaEvent extends StreamEvent { ... }
  class A2uiMessageEvent extends StreamEvent { ... }
  class TextDeltaEvent extends StreamEvent { ... }
  class CompleteEvent extends StreamEvent { ... }
  class ErrorEvent extends StreamEvent { ... }
  ```
- [ ] Implement DeltaEvent for raw content deltas
- [ ] Implement A2uiMessageEvent containing A2uiMessageData
- [ ] Implement TextDeltaEvent for text content
- [ ] Implement CompleteEvent for stream completion
- [ ] Implement ErrorEvent with A2uiException

### Parse Result (lib/src/models/parse_result.dart)

- [ ] Implement ParseResult class
- [ ] Properties:
  - [ ] a2uiMessages (List<A2uiMessageData>)
  - [ ] textContent (String)
  - [ ] hasToolUse (bool)
- [ ] Add factory methods for common cases
- [ ] Add isEmpty/isNotEmpty getters

### Validation Result (lib/src/models/validation_result.dart)

- [ ] Implement ValidationResult class
- [ ] Properties:
  - [ ] isValid (bool)
  - [ ] errors (List<ValidationError>)
- [ ] Implement ValidationError class
  - [ ] field (String)
  - [ ] message (String)
  - [ ] code (String)

### Stream Config (lib/src/models/stream_config.dart)

- [ ] Implement StreamConfig class
- [ ] Properties:
  - [ ] maxTokens (int, default 4096)
  - [ ] timeout (Duration, default 60s)
  - [ ] retryAttempts (int, default 3)
- [ ] Make it a const class for default instantiation

### JSON Serialization Setup

- [ ] Add @JsonSerializable annotations to all models
- [ ] Create build.yaml for json_serializable config
- [ ] Run build_runner to generate .g.dart files
- [ ] Export generated files properly

## Files

### Primary Files
- `lib/src/models/a2ui_message.dart` - Message type hierarchy
- `lib/src/models/widget_node.dart` - Widget tree node
- `lib/src/models/tool_schema.dart` - Tool schema definition
- `lib/src/models/stream_event.dart` - Stream event types
- `lib/src/models/parse_result.dart` - Parser output
- `lib/src/models/validation_result.dart` - Validation output
- `lib/src/models/stream_config.dart` - Stream configuration

### Generated Files
- `lib/src/models/a2ui_message.g.dart`
- `lib/src/models/widget_node.g.dart`
- `lib/src/models/tool_schema.g.dart`
- `lib/src/models/parse_result.g.dart`

### Barrel Export
- `lib/src/models/models.dart` - Exports all models

## Dependencies

- json_annotation: ^4.8.0
- json_serializable: ^6.7.0 (dev)
- meta: ^1.9.0

## Notes

### Design Decisions

1. **Sealed Classes**: Using sealed class for A2uiMessageData and StreamEvent enables:
   - Exhaustive pattern matching in switch statements
   - Type-safe message handling
   - Compiler-enforced handling of all cases

2. **Immutability**: All models are immutable with:
   - Final fields
   - Const constructors where applicable
   - copyWith methods for updates

3. **JSON Serialization**: Using json_serializable for:
   - Consistent serialization patterns
   - Reduced boilerplate
   - Type-safe JSON handling

4. **Nullable vs Required**: Following spec exactly:
   - Required fields throw on null
   - Optional fields use nullable types

### Performance Considerations

- WidgetNode uses recursive fromJson - may need optimization for deep trees
- Consider lazy deserialization for large widget lists
- Pre-compute hashCode for frequently compared objects

### Validation

- All fromJson methods should validate input
- Throw MessageParseException for invalid data
- Include original JSON in error for debugging

## Test Coverage Requirements

| Model | Min Coverage |
|-------|--------------|
| A2uiMessageData hierarchy | 95% |
| WidgetNode | 95% |
| A2uiToolSchema | 95% |
| StreamEvent hierarchy | 90% |
| ParseResult | 100% |
| ValidationResult | 100% |

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
