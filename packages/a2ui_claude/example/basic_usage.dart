// ignore_for_file: avoid_print
/// Basic usage example for a2ui_claude package.
///
/// This example demonstrates:
/// - Defining A2UI tool schemas
/// - Converting tools to Claude API format
/// - Generating tool instructions for the system prompt
/// - Parsing Claude responses into A2UI messages
/// - Validating tool inputs
library;

import 'package:a2ui_claude/a2ui_claude.dart';

void main() {
  print('=== a2ui_claude Basic Usage Example ===\n');

  // 1. Define A2UI tool schemas
  print('1. Defining A2UI tool schemas...');
  final toolSchemas = _defineToolSchemas();
  print('   Defined ${toolSchemas.length} tools\n');

  // 2. Convert to Claude API format
  print('2. Converting to Claude tool format...');
  final claudeTools = A2uiToolConverter.toClaudeTools(toolSchemas);
  print('   Converted ${claudeTools.length} tools');
  print('   First tool: ${claudeTools.first['name']}\n');

  // 3. Generate tool instructions
  print('3. Generating tool instructions for system prompt...');
  final instructions = A2uiToolConverter.generateToolInstructions(toolSchemas);
  print(instructions);

  // 4. Validate tool input
  print('4. Validating tool inputs...');
  _demonstrateValidation(toolSchemas);

  // 5. Parse a mock Claude response
  print('5. Parsing Claude response...');
  _demonstrateParsing();

  print('\n=== Example Complete ===');
}

/// Define the A2UI tool schemas available for UI generation.
List<A2uiToolSchema> _defineToolSchemas() {
  return [
    const A2uiToolSchema(
      name: 'begin_rendering',
      description: 'Signals the start of a UI generation sequence',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string', 'description': 'Unique surface ID'},
          'parentSurfaceId': {
            'type': 'string',
            'description': 'Optional parent surface ID',
          },
          'metadata': {'type': 'object', 'description': 'Optional metadata'},
        },
      },
      requiredFields: ['surfaceId'],
    ),
    const A2uiToolSchema(
      name: 'surface_update',
      description: 'Updates the widget tree for a UI surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string', 'description': 'Surface to update'},
          'widgets': {
            'type': 'array',
            'description': 'Widget tree definition',
            'items': {'type': 'object'},
          },
          'append': {
            'type': 'boolean',
            'description': 'Append to existing widgets',
          },
        },
      },
      requiredFields: ['surfaceId', 'widgets'],
    ),
    const A2uiToolSchema(
      name: 'data_model_update',
      description: 'Updates bound data values that widgets observe',
      inputSchema: {
        'type': 'object',
        'properties': {
          'updates': {'type': 'object', 'description': 'Key-value updates'},
          'scope': {'type': 'string', 'description': 'Optional update scope'},
        },
      },
      requiredFields: ['updates'],
    ),
    const A2uiToolSchema(
      name: 'delete_surface',
      description: 'Removes a UI surface from the rendering tree',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string', 'description': 'Surface to delete'},
          'cascade': {
            'type': 'boolean',
            'description': 'Delete child surfaces',
          },
        },
      },
      requiredFields: ['surfaceId'],
    ),
  ];
}

/// Demonstrate input validation.
void _demonstrateValidation(List<A2uiToolSchema> schemas) {
  // Valid input
  final validResult = A2uiToolConverter.validateToolInput('begin_rendering', {
    'surfaceId': 'main-ui',
  }, schemas);
  print('   Valid input result: ${validResult.isValid}');

  // Invalid input (missing required field)
  final invalidResult = A2uiToolConverter.validateToolInput(
    'begin_rendering',
    {}, // Missing surfaceId
    schemas,
  );
  print('   Invalid input result: ${invalidResult.isValid}');
  if (!invalidResult.isValid) {
    for (final error in invalidResult.errors) {
      print('   - Error: ${error.message}');
    }
  }

  // Unknown tool
  final unknownResult = A2uiToolConverter.validateToolInput('unknown_tool', {
    'foo': 'bar',
  }, schemas);
  print('   Unknown tool result: ${unknownResult.isValid}');
  if (!unknownResult.isValid) {
    for (final error in unknownResult.errors) {
      print('   - Error: ${error.message}');
    }
  }
  print('');
}

/// Demonstrate parsing Claude responses.
void _demonstrateParsing() {
  // Mock Claude response with tool_use blocks
  final mockResponse = {
    'id': 'msg_123',
    'type': 'message',
    'role': 'assistant',
    'content': [
      {'type': 'text', 'text': "I'll create a greeting UI for you."},
      {
        'type': 'tool_use',
        'id': 'toolu_001',
        'name': 'begin_rendering',
        'input': {
          'surfaceId': 'greeting-ui',
          'metadata': {'intent': 'greeting'},
        },
      },
      {
        'type': 'tool_use',
        'id': 'toolu_002',
        'name': 'surface_update',
        'input': {
          'surfaceId': 'greeting-ui',
          'widgets': [
            {
              'type': 'Container',
              'props': {'padding': 16},
              'children': [
                {
                  'type': 'Text',
                  'props': {'text': 'Hello, World!', 'style': 'headline'},
                },
                {
                  'type': 'Button',
                  'props': {'label': 'Click me', 'onTap': 'handleTap'},
                },
              ],
            },
          ],
        },
      },
    ],
  };

  // Parse the response
  final result = ClaudeA2uiParser.parseMessage(mockResponse);

  print('   Text content: "${result.textContent}"');
  print('   Has tool use: ${result.hasToolUse}');
  print('   A2UI messages: ${result.a2uiMessages.length}');

  // Process each A2UI message using pattern matching
  for (final message in result.a2uiMessages) {
    switch (message) {
      case BeginRenderingData(:final surfaceId, :final metadata):
        print('   -> BeginRendering: $surfaceId (metadata: $metadata)');
      case SurfaceUpdateData(:final surfaceId, :final widgets):
        print('   -> SurfaceUpdate: $surfaceId with ${widgets.length} widgets');
        _printWidgetTree(widgets, indent: 6);
      case DataModelUpdateData(:final updates, :final scope):
        print(
          '   -> DataModelUpdate: ${updates.keys.toList()} (scope: $scope)',
        );
      case DeleteSurfaceData(:final surfaceId, :final cascade):
        print('   -> DeleteSurface: $surfaceId (cascade: $cascade)');
    }
  }
}

/// Print widget tree structure.
void _printWidgetTree(List<WidgetNode> widgets, {int indent = 0}) {
  final prefix = ' ' * indent;
  for (final widget in widgets) {
    print('$prefix- ${widget.type}');
    if (widget.children != null && widget.children!.isNotEmpty) {
      _printWidgetTree(widget.children!, indent: indent + 2);
    }
  }
}
