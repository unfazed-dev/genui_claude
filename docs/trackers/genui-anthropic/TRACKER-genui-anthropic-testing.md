# TRACKER: GenUI Anthropic Testing Implementation

## Status: IN_PROGRESS

## Overview

Comprehensive testing strategy for the genui_anthropic package including unit tests, widget tests, integration tests, and example app. Target: 90%+ overall code coverage.

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### Test Infrastructure Setup (Partial)

- [x] Configure test dependencies in pubspec.yaml
  - [x] flutter_test (sdk)
  - [ ] integration_test (sdk) - not yet added
  - [x] mockito: ^5.4.0
  - [x] build_runner: ^2.4.0
- [x] Create test directory structure
- [ ] Set up mock generation with @GenerateMocks
- [ ] Create test utilities and helpers

**Current: 10 tests passing**

### Mock Setup (test/mocks/)

#### Mock Generators (mock_generators.dart)
- [ ] Create MockClaudeStreamHandler
- [ ] Create MockAnthropicClient
- [ ] Create MockAnthropicContentGenerator
- [ ] Create MockGenUiManager
- [ ] Create stub helper methods

#### Stub Data
- [ ] Create stub StreamEvent sequences
- [ ] Create stub A2uiMessage sequences
- [ ] Create stub Tool definitions
- [ ] Create stub CatalogItem definitions
- [ ] Create stub conversation histories

### Unit Tests - Content Generator (test/genui_anthropic_test.dart) (Partial)

#### anthropic_content_generator_test.dart ✅
- [x] Test default constructor creates with required parameters
- [x] Test default constructor creates with custom model and config
- [x] Test .proxy() constructor creates with required parameters
- [x] Test .proxy() constructor creates with auth token and config
- [x] Test implements ContentGenerator interface
- [x] Test isProcessing starts as false
- [x] Test stream getters return correct types
- [ ] Test a2uiMessageStream emits A2uiMessages
- [ ] Test textResponseStream emits text chunks
- [ ] Test errorStream emits errors
- [ ] Test sendRequest processes all event types
- [ ] Test sendRequest handles exceptions
- [ ] Test dispose() closes all controllers

#### direct_mode_test.dart
- [ ] Test DirectModeHandler initialization
- [ ] Test API key is passed to client
- [ ] Test model parameter is used
- [ ] Test systemInstruction is included
- [ ] Test config options are applied
- [ ] Test streamRequest delegates to ClaudeStreamHandler
- [ ] Test custom headers are sent

#### proxy_mode_test.dart
- [ ] Test ProxyModeHandler initialization
- [ ] Test endpoint is used correctly
- [ ] Test auth token is included in headers
- [ ] Test custom headers are merged
- [ ] Test request body includes messages
- [ ] Test request body includes tools
- [ ] Test history pruning respects maxHistoryMessages
- [ ] Test SSE stream parsing
- [ ] Test timeout handling

### Unit Tests - Adapters (test/adapter/)

#### message_adapter_test.dart
- [ ] Test toGenUiMessage with BeginRenderingData
  - [ ] All fields present
  - [ ] Only required fields
- [ ] Test toGenUiMessage with SurfaceUpdateData
  - [ ] Single widget
  - [ ] Multiple widgets
  - [ ] Nested widgets
  - [ ] append flag variations
- [ ] Test toGenUiMessage with DataModelUpdateData
  - [ ] Primitive values
  - [ ] Object values
  - [ ] Array values
  - [ ] With scope
- [ ] Test toGenUiMessage with DeleteSurfaceData
  - [ ] cascade true
  - [ ] cascade false
- [ ] Test _toGenUiWidget
  - [ ] Flat widget
  - [ ] Widget with children
  - [ ] Widget with dataBinding
  - [ ] Deeply nested (5+ levels)
  - [ ] Null children handled

#### tool_bridge_test.dart
- [ ] Test fromCatalog extracts tools from manager
- [ ] Test fromItems maps CatalogItem list
- [ ] Test tool name mapping
- [ ] Test tool description mapping
- [ ] Test inputSchema conversion:
  - [ ] String properties
  - [ ] Number properties
  - [ ] Boolean properties
  - [ ] Array properties
  - [ ] Nested object properties
  - [ ] Required fields
- [ ] Test withA2uiTools prepends control tools
- [ ] Test A2uiControlTools.all contains 4 tools
- [ ] Test begin_rendering tool schema
- [ ] Test surface_update tool schema
- [ ] Test data_model_update tool schema
- [ ] Test delete_surface tool schema

### Unit Tests - Config (test/genui_anthropic_test.dart) ✅

#### AnthropicConfig tests ✅
- [x] Test has default values
- [x] Test copyWith creates modified copy

#### ProxyConfig tests ✅
- [x] Test has default values
- [x] Test copyWith creates modified copy

### Unit Tests - Utils (test/utils/)

#### message_converter_test.dart
- [ ] Test toClaudeMessages with user message
- [ ] Test toClaudeMessages with assistant message
- [ ] Test toClaudeMessages with conversation
- [ ] Test pruneHistory with fewer than max
- [ ] Test pruneHistory with more than max
- [ ] Test pruneHistory preserves pairs

### Widget Tests (test/widget/)

#### chat_integration_test.dart
- [ ] Test ChatScreen renders with mock generator
- [ ] Test message input triggers sendRequest
- [ ] Test A2uiMessages render to GenUiSurface
- [ ] Test text responses display in chat
- [ ] Test error banner shows on error
- [ ] Test dispose is called on unmount

#### Error UI Tests
- [ ] Test error banner appears on network error
- [ ] Test retry button triggers retry
- [ ] Test dismiss clears error

### Integration Tests (integration_test/)

#### claude_flow_test.dart
- [ ] Test full Claude → GenUI flow with real API
- [ ] Test tool selection and execution
- [ ] Test streaming UI rendering
- [ ] Test conversation continuity
- [ ] Test error recovery
- [ ] Test multiple sequential messages

#### proxy_flow_test.dart (if proxy available)
- [ ] Test proxy mode with test endpoint
- [ ] Test auth token handling
- [ ] Test history pruning

### Example App (example/)

#### Structure
- [ ] Create example/pubspec.yaml
- [ ] Create example/lib/main.dart
- [ ] Create example/lib/catalog/demo_catalog.dart
- [ ] Create example/lib/screens/basic_chat.dart
- [ ] Create example/lib/screens/production_chat.dart

#### Demo Catalog
- [ ] user_card widget
- [ ] task_form widget
- [ ] search_results widget
- [ ] analytics_chart widget

#### Basic Chat Screen
- [ ] Direct mode example
- [ ] Environment variable API key
- [ ] Simple chat interface
- [ ] Error handling

#### Production Chat Screen
- [ ] Proxy mode example
- [ ] Supabase integration
- [ ] Auth token refresh
- [ ] History management

### Test Utilities (test/helpers/)

#### test_utils.dart
- [ ] Create expectA2uiMessage matcher
- [ ] Create expectStreamEvent matcher
- [ ] Create async stream test helpers
- [ ] Create conversation builder helper

## Files

```
test/
├── content_generator/
│   ├── anthropic_content_generator_test.dart
│   ├── direct_mode_test.dart
│   └── proxy_mode_test.dart
├── adapter/
│   ├── message_adapter_test.dart
│   └── tool_bridge_test.dart
├── config/
│   ├── anthropic_config_test.dart
│   └── proxy_config_test.dart
├── utils/
│   └── message_converter_test.dart
├── widget/
│   └── chat_integration_test.dart
├── mocks/
│   ├── mock_generators.dart
│   └── mock_generators.mocks.dart (generated)
└── helpers/
    └── test_utils.dart

integration_test/
├── claude_flow_test.dart
└── proxy_flow_test.dart

example/
├── lib/
│   ├── main.dart
│   ├── catalog/
│   │   └── demo_catalog.dart
│   └── screens/
│       ├── basic_chat.dart
│       └── production_chat.dart
├── pubspec.yaml
└── README.md
```

## Coverage Requirements

| Component | Min Coverage | Target |
|-----------|--------------|--------|
| AnthropicContentGenerator | 90% | 95% |
| DirectModeHandler | 85% | 90% |
| ProxyModeHandler | 85% | 90% |
| A2uiMessageAdapter | 95% | 100% |
| CatalogToolBridge | 90% | 95% |
| Config classes | 95% | 100% |
| MessageConverter | 90% | 95% |
| **Overall Package** | **90%** | **95%** |

## Notes

### Testing Patterns

#### Mocking the Stream Handler
```dart
@GenerateMocks([ClaudeStreamHandler])
void main() {
  late MockClaudeStreamHandler mockHandler;
  late AnthropicContentGenerator generator;

  setUp(() {
    mockHandler = MockClaudeStreamHandler();
    generator = AnthropicContentGenerator.withHandler(
      handler: mockHandler,
      tools: testTools,
    );
  });

  test('emits A2uiMessages from tool_use responses', () async {
    when(mockHandler.streamRequest(any)).thenAnswer(
      (_) => Stream.fromIterable([
        A2uiMessageEvent(BeginRenderingData(surfaceId: 'main')),
        CompleteEvent(),
      ]),
    );

    final messages = <A2uiMessage>[];
    generator.a2uiMessageStream.listen(messages.add);

    await generator.sendRequest([Message.user('Hello')]);

    expect(messages, hasLength(1));
    expect(messages.first, isA<BeginRendering>());
  });
}
```

#### Widget Test Pattern
```dart
testWidgets('ChatScreen renders generated UI', (tester) async {
  final mockGenerator = MockAnthropicContentGenerator();

  // Stub the streams
  when(mockGenerator.a2uiMessageStream).thenAnswer(
    (_) => Stream.fromIterable([
      A2uiMessage.beginRendering(surfaceId: 'main'),
      A2uiMessage.surfaceUpdate(
        surfaceId: 'main',
        widgets: [GenUiWidget(type: 'text', properties: {'text': 'Hi'})],
      ),
    ]),
  );
  when(mockGenerator.textResponseStream).thenAnswer(
    (_) => Stream.empty(),
  );
  when(mockGenerator.errorStream).thenAnswer(
    (_) => Stream.empty(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(contentGenerator: mockGenerator),
    ),
  );

  await tester.enterText(find.byType(TextField), 'Generate UI');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();

  expect(find.text('Hi'), findsOneWidget);
});
```

### Integration Test Environment

- Use `TEST_ANTHROPIC_API_KEY` environment variable
- Skip integration tests if key not available
- Run integration tests in CI with secret
- Set reasonable timeouts (30-60s for Claude responses)

### Example App Notes

- Example should work out of the box with environment variable
- Include clear setup instructions in example README
- Demonstrate both direct and proxy modes
- Show error handling patterns

## Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific test file
flutter test test/content_generator/anthropic_content_generator_test.dart

# Run integration tests (requires API key)
flutter test integration_test/

# Generate mocks
dart run build_runner build

# Run example app
cd example && flutter run
```

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
| 2025-12-14 | Updated status: 10 tests passing (7 AnthropicContentGenerator, 2 AnthropicConfig, 2 ProxyConfig). Mock setup and advanced tests pending. |
