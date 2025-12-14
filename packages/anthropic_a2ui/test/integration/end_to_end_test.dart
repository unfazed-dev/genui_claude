/// End-to-end integration tests for the anthropic_a2ui package.
///
/// These tests verify the complete flow from schema definition through
/// request processing to A2UI message parsing.
library;

import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:test/test.dart';

import '../fixtures/mock_responses.dart';
import '../helpers/test_utils.dart';

void main() {
  group('End-to-End Integration Tests', () {
    group('Schema to ClaudeTools conversion', () {
      test('converts A2UI tool schemas to Claude tool format', () {
        final schemas = [
          const A2uiToolSchema(
            name: 'begin_rendering',
            description: 'Starts rendering a UI surface',
            inputSchema: {
              'type': 'object',
              'properties': {
                'surfaceId': {
                  'type': 'string',
                  'description': 'Unique identifier for the surface',
                },
                'parentSurfaceId': {
                  'type': 'string',
                  'description': 'Optional parent surface ID',
                },
              },
              'required': ['surfaceId'],
            },
          ),
        ];

        final claudeTools = A2uiToolConverter.toClaudeTools(schemas);

        expect(claudeTools, hasLength(1));
        expect(claudeTools.first['name'], equals('begin_rendering'));
        expect(claudeTools.first['input_schema'], isNotNull);
      });

      test('generates tool instructions for system prompt', () {
        final schemas = [
          const A2uiToolSchema(
            name: 'begin_rendering',
            description: 'Starts rendering a UI surface',
            inputSchema: {'type': 'object'},
          ),
          const A2uiToolSchema(
            name: 'surface_update',
            description: 'Updates a UI surface with widgets',
            inputSchema: {'type': 'object'},
          ),
        ];

        final instructions = A2uiToolConverter.generateToolInstructions(schemas);

        expect(instructions, contains('begin_rendering'));
        expect(instructions, contains('surface_update'));
      });
    });

    group('Message parsing flow', () {
      test('parses begin_rendering tool from message content', () {
        final input = MockToolUseBlocks.beginRendering(
          surfaceId: 'test-surface-123',
        );

        final result = ClaudeA2uiParser.parseToolUse(
          'begin_rendering',
          input['input'] as Map<String, dynamic>,
        );

        expect(result, isNotNull);
        expect(result, isA<BeginRenderingData>());
        expect(
          result,
          isBeginRenderingData(surfaceId: 'test-surface-123'),
        );
      });

      test('parses surface_update tool from message content', () {
        final input = MockToolUseBlocks.surfaceUpdateSimple(
          surfaceId: 'test-surface-123',
        );

        final result = ClaudeA2uiParser.parseToolUse(
          'surface_update',
          input['input'] as Map<String, dynamic>,
        );

        expect(result, isNotNull);
        expect(result, isA<SurfaceUpdateData>());
        expect(
          result,
          isSurfaceUpdateData(surfaceId: 'test-surface-123', widgetCount: 2),
        );
      });

      test('parses data_model_update tool from message content', () {
        final input = MockToolUseBlocks.dataModelUpdate(
          surfaceId: 'test-surface',
          updates: {'key': 'value', 'count': 42},
          scope: 'local',
        );

        final result = ClaudeA2uiParser.parseToolUse(
          'data_model_update',
          input['input'] as Map<String, dynamic>,
        );

        expect(result, isNotNull);
        expect(result, isA<DataModelUpdateData>());
        expect(result, isDataModelUpdateData(scope: 'local'));
      });

      test('parses delete_surface tool from message content', () {
        final input = MockToolUseBlocks.deleteSurface(
          surfaceId: 'test-surface-123',
          cascade: false,
        );

        final result = ClaudeA2uiParser.parseToolUse(
          'delete_surface',
          input['input'] as Map<String, dynamic>,
        );

        expect(result, isNotNull);
        expect(result, isA<DeleteSurfaceData>());
        expect(
          result,
          isDeleteSurfaceData(surfaceId: 'test-surface-123', cascade: false),
        );
      });

      test('returns null for unknown tool names', () {
        final result = ClaudeA2uiParser.parseToolUse(
          'unknown_tool',
          {'foo': 'bar'},
        );

        expect(result, isNull);
      });
    });

    group('Stream handler flow', () {
      test('processes text delta events', () async {
        final handler = ClaudeStreamHandler();
        final inputEvents = [
          MockStreamEvents.textDelta(index: 0, text: 'Hello'),
          MockStreamEvents.textDelta(index: 0, text: ' World'),
          MockStreamEvents.messageStop,
        ];

        final events = await collectStream(
          handler.streamRequest(
            messageStream: Stream.fromIterable(inputEvents),
          ),
        );

        final textEvents = events.whereType<TextDeltaEvent>().toList();
        expect(textEvents, hasLength(2));
        expect(textEvents[0], isTextDeltaEvent('Hello'));
        expect(textEvents[1], isTextDeltaEvent(' World'));
      });

      test('yields CompleteEvent at end of stream', () async {
        final handler = ClaudeStreamHandler();
        final inputEvents = [
          MockStreamEvents.textDelta(index: 0, text: 'Test'),
          MockStreamEvents.messageStop,
        ];

        final events = await collectStream(
          handler.streamRequest(
            messageStream: Stream.fromIterable(inputEvents),
          ),
        );

        expect(events.last, isCompleteEvent);
      });

      test('yields ErrorEvent on error', () async {
        final handler = ClaudeStreamHandler();
        final inputEvents = [
          MockStreamEvents.error(message: 'API Error'),
        ];

        final events = await collectStream(
          handler.streamRequest(
            messageStream: Stream.fromIterable(inputEvents),
          ),
        );

        expect(events, hasLength(1));
        expect(events.first, isErrorEvent('API Error'));
      });
    });

    group('StreamParser integration', () {
      test('parses stream events with tool_use blocks', () async {
        final parser = StreamParser();
        final inputEvents = [
          MockStreamEvents.toolUseStart(
            index: 0,
            toolName: 'unknown_test_tool',
          ),
          MockStreamEvents.inputJsonDelta(
            index: 0,
            partialJson: '{"test": "value"}',
          ),
          MockStreamEvents.contentBlockStop(index: 0),
        ];

        final messages = await collectStream(
          parser.parseStream(Stream.fromIterable(inputEvents)),
        );

        // Unknown tools return null, so no messages yielded
        expect(messages, isEmpty);
      });

      test('handles multiple content blocks in sequence', () async {
        final parser = StreamParser();
        final inputEvents = [
          // First text block
          MockStreamEvents.textStart(index: 0),
          MockStreamEvents.textDelta(index: 0, text: 'Some text'),
          MockStreamEvents.contentBlockStop(index: 0),
          // Second tool_use block (unknown tool)
          MockStreamEvents.toolUseStart(index: 1, toolName: 'unknown_tool'),
          MockStreamEvents.inputJsonDelta(index: 1, partialJson: '{}'),
          MockStreamEvents.contentBlockStop(index: 1),
        ];

        final messages = await collectStream(
          parser.parseStream(Stream.fromIterable(inputEvents)),
        );

        // Text blocks and unknown tools don't yield A2UI messages
        expect(messages, isEmpty);
      });

      test('reset allows reuse of parser', () async {
        final parser = StreamParser();

        // First parse
        final events1 = [
          MockStreamEvents.textStart(index: 0),
          MockStreamEvents.contentBlockStop(index: 0),
        ];
        await collectStream(parser.parseStream(Stream.fromIterable(events1)));

        // Reset
        parser.reset();

        // Second parse should work
        final events2 = [
          MockStreamEvents.textStart(index: 0),
          MockStreamEvents.contentBlockStop(index: 0),
        ];
        final messages = await collectStream(
          parser.parseStream(Stream.fromIterable(events2)),
        );

        expect(messages, isEmpty);
      });
    });

    group('Validation flow', () {
      test('validates correct tool input', () {
        const schemas = [
          A2uiToolSchema(
            name: 'begin_rendering',
            description: 'Test tool',
            inputSchema: {
              'type': 'object',
              'properties': {
                'surfaceId': {'type': 'string'},
              },
            },
            requiredFields: ['surfaceId'],
          ),
        ];

        final result = A2uiToolConverter.validateToolInput(
          'begin_rendering',
          {'surfaceId': 'test-123'},
          schemas,
        );

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('validates and reports missing required field', () {
        const schemas = [
          A2uiToolSchema(
            name: 'begin_rendering',
            description: 'Test tool',
            inputSchema: {
              'type': 'object',
              'properties': {
                'surfaceId': {'type': 'string'},
              },
            },
            requiredFields: ['surfaceId'],
          ),
        ];

        final result = A2uiToolConverter.validateToolInput(
          'begin_rendering',
          <String, dynamic>{}, // Missing surfaceId
          schemas,
        );

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      });
    });

    group('Rate limiter integration', () {
      test('executes requests when not rate limited', () async {
        final limiter = RateLimiter();
        var executed = false;

        await limiter.execute(() async {
          executed = true;
          return 'result';
        });

        expect(executed, isTrue);
        expect(limiter.isRateLimited, isFalse);
      });

      test('respects rate limit state', () async {
        final limiter = RateLimiter()
          // Set rate limited with short duration
          ..recordRateLimit(
            statusCode: 429,
            retryAfter: const Duration(milliseconds: 50),
          );

        expect(limiter.isRateLimited, isTrue);

        // Wait for reset
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(limiter.isRateLimited, isFalse);
      });
    });

    group('Error recovery flow', () {
      test('StreamHandler handles stream errors gracefully', () async {
        final handler = ClaudeStreamHandler();

        Stream<Map<String, dynamic>> errorStream() async* {
          yield MockStreamEvents.textDelta(index: 0, text: 'Start');
          throw Exception('Connection lost');
        }

        Object? caughtError;
        final events = <StreamEvent>[];

        try {
          await for (final event in handler.streamRequest(
            messageStream: errorStream(),
          )) {
            events.add(event);
          }
        } on Exception catch (e) {
          caughtError = e;
        }

        expect(caughtError, isNotNull);
        // Some events may have been processed before error
        expect(events.whereType<TextDeltaEvent>(), isNotEmpty);
      });

      test('RetryPolicy determines retry eligibility', () {
        const policy = RetryPolicy.defaults;

        // First attempt should retry
        expect(
          policy.shouldRetry(
            const StreamException('error', isRetryable: true),
            1,
          ),
          isTrue,
        );

        // Exceeding max attempts should not retry
        expect(
          policy.shouldRetry(
            const StreamException('error', isRetryable: true),
            10,
          ),
          isFalse,
        );

        // Non-retryable errors should not retry
        expect(
          policy.shouldRetry(
            const StreamException('error'),
            1,
          ),
          isFalse,
        );
      });
    });

    group('Tool roundtrip tests', () {
      test('begin_rendering toJson/fromJson roundtrip', () {
        const original = BeginRenderingData(
          surfaceId: 'test-surface',
          parentSurfaceId: 'parent-surface',
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final restored = BeginRenderingData.fromJson(json);

        expect(restored.surfaceId, equals(original.surfaceId));
        expect(restored.parentSurfaceId, equals(original.parentSurfaceId));
        expect(restored.metadata, equals(original.metadata));
      });

      test('surface_update toJson/fromJson roundtrip', () {
        final original = SurfaceUpdateData(
          surfaceId: 'test-surface',
          widgets: [
            textWidget(content: 'Hello'),
            buttonWidget(label: 'Click'),
          ],
          append: true,
        );

        final json = original.toJson();
        final restored = SurfaceUpdateData.fromJson(json);

        expect(restored.surfaceId, equals(original.surfaceId));
        expect(restored.widgets.length, equals(original.widgets.length));
        expect(restored.append, equals(original.append));
      });

      test('data_model_update toJson/fromJson roundtrip', () {
        const original = DataModelUpdateData(
          updates: {'count': 42, 'name': 'Test'},
          scope: 'local',
        );

        final json = original.toJson();
        final restored = DataModelUpdateData.fromJson(json);

        expect(restored.updates, equals(original.updates));
        expect(restored.scope, equals(original.scope));
      });

      test('delete_surface toJson/fromJson roundtrip', () {
        const original = DeleteSurfaceData(
          surfaceId: 'test-surface',
          cascade: false,
        );

        final json = original.toJson();
        final restored = DeleteSurfaceData.fromJson(json);

        expect(restored.surfaceId, equals(original.surfaceId));
        expect(restored.cascade, equals(original.cascade));
      });
    });

    group('Widget tree integration', () {
      test('creates nested widget structure', () {
        final container = containerWidget(
          type: 'column',
          properties: {'spacing': 16},
          children: [
            textWidget(content: 'Header'),
            containerWidget(
              type: 'row',
              children: [
                buttonWidget(label: 'Cancel'),
                buttonWidget(label: 'Submit'),
              ],
            ),
          ],
        );

        expect(container.type, equals('column'));
        expect(container.children, hasLength(2));
        expect(container.children![0].type, equals('text'));
        expect(container.children![1].type, equals('row'));
        expect(container.children![1].children, hasLength(2));
      });

      test('widget node copyWith preserves unchanged values', () {
        final original = textWidget(content: 'Original');

        final modified = original.copyWith(
          type: 'modified_text',
        );

        expect(modified.type, equals('modified_text'));
        expect(modified.properties, equals(original.properties));
      });

      test('widget node toJson/fromJson roundtrip', () {
        final original = containerWidget(
          type: 'column',
          children: [textWidget(content: 'Hello')],
          dataBinding: 'dataKey',
        );

        final json = original.toJson();
        final restored = WidgetNode.fromJson(json);

        expect(restored.type, equals(original.type));
        expect(restored.children?.length, equals(original.children?.length));
        expect(restored.dataBinding, equals(original.dataBinding));
      });
    });
  });
}
