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
        properties: {},
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
      const result = ParseResult.empty();
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
  });

  group('ValidationResult', () {
    test('valid result', () {
      const result = ValidationResult.valid();
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
  });
}
