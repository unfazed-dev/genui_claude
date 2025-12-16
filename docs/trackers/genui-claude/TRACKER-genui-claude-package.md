# TRACKER: genui_claude Package Implementation

## Status: COMPLETED

## Overview

Flutter ContentGenerator implementation that enables Claude AI models to power the Flutter GenUI SDK. This package serves as the bridge between Claude's reasoning capabilities and GenUI's dynamic widget rendering system, leveraging a2ui_claude for protocol conversion.

**Specification Document:** [docs/genui_claude_spec.md](../genui_claude_spec.md)

## Tasks

### Phase 1: Package Infrastructure ✅
- [x] Update pubspec.yaml with required dependencies:
  - [x] genui: ^0.5.1
  - [x] a2ui_claude: ^1.0.0 (path dependency for monorepo)
  - [x] anthropic_sdk_dart: ^0.3.0
  - [x] http: ^1.2.0
- [x] Update dev dependencies:
  - [x] flutter_test (sdk)
  - [x] integration_test (sdk)
  - [x] mockito: ^5.4.0
  - [x] build_runner: ^2.4.0
- [x] Update environment constraints (sdk: ^3.5.0, flutter: >=3.22.0)
- [x] Create package directory structure per spec

### Phase 2: Configuration Classes ✅
- [x] Create ClaudeConfig (lib/src/config/claude_config.dart)
  - [x] maxTokens property (default 4096)
  - [x] timeout property (default 60s)
  - [x] retryAttempts property (default 3)
  - [x] enableStreaming property (default true)
  - [x] headers property (optional)
  - [x] defaults constant
  - [x] copyWith method
- [x] Create ProxyConfig (lib/src/config/claude_config.dart)
  - [x] timeout property (default 120s)
  - [x] retryAttempts property (default 3)
  - [x] headers property (optional)
  - [x] includeHistory property (default true)
  - [x] maxHistoryMessages property (default 20)
  - [x] defaults constant
  - [x] copyWith method

### Phase 3: Content Generator Core ✅
- [x] Create ClaudeContentGenerator implementing ContentGenerator
  - [x] Default factory constructor (direct API mode)
  - [x] .proxy() factory constructor (backend proxy mode)
  - [x] a2uiMessageStream getter (StreamController.broadcast)
  - [x] textResponseStream getter (StreamController.broadcast)
  - [x] errorStream getter (StreamController.broadcast)
  - [x] isProcessing getter (ValueNotifier<bool>)
  - [x] sendRequest() method
  - [x] dispose() method
- [x] Implement DirectModeHandler (lib/src/handler/direct_mode_handler.dart)
- [x] Implement ProxyModeHandler (lib/src/handler/proxy_mode_handler.dart)
- [x] Stream controller management
- [x] ClaudeStreamHandler integration from a2ui_claude

### Phase 4: Adapters and Bridges ✅
- [x] Create A2uiMessageAdapter (lib/src/adapter/message_adapter.dart)
  - [x] toGenUiMessage() static method
  - [x] _toComponent() helper (WidgetNode → Component)
  - [x] Handle all A2uiMessageData types:
    - [x] BeginRenderingData → BeginRendering
    - [x] SurfaceUpdateData → SurfaceUpdate
    - [x] DataModelUpdateData → DataModelUpdate
    - [x] DeleteSurfaceData → SurfaceDeletion
  - [x] toGenUiMessages() batch conversion
- [x] Create CatalogToolBridge (lib/src/adapter/tool_bridge.dart)
  - [x] fromCatalog() static method
  - [x] fromItems() static method
  - [x] withA2uiTools() static method
  - [x] A2uiControlTools definitions (lib/src/adapter/a2ui_control_tools.dart)

### Phase 5: Utility Classes ✅
- [x] Create MessageConverter (lib/src/utils/message_converter.dart)
  - [x] Convert GenUI Message to Claude Message
  - [x] Handle conversation history
  - [x] Pruning logic for max messages

### Phase 6: Public API ✅
- [x] Update lib/genui_claude.dart exports
- [x] Export all public types (adapter, config, content_generator)
- [x] Add library-level documentation with examples

### Phase 7: Testing ✅
- [x] Unit tests for ClaudeContentGenerator (basic tests)
- [x] Unit tests for A2uiMessageAdapter
- [x] Unit tests for CatalogToolBridge
- [x] Unit tests for configuration classes (ClaudeConfig, ProxyConfig)
- [x] Widget tests for chat integration (test/widget/content_generator_widget_test.dart)
- [x] Integration tests for full Claude → GenUI flow (test/integration/)
- [x] Create mock generators (test/mocks/mock_generators.dart)
- **Current: 153 tests passing (0 skipped with API key)**
- Run with API key: `flutter test --dart-define=TEST_CLAUDE_API_KEY=your-key`

### Phase 8: Examples ✅
- [x] Create example/lib/main.dart (basic example)
- [x] Create example/lib/catalog/demo_catalog.dart
- [x] Create example/lib/screens/basic_chat.dart
- [x] Create example/lib/screens/production_chat.dart
- [x] Example pubspec.yaml

### Phase 9: Documentation ✅
- [x] Update package README.md
- [x] Add inline API documentation
- [x] Create CHANGELOG.md entry
- [x] Supabase Edge Function template (TypeScript)

## Files

### Package Root
- `packages/genui_claude/pubspec.yaml` - Package configuration
- `packages/genui_claude/lib/genui_claude.dart` - Public exports
- `packages/genui_claude/analysis_options.yaml` - Linting rules
- `packages/genui_claude/README.md` - Package documentation
- `packages/genui_claude/CHANGELOG.md` - Version changelog

### Source Files
- `lib/src/content_generator/claude_content_generator.dart` - Main class
- `lib/src/handler/api_handler.dart` - Handler interface and ApiRequest
- `lib/src/handler/direct_mode_handler.dart` - Direct API handler using anthropic_sdk_dart
- `lib/src/handler/proxy_mode_handler.dart` - Proxy handler with HTTP streaming
- `lib/src/adapter/message_adapter.dart` - A2UI message bridging
- `lib/src/adapter/tool_bridge.dart` - Catalog to tools conversion
- `lib/src/adapter/a2ui_control_tools.dart` - A2UI control tool definitions
- `lib/src/config/claude_config.dart` - Direct and proxy mode configs
- `lib/src/utils/message_converter.dart` - GenUI Message conversion

### Test Files
- `test/genui_claude_test.dart` - Main package tests
- `test/adapter/message_adapter_test.dart`
- `test/adapter/tool_bridge_test.dart`
- `test/adapter/a2ui_control_tools_test.dart`
- `test/handler/direct_mode_handler_test.dart`
- `test/handler/proxy_mode_handler_test.dart`
- `test/handler/mock_api_handler.dart` - Mock handler for testing
- `test/widget/content_generator_widget_test.dart` - Widget tests
- `test/integration/claude_flow_test.dart` - Direct mode integration
- `test/integration/proxy_flow_test.dart` - Proxy mode integration
- `test/integration/helpers/mock_proxy_server.dart` - Mock HTTP server
- `test/integration/helpers/integration_test_utils.dart`
- `test/utils/message_converter_test.dart`
- `test/helpers/test_utils.dart` - Test utilities
- `test/mocks/mock_generators.dart`

### Example Files
- `example/pubspec.yaml`
- `example/lib/main.dart`
- `example/lib/catalog/demo_catalog.dart`
- `example/lib/screens/basic_chat.dart`
- `example/lib/screens/production_chat.dart`
- `example/supabase/functions/claude-genui/index.ts`

## Dependencies

### External
- genui: ^0.5.1 (GenUI SDK - ContentGenerator interface)

### Internal (monorepo)
- a2ui_claude: path dependency (protocol conversion)

## Notes

### Architecture Decisions

1. **Thin Adapter Layer**: This package wraps a2ui_claude functionality with minimal additional code
2. **Two Operation Modes**:
   - Direct Mode: Development/prototyping with API key in app
   - Proxy Mode: Production with backend Edge Function
3. **Stream Architecture**: Three concurrent broadcast streams (a2ui, text, error)
4. **Flutter Lifecycle**: Proper dispose patterns for stream controllers

### Current State
- Package fully implemented with all functionality
- 153 tests passing (0 skipped with API key)
- DirectModeHandler using anthropic_sdk_dart for direct API access
- ProxyModeHandler with real HTTP streaming implementation
- Widget tests for UI integration patterns
- Integration tests for full Claude → GenUI flow (verified with real API)
- Complete example app with basic and production chat screens
- Comprehensive README documentation
- Supabase Edge Function template for production deployments

### Relationship to a2ui_claude

| Concern | a2ui_claude | genui_claude |
|---------|----------------|-----------------|
| Tool schema conversion | Implements | Uses |
| Message parsing | Implements | Uses |
| Stream handling | Implements | Uses |
| ContentGenerator interface | — | Implements |
| GenUI type bridging | — | Implements |
| Flutter lifecycle | — | Manages |

### Performance Targets

| Operation | Direct Mode | Proxy Mode |
|-----------|-------------|------------|
| Tool schema conversion | < 1ms | < 1ms |
| Network round-trip | 50-150ms | 80-200ms |
| Claude processing (TTFT) | 200-800ms | 200-800ms |
| Stream event processing | < 0.5ms | < 0.5ms |
| Widget render (GenUI) | 16-50ms | 16-50ms |

## Related Trackers

- [TRACKER-a2ui-claude-package.md](../a2ui-claude/TRACKER-a2ui-claude-package.md) - Prerequisite package
- [TRACKER-genui-content-generator.md](TRACKER-genui-content-generator.md) - Core component details
- [TRACKER-genui-adapters.md](TRACKER-genui-adapters.md) - Adapter implementation
- [TRACKER-genui-claude-testing.md](TRACKER-genui-claude-testing.md) - Test implementation

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec document |
| 2025-12-14 | Completed all core implementation phases |
| 2025-12-14 | Added A2uiMessageAdapter tests (20 tests) |
| 2025-12-14 | Created mock generators |
| 2025-12-14 | Created example app with demo catalog |
| 2025-12-14 | Created README.md documentation |
| 2025-12-14 | Created CHANGELOG.md |
| 2025-12-14 | Created Supabase Edge Function template |
| 2025-12-14 | Marked tracker as COMPLETED (73 tests passing) |
| 2025-12-14 | Updated tracker: all deferred items now complete (147 tests passing) |
| 2025-12-14 | Verified with real API key: 153 tests passing, 0 skipped |
