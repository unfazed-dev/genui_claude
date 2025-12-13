---
name: genui-flutter
description: Flutter GenUI SDK for building dynamic, LLM-generated user interfaces. Use when creating chatbots with interactive UI, AI agents that generate forms/widgets dynamically, or any application where the UI is composed at runtime by an AI model based on user intent.
version: 0.5.1 (alpha)
---

# Flutter GenUI SDK

Comprehensive guide to building dynamic, LLM-generated user interfaces with Flutter's GenUI SDK. This SDK transforms text-based AI conversations into rich, interactive widget experiences.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GENUI ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  USER                     GENUI                        AI MODEL             │
│  ────                     ─────                        ────────             │
│                                                                             │
│  ┌──────────┐            ┌─────────────────┐          ┌──────────────┐     │
│  │  Input   │───prompt──▶│GenUiConversation│──tools──▶│ Gemini/LLM   │     │
│  │  Field   │            │                 │          │              │     │
│  └──────────┘            │  ┌───────────┐  │          │  Uses Widget │     │
│                          │  │ Catalog   │  │◀─schema─ │  Schemas to  │     │
│                          │  │ (Widgets) │  │          │  Generate UI │     │
│  ┌──────────┐            │  └───────────┘  │          │              │     │
│  │Generated │◀──render───│                 │◀──JSON───│              │     │
│  │   UI     │            │  ┌───────────┐  │          └──────────────┘     │
│  │ Surface  │            │  │ DataModel │  │                               │
│  └────┬─────┘            │  │  (State)  │  │                               │
│       │                  │  └───────────┘  │                               │
│       │                  └─────────────────┘                               │
│       │                          ▲                                         │
│       └──────user action─────────┘                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**What GenUI Does:**
- Replaces "walls of text" from LLMs with dynamic, interactive graphical UI
- Converts AI responses into rendered Flutter widgets at runtime
- Creates two-way interaction: user actions update DataModel → sent back to AI

**Key Benefits:**
- **Interactive AI chatbots** - Instead of text descriptions, show carousels, forms, cards
- **Dynamic forms** - AI generates forms with sliders, date pickers, text fields on the fly
- **Brand consistency** - Uses YOUR existing widget catalog, not generic components
- **Cross-platform** - Works anywhere Flutter works (mobile, web, desktop)

**Status:** Alpha (API will change). Requires Flutter ≥3.35.7

## Setup

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core GenUI
  genui: ^0.5.1
  
  # Choose ONE content generator:
  
  # Option 1: Google Generative AI (quick prototyping)
  genui_google_generative_ai: ^0.5.1
  
  # Option 2: Firebase AI (production recommended)
  genui_firebase_ai: ^0.5.1
  firebase_core: ^latest
  
  # Option 3: A2UI server (custom backend)
  genui_a2ui: ^0.5.1
  
  # For schema building
  json_schema_builder: ^0.5.1
```

### Content Generator Options

| Generator | Use Case | Auth |
|-----------|----------|------|
| `GoogleGenerativeAiContentGenerator` | Quick prototyping, local testing | API key only |
| `FirebaseAiContentGenerator` | Production apps | Firebase AI Logic |
| `A2uiContentGenerator` | Custom backend servers | A2UI protocol |

## Core Concepts

### 1. GenUiConversation

The main entry point that orchestrates everything.

```dart
late final GenUiConversation _genUiConversation;

@override
void initState() {
  super.initState();
  
  // Create GenUiManager with widget catalog
  final genUiManager = GenUiManager(
    catalog: CoreCatalogItems.asCatalog().copyWith([
      // Add custom widgets here
    ]),
  );
  
  // Create content generator (connects to AI)
  final contentGenerator = GoogleGenerativeAiContentGenerator(
    apiKey: 'YOUR_GEMINI_API_KEY',
    systemInstruction: '''
      You are a helpful assistant that generates UI.
      Use the available widgets to create interactive experiences.
    ''',
    tools: genUiManager.getTools(),
  );
  
  // Create conversation
  _genUiConversation = GenUiConversation(
    genUiManager: genUiManager,
    contentGenerator: contentGenerator,
    onSurfaceAdded: _handleSurfaceAdded,
    onSurfaceRemoved: _handleSurfaceRemoved,
    onTextResponse: _handleTextResponse,
    onError: _handleError,
  );
}
```

### 2. Catalog & CatalogItems

The catalog defines what widgets the AI can use.

```dart
// Widget catalog = vocabulary for the AI
final catalog = Catalog(components: [
  // Built-in core items
  ...CoreCatalogItems.items,
  
  // Your custom widgets
  productCard,
  bookingForm,
  ratingStar,
]);

// Or start with core and add
final catalog = CoreCatalogItems.asCatalog().copyWith([
  productCard,
  bookingForm,
]);
```

### 3. DataModel & DataContext

Centralized state store for all dynamic UI.

```dart
// DataModel holds all UI state
// - Widgets are "bound" to paths in the DataModel
// - Changes to DataModel automatically rebuild bound widgets
// - User interactions update DataModel → sent back to AI

// Data binding in JSON from AI:
{
  "TextField": {
    "value": {"path": "/user/name"},  // Bound to DataModel
    "hint": {"literalString": "Enter name"}  // Static value
  }
}
```

### 4. GenUiSurface

The widget that renders generated UI.

```dart
// Each AI-generated UI has a unique surfaceId
GenUiSurface(
  host: _genUiConversation.genUiManager,
  surfaceId: surfaceId,
  onEvent: (event) {
    // Handle custom events from widgets
    print('Event: ${event.type} - ${event.payload}');
  },
)
```

## Creating Custom CatalogItems

### Basic Widget

```dart
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:genui/genui.dart';

// Step 1: Define the data schema
final _productCardSchema = S.object(
  description: 'A card displaying product information',
  properties: {
    'title': S.string(description: 'Product name'),
    'price': S.number(description: 'Price in dollars'),
    'imageUrl': S.string(description: 'URL of product image'),
    'description': S.string(description: 'Product description'),
  },
  required: ['title', 'price'],
);

// Step 2: Create the CatalogItem
final productCard = CatalogItem(
  name: 'ProductCard',
  dataSchema: _productCardSchema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String;
    final price = json['price'] as num;
    final imageUrl = json['imageUrl'] as String?;
    final description = json['description'] as String?;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Image.network(imageUrl, height: 150, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  },
);
```

### Interactive Widget with Events

```dart
final _ratingSchema = S.object(
  description: 'A star rating selector',
  properties: {
    'label': S.string(description: 'Label above the rating'),
    'maxStars': S.integer(description: 'Maximum number of stars'),
    'currentRating': S.integer(description: 'Currently selected rating'),
  },
  required: ['maxStars'],
);

final ratingStar = CatalogItem(
  name: 'RatingStar',
  dataSchema: _ratingSchema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final json = data as Map<String, Object?>;
    final label = json['label'] as String?;
    final maxStars = json['maxStars'] as int;
    final currentRating = json['currentRating'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxStars, (index) {
            final starNumber = index + 1;
            return IconButton(
              icon: Icon(
                starNumber <= currentRating
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                // Dispatch event back to AI
                dispatchEvent(
                  GenUiEvent(
                    type: 'rating_selected',
                    payload: {'rating': starNumber},
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  },
);
```

### Widget with Data Binding

```dart
final _textInputSchema = S.object(
  description: 'A text input field bound to data model',
  properties: {
    'label': S.string(description: 'Field label'),
    'placeholder': S.string(description: 'Placeholder text'),
    'bindPath': S.string(description: 'DataModel path to bind value'),
  },
  required: ['bindPath'],
);

final boundTextField = CatalogItem(
  name: 'BoundTextField',
  dataSchema: _textInputSchema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final json = data as Map<String, Object?>;
    final label = json['label'] as String?;
    final placeholder = json['placeholder'] as String?;
    final bindPath = json['bindPath'] as String;
    
    // Get current value from DataModel
    final currentValue = dataContext.getValue(bindPath) as String? ?? '';
    
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
      ),
      controller: TextEditingController(text: currentValue),
      onChanged: (value) {
        // Update DataModel - automatically syncs with AI
        dataContext.setValue(bindPath, value);
      },
    );
  },
);
```

### Widget with Children (Composition)

```dart
final _cardWithActionsSchema = S.object(
  description: 'A card with customizable content and action buttons',
  properties: {
    'title': S.string(description: 'Card title'),
    'content': S.ref('children', description: 'Card body content'),
    'actions': S.ref('children', description: 'Action buttons'),
  },
  required: ['title'],
);

final cardWithActions = CatalogItem(
  name: 'CardWithActions',
  dataSchema: _cardWithActionsSchema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,  // Use this to build child widgets!
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String;
    final contentData = json['content'];
    final actionsData = json['actions'] as List<dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            // Build child content using buildChild
            if (contentData != null)
              buildChild(contentData),
            
            const SizedBox(height: 16),
            
            // Build action buttons
            if (actionsData != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actionsData
                    .map((action) => buildChild(action))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  },
);
```

## Complete App Example

```dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final GenUiManager _genUiManager;
  late final GenUiConversation _genUiConversation;
  
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Messages to display (mix of text and surfaces)
  final _messages = <ChatMessage>[];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Create manager with catalog
    _genUiManager = GenUiManager(
      catalog: CoreCatalogItems.asCatalog().copyWith([
        // Add your custom widgets here
      ]),
    );
    
    // Create content generator
    final contentGenerator = GoogleGenerativeAiContentGenerator(
      apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      systemInstruction: '''
        You are a helpful travel assistant.
        When users ask about trips, generate interactive UI:
        - Use cards to show destination options
        - Use forms for booking details
        - Use carousels for image galleries
        Always prefer generating UI over plain text when appropriate.
      ''',
      tools: _genUiManager.getTools(),
    );
    
    // Create conversation
    _genUiConversation = GenUiConversation(
      genUiManager: _genUiManager,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceRemoved: _onSurfaceRemoved,
      onTextResponse: _onTextResponse,
      onError: _onError,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage.surface(update.surfaceId));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _onSurfaceRemoved(SurfaceRemoved update) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere(
        (msg) => msg.surfaceId == update.surfaceId,
      );
    });
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage.text(text, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _onError(Object error) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage.text('Error: $error', isUser: false));
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage.text(text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();
    
    // Send to AI
    _genUiConversation.sendRequest(UserMessage.text(text));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about travel destinations...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.surfaceId != null) {
      // Render GenUI surface
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GenUiSurface(
          host: _genUiManager,
          surfaceId: message.surfaceId!,
          onEvent: (event) {
            // Handle events from generated UI
            debugPrint('GenUI Event: ${event.type} - ${event.payload}');
          },
        ),
      );
    }
    
    // Render text message
    return Align(
      alignment: message.isUser 
          ? Alignment.centerRight 
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text ?? ''),
      ),
    );
  }
}

// Message model
class ChatMessage {
  final String? text;
  final String? surfaceId;
  final bool isUser;

  ChatMessage._({this.text, this.surfaceId, this.isUser = false});

  factory ChatMessage.text(String text, {required bool isUser}) =>
      ChatMessage._(text: text, isUser: isUser);

  factory ChatMessage.surface(String surfaceId) =>
      ChatMessage._(surfaceId: surfaceId);
}
```

## Schema Builder Reference

The `json_schema_builder` package provides the `S` class for building schemas.

### Primitive Types

```dart
// String
S.string(
  description: 'User name',
  minLength: 1,
  maxLength: 100,
  pattern: r'^[a-zA-Z]+$',  // Regex
)

// Number (double)
S.number(
  description: 'Price in dollars',
  minimum: 0,
  maximum: 1000,
)

// Integer
S.integer(
  description: 'Quantity',
  minimum: 1,
  maximum: 99,
)

// Boolean
S.boolean(
  description: 'Is featured product',
)
```

### Enum

```dart
S.enum$(
  description: 'Priority level',
  values: ['low', 'medium', 'high'],
)
```

### Object

```dart
S.object(
  description: 'User profile',
  properties: {
    'name': S.string(description: 'Full name'),
    'email': S.string(description: 'Email address'),
    'age': S.integer(description: 'Age in years'),
    'isVerified': S.boolean(),
  },
  required: ['name', 'email'],  // Required properties
)
```

### Array

```dart
S.array(
  description: 'List of tags',
  items: S.string(),
  minItems: 1,
  maxItems: 10,
)
```

### Reference (for children)

```dart
// Reference to allow nested widgets
S.ref('children', description: 'Child widgets to render')
```

## System Instructions

The AI needs clear instructions on when/how to use widgets.

### Effective System Instructions

```dart
final systemInstruction = '''
You are a travel booking assistant.

WHEN TO GENERATE UI:
- When showing destination options → Use DestinationCard widgets
- When collecting booking details → Generate BookingForm
- When showing prices → Use PriceComparison widget
- When asking yes/no questions → Use ButtonGroup instead of asking for text

WIDGET GUIDELINES:
- Always include relevant images when available
- Use clear, action-oriented button labels
- Group related form fields together
- Show loading states for async operations

AVAILABLE WIDGETS:
- DestinationCard: Shows destination with image, price, rating
- BookingForm: Date pickers, passenger count, preferences
- PriceComparison: Side-by-side price breakdown
- ButtonGroup: Multiple choice options as buttons
- ImageCarousel: Scrollable image gallery

RESPONSE FORMAT:
- Prefer UI generation over text descriptions
- Only use text for explanations that can't be shown visually
- Always generate complete, valid widget structures
''';
```

## Firebase AI Setup (Production)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// In your widget
final contentGenerator = FirebaseAiContentGenerator(
  systemInstruction: systemInstruction,
  tools: genUiManager.getTools(),
  // Firebase handles API key management
);
```

## Best Practices

### 1. Design Widget Schemas for AI

```dart
// ✅ GOOD - Descriptive, well-constrained
final _schema = S.object(
  description: 'Product card showing item for purchase',
  properties: {
    'title': S.string(
      description: 'Product name, max 50 chars',
      maxLength: 50,
    ),
    'price': S.number(
      description: 'Price in USD, positive number',
      minimum: 0,
    ),
    'category': S.enum$(
      description: 'Product category',
      values: ['electronics', 'clothing', 'home'],
    ),
  },
  required: ['title', 'price'],
);

// ❌ BAD - Vague, no constraints
final _schema = S.object(
  properties: {
    'data': S.string(),
    'value': S.number(),
  },
);
```

### 2. Handle Events Properly

```dart
GenUiSurface(
  host: genUiManager,
  surfaceId: surfaceId,
  onEvent: (event) {
    switch (event.type) {
      case 'add_to_cart':
        final productId = event.payload['productId'];
        _handleAddToCart(productId);
        break;
      case 'select_date':
        final date = event.payload['date'];
        _handleDateSelection(date);
        break;
      default:
        debugPrint('Unknown event: ${event.type}');
    }
  },
)
```

### 3. Provide Good Fallbacks

```dart
widgetBuilder: ({required data, ...}) {
  final json = data as Map<String, Object?>;
  
  // Safely extract with defaults
  final title = json['title'] as String? ?? 'Untitled';
  final price = (json['price'] as num?)?.toDouble() ?? 0.0;
  final imageUrl = json['imageUrl'] as String?;
  
  return Card(
    child: Column(
      children: [
        // Handle missing image gracefully
        if (imageUrl != null)
          Image.network(
            imageUrl,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          )
        else
          const Icon(Icons.image, size: 100),
        // ...
      ],
    ),
  );
}
```

### 4. Keep Catalogs Focused

```dart
// Domain-specific catalogs
class TravelCatalog {
  static Catalog get catalog => Catalog(components: [
    destinationCard,
    flightCard,
    hotelCard,
    bookingForm,
    itineraryTimeline,
  ]);
}

class EcommerceCatalog {
  static Catalog get catalog => Catalog(components: [
    productCard,
    cartItem,
    checkoutForm,
    orderSummary,
    paymentMethod,
  ]);
}

// Use the appropriate catalog
final genUiManager = GenUiManager(
  catalog: CoreCatalogItems.asCatalog().copyWith(
    TravelCatalog.catalog.components,
  ),
);
```

## Debugging

### Enable Logging

```dart
import 'package:logging/logging.dart';

final logger = configureGenUiLogging(level: Level.ALL);

void main() {
  logger.onRecord.listen((record) {
    debugPrint('[${record.loggerName}] ${record.message}');
  });
  
  runApp(const MyApp());
}
```

### Common Issues

**Issue: Widgets not rendering**
- Check that widget name in system instruction matches CatalogItem name exactly
- Verify schema is valid and required fields are provided
- Check console for parsing errors

**Issue: Events not firing**
- Ensure `dispatchEvent` is called in widget builder
- Check `onEvent` callback is set on GenUiSurface
- Verify event type matches expected string

**Issue: Data binding not updating**
- Use `dataContext.getValue()` and `dataContext.setValue()`
- Ensure path strings match between AI response and code
- Check DataModel is being updated correctly

## Limitations (Alpha)

- No conversation persistence (state lost on app close)
- Boilerplate required for custom CatalogItems
- Core catalog items may have bugs
- API names will change in future versions
- No streaming UI rendering yet (full response required)
