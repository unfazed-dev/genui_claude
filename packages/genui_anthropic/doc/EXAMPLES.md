# Examples

Practical code examples for using the `genui_anthropic` package.

## Table of Contents

- [Basic Chat Application](#basic-chat-application)
- [Production Deployment](#production-deployment)
- [Custom Configuration](#custom-configuration)
- [Building a Widget Catalog](#building-a-widget-catalog)
- [Conversation with History](#conversation-with-history)
- [Streaming Response Handling](#streaming-response-handling)
- [Error Handling](#error-handling)
- [Testing Patterns](#testing-patterns)
- [Troubleshooting](#troubleshooting)

---

## Basic Chat Application

Complete example of a chat screen with Claude-powered generative UI.

### Step 1: Create a Widget Catalog

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class MyCatalog extends Catalog {
  MyCatalog() : super(_items);

  static final List<CatalogItem> _items = [
    CatalogItem(
      name: 'info_card',
      dataSchema: S.object(
        description: 'A card displaying information with title and content',
        properties: {
          'title': S.string(description: 'Card title'),
          'content': S.string(description: 'Card body content'),
          'icon': S.string(description: 'Icon: info, warning, success, error'),
        },
        required: ['title', 'content'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return Card(
          child: ListTile(
            leading: Icon(_getIcon(props['icon'] as String?)),
            title: Text(props['title'] as String? ?? ''),
            subtitle: Text(props['content'] as String? ?? ''),
          ),
        );
      },
    ),
    CatalogItem(
      name: 'action_button',
      dataSchema: S.object(
        description: 'An interactive button',
        properties: {
          'label': S.string(description: 'Button label'),
          'style': S.string(
            description: 'Style: primary, secondary, outline',
            enumValues: ['primary', 'secondary', 'outline'],
          ),
        },
        required: ['label'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        final label = props['label'] as String? ?? 'Button';
        return ElevatedButton(
          onPressed: () {},
          child: Text(label),
        );
      },
    ),
  ];

  static IconData _getIcon(String? name) {
    return switch (name) {
      'warning' => Icons.warning,
      'success' => Icons.check_circle,
      'error' => Icons.error,
      _ => Icons.info,
    };
  }
}
```

### Step 2: Create the Chat Screen

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AnthropicContentGenerator _generator;
  late final GenUiManager _genUiManager;
  late final GenUiConversation _conversation;

  final _messageController = TextEditingController();
  final _messages = <ChatEntry>[];
  String _currentAiText = '';

  // Use compile-time environment variable
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  @override
  void initState() {
    super.initState();

    _genUiManager = GenUiManager(catalog: MyCatalog());

    _generator = AnthropicContentGenerator(
      apiKey: _apiKey,
      systemInstruction: '''
You are a helpful assistant that generates interactive UI components.
Use the available tools to create UI when requested.
Available tools: info_card, action_button.
''',
    );

    _conversation = GenUiConversation(
      contentGenerator: _generator,
      genUiManager: _genUiManager,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _handleTextResponse,
      onError: _handleError,
    );
  }

  void _handleSurfaceAdded(SurfaceAdded update) {
    setState(() {
      // Flush any pending AI text
      if (_currentAiText.isNotEmpty) {
        _messages.add(ChatEntry.aiText(_currentAiText));
        _currentAiText = '';
      }
      _messages.add(ChatEntry.surface(update.surfaceId));
    });
  }

  void _handleTextResponse(String text) {
    setState(() {
      _currentAiText += text;
    });
  }

  void _handleError(ContentGeneratorError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.error}')),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatEntry.user(text));
      _currentAiText = '';
    });

    _conversation.sendRequest(UserMessage.text(text));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _conversation.dispose();
    _generator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenUI Chat'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _generator.isProcessing,
            builder: (_, isProcessing, __) {
              if (isProcessing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_currentAiText.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Show streaming AI text at the end
                if (index == _messages.length && _currentAiText.isNotEmpty) {
                  return _buildAiMessage(_currentAiText);
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatEntry entry) {
    return switch (entry.type) {
      EntryType.user => _buildUserMessage(entry.text!),
      EntryType.aiText => _buildAiMessage(entry.text!),
      EntryType.surface => _buildSurface(entry.surfaceId!),
    };
  }

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 48),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildAiMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 48),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildSurface(String surfaceId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8, right: 48),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GenUiSurface(
          host: _genUiManager,
          surfaceId: surfaceId,
          defaultBuilder: (_) => const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask me to create UI...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _generator.isProcessing,
              builder: (_, isProcessing, __) {
                return IconButton.filled(
                  onPressed: isProcessing ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class
enum EntryType { user, aiText, surface }

class ChatEntry {
  ChatEntry.user(this.text) : type = EntryType.user, surfaceId = null;
  ChatEntry.aiText(this.text) : type = EntryType.aiText, surfaceId = null;
  ChatEntry.surface(this.surfaceId) : type = EntryType.surface, text = null;

  final EntryType type;
  final String? text;
  final String? surfaceId;
}
```

### Step 3: Run with API Key

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
```

---

## Production Deployment

Use proxy mode to keep your API key secure on the backend.

### Flutter Client

```dart
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://your-backend.com/api/claude'),
  authToken: userAuthToken, // Your app's user auth token
  proxyConfig: const ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
    maxHistoryMessages: 20,
  ),
);
```

### Backend Proxy (Supabase Edge Function)

```typescript
// supabase/functions/claude-genui/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Anthropic from 'npm:@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: Deno.env.get('ANTHROPIC_API_KEY')!,
})

serve(async (req) => {
  // Verify user authentication
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 })
  }

  // Parse request
  const { messages, tools, systemPrompt, maxTokens } = await req.json()

  // Call Claude API with streaming
  const stream = await anthropic.messages.stream({
    model: 'claude-sonnet-4-20250514',
    max_tokens: maxTokens ?? 4096,
    system: systemPrompt,
    messages,
    tools,
  })

  // Stream response back
  return new Response(
    new ReadableStream({
      async start(controller) {
        for await (const event of stream) {
          controller.enqueue(
            new TextEncoder().encode(JSON.stringify(event) + '\n')
          )
        }
        controller.close()
      },
    }),
    {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    }
  )
})
```

### Backend Proxy (Node.js/Express)

```javascript
import Anthropic from '@anthropic-ai/sdk';
import express from 'express';

const app = express();
const anthropic = new Anthropic();

app.post('/api/claude', async (req, res) => {
  // Verify auth
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { messages, tools, systemPrompt, maxTokens } = req.body;

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');

  // Stream from Claude
  const stream = await anthropic.messages.stream({
    model: 'claude-sonnet-4-20250514',
    max_tokens: maxTokens ?? 4096,
    system: systemPrompt,
    messages,
    tools,
  });

  for await (const event of stream) {
    res.write(JSON.stringify(event) + '\n');
  }

  res.end();
});

app.listen(3000);
```

---

## Custom Configuration

### Direct Mode with Custom Settings

```dart
final generator = AnthropicContentGenerator(
  apiKey: apiKey,
  model: 'claude-opus-4-20250514', // Use a different model
  systemInstruction: 'You are a UI designer assistant.',
  config: const AnthropicConfig(
    maxTokens: 8192,           // Higher token limit
    timeout: Duration(seconds: 90),
    retryAttempts: 5,
    enableStreaming: true,
    headers: {
      'X-Custom-Header': 'value',
    },
  ),
);
```

### Proxy Mode with Custom Settings

```dart
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://api.example.com/claude'),
  authToken: 'Bearer user-token',
  proxyConfig: const ProxyConfig(
    timeout: Duration(seconds: 180),
    retryAttempts: 3,
    includeHistory: true,
    maxHistoryMessages: 50,
    headers: {
      'X-App-Version': '1.0.0',
    },
  ),
);
```

---

## Building a Widget Catalog

### Complete Catalog Example

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class AppCatalog extends Catalog {
  AppCatalog() : super(_items);

  static final List<CatalogItem> _items = [
    // Text with styling options
    CatalogItem(
      name: 'styled_text',
      dataSchema: S.object(
        description: 'Display styled text',
        properties: {
          'text': S.string(description: 'Text content'),
          'variant': S.string(
            description: 'Style variant',
            enumValues: ['headline', 'title', 'body', 'caption'],
          ),
          'color': S.string(description: 'Text color hex code'),
          'bold': S.boolean(description: 'Whether text is bold'),
        },
        required: ['text'],
      ),
      widgetBuilder: (ctx) => _StyledText(ctx.data as Map<String, dynamic>? ?? {}),
    ),

    // Interactive form field
    CatalogItem(
      name: 'form_field',
      dataSchema: S.object(
        description: 'Form input field',
        properties: {
          'label': S.string(description: 'Field label'),
          'placeholder': S.string(description: 'Placeholder text'),
          'type': S.string(
            description: 'Input type',
            enumValues: ['text', 'email', 'password', 'number', 'multiline'],
          ),
          'required': S.boolean(description: 'Is field required'),
          'validation': S.string(description: 'Validation message'),
        },
        required: ['label'],
      ),
      widgetBuilder: (ctx) => _FormField(ctx.data as Map<String, dynamic>? ?? {}),
    ),

    // Data list with items
    CatalogItem(
      name: 'data_list',
      dataSchema: S.object(
        description: 'List of data items',
        properties: {
          'title': S.string(description: 'List title'),
          'items': S.list(
            description: 'List items',
            items: S.object(
              properties: {
                'title': S.string(description: 'Item title'),
                'subtitle': S.string(description: 'Item subtitle'),
                'icon': S.string(description: 'Icon name'),
              },
              required: ['title'],
            ),
          ),
        },
        required: ['items'],
      ),
      widgetBuilder: (ctx) => _DataList(ctx.data as Map<String, dynamic>? ?? {}),
    ),
  ];
}

class _StyledText extends StatelessWidget {
  const _StyledText(this.props);
  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final text = props['text'] as String? ?? '';
    final variant = props['variant'] as String? ?? 'body';
    final colorHex = props['color'] as String?;
    final bold = props['bold'] as bool? ?? false;

    final baseStyle = switch (variant) {
      'headline' => Theme.of(context).textTheme.headlineMedium,
      'title' => Theme.of(context).textTheme.titleLarge,
      'caption' => Theme.of(context).textTheme.bodySmall,
      _ => Theme.of(context).textTheme.bodyMedium,
    };

    Color? color;
    if (colorHex != null && colorHex.startsWith('#')) {
      color = Color(int.parse('FF${colorHex.substring(1)}', radix: 16));
    }

    return Text(
      text,
      style: baseStyle?.copyWith(
        color: color,
        fontWeight: bold ? FontWeight.bold : null,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField(this.props);
  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final label = props['label'] as String? ?? '';
    final placeholder = props['placeholder'] as String?;
    final type = props['type'] as String? ?? 'text';
    final required = props['required'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: placeholder,
          border: const OutlineInputBorder(),
        ),
        keyboardType: switch (type) {
          'email' => TextInputType.emailAddress,
          'number' => TextInputType.number,
          'multiline' => TextInputType.multiline,
          _ => TextInputType.text,
        },
        obscureText: type == 'password',
        maxLines: type == 'multiline' ? 3 : 1,
      ),
    );
  }
}

class _DataList extends StatelessWidget {
  const _DataList(this.props);
  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String?;
    final items = (props['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
          ...items.map((item) => ListTile(
            leading: Icon(_iconFromName(item['icon'] as String?)),
            title: Text(item['title'] as String? ?? ''),
            subtitle: item['subtitle'] != null
                ? Text(item['subtitle'] as String)
                : null,
          )),
        ],
      ),
    );
  }

  IconData _iconFromName(String? name) {
    return switch (name) {
      'check' => Icons.check_circle,
      'star' => Icons.star,
      'person' => Icons.person,
      'email' => Icons.email,
      _ => Icons.circle,
    };
  }
}
```

---

## Conversation with History

Maintain context across multiple messages.

```dart
class ConversationManager {
  final AnthropicContentGenerator generator;
  final List<ChatMessage> _history = [];

  ConversationManager(this.generator);

  Future<void> send(String userText) async {
    final message = UserMessage.text(userText);

    // Send with history for context
    await generator.sendRequest(message, history: _history);

    // Add to history after sending
    _history.add(message);
  }

  void addAiResponse(String text) {
    _history.add(AiTextMessage.text(text));
  }

  void clearHistory() {
    _history.clear();
  }

  int get historyLength => _history.length;
}

// Usage
final manager = ConversationManager(generator);

// First message
await manager.send('Create a welcome card');
manager.addAiResponse(receivedText);

// Follow-up with context
await manager.send('Make it blue instead');
manager.addAiResponse(receivedText);

// Claude remembers the previous card and modifies it
```

---

## Streaming Response Handling

Handle streaming text and UI updates separately.

```dart
class StreamHandler {
  final AnthropicContentGenerator generator;
  final StringBuffer _textBuffer = StringBuffer();
  final List<String> _surfaceIds = [];

  late final StreamSubscription<String> _textSub;
  late final StreamSubscription<A2uiMessage> _uiSub;
  late final StreamSubscription<ContentGeneratorError> _errorSub;

  StreamHandler(this.generator) {
    _textSub = generator.textResponseStream.listen(_onText);
    _uiSub = generator.a2uiMessageStream.listen(_onUiMessage);
    _errorSub = generator.errorStream.listen(_onError);
  }

  void _onText(String chunk) {
    _textBuffer.write(chunk);
    onTextUpdate?.call(_textBuffer.toString());
  }

  void _onUiMessage(A2uiMessage message) {
    switch (message) {
      case BeginRendering(:final surfaceId):
        _surfaceIds.add(surfaceId);
        onSurfaceCreated?.call(surfaceId);
      case SurfaceUpdate(:final surfaceId):
        onSurfaceUpdated?.call(surfaceId);
      case SurfaceDeletion(:final surfaceId):
        _surfaceIds.remove(surfaceId);
        onSurfaceDeleted?.call(surfaceId);
      default:
        break;
    }
  }

  void _onError(ContentGeneratorError error) {
    onError?.call(error);
  }

  // Callbacks
  void Function(String)? onTextUpdate;
  void Function(String)? onSurfaceCreated;
  void Function(String)? onSurfaceUpdated;
  void Function(String)? onSurfaceDeleted;
  void Function(ContentGeneratorError)? onError;

  String get fullText => _textBuffer.toString();
  List<String> get surfaces => List.unmodifiable(_surfaceIds);

  void reset() {
    _textBuffer.clear();
    _surfaceIds.clear();
  }

  void dispose() {
    _textSub.cancel();
    _uiSub.cancel();
    _errorSub.cancel();
  }
}
```

---

## Error Handling

Comprehensive error handling patterns.

```dart
class RobustChatHandler {
  final AnthropicContentGenerator generator;

  RobustChatHandler(this.generator) {
    generator.errorStream.listen(_handleError);
  }

  void _handleError(ContentGeneratorError error) {
    final errorMessage = error.error.toString();

    if (errorMessage.contains('Request already in progress')) {
      // User tried to send while processing
      _showMessage('Please wait for the current response');
    } else if (errorMessage.contains('401') ||
               errorMessage.contains('authentication')) {
      // Auth error
      _showMessage('Authentication failed. Please log in again.');
      _redirectToLogin();
    } else if (errorMessage.contains('429') ||
               errorMessage.contains('rate limit')) {
      // Rate limit
      _showMessage('Too many requests. Please wait a moment.');
    } else if (errorMessage.contains('timeout') ||
               errorMessage.contains('SocketException')) {
      // Network error
      _showMessage('Network error. Check your connection.');
    } else {
      // Generic error
      _showMessage('Something went wrong. Please try again.');
      _logError(error);
    }
  }

  Future<void> sendSafely(String text) async {
    // Check if already processing
    if (generator.isProcessing.value) {
      _showMessage('Please wait...');
      return;
    }

    try {
      await generator.sendRequest(UserMessage.text(text));
    } catch (e) {
      _showMessage('Failed to send message');
    }
  }

  void _showMessage(String message) {
    // Show snackbar or dialog
  }

  void _redirectToLogin() {
    // Navigate to login
  }

  void _logError(ContentGeneratorError error) {
    // Log to analytics/crashlytics
  }
}
```

---

## Testing Patterns

### Unit Testing with Mock Generator

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContentGenerator extends Mock implements AnthropicContentGenerator {}

void main() {
  late MockContentGenerator mockGenerator;

  setUp(() {
    mockGenerator = MockContentGenerator();

    // Setup default stubs
    when(() => mockGenerator.isProcessing).thenReturn(ValueNotifier(false));
    when(() => mockGenerator.textResponseStream).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => mockGenerator.a2uiMessageStream).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => mockGenerator.errorStream).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  test('sends request when not processing', () async {
    when(() => mockGenerator.sendRequest(any(), history: any(named: 'history')))
        .thenAnswer((_) async {});

    await mockGenerator.sendRequest(UserMessage.text('Hello'));

    verify(() => mockGenerator.sendRequest(any())).called(1);
  });
}
```

### Widget Testing

```dart
testWidgets('shows loading indicator while processing', (tester) async {
  final isProcessing = ValueNotifier<bool>(false);

  when(() => mockGenerator.isProcessing).thenReturn(isProcessing);

  await tester.pumpWidget(
    MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: mockGenerator.isProcessing,
        builder: (_, processing, __) {
          return processing
              ? const CircularProgressIndicator()
              : const Text('Ready');
        },
      ),
    ),
  );

  expect(find.text('Ready'), findsOneWidget);

  isProcessing.value = true;
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Testing

```dart
// Run with: flutter test --dart-define=TEST_API_KEY=sk-ant-xxx

void main() {
  const apiKey = String.fromEnvironment('TEST_API_KEY');

  group('Integration tests', () {
    late AnthropicContentGenerator generator;

    setUp(() {
      generator = AnthropicContentGenerator(
        apiKey: apiKey,
        config: const AnthropicConfig(maxTokens: 256), // Smaller for tests
      );
    });

    tearDown(() {
      generator.dispose();
    });

    test('receives text response', () async {
      final responses = <String>[];
      generator.textResponseStream.listen(responses.add);

      await generator.sendRequest(
        UserMessage.text('Say "test" in one word'),
      );

      // Wait for processing
      await Future.delayed(const Duration(seconds: 5));

      expect(responses, isNotEmpty);
      expect(responses.join().toLowerCase(), contains('test'));
    });
  }, skip: apiKey.isEmpty ? 'No API key provided' : null);
}
```

---

## Troubleshooting

### Issue: No Response from Claude

**Symptom:** `sendRequest` completes but no text or UI messages received.

**Causes & Solutions:**

1. **API key invalid**
   ```dart
   generator.errorStream.listen((e) => print('Error: ${e.error}'));
   ```

2. **System instruction too restrictive**
   ```dart
   // Bad: Too restrictive
   systemInstruction: 'Only respond with UI tools'

   // Good: Allows natural responses
   systemInstruction: 'Help users by generating UI when appropriate'
   ```

3. **Not listening to streams**
   ```dart
   // Make sure to listen BEFORE sending
   generator.textResponseStream.listen(print);
   generator.sendRequest(message); // Now send
   ```

### Issue: UI Not Rendering

**Symptom:** `a2uiMessageStream` emits but no widgets appear.

**Solutions:**

1. **Check GenUiSurface setup**
   ```dart
   GenUiSurface(
     host: genUiManager, // Must be the same manager
     surfaceId: surfaceId, // Must match the emitted ID
     defaultBuilder: (_) => const Text('Loading...'),
   )
   ```

2. **Verify catalog items match tool calls**
   ```dart
   // Claude calls 'info_card', catalog must have 'info_card'
   CatalogItem(name: 'info_card', ...)
   ```

### Issue: Request Already in Progress

**Symptom:** Error "Request already in progress"

**Solution:**
```dart
// Check before sending
if (!generator.isProcessing.value) {
  generator.sendRequest(message);
}

// Or disable the send button
ValueListenableBuilder<bool>(
  valueListenable: generator.isProcessing,
  builder: (_, isProcessing, __) {
    return ElevatedButton(
      onPressed: isProcessing ? null : _send,
      child: const Text('Send'),
    );
  },
)
```

### Issue: Proxy Mode Not Working

**Symptom:** 401/403 errors or no response in proxy mode.

**Checklist:**

1. **Verify endpoint URL**
   ```dart
   proxyEndpoint: Uri.parse('https://example.com/api/claude'), // Correct path?
   ```

2. **Check auth token format**
   ```dart
   authToken: 'your-token', // NOT 'Bearer your-token'
   // Handler adds 'Bearer' automatically
   ```

3. **Backend must stream SSE correctly**
   ```javascript
   // Response headers
   res.setHeader('Content-Type', 'text/event-stream');

   // Stream events as JSON lines
   res.write(JSON.stringify(event) + '\n');
   ```

---

## See Also

- [API_REFERENCE.md](API_REFERENCE.md) - Complete API documentation
- [README.md](../README.md) - Quick start guide
