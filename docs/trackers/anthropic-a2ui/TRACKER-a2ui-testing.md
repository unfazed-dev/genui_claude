# TRACKER: A2UI Testing Implementation

## Status: PLANNING

## Overview

Comprehensive testing strategy for the anthropic_a2ui package including unit tests, integration tests, mock fixtures, and coverage requirements. Target: 90%+ overall code coverage.

**Parent Tracker:** [TRACKER-anthropic-a2ui-package.md](./TRACKER-anthropic-a2ui-package.md)

## Tasks

### Test Infrastructure Setup

- [ ] Configure test dependencies in pubspec.yaml
  - [ ] test: ^1.24.0
  - [ ] mockito: ^5.4.0
  - [ ] build_runner: ^2.4.0 (for mockito generation)
  - [ ] coverage: ^1.6.0
- [ ] Create test directory structure matching lib/src
- [ ] Create test utilities and helpers
- [ ] Set up mock generation with @GenerateMocks

### Mock Fixtures (test/fixtures/)

#### Mock Responses (mock_responses.dart)
- [ ] Create mock MessageStreamEvent sequences
- [ ] Create mock tool_use ToolUseBlock samples:
  - [ ] begin_rendering mock
  - [ ] surface_update mock (simple)
  - [ ] surface_update mock (nested widgets)
  - [ ] data_model_update mock
  - [ ] delete_surface mock
- [ ] Create mock error responses:
  - [ ] 429 rate limit response
  - [ ] 500 server error response
  - [ ] Malformed JSON response
  - [ ] Timeout response

#### Mock Clients (mock_clients.dart)
- [ ] Create MockAnthropicClient using mockito
- [ ] Implement stubStreamResponse helper
- [ ] Implement stubErrorResponse helper
- [ ] Create MockHttpClient for network tests

### Unit Tests - Models (test/models/)

#### a2ui_message_test.dart
- [ ] Test BeginRenderingData
  - [ ] Construction with required fields
  - [ ] Construction with optional fields
  - [ ] fromJson parsing
  - [ ] toJson serialization
  - [ ] Equality comparison
- [ ] Test SurfaceUpdateData
  - [ ] Construction with widgets list
  - [ ] append flag behavior
  - [ ] fromJson with nested WidgetNodes
  - [ ] toJson serialization
- [ ] Test DataModelUpdateData
  - [ ] Various update types (primitives, objects, arrays)
  - [ ] Scope handling
- [ ] Test DeleteSurfaceData
  - [ ] cascade flag defaults
  - [ ] Serialization roundtrip

#### widget_node_test.dart
- [ ] Test flat widget node
- [ ] Test widget with children (1 level)
- [ ] Test deeply nested widgets (5+ levels)
- [ ] Test widget with dataBinding
- [ ] Test fromJson recursive parsing
- [ ] Test toJson recursive serialization
- [ ] Test copyWith method

#### tool_schema_test.dart
- [ ] Test schema construction
- [ ] Test toClaudeTool conversion
- [ ] Test inputSchema variations
- [ ] Test requiredFields handling

### Unit Tests - Converter (test/converter/)

#### tool_converter_test.dart
- [ ] Test toClaudeTools with single schema
- [ ] Test toClaudeTools with multiple schemas
- [ ] Test toClaudeTools with nested object properties
- [ ] Test toClaudeTools with array properties
- [ ] Test generateToolInstructions output format
- [ ] Test validateToolInput - valid input
- [ ] Test validateToolInput - missing required field
- [ ] Test validateToolInput - wrong type
- [ ] Test validateToolInput - unknown tool

#### schema_mapper_test.dart
- [ ] Test primitive type mapping (string, number, boolean, integer)
- [ ] Test array type mapping
- [ ] Test object type mapping
- [ ] Test nested schema mapping
- [ ] Test required field mapping

### Unit Tests - Parser (test/parser/)

#### message_parser_test.dart
- [ ] Test parseToolUse - begin_rendering
- [ ] Test parseToolUse - surface_update
- [ ] Test parseToolUse - data_model_update
- [ ] Test parseToolUse - delete_surface
- [ ] Test parseToolUse - unknown tool returns null
- [ ] Test parseToolUse - malformed input
- [ ] Test parseMessage - single tool_use
- [ ] Test parseMessage - multiple tool_use blocks
- [ ] Test parseMessage - mixed content (tool + text)
- [ ] Test parseMessage - text only
- [ ] Test ParseResult hasToolUse flag

#### stream_parser_test.dart
- [ ] Test parseStream - complete tool_use
- [ ] Test parseStream - streaming deltas
- [ ] Test parseStream - multiple blocks
- [ ] Test parseStream - error mid-stream
- [ ] Test partial JSON accumulation
- [ ] Test stream cancellation cleanup

#### block_handlers_test.dart
- [ ] Test ToolUseBlockHandler delta accumulation
- [ ] Test ToolUseBlockHandler complete parsing
- [ ] Test TextBlockHandler delta accumulation
- [ ] Test BlockHandlerFactory selection

### Unit Tests - Stream (test/stream/)

#### stream_handler_test.dart
- [ ] Test streamRequest - successful flow
- [ ] Test streamRequest - emits correct event types
- [ ] Test streamRequest - handles message_start
- [ ] Test streamRequest - handles content_block events
- [ ] Test streamRequest - handles message_stop
- [ ] Test streamRequest - connection error
- [ ] Test StreamConfig defaults
- [ ] Test custom model parameter

#### retry_policy_test.dart
- [ ] Test shouldRetry - retryable error
- [ ] Test shouldRetry - non-retryable error
- [ ] Test shouldRetry - max attempts exceeded
- [ ] Test getDelay - exponential backoff calculation
- [ ] Test getDelay - respects maxDelay
- [ ] Test retryWithBackoff - success on first try
- [ ] Test retryWithBackoff - success on retry
- [ ] Test retryWithBackoff - exhausted retries

#### rate_limiter_test.dart
- [ ] Test 429 response handling
- [ ] Test Retry-After header parsing
- [ ] Test request queuing
- [ ] Test rate limit reset

### Unit Tests - Exceptions (test/exceptions/)

#### exceptions_test.dart
- [ ] Test A2uiException toString
- [ ] Test ToolConversionException with details
- [ ] Test MessageParseException with raw content
- [ ] Test StreamException with status code
- [ ] Test ValidationException with error list
- [ ] Test exception inheritance/sealed class behavior

### Integration Tests (test/integration/)

#### end_to_end_test.dart
- [ ] Test full flow: schema -> request -> parse -> A2UI messages
- [ ] Test streaming flow with mock client
- [ ] Test error recovery flow
- [ ] Test multiple sequential requests
- [ ] Test concurrent requests

#### Tool to A2UI roundtrip tests
- [ ] Create tools from schemas
- [ ] Mock Claude response with those tools
- [ ] Parse back to A2UI messages
- [ ] Verify data integrity

### Performance Tests (test/performance/)

- [ ] Benchmark tool conversion (10, 100, 1000 tools)
- [ ] Benchmark message parsing (various sizes)
- [ ] Benchmark stream event processing
- [ ] Memory usage profiling
- [ ] Verify performance targets from spec

### Test Utilities (test/helpers/)

#### test_utils.dart
- [ ] Create expectA2uiMessage matcher
- [ ] Create expectStreamEvent matcher
- [ ] Create JSON comparison helpers
- [ ] Create async test helpers

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
