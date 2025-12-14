# Catalog Design Pattern Guide

Best practices for designing widget catalogs for Claude-powered GenUI.

## Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [Schema Best Practices](#schema-best-practices)
- [Naming Conventions](#naming-conventions)
- [Widget Patterns](#widget-patterns)
- [Data Binding](#data-binding)
- [Event Handling](#event-handling)
- [Testing Catalogs](#testing-catalogs)
- [Performance Considerations](#performance-considerations)
- [Common Patterns](#common-patterns)

---

## Overview

A widget catalog defines the UI components that Claude can generate. Well-designed catalogs enable Claude to create intuitive, functional UIs.

### Key Concepts

- **CatalogItem**: Defines a widget with schema and builder
- **Schema**: JSON Schema describing widget data structure
- **Builder**: Function that creates Flutter widget from data

---

## Design Principles

### 1. Keep It Simple

Claude works best with focused, single-purpose widgets.

```dart
// Good: Single purpose
CatalogItem(
  name: 'text_display',
  dataSchema: S.object(
    properties: {'text': S.string()},
  ),
  widgetBuilder: (ctx) => Text(ctx.data['text']),
)

// Avoid: Multi-purpose "god widget"
CatalogItem(
  name: 'universal_component',
  dataSchema: S.object(
    properties: {
      'type': S.string(), // text, button, card, list, etc.
      'data': S.object(),
      // 20 more optional properties...
    },
  ),
)
```

### 2. Clear Descriptions

Help Claude understand when to use each widget.

```dart
CatalogItem(
  name: 'action_button',
  dataSchema: S.object(
    description: 'A primary action button for user interactions. '
        'Use for main CTAs like "Submit", "Continue", "Save".',
    properties: {
      'label': S.string(description: 'Button text, keep it short (1-3 words)'),
      'action': S.string(description: 'Action ID sent on tap'),
      'variant': S.string(
        description: 'Visual style: "primary" for main actions, '
            '"secondary" for alternatives, "danger" for destructive actions',
      ),
    },
  ),
)
```

### 3. Sensible Defaults

Make widgets work with minimal data.

```dart
widgetBuilder: (ctx) {
  final data = ctx.data as Map<String, dynamic>;
  return ElevatedButton(
    onPressed: () => ctx.onAction(data['action'] ?? 'button_tap'),
    style: _getStyle(data['variant'] ?? 'primary'),
    child: Text(data['label'] ?? 'Submit'),
  );
}
```

### 4. Composition Over Complexity

Create small widgets that combine well.

```dart
// Good: Composable widgets
'info_card'     // Just the card container
'card_header'   // Header section
'card_content'  // Content section
'card_actions'  // Action buttons

// Avoid: Monolithic widget
'mega_card_with_everything'
```

---

## Schema Best Practices

### Required vs Optional Fields

Mark essential fields as required, provide defaults for optional ones.

```dart
S.object(
  properties: {
    'title': S.string(description: 'Required card title'),
    'subtitle': S.string(description: 'Optional subtitle'),
    'icon': S.string(description: 'Optional icon name'),
  },
  required: ['title'], // Only title is required
)
```

### Use Enums for Constrained Values

```dart
S.object(
  properties: {
    'size': S.string(
      description: 'Button size',
      enumValues: ['small', 'medium', 'large'],
    ),
    'color': S.string(
      description: 'Button color scheme',
      enumValues: ['primary', 'secondary', 'danger', 'success'],
    ),
  },
)
```

### Type Constraints

Use appropriate types and constraints.

```dart
properties: {
  'name': S.string(minLength: 1, maxLength: 100),
  'age': S.integer(minimum: 0, maximum: 150),
  'price': S.number(minimum: 0),
  'isActive': S.boolean(),
  'tags': S.array(items: S.string(), maxItems: 10),
}
```

### Nested Objects

For complex data, use nested schemas.

```dart
S.object(
  properties: {
    'user': S.object(
      description: 'User profile information',
      properties: {
        'name': S.string(),
        'avatar': S.string(description: 'URL to avatar image'),
        'verified': S.boolean(),
      },
      required: ['name'],
    ),
    'message': S.string(),
    'timestamp': S.string(description: 'ISO 8601 timestamp'),
  },
)
```

---

## Naming Conventions

### Widget Names

Use snake_case, descriptive names.

```dart
// Good names
'user_profile_card'
'action_button'
'data_table'
'navigation_menu'
'status_badge'

// Avoid
'Card1'           // Not descriptive
'userProfileCard' // Wrong case
'btn'             // Too short
'component'       // Too generic
```

### Property Names

Use snake_case, meaningful names.

```dart
// Good
'first_name'
'created_at'
'is_active'
'item_count'

// Avoid
'fn'          // Cryptic
'firstName'   // Wrong case
'x'           // Meaningless
```

### Action Names

Use verb_noun pattern.

```dart
// Good
'submit_form'
'delete_item'
'open_modal'
'navigate_back'
'refresh_data'

// Avoid
'click'       // Too generic
'action1'     // Meaningless
```

---

## Widget Patterns

### Simple Display Widget

```dart
CatalogItem(
  name: 'info_text',
  dataSchema: S.object(
    description: 'Displays informational text with optional icon',
    properties: {
      'text': S.string(description: 'The text to display'),
      'icon': S.string(description: 'Optional Material icon name'),
      'style': S.string(
        description: 'Text style',
        enumValues: ['body', 'caption', 'title'],
      ),
    },
    required: ['text'],
  ),
  widgetBuilder: (ctx) {
    final data = ctx.data as Map<String, dynamic>;
    final text = data['text'] as String? ?? '';
    final icon = data['icon'] as String?;
    final style = data['style'] as String? ?? 'body';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(_parseIcon(icon)),
          const SizedBox(width: 8),
        ],
        Text(text, style: _getTextStyle(style)),
      ],
    );
  },
)
```

### Interactive Widget

```dart
CatalogItem(
  name: 'toggle_switch',
  dataSchema: S.object(
    description: 'A toggle switch for boolean settings',
    properties: {
      'label': S.string(description: 'Label text'),
      'value': S.boolean(description: 'Current state'),
      'on_change': S.string(description: 'Action ID when toggled'),
      'disabled': S.boolean(description: 'Whether switch is disabled'),
    },
    required: ['label', 'on_change'],
  ),
  widgetBuilder: (ctx) {
    final data = ctx.data as Map<String, dynamic>;

    return SwitchListTile(
      title: Text(data['label'] as String? ?? ''),
      value: data['value'] as bool? ?? false,
      onChanged: data['disabled'] == true
          ? null
          : (value) => ctx.onAction(
                data['on_change'] as String,
                payload: {'value': value},
              ),
    );
  },
)
```

### Container Widget

```dart
CatalogItem(
  name: 'card_container',
  dataSchema: S.object(
    description: 'A Material card container for grouping content',
    properties: {
      'padding': S.number(description: 'Inner padding (default: 16)'),
      'elevation': S.number(description: 'Shadow elevation (default: 1)'),
    },
  ),
  // Children are handled by GenUI surface composition
  widgetBuilder: (ctx) {
    final data = ctx.data as Map<String, dynamic>;

    return Card(
      elevation: (data['elevation'] as num?)?.toDouble() ?? 1,
      child: Padding(
        padding: EdgeInsets.all(
          (data['padding'] as num?)?.toDouble() ?? 16,
        ),
        child: ctx.child, // Child surface content
      ),
    );
  },
)
```

### List Widget

```dart
CatalogItem(
  name: 'item_list',
  dataSchema: S.object(
    description: 'Displays a list of items',
    properties: {
      'items': S.array(
        description: 'List items',
        items: S.object(
          properties: {
            'id': S.string(),
            'title': S.string(),
            'subtitle': S.string(),
            'on_tap': S.string(),
          },
          required: ['id', 'title'],
        ),
      ),
      'dividers': S.boolean(description: 'Show dividers between items'),
    },
    required: ['items'],
  ),
  widgetBuilder: (ctx) {
    final data = ctx.data as Map<String, dynamic>;
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dividers = data['dividers'] as bool? ?? true;

    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          dividers ? const Divider() : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item['title'] as String? ?? ''),
          subtitle: item['subtitle'] != null
              ? Text(item['subtitle'] as String)
              : null,
          onTap: item['on_tap'] != null
              ? () => ctx.onAction(item['on_tap'] as String)
              : null,
        );
      },
    );
  },
)
```

---

## Data Binding

### Reading Data

```dart
widgetBuilder: (ctx) {
  // ctx.data contains the widget data
  final data = ctx.data as Map<String, dynamic>;

  // Access with null safety
  final title = data['title'] as String? ?? 'Default';
  final count = data['count'] as int? ?? 0;
  final items = (data['items'] as List?)?.cast<String>() ?? [];

  return MyWidget(title: title, count: count, items: items);
}
```

### Dynamic Data Updates

```dart
// Data model updates trigger widget rebuilds automatically
// Claude can send data_model_update events to change widget data
```

### Accessing Context

```dart
widgetBuilder: (ctx) {
  // Surface ID for this widget instance
  final surfaceId = ctx.surfaceId;

  // Conversation context (if available)
  final conversationId = ctx.conversationId;

  // Parent data (if nested)
  final parentData = ctx.parentData;

  return MyWidget();
}
```

---

## Event Handling

### Simple Actions

```dart
onTap: () => ctx.onAction('button_clicked')
```

### Actions with Payload

```dart
onTap: () => ctx.onAction(
  'item_selected',
  payload: {
    'item_id': itemId,
    'timestamp': DateTime.now().toIso8601String(),
  },
)
```

### Form Submissions

```dart
CatalogItem(
  name: 'login_form',
  dataSchema: S.object(
    properties: {
      'on_submit': S.string(description: 'Action when form submitted'),
    },
  ),
  widgetBuilder: (ctx) {
    final data = ctx.data as Map<String, dynamic>;
    final controller = TextEditingController();

    return Column(
      children: [
        TextField(controller: controller),
        ElevatedButton(
          onPressed: () => ctx.onAction(
            data['on_submit'] as String? ?? 'form_submit',
            payload: {'username': controller.text},
          ),
          child: Text('Login'),
        ),
      ],
    );
  },
)
```

---

## Testing Catalogs

### Unit Test Widget Builder

```dart
void main() {
  group('InfoCard', () {
    test('renders with required data', () {
      final item = catalog.items.firstWhere((i) => i.name == 'info_card');

      final widget = item.widgetBuilder(
        MockItemContext(
          data: {'title': 'Test Title'},
        ),
      );

      expect(widget, isA<Card>());
    });

    test('handles missing optional data', () {
      final item = catalog.items.firstWhere((i) => i.name == 'info_card');

      // Should not throw with only required fields
      expect(
        () => item.widgetBuilder(
          MockItemContext(data: {'title': 'Test'}),
        ),
        returnsNormally,
      );
    });
  });
}
```

### Widget Test

```dart
testWidgets('action_button sends action on tap', (tester) async {
  String? receivedAction;
  Map<String, dynamic>? receivedPayload;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: catalog.items
            .firstWhere((i) => i.name == 'action_button')
            .widgetBuilder(
              MockItemContext(
                data: {
                  'label': 'Submit',
                  'action': 'submit_form',
                },
                onAction: (action, {payload}) {
                  receivedAction = action;
                  receivedPayload = payload;
                },
              ),
            ),
      ),
    ),
  );

  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(receivedAction, equals('submit_form'));
});
```

### Schema Validation Test

```dart
test('schema is valid JSON Schema', () {
  for (final item in catalog.items) {
    final schema = item.dataSchema.toJson();

    // Basic structure validation
    expect(schema['type'], equals('object'));
    expect(schema['properties'], isA<Map>());

    // Required fields exist in properties
    final required = schema['required'] as List?;
    final properties = schema['properties'] as Map;

    for (final field in required ?? []) {
      expect(properties.containsKey(field), isTrue,
          reason: '$field is required but not in properties');
    }
  }
});
```

---

## Performance Considerations

### Avoid Heavy Initialization

```dart
// Bad: Heavy work in builder
widgetBuilder: (ctx) {
  final heavyData = processLargeDataset(ctx.data); // Expensive!
  return DataTable(data: heavyData);
}

// Good: Lazy loading
widgetBuilder: (ctx) {
  return FutureBuilder(
    future: processLargeDatasetAsync(ctx.data),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      return DataTable(data: snapshot.data!);
    },
  );
}
```

### Use Keys for Lists

```dart
widgetBuilder: (ctx) {
  final items = ctx.data['items'] as List;

  return Column(
    children: items.map((item) {
      return MyWidget(
        key: ValueKey(item['id']), // Enable efficient updates
        data: item,
      );
    }).toList(),
  );
}
```

### Limit Catalog Size

Keep catalogs focused on the use case:

```dart
// Good: Focused catalog for a chat app
class ChatCatalog extends Catalog {
  static final items = [
    'message_bubble',
    'typing_indicator',
    'timestamp_divider',
    'user_avatar',
    'action_buttons',
  ];
}

// Avoid: Kitchen sink catalog
class EverythingCatalog extends Catalog {
  static final items = [
    // 50+ widgets for every possible use case
  ];
}
```

---

## Common Patterns

### Form Widgets

```dart
// Text input
'text_input': S.object(
  properties: {
    'label': S.string(),
    'placeholder': S.string(),
    'value': S.string(),
    'error': S.string(),
    'on_change': S.string(),
  },
)

// Dropdown
'dropdown': S.object(
  properties: {
    'label': S.string(),
    'options': S.array(items: S.object(
      properties: {
        'value': S.string(),
        'label': S.string(),
      },
    )),
    'selected': S.string(),
    'on_change': S.string(),
  },
)
```

### Layout Widgets

```dart
// Horizontal row
'row': S.object(
  properties: {
    'spacing': S.number(),
    'alignment': S.string(enumValues: ['start', 'center', 'end', 'between']),
  },
)

// Vertical column
'column': S.object(
  properties: {
    'spacing': S.number(),
    'alignment': S.string(enumValues: ['start', 'center', 'end']),
  },
)
```

### Feedback Widgets

```dart
// Loading
'loading': S.object(
  properties: {
    'message': S.string(),
    'progress': S.number(minimum: 0, maximum: 1),
  },
)

// Error
'error_message': S.object(
  properties: {
    'title': S.string(),
    'message': S.string(),
    'retry_action': S.string(),
  },
)

// Success
'success_message': S.object(
  properties: {
    'title': S.string(),
    'message': S.string(),
    'dismiss_action': S.string(),
  },
)
```

---

## Checklist

When designing a catalog:

- [ ] Each widget has a clear, single purpose
- [ ] Descriptions explain when to use each widget
- [ ] Required fields are minimal
- [ ] Optional fields have sensible defaults
- [ ] Names follow snake_case convention
- [ ] Actions use verb_noun pattern
- [ ] Enums used for constrained values
- [ ] Schemas are valid JSON Schema
- [ ] Widget builders handle missing data gracefully
- [ ] Keys used for list items
- [ ] Heavy work is lazy-loaded
- [ ] Tests cover widget builders and schemas
