import 'dart:async';
import 'dart:io';

import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiMessageData', () {
    group('BeginRenderingData', () {
      test('creates with required fields', () {
        const data = BeginRenderingData(surfaceId: 'surface-1');
        expect(data.surfaceId, equals('surface-1'));
        expect(data.parentSurfaceId, isNull);
        expect(data.metadata, isNull);
      });

      test('creates with all fields', () {
        const data = BeginRenderingData(
          surfaceId: 'surface-1',
          parentSurfaceId: 'parent-1',
          metadata: {'key': 'value'},
        );
        expect(data.surfaceId, equals('surface-1'));
        expect(data.parentSurfaceId, equals('parent-1'));
        expect(data.metadata, equals({'key': 'value'}));
      });

      test('serializes to JSON', () {
        const data = BeginRenderingData(
          surfaceId: 'surface-1',
          parentSurfaceId: 'parent-1',
        );
        final json = data.toJson();
        expect(json['surfaceId'], equals('surface-1'));
        expect(json['parentSurfaceId'], equals('parent-1'));
      });

      test('deserializes from JSON', () {
        final data = BeginRenderingData.fromJson(const {
          'surfaceId': 'surface-1',
          'parentSurfaceId': 'parent-1',
        });
        expect(data.surfaceId, equals('surface-1'));
        expect(data.parentSurfaceId, equals('parent-1'));
      });
    });

    group('SurfaceUpdateData', () {
      test('creates with widgets', () {
        const data = SurfaceUpdateData(
          surfaceId: 'surface-1',
          widgets: [
            WidgetNode(type: 'text', properties: {'text': 'Hello'}),
          ],
        );
        expect(data.surfaceId, equals('surface-1'));
        expect(data.widgets.length, equals(1));
        expect(data.append, isFalse);
      });

      test('serializes to JSON', () {
        const data = SurfaceUpdateData(
          surfaceId: 'surface-1',
          widgets: [
             WidgetNode(type: 'text', properties: {'text': 'Hello'}),
          ],
          append: true,
        );
        final json = data.toJson();
        expect(json['surfaceId'], equals('surface-1'));
        expect(json['append'], isTrue);
        expect(json['widgets'], isA<List<dynamic>>());
      });
    });

    group('DataModelUpdateData', () {
      test('creates with updates', () {
        const data = DataModelUpdateData(
          updates: {'name': 'John', 'age': 30},
        );
        expect(data.updates['name'], equals('John'));
        expect(data.updates['age'], equals(30));
        expect(data.scope, isNull);
      });

      test('creates with scope', () {
        const data = DataModelUpdateData(
          updates: {'name': 'John'},
          scope: 'user',
        );
        expect(data.scope, equals('user'));
      });
    });

    group('DeleteSurfaceData', () {
      test('creates with default cascade', () {
        const data = DeleteSurfaceData(surfaceId: 'surface-1');
        expect(data.surfaceId, equals('surface-1'));
        expect(data.cascade, isTrue);
      });

      test('creates with cascade false', () {
        const data = DeleteSurfaceData(surfaceId: 'surface-1', cascade: false);
        expect(data.cascade, isFalse);
      });
    });
  });

  group('WidgetNode', () {
    test('creates with required fields', () {
      const node = WidgetNode(type: 'button', properties: {'label': 'Click'});
      expect(node.type, equals('button'));
      expect(node.properties['label'], equals('Click'));
      expect(node.children, isNull);
      expect(node.dataBinding, isNull);
    });

    test('creates with children', () {
      const node = WidgetNode(
        type: 'column',
        children: [
          WidgetNode(type: 'text', properties: {'text': 'Child'}),
        ],
      );
      expect(node.children?.length, equals(1));
    });

    test('copyWith creates new instance', () {
      const original = WidgetNode(type: 'text', properties: {'text': 'Hello'});
      final copy = original.copyWith(type: 'button');
      expect(copy.type, equals('button'));
      expect(original.type, equals('text'));
    });
  });

  group('A2uiToolSchema', () {
    test('creates with required fields', () {
      const schema = A2uiToolSchema(
        name: 'user_card',
        description: 'Display user profile',
        inputSchema: {
          'type': 'object',
          'properties': {
            'userId': {'type': 'string'},
          },
        },
      );
      expect(schema.name, equals('user_card'));
      expect(schema.description, equals('Display user profile'));
    });
  });

  group('StreamConfig', () {
    test('has default values', () {
      const config = StreamConfig.defaults;
      expect(config.maxTokens, equals(4096));
      expect(config.timeout, equals(const Duration(seconds: 60)));
      expect(config.retryAttempts, equals(3));
    });

    test('copyWith creates modified copy', () {
      const original = StreamConfig.defaults;
      final modified = original.copyWith(maxTokens: 8192);
      expect(modified.maxTokens, equals(8192));
      expect(original.maxTokens, equals(4096));
    });
  });

  group('ParseResult', () {
    test('empty result', () {
      final result = ParseResult.empty();
      expect(result.isEmpty, isTrue);
      expect(result.hasToolUse, isFalse);
    });

    test('text only result', () {
      final result = ParseResult.textOnly('Hello world');
      expect(result.textContent, equals('Hello world'));
      expect(result.hasToolUse, isFalse);
    });

    test('messages only result', () {
      final result = ParseResult.messagesOnly(const [
        BeginRenderingData(surfaceId: 'surface-1'),
      ]);
      expect(result.a2uiMessages.length, equals(1));
      expect(result.hasToolUse, isTrue);
    });
  });

  group('Exceptions', () {
    test('ToolConversionException contains tool name', () {
      const exception = ToolConversionException(
        'Invalid schema',
        'my_tool',
      );
      expect(exception.toolName, equals('my_tool'));
      expect(exception.toString(), contains('my_tool'));
    });

    test('StreamException tracks retryable status', () {
      const retryable = StreamException(
        'Timeout',
        isRetryable: true,
      );
      const nonRetryable = StreamException(
        'Auth failed',
      );
      expect(retryable.isRetryable, isTrue);
      expect(nonRetryable.isRetryable, isFalse);
    });

    test('ValidationException contains errors', () {
      const exception = ValidationException(
        'Validation failed',
        [
          ValidationError(
            field: 'name',
            message: 'Required',
            code: 'required',
          ),
        ],
      );
      expect(exception.errors.length, equals(1));
      expect(exception.errors.first.field, equals('name'));
    });

    test('MessageParseException contains raw content', () {
      const exception = MessageParseException(
        'Failed to parse',
        '{"invalid": json}',
        'valid JSON object',
      );
      expect(exception.rawContent, equals('{"invalid": json}'));
      expect(exception.expectedFormat, equals('valid JSON object'));
      expect(exception.toString(), contains('MessageParseException'));
    });

    test('StreamException toString includes HTTP status', () {
      const exception = StreamException(
        'Rate limited',
        httpStatusCode: 429,
        isRetryable: true,
      );
      expect(exception.toString(), contains('429'));
      expect(exception.toString(), contains('Rate limited'));
    });

    test('ValidationException toString shows error count', () {
      const exception = ValidationException(
        'Multiple errors',
        [
          ValidationError(field: 'a', message: 'm1', code: 'c1'),
          ValidationError(field: 'b', message: 'm2', code: 'c2'),
        ],
      );
      expect(exception.toString(), contains('2 errors'));
    });

    test('ValidationError toString formats correctly', () {
      const error = ValidationError(
        field: 'email',
        message: 'Invalid format',
        code: 'invalid_email',
      );
      expect(error.toString(), equals('email: Invalid format (invalid_email)'));
    });

    test('exception sealed class exhaustive matching', () {
      String matchException(A2uiException exception) {
        return switch (exception) {
          ToolConversionException() => 'tool',
          MessageParseException() => 'parse',
          StreamException() => 'stream',
          ValidationException() => 'validation',
        };
      }

      expect(
        matchException(const ToolConversionException('error', 'tool')),
        equals('tool'),
      );
      expect(
        matchException(const MessageParseException('error')),
        equals('parse'),
      );
      expect(
        matchException(const StreamException('error')),
        equals('stream'),
      );
      expect(
        matchException(const ValidationException('error', [])),
        equals('validation'),
      );
    });

    test('exceptions inherit from A2uiException', () {
      expect(
        const ToolConversionException('msg', 'tool'),
        isA<A2uiException>(),
      );
      expect(
        const MessageParseException('msg'),
        isA<A2uiException>(),
      );
      expect(
        const StreamException('msg'),
        isA<A2uiException>(),
      );
      expect(
        const ValidationException('msg', []),
        isA<A2uiException>(),
      );
    });

    test('exceptions implement Exception interface', () {
      expect(
        const ToolConversionException('msg', 'tool'),
        isA<Exception>(),
      );
    });
  });

  group('A2uiToolConverter', () {
    test('validates tool input - valid', () {
      const schema = A2uiToolSchema(
        name: 'test_tool',
        description: 'Test',
        inputSchema: {'type': 'object'},
        requiredFields: ['name'],
      );

      final result = A2uiToolConverter.validateToolInput(
        'test_tool',
        {'name': 'John'},
        [schema],
      );

      expect(result.isValid, isTrue);
    });

    test('validates tool input - missing required field', () {
      const schema = A2uiToolSchema(
        name: 'test_tool',
        description: 'Test',
        inputSchema: {'type': 'object'},
        requiredFields: ['name'],
      );

      final result = A2uiToolConverter.validateToolInput(
        'test_tool',
        {},
        [schema],
      );

      expect(result.isValid, isFalse);
      expect(result.errors.first.field, equals('name'));
    });

    test('validates tool input - unknown tool', () {
      final result = A2uiToolConverter.validateToolInput(
        'unknown_tool',
        {},
        [],
      );

      expect(result.isValid, isFalse);
      expect(result.errors.first.code, equals('unknown_tool'));
    });

    test('generates tool instructions', () {
      final instructions = A2uiToolConverter.generateToolInstructions([
        const A2uiToolSchema(
          name: 'tool_a',
          description: 'Does A',
          inputSchema: {},
        ),
        const A2uiToolSchema(
          name: 'tool_b',
          description: 'Does B',
          inputSchema: {},
        ),
      ]);

      expect(instructions, contains('tool_a'));
      expect(instructions, contains('tool_b'));
      expect(instructions, contains('Does A'));
    });

    test('toClaudeTools with single schema', () {
      final tools = A2uiToolConverter.toClaudeTools([
        const A2uiToolSchema(
          name: 'user_card',
          description: 'Display user profile',
          inputSchema: {
            'type': 'object',
            'properties': {
              'userId': {'type': 'string'},
            },
          },
          requiredFields: ['userId'],
        ),
      ]);

      expect(tools.length, equals(1));
      final firstTool = tools.first;
      expect(firstTool['name'], equals('user_card'));
      expect(firstTool['description'], equals('Display user profile'));
      final inputSchema = firstTool['input_schema'] as Map<String, dynamic>;
      expect(inputSchema['type'], equals('object'));
      expect(inputSchema['required'], equals(['userId']));
    });

    test('toClaudeTools with multiple schemas', () {
      final tools = A2uiToolConverter.toClaudeTools([
        const A2uiToolSchema(
          name: 'tool_a',
          description: 'Tool A',
          inputSchema: {},
        ),
        const A2uiToolSchema(
          name: 'tool_b',
          description: 'Tool B',
          inputSchema: {},
        ),
        const A2uiToolSchema(
          name: 'tool_c',
          description: 'Tool C',
          inputSchema: {},
        ),
      ]);

      expect(tools.length, equals(3));
      expect(tools.map((t) => t['name']), containsAll(['tool_a', 'tool_b', 'tool_c']));
    });

    test('toClaudeTools with nested object properties', () {
      final tools = A2uiToolConverter.toClaudeTools([
        const A2uiToolSchema(
          name: 'nested_tool',
          description: 'Tool with nested objects',
          inputSchema: {
            'type': 'object',
            'properties': {
              'user': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'address': {
                    'type': 'object',
                    'properties': {
                      'city': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        ),
      ]);

      expect(tools.length, equals(1));
      final inputSchema = tools.first['input_schema'] as Map<String, dynamic>;
      final props = inputSchema['properties'] as Map<String, dynamic>;
      final userProp = props['user'] as Map<String, dynamic>;
      expect(userProp['type'], equals('object'));
      final userProps = userProp['properties'] as Map<String, dynamic>;
      final addressProp = userProps['address'] as Map<String, dynamic>;
      expect(addressProp['type'], equals('object'));
    });

    test('toClaudeTools with array properties', () {
      final tools = A2uiToolConverter.toClaudeTools([
        const A2uiToolSchema(
          name: 'list_tool',
          description: 'Tool with array',
          inputSchema: {
            'type': 'object',
            'properties': {
              'items': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        ),
      ]);

      expect(tools.length, equals(1));
      final inputSchema = tools.first['input_schema'] as Map<String, dynamic>;
      final props = inputSchema['properties'] as Map<String, dynamic>;
      final itemsProp = props['items'] as Map<String, dynamic>;
      expect(itemsProp['type'], equals('array'));
      final itemsItems = itemsProp['items'] as Map<String, dynamic>;
      expect(itemsItems['type'], equals('string'));
    });
  });

  group('ClaudeA2uiParser', () {
    test('parses begin_rendering tool', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'begin_rendering',
        {'surfaceId': 'surface-1'},
      );

      expect(result, isA<BeginRenderingData>());
      expect((result! as BeginRenderingData).surfaceId, equals('surface-1'));
    });

    test('parses surface_update tool', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'surface_update',
        {
          'surfaceId': 'surface-1',
          'widgets': [
            {'type': 'text', 'properties': {'text': 'Hello'}},
          ],
        },
      );

      expect(result, isA<SurfaceUpdateData>());
    });

    test('returns null for unknown tool', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'unknown_tool',
        {},
      );

      expect(result, isNull);
    });

    test('parses message with tool_use blocks', () {
      final result = ClaudeA2uiParser.parseMessage({
        'content': [
          {
            'type': 'tool_use',
            'name': 'begin_rendering',
            'input': {'surfaceId': 'surface-1'},
          },
          {
            'type': 'text',
            'text': 'Creating UI...',
          },
        ],
      });

      expect(result.hasToolUse, isTrue);
      expect(result.a2uiMessages.length, equals(1));
      expect(result.textContent, equals('Creating UI...'));
    });

    test('parses data_model_update tool', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'data_model_update',
        {
          'updates': {'name': 'John', 'age': 30},
          'scope': 'user',
        },
      );

      expect(result, isA<DataModelUpdateData>());
      final data = result! as DataModelUpdateData;
      expect(data.updates['name'], equals('John'));
      expect(data.updates['age'], equals(30));
      expect(data.scope, equals('user'));
    });

    test('parses delete_surface tool', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'delete_surface',
        {
          'surfaceId': 'surface-to-delete',
          'cascade': false,
        },
      );

      expect(result, isA<DeleteSurfaceData>());
      final data = result! as DeleteSurfaceData;
      expect(data.surfaceId, equals('surface-to-delete'));
      expect(data.cascade, isFalse);
    });

    test('parses delete_surface with default cascade', () {
      final result = ClaudeA2uiParser.parseToolUse(
        'delete_surface',
        {'surfaceId': 'surface-1'},
      );

      expect(result, isA<DeleteSurfaceData>());
      expect((result! as DeleteSurfaceData).cascade, isTrue);
    });

    test('parses message with text only', () {
      final result = ClaudeA2uiParser.parseMessage({
        'content': [
          {'type': 'text', 'text': 'Hello'},
          {'type': 'text', 'text': 'World'},
        ],
      });

      expect(result.hasToolUse, isFalse);
      expect(result.a2uiMessages, isEmpty);
      expect(result.textContent, equals('Hello\nWorld'));
    });

    test('parses message with mixed content (multiple tools + text)', () {
      final result = ClaudeA2uiParser.parseMessage({
        'content': [
          {'type': 'text', 'text': 'Starting render...'},
          {
            'type': 'tool_use',
            'name': 'begin_rendering',
            'input': {'surfaceId': 'surface-1'},
          },
          {
            'type': 'tool_use',
            'name': 'surface_update',
            'input': {
              'surfaceId': 'surface-1',
              'widgets': [
                {'type': 'text', 'properties': {'text': 'Hello'}},
              ],
            },
          },
          {'type': 'text', 'text': 'Render complete.'},
        ],
      });

      expect(result.hasToolUse, isTrue);
      expect(result.a2uiMessages.length, equals(2));
      expect(result.a2uiMessages[0], isA<BeginRenderingData>());
      expect(result.a2uiMessages[1], isA<SurfaceUpdateData>());
      expect(result.textContent, equals('Starting render...\nRender complete.'));
    });

    test('parses message with null content returns empty', () {
      final result = ClaudeA2uiParser.parseMessage({});
      expect(result.isEmpty, isTrue);
      expect(result.hasToolUse, isFalse);
    });

    test('skips unknown tools in message parsing', () {
      final result = ClaudeA2uiParser.parseMessage({
        'content': [
          {
            'type': 'tool_use',
            'name': 'unknown_tool',
            'input': {'foo': 'bar'},
          },
          {
            'type': 'tool_use',
            'name': 'begin_rendering',
            'input': {'surfaceId': 'surface-1'},
          },
        ],
      });

      expect(result.a2uiMessages.length, equals(1));
      expect(result.a2uiMessages[0], isA<BeginRenderingData>());
    });
  });

  group('ValidationResult', () {
    test('valid result', () {
      final result = ValidationResult.valid();
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('invalid result with errors', () {
      final result = ValidationResult.invalid(const [
        ValidationError(
          field: 'email',
          message: 'Invalid format',
          code: 'invalid_format',
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
    });

    test('error factory', () {
      final result = ValidationResult.error(
        field: 'name',
        message: 'Required',
        code: 'required',
      );
      expect(result.isValid, isFalse);
      expect(result.errors.first.field, equals('name'));
    });
  });

  group('RetryPolicy', () {
    test('has default values', () {
      const policy = RetryPolicy.defaults;
      expect(policy.maxAttempts, equals(3));
      expect(policy.initialDelay, equals(const Duration(milliseconds: 500)));
    });

    test('shouldRetry respects max attempts', () {
      const policy = RetryPolicy.defaults;
      expect(
        policy.shouldRetry(const StreamException('error', isRetryable: true), 2),
        isTrue,
      );
      expect(
        policy.shouldRetry(const StreamException('error', isRetryable: true), 3),
        isFalse,
      );
    });

    test('shouldRetry checks isRetryable', () {
      const policy = RetryPolicy.defaults;
      expect(
        policy.shouldRetry(
          const StreamException('error', isRetryable: true),
          1,
        ),
        isTrue,
      );
      expect(
        policy.shouldRetry(
          const StreamException('error'),
          1,
        ),
        isFalse,
      );
    });

    test('getDelay uses exponential backoff', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 3,
      );
      expect(policy.getDelay(1), equals(const Duration(seconds: 3)));
      expect(policy.getDelay(2), equals(const Duration(seconds: 6)));
    });

    test('shouldRetry returns true for TimeoutException', () {
      const policy = RetryPolicy.defaults;
      // TimeoutException should be retryable
      expect(
        policy.shouldRetry(TimeoutException('timeout'), 1),
        isTrue,
      );
    });

    test('shouldRetry returns true for SocketException', () {
      const policy = RetryPolicy.defaults;
      // SocketException should be retryable
      expect(
        policy.shouldRetry(
          const SocketException('connection failed'),
          1,
        ),
        isTrue,
      );
    });

    test('shouldRetry returns false for non-retryable exceptions', () {
      const policy = RetryPolicy.defaults;
      // Generic exceptions should not be retryable
      expect(
        policy.shouldRetry(Exception('generic error'), 1),
        isFalse,
      );
      expect(
        policy.shouldRetry(const FormatException('parse error'), 1),
        isFalse,
      );
    });

    test('shouldRetry returns true for HttpException', () {
      const policy = RetryPolicy.defaults;
      // HttpException should be retryable (network error)
      expect(
        policy.shouldRetry(const HttpException('connection reset'), 1),
        isTrue,
      );
    });
  });

  group('SchemaMapper', () {
    test('converts string property', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'name': {'type': 'string', 'description': 'User name'},
        },
      });

      final nameProp = result['name'] as Map<String, dynamic>;
      expect(nameProp['type'], equals('string'));
      expect(nameProp['description'], equals('User name'));
    });

    test('converts string property with enum', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'status': {
            'type': 'string',
            'enum': ['active', 'inactive'],
          },
        },
      });

      final statusProp = result['status'] as Map<String, dynamic>;
      expect(statusProp['type'], equals('string'));
      expect(statusProp['enum'], equals(['active', 'inactive']));
    });

    test('converts number property', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'age': {'type': 'number', 'description': 'User age'},
        },
      });

      final ageProp = result['age'] as Map<String, dynamic>;
      expect(ageProp['type'], equals('number'));
      expect(ageProp['description'], equals('User age'));
    });

    test('converts integer property', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'count': {'type': 'integer'},
        },
      });

      final countProp = result['count'] as Map<String, dynamic>;
      expect(countProp['type'], equals('integer'));
    });

    test('converts boolean property', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'active': {'type': 'boolean', 'description': 'Is active'},
        },
      });

      final activeProp = result['active'] as Map<String, dynamic>;
      expect(activeProp['type'], equals('boolean'));
      expect(activeProp['description'], equals('Is active'));
    });

    test('converts array property with items', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of tags',
          },
        },
      });

      final tagsProp = result['tags'] as Map<String, dynamic>;
      expect(tagsProp['type'], equals('array'));
      final tagsItems = tagsProp['items'] as Map<String, dynamic>;
      expect(tagsItems['type'], equals('string'));
      expect(tagsProp['description'], equals('List of tags'));
    });

    test('converts object property with nested properties', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'user': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
            'required': ['name'],
          },
        },
      });

      final userProp = result['user'] as Map<String, dynamic>;
      expect(userProp['type'], equals('object'));
      final userProps = userProp['properties'] as Map<String, dynamic>;
      final nameProp = userProps['name'] as Map<String, dynamic>;
      expect(nameProp['type'], equals('string'));
      expect(userProp['required'], equals(['name']));
    });

    test('converts deeply nested object', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'data': {
            'type': 'object',
            'properties': {
              'level1': {
                'type': 'object',
                'properties': {
                  'level2': {'type': 'string'},
                },
              },
            },
          },
        },
      });

      final dataProp = result['data'] as Map<String, dynamic>;
      expect(dataProp['type'], equals('object'));
      final dataProps = dataProp['properties'] as Map<String, dynamic>;
      final level1Prop = dataProps['level1'] as Map<String, dynamic>;
      expect(level1Prop['type'], equals('object'));
      final level1Props = level1Prop['properties'] as Map<String, dynamic>;
      final level2Prop = level1Props['level2'] as Map<String, dynamic>;
      expect(level2Prop['type'], equals('string'));
    });

    test('returns empty map for null properties', () {
      final result = SchemaMapper.convertProperties({});
      expect(result, isEmpty);
    });

    test('preserves unknown types', () {
      final result = SchemaMapper.convertProperties({
        'properties': {
          'custom': {'type': 'custom_type', 'extra': 'data'},
        },
      });

      final customProp = result['custom'] as Map<String, dynamic>;
      expect(customProp['type'], equals('custom_type'));
      expect(customProp['extra'], equals('data'));
    });
  });

  group('BlockHandlers', () {
    group('ToolUseBlockHandler', () {
      test('accumulates partial JSON deltas', () {
        final handler = ToolUseBlockHandler()
          ..toolName = 'test_tool'
          ..handleDelta({'partial_json': '{"name":'})
          ..handleDelta({'partial_json': '"John"}'});

        expect(handler.complete(), equals('{"name":"John"}'));
      });

      test('ignores null partial_json', () {
        final handler = ToolUseBlockHandler()
          ..handleDelta({})
          ..handleDelta({'other': 'data'});

        expect(handler.complete(), isEmpty);
      });

      test('reset clears buffer and toolName', () {
        final handler = ToolUseBlockHandler()
          ..toolName = 'test_tool'
          ..handleDelta({'partial_json': 'data'})
          ..reset();

        expect(handler.complete(), isEmpty);
        expect(handler.toolName, isNull);
      });
    });

    group('TextBlockHandler', () {
      test('accumulates text deltas', () {
        final handler = TextBlockHandler()
          ..handleDelta({'text': 'Hello '})
          ..handleDelta({'text': 'World!'});

        expect(handler.complete(), equals('Hello World!'));
      });

      test('ignores null text', () {
        final handler = TextBlockHandler()
          ..handleDelta({})
          ..handleDelta({'other': 'data'});

        expect(handler.complete(), isEmpty);
      });

      test('reset clears buffer', () {
        final handler = TextBlockHandler()
          ..handleDelta({'text': 'data'})
          ..reset();

        expect(handler.complete(), isEmpty);
      });
    });

    group('BlockHandlerFactory', () {
      test('creates ToolUseBlockHandler for tool_use type', () {
        final handler = BlockHandlerFactory.create('tool_use');
        expect(handler, isA<ToolUseBlockHandler>());
      });

      test('creates TextBlockHandler for text type', () {
        final handler = BlockHandlerFactory.create('text');
        expect(handler, isA<TextBlockHandler>());
      });

      test('returns null for unknown type', () {
        final handler = BlockHandlerFactory.create('unknown');
        expect(handler, isNull);
      });
    });
  });

  group('StreamParser', () {
    test('reset clears internal state', () {
      // Call reset to ensure no exception
      // Parser should be in clean state - no direct way to verify,
      // but we can verify it doesn't throw
      final parser = StreamParser()..reset();
      expect(parser.reset, returnsNormally);
    });

    test('parseStream yields nothing for empty stream', () async {
      final parser = StreamParser();
      final events = <A2uiMessageData>[];

      await for (final event in parser.parseStream(const Stream.empty())) {
        events.add(event);
      }

      expect(events, isEmpty);
    });

    test('parseStream handles content_block_start for tool_use', () async {
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        },
      ];

      final events = <A2uiMessageData>[];
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      // No complete blocks yet, so no messages
      expect(events, isEmpty);
    });

    test('parseStream handles content_block_delta', () async {
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"surfaceId":'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '"test"}'},
        },
      ];

      final events = <A2uiMessageData>[];
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      // Still no complete blocks
      expect(events, isEmpty);
    });

    test('parseStream handles non-tool_use content_block_start', () async {
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text'},
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ];

      final events = <A2uiMessageData>[];
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      // Text blocks don't produce A2UI messages
      expect(events, isEmpty);
    });

    test('parseStream processes complete tool_use block sequence', () async {
      // This test verifies the stream parser correctly processes
      // content_block_start -> content_block_delta -> content_block_stop sequence
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'unknown_tool'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"foo":'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '"bar"}'},
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ];

      final events = <A2uiMessageData>[];
      // Using unknown_tool to avoid TypeError from BeginRenderingData.fromJson
      // since _parseJson stub returns {} and known tools require specific fields.
      // ClaudeA2uiParser.parseToolUse returns null for unknown tools.
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      // Unknown tool returns null from parseToolUse, so no events yielded
      expect(events, isEmpty);
    });

    test('parseStream handles error mid-stream gracefully', () async {
      final parser = StreamParser();
      final events = <A2uiMessageData>[];
      Object? capturedError;

      // Use sync events list instead of StreamController to avoid timing issues
      Stream<Map<String, dynamic>> createErrorStream() async* {
        yield {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        };
        yield {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"surfaceId":'},
        };
        throw Exception('Connection lost');
      }

      try {
        await for (final event in parser.parseStream(createErrorStream())) {
          events.add(event);
        }
      } on Exception catch (e) {
        capturedError = e;
      }

      expect(capturedError, isA<Exception>());
      expect(events, isEmpty);
    });

    test('stream cancellation cleans up parser state', () async {
      final parser = StreamParser();

      // Create a stream that we can cancel mid-way
      Stream<Map<String, dynamic>> createInfiniteStream() async* {
        yield {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        };
        // Would continue indefinitely, but we'll cancel
      }

      // Start listening
      final events = <A2uiMessageData>[];
      final subscription = parser.parseStream(createInfiniteStream()).listen(
        events.add,
      );

      // Give it time to process then cancel
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      // Reset parser to ensure clean state
      parser.reset();

      // Should be able to parse a new stream without issues
      final newEvents = <A2uiMessageData>[];
      await for (final event in parser.parseStream(const Stream.empty())) {
        newEvents.add(event);
      }

      expect(newEvents, isEmpty);
      expect(parser.reset, returnsNormally);
    });

    test('parseStream yields BeginRenderingData for complete begin_rendering tool', () async {
      // BUG FIX TEST: This test verifies JSON is properly parsed
      // Previously _parseJson() returned {} which broke all parsing
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"surfaceId":"test-surface-123"}'},
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ];

      final events = <A2uiMessageData>[];
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      // Should yield exactly one BeginRenderingData with correct surfaceId
      expect(events, hasLength(1));
      expect(events.first, isA<BeginRenderingData>());
      final beginData = events.first as BeginRenderingData;
      expect(beginData.surfaceId, equals('test-surface-123'));
    });

    test('parseStream yields SurfaceUpdateData for complete surface_update tool', () async {
      // BUG FIX TEST: Verifies JSON parsing works for surface_update
      final parser = StreamParser();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'surface_update'},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': '{"surfaceId":"surface-1","widgets":[{"type":"Text","properties":{"text":"Hello"}}]}',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ];

      final events = <A2uiMessageData>[];
      await for (final event
          in parser.parseStream(Stream.fromIterable(inputEvents))) {
        events.add(event);
      }

      expect(events, hasLength(1));
      expect(events.first, isA<SurfaceUpdateData>());
      final updateData = events.first as SurfaceUpdateData;
      expect(updateData.surfaceId, equals('surface-1'));
      expect(updateData.widgets, hasLength(1));
      expect(updateData.widgets.first.type, equals('Text'));
    });
  });

  group('RateLimiter', () {
    test('executes request immediately when not rate limited', () async {
      final limiter = RateLimiter();
      var executed = false;

      await limiter.execute(() async {
        executed = true;
        return 'result';
      });

      expect(executed, isTrue);
      expect(limiter.isRateLimited, isFalse);
    });

    test('records 429 response and sets rate limited state', () {
      final limiter = RateLimiter()..recordRateLimit(statusCode: 429);

      expect(limiter.isRateLimited, isTrue);
    });

    test('parses Retry-After header as seconds', () {
      expect(RateLimiter.parseRetryAfter('30'), equals(const Duration(seconds: 30)));
      expect(RateLimiter.parseRetryAfter('60'), equals(const Duration(seconds: 60)));
      expect(RateLimiter.parseRetryAfter(null), isNull);
    });

    test('queues requests when rate limited', () async {
      // Set rate limited state with very short duration for test
      final limiter = RateLimiter()
        ..recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(milliseconds: 50),
        );
      var requestCount = 0;

      expect(limiter.isRateLimited, isTrue);

      // Queue a request (will complete after rate limit resets)
      final future = limiter.execute(() async => ++requestCount);

      // Request should be queued, not executed immediately
      expect(requestCount, equals(0));

      // Wait for rate limit to reset and queue to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Now the request should have been processed
      final result = await future;
      expect(result, equals(1));
    });

    test('ignores non-429 status codes', () {
      final limiter = RateLimiter()..recordRateLimit(statusCode: 500);

      expect(limiter.isRateLimited, isFalse);
    });

    test('dispose cancels timer and clears queue', () {
      final limiter = RateLimiter()
        ..recordRateLimit(statusCode: 429)
        ..dispose();

      // Should not throw
      expect(limiter.dispose, returnsNormally);
    });

    test('uses custom retry duration from Retry-After header', () {
      final limiter = RateLimiter()
        ..recordRateLimit(
          statusCode: 429,
          retryAfter: const Duration(seconds: 120),
        );

      expect(limiter.isRateLimited, isTrue);
    });
  });

  group('ClaudeStreamHandler', () {
    test('creates with default config', () {
      final handler = ClaudeStreamHandler();
      expect(handler.config, equals(StreamConfig.defaults));
    });

    test('creates with custom config', () {
      final handler = ClaudeStreamHandler(
        config: StreamConfig.defaults.copyWith(maxTokens: 8192),
      );
      expect(handler.config.maxTokens, equals(8192));
    });

    test('streamRequest yields TextDeltaEvent for text deltas', () async {
      final handler = ClaudeStreamHandler();
      final inputEvents = [
        {
          'type': 'content_block_delta',
          'delta': {'type': 'text_delta', 'text': 'Hello'},
        },
        {
          'type': 'content_block_delta',
          'delta': {'type': 'text_delta', 'text': ' World'},
        },
      ];

      final events = <StreamEvent>[];
      await for (final event in handler.streamRequest(
        messageStream: Stream.fromIterable(inputEvents),
      )) {
        events.add(event);
      }

      // Each text_delta produces both TextDeltaEvent and DeltaEvent
      expect(events.whereType<TextDeltaEvent>().length, equals(2));
      expect(events.whereType<DeltaEvent>().length, equals(2));

      final textEvents = events.whereType<TextDeltaEvent>().toList();
      expect(textEvents[0].text, equals('Hello'));
      expect(textEvents[1].text, equals(' World'));
    });

    test('streamRequest yields CompleteEvent on message_stop', () async {
      final handler = ClaudeStreamHandler();
      final inputEvents = [
        {'type': 'message_stop'},
      ];

      final events = <StreamEvent>[];
      await for (final event in handler.streamRequest(
        messageStream: Stream.fromIterable(inputEvents),
      )) {
        events.add(event);
      }

      expect(events.length, equals(1));
      expect(events.first, isA<CompleteEvent>());
    });

    test('streamRequest yields ErrorEvent on error type', () async {
      final handler = ClaudeStreamHandler();
      final inputEvents = [
        {
          'type': 'error',
          'error': {'message': 'API error occurred'},
        },
      ];

      final events = <StreamEvent>[];
      await for (final event in handler.streamRequest(
        messageStream: Stream.fromIterable(inputEvents),
      )) {
        events.add(event);
      }

      expect(events.length, equals(1));
      expect(events.first, isA<ErrorEvent>());
      final errorEvent = events.first as ErrorEvent;
      expect(errorEvent.error.message, equals('API error occurred'));
    });

    test('streamRequest handles content_block_start for tool_use', () async {
      final handler = ClaudeStreamHandler();
      final inputEvents = [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'name': 'begin_rendering'},
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ];

      final events = <StreamEvent>[];
      await for (final event in handler.streamRequest(
        messageStream: Stream.fromIterable(inputEvents),
      )) {
        events.add(event);
      }

      // No events from tool blocks in the main loop
      expect(events, isEmpty);
    });

    test('dispose resets internal state', () {
      final handler = ClaudeStreamHandler();

      // Should not throw
      expect(handler.dispose, returnsNormally);
    });

    test('StreamEvent sealed class exhaustive matching', () {
      String matchEvent(StreamEvent event) {
        return switch (event) {
          DeltaEvent() => 'delta',
          A2uiMessageEvent() => 'a2ui',
          TextDeltaEvent() => 'text',
          CompleteEvent() => 'complete',
          ErrorEvent() => 'error',
        };
      }

      expect(
        matchEvent(const DeltaEvent({})),
        equals('delta'),
      );
      expect(
        matchEvent(const A2uiMessageEvent(BeginRenderingData(surfaceId: 's'))),
        equals('a2ui'),
      );
      expect(
        matchEvent(const TextDeltaEvent('text')),
        equals('text'),
      );
      expect(
        matchEvent(const CompleteEvent()),
        equals('complete'),
      );
      expect(
        matchEvent(const ErrorEvent(StreamException('err'))),
        equals('error'),
      );
    });

    test('streamRequest handles unknown event types gracefully', () async {
      final handler = ClaudeStreamHandler();
      final inputEvents = [
        {'type': 'unknown_event', 'data': 'some data'},
        {'type': 'message_stop'},
      ];

      final events = <StreamEvent>[];
      await for (final event in handler.streamRequest(
        messageStream: Stream.fromIterable(inputEvents),
      )) {
        events.add(event);
      }

      // Only message_stop should produce an event
      expect(events.length, equals(1));
      expect(events.first, isA<CompleteEvent>());
    });
  });
}
