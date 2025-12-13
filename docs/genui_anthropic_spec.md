# genui_anthropic

## Technical Specification Document

**Flutter ContentGenerator for Claude AI Integration with GenUI SDK**

Version 1.0.0 | December 2025

---

| Field | Value |
|-------|-------|
| Document Owner | unfazed-dev (github.com/unfazed-dev) |
| Package Type | Flutter Package (depends on Flutter SDK) |
| Target Environments | Flutter Mobile (iOS, Android), Flutter Web, Flutter Desktop |
| GenUI Version | ^0.5.1 |
| License | MIT |
| Repository | github.com/unfazed-dev/anthropic_genui (monorepo) |
| Package Path | packages/genui_anthropic |

---

## 1. Executive Summary

The genui_anthropic package provides a Flutter-native ContentGenerator implementation that enables Anthropic's Claude AI models to power the Flutter GenUI SDK. This package serves as the bridge between Claude's sophisticated reasoning capabilities and GenUI's dynamic widget rendering system.

By leveraging the anthropic_a2ui Dart package for protocol conversion, genui_anthropic provides a thin, focused adapter layer that integrates seamlessly with the existing GenUI ecosystem while maintaining compatibility with Flutter's reactive programming patterns.

---

## 2. Problem Statement

### 2.1 GenUI ContentGenerator Abstraction

The Flutter GenUI SDK uses a ContentGenerator abstraction to communicate with AI backends. This abstraction expects implementations to provide:

- A2UI message streams for UI rendering instructions
- Text response streams for conversational display
- Error handling streams
- Tool definitions derived from the widget catalog

### 2.2 Current Limitations

Existing ContentGenerator implementations are limited to Google's AI services (Gemini via Firebase or direct API). Developers seeking to use Claude's capabilities with GenUI have no supported path.

### 2.3 Solution

This package provides AnthropicContentGenerator, a production-ready ContentGenerator implementation that enables Claude-powered generative UI in Flutter applications. It supports both direct API access for development and backend proxy patterns for production deployments.

---

## 3. Architecture

### 3.1 Design Principles

- **Thin Adapter Layer:** Minimal code wrapping anthropic_a2ui functionality
- **GenUI Compatibility:** Full compliance with ContentGenerator interface
- **Flutter Idioms:** Follows Flutter conventions (dispose patterns, widget lifecycle)
- **Flexible Backends:** Direct API or proxy modes
- **Testability:** Easy mocking for widget tests

### 3.2 System Context

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Flutter Application                            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    GenUiConversation                          │  │
│  │  ┌─────────────────┐  ┌────────────────────────────────────┐  │  │
│  │  │  GenUiManager   │  │  AnthropicContentGenerator         │  │  │
│  │  │  (Catalog)      │  │  ┌──────────────────────────────┐  │  │  │
│  │  │                 │  │  │  anthropic_a2ui              │  │  │  │
│  │  │  - Widgets      │──│  │  - Tool Conversion           │  │  │  │
│  │  │  - Data Model   │  │  │  - Message Parsing           │  │  │  │
│  │  │  - Surfaces     │  │  │  - Stream Handling           │  │  │  │
│  │  └─────────────────┘  │  └──────────────────────────────┘  │  │  │
│  │                       └──────────────┬─────────────────────┘  │  │
│  └──────────────────────────────────────┼────────────────────────┘  │
│                                         │                            │
│  ┌──────────────────────────────────────▼────────────────────────┐  │
│  │                     GenUiSurface Widgets                      │  │
│  │  (Rendered UI based on A2UI messages)                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
           ┌────────▼────────┐           ┌─────────▼─────────┐
           │  Direct Mode    │           │   Proxy Mode      │
           │  (Development)  │           │   (Production)    │
           │                 │           │                   │
           │  Claude API     │           │  Supabase Edge    │
           │  (api.anthropic │           │  Function         │
           │   .com)         │           │  → Claude API     │
           └─────────────────┘           └───────────────────┘
```

### 3.3 Relationship to anthropic_a2ui

This package maintains a clear separation of concerns with anthropic_a2ui:

| Concern | anthropic_a2ui | genui_anthropic |
|---------|----------------|-----------------|
| Tool schema conversion | ✓ Implements | Uses |
| Message parsing | ✓ Implements | Uses |
| Stream handling | ✓ Implements | Uses |
| ContentGenerator interface | — | ✓ Implements |
| GenUI type bridging | — | ✓ Implements |
| Flutter lifecycle | — | ✓ Manages |

---

## 4. Core Components

### 4.1 AnthropicContentGenerator

The primary class implementing GenUI's ContentGenerator interface.

```dart
class AnthropicContentGenerator implements ContentGenerator {
  /// Create a direct API connection (for development/prototyping)
  factory AnthropicContentGenerator({
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    String? systemInstruction,
    required List<Tool> tools,
    AnthropicConfig? config,
  });
  
  /// Create a backend proxy connection (for production)
  factory AnthropicContentGenerator.proxy({
    required Uri endpoint,
    String? authToken,
    required List<Tool> tools,
    ProxyConfig? config,
  });
  
  // ContentGenerator interface implementation
  @override
  Stream<A2uiMessage> get a2uiMessageStream;
  
  @override
  Stream<String> get textResponseStream;
  
  @override
  Stream<Object> get errorStream;
  
  @override
  Future<void> sendRequest(List<Message> conversationHistory);
  
  @override
  List<Tool> get tools;
  
  /// Dispose of resources
  void dispose();
}
```

### 4.2 Configuration Classes

#### 4.2.1 AnthropicConfig

Configuration for direct API mode.

```dart
class AnthropicConfig {
  /// Maximum tokens in response
  final int maxTokens;
  
  /// Request timeout duration
  final Duration timeout;
  
  /// Number of retry attempts for transient failures
  final int retryAttempts;
  
  /// Enable streaming responses
  final bool enableStreaming;
  
  /// Custom HTTP headers
  final Map<String, String>? headers;
  
  const AnthropicConfig({
    this.maxTokens = 4096,
    this.timeout = const Duration(seconds: 60),
    this.retryAttempts = 3,
    this.enableStreaming = true,
    this.headers,
  });
}
```

#### 4.2.2 ProxyConfig

Configuration for backend proxy mode.

```dart
class ProxyConfig {
  /// Request timeout duration
  final Duration timeout;
  
  /// Number of retry attempts
  final int retryAttempts;
  
  /// Custom HTTP headers (in addition to auth)
  final Map<String, String>? headers;
  
  /// Whether to send conversation history
  final bool includeHistory;
  
  /// Maximum history messages to include
  final int maxHistoryMessages;
  
  const ProxyConfig({
    this.timeout = const Duration(seconds: 120),
    this.retryAttempts = 3,
    this.headers,
    this.includeHistory = true,
    this.maxHistoryMessages = 20,
  });
}
```

### 4.3 Message Adapter

Bridges between anthropic_a2ui message types and GenUI's A2uiMessage types.

```dart
class A2uiMessageAdapter {
  /// Convert anthropic_a2ui message to GenUI A2uiMessage
  static A2uiMessage toGenUiMessage(A2uiMessageData data) {
    return switch (data) {
      BeginRenderingData d => A2uiMessage.beginRendering(
        surfaceId: d.surfaceId,
        parentSurfaceId: d.parentSurfaceId,
      ),
      SurfaceUpdateData d => A2uiMessage.surfaceUpdate(
        surfaceId: d.surfaceId,
        widgets: d.widgets.map(_toGenUiWidget).toList(),
      ),
      DataModelUpdateData d => A2uiMessage.dataModelUpdate(
        updates: d.updates,
      ),
      DeleteSurfaceData d => A2uiMessage.deleteSurface(
        surfaceId: d.surfaceId,
      ),
    };
  }
  
  /// Convert widget node to GenUI widget representation
  static GenUiWidget _toGenUiWidget(WidgetNode node) {
    return GenUiWidget(
      type: node.type,
      properties: node.properties,
      children: node.children?.map(_toGenUiWidget).toList(),
      dataBinding: node.dataBinding,
    );
  }
}
```

### 4.4 Tool Catalog Bridge

Extracts tool definitions from GenUI catalog for Claude API.

```dart
class CatalogToolBridge {
  /// Extract tools from GenUiManager's catalog
  static List<Tool> fromCatalog(GenUiManager manager) {
    final catalogItems = manager.catalog.items;
    return catalogItems.map((item) => Tool(
      name: item.name,
      description: item.description,
      inputSchema: _convertSchema(item.inputSchema),
    )).toList();
  }
  
  /// Extract tools from individual CatalogItems
  static List<Tool> fromItems(List<CatalogItem> items) {
    return items.map((item) => Tool(
      name: item.name,
      description: item.description,
      inputSchema: _convertSchema(item.inputSchema),
    )).toList();
  }
  
  /// Add A2UI control tools (begin_rendering, surface_update, etc.)
  static List<Tool> withA2uiTools(List<Tool> widgetTools) {
    return [
      ...A2uiControlTools.all,
      ...widgetTools,
    ];
  }
}
```

---

## 5. Integration Patterns

### 5.1 Basic Integration

Minimal setup for development and prototyping.

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenUiConversation _conversation;
  late final AnthropicContentGenerator _contentGenerator;
  
  @override
  void initState() {
    super.initState();
    
    // Create content generator
    _contentGenerator = AnthropicContentGenerator(
      apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
      model: 'claude-sonnet-4-20250514',
      systemInstruction: '''
You are a helpful assistant that generates UI components.
Use the available tools to create interactive interfaces.
''',
      tools: CatalogToolBridge.fromItems(MyCatalog.items),
    );
    
    // Create conversation
    _conversation = GenUiConversation(
      contentGenerator: _contentGenerator,
      catalog: MyCatalog(),
    );
  }
  
  @override
  void dispose() {
    _contentGenerator.dispose();
    _conversation.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GenUiChatView(conversation: _conversation);
  }
}
```

### 5.2 Production Integration with Supabase

Recommended pattern for production deployments with secure API key handling.

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductionChatScreen extends StatefulWidget {
  @override
  State<ProductionChatScreen> createState() => _ProductionChatScreenState();
}

class _ProductionChatScreenState extends State<ProductionChatScreen> {
  late final GenUiConversation _conversation;
  late final AnthropicContentGenerator _contentGenerator;
  
  @override
  void initState() {
    super.initState();
    
    final supabase = Supabase.instance.client;
    
    // Create content generator with backend proxy
    _contentGenerator = AnthropicContentGenerator.proxy(
      endpoint: Uri.parse(
        '${supabase.supabaseUrl}/functions/v1/claude-genui',
      ),
      authToken: supabase.auth.currentSession?.accessToken,
      tools: CatalogToolBridge.fromItems(DemoCatalog.items),
      config: ProxyConfig(
        timeout: Duration(seconds: 120),
        includeHistory: true,
        maxHistoryMessages: 10,
      ),
    );
    
    _conversation = GenUiConversation(
      contentGenerator: _contentGenerator,
      catalog: DemoCatalog(),
    );
  }
  
  // ... dispose and build methods
}
```

### 5.3 Custom Catalog Integration

Creating domain-specific widget catalogs for your application.

```dart
// lib/catalog/app_catalog.dart
import 'package:genui/genui.dart';

class AppCatalog extends Catalog {
  @override
  List<CatalogItem> get items => [
    // User profile card widget
    CatalogItem(
      name: 'user_card',
      description: 'Display user profile summary with avatar, name, and status',
      inputSchema: {
        'type': 'object',
        'properties': {
          'userId': {'type': 'string'},
          'showDetails': {'type': 'boolean', 'default': true},
          'compact': {'type': 'boolean', 'default': false},
        },
        'required': ['userId'],
      },
      builder: (context, properties, dataModel) {
        return UserCard(
          userId: properties['userId'],
          showDetails: properties['showDetails'] ?? true,
          compact: properties['compact'] ?? false,
        );
      },
    ),
    
    // Task creation form widget
    CatalogItem(
      name: 'task_form',
      description: 'Interactive form for creating and editing tasks',
      inputSchema: {
        'type': 'object',
        'properties': {
          'projectId': {'type': 'string'},
          'assigneeId': {'type': 'string'},
          'taskType': {'type': 'string'},
          'dueDate': {'type': 'string'},
        },
        'required': ['projectId', 'taskType'],
      },
      builder: (context, properties, dataModel) {
        return TaskForm(
          projectId: properties['projectId'],
          assigneeId: properties['assigneeId'],
          taskType: properties['taskType'],
          dueDate: properties['dueDate'],
          onTaskCreated: (task) {
            dataModel.update('lastTask', task.toJson());
          },
        );
      },
    ),
    
    // Search results list
    CatalogItem(
      name: 'search_results',
      description: 'Display list of search results with filtering',
      inputSchema: {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'category': {'type': 'string'},
          'maxResults': {'type': 'number'},
          'results': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
                'title': {'type': 'string'},
                'description': {'type': 'string'},
                'score': {'type': 'number'},
              },
            },
          },
        },
        'required': ['query'],
      },
      builder: (context, properties, dataModel) {
        return SearchResultsView(
          query: properties['query'],
          category: properties['category'],
          results: properties['results'],
          onResultSelected: (result) {
            dataModel.update('selectedResult', result);
          },
        );
      },
    ),
    
    // Analytics dashboard widget
    CatalogItem(
      name: 'analytics_chart',
      description: 'Visual chart showing metrics and trends',
      inputSchema: {
        'type': 'object',
        'properties': {
          'chartType': {'type': 'string', 'enum': ['line', 'bar', 'pie']},
          'dataSource': {'type': 'string'},
          'timeRange': {'type': 'string'},
          'showLegend': {'type': 'boolean'},
        },
        'required': ['chartType', 'dataSource'],
      },
      builder: (context, properties, dataModel) {
        return AnalyticsChart(
          chartType: properties['chartType'],
          dataSource: properties['dataSource'],
          timeRange: properties['timeRange'],
          showLegend: properties['showLegend'] ?? true,
        );
      },
    ),
  ];
}
```

---

## 6. Streaming Architecture

### 6.1 Stream Flow

The package manages three concurrent streams as required by ContentGenerator:

```
┌─────────────────────────────────────────────────────────────────┐
│                   AnthropicContentGenerator                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    ClaudeStreamHandler                     │  │
│  │               (from anthropic_a2ui)                        │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │                                     │
│            ┌───────────────┼───────────────┐                     │
│            │               │               │                     │
│   ┌────────▼────────┐ ┌────▼─────┐ ┌───────▼───────┐            │
│   │ _a2uiController │ │ _text    │ │ _error        │            │
│   │ StreamController│ │ Controller│ │ Controller    │            │
│   │ <A2uiMessage>   │ │ <String> │ │ <Object>      │            │
│   └────────┬────────┘ └────┬─────┘ └───────┬───────┘            │
│            │               │               │                     │
└────────────┼───────────────┼───────────────┼─────────────────────┘
             │               │               │
    ┌────────▼────────┐ ┌────▼─────┐ ┌───────▼───────┐
    │ a2uiMessageStream│ │textResponse│ │ errorStream   │
    │ (to GenUI)      │ │Stream    │ │ (to UI)       │
    └─────────────────┘ └──────────┘ └───────────────┘
```

### 6.2 Stream Implementation

```dart
class AnthropicContentGenerator implements ContentGenerator {
  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  
  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;
  
  @override
  Stream<String> get textResponseStream => _textController.stream;
  
  @override
  Stream<Object> get errorStream => _errorController.stream;
  
  @override
  Future<void> sendRequest(List<Message> conversationHistory) async {
    try {
      await for (final event in _streamHandler.streamRequest(
        messages: _convertMessages(conversationHistory),
        tools: _tools,
        systemPrompt: _systemInstruction,
      )) {
        switch (event) {
          case A2uiMessageEvent(:final message):
            // Convert and emit A2UI message
            final genUiMessage = A2uiMessageAdapter.toGenUiMessage(message);
            _a2uiController.add(genUiMessage);
            
          case TextDeltaEvent(:final text):
            // Emit text chunk
            _textController.add(text);
            
          case ErrorEvent(:final error):
            // Emit error
            _errorController.addError(error);
            
          case CompleteEvent():
            // Stream complete - no action needed
            break;
        }
      }
    } catch (e, stackTrace) {
      _errorController.addError(e, stackTrace);
    }
  }
  
  void dispose() {
    _a2uiController.close();
    _textController.close();
    _errorController.close();
  }
}
```

### 6.3 Progressive UI Rendering

The streaming architecture enables progressive UI updates as Claude generates responses:

1. Claude begins generating response with begin_rendering tool call
2. Package emits BeginRendering A2uiMessage → GenUI creates surface placeholder
3. Claude streams surface_update with partial widget tree
4. Package emits SurfaceUpdate → GenUI renders widgets progressively
5. Data model updates stream alongside widget updates
6. User sees UI building in real-time (typically 200-500ms per update)

---

## 7. Error Handling

### 7.1 Error Categories

| Category | Examples | Handling |
|----------|----------|----------|
| Network | Timeout, connection failed, DNS | Retry with backoff, emit to errorStream |
| Authentication | Invalid API key, expired token | Emit AuthenticationError, no retry |
| Rate Limiting | 429 response from API/proxy | Queue with delay, emit warning |
| Parse | Malformed response, invalid JSON | Skip block, log warning, continue |
| Validation | Invalid tool input, schema mismatch | Emit ValidationError with details |

### 7.2 Error Recovery UI Pattern

```dart
class ResilientChatView extends StatelessWidget {
  final GenUiConversation conversation;
  final AnthropicContentGenerator contentGenerator;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: contentGenerator.errorStream,
      builder: (context, errorSnapshot) {
        return Column(
          children: [
            // Error banner (if error present)
            if (errorSnapshot.hasError)
              ErrorBanner(
                error: errorSnapshot.error!,
                onRetry: () => _retryLastMessage(),
                onDismiss: () => _clearError(),
              ),
            
            // Main chat view
            Expanded(
              child: GenUiChatView(conversation: conversation),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

```dart
// test/anthropic_content_generator_test.dart
void main() {
  group('AnthropicContentGenerator', () {
    late MockClaudeStreamHandler mockHandler;
    late AnthropicContentGenerator generator;
    
    setUp(() {
      mockHandler = MockClaudeStreamHandler();
      generator = AnthropicContentGenerator.withHandler(
        handler: mockHandler,
        tools: testTools,
      );
    });
    
    tearDown(() {
      generator.dispose();
    });
    
    test('emits A2uiMessages from tool_use responses', () async {
      mockHandler.stubResponse([
        A2uiMessageEvent(BeginRenderingData(surfaceId: 'surface-1')),
        A2uiMessageEvent(SurfaceUpdateData(
          surfaceId: 'surface-1',
          widgets: [WidgetNode(type: 'text', properties: {'text': 'Hello'})],
        )),
        CompleteEvent(),
      ]);
      
      final messages = <A2uiMessage>[];
      generator.a2uiMessageStream.listen(messages.add);
      
      await generator.sendRequest([Message.user('Say hello')]);
      
      expect(messages, hasLength(2));
      expect(messages[0], isA<BeginRendering>());
      expect(messages[1], isA<SurfaceUpdate>());
    });
    
    test('emits text responses', () async {
      mockHandler.stubResponse([
        TextDeltaEvent('Hello '),
        TextDeltaEvent('world!'),
        CompleteEvent(),
      ]);
      
      final textChunks = <String>[];
      generator.textResponseStream.listen(textChunks.add);
      
      await generator.sendRequest([Message.user('Greet me')]);
      
      expect(textChunks.join(), equals('Hello world!'));
    });
    
    test('handles errors gracefully', () async {
      mockHandler.stubError(NetworkException('Connection timeout'));
      
      final errors = <Object>[];
      generator.errorStream.listen(errors.add);
      
      await generator.sendRequest([Message.user('Test')]);
      
      expect(errors, hasLength(1));
      expect(errors[0], isA<NetworkException>());
    });
  });
}
```

### 8.2 Widget Tests

```dart
// test/widget/chat_screen_test.dart
void main() {
  testWidgets('ChatScreen renders generated UI', (tester) async {
    final mockGenerator = MockAnthropicContentGenerator();
    
    // Stub A2UI message stream
    mockGenerator.stubA2uiStream([
      A2uiMessage.beginRendering(surfaceId: 'main'),
      A2uiMessage.surfaceUpdate(
        surfaceId: 'main',
        widgets: [
          GenUiWidget(type: 'text', properties: {'text': 'Generated content'}),
        ],
      ),
    ]);
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(contentGenerator: mockGenerator),
      ),
    );
    
    // Trigger message send
    await tester.enterText(find.byType(TextField), 'Generate UI');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    // Verify generated widget rendered
    expect(find.text('Generated content'), findsOneWidget);
  });
}
```

### 8.3 Integration Tests

```dart
// integration_test/claude_integration_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Full Claude → GenUI flow', (tester) async {
    // Use real API in CI (with test API key)
    final generator = AnthropicContentGenerator(
      apiKey: Platform.environment['TEST_ANTHROPIC_API_KEY']!,
      model: 'claude-sonnet-4-20250514',
      tools: TestCatalog.tools,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: TestChatScreen(generator: generator),
      ),
    );
    
    // Send test message
    await tester.enterText(find.byType(TextField), 'Create a simple form');
    await tester.tap(find.byIcon(Icons.send));
    
    // Wait for response (with timeout)
    await tester.pumpAndSettle(timeout: Duration(seconds: 30));
    
    // Verify some UI was generated
    expect(find.byType(GenUiSurface), findsWidgets);
    
    generator.dispose();
  });
}
```

### 8.4 Coverage Requirements

| Component | Min Coverage | Target |
|-----------|--------------|--------|
| AnthropicContentGenerator | 90% | 95% |
| A2uiMessageAdapter | 95% | 100% |
| CatalogToolBridge | 90% | 95% |
| Configuration classes | 95% | 100% |
| Overall Package | 90% | 95% |

---

## 9. Dependencies

### 9.1 Runtime Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  genui: ^0.5.1                    # GenUI SDK
  anthropic_a2ui: ^1.0.0           # Protocol conversion (Dart package)
  anthropic_sdk_dart: ^0.9.0       # Claude API client
  http: ^1.1.0                     # HTTP client for proxy mode
```

### 9.2 Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0                  # Mocking
  build_runner: ^2.4.0             # Code generation
```

### 9.3 Environment Constraints

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.35.0'
```

---

## 10. File Structure

### 10.1 Monorepo Structure

```
anthropic_genui/                          # Monorepo root
├── packages/
│   ├── anthropic_a2ui/                   # Dart package (protocol conversion)
│   │   └── ...
│   └── genui_anthropic/                  # This package
│       └── ...
├── example/
│   └── demo_app/                         # Shared example app
├── melos.yaml                            # Monorepo tooling
├── README.md
└── LICENSE
```

### 10.2 Package Structure

```
packages/genui_anthropic/
├── lib/
│   ├── genui_anthropic.dart           # Public API exports
│   └── src/
│       ├── content_generator/
│       │   ├── anthropic_content_generator.dart
│       │   ├── direct_mode.dart       # Direct API implementation
│       │   └── proxy_mode.dart        # Backend proxy implementation
│       ├── adapter/
│       │   ├── message_adapter.dart   # A2UI message bridging
│       │   └── tool_bridge.dart       # Catalog to tools conversion
│       ├── config/
│       │   ├── anthropic_config.dart
│       │   └── proxy_config.dart
│       └── utils/
│           └── message_converter.dart # GenUI Message conversion
├── test/
│   ├── content_generator/
│   │   ├── anthropic_content_generator_test.dart
│   │   ├── direct_mode_test.dart
│   │   └── proxy_mode_test.dart
│   ├── adapter/
│   │   ├── message_adapter_test.dart
│   │   └── tool_bridge_test.dart
│   ├── widget/
│   │   └── chat_integration_test.dart
│   └── mocks/
│       └── mock_generators.dart
├── example/
│   ├── lib/
│   │   ├── main.dart                  # Basic example
│   │   ├── catalog/
│   │   │   └── demo_catalog.dart      # Example catalog
│   │   └── screens/
│   │       ├── basic_chat.dart
│   │       └── production_chat.dart
│   └── pubspec.yaml
├── integration_test/
│   └── claude_flow_test.dart
├── pubspec.yaml
├── analysis_options.yaml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

---

## 11. Supabase Edge Function Template

For production deployments, the package expects a backend proxy. Here is the recommended Supabase Edge Function implementation:

### 11.1 Edge Function Structure

```typescript
// supabase/functions/claude-genui/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Anthropic from 'npm:@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: Deno.env.get('ANTHROPIC_API_KEY')!,
})

serve(async (req) => {
  // Verify authentication
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 })
  }
  
  // Parse request
  const { messages, tools, systemPrompt, userContext } = await req.json()
  
  // Enrich system prompt with context (if provided)
  const enrichedPrompt = userContext 
    ? `${systemPrompt}\n\nContext: ${JSON.stringify(userContext)}`
    : systemPrompt
  
  // Create streaming response
  const stream = await anthropic.messages.stream({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 4096,
    system: enrichedPrompt,
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

### 11.2 Context Enrichment

The Edge Function can enrich requests with Supabase data before forwarding to Claude:

```typescript
// Enhanced version with context loading
import { createClient } from 'npm:@supabase/supabase-js'

async function loadUserContext(supabase, userId) {
  // Load user's profile data (RLS applied)
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, name, email, role')
    .eq('user_id', userId)
    .single()
  
  // Load recent activity
  const { data: activities } = await supabase
    .from('activities')
    .select('id, type, description, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(5)
  
  return {
    profile,
    recentActivities: activities,
  }
}
```

---

## 12. Performance Considerations

### 12.1 Latency Breakdown

| Operation | Direct Mode | Proxy Mode |
|-----------|-------------|------------|
| Tool schema conversion | < 1ms | < 1ms |
| Network round-trip | 50-150ms | 80-200ms |
| Claude processing (TTFT) | 200-800ms | 200-800ms |
| Stream event processing | < 0.5ms | < 0.5ms |
| Widget render (GenUI) | 16-50ms | 16-50ms |

### 12.2 Optimization Strategies

- **Connection Keep-Alive:** Reuse HTTP connections for proxy mode
- **Tool Caching:** Cache converted tool schemas between requests
- **Conversation Pruning:** Limit history to most recent N messages
- **Regional Deployment:** Deploy Edge Functions to user-proximate regions

---

## 13. Security Considerations

### 13.1 API Key Security

- **Direct Mode (Development Only):** Use compile-time environment variables, never hardcode
- **Proxy Mode (Production):** API key stored in Supabase secrets, never exposed to client
- **Token Refresh:** Auth tokens refreshed automatically by Supabase client

### 13.2 Input Sanitization

All user inputs are sanitized before sending to Claude:

- Message content length limits enforced
- Tool inputs validated against schemas
- Conversation history pruned to prevent context overflow

---

## 14. Roadmap

### 14.1 Version 1.0.0 (Initial Release)

- ContentGenerator implementation
- Direct and proxy modes
- Streaming support
- Supabase Edge Function template

### 14.2 Version 1.1.0

- Offline message queueing
- Conversation persistence helpers
- Advanced retry policies

### 14.3 Version 1.2.0

- Multi-modal support (images in chat)
- Voice input integration hooks
- Analytics and telemetry hooks

---

## 15. Appendix

### 15.1 GenUI SDK Reference

For GenUI SDK documentation, see the official package: https://pub.dev/packages/genui

### 15.2 Related Packages

- anthropic_a2ui - Protocol conversion layer (same monorepo)
- genui - Flutter GenUI SDK core
- genui_firebase_ai - Firebase/Gemini ContentGenerator (reference implementation)
- supabase_flutter - Supabase Flutter client

### 15.3 Monorepo Development

This package is developed as part of the anthropic_genui monorepo. For local development:

```bash
# Clone the monorepo
git clone https://github.com/unfazed-dev/anthropic_genui.git
cd anthropic_genui

# Install Melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run tests across all packages
melos test

# Run Flutter tests only
melos run test:flutter

# Publish packages (maintainers only)
melos publish
```

### 15.4 Example Catalogs

The example/ directory contains several reference catalogs:

- demo_catalog.dart - Basic widgets for getting started
- form_catalog.dart - Form-building widgets
- data_viz_catalog.dart - Charts and data visualization

### 15.5 Troubleshooting

Common issues and solutions:

1. **No UI generated:** Verify system prompt instructs Claude to use tools
2. **Authentication errors:** Check API key (direct) or auth token (proxy)
3. **Widgets not rendering:** Ensure catalog item names match tool names exactly
4. **Slow responses:** Consider using claude-haiku for faster iterations
