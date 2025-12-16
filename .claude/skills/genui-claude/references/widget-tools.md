# Widget Tools

How widgets are converted to Claude tools and how A2UI control tools work.

## CatalogToolBridge

Converts GenUI Catalog items to Claude tool schemas.

### Basic Usage

```dart
import 'package:genui_claude/genui_claude.dart';

// From catalog items list
final tools = CatalogToolBridge.fromItems(catalog.items.toList());

// From Catalog instance
final tools = CatalogToolBridge.fromCatalog(myCatalog);

// With A2UI control tools (recommended)
final widgetTools = CatalogToolBridge.fromCatalog(myCatalog);
final allTools = CatalogToolBridge.withA2uiTools(widgetTools);
// Returns: [begin_rendering, surface_update, data_model_update, delete_surface, ...widgets]
```

### Tool Schema Output Format

```dart
// Input: CatalogItem
CatalogItem(
  name: 'info_card',
  dataSchema: S.object(
    description: 'Display information in a card format',
    properties: {
      'title': S.string(description: 'Card title'),
      'content': S.string(description: 'Card body text'),
      'icon': S.string(description: 'Optional icon name'),
    },
    required: ['title', 'content'],
  ),
  widgetBuilder: (context) => InfoCard(...),
)

// Output: A2uiToolSchema (→ Claude tool format)
{
  'name': 'info_card',
  'description': 'Display information in a card format',
  'input_schema': {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Card title'},
      'content': {'type': 'string', 'description': 'Card body text'},
      'icon': {'type': 'string', 'description': 'Optional icon name'},
    },
    'required': ['title', 'content'],
  },
}
```

## A2UI Tool Converter Utilities

The `A2uiToolConverter` class provides utilities for schema validation, instruction generation, and tool format conversion.

### Convert Schemas to Claude Tools

```dart
import 'package:a2ui_claude/a2ui_claude.dart';

// Convert A2uiToolSchema list to Claude API format
final widgetSchemas = [
  A2uiToolSchema(
    name: 'info_card',
    description: 'Display information in a card',
    inputSchema: {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'content': {'type': 'string'},
      },
      'required': ['title', 'content'],
    },
  ),
];

final claudeTools = A2uiToolConverter.toClaudeTools(widgetSchemas);
// Returns List<Map<String, dynamic>> ready for Claude API
```

### Generate System Prompt Instructions

Automatically generate widget documentation for the system prompt:

```dart
final instructions = A2uiToolConverter.generateToolInstructions(widgetSchemas);

// Output:
// "Available widgets:
//  - info_card: Display information in a card
//    Required: title, content
//  - action_button: A clickable button that triggers an action
//    Required: label, action"

// Use in system prompt
final systemPrompt = '''
You are a UI assistant.

$instructions

When generating UI:
1. Always call begin_rendering first
2. Use surface_update to provide the widget tree
''';
```

### Validate Tool Input

Validate Claude's tool input against the schema before processing:

```dart
// Validate tool input
final validation = A2uiToolConverter.validateToolInput(
  'info_card',
  {'title': 'Hello'},  // Missing 'content' which is required
  widgetSchemas,
);

if (!validation.isValid) {
  print('Validation errors: ${validation.errors}');
  // Output: ["Missing required property: content"]
}

// In stream handler
case A2uiMessageEvent(:final message):
  if (message is SurfaceUpdateData) {
    for (final widget in message.widgets) {
      final validation = A2uiToolConverter.validateToolInput(
        widget.type,
        widget.properties,
        widgetSchemas,
      );
      if (!validation.isValid) {
        log('Invalid widget: ${validation.errors}');
      }
    }
  }
```

### ValidationResult Structure

```dart
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;  // Non-fatal issues
}
```

### Full Workflow Example

```dart
// 1. Define widget schemas
final widgetSchemas = [
  A2uiToolSchema(
    name: 'info_card',
    description: 'Display information in a card',
    inputSchema: {...},
  ),
  A2uiToolSchema(
    name: 'action_button',
    description: 'A clickable button',
    inputSchema: {...},
  ),
];

// 2. Combine with A2UI control tools
final allTools = A2uiControlTools.withWidgetTools(widgetSchemas);

// 3. Generate instructions
final instructions = A2uiToolConverter.generateToolInstructions(widgetSchemas);

// 4. Create system prompt
final systemPrompt = '''
You are a helpful UI assistant.

$instructions

Guidelines:
- Use begin_rendering before surface_update
- Match widget types exactly
''';

// 5. In request handler, validate inputs
final validation = A2uiToolConverter.validateToolInput(
  toolName,
  toolInput,
  widgetSchemas,
);
```

## A2UI Control Tools

Pre-defined tools Claude uses to manage UI surfaces.

### begin_rendering

Signals the start of UI generation for a surface.

```dart
A2uiControlTools.beginRendering
```

**Schema:**
```json
{
  "name": "begin_rendering",
  "description": "Signal the start of UI generation for a surface. Call this before surface_update.",
  "input_schema": {
    "type": "object",
    "properties": {
      "surfaceId": {
        "type": "string",
        "description": "Unique identifier for the UI surface"
      },
      "parentSurfaceId": {
        "type": "string",
        "description": "Optional parent surface for nested UIs"
      },
      "root": {
        "type": "string",
        "description": "Root element ID, defaults to 'root'"
      },
      "metadata": {
        "type": "object",
        "description": "Additional surface metadata for custom handling"
      }
    },
    "required": ["surfaceId"]
  }
}
```

**Example Claude call:**
```json
{
  "type": "tool_use",
  "name": "begin_rendering",
  "input": {
    "surfaceId": "card_123"
  }
}
```

**Example with metadata:**
```json
{
  "type": "tool_use",
  "name": "begin_rendering",
  "input": {
    "surfaceId": "form_456",
    "root": "form_root",
    "metadata": {
      "source": "user_request",
      "priority": "high"
    }
  }
}
```

### surface_update

Updates the widget tree of a surface.

```dart
A2uiControlTools.surfaceUpdate
```

**Schema:**
```json
{
  "name": "surface_update",
  "description": "Update the widget tree of a surface with components from the catalog.",
  "input_schema": {
    "type": "object",
    "properties": {
      "surfaceId": {
        "type": "string",
        "description": "The surface to update"
      },
      "widgets": {
        "type": "array",
        "description": "Array of widget nodes to render",
        "items": {
          "type": "object",
          "properties": {
            "type": {"type": "string"},
            "properties": {"type": "object"},
            "children": {"type": "array"}
          }
        }
      },
      "append": {
        "type": "boolean",
        "description": "If true, append to existing widgets instead of replacing"
      }
    },
    "required": ["surfaceId", "widgets"]
  }
}
```

**Example Claude call:**
```json
{
  "type": "tool_use",
  "name": "surface_update",
  "input": {
    "surfaceId": "card_123",
    "widgets": [
      {
        "type": "info_card",
        "properties": {
          "title": "Welcome",
          "content": "Hello, world!"
        }
      }
    ]
  }
}
```

### data_model_update

Updates bound data values.

```dart
A2uiControlTools.dataModelUpdate
```

**Schema:**
```json
{
  "name": "data_model_update",
  "description": "Update data model values that are bound to UI components.",
  "input_schema": {
    "type": "object",
    "properties": {
      "updates": {
        "type": "object",
        "description": "Key-value pairs to update in the data model"
      },
      "scope": {
        "type": "string",
        "description": "Optional scope for the updates"
      }
    },
    "required": ["updates"]
  }
}
```

### delete_surface

Removes a UI surface.

```dart
A2uiControlTools.deleteSurface
```

**Schema:**
```json
{
  "name": "delete_surface",
  "description": "Delete a UI surface and optionally its children.",
  "input_schema": {
    "type": "object",
    "properties": {
      "surfaceId": {
        "type": "string",
        "description": "The surface to delete"
      },
      "cascade": {
        "type": "boolean",
        "description": "If true, also delete child surfaces"
      }
    },
    "required": ["surfaceId"]
  }
}
```

### All Control Tools

```dart
// Get all control tools
final controlTools = A2uiControlTools.all;
// Returns: [beginRendering, surfaceUpdate, dataModelUpdate, deleteSurface]
```

## Schema Conversion Reference

### Supported Schema Types

| json_schema_builder | JSON Schema Output |
|---------------------|-------------------|
| `S.string()` | `{"type": "string"}` |
| `S.number()` | `{"type": "number"}` |
| `S.integer()` | `{"type": "integer"}` |
| `S.boolean()` | `{"type": "boolean"}` |
| `S.object()` | `{"type": "object", "properties": {...}}` |
| `S.array()` | `{"type": "array", "items": {...}}` |
| `S.enum$()` | `{"type": "string", "enum": [...]}` |
| `S.ref()` | `{"$ref": "..."}` (for children) |

### Complex Schema Example

```dart
// Input schema
final formSchema = S.object(
  description: 'A dynamic form with multiple fields',
  properties: {
    'title': S.string(
      description: 'Form title',
      minLength: 1,
      maxLength: 100,
    ),
    'fields': S.array(
      description: 'Form fields',
      items: S.object(
        properties: {
          'name': S.string(description: 'Field identifier'),
          'label': S.string(description: 'Display label'),
          'type': S.enum$(
            description: 'Field type',
            values: ['text', 'number', 'date', 'checkbox'],
          ),
          'required': S.boolean(description: 'Is field required'),
        },
        required: ['name', 'type'],
      ),
    ),
    'submitLabel': S.string(description: 'Submit button text'),
  },
  required: ['title', 'fields'],
);

// Output JSON Schema
{
  "type": "object",
  "description": "A dynamic form with multiple fields",
  "properties": {
    "title": {
      "type": "string",
      "description": "Form title",
      "minLength": 1,
      "maxLength": 100
    },
    "fields": {
      "type": "array",
      "description": "Form fields",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string", "description": "Field identifier"},
          "label": {"type": "string", "description": "Display label"},
          "type": {
            "type": "string",
            "description": "Field type",
            "enum": ["text", "number", "date", "checkbox"]
          },
          "required": {"type": "boolean", "description": "Is field required"}
        },
        "required": ["name", "type"]
      }
    },
    "submitLabel": {
      "type": "string",
      "description": "Submit button text"
    }
  },
  "required": ["title", "fields"]
}
```

## Claude Tool Call Flow

### Typical UI Generation Sequence

1. **User request:** "Show me a product card"

2. **Claude calls begin_rendering:**
```json
{
  "type": "tool_use",
  "id": "toolu_abc123",
  "name": "begin_rendering",
  "input": {"surfaceId": "product_surface_1"}
}
```

3. **Claude calls surface_update:**
```json
{
  "type": "tool_use",
  "id": "toolu_def456",
  "name": "surface_update",
  "input": {
    "surfaceId": "product_surface_1",
    "widgets": [{
      "type": "product_card",
      "properties": {
        "name": "Wireless Headphones",
        "price": 79.99,
        "imageUrl": "https://example.com/headphones.jpg"
      }
    }]
  }
}
```

4. **Optional text response:** "Here's a product card for the wireless headphones."

### Message Conversion

Claude's tool calls are converted to GenUI messages:

```dart
// Claude tool_use → A2uiMessageData → A2uiMessage

// begin_rendering
BeginRenderingData(
  surfaceId: 'product_surface_1',
  root: 'root',
  metadata: {'source': 'user_request'},
)
→ BeginRendering(
  surfaceId: 'product_surface_1',
  root: 'root',
  metadata: {'source': 'user_request'},
)

// surface_update
SurfaceUpdateData(
  surfaceId: 'product_surface_1',
  widgets: [WidgetNode(type: 'product_card', properties: {...})],
)
→ SurfaceUpdate(
  surfaceId: 'product_surface_1',
  components: [Component(id: 'product_card', componentProperties: {...})],
)
```

## Widget Node Structure

### WidgetNode Model

```dart
@freezed
class WidgetNode {
  const factory WidgetNode({
    required String type,              // Widget type from catalog
    @Default({}) Map<String, dynamic> properties,  // Widget properties
    List<WidgetNode>? children,        // Nested widgets
    String? dataBinding,               // Data model binding path
  }) = _WidgetNode;
}
```

### Data Binding

The `dataBinding` property connects widgets to the GenUI DataModel for reactive updates. When Claude generates a widget with a data binding, changes to the DataModel automatically update the widget.

**Basic Data Binding:**

```dart
// Widget with data binding
{
  "type": "text_field",
  "properties": {
    "label": "Email Address",
    "placeholder": "Enter your email"
  },
  "dataBinding": "user.email"  // Binds to DataModel path
}
```

**How It Works:**

```dart
// 1. Claude creates widget with dataBinding
final widgetNode = WidgetNode(
  type: 'text_field',
  properties: {'label': 'Name'},
  dataBinding: 'form.name',
);

// 2. GenUI binds widget to DataModel
// When user types in the field, DataModel is updated:
dataModel.setValue('form.name', 'John Doe');

// 3. Claude can update bound values via data_model_update
// Tool call:
{
  "name": "data_model_update",
  "input": {
    "updates": {
      "form.name": "Jane Smith"
    }
  }
}
// Widget automatically reflects the new value
```

**Nested Data Binding Paths:**

```dart
// Dot notation for nested objects
"dataBinding": "user.profile.avatar"      // → dataModel['user']['profile']['avatar']
"dataBinding": "cart.items.0.quantity"    // → dataModel['cart']['items'][0]['quantity']
"dataBinding": "settings.theme.darkMode"  // → dataModel['settings']['theme']['darkMode']
```

**Form Example with Data Binding:**

```json
{
  "type": "form_container",
  "properties": {"title": "Contact Information"},
  "children": [
    {
      "type": "text_field",
      "properties": {"label": "Name"},
      "dataBinding": "contact.name"
    },
    {
      "type": "text_field",
      "properties": {"label": "Email", "type": "email"},
      "dataBinding": "contact.email"
    },
    {
      "type": "text_field",
      "properties": {"label": "Phone", "type": "tel"},
      "dataBinding": "contact.phone"
    }
  ]
}
```

**Retrieving Bound Values:**

```dart
// In widget builder
CatalogItem(
  name: 'text_field',
  dataSchema: S.object(...),
  widgetBuilder: (context) {
    final binding = context.component.dataBinding;
    if (binding != null) {
      // Watch for changes
      return context.dataModel.watchPath(binding, (value) {
        controller.text = value ?? '';
      });
    }
    return TextField(controller: controller);
  },
)
```

### Nested Widgets Example

```dart
// Claude can create nested structures
{
  "type": "card",
  "properties": {"title": "User Profile"},
  "children": [
    {
      "type": "avatar",
      "properties": {"imageUrl": "...", "size": "large"}
    },
    {
      "type": "text_display",
      "properties": {"text": "John Doe", "style": "title"}
    },
    {
      "type": "button_row",
      "children": [
        {"type": "button", "properties": {"label": "Edit", "variant": "primary"}},
        {"type": "button", "properties": {"label": "Delete", "variant": "danger"}}
      ]
    }
  ]
}
```

## Best Practices

### Schema Design for Claude

```dart
// DO: Provide clear descriptions
S.string(description: 'The product name, shown as the card title')

// DON'T: Leave descriptions empty
S.string()

// DO: Use enums for constrained values
S.enum$(
  description: 'Button style variant',
  values: ['primary', 'secondary', 'danger'],
)

// DON'T: Use unconstrained strings for known options
S.string(description: 'Button style')

// DO: Mark required fields
S.object(
  properties: {...},
  required: ['title', 'content'],  // Claude knows these are mandatory
)

// DO: Provide constraints
S.integer(
  description: 'Rating from 1-5 stars',
  minimum: 1,
  maximum: 5,
)
```

### Widget Naming

```dart
// DO: Use descriptive snake_case names
'product_card'
'user_profile'
'date_picker'

// DON'T: Use vague or inconsistent names
'card1'
'UserProfile'
'dp'
```

### System Prompt Integration

```dart
// Include widget descriptions in system prompt
final systemPrompt = '''
You have access to these UI widgets:

- product_card: Display a product with name, price, and image
- info_card: Show informational text with a title
- action_button: A clickable button that triggers events
- form_field: An input field for user data

When generating UI:
1. Always call begin_rendering first
2. Use surface_update to provide the widget tree
3. Match widget types exactly to the names above
''';
```
