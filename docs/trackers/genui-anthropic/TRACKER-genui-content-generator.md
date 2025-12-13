# TRACKER: GenUI Content Generator Implementation

## Status: IN_PROGRESS

## Overview

Implementation of AnthropicContentGenerator, the core class that implements GenUI's ContentGenerator interface. Supports both direct API access (development) and backend proxy mode (production).

**Parent Tracker:** [TRACKER-genui-anthropic-package.md](./TRACKER-genui-anthropic-package.md)

## Tasks

### Configuration Classes (lib/src/config/) ✅

#### AnthropicConfig (anthropic_config.dart) ✅
- [x] Create AnthropicConfig class
- [x] Properties:
  - [x] maxTokens (int, default 4096)
  - [x] timeout (Duration, default 60s)
  - [x] retryAttempts (int, default 3)
  - [x] enableStreaming (bool, default true)
  - [x] headers (Map<String, String>?, optional)
- [x] Const constructor
- [x] copyWith method
- [x] Default instance constant

#### ProxyConfig (anthropic_config.dart) ✅
- [x] Create ProxyConfig class
- [x] Properties:
  - [x] timeout (Duration, default 120s)
  - [x] retryAttempts (int, default 3)
  - [x] headers (Map<String, String>?, optional)
  - [x] includeHistory (bool, default true)
  - [x] maxHistoryMessages (int, default 20)
- [x] Const constructor
- [x] copyWith method
- [x] Default instance constant

### AnthropicContentGenerator (lib/src/content_generator/) ✅

#### Main Class (anthropic_content_generator.dart) ✅
- [x] Implement ContentGenerator interface
- [x] Create default constructor for direct mode:
  ```dart
  AnthropicContentGenerator({
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    String? systemInstruction,
    AnthropicConfig? config,
  })
  ```
- [x] Create .proxy() factory for backend mode:
  ```dart
  AnthropicContentGenerator.proxy({
    required Uri proxyEndpoint,
    String? authToken,
    ProxyConfig? config,
  })
  ```
- [ ] Create .withHandler() factory for testing (deferred)

#### Stream Controllers ✅
- [x] _a2uiController (StreamController<A2uiMessage>.broadcast())
- [x] _textController (StreamController<String>.broadcast())
- [x] _errorController (StreamController<ContentGeneratorError>.broadcast())
- [x] _isProcessing (ValueNotifier<bool>)

#### ContentGenerator Interface Implementation ✅
- [x] a2uiMessageStream getter -> _a2uiController.stream
- [x] textResponseStream getter -> _textController.stream
- [x] errorStream getter -> _errorController.stream
- [x] isProcessing getter -> _isProcessing
- [x] sendRequest(ChatMessage, {history}) method

#### sendRequest Implementation ✅
- [x] Extract text from ChatMessage
- [x] Call _streamHandler.streamRequest()
- [x] Process StreamEvent types:
  - [x] A2uiMessageEvent -> convert via A2uiMessageAdapter and emit
  - [x] TextDeltaEvent -> emit to _textController
  - [x] ErrorEvent -> emit to _errorController
  - [x] DeltaEvent -> ignored
  - [x] CompleteEvent -> no action
- [x] Wrap in try-catch, emit errors to _errorController
- [x] Set isProcessing flag during request

#### Resource Management ✅
- [x] dispose() method
- [x] Close all stream controllers
- [x] Dispose ValueNotifier
- [x] Dispose ClaudeStreamHandler

### Direct Mode Handler (direct_mode.dart) - DEFERRED

> Currently using mock stream in AnthropicContentGenerator. Will implement when anthropic_sdk_dart integration is added.

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

### Proxy Mode Handler (proxy_mode.dart) - DEFERRED

> Currently using mock stream in AnthropicContentGenerator. Will implement when HTTP integration is added.

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

### Handler Interface (handler.dart) - DEFERRED

- [ ] Create abstract RequestHandler class or interface
- [ ] Define streamRequest() method signature
- [ ] Used by both DirectModeHandler and ProxyModeHandler

## Files

### Config ✅
- `lib/src/config/anthropic_config.dart` ✅ (contains both AnthropicConfig and ProxyConfig)

### Content Generator (Partial)
- `lib/src/content_generator/anthropic_content_generator.dart` ✅
- `lib/src/content_generator/direct_mode.dart` (not yet created)
- `lib/src/content_generator/proxy_mode.dart` (not yet created)
- `lib/src/content_generator/handler.dart` (not yet created)

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
| 2025-12-14 | Updated status: Configuration classes and main AnthropicContentGenerator complete. Handler classes deferred. |
