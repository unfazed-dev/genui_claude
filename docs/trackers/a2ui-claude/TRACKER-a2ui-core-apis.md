# TRACKER: A2UI Core APIs Implementation

## Status: COMPLETE

## Overview

Implementation of the three core API components for a2ui_claude: A2uiToolConverter (tool schema conversion), ClaudeA2uiParser (response parsing), and ClaudeStreamHandler (streaming management).

**Parent Tracker:** [TRACKER-a2ui-claude-package.md](./TRACKER-a2ui-claude-package.md)

## Tasks

### A2uiToolConverter (lib/src/converter/) ✅

#### Main Class (tool_converter.dart) ✅
- [x] Create A2uiToolConverter class
- [x] Implement `toClaudeTools(List<A2uiToolSchema>)` static method
  - [x] Convert A2UI schema to Claude Tool format
  - [x] Handle nested object properties
  - [x] Map required fields correctly
- [x] Implement `generateToolInstructions(List<A2uiToolSchema>)` static method
  - [x] Generate system prompt supplement
  - [x] List available tools with descriptions
- [x] Implement `validateToolInput()` static method
  - [x] Validate tool name exists in schemas
  - [x] Validate input against schema
  - [x] Return ValidationResult with errors

#### Schema Mapper (schema_mapper.dart) ✅
- [x] Create SchemaMapper utility class
- [x] Implement `convertProperties(Map<String, dynamic>)` method
  - [x] Handle primitive types (string, number, boolean, integer)
  - [x] Handle array types with item schemas
  - [x] Handle nested object types
  - [x] Handle anyOf/oneOf unions
- [x] Implement `_enhanceDescription(A2uiToolSchema)` helper
  - [x] Add A2UI-specific context to descriptions
  - [x] Include widget hierarchy hints

### ClaudeA2uiParser (lib/src/parser/) ✅

#### Message Parser (message_parser.dart) ✅
- [x] Create ClaudeA2uiParser class
- [x] Implement `parseToolUse(ToolUseBlock)` static method
  - [x] Pattern match on tool name:
    - [x] 'begin_rendering' -> BeginRenderingData
    - [x] 'surface_update' -> SurfaceUpdateData
    - [x] 'data_model_update' -> DataModelUpdateData
    - [x] 'delete_surface' -> DeleteSurfaceData
  - [x] Return null for unknown tools
  - [x] Handle malformed input gracefully
- [x] Implement `parseMessage(Message)` static method
  - [x] Iterate through message.content blocks
  - [x] Collect A2uiMessageData from ToolUseBlocks
  - [x] Collect text from TextBlocks
  - [x] Return ParseResult

#### Stream Parser (stream_parser.dart) ✅
- [x] Create StreamParser class
- [x] Implement `parseStream(Stream<MessageStreamEvent>)` method
  - [x] Handle ContentBlockStart events
  - [x] Handle ContentBlockDelta events
  - [x] Handle ContentBlockStop events
  - [x] Yield A2uiMessageData as blocks complete
  - [x] Handle partial JSON accumulation

#### Block Handlers (block_handlers.dart) ✅
- [x] Create BlockHandler abstract class
- [x] Implement ToolUseBlockHandler
  - [x] Accumulate partial JSON from deltas
  - [x] Parse complete block on stop
  - [x] Validate before returning
- [x] Implement TextBlockHandler
  - [x] Accumulate text content
  - [x] Handle streaming text deltas
- [x] Create BlockHandlerFactory
  - [x] Return appropriate handler by block type

### ClaudeStreamHandler (lib/src/stream/) ✅

#### Stream Handler (stream_handler.dart) ✅
- [x] Create ClaudeStreamHandler class
- [x] Implement `streamRequest()` async generator method
  ```dart
  Stream<StreamEvent> streamRequest({
    required Stream<Map<String, dynamic>> messageStream,
    StreamConfig? config,
  })
  ```
- [x] Handle message stream event types:
  - [x] content_block_start
  - [x] content_block_delta
  - [x] content_block_stop
  - [x] message_stop
- [x] Yield appropriate StreamEvent types
- [x] Handle connection errors
- [x] Implement dispose method for cleanup

#### Retry Policy (retry_policy.dart) ✅
- [x] Create RetryPolicy class
- [x] Properties:
  - [x] maxAttempts (int)
  - [x] initialDelay (Duration)
  - [x] maxDelay (Duration)
  - [x] backoffMultiplier (double)
- [x] Implement `shouldRetry(Exception, int attempt)` method
- [x] Implement `getDelay(int attempt)` method with exponential backoff
- [x] Add default factory constructor

#### Rate Limiter (rate_limiter.dart) ✅
- [x] Create RateLimiter class
- [x] Handle 429 Too Many Requests responses
- [x] Queue requests when rate limited
- [x] Implement token bucket algorithm
- [x] Parse Retry-After header when available
- [x] Emit RateLimitEvent for monitoring

### Exception Classes (lib/src/exceptions/) ✅

#### Exception Hierarchy (exceptions.dart) ✅
- [x] Create A2uiException sealed class
  - [x] message property
  - [x] stackTrace property
  - [x] toString() override
- [x] Implement ToolConversionException
  - [x] toolName property
  - [x] invalidSchema property
- [x] Implement MessageParseException
  - [x] rawContent property
  - [x] expectedFormat property
- [x] Implement StreamException
  - [x] httpStatusCode property
  - [x] isRetryable property
- [x] Implement ValidationException
  - [x] errors property (List<ValidationError>)

### Utility Classes (lib/src/utils/) - Integrated into components

> JSON and validation utilities are integrated directly into the converter, parser, and model classes rather than as separate utility files.

- [x] JSON serialization in model classes
- [x] Validation in A2uiToolConverter.validateToolInput()
- [x] Required field validation in ValidationResult

## Files

### Converter ✅
- `lib/src/converter/tool_converter.dart` ✅
- `lib/src/converter/schema_mapper.dart` ✅
- `lib/src/converter/converter.dart` ✅ (barrel export)

### Parser ✅
- `lib/src/parser/message_parser.dart` ✅
- `lib/src/parser/stream_parser.dart` ✅
- `lib/src/parser/block_handlers.dart` ✅
- `lib/src/parser/parser.dart` ✅ (barrel export)

### Stream ✅
- `lib/src/stream/stream_handler.dart` ✅
- `lib/src/stream/retry_policy.dart` ✅
- `lib/src/stream/rate_limiter.dart` ✅
- `lib/src/stream/stream.dart` ✅ (barrel export)

### Exceptions ✅
- `lib/src/exceptions/exceptions.dart` ✅

### Utils (Integrated)
- Utilities integrated into model/converter/parser classes

## Dependencies

- anthropic_sdk_dart: ^0.9.0 (for types: Message, Tool, ToolUseBlock, etc.)
- collection: ^1.18.0 (for collection utilities)
- meta: ^1.9.0 (for annotations)

## Notes

### API Design Principles

1. **Static Methods for Stateless Operations**:
   - Tool conversion and message parsing are stateless
   - Use static methods for easy testing and no instantiation overhead

2. **Instance for Stateful Operations**:
   - StreamHandler maintains connection state
   - RateLimiter tracks request history
   - Use instance methods with dependency injection

3. **Error Handling Strategy**:
   - Network errors -> StreamException with isRetryable=true
   - Parse errors -> MessageParseException with raw content
   - Schema errors -> ToolConversionException with details
   - Validation errors -> ValidationException with error list

### Performance Targets (from spec)

| Operation | Target Latency |
|-----------|----------------|
| Tool schema conversion (10 tools) | < 1ms |
| Parse single tool_use block | < 0.5ms |
| Stream event processing | < 0.1ms/event |
| Full response parse | < 5ms |

### Stream Processing Architecture

```
MessageStreamEvent (from SDK)
        │
        ▼
┌─────────────────┐
│ ClaudeStreamHandler │
│ (event routing)     │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
BlockHandler  BlockHandler
(tool_use)    (text)
    │         │
    ▼         ▼
A2uiMessageEvent  TextDeltaEvent
    │         │
    └────┬────┘
         ▼
    StreamEvent
    (to consumer)
```

### Connection Management

- Reuse AnthropicClient for connection pooling
- Clean up handlers on stream cancellation
- Timeout handling at StreamConfig level
- Graceful degradation on partial failures

## Test Requirements

| Component | Min Coverage |
|-----------|--------------|
| A2uiToolConverter | 90% |
| SchemaMapper | 90% |
| ClaudeA2uiParser | 90% |
| StreamParser | 85% |
| BlockHandlers | 85% |
| ClaudeStreamHandler | 85% |
| RetryPolicy | 95% |
| RateLimiter | 90% |

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
| 2025-12-14 | Status: COMPLETE. All core APIs implemented: A2uiToolConverter, ClaudeA2uiParser, ClaudeStreamHandler, exceptions. |
