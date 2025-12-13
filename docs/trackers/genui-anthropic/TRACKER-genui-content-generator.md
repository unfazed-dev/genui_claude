# TRACKER: GenUI Content Generator Implementation

## Status: PLANNING

## Overview

Implementation of AnthropicContentGenerator, the core class that implements GenUI's ContentGenerator interface. Supports both direct API access (development) and backend proxy mode (production).

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### Configuration Classes (lib/src/config/)

#### AnthropicConfig (anthropic_config.dart)
- [ ] Create AnthropicConfig class
- [ ] Properties:
  - [ ] maxTokens (int, default 4096)
  - [ ] timeout (Duration, default 60s)
  - [ ] retryAttempts (int, default 3)
  - [ ] enableStreaming (bool, default true)
  - [ ] headers (Map<String, String>?, optional)
- [ ] Const constructor
- [ ] copyWith method
- [ ] Default instance constant

#### ProxyConfig (proxy_config.dart)
- [ ] Create ProxyConfig class
- [ ] Properties:
  - [ ] timeout (Duration, default 120s)
  - [ ] retryAttempts (int, default 3)
  - [ ] headers (Map<String, String>?, optional)
  - [ ] includeHistory (bool, default true)
  - [ ] maxHistoryMessages (int, default 20)
- [ ] Const constructor
- [ ] copyWith method
- [ ] Default instance constant

### AnthropicContentGenerator (lib/src/content_generator/)

#### Main Class (anthropic_content_generator.dart)
- [ ] Implement ContentGenerator interface
- [ ] Private constructor with required dependencies
- [ ] Create default factory constructor for direct mode:
  ```dart
  factory AnthropicContentGenerator({
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    String? systemInstruction,
    required List<Tool> tools,
    AnthropicConfig? config,
  })
  ```
- [ ] Create .proxy() factory for backend mode:
  ```dart
  factory AnthropicContentGenerator.proxy({
    required Uri endpoint,
    String? authToken,
    required List<Tool> tools,
    ProxyConfig? config,
  })
  ```
- [ ] Create .withHandler() factory for testing

#### Stream Controllers
- [ ] _a2uiController (StreamController<A2uiMessage>.broadcast())
- [ ] _textController (StreamController<String>.broadcast())
- [ ] _errorController (StreamController<Object>.broadcast())

#### ContentGenerator Interface Implementation
- [ ] a2uiMessageStream getter -> _a2uiController.stream
- [ ] textResponseStream getter -> _textController.stream
- [ ] errorStream getter -> _errorController.stream
- [ ] tools getter
- [ ] sendRequest(List<Message> conversationHistory) method

#### sendRequest Implementation
- [ ] Convert GenUI messages to Claude format
- [ ] Call handler.streamRequest()
- [ ] Process StreamEvent types:
  - [ ] A2uiMessageEvent -> convert and emit to _a2uiController
  - [ ] TextDeltaEvent -> emit to _textController
  - [ ] ErrorEvent -> emit to _errorController
  - [ ] CompleteEvent -> no action
- [ ] Wrap in try-catch, emit errors to _errorController

#### Resource Management
- [ ] dispose() method
- [ ] Close all stream controllers
- [ ] Clean up handler resources

### Direct Mode Handler (direct_mode.dart)

- [ ] Create DirectModeHandler class
- [ ] Constructor with:
  - [ ] apiKey (String)
  - [ ] model (String)
  - [ ] systemInstruction (String?)
  - [ ] config (AnthropicConfig)
- [ ] Initialize AnthropicClient from anthropic_sdk_dart
- [ ] Initialize ClaudeStreamHandler from anthropic_a2ui
- [ ] Implement streamRequest() method
- [ ] Connection management

### Proxy Mode Handler (proxy_mode.dart)

- [ ] Create ProxyModeHandler class
- [ ] Constructor with:
  - [ ] endpoint (Uri)
  - [ ] authToken (String?)
  - [ ] config (ProxyConfig)
- [ ] Initialize HTTP client
- [ ] Build request headers (auth + custom)
- [ ] Implement streamRequest() method:
  - [ ] POST to endpoint with JSON body
  - [ ] Parse SSE stream response
  - [ ] Convert to StreamEvent
- [ ] Handle conversation history pruning
- [ ] Connection management

### Handler Interface (handler.dart)

- [ ] Create abstract RequestHandler class or interface
- [ ] Define streamRequest() method signature
- [ ] Used by both DirectModeHandler and ProxyModeHandler

## Files

### Config
- `lib/src/config/anthropic_config.dart`
- `lib/src/config/proxy_config.dart`
- `lib/src/config/config.dart` (barrel export)

### Content Generator
- `lib/src/content_generator/anthropic_content_generator.dart`
- `lib/src/content_generator/direct_mode.dart`
- `lib/src/content_generator/proxy_mode.dart`
- `lib/src/content_generator/handler.dart`
- `lib/src/content_generator/content_generator.dart` (barrel export)

## Dependencies

- genui: ^0.5.1 (ContentGenerator, A2uiMessage, Tool, Message types)
- anthropic_a2ui (ClaudeStreamHandler, StreamEvent, A2uiMessageData)
- anthropic_sdk_dart (AnthropicClient for direct mode)
- http (HTTP client for proxy mode)

## Notes

### ContentGenerator Interface

From GenUI SDK, ContentGenerator requires:
```dart
abstract class ContentGenerator {
  Stream<A2uiMessage> get a2uiMessageStream;
  Stream<String> get textResponseStream;
  Stream<Object> get errorStream;
  Future<void> sendRequest(List<Message> conversationHistory);
  List<Tool> get tools;
}
```

### Stream Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   AnthropicContentGenerator                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              DirectModeHandler / ProxyModeHandler          │  │
│  │                    ClaudeStreamHandler                     │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │                                     │
│            ┌───────────────┼───────────────┐                     │
│            │               │               │                     │
│   ┌────────▼────────┐ ┌────▼─────┐ ┌───────▼───────┐            │
│   │ _a2uiController │ │ _text    │ │ _error        │            │
│   │ <A2uiMessage>   │ │ <String> │ │ <Object>      │            │
│   └────────┬────────┘ └────┬─────┘ └───────┬───────┘            │
│            │               │               │                     │
└────────────┼───────────────┼───────────────┼─────────────────────┘
             ▼               ▼               ▼
        a2uiMessageStream  textResponse   errorStream
        (to GenUI)         Stream         (to UI)
```

### Error Handling Strategy

| Error Type | Action |
|------------|--------|
| Network timeout | Retry with backoff, then emit |
| Auth failure | Emit immediately, no retry |
| Rate limit (429) | Queue with delay |
| Parse error | Log, skip, continue |
| Validation error | Emit with details |

### Direct vs Proxy Mode

| Aspect | Direct Mode | Proxy Mode |
|--------|-------------|------------|
| API Key | In app (insecure) | In backend |
| Use Case | Development | Production |
| Latency | Lower | Higher (+proxy hop) |
| Context | None | Can enrich with DB |
| Auth | API key | User token |

### Testing Considerations

- Use .withHandler() factory to inject mock handlers
- Mock ClaudeStreamHandler for unit tests
- Integration tests with real API (CI only)

## Test Coverage Requirements

| Component | Min Coverage |
|-----------|--------------|
| AnthropicContentGenerator | 90% |
| DirectModeHandler | 85% |
| ProxyModeHandler | 85% |
| Config classes | 95% |

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
