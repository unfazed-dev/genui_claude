# GenUI Patterns & Schema Reference

## Schema Builder Quick Reference

```dart
import 'package:json_schema_builder/json_schema_builder.dart';

// All schemas use the S class
```

### Primitive Types

```dart
// String
S.string()
S.string(description: 'User name')
S.string(minLength: 1, maxLength: 100)
S.string(pattern: r'^[a-zA-Z]+$')

// Number (floating point)
S.number()
S.number(description: 'Price in USD')
S.number(minimum: 0, maximum: 1000)
S.number(exclusiveMinimum: 0)

// Integer
S.integer()
S.integer(description: 'Quantity')
S.integer(minimum: 1, maximum: 99)

// Boolean
S.boolean()
S.boolean(description: 'Is active')
```

### Complex Types

```dart
// Enum
S.enum$(
  values: ['low', 'medium', 'high'],
  description: 'Priority level',
)

// Object
S.object(
  description: 'User profile',
  properties: {
    'name': S.string(),
    'age': S.integer(),
    'email': S.string(),
  },
  required: ['name', 'email'],
)

// Array
S.array(
  items: S.string(),
  description: 'List of tags',
)

S.array(
  items: S.object(properties: {
    'id': S.integer(),
    'name': S.string(),
  }),
  minItems: 1,
  maxItems: 10,
)

// Reference (for nested widgets)
S.ref('children', description: 'Child widgets')
```

## CatalogItem Builder Parameters

```dart
CatalogItem(
  name: 'WidgetName',           // Name AI uses to reference
  dataSchema: schema,           // JSON schema for properties
  widgetBuilder: ({
    required data,              // Map<String, Object?> from AI
    required id,                // Unique widget instance ID
    required buildChild,        // Function to build nested widgets
    required dispatchEvent,     // Function to send events to AI
    required context,           // BuildContext
    required dataContext,       // DataModel access
  }) {
    // Return Widget
  },
);
```

## Data Extraction Patterns

```dart
// Required string
final title = json['title'] as String;

// Optional string
final subtitle = json['subtitle'] as String?;

// String with default
final label = json['label'] as String? ?? 'Default';

// Numbers
final price = (json['price'] as num).toDouble();
final count = json['count'] as int;
final optionalNum = (json['value'] as num?)?.toDouble();

// Boolean
final isActive = json['isActive'] as bool? ?? false;

// List
final items = (json['items'] as List<dynamic>?)
    ?.cast<Map<String, Object?>>() ?? [];

// Nested object
final address = json['address'] as Map<String, Object?>?;
final city = address?['city'] as String?;
```

## Event Dispatching

```dart
// Simple event
dispatchEvent(GenUiEvent(
  type: 'button_clicked',
  payload: {},
));

// Event with data
dispatchEvent(GenUiEvent(
  type: 'item_selected',
  payload: {
    'itemId': item.id,
    'itemName': item.name,
  },
));

// Event with current form data
dispatchEvent(GenUiEvent(
  type: 'form_submitted',
  payload: {
    'name': nameController.text,
    'email': emailController.text,
  },
));
```

## DataModel Binding

```dart
// Read from DataModel
final currentValue = dataContext.getValue('/user/name') as String?;

// Write to DataModel (triggers rebuild of bound widgets)
dataContext.setValue('/user/name', newValue);

// JSON binding format from AI
{
  "TextField": {
    "value": {"path": "/form/email"},      // Bound
    "label": {"literalString": "Email"}     // Static
  }
}
```

## Common Widget Patterns

### Display Card

```dart
final displayCard = CatalogItem(
  name: 'DisplayCard',
  dataSchema: S.object(
    properties: {
      'title': S.string(description: 'Card title'),
      'subtitle': S.string(description: 'Optional subtitle'),
      'imageUrl': S.string(description: 'Image URL'),
      'body': S.string(description: 'Card body text'),
    },
    required: ['title'],
  ),
  widgetBuilder: ({required data, required context, ...}) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String;
    final subtitle = json['subtitle'] as String?;
    final imageUrl = json['imageUrl'] as String?;
    final body = json['body'] as String?;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 64),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                if (body != null) ...[
                  const SizedBox(height: 12),
                  Text(body),
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

### Action Button Group

```dart
final buttonGroup = CatalogItem(
  name: 'ButtonGroup',
  dataSchema: S.object(
    properties: {
      'title': S.string(description: 'Group title/question'),
      'options': S.array(
        items: S.object(
          properties: {
            'label': S.string(),
            'value': S.string(),
            'icon': S.string(description: 'Optional icon name'),
          },
          required: ['label', 'value'],
        ),
        description: 'Button options',
      ),
    },
    required: ['options'],
  ),
  widgetBuilder: ({required data, required dispatchEvent, required context, ...}) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String?;
    final options = (json['options'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final label = option['label'] as String;
            final value = option['value'] as String;
            
            return FilledButton.tonal(
              onPressed: () => dispatchEvent(GenUiEvent(
                type: 'option_selected',
                payload: {'value': value, 'label': label},
              )),
              child: Text(label),
            );
          }).toList(),
        ),
      ],
    );
  },
);
```

### Form Input

```dart
final formInput = CatalogItem(
  name: 'FormInput',
  dataSchema: S.object(
    properties: {
      'label': S.string(description: 'Field label'),
      'placeholder': S.string(description: 'Placeholder text'),
      'fieldType': S.enum$(
        values: ['text', 'email', 'number', 'password', 'multiline'],
        description: 'Input type',
      ),
      'bindPath': S.string(description: 'DataModel path'),
      'required': S.boolean(description: 'Is required'),
    },
    required: ['label', 'bindPath'],
  ),
  widgetBuilder: ({
    required data,
    required dataContext,
    required context,
    ...
  }) {
    final json = data as Map<String, Object?>;
    final label = json['label'] as String;
    final placeholder = json['placeholder'] as String?;
    final fieldType = json['fieldType'] as String? ?? 'text';
    final bindPath = json['bindPath'] as String;
    final isRequired = json['required'] as bool? ?? false;
    
    final currentValue = dataContext.getValue(bindPath) as String? ?? '';
    
    return TextField(
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: currentValue),
      keyboardType: _keyboardType(fieldType),
      obscureText: fieldType == 'password',
      maxLines: fieldType == 'multiline' ? 4 : 1,
      onChanged: (value) => dataContext.setValue(bindPath, value),
    );
  },
);

TextInputType _keyboardType(String fieldType) => switch (fieldType) {
  'email' => TextInputType.emailAddress,
  'number' => TextInputType.number,
  'multiline' => TextInputType.multiline,
  _ => TextInputType.text,
};
```

### List/Carousel

```dart
final itemCarousel = CatalogItem(
  name: 'ItemCarousel',
  dataSchema: S.object(
    properties: {
      'title': S.string(description: 'Section title'),
      'items': S.array(
        items: S.object(
          properties: {
            'id': S.string(),
            'title': S.string(),
            'subtitle': S.string(),
            'imageUrl': S.string(),
          },
          required: ['id', 'title'],
        ),
      ),
    },
    required: ['items'],
  ),
  widgetBuilder: ({
    required data,
    required dispatchEvent,
    required context,
    ...
  }) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String?;
    final items = (json['items'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id'] as String;
              final itemTitle = item['title'] as String;
              final subtitle = item['subtitle'] as String?;
              final imageUrl = item['imageUrl'] as String?;
              
              return GestureDetector(
                onTap: () => dispatchEvent(GenUiEvent(
                  type: 'item_tapped',
                  payload: {'id': id, 'title': itemTitle},
                )),
                child: SizedBox(
                  width: 140,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          Image.network(
                            imageUrl,
                            height: 80,
                            width: 140,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  },
);
```

### Confirmation Dialog Content

```dart
final confirmationContent = CatalogItem(
  name: 'ConfirmationContent',
  dataSchema: S.object(
    properties: {
      'title': S.string(description: 'Dialog title'),
      'message': S.string(description: 'Confirmation message'),
      'confirmLabel': S.string(description: 'Confirm button text'),
      'cancelLabel': S.string(description: 'Cancel button text'),
      'isDestructive': S.boolean(description: 'Is destructive action'),
    },
    required: ['title', 'message'],
  ),
  widgetBuilder: ({
    required data,
    required dispatchEvent,
    required context,
    ...
  }) {
    final json = data as Map<String, Object?>;
    final title = json['title'] as String;
    final message = json['message'] as String;
    final confirmLabel = json['confirmLabel'] as String? ?? 'Confirm';
    final cancelLabel = json['cancelLabel'] as String? ?? 'Cancel';
    final isDestructive = json['isDestructive'] as bool? ?? false;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(message),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => dispatchEvent(GenUiEvent(
                type: 'cancelled',
                payload: {},
              )),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () => dispatchEvent(GenUiEvent(
                type: 'confirmed',
                payload: {},
              )),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ],
    );
  },
);
```

## System Instruction Templates

### E-commerce Assistant

```
You are a shopping assistant for an online store.

WIDGET USAGE:
- ProductCard: Show individual products with image, title, price
- ItemCarousel: Display product recommendations horizontally
- ButtonGroup: Offer category/filter choices
- FormInput: Collect shipping/payment details
- ConfirmationContent: Confirm purchases

GUIDELINES:
- Always show product images when available
- Display prices prominently
- Use ButtonGroup for multiple choice questions
- Generate complete forms for checkout flows
- Prefer visual UI over text descriptions

IMPORTANT:
- Never show out-of-stock items without indication
- Always include action buttons on product cards
- Group related products in carousels
```

### Travel Booking Assistant

```
You are a travel booking assistant.

WIDGET USAGE:
- DisplayCard: Show destination information
- ItemCarousel: Display hotel/flight options
- FormInput: Collect dates, passenger info
- ButtonGroup: Offer travel class, preferences
- ConfirmationContent: Confirm bookings

FLOW PATTERNS:
1. Destination selection → Show destination cards
2. Date selection → Generate date picker form
3. Options display → Use carousel for hotels/flights
4. Details collection → Multi-field form
5. Confirmation → Summary card with confirm button

ALWAYS:
- Include prices in local currency
- Show ratings/reviews when available
- Indicate availability status
- Provide clear next-step buttons
```

### Support Chat Assistant

```
You are a customer support assistant.

WIDGET USAGE:
- DisplayCard: Show help articles, FAQs
- ButtonGroup: Quick reply options, categories
- FormInput: Collect issue details
- ConfirmationContent: Confirm actions

INTERACTION PATTERNS:
- Start with category selection buttons
- Show relevant FAQ cards based on selection
- Collect details via forms if needed
- Confirm resolutions with user

TONE:
- Use friendly, helpful language
- Provide clear action buttons
- Show progress indicators for multi-step flows
```

## Event Handling Patterns

```dart
GenUiSurface(
  host: genUiManager,
  surfaceId: surfaceId,
  onEvent: (event) async {
    switch (event.type) {
      // Navigation events
      case 'navigate_to':
        final route = event.payload['route'] as String;
        Navigator.pushNamed(context, route);
        break;
      
      // Selection events
      case 'item_selected':
        final itemId = event.payload['id'] as String;
        await _handleItemSelection(itemId);
        // Send follow-up to AI
        _genUiConversation.sendRequest(
          UserMessage.text('Selected item: $itemId'),
        );
        break;
      
      // Form events
      case 'form_submitted':
        final formData = event.payload;
        await _processForm(formData);
        break;
      
      // Confirmation events
      case 'confirmed':
        await _executeConfirmedAction();
        break;
      case 'cancelled':
        _showCancellationMessage();
        break;
      
      default:
        debugPrint('Unhandled event: ${event.type}');
    }
  },
)
```

## Debugging Checklist

□ Widget name in CatalogItem matches system instruction exactly (case-sensitive)
□ Required schema properties have values in AI response
□ Schema types match expected Dart types
□ dispatchEvent is called for interactive elements
□ onEvent handler processes all expected event types
□ DataModel paths are consistent between AI response and code
□ Error handling in widgetBuilder for malformed data
□ Logging enabled to see AI responses and errors
