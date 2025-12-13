# TRACKER: genui_anthropic Package Implementation

## Status: PLANNING

## Overview

Flutter ContentGenerator implementation that enables Anthropic's Claude AI models to power the Flutter GenUI SDK. This package serves as the bridge between Claude's reasoning capabilities and GenUI's dynamic widget rendering system, leveraging anthropic_a2ui for protocol conversion.

**Specification Document:** [docs/genui_anthropic_spec.md](../genui_anthropic_spec.md)

## Tasks

### Phase 1: Package Infrastructure
- [ ] Update pubspec.yaml with required dependencies:
  - [ ] genui: ^0.5.1
  - [ ] anthropic_a2ui: ^1.0.0 (path dependency for monorepo)
  - [ ] anthropic_sdk_dart: ^0.9.0
  - [ ] http: ^1.1.0
- [ ] Update dev dependencies:
  - [ ] flutter_test (sdk)
  - [ ] integration_test (sdk)
  - [ ] mockito: ^5.4.0
  - [ ] build_runner: ^2.4.0
- [ ] Update environment constraints (sdk: >=3.0.0, flutter: >=3.35.0)
- [ ] Create package directory structure per spec

### Phase 2: Configuration Classes
- [ ] Create AnthropicConfig (lib/src/config/)
  - [ ] maxTokens property
  - [ ] timeout property
  - [ ] retryAttempts property
  - [ ] enableStreaming property
  - [ ] headers property
- [ ] Create ProxyConfig (lib/src/config/)
  - [ ] timeout property
  - [ ] retryAttempts property
  - [ ] headers property
  - [ ] includeHistory property
  - [ ] maxHistoryMessages property

### Phase 3: Content Generator Core
- [ ] Create AnthropicContentGenerator implementing ContentGenerator
  - [ ] Default factory constructor (direct API mode)
  - [ ] .proxy() factory constructor (backend proxy mode)
  - [ ] a2uiMessageStream getter
  - [ ] textResponseStream getter
  - [ ] errorStream getter
  - [ ] sendRequest() method
  - [ ] tools getter
  - [ ] dispose() method
- [ ] Implement DirectModeHandler (lib/src/content_generator/)
- [ ] Implement ProxyModeHandler (lib/src/content_generator/)
- [ ] Stream controller management

### Phase 4: Adapters and Bridges
- [ ] Create A2uiMessageAdapter (lib/src/adapter/)
  - [ ] toGenUiMessage() static method
  - [ ] _toGenUiWidget() helper
  - [ ] Handle all A2uiMessageData types
- [ ] Create CatalogToolBridge (lib/src/adapter/)
  - [ ] fromCatalog() static method
  - [ ] fromItems() static method
  - [ ] withA2uiTools() static method
  - [ ] A2uiControlTools definitions

### Phase 5: Utility Classes
- [ ] Create MessageConverter (lib/src/utils/)
  - [ ] Convert GenUI Message to Claude Message
  - [ ] Handle conversation history
  - [ ] Pruning logic for max messages

### Phase 6: Public API
- [ ] Update lib/genui_anthropic.dart exports
- [ ] Export all public types
- [ ] Add library-level documentation

### Phase 7: Testing
- [ ] Unit tests for AnthropicContentGenerator
- [ ] Unit tests for A2uiMessageAdapter
- [ ] Unit tests for CatalogToolBridge
- [ ] Unit tests for configuration classes
- [ ] Widget tests for chat integration
- [ ] Integration tests for full Claude → GenUI flow
- [ ] Create mock generators
- [ ] Achieve 90%+ code coverage

### Phase 8: Examples
- [ ] Create example/lib/main.dart (basic example)
- [ ] Create example/lib/catalog/demo_catalog.dart
- [ ] Create example/lib/screens/basic_chat.dart
- [ ] Create example/lib/screens/production_chat.dart
- [ ] Example pubspec.yaml

### Phase 9: Documentation
- [ ] Update package README.md
- [ ] Add inline API documentation
- [ ] Create CHANGELOG.md entry
- [ ] Supabase Edge Function template (TypeScript)

## Files

### Package Root
- `packages/genui_anthropic/pubspec.yaml` - Package configuration (needs update)
- `packages/genui_anthropic/lib/genui_anthropic.dart` - Public exports
- `packages/genui_anthropic/analysis_options.yaml` - Linting rules

### Source Files (to create)
- `lib/src/content_generator/anthropic_content_generator.dart` - Main class
- `lib/src/content_generator/direct_mode.dart` - Direct API implementation
- `lib/src/content_generator/proxy_mode.dart` - Backend proxy implementation
- `lib/src/adapter/message_adapter.dart` - A2UI message bridging
- `lib/src/adapter/tool_bridge.dart` - Catalog to tools conversion
- `lib/src/config/anthropic_config.dart` - Direct mode config
- `lib/src/config/proxy_config.dart` - Proxy mode config
- `lib/src/utils/message_converter.dart` - GenUI Message conversion

### Test Files (to create)
- `test/content_generator/anthropic_content_generator_test.dart`
- `test/content_generator/direct_mode_test.dart`
- `test/content_generator/proxy_mode_test.dart`
- `test/adapter/message_adapter_test.dart`
- `test/adapter/tool_bridge_test.dart`
- `test/widget/chat_integration_test.dart`
- `test/mocks/mock_generators.dart`
- `integration_test/claude_flow_test.dart`

### Example Files (to create)
- `example/lib/main.dart`
- `example/lib/catalog/demo_catalog.dart`
- `example/lib/screens/basic_chat.dart`
- `example/lib/screens/production_chat.dart`
- `example/pubspec.yaml`

## Dependencies

### External
- genui: ^0.5.1 (GenUI SDK - ContentGenerator interface)
- anthropic_sdk_dart: ^0.9.0 (Claude API client)
- http: ^1.1.0 (HTTP client for proxy mode)

### Internal (monorepo)
- anthropic_a2ui: ^1.0.0 (protocol conversion - must be implemented first)

## Notes

### Architecture Decisions

1. **Thin Adapter Layer**: This package wraps anthropic_a2ui functionality with minimal additional code
2. **Two Operation Modes**:
   - Direct Mode: Development/prototyping with API key in app
   - Proxy Mode: Production with backend Edge Function
3. **Stream Architecture**: Three concurrent broadcast streams (a2ui, text, error)
4. **Flutter Lifecycle**: Proper dispose patterns for stream controllers

### Current State
- Package exists as placeholder
- Already has path dependency on anthropic_a2ui
- No actual ContentGenerator implementation

### Key Considerations
- Depends on anthropic_a2ui being implemented first
- Must comply with GenUI's ContentGenerator interface
- Production deployments should use proxy mode (never embed API keys)
- Progressive UI rendering through streaming

### Relationship to anthropic_a2ui

| Concern | anthropic_a2ui | genui_anthropic |
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

- [TRACKER-anthropic-a2ui-package.md](../anthropic-a2ui/TRACKER-anthropic-a2ui-package.md) - Prerequisite package
- [TRACKER-genui-content-generator.md](TRACKER-genui-content-generator.md) - Core component details
- [TRACKER-genui-adapters.md](TRACKER-genui-adapters.md) - Adapter implementation
- [TRACKER-genui-anthropic-testing.md](TRACKER-genui-anthropic-testing.md) - Test implementation

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec document |
