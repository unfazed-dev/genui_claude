# TRACKER: A2UI Data Models Implementation

## Status: COMPLETE

## Overview

Implementation of all data model classes for the a2ui_claude package. These models provide type-safe Dart representations of A2UI protocol messages, tool schemas, widget nodes, and stream events.

**Parent Tracker:** [TRACKER-a2ui-claude-package.md](./TRACKER-a2ui-claude-package.md)

## Tasks

### A2UI Message Types (lib/src/models/a2ui_message.dart) ✅

#### Base Class ✅
- [x] Create `A2uiMessageData` sealed class
  ```dart
  sealed class A2uiMessageData {
    const A2uiMessageData();
    Map<String, dynamic> toJson();
  }
  ```

#### BeginRenderingData ✅
- [x] Implement BeginRenderingData class
- [x] Properties:
  - [x] surfaceId (required String)
  - [x] parentSurfaceId (optional String)
  - [x] metadata (optional Map<String, dynamic>)
- [x] Add fromJson factory constructor
- [x] Add toJson method
- [x] Add equality and hashCode overrides

#### SurfaceUpdateData ✅
- [x] Implement SurfaceUpdateData class
- [x] Properties:
  - [x] surfaceId (required String)
  - [x] widgets (required List<WidgetNode>)
  - [x] append (bool, default false)
- [x] Add fromJson factory constructor
- [x] Add toJson method
- [x] Add equality and hashCode overrides

#### DataModelUpdateData ✅
- [x] Implement DataModelUpdateData class
- [x] Properties:
  - [x] updates (required Map<String, dynamic>)
  - [x] scope (optional String)
- [x] Add fromJson factory constructor
- [x] Add toJson method
- [x] Add equality and hashCode overrides

#### DeleteSurfaceData ✅
- [x] Implement DeleteSurfaceData class
- [x] Properties:
  - [x] surfaceId (required String)
  - [x] cascade (bool, default true)
- [x] Add fromJson factory constructor
- [x] Add toJson method
- [x] Add equality and hashCode overrides

### Widget Node (lib/src/models/widget_node.dart) ✅

- [x] Implement WidgetNode class
- [x] Properties:
  - [x] type (required String)
  - [x] properties (required Map<String, dynamic>)
  - [x] children (optional List<WidgetNode>)
  - [x] dataBinding (optional String)
- [x] Add fromJson factory constructor (recursive for children)
- [x] Add toJson method
- [x] Add copyWith method for immutable updates
- [x] Add equality and hashCode overrides

### Tool Schema (lib/src/models/tool_schema.dart) ✅

- [x] Implement A2uiToolSchema class
- [x] Properties:
  - [x] name (required String)
  - [x] description (required String)
  - [x] inputSchema (required Map<String, dynamic>)
  - [x] requiredFields (optional List<String>)
- [x] Add fromJson factory constructor
- [x] Add toJson method
- [x] Add toClaudeTool() conversion method
- [x] Add equality and hashCode overrides

### Stream Events (lib/src/models/stream_event.dart) ✅

- [x] Create StreamEvent sealed class hierarchy:
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
- [x] Implement DeltaEvent for raw content deltas
- [x] Implement A2uiMessageEvent containing A2uiMessageData
- [x] Implement TextDeltaEvent for text content
- [x] Implement CompleteEvent for stream completion
- [x] Implement ErrorEvent with error string

### Parse Result (lib/src/models/parse_result.dart) ✅

- [x] Implement ParseResult class
- [x] Properties:
  - [x] a2uiMessages (List<A2uiMessageData>)
  - [x] textContent (String)
  - [x] hasToolUse (bool)
- [x] Add factory methods for common cases
- [x] Add isEmpty/isNotEmpty getters

### Validation Result (lib/src/models/validation_result.dart) ✅

- [x] Implement ValidationResult class
- [x] Properties:
  - [x] isValid (bool)
  - [x] errors (List<ValidationError>)
- [x] Implement ValidationError class
  - [x] field (String)
  - [x] message (String)
  - [x] code (String)

### Stream Config (lib/src/models/stream_config.dart) ✅

- [x] Implement StreamConfig class
- [x] Properties:
  - [x] maxTokens (int, default 4096)
  - [x] timeout (Duration, default 60s)
  - [x] retryAttempts (int, default 3)
- [x] Make it a const class for default instantiation
- [x] Add copyWith method

### JSON Serialization Setup (Freezed)

- [x] Freezed code generation implemented
- [x] @Freezed annotations added to all models
- [x] build.yaml created with explicit_to_json and include_if_null settings
- [x] build_runner generates .freezed.dart and .g.dart files
- [x] Generated files exported properly

**Migration Details:**
- Migrated from manual JSON to freezed 3.x code generation
- Added `abstract` keyword for non-sealed classes (freezed 3.x requirement)
- Configured `explicit_to_json: true` for proper nested object serialization

## Files

### Primary Files ✅
- `lib/src/models/a2ui_message.dart` ✅ - Message type hierarchy
- `lib/src/models/widget_node.dart` ✅ - Widget tree node
- `lib/src/models/tool_schema.dart` ✅ - Tool schema definition
- `lib/src/models/stream_event.dart` ✅ - Stream event types
- `lib/src/models/parse_result.dart` ✅ - Parser output
- `lib/src/models/validation_result.dart` ✅ - Validation output
- `lib/src/models/stream_config.dart` ✅ - Stream configuration

### Generated Files ✅
- `lib/src/models/a2ui_message.freezed.dart` ✅ - Freezed implementation
- `lib/src/models/a2ui_message.g.dart` ✅ - JSON serialization
- `lib/src/models/widget_node.freezed.dart` ✅
- `lib/src/models/widget_node.g.dart` ✅
- `lib/src/models/tool_schema.freezed.dart` ✅
- `lib/src/models/tool_schema.g.dart` ✅
- `lib/src/models/stream_event.freezed.dart` ✅
- `lib/src/models/parse_result.freezed.dart` ✅
- `lib/src/models/validation_result.freezed.dart` ✅
- `lib/src/models/stream_config.freezed.dart` ✅

### Barrel Export ✅
- `lib/src/models/models.dart` ✅ - Exports all models

## Dependencies

- freezed_annotation: ^3.1.0
- json_annotation: ^4.9.0
- meta: ^1.9.0

**Dev Dependencies:**
- freezed: ^3.0.6
- json_serializable: ^6.9.0
- build_runner: ^2.4.0

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
| 2025-12-14 | Status: COMPLETE. All data models implemented with manual JSON serialization. 37 tests passing for package. |
| 2025-12-14 | Marked json_serializable tasks as N/A - sealed classes not compatible with code generation. Manual JSON is the correct approach. 146 tests passing. |
| 2025-12-14 | **MIGRATED TO FREEZED**: All models migrated to freezed 3.x code generation. Added mocktail for mock clients. 146 tests passing. Industry standard approach. |
