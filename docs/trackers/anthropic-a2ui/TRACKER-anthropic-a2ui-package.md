# TRACKER: anthropic_a2ui Package Implementation

## Status: PLANNING

## Overview

Pure Dart package for converting between Anthropic's Claude API responses and A2UI (Agent-to-UI) protocol messages. Serves as the foundational layer for integrating Claude's capabilities with generative UI frameworks. Zero Flutter dependencies to enable deployment across Flutter apps, Dart CLI, server-side Dart, and edge functions.

**Specification Document:** [docs/anthropic_a2ui_spec.md](../anthropic_a2ui_spec.md)

## Tasks

### Phase 1: Package Infrastructure
- [ ] Convert pubspec.yaml to pure Dart (remove Flutter SDK dependency)
- [ ] Add runtime dependencies:
  - [ ] anthropic_sdk_dart: ^0.9.0
  - [ ] json_annotation: ^4.8.0
  - [ ] meta: ^1.9.0
  - [ ] collection: ^1.18.0
- [ ] Add dev dependencies:
  - [ ] test: ^1.24.0
  - [ ] mockito: ^5.4.0
  - [ ] build_runner: ^2.4.0
  - [ ] json_serializable: ^6.7.0
  - [ ] coverage: ^1.6.0
- [ ] Update SDK constraint to `>=3.0.0 <4.0.0`
- [ ] Create package directory structure per spec

### Phase 2: Data Models
- [ ] Create `lib/src/models/` directory
- [ ] Implement A2uiMessageData sealed class hierarchy
- [ ] Implement BeginRenderingData
- [ ] Implement SurfaceUpdateData
- [ ] Implement DataModelUpdateData
- [ ] Implement DeleteSurfaceData
- [ ] Implement WidgetNode model
- [ ] Implement A2uiToolSchema
- [ ] Implement StreamEvent types
- [ ] Implement ParseResult
- [ ] Add JSON serialization with json_serializable

### Phase 3: Core Components
- [ ] Create A2uiToolConverter (lib/src/converter/)
  - [ ] toClaudeTools() method
  - [ ] generateToolInstructions() method
  - [ ] validateToolInput() method
  - [ ] Schema mapping utilities
- [ ] Create ClaudeA2uiParser (lib/src/parser/)
  - [ ] parseToolUse() method
  - [ ] parseMessage() method
  - [ ] parseStream() method
  - [ ] Block handlers for each content type
- [ ] Create ClaudeStreamHandler (lib/src/stream/)
  - [ ] streamRequest() method
  - [ ] StreamConfig class
  - [ ] Retry policy implementation
  - [ ] Rate limiter

### Phase 4: Error Handling
- [ ] Create exception hierarchy (lib/src/exceptions/)
  - [ ] A2uiException sealed class
  - [ ] ToolConversionException
  - [ ] MessageParseException
  - [ ] StreamException
  - [ ] ValidationException
- [ ] Implement error recovery strategies
- [ ] Add validation utilities

### Phase 5: Public API
- [ ] Update lib/anthropic_a2ui.dart exports
- [ ] Ensure all public types are exported
- [ ] Add library-level documentation

### Phase 6: Testing
- [ ] Unit tests for A2uiToolConverter
- [ ] Unit tests for ClaudeA2uiParser
- [ ] Unit tests for ClaudeStreamHandler
- [ ] Unit tests for all data models
- [ ] Integration tests for end-to-end flow
- [ ] Create mock response fixtures
- [ ] Achieve 90%+ code coverage

### Phase 7: Documentation & Examples
- [ ] Create example/basic_usage.dart
- [ ] Create example/streaming_example.dart
- [ ] Create example/server_side_example.dart
- [ ] Update package README.md
- [ ] Add inline API documentation
- [ ] Create CHANGELOG.md entry

## Files

### Package Root
- `packages/anthropic_a2ui/pubspec.yaml` - Package configuration (needs major update)
- `packages/anthropic_a2ui/lib/anthropic_a2ui.dart` - Public exports
- `packages/anthropic_a2ui/analysis_options.yaml` - Linting rules

### Source Files (to create)
- `lib/src/models/a2ui_message.dart` - Message types
- `lib/src/models/tool_schema.dart` - Tool definitions
- `lib/src/models/widget_node.dart` - Widget tree nodes
- `lib/src/models/stream_event.dart` - Stream event types
- `lib/src/models/parse_result.dart` - Parser results
- `lib/src/converter/tool_converter.dart` - A2UI ↔ Claude tool conversion
- `lib/src/converter/schema_mapper.dart` - JSON Schema mapping
- `lib/src/parser/message_parser.dart` - Response parsing
- `lib/src/parser/stream_parser.dart` - SSE stream parsing
- `lib/src/parser/block_handlers.dart` - Content block handlers
- `lib/src/stream/stream_handler.dart` - Stream management
- `lib/src/stream/retry_policy.dart` - Retry logic
- `lib/src/stream/rate_limiter.dart` - Rate limit handling
- `lib/src/exceptions/exceptions.dart` - Exception hierarchy
- `lib/src/utils/json_utils.dart` - JSON helpers
- `lib/src/utils/validation.dart` - Input validation

### Test Files (to create)
- `test/converter/tool_converter_test.dart`
- `test/parser/message_parser_test.dart`
- `test/parser/stream_parser_test.dart`
- `test/stream/stream_handler_test.dart`
- `test/models/a2ui_message_test.dart`
- `test/integration/end_to_end_test.dart`
- `test/fixtures/mock_responses.dart`

## Dependencies

### External
- anthropic_sdk_dart package (Claude API client)
- json_annotation for serialization
- meta for annotations

### Internal (monorepo)
- None for this package (it's the foundation layer)
- genui_anthropic depends on this package

## Notes

### Architecture Decisions
- Using sealed class for A2uiMessageData to leverage exhaustive pattern matching
- Stream-first design for real-time progressive UI rendering
- Lazy parsing to minimize memory usage during streaming

### Current State
- Package exists as placeholder with Flutter dependency
- Must be converted to pure Dart package
- No actual implementation exists yet

### Key Considerations
- This is a foundational package - genui_anthropic depends on it
- Must be deployable to edge functions (Supabase, Cloudflare Workers)
- Performance benchmarks defined in spec:
  - Tool schema conversion (10 tools): < 1ms
  - Parse single tool_use block: < 0.5ms
  - Stream event processing: < 0.1ms/event

## Related Trackers

- [TRACKER-a2ui-data-models.md](./TRACKER-a2ui-data-models.md) - Detailed model implementation
- [TRACKER-a2ui-core-apis.md](./TRACKER-a2ui-core-apis.md) - Core API implementation
- [TRACKER-a2ui-testing.md](./TRACKER-a2ui-testing.md) - Test implementation

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec document |
