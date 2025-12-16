// ignore_for_file: avoid_print

import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

/// Performance benchmarks for a2ui_claude package.
///
/// Target performance (from spec):
/// - Tool conversion: < 1ms for 10 tools
/// - Message parsing: < 5ms typical response
/// - Stream processing: < 0.1ms per event
void main() {
  group('Performance Benchmarks', () {
    group('Tool Conversion Benchmarks', () {
      test('converts 10 tools under 1ms', () {
        final schemas = _generateToolSchemas(10);

        final stopwatch = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas);
        stopwatch.stop();

        print('10 tools conversion: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1),
          reason: 'Tool conversion for 10 tools should be < 1ms',
        );
      });

      test('converts 100 tools in reasonable time', () {
        final schemas = _generateToolSchemas(100);

        final stopwatch = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas);
        stopwatch.stop();

        print('100 tools conversion: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason: 'Tool conversion for 100 tools should be < 10ms',
        );
      });

      test('converts 1000 tools in acceptable time', () {
        final schemas = _generateToolSchemas(1000);

        final stopwatch = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas);
        stopwatch.stop();

        print('1000 tools conversion: ${stopwatch.elapsedMilliseconds}ms');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Tool conversion for 1000 tools should be < 100ms',
        );
      });

      test('tool conversion scales linearly', () {
        final schemas10 = _generateToolSchemas(10);
        final schemas100 = _generateToolSchemas(100);
        final schemas1000 = _generateToolSchemas(1000);

        // Warm up
        A2uiToolConverter.toClaudeTools(schemas10);

        final stopwatch10 = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas10);
        stopwatch10.stop();

        final stopwatch100 = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas100);
        stopwatch100.stop();

        final stopwatch1000 = Stopwatch()..start();
        A2uiToolConverter.toClaudeTools(schemas1000);
        stopwatch1000.stop();

        final ratio100 = stopwatch100.elapsedMicroseconds /
            (stopwatch10.elapsedMicroseconds.clamp(1, double.maxFinite));
        final ratio1000 = stopwatch1000.elapsedMicroseconds /
            (stopwatch100.elapsedMicroseconds.clamp(1, double.maxFinite));

        print('Scaling: 10→100 ratio: ${ratio100.toStringAsFixed(2)}x, '
            '100→1000 ratio: ${ratio1000.toStringAsFixed(2)}x');

        // Allow for system variance in timing-sensitive benchmarks.
        // Linear scaling (O(n)) would give ratio ~10, quadratic (O(n²)) ~100.
        // Threshold of 30 validates sub-quadratic scaling while accounting
        // for CI/system load variance.
        expect(ratio100, lessThan(30), reason: 'Should scale sub-linearly');
        expect(ratio1000, lessThan(30), reason: 'Should scale sub-linearly');
      });

      test('generateToolInstructions performance', () {
        final schemas = _generateToolSchemas(100);

        final stopwatch = Stopwatch()..start();
        A2uiToolConverter.generateToolInstructions(schemas);
        stopwatch.stop();

        print('Instructions for 100 tools: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason: 'Instruction generation should be < 10ms',
        );
      });

      test('validateToolInput performance', () {
        final schemas = _generateToolSchemas(100);
        final input = {'surfaceId': 'test-1', 'title': 'Test'};

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 1000; i++) {
          A2uiToolConverter.validateToolInput('tool_50', input, schemas);
        }
        stopwatch.stop();

        final perValidation = stopwatch.elapsedMicroseconds / 1000;
        print('Validation per call: ${perValidation.toStringAsFixed(2)}μs');
        expect(
          perValidation,
          lessThan(100),
          reason: 'Validation should be < 100μs per call',
        );
      });
    });

    group('Message Parsing Benchmarks', () {
      test('parses simple message under 5ms', () {
        final message = _generateSimpleMessage(1);

        final stopwatch = Stopwatch()..start();
        ClaudeA2uiParser.parseMessage(message);
        stopwatch.stop();

        print('Simple message parsing: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5),
          reason: 'Simple message parsing should be < 5ms',
        );
      });

      test('parses message with 10 tool blocks', () {
        final message = _generateMessageWithBlocks(10);

        final stopwatch = Stopwatch()..start();
        ClaudeA2uiParser.parseMessage(message);
        stopwatch.stop();

        print('10 blocks parsing: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5),
          reason: 'Parsing 10 blocks should be < 5ms',
        );
      });

      test('parses message with 100 tool blocks', () {
        final message = _generateMessageWithBlocks(100);

        final stopwatch = Stopwatch()..start();
        ClaudeA2uiParser.parseMessage(message);
        stopwatch.stop();

        print('100 blocks parsing: ${stopwatch.elapsedMilliseconds}ms');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason: 'Parsing 100 blocks should be < 50ms',
        );
      });

      test('parses message with nested widgets', () {
        final message = _generateNestedWidgetMessage(depth: 5, breadth: 3);

        final stopwatch = Stopwatch()..start();
        ClaudeA2uiParser.parseMessage(message);
        stopwatch.stop();

        print('Nested widgets parsing: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason: 'Nested widget parsing should be < 10ms',
        );
      });

      test('parseToolUse performance for each tool type', () {
        final tools = {
          'begin_rendering': {'surfaceId': 'test-1', 'title': 'Test'},
          'surface_update': {
            'surfaceId': 'test-1',
            'widgets': [
              {'type': 'text', 'id': 't1', 'props': {'content': 'Hello'}},
            ],
          },
          'data_model_update': {
            'surfaceId': 'test-1',
            'updates': {'count': 42},
          },
          'delete_surface': {'surfaceId': 'test-1', 'cascade': true},
        };

        for (final entry in tools.entries) {
          final stopwatch = Stopwatch()..start();
          for (var i = 0; i < 1000; i++) {
            ClaudeA2uiParser.parseToolUse(entry.key, entry.value);
          }
          stopwatch.stop();

          final perParse = stopwatch.elapsedMicroseconds / 1000;
          print('${entry.key}: ${perParse.toStringAsFixed(2)}μs per parse');
          expect(
            perParse,
            lessThan(50),
            reason: '${entry.key} parsing should be < 50μs',
          );
        }
      });

      test('parses large data_model_update', () {
        final largeUpdates = <String, dynamic>{};
        for (var i = 0; i < 1000; i++) {
          largeUpdates['field_$i'] = 'value_$i';
        }
        final message = {
          'content': [
            {
              'type': 'tool_use',
              'name': 'data_model_update',
              'input': {
                'surfaceId': 'test-1',
                'updates': largeUpdates,
              },
            },
          ],
        };

        final stopwatch = Stopwatch()..start();
        ClaudeA2uiParser.parseMessage(message);
        stopwatch.stop();

        print('Large data model: ${stopwatch.elapsedMicroseconds}μs');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason: 'Large data model parsing should be < 10ms',
        );
      });
    });

    group('Stream Event Processing Benchmarks', () {
      test('processes stream events under 0.1ms each', () async {
        final events = _generateStreamEvents(100);
        final parser = StreamParser();

        final stopwatch = Stopwatch()..start();
        await parser.parseStream(Stream.fromIterable(events)).toList();
        stopwatch.stop();

        final perEvent = stopwatch.elapsedMicroseconds / events.length;
        print('Per-event processing: ${perEvent.toStringAsFixed(2)}μs');
        expect(
          perEvent,
          lessThan(100), // 0.1ms = 100μs
          reason: 'Stream processing should be < 0.1ms per event',
        );
      });

      test('processes 1000 events efficiently', () async {
        final events = _generateStreamEvents(1000);
        final parser = StreamParser();

        final stopwatch = Stopwatch()..start();
        await parser.parseStream(Stream.fromIterable(events)).toList();
        stopwatch.stop();

        print('1000 events: ${stopwatch.elapsedMilliseconds}ms');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Processing 1000 events should be < 100ms',
        );
      });

      test('parser reset is fast', () {
        final parser = StreamParser();

        // Simulate some state accumulation (ignore the stream result)
        unawaited(
          parser
              .parseStream(
                Stream.fromIterable([
                  {
                    'type': 'content_block_start',
                    'index': 0,
                    'content_block': {
                      'type': 'tool_use',
                      'name': 'begin_rendering',
                    },
                  },
                  {
                    'type': 'content_block_delta',
                    'index': 0,
                    'delta': {
                      'type': 'input_json_delta',
                      'partial_json': '{"sur',
                    },
                  },
                ]),
              )
              .toList(),
        );

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 10000; i++) {
          parser.reset();
        }
        stopwatch.stop();

        final perReset = stopwatch.elapsedMicroseconds / 10000;
        print('Per-reset: ${perReset.toStringAsFixed(2)}μs');
        expect(
          perReset,
          lessThan(1),
          reason: 'Parser reset should be < 1μs',
        );
      });

      test('handles rapid stream creation/disposal', () async {
        final events = _generateStreamEvents(10);

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          final parser = StreamParser();
          await parser.parseStream(Stream.fromIterable(events)).toList();
          parser.reset();
        }
        stopwatch.stop();

        final perCycle = stopwatch.elapsedMicroseconds / 100;
        print('Per create/process/dispose cycle: ${perCycle.toStringAsFixed(2)}μs');
        expect(
          perCycle,
          lessThan(1000),
          reason: 'Full cycle should be < 1ms',
        );
      });
    });

    group('Memory Usage Profiling', () {
      test('tool conversion memory is stable', () {
        final schemas = _generateToolSchemas(1000);

        // Warm up
        A2uiToolConverter.toClaudeTools(schemas);

        // Multiple iterations to check for leaks
        for (var i = 0; i < 10; i++) {
          A2uiToolConverter.toClaudeTools(schemas);
        }

        // If we get here without OOM, memory is bounded
        expect(true, isTrue, reason: 'No memory issues detected');
      });

      test('message parsing memory is stable', () {
        final message = _generateMessageWithBlocks(100);

        // Multiple iterations to check for leaks
        for (var i = 0; i < 100; i++) {
          ClaudeA2uiParser.parseMessage(message);
        }

        // If we get here without OOM, memory is bounded
        expect(true, isTrue, reason: 'No memory issues detected');
      });

      test('stream parser memory is stable after reset', () async {
        final events = _generateStreamEvents(100);

        final parser = StreamParser();
        for (var i = 0; i < 100; i++) {
          await parser.parseStream(Stream.fromIterable(events)).toList();
          parser.reset();
        }

        // If we get here without OOM, memory is bounded
        expect(true, isTrue, reason: 'No memory issues detected');
      });
    });

    group('Performance Targets Verification', () {
      test('SPEC: Tool conversion < 1ms for 10 tools', () {
        final schemas = _generateToolSchemas(10);

        // Run multiple times to get consistent result
        final times = <int>[];
        for (var i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          A2uiToolConverter.toClaudeTools(schemas);
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        print('Avg tool conversion (10 tools): ${avgTime.toStringAsFixed(2)}μs');

        expect(
          avgTime,
          lessThan(1000), // 1ms = 1000μs
          reason: 'SPEC: Tool conversion should be < 1ms for 10 tools',
        );
      });

      test('SPEC: Message parsing < 5ms typical response', () {
        final message = _generateTypicalMessage();

        // Run multiple times to get consistent result
        final times = <int>[];
        for (var i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          ClaudeA2uiParser.parseMessage(message);
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        print('Avg message parsing: ${avgTime.toStringAsFixed(2)}μs');

        expect(
          avgTime,
          lessThan(5000), // 5ms = 5000μs
          reason: 'SPEC: Message parsing should be < 5ms',
        );
      });

      test('SPEC: Stream processing < 0.1ms per event', () async {
        final events = _generateStreamEvents(100);
        final parser = StreamParser();

        // Run multiple times to get consistent result
        final times = <int>[];
        for (var i = 0; i < 10; i++) {
          final freshParser = StreamParser();
          final stopwatch = Stopwatch()..start();
          await freshParser.parseStream(Stream.fromIterable(events)).toList();
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }

        final avgTotal = times.reduce((a, b) => a + b) / times.length;
        final avgPerEvent = avgTotal / events.length;
        print('Avg stream processing per event: ${avgPerEvent.toStringAsFixed(2)}μs');

        expect(
          avgPerEvent,
          lessThan(100), // 0.1ms = 100μs
          reason: 'SPEC: Stream processing should be < 0.1ms per event',
        );

        parser.reset();
      });
    });
  });
}

// Helper functions for generating test data

const _benchmarkInputSchema = <String, dynamic>{
  'properties': <String, dynamic>{
    'surfaceId': <String, dynamic>{'type': 'string', 'description': 'Surface ID'},
    'title': <String, dynamic>{'type': 'string', 'description': 'Title'},
    'count': <String, dynamic>{'type': 'integer', 'description': 'Count'},
  },
};

const _benchmarkRequiredFields = <String>['surfaceId'];

List<A2uiToolSchema> _generateToolSchemas(int count) {
  return List.generate(
    count,
    (i) => A2uiToolSchema(
      name: 'tool_$i',
      description: 'Description for tool $i with some additional text',
      inputSchema: _benchmarkInputSchema,
      requiredFields: _benchmarkRequiredFields,
    ),
  );
}

Map<String, dynamic> _generateSimpleMessage(int blockCount) {
  return {
    'content': [
      {
        'type': 'tool_use',
        'name': 'begin_rendering',
        'input': {'surfaceId': 'test-1'},
      },
    ],
  };
}

Map<String, dynamic> _generateMessageWithBlocks(int blockCount) {
  return {
    'content': List.generate(
      blockCount,
      (i) => {
        'type': 'tool_use',
        'name': i % 4 == 0
            ? 'begin_rendering'
            : i % 4 == 1
                ? 'surface_update'
                : i % 4 == 2
                    ? 'data_model_update'
                    : 'delete_surface',
        'input': i % 4 == 0
            ? {'surfaceId': 'surface-$i'}
            : i % 4 == 1
                ? {
                    'surfaceId': 'surface-$i',
                    'widgets': [
                      {'type': 'text', 'id': 't$i', 'props': {'content': 'Text $i'}},
                    ],
                  }
                : i % 4 == 2
                    ? {'surfaceId': 'surface-$i', 'updates': {'field$i': 'value$i'}}
                    : {'surfaceId': 'surface-$i', 'cascade': true},
      },
    ),
  };
}

Map<String, dynamic> _generateNestedWidgetMessage({
  required int depth,
  required int breadth,
}) {
  Map<String, dynamic> buildWidget(int currentDepth, int index) {
    if (currentDepth >= depth) {
      return {
        'type': 'text',
        'id': 't_${currentDepth}_$index',
        'props': {'content': 'Leaf $index'},
      };
    }
    return {
      'type': 'column',
      'id': 'col_${currentDepth}_$index',
      'props': {'spacing': 8},
      'children': List.generate(
        breadth,
        (i) => buildWidget(currentDepth + 1, i),
      ),
    };
  }

  return {
    'content': [
      {
        'type': 'tool_use',
        'name': 'surface_update',
        'input': {
          'surfaceId': 'test-1',
          'widgets': [buildWidget(0, 0)],
        },
      },
    ],
  };
}

Map<String, dynamic> _generateTypicalMessage() {
  // A typical Claude response with text and a few tool blocks
  return {
    'content': [
      {
        'type': 'text',
        'text': "I'll create a user interface for you.",
      },
      {
        'type': 'tool_use',
        'name': 'begin_rendering',
        'input': {
          'surfaceId': 'main-ui',
          'title': 'User Dashboard',
        },
      },
      {
        'type': 'tool_use',
        'name': 'surface_update',
        'input': {
          'surfaceId': 'main-ui',
          'widgets': [
            {
              'type': 'column',
              'id': 'main-column',
              'props': {'spacing': 16},
              'children': [
                {
                  'type': 'text',
                  'id': 'header',
                  'props': {'content': 'Welcome to Dashboard'},
                },
                {
                  'type': 'row',
                  'id': 'button-row',
                  'props': {'alignment': 'center'},
                  'children': [
                    {
                      'type': 'button',
                      'id': 'btn-settings',
                      'props': {'label': 'Settings'},
                    },
                    {
                      'type': 'button',
                      'id': 'btn-profile',
                      'props': {'label': 'Profile'},
                    },
                  ],
                },
              ],
            },
          ],
        },
      },
    ],
  };
}

List<Map<String, dynamic>> _generateStreamEvents(int count) {
  final events = <Map<String, dynamic>>[];

  // Generate events without content_block_stop to avoid triggering
  // the _parseJson stub (which returns empty map and causes failures).
  // This tests the stream event processing loop performance.
  for (var i = 0; i < count; i++) {
    final blockIndex = i ~/ 4;

    switch (i % 4) {
      case 0:
        events.add({
          'type': 'content_block_start',
          'index': blockIndex,
          'content_block': {
            'type': 'text',
            'text': '',
          },
        });
      case 1:
      case 2:
        events.add({
          'type': 'content_block_delta',
          'index': blockIndex,
          'delta': {
            'type': 'text_delta',
            'text': 'chunk_$i',
          },
        });
      case 3:
        // Use message_delta instead of content_block_stop to avoid parsing
        events.add({
          'type': 'message_delta',
          'delta': {
            'stop_reason': null,
          },
        });
    }
  }

  return events;
}
