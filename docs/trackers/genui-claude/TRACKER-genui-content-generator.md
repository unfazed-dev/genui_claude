# TRACKER: GenUI Content Generator Implementation

## Status: COMPLETE

## Overview

Implementation of ClaudeContentGenerator, the core class that implements GenUI's ContentGenerator interface. Supports both direct API access (development) and backend proxy mode (production).

**Parent Tracker:** [TRACKER-genui-claude-package.md](./TRACKER-genui-claude-package.md)

## Tasks

### Configuration Classes (lib/src/config/) ✅

#### ClaudeConfig (claude_config.dart) ✅
- [x] Create ClaudeConfig class
- [x] Properties:
  - [x] maxTokens (int, default 4096)
  - [x] timeout (Duration, default 60s)
  - [x] retryAttempts (int, default 3)
  - [x] enableStreaming (bool, default true)
  - [x] headers (Map<String, String>?, optional)
- [x] Const constructor
- [x] copyWith method
- [x] Default instance constant

#### ProxyConfig (claude_config.dart) ✅
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

### ClaudeContentGenerator (lib/src/content_generator/) ✅

#### Main Class (claude_content_generator.dart) ✅
- [x] Implement ContentGenerator interface
- [x] Create default constructor for direct mode:
  ```dart
  ClaudeContentGenerator({
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    String? systemInstruction,
    ClaudeConfig? config,
  })
  ```
- [x] Create .proxy() factory for backend mode:
  ```dart
  ClaudeContentGenerator.proxy({
    required Uri proxyEndpoint,
    String? authToken,
    ProxyConfig? config,
  })
  ```
- [x] Create .withHandler() factory for testing

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

### Handler Interface (lib/src/handler/api_handler.dart) ✅

- [x] Create ApiRequest class with:
  - [x] messages (List<Map<String, dynamic>>)
  - [x] maxTokens (int)
  - [x] systemInstruction (String?)
  - [x] tools (List<Map<String, dynamic>>?)
  - [x] model (String?)
  - [x] temperature (double?)
- [x] Create abstract ApiHandler class with:
  - [x] createStream(ApiRequest) -> Stream<Map<String, dynamic>>
  - [x] dispose() method

### Direct Mode Handler (lib/src/handler/direct_mode_handler.dart) ✅

- [x] Create DirectModeHandler class implementing ApiHandler
- [x] Constructor with:
  - [x] apiKey (String)
  - [x] model (String, default 'claude-sonnet-4-20250514')
  - [x] config (ClaudeConfig)
- [x] Initialize AnthropicClient from anthropic_sdk_dart
- [x] Implement createStream() method:
  - [x] Convert ApiRequest to CreateMessageRequest
  - [x] Convert messages to SDK Message format
  - [x] Convert tools to SDK Tool format
  - [x] Stream SDK events via createMessageStream()
  - [x] Convert MessageStreamEvent to Map format
- [x] Handle errors and emit error events

### Proxy Mode Handler (lib/src/handler/proxy_mode_handler.dart) ✅

- [x] Create ProxyModeHandler class implementing ApiHandler
- [x] Constructor with:
  - [x] endpoint (Uri)
  - [x] authToken (String?)
  - [x] config (ProxyConfig)
  - [x] client (http.Client?, optional for testing)
- [x] Build request headers (auth + custom)
- [x] Implement createStream() method:
  - [x] POST to endpoint with JSON body
  - [x] Parse SSE stream response
  - [x] Yield Map events directly
- [x] Handle HTTP errors
- [x] Resource cleanup in dispose()

### Testing Support ✅

- [x] MockApiHandler class in test/handler/mock_api_handler.dart
- [x] MockEventFactory for common event sequences
- [x] stubEvents(), stubTextResponse(), stubError() methods

## Files

### Config ✅
- `lib/src/config/claude_config.dart` ✅ (contains both ClaudeConfig and ProxyConfig)

### Content Generator ✅
- `lib/src/content_generator/claude_content_generator.dart` ✅

### Handler ✅
- `lib/src/handler/api_handler.dart` ✅ (ApiRequest, ApiHandler interface)
- `lib/src/handler/direct_mode_handler.dart` ✅ (DirectModeHandler)
- `lib/src/handler/proxy_mode_handler.dart` ✅ (ProxyModeHandler)
- `lib/src/handler/handler.dart` ✅ (barrel export)

### Testing ✅
- `test/handler/mock_api_handler.dart` ✅ (MockApiHandler, MockEventFactory)

## Dependencies

- genui: ^0.5.1 (ContentGenerator, A2uiMessage, Tool, Message types)
- a2ui_claude (ClaudeStreamHandler, StreamEvent, A2uiMessageData)
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
│                   ClaudeContentGenerator                      │
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
| ClaudeContentGenerator | 90% |
| DirectModeHandler | 85% |
| ProxyModeHandler | 85% |
| Config classes | 95% |

## History

| Date | Action |
|------|--------|
| 2025-12-13 | Created tracker from spec |
| 2025-12-14 | Updated status: Configuration classes and main ClaudeContentGenerator complete. Handler classes deferred. |
| 2025-12-14 | Implemented handler architecture: ApiHandler interface, DirectModeHandler (anthropic_sdk_dart), ProxyModeHandler (HTTP/SSE), integrated into ClaudeContentGenerator, added MockApiHandler for testing. All tasks complete. |
