# TRACKER: GenUI Anthropic Testing Implementation

## Status: COMPLETE

## Overview

Comprehensive testing strategy for the genui_anthropic package including unit tests, widget tests, integration tests, and example app. Target: 90%+ overall code coverage.

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### Test Infrastructure Setup ✅

- [x] Configure test dependencies in pubspec.yaml
  - [x] flutter_test (sdk)
  - [x] integration_test (sdk)
  - [x] mockito: ^5.4.0
  - [x] build_runner: ^2.4.0
- [x] Create test directory structure
- [x] Set up mock generation with @GenerateMocks
- [x] Create test utilities and helpers

**Current: 161 tests passing** (149 unit/widget + 12 integration)

### Mock Setup (test/mocks/) ✅

#### Mock Generators (mock_generators.dart) ✅
- [x] Create MockClaudeStreamHandler
- [x] Create MockAnthropicContentGenerator
- [x] Create MockToolFactory
- [x] Create MockCatalogItemFactory
- [x] Create stub helper methods

#### Stub Data ✅
- [x] Create stub StreamEvent sequences (MockStreamEventFactory)
- [x] Create stub A2uiMessage sequences (MockA2uiMessageFactory)
- [x] Create stub Tool definitions (MockToolFactory)
- [x] Create stub CatalogItem definitions (MockCatalogItemFactory)
- [x] Create stub conversation histories (MockChatMessageFactory)

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

### Widget Tests (test/widget/) ✅

#### content_generator_widget_test.dart ✅ (12 tests)
- [x] Test isProcessing ValueListenable renders correctly when not processing
- [x] Test isProcessing updates when processing state changes
- [x] Test shows loading indicator while processing
- [x] Test receives text responses from stream
- [x] Test receives A2UI messages from stream
- [x] Test receives errors from stream
- [x] Test isProcessing lifecycle can be simulated
- [x] Test direct emit triggers stream listeners
- [x] Test error banner appears on error event
- [x] Test error banner can be dismissed
- [x] Test generator can be disposed without error
- [x] Test widget unmounts cleanly after dispose

### Integration Tests (test/integration/) ✅

#### claude_flow_test.dart ✅ (6 tests)
- [x] Test full Claude → GenUI flow with real API
- [x] Test tool selection and execution
- [x] Test streaming UI rendering
- [x] Test conversation continuity
- [x] Test error recovery
- [x] Test multiple sequential messages

#### proxy_flow_test.dart ✅ (6 tests)
- [x] Test proxy mode with mock server endpoint
- [x] Test auth token handling
- [x] Test history pruning
- [x] Test handles server errors gracefully
- [x] Test handles unauthorized errors
- [x] Test streams multiple text chunks

### Example App (example/) ✅

#### Structure ✅
- [x] Create example/pubspec.yaml
- [x] Create example/lib/main.dart
- [x] Create example/lib/catalog/demo_catalog.dart
- [x] Create example/lib/screens/basic_chat.dart
- [x] Create example/lib/screens/production_chat.dart

#### Demo Catalog ✅
- [x] text_display widget
- [x] info_card widget
- [x] action_button widget
- [x] item_list widget
- [x] progress_indicator widget
- [x] input_field widget
- [x] image_display widget
- [x] divider widget
- [x] spacer widget
- [x] container widget

#### Basic Chat Screen ✅
- [x] Direct mode example
- [x] Environment variable API key
- [x] Simple chat interface
- [x] Error handling

#### Production Chat Screen ✅
- [x] Proxy mode example
- [x] Supabase integration pattern
- [x] Auth token handling
- [x] History management

### Test Utilities (test/helpers/) ✅

#### test_utils.dart ✅
- [x] Create isBeginRendering custom matcher
- [x] Create isSurfaceUpdate custom matcher
- [x] Create isDataModelUpdate custom matcher
- [x] Create isSurfaceDeletion custom matcher
- [x] Create collectStream async stream helper
- [x] Create waitForItems stream helper
- [x] Create waitForFirst stream helper
- [x] Create ConversationBuilder helper
- [x] Create testComponent helper
- [x] Create testComponents helper
- [x] Create expectStreamEmits assertion helper
- [x] Create expectStreamContains assertion helper

## Files

### Current Structure ✅
```
test/
├── genui_anthropic_test.dart              ✅ (17 tests)
├── handler/
│   ├── direct_mode_handler_test.dart      ✅ (24 tests)
│   ├── proxy_mode_handler_test.dart       ✅ (25 tests)
│   ├── proxy_mode_handler_test.mocks.dart (generated)
│   └── mock_api_handler.dart              ✅
├── adapter/
│   ├── message_adapter_test.dart          ✅ (14 tests)
│   ├── catalog_tool_bridge_test.dart      ✅ (10 tests)
│   └── a2ui_control_tools_test.dart       ✅ (8 tests)
├── utils/
│   └── message_converter_test.dart        ✅ (15 tests)
├── widget/
│   └── content_generator_widget_test.dart ✅ (12 tests)
├── helpers/
│   └── test_utils.dart                    ✅
└── mocks/
    └── mock_generators.dart               ✅ (extended)

example/
├── lib/
│   ├── main.dart                          ✅
│   ├── catalog/
│   │   └── demo_catalog.dart              ✅
│   └── screens/
│       ├── basic_chat.dart                ✅
│       └── production_chat.dart           ✅
├── pubspec.yaml                           ✅
└── README.md                              ✅
```

### Integration Tests ✅
```
test/integration/
├── helpers/
│   ├── api_key_config.dart             ✅
│   ├── integration_test_utils.dart     ✅
│   └── mock_proxy_server.dart          ✅
├── claude_flow_test.dart               ✅ (6 tests - real API)
└── proxy_flow_test.dart                ✅ (6 tests - mock server)
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
| 2025-12-14 | Major update: **149 tests passing**. Added MockClaudeStreamHandler, MockToolFactory, MockCatalogItemFactory to mock_generators.dart. Created test_utils.dart with custom matchers (isBeginRendering, isSurfaceUpdate, etc.), stream helpers, and ConversationBuilder. Added 12 widget tests for ContentGenerator integration. Example app already complete. |
| 2025-12-14 | **COMPLETE: 161 tests passing**. Added integration tests: claude_flow_test.dart (6 tests with real Claude API) and proxy_flow_test.dart (6 tests with mock HTTP server). Fixed bug in anthropic_a2ui ClaudeStreamHandler that was iterating stream twice. Tests now in test/integration/ folder with helper utilities for API key config, test utilities, and mock proxy server. |
