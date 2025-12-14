#!/usr/bin/env dart
/// Tool Schema Generator for GenUI Anthropic
///
/// Generates Claude-compatible tool JSON schemas from widget catalogs.
/// Useful for debugging, documentation, and verifying tool definitions.
///
/// Usage:
///   dart run .claude/skills/genui-anthropic/scripts/generate_tool_schema.dart
///
/// Output formats:
///   - JSON (default): Full Claude API tool format
///   - Markdown: Documentation-friendly format

import 'dart:convert';
import 'dart:io';

/// A2UI control tools that Claude uses to manage UI surfaces
class A2uiControlTools {
  static const beginRendering = {
    'name': 'begin_rendering',
    'description':
        'Signal the start of UI generation for a surface. Call this before surface_update to initialize a new UI surface.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'Unique identifier for the UI surface',
        },
        'parentSurfaceId': {
          'type': 'string',
          'description': 'Optional parent surface for nested UIs',
        },
      },
      'required': ['surfaceId'],
    },
  };

  static const surfaceUpdate = {
    'name': 'surface_update',
    'description':
        'Update the widget tree of a surface with components from the catalog.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'The surface to update',
        },
        'widgets': {
          'type': 'array',
          'description': 'Array of widget nodes to render',
          'items': {
            'type': 'object',
            'properties': {
              'type': {'type': 'string', 'description': 'Widget type from catalog'},
              'properties': {'type': 'object', 'description': 'Widget properties'},
              'children': {'type': 'array', 'description': 'Nested widgets'},
            },
            'required': ['type'],
          },
        },
        'append': {
          'type': 'boolean',
          'description': 'If true, append to existing widgets instead of replacing',
        },
      },
      'required': ['surfaceId', 'widgets'],
    },
  };

  static const dataModelUpdate = {
    'name': 'data_model_update',
    'description': 'Update data model values that are bound to UI components.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'updates': {
          'type': 'object',
          'description': 'Key-value pairs to update in the data model',
        },
        'scope': {
          'type': 'string',
          'description': 'Optional scope for the updates',
        },
      },
      'required': ['updates'],
    },
  };

  static const deleteSurface = {
    'name': 'delete_surface',
    'description': 'Delete a UI surface and optionally its children.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'The surface to delete',
        },
        'cascade': {
          'type': 'boolean',
          'description': 'If true, also delete child surfaces',
        },
      },
      'required': ['surfaceId'],
    },
  };

  static List<Map<String, dynamic>> get all => [
        beginRendering,
        surfaceUpdate,
        dataModelUpdate,
        deleteSurface,
      ];
}

/// Converts a catalog item to Claude tool schema format
Map<String, dynamic> catalogItemToTool(Map<String, dynamic> item) {
  final name = item['name'] as String;
  final schema = item['dataSchema'] as Map<String, dynamic>;

  return {
    'name': name,
    'description': schema['description'] ?? 'Widget: $name',
    'input_schema': _convertSchema(schema),
  };
}

/// Converts json_schema_builder schema to JSON Schema format
Map<String, dynamic> _convertSchema(Map<String, dynamic> schema) {
  final result = <String, dynamic>{};

  if (schema['type'] != null) {
    result['type'] = schema['type'];
  }

  if (schema['description'] != null) {
    result['description'] = schema['description'];
  }

  if (schema['properties'] != null) {
    result['properties'] = <String, dynamic>{};
    final props = schema['properties'] as Map<String, dynamic>;
    for (final entry in props.entries) {
      result['properties'][entry.key] = _convertSchema(entry.value as Map<String, dynamic>);
    }
  }

  if (schema['required'] != null) {
    result['required'] = schema['required'];
  }

  if (schema['items'] != null) {
    result['items'] = _convertSchema(schema['items'] as Map<String, dynamic>);
  }

  if (schema['enum'] != null) {
    result['enum'] = schema['enum'];
  }

  // Copy numeric constraints
  for (final key in ['minimum', 'maximum', 'minLength', 'maxLength', 'minItems', 'maxItems']) {
    if (schema[key] != null) {
      result[key] = schema[key];
    }
  }

  return result;
}

/// Generates full tool list with A2UI controls and widget tools
List<Map<String, dynamic>> generateToolList(List<Map<String, dynamic>> catalogItems) {
  final tools = <Map<String, dynamic>>[];

  // Add A2UI control tools first
  tools.addAll(A2uiControlTools.all);

  // Add widget tools from catalog
  for (final item in catalogItems) {
    tools.add(catalogItemToTool(item));
  }

  return tools;
}

/// Outputs tools as JSON
String toJson(List<Map<String, dynamic>> tools, {bool pretty = true}) {
  final encoder = pretty ? JsonEncoder.withIndent('  ') : JsonEncoder();
  return encoder.convert(tools);
}

/// Outputs tools as Markdown documentation
String toMarkdown(List<Map<String, dynamic>> tools) {
  final buffer = StringBuffer();

  buffer.writeln('# Claude Tool Schemas');
  buffer.writeln();
  buffer.writeln('Generated tool schemas for GenUI Anthropic.');
  buffer.writeln();

  buffer.writeln('## A2UI Control Tools');
  buffer.writeln();

  for (final tool in tools.take(4)) {
    _writeToolMarkdown(buffer, tool);
  }

  if (tools.length > 4) {
    buffer.writeln('## Widget Tools');
    buffer.writeln();

    for (final tool in tools.skip(4)) {
      _writeToolMarkdown(buffer, tool);
    }
  }

  return buffer.toString();
}

void _writeToolMarkdown(StringBuffer buffer, Map<String, dynamic> tool) {
  buffer.writeln('### ${tool['name']}');
  buffer.writeln();
  buffer.writeln(tool['description']);
  buffer.writeln();
  buffer.writeln('```json');
  buffer.writeln(JsonEncoder.withIndent('  ').convert(tool['input_schema']));
  buffer.writeln('```');
  buffer.writeln();
}

void main(List<String> args) {
  // Parse arguments
  final format = args.contains('--markdown') ? 'markdown' : 'json';
  final compact = args.contains('--compact');

  // Example catalog items
  final exampleCatalog = [
    {
      'name': 'info_card',
      'dataSchema': {
        'type': 'object',
        'description': 'Display information in a styled card with title and content',
        'properties': {
          'title': {'type': 'string', 'description': 'Card title'},
          'content': {'type': 'string', 'description': 'Card body text'},
          'icon': {'type': 'string', 'description': 'Optional Material icon name'},
          'variant': {
            'type': 'string',
            'description': 'Card style variant',
            'enum': ['default', 'outlined', 'elevated'],
          },
        },
        'required': ['title', 'content'],
      },
    },
    {
      'name': 'action_button',
      'dataSchema': {
        'type': 'object',
        'description': 'A clickable button that triggers an action',
        'properties': {
          'label': {'type': 'string', 'description': 'Button text'},
          'action': {'type': 'string', 'description': 'Action identifier for event handling'},
          'variant': {
            'type': 'string',
            'description': 'Button style',
            'enum': ['primary', 'secondary', 'danger', 'text'],
          },
          'disabled': {'type': 'boolean', 'description': 'Whether button is disabled'},
        },
        'required': ['label', 'action'],
      },
    },
    {
      'name': 'form_field',
      'dataSchema': {
        'type': 'object',
        'description': 'An input field for collecting user data',
        'properties': {
          'name': {'type': 'string', 'description': 'Field identifier'},
          'label': {'type': 'string', 'description': 'Display label'},
          'type': {
            'type': 'string',
            'description': 'Input type',
            'enum': ['text', 'number', 'email', 'password', 'date'],
          },
          'placeholder': {'type': 'string', 'description': 'Placeholder text'},
          'required': {'type': 'boolean', 'description': 'Whether field is required'},
          'bindPath': {'type': 'string', 'description': 'DataModel binding path'},
        },
        'required': ['name', 'type'],
      },
    },
  ];

  final tools = generateToolList(exampleCatalog);

  print('GenUI Anthropic Tool Schema Generator');
  print('=====================================');
  print('');
  print('Tools generated: ${tools.length}');
  print('  - A2UI control tools: 4');
  print('  - Widget tools: ${tools.length - 4}');
  print('');

  if (format == 'markdown') {
    print(toMarkdown(tools));
  } else {
    print(toJson(tools, pretty: !compact));
  }
}
