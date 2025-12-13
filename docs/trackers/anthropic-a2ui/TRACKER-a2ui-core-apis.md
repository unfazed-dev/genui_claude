# TRACKER: A2UI Core APIs Implementation

## Status: PLANNING

## Overview

Implementation of the three core API components for anthropic_a2ui: A2uiToolConverter (tool schema conversion), ClaudeA2uiParser (response parsing), and ClaudeStreamHandler (streaming management).

**Parent Tracker:** [TRACKER-anthropic-a2ui-package.md](./TRACKER-anthropic-a2ui-package.md)

## Tasks

### A2uiToolConverter (lib/src/converter/)

#### Main Class (tool_converter.dart)
- [ ] Create A2uiToolConverter class
- [ ] Implement `toClaudeTools(List<A2uiToolSchema>)` static method
  - [ ] Convert A2UI schema to Claude Tool format
  - [ ] Handle nested object properties
  - [ ] Map required fields correctly
- [ ] Implement `generateToolInstructions(List<A2uiToolSchema>)` static method
  - [ ] Generate system prompt supplement
  - [ ] List available tools with descriptions
- [ ] Implement `validateToolInput()` static method
  - [ ] Validate tool name exists in schemas
  - [ ] Validate input against schema
  - [ ] Return ValidationResult with errors

#### Schema Mapper (schema_mapper.dart)
- [ ] Create SchemaMapper utility class
- [ ] Implement `convertProperties(Map<String, dynamic>)` method
  - [ ] Handle primitive types (string, number, boolean, integer)
  - [ ] Handle array types with item schemas
  - [ ] Handle nested object types
  - [ ] Handle anyOf/oneOf unions
- [ ] Implement `_enhanceDescription(A2uiToolSchema)` helper
  - [ ] Add A2UI-specific context to descriptions
  - [ ] Include widget hierarchy hints

### ClaudeA2uiParser (lib/src/parser/)

#### Message Parser (message_parser.dart)
- [ ] Create ClaudeA2uiParser class
- [ ] Implement `parseToolUse(ToolUseBlock)` static method
  - [ ] Pattern match on tool name:
    - [ ] 'begin_rendering' -> BeginRenderingData
    - [ ] 'surface_update' -> SurfaceUpdateData
    - [ ] 'data_model_update' -> DataModelUpdateData
    - [ ] 'delete_surface' -> DeleteSurfaceData
  - [ ] Return null for unknown tools
  - [ ] Handle malformed input gracefully
- [ ] Implement `parseMessage(Message)` static method
  - [ ] Iterate through message.content blocks
  - [ ] Collect A2uiMessageData from ToolUseBlocks
  - [ ] Collect text from TextBlocks
  - [ ] Return ParseResult

#### Stream Parser (stream_parser.dart)
- [ ] Create StreamParser class
- [ ] Implement `parseStream(Stream<MessageStreamEvent>)` method
  - [ ] Handle ContentBlockStart events
  - [ ] Handle ContentBlockDelta events
  - [ ] Handle ContentBlockStop events
  - [ ] Yield A2uiMessageData as blocks complete
  - [ ] Handle partial JSON accumulation

#### Block Handlers (block_handlers.dart)
- [ ] Create BlockHandler abstract class
- [ ] Implement ToolUseBlockHandler
  - [ ] Accumulate partial JSON from deltas
  - [ ] Parse complete block on stop
  - [ ] Validate before returning
- [ ] Implement TextBlockHandler
  - [ ] Accumulate text content
  - [ ] Handle streaming text deltas
- [ ] Create BlockHandlerFactory
  - [ ] Return appropriate handler by block type

### ClaudeStreamHandler (lib/src/stream/)

#### Stream Handler (stream_handler.dart)
- [ ] Create ClaudeStreamHandler class
- [ ] Constructor taking AnthropicClient and optional StreamConfig
- [ ] Implement `streamRequest()` async generator method
  ```dart
  Stream<StreamEvent> streamRequest({
    required List<Message> messages,
    required List<Tool> tools,
    required String systemPrompt,
    String model = 'claude-sonnet-4-20250514',
  })
  ```
- [ ] Handle MessageStreamEvent types:
  - [ ] message_start
  - [ ] content_block_start
  - [ ] content_block_delta
  - [ ] content_block_stop
  - [ ] message_delta
  - [ ] message_stop
- [ ] Yield appropriate StreamEvent types
- [ ] Handle connection errors
- [ ] Implement cleanup on cancel

#### Retry Policy (retry_policy.dart)
- [ ] Create RetryPolicy class
- [ ] Properties:
  - [ ] maxAttempts (int)
  - [ ] initialDelay (Duration)
  - [ ] maxDelay (Duration)
  - [ ] backoffMultiplier (double)
- [ ] Implement `shouldRetry(Exception, int attempt)` method
- [ ] Implement `getDelay(int attempt)` method with exponential backoff
- [ ] Implement `retryWithBackoff<T>(Future<T> Function())` method

#### Rate Limiter (rate_limiter.dart)
- [ ] Create RateLimiter class
- [ ] Handle 429 Too Many Requests responses
- [ ] Queue requests when rate limited
- [ ] Implement token bucket or sliding window algorithm
- [ ] Parse Retry-After header when available
- [ ] Emit RateLimitEvent for monitoring

### Exception Classes (lib/src/exceptions/)

#### Exception Hierarchy (exceptions.dart)
- [ ] Create A2uiException sealed class
  - [ ] message property
  - [ ] stackTrace property
  - [ ] toString() override
- [ ] Implement ToolConversionException
  - [ ] toolName property
  - [ ] invalidSchema property
- [ ] Implement MessageParseException
  - [ ] rawContent property
  - [ ] expectedFormat property
- [ ] Implement StreamException
  - [ ] httpStatusCode property
  - [ ] isRetryable property
- [ ] Implement ValidationException
  - [ ] errors property (List<ValidationError>)

### Utility Classes (lib/src/utils/)

#### JSON Utilities (json_utils.dart)
- [ ] Create JsonUtils class
- [ ] Implement `safeDecode(String)` method
- [ ] Implement `safeGet<T>(Map, String key)` method
- [ ] Implement `deepMerge(Map, Map)` method
- [ ] Handle null values gracefully

#### Validation Utilities (validation.dart)
- [ ] Create Validation utility class
- [ ] Implement JSON Schema validation
- [ ] Widget tree depth validation (prevent stack overflow)
- [ ] String length limit validation
- [ ] Required field validation

## Files

### Converter
- `lib/src/converter/tool_converter.dart`
- `lib/src/converter/schema_mapper.dart`
- `lib/src/converter/converter.dart` (barrel export)

### Parser
- `lib/src/parser/message_parser.dart`
- `lib/src/parser/stream_parser.dart`
- `lib/src/parser/block_handlers.dart`
- `lib/src/parser/parser.dart` (barrel export)

### Stream
- `lib/src/stream/stream_handler.dart`
- `lib/src/stream/retry_policy.dart`
- `lib/src/stream/rate_limiter.dart`
- `lib/src/stream/stream.dart` (barrel export)

### Exceptions
- `lib/src/exceptions/exceptions.dart`

### Utils
- `lib/src/utils/json_utils.dart`
- `lib/src/utils/validation.dart`
- `lib/src/utils/utils.dart` (barrel export)

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
