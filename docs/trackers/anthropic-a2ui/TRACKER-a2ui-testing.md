# TRACKER: A2UI Testing Implementation

## Status: COMPLETE

## Overview

Comprehensive testing strategy for the anthropic_a2ui package including unit tests, integration tests, mock fixtures, and coverage requirements. Target: 90%+ overall code coverage.

**Parent Tracker:** [TRACKER-anthropic-a2ui-package.md](./TRACKER-anthropic-a2ui-package.md)

## Tasks

### Test Infrastructure Setup ✅

- [x] Configure test dependencies in pubspec.yaml
  - [x] test: ^1.24.0
  - [x] mocktail: ^1.0.3 (replaced mockito - no codegen needed)
  - [x] build_runner: ^2.4.0
  - [x] coverage: ^1.6.0
- [x] Create test directory structure
- [x] Create test utilities and helpers
- [x] Create mock_clients.dart with mocktail mocks

**Current: 146 tests passing**

### Mock Fixtures (test/fixtures/) ✅

#### Mock Responses (mock_responses.dart) ✅
- [x] Create MockStreamEvents class with event factories
- [x] Create mock tool_use ToolUseBlock samples:
  - [x] begin_rendering mock
  - [x] surface_update mock (simple)
  - [x] surface_update mock (nested widgets)
  - [x] data_model_update mock
  - [x] delete_surface mock
- [x] Create mock error responses:
  - [x] 429 rate limit response
  - [x] 500 server error response
  - [x] Malformed JSON response
  - [x] Authentication error response
- [x] Create MockStreamSequences for complete stream flows

#### Mock Clients (test/mocks/mock_clients.dart) ✅
- [x] Create MockHttpClient using mocktail
- [x] Implement stubStreamResponse helper
- [x] Implement stubErrorStream helper
- [x] Implement stubDelayedStream helper
- [x] Create MockStreamHandler for testing stream processing
- [x] Create MockStreamedResponse for HTTP response simulation
- [x] Create MockEventSequences for common test scenarios
- [x] Create registerMockFallbackValues() helper

**Architecture Note:** Package is decoupled from anthropic_sdk_dart:
- `ClaudeStreamHandler.streamRequest()` accepts `Stream<Map<String, dynamic>>`
- Mock clients simulate HTTP-level interactions, not SDK types
- This enables testing without external dependencies

### Unit Tests - Models (test/anthropic_a2ui_test.dart) ✅

#### a2ui_message tests ✅
- [x] Test BeginRenderingData
  - [x] Construction with required fields
  - [x] Construction with optional fields (all fields)
  - [x] toJson serialization
  - [x] fromJson parsing (deserializes from JSON)
- [x] Test SurfaceUpdateData
  - [x] Construction with widgets list
  - [x] toJson serialization
- [x] Test DataModelUpdateData
  - [x] Construction with updates
  - [x] Construction with scope
- [x] Test DeleteSurfaceData
  - [x] cascade flag defaults (true)
  - [x] cascade flag false

#### widget_node tests ✅
- [x] Test construction with required fields
- [x] Test widget with children
- [x] Test copyWith method

#### tool_schema tests ✅
- [x] Test schema construction with required fields

### Unit Tests - Converter (test/anthropic_a2ui_test.dart) ✅

#### A2uiToolConverter tests ✅
- [x] Test validateToolInput - valid input
- [x] Test validateToolInput - missing required field
- [x] Test validateToolInput - unknown tool
- [x] Test generateToolInstructions output format
- [x] Test toClaudeTools with single schema
- [x] Test toClaudeTools with multiple schemas
- [x] Test toClaudeTools with nested object properties
- [x] Test toClaudeTools with array properties

#### SchemaMapper tests ✅
- [x] Test string property conversion
- [x] Test string property with enum
- [x] Test number property conversion
- [x] Test integer property conversion
- [x] Test boolean property conversion
- [x] Test array property with items
- [x] Test object property with nested properties
- [x] Test deeply nested object
- [x] Test empty map for null properties
- [x] Test preserves unknown types

### Unit Tests - Parser (test/anthropic_a2ui_test.dart) ✅

#### ClaudeA2uiParser tests ✅
- [x] Test parseToolUse - begin_rendering
- [x] Test parseToolUse - surface_update
- [x] Test parseToolUse - unknown tool returns null
- [x] Test parseMessage - with tool_use blocks
- [x] Test parseToolUse - data_model_update
- [x] Test parseToolUse - delete_surface
- [x] Test parseMessage - mixed content (tool + text)
- [x] Test parseMessage - text only
- [x] Test parseMessage - null content returns empty
- [x] Test parseMessage - skips unknown tools

#### StreamParser tests ✅
- [x] Test reset clears internal state
- [x] Test parseStream yields nothing for empty stream
- [x] Test parseStream handles content_block_start for tool_use
- [x] Test parseStream handles content_block_delta
- [x] Test parseStream handles non-tool_use content_block_start
- [x] Test parseStream - complete tool_use block sequence
- [x] Test parseStream - error mid-stream
- [x] Test stream cancellation cleanup

#### BlockHandlers tests ✅
- [x] Test ToolUseBlockHandler accumulates partial JSON deltas
- [x] Test ToolUseBlockHandler ignores null partial_json
- [x] Test ToolUseBlockHandler reset clears buffer and toolName
- [x] Test TextBlockHandler accumulates text deltas
- [x] Test TextBlockHandler ignores null text
- [x] Test TextBlockHandler reset clears buffer
- [x] Test BlockHandlerFactory creates ToolUseBlockHandler for tool_use
- [x] Test BlockHandlerFactory creates TextBlockHandler for text
- [x] Test BlockHandlerFactory returns null for unknown type

### Unit Tests - Stream (test/anthropic_a2ui_test.dart) (Partial)

#### StreamConfig tests ✅
- [x] Test has default values
- [x] Test copyWith creates modified copy

#### ParseResult tests ✅
- [x] Test empty result
- [x] Test text only result
- [x] Test messages only result

#### ValidationResult tests ✅
- [x] Test valid result
- [x] Test invalid result with errors
- [x] Test error factory

#### RetryPolicy tests ✅
- [x] Test has default values
- [x] Test shouldRetry respects max attempts
- [x] Test shouldRetry checks isRetryable
- [x] Test getDelay uses exponential backoff

#### ClaudeStreamHandler tests ✅
- [x] Test creates with default config
- [x] Test creates with custom config
- [x] Test streamRequest yields TextDeltaEvent for text deltas
- [x] Test streamRequest yields CompleteEvent on message_stop
- [x] Test streamRequest yields ErrorEvent on error type
- [x] Test streamRequest handles content_block_start for tool_use
- [x] Test dispose resets internal state
- [x] Test StreamEvent sealed class exhaustive matching
- [x] Test streamRequest handles unknown event types gracefully

#### RateLimiter tests ✅
- [x] Test executes request immediately when not rate limited
- [x] Test records 429 response and sets rate limited state
- [x] Test parses Retry-After header as seconds
- [x] Test queues requests when rate limited
- [x] Test ignores non-429 status codes
- [x] Test dispose cancels timer and clears queue
- [x] Test uses custom retry duration from Retry-After header

### Unit Tests - Exceptions (test/anthropic_a2ui_test.dart) ✅

#### Exceptions tests ✅
- [x] Test ToolConversionException contains tool name
- [x] Test StreamException tracks retryable status
- [x] Test ValidationException contains errors
- [x] Test MessageParseException with raw content
- [x] Test StreamException toString includes HTTP status
- [x] Test ValidationException toString shows error count
- [x] Test ValidationError toString formats correctly
- [x] Test exception sealed class exhaustive matching
- [x] Test exceptions inherit from A2uiException
- [x] Test exceptions implement Exception interface

### Integration Tests (test/integration/) ✅

#### end_to_end_test.dart ✅
- [x] Test schema to ClaudeTools conversion
- [x] Test tool instructions generation
- [x] Test message parsing flow (begin_rendering, surface_update, data_model_update, delete_surface)
- [x] Test stream handler flow (text deltas, CompleteEvent, ErrorEvent)
- [x] Test StreamParser integration (tool_use blocks, multiple content blocks, reset)
- [x] Test validation flow (valid input, missing required field)
- [x] Test rate limiter integration
- [x] Test error recovery flow (stream errors, RetryPolicy)

#### Tool to A2UI roundtrip tests ✅
- [x] begin_rendering toJson/fromJson roundtrip
- [x] surface_update toJson/fromJson roundtrip
- [x] data_model_update toJson/fromJson roundtrip
- [x] delete_surface toJson/fromJson roundtrip
- [x] Widget tree integration tests
- [x] Widget node copyWith and toJson/fromJson roundtrip

### Performance Tests (test/performance/) ✅

- [x] Benchmark tool conversion (10, 100, 1000 tools)
- [x] Benchmark message parsing (various sizes)
- [x] Benchmark stream event processing
- [x] Memory usage profiling
- [x] Verify performance targets from spec

### Test Utilities (test/helpers/) ✅

#### test_utils.dart ✅
- [x] Create isBeginRenderingData matcher
- [x] Create isSurfaceUpdateData matcher
- [x] Create isDataModelUpdateData matcher
- [x] Create isDeleteSurfaceData matcher
- [x] Create isTextDeltaEvent matcher
- [x] Create isErrorEvent matcher
- [x] Create isA2uiMessageEvent matcher
- [x] Create JSON comparison helpers (jsonEquals, jsonEqualTo)
- [x] Create async test helpers (collectStream, expectStreamEmits, streamFromEvents)
- [x] Create widget node helpers (textWidget, buttonWidget, containerWidget)

## Files

```
test/
├── models/
│   ├── a2ui_message_test.dart
│   ├── widget_node_test.dart
│   ├── tool_schema_test.dart
│   ├── stream_event_test.dart
│   └── parse_result_test.dart
├── converter/
│   ├── tool_converter_test.dart
│   └── schema_mapper_test.dart
├── parser/
│   ├── message_parser_test.dart
│   ├── stream_parser_test.dart
│   └── block_handlers_test.dart
├── stream/
│   ├── stream_handler_test.dart
│   ├── retry_policy_test.dart
│   └── rate_limiter_test.dart
├── exceptions/
│   └── exceptions_test.dart
├── integration/
│   └── end_to_end_test.dart
├── performance/
│   └── benchmarks_test.dart
├── fixtures/
│   ├── mock_responses.dart
│   ├── mock_clients.dart
│   └── mock_clients.mocks.dart (generated)
└── helpers/
    └── test_utils.dart
```

## Coverage Requirements

| Component | Min Coverage | Target |
|-----------|--------------|--------|
| lib/src/models/ | 95% | 100% |
| lib/src/converter/ | 90% | 95% |
| lib/src/parser/ | 90% | 95% |
| lib/src/stream/ | 85% | 90% |
| lib/src/exceptions/ | 95% | 100% |
| lib/src/utils/ | 90% | 95% |
| **Overall Package** | **90%** | **95%** |

## Notes

### Testing Principles

1. **Isolation**: Each unit test focuses on a single class/method
2. **Mocking**: Use mockito for external dependencies
3. **Coverage**: Aim for behavior coverage, not just line coverage
4. **Edge Cases**: Test error paths and boundary conditions
5. **Async**: Properly handle async/stream tests with completion

### Mock Strategy

```dart
// Example mock setup
@GenerateMocks([AnthropicClient])
void main() {
  late MockAnthropicClient mockClient;
  late ClaudeStreamHandler handler;

  setUp(() {
    mockClient = MockAnthropicClient();
    handler = ClaudeStreamHandler(mockClient);
  });

  test('processes streaming response', () async {
    when(mockClient.messages.stream(any))
        .thenAnswer((_) => Stream.fromIterable(mockEvents));

    final events = await handler.streamRequest(...).toList();

    expect(events, hasLength(3));
    expect(events.first, isA<A2uiMessageEvent>());
  });
}
```

### Performance Testing Notes

- Use `benchmark_harness` for micro-benchmarks
- Run performance tests separately from unit tests
- Compare against spec targets:
  - Tool conversion: < 1ms for 10 tools
  - Message parsing: < 5ms typical response
  - Stream processing: < 0.1ms per event

### CI Integration

- Run tests on every PR
- Generate coverage report
- Fail build if coverage drops below 90%
- Run performance benchmarks weekly

## Commands

```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib

# Run specific test file
dart test test/converter/tool_converter_test.dart

# Run tests matching pattern
dart test --name "parseToolUse"

# Generate mocks
dart run build_runner build
```

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
| 2025-12-14 | Status: IN_PROGRESS. 37 tests passing. Models, converter, parser, and stream basics covered. Mock setup and integration tests pending. |
| 2025-12-14 | Status: IN_PROGRESS. 55 tests passing. Added toClaudeTools tests (4), parseToolUse tests for data_model_update/delete_surface (3), parseMessage tests (4), exception tests (6). All unit tests for converter, parser, and exceptions complete. |
| 2025-12-14 | Status: IN_PROGRESS. 80 tests passing. Added SchemaMapper tests (10), BlockHandlers tests (9), StreamParser tests (5). All unit tests for models, converter, parser, and stream components complete. Mock fixtures and integration tests pending. |
| 2025-12-14 | Status: IN_PROGRESS. 98 tests passing. Added StreamParser tests (3), RateLimiter tests (7), ClaudeStreamHandler tests (9). All unit tests for stream components complete. Mock fixtures and integration tests pending. |
| 2025-12-14 | Status: IN_PROGRESS. 124 tests passing. Added mock fixtures (mock_responses.dart), test utilities (test_utils.dart), and integration tests (end_to_end_test.dart with 26 tests). Performance tests pending. |
| 2025-12-14 | Status: COMPLETE. 146 tests passing. Added performance benchmarks (benchmarks_test.dart with 22 tests). All spec performance targets verified: tool conversion <1ms for 10 tools, message parsing <5ms, stream processing <0.1ms per event. |
| 2025-12-14 | Marked mock client tasks as N/A - package architecture decoupled from SDK, using raw JSON maps for testability. All deferred tasks resolved. |
| 2025-12-14 | **ADDED MOCKTAIL MOCKS**: Created mock_clients.dart with MockHttpClient, MockStreamHandler, stubStreamResponse, stubErrorStream, stubDelayedStream, and MockEventSequences. Industry standard mocktail replaces mockito. |
