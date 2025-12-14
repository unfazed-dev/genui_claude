# TRACKER: GenUI Anthropic Testing Implementation

## Status: IN_PROGRESS

## Overview

Comprehensive testing strategy for the genui_anthropic package including unit tests, widget tests, integration tests, and example app. Target: 90%+ overall code coverage.

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### Test Infrastructure Setup ✅

- [x] Configure test dependencies in pubspec.yaml
  - [x] flutter_test (sdk)
  - [ ] integration_test (sdk) - not yet added
  - [x] mockito: ^5.4.0
  - [x] build_runner: ^2.4.0
- [x] Create test directory structure
- [x] Set up mock generation with @GenerateMocks
- [ ] Create test utilities and helpers

**Current: 125+ tests passing**

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

### Unit Tests - Content Generator ✅

#### anthropic_content_generator_test.dart ✅ (17 tests)
- [x] Test default constructor creates with required parameters
- [x] Test default constructor creates with custom model and config
- [x] Test .proxy() constructor creates with required parameters
- [x] Test .proxy() constructor creates with auth token and config
- [x] Test implements ContentGenerator interface
- [x] Test isProcessing starts as false
- [x] Test stream getters return correct types (broadcast streams)
- [x] Test isProcessing is a ValueListenable
- [x] Test sendRequest handles exceptions gracefully
- [x] Test dispose() disposes handler
- [x] Test dispose() closes all resources

#### direct_mode_handler_test.dart ✅ (24 tests)
- [x] Test DirectModeHandler constructor with required parameters
- [x] Test DirectModeHandler constructor with custom model
- [x] Test DirectModeHandler constructor with custom config
- [x] Test dispose without error
- [x] Test SDK event format expectations (8 event types)
- [x] Test message format validation (user, assistant, tool_use, tool_result)
- [x] Test tool format validation
- [x] Test media type parsing (jpeg, png, gif, webp, unknown)

#### proxy_mode_handler_test.dart ✅ (25 tests)
- [x] Test ProxyModeHandler constructor with required parameters
- [x] Test ProxyModeHandler constructor with auth token
- [x] Test ProxyModeHandler constructor with custom config
- [x] Test sends POST request to endpoint
- [x] Test includes correct headers without auth token
- [x] Test includes Authorization header with auth token
- [x] Test includes custom headers from config
- [x] Test request body includes messages and max_tokens
- [x] Test request body includes system instruction when provided
- [x] Test request body includes tools when provided
- [x] Test request body includes model when provided
- [x] Test request body includes temperature when provided
- [x] Test request body excludes null optional fields
- [x] Test SSE parsing - valid data events
- [x] Test SSE parsing - skips empty lines
- [x] Test SSE parsing - skips [DONE] marker
- [x] Test SSE parsing - handles malformed JSON with error event
- [x] Test SSE parsing - ignores non-data lines
- [x] Test error handling - HTTP 400, 401, 500
- [x] Test error handling - timeout
- [x] Test error handling - network exception
- [x] Test dispose - closes owned client
- [x] Test dispose - does not close provided client

### Unit Tests - Adapters (test/adapter/) ✅

#### message_adapter_test.dart ✅ (14 tests - pre-existing)
- [x] Test toGenUiMessage with BeginRenderingData (all fields, required only)
- [x] Test toGenUiMessage with SurfaceUpdateData (single, multiple, empty widgets)
- [x] Test toGenUiMessage with DataModelUpdateData (with/without scope)
- [x] Test toGenUiMessage with DeleteSurfaceData
- [x] Test toGenUiMessages batch conversion
- [x] Test widget properties (strings, numbers, booleans, lists, nested, nulls)

#### catalog_tool_bridge_test.dart ✅ (10 tests - pre-existing)
- [x] Test fromItems converts empty list
- [x] Test fromItems converts single CatalogItem to A2uiToolSchema
- [x] Test fromItems extracts inputSchema from CatalogItem dataSchema
- [x] Test fromItems extracts required fields from schema
- [x] Test fromItems converts multiple CatalogItems
- [x] Test fromItems handles nested object schemas
- [x] Test fromCatalog extracts tools from Catalog
- [x] Test fromCatalog handles empty catalog
- [x] Test withA2uiTools prepends A2UI control tools
- [x] Test withA2uiTools includes all A2UI control tools

#### a2ui_control_tools_test.dart ✅ (8 tests - pre-existing)
- [x] Test A2uiControlTools.all contains 4 tools
- [x] Test begin_rendering tool schema
- [x] Test surface_update tool schema
- [x] Test data_model_update tool schema
- [x] Test delete_surface tool schema

### Unit Tests - Config (test/genui_anthropic_test.dart) ✅

#### AnthropicConfig tests ✅
- [x] Test has default values
- [x] Test copyWith creates modified copy

#### ProxyConfig tests ✅
- [x] Test has default values
- [x] Test copyWith creates modified copy

### Unit Tests - Utils (test/utils/) ✅

#### message_converter_test.dart ✅ (15 tests - pre-existing)
- [x] Test toClaudeMessages converts empty list
- [x] Test toClaudeMessages converts UserMessage to user role
- [x] Test toClaudeMessages converts AiTextMessage to assistant role
- [x] Test toClaudeMessages converts conversation with multiple turns
- [x] Test toClaudeMessages handles UserMessage with multiple TextParts
- [x] Test toClaudeMessages handles ToolCallPart in AiTextMessage
- [x] Test toClaudeMessages handles ToolResponseMessage
- [x] Test toClaudeMessages skips InternalMessage by default
- [x] Test pruneHistory returns all messages when under limit
- [x] Test pruneHistory keeps most recent messages when over limit
- [x] Test pruneHistory preserves user-assistant pair boundaries
- [x] Test pruneHistory handles single message
- [x] Test pruneHistory returns empty for empty input
- [x] Test extractSystemContext extracts InternalMessage as system context
- [x] Test extractSystemContext combines multiple InternalMessages
- [x] Test extractSystemContext returns null when no InternalMessage

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

### Current Structure ✅
```
test/
├── genui_anthropic_test.dart           ✅ (17 tests)
├── handler/
│   ├── direct_mode_handler_test.dart   ✅ (24 tests)
│   ├── proxy_mode_handler_test.dart    ✅ (25 tests)
│   ├── proxy_mode_handler_test.mocks.dart (generated)
│   └── mock_api_handler.dart           ✅
├── adapter/
│   ├── message_adapter_test.dart       ✅ (14 tests)
│   ├── catalog_tool_bridge_test.dart   ✅ (10 tests)
│   └── a2ui_control_tools_test.dart    ✅ (8 tests)
├── utils/
│   └── message_converter_test.dart     ✅ (15 tests)
└── mocks/
    └── mock_generators.dart            ✅
```

### Planned (Not Yet Created)
```
test/
├── widget/
│   └── chat_integration_test.dart      ⏳
└── helpers/
    └── test_utils.dart                 ⏳

integration_test/
├── claude_flow_test.dart               ⏳
└── proxy_flow_test.dart                ⏳

example/
├── lib/
│   ├── main.dart                       ⏳
│   ├── catalog/
│   │   └── demo_catalog.dart           ⏳
│   └── screens/
│       ├── basic_chat.dart             ⏳
│       └── production_chat.dart        ⏳
├── pubspec.yaml                        ⏳
└── README.md                           ⏳
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
| 2025-12-14 | Major update: **125+ tests passing**. Added ProxyModeHandler tests (25), DirectModeHandler tests (24), extended ContentGenerator sendRequest tests (17). Handler layer now fully tested. |
