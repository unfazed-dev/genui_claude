# API Patterns

Detailed patterns for using the genui_anthropic API, including handler customization, stream processing, and message conversion.

## AnthropicContentGenerator Patterns

### Constructor Selection

```dart
// Development: Direct API access
final generator = AnthropicContentGenerator(
  apiKey: 'sk-ant-...',
  model: 'claude-sonnet-4-20250514',
  systemInstruction: 'You are a UI assistant.',
  config: AnthropicConfig(maxTokens: 4096),
);

// Production: Backend proxy
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://api.example.com/claude'),
  authToken: userJwtToken,
  proxyConfig: ProxyConfig(timeout: Duration(seconds: 120)),
);

// Testing: Mock handler
final generator = AnthropicContentGenerator.withHandler(
  handler: mockHandler,
  model: 'claude-sonnet-4-20250514',
  systemInstruction: 'Test instruction',
);
```

### Full Integration Pattern

```dart
class GenUiChatController {
  late final AnthropicContentGenerator _generator;
  late final GenUiConversation _conversation;

  final _messages = <ChatMessage>[];
  final _surfaces = <String, Widget>{};

  StreamSubscription? _a2uiSub;
  StreamSubscription? _textSub;
  StreamSubscription? _errorSub;

  void initialize({
    required String apiKey,
    required Catalog catalog,
  }) {
    _generator = AnthropicContentGenerator(
      apiKey: apiKey,
      systemInstruction: _buildSystemPrompt(catalog),
    );

    final manager = GenUiManager(catalog: catalog);

    _conversation = GenUiConversation(
      contentGenerator: _generator,
      genUiManager: manager,
      onSurfaceAdded: _handleSurfaceAdded,
      onSurfaceRemoved: _handleSurfaceRemoved,
      onTextResponse: _handleTextResponse,
      onError: _handleError,
    );

    // Optional: Direct stream access for custom handling
    _a2uiSub = _generator.a2uiMessageStream.listen(_handleA2uiMessage);
    _textSub = _generator.textResponseStream.listen(_handleTextDelta);
    _errorSub = _generator.errorStream.listen(_handleStreamError);
  }

  String _buildSystemPrompt(Catalog catalog) {
    final widgetNames = catalog.items.map((i) => i.name).join(', ');
    return '''
You are a helpful UI assistant.
Available widgets: $widgetNames

When the user's request can be fulfilled with UI:
1. Call begin_rendering with a unique surfaceId
2. Call surface_update with the widget tree
3. Optionally add text explanation

Prefer generating UI over plain text descriptions.
''';
  }

  void dispose() {
    _a2uiSub?.cancel();
    _textSub?.cancel();
    _errorSub?.cancel();
    _generator.dispose();
    _conversation.dispose();
  }
}
```

## Handler Architecture

### ApiHandler Interface

```dart
abstract class ApiHandler {
  /// Creates a streaming response from Claude
  /// Emits Claude SSE event maps
  Stream<Map<String, dynamic>> createStream(ApiRequest request);

  /// Cleanup resources
  void dispose();
}
```

### ApiRequest Structure

```dart
class ApiRequest {
  final List<Map<String, dynamic>> messages;  // Claude API format
  final int maxTokens;
  final String? systemInstruction;
  final List<Map<String, dynamic>>? tools;
  final String? model;
  final double? temperature;
}
```

### Custom Handler Implementation

```dart
class CustomApiHandler implements ApiHandler {
  final http.Client _client;
  final Uri _endpoint;

  CustomApiHandler({
    required Uri endpoint,
    http.Client? client,
  }) : _endpoint = endpoint,
       _client = client ?? http.Client();

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    final response = await _client.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      },
      body: jsonEncode({
        'messages': request.messages,
        'max_tokens': request.maxTokens,
        'system': request.systemInstruction,
        'tools': request.tools,
        'stream': true,
      }),
    );

    if (response.statusCode != 200) {
      yield {'type': 'error', 'error': {'message': response.body}};
      return;
    }

    // Parse SSE stream
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') break;
        yield jsonDecode(data) as Map<String, dynamic>;
      }
    }
  }

  @override
  void dispose() => _client.close();
}
```

## Stream Processing

### Claude SSE Event Types

```dart
// Content block start (text or tool_use)
{'type': 'content_block_start', 'index': 0, 'content_block': {
  'type': 'text',
  'text': ''
}}

// Text delta
{'type': 'content_block_delta', 'index': 0, 'delta': {
  'type': 'text_delta',
  'text': 'Hello'
}}

// Tool use start
{'type': 'content_block_start', 'index': 1, 'content_block': {
  'type': 'tool_use',
  'id': 'toolu_123',
  'name': 'begin_rendering',
  'input': {}
}}

// Tool input delta (JSON chunks)
{'type': 'content_block_delta', 'index': 1, 'delta': {
  'type': 'input_json_delta',
  'partial_json': '{"surfaceId":'
}}

// Content block stop
{'type': 'content_block_stop', 'index': 1}

// Message complete
{'type': 'message_stop'}

// Error
{'type': 'error', 'error': {'type': 'api_error', 'message': '...'}}
```

### Stream Handler Processing

The `ClaudeStreamHandler` (from anthropic_a2ui) processes raw events:

```dart
// Internal processing flow
Stream<StreamEvent> streamRequest({
  required Stream<Map<String, dynamic>> messageStream,
}) async* {
  String toolInputBuffer = '';
  A2uiToolCall? currentTool;

  await for (final event in messageStream) {
    switch (event['type']) {
      case 'content_block_delta':
        final delta = event['delta'];
        if (delta['type'] == 'text_delta') {
          yield TextDeltaEvent(delta['text']);
        } else if (delta['type'] == 'input_json_delta') {
          toolInputBuffer += delta['partial_json'];
        }

      case 'content_block_stop':
        if (currentTool != null && toolInputBuffer.isNotEmpty) {
          final input = jsonDecode(toolInputBuffer);
          final message = _parseA2uiMessage(currentTool.name, input);
          if (message != null) {
            yield A2uiMessageEvent(message);
          }
          toolInputBuffer = '';
        }

      case 'message_stop':
        yield CompleteEvent();

      case 'error':
        yield ErrorEvent(Exception(event['error']['message']));
    }
  }
}
```

## Message Conversion

### GenUI to Claude Format

```dart
// MessageConverter transforms GenUI messages to Claude API format

// User text message
UserMessage.text('Hello') → {
  'role': 'user',
  'content': [{'type': 'text', 'text': 'Hello'}]
}

// AI text response
AiTextMessage.text('Hi there') → {
  'role': 'assistant',
  'content': [{'type': 'text', 'text': 'Hi there'}]
}

// AI UI response (tool use)
AiUiMessage(surfaceId: 'abc', widgets: [...]) → {
  'role': 'assistant',
  'content': [{
    'type': 'tool_use',
    'id': 'toolu_abc',
    'name': 'surface_update',
    'input': {'surfaceId': 'abc', 'widgets': [...]}
  }]
}

// Tool result
ToolResponseMessage(callId: 'toolu_abc', result: {...}) → {
  'role': 'user',
  'content': [{
    'type': 'tool_result',
    'tool_use_id': 'toolu_abc',
    'content': '{"status": "rendered"}'
  }]
}
```

### History Pruning

```dart
// Limit history to prevent token overflow
final pruned = MessageConverter.pruneHistory(
  messages,
  maxMessages: 20,
);

// Pruning preserves:
// - User-assistant message pairs
// - Most recent messages
// - Proper conversation structure
```

## Error Handling Patterns

### ContentGeneratorError

```dart
_generator.errorStream.listen((error) {
  final exception = error.error;
  final stackTrace = error.stackTrace;

  if (exception is ApiException) {
    // Handle API errors (rate limit, invalid key, etc.)
    handleApiError(exception);
  } else if (exception is TimeoutException) {
    // Handle timeout
    showTimeoutMessage();
  } else {
    // Generic error
    logError(exception, stackTrace);
  }
});
```

### Concurrent Request Prevention

```dart
Future<void> sendMessage(String text) async {
  // Check if already processing
  if (_generator.isProcessing.value) {
    showSnackBar('Please wait for current request to complete');
    return;
  }

  await _conversation.sendRequest(UserMessage.text(text));
}
```

### Retry Pattern

```dart
Future<void> sendWithRetry(ChatMessage message, {int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      await _conversation.sendRequest(message);
      return;
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries) rethrow;
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
}
```

## Testing Patterns

### Mock Handler for Tests

```dart
class MockApiHandler implements ApiHandler {
  final _eventQueue = <Map<String, dynamic>>[];
  final _requestLog = <ApiRequest>[];

  void stubEvents(List<Map<String, dynamic>> events) {
    _eventQueue.addAll(events);
  }

  List<ApiRequest> get requests => List.unmodifiable(_requestLog);

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    _requestLog.add(request);
    for (final event in _eventQueue) {
      await Future.delayed(Duration(milliseconds: 10));
      yield event;
    }
    _eventQueue.clear();
  }

  @override
  void dispose() {}
}

// Usage in test
test('sends message and receives UI', () async {
  final handler = MockApiHandler();
  handler.stubEvents([
    {'type': 'content_block_start', 'index': 0, 'content_block': {
      'type': 'tool_use', 'name': 'begin_rendering', 'id': 'tool_1', 'input': {}
    }},
    {'type': 'content_block_delta', 'index': 0, 'delta': {
      'type': 'input_json_delta', 'partial_json': '{"surfaceId":"test"}'
    }},
    {'type': 'content_block_stop', 'index': 0},
    {'type': 'message_stop'},
  ]);

  final generator = AnthropicContentGenerator.withHandler(handler: handler);
  final messages = <A2uiMessage>[];
  generator.a2uiMessageStream.listen(messages.add);

  await generator.sendRequest(UserMessage.text('Create a card'));
  await Future.delayed(Duration(milliseconds: 100));

  expect(messages, hasLength(1));
  expect(messages.first, isA<BeginRendering>());
});
```

### Stream Collector Utility

```dart
Future<List<T>> collectStream<T>(
  Stream<T> stream, {
  Duration timeout = const Duration(seconds: 5),
  int? maxItems,
}) async {
  final items = <T>[];
  final completer = Completer<List<T>>();

  final sub = stream.listen(
    (item) {
      items.add(item);
      if (maxItems != null && items.length >= maxItems) {
        completer.complete(items);
      }
    },
    onDone: () => completer.complete(items),
    onError: (e) => completer.completeError(e),
  );

  try {
    return await completer.future.timeout(timeout);
  } finally {
    await sub.cancel();
  }
}
```
