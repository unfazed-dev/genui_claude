// ignore_for_file: avoid_print
/// Streaming example for a2ui_claude package.
///
/// This example demonstrates:
/// - Setting up ClaudeStreamHandler with custom configuration
/// - Processing streaming events with pattern matching
/// - Handling text deltas, A2UI messages, and errors
/// - Progressive UI rendering from stream events
library;

import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart';

void main() async {
  print('=== a2ui_claude Streaming Example ===\n');

  // 1. Create stream handler with custom config
  print('1. Creating stream handler with custom config...');
  final handler = ClaudeStreamHandler(
    config: const StreamConfig(
      maxTokens: 8192,
      timeout: Duration(seconds: 120),
      retryAttempts: 5,
    ),
  );
  print('   Handler created with config: ${handler.config}\n');

  // 2. Simulate streaming response
  print('2. Processing simulated stream...');
  await _demonstrateStreaming(handler);

  // 3. Clean up
  print('\n3. Disposing handler...');
  handler.dispose();
  print('   Handler disposed');

  print('\n=== Example Complete ===');
}

/// Demonstrate streaming response processing.
Future<void> _demonstrateStreaming(ClaudeStreamHandler handler) async {
  // Create a mock stream of Claude SSE events
  final mockStream = _createMockStream();

  // Track accumulated state
  final textBuffer = StringBuffer();
  final receivedMessages = <A2uiMessageData>[];

  // Process stream events
  await for (final event in handler.streamRequest(messageStream: mockStream)) {
    switch (event) {
      case TextDeltaEvent(:final text):
        textBuffer.write(text);
        print('   [TextDelta] "$text"');

      case A2uiMessageEvent(:final message):
        receivedMessages.add(message);
        print('   [A2uiMessage] ${_describeMessage(message)}');

      case DeltaEvent(:final data):
        // Raw delta for custom processing
        final deltaType = data['type'] as String?;
        print('   [Delta] type: $deltaType');

      case CompleteEvent():
        print('   [Complete] Stream finished');
        print('   -> Total text: "$textBuffer"');
        print('   -> Total A2UI messages: ${receivedMessages.length}');

      case ErrorEvent(:final error):
        print('   [Error] ${error.message}');
        if (error is StreamException && error.isRetryable) {
          print('   -> Error is retryable');
        }

      case ThinkingEvent(:final content, :final isComplete):
        if (content.isNotEmpty) {
          final preview = content.length > 50
              ? '${content.substring(0, 50)}...'
              : content;
          print('   [Thinking] "$preview"');
        }
        if (isComplete) {
          print('   [Thinking] Block complete');
        }
    }
  }
}

/// Create a mock stream simulating Claude SSE events.
Stream<Map<String, dynamic>> _createMockStream() async* {
  // Simulate network delay
  await Future<void>.delayed(const Duration(milliseconds: 50));

  // Text content streaming
  yield <String, dynamic>{
    'type': 'content_block_delta',
    'index': 0,
    'delta': <String, dynamic>{'type': 'text_delta', 'text': 'Creating '},
  };
  await Future<void>.delayed(const Duration(milliseconds: 20));

  yield <String, dynamic>{
    'type': 'content_block_delta',
    'index': 0,
    'delta': <String, dynamic>{'type': 'text_delta', 'text': 'a weather '},
  };
  await Future<void>.delayed(const Duration(milliseconds: 20));

  yield <String, dynamic>{
    'type': 'content_block_delta',
    'index': 0,
    'delta': <String, dynamic>{'type': 'text_delta', 'text': 'widget...'},
  };
  await Future<void>.delayed(const Duration(milliseconds: 20));

  // Tool use block start
  yield <String, dynamic>{
    'type': 'content_block_start',
    'index': 1,
    'content_block': <String, dynamic>{
      'type': 'tool_use',
      'id': 'toolu_001',
      'name': 'begin_rendering',
      'input': <String, dynamic>{},
    },
  };

  // Tool input delta (partial JSON)
  yield <String, dynamic>{
    'type': 'content_block_delta',
    'index': 1,
    'delta': <String, dynamic>{
      'type': 'input_json_delta',
      'partial_json': '{"surfaceId": "weather-widget"}',
    },
  };

  // Tool block stop
  yield <String, dynamic>{'type': 'content_block_stop', 'index': 1};

  // Another tool use
  yield <String, dynamic>{
    'type': 'content_block_start',
    'index': 2,
    'content_block': <String, dynamic>{
      'type': 'tool_use',
      'id': 'toolu_002',
      'name': 'surface_update',
      'input': <String, dynamic>{},
    },
  };

  yield <String, dynamic>{
    'type': 'content_block_delta',
    'index': 2,
    'delta': <String, dynamic>{
      'type': 'input_json_delta',
      'partial_json': '''
{
  "surfaceId": "weather-widget",
  "widgets": [
    {
      "type": "Card",
      "props": {"elevation": 4},
      "children": [
        {"type": "Text", "props": {"text": "San Francisco"}},
        {"type": "Text", "props": {"text": "72F Sunny", "style": "headline"}}
      ]
    }
  ]
}
''',
    },
  };

  yield <String, dynamic>{'type': 'content_block_stop', 'index': 2};

  // Message stop
  yield <String, dynamic>{'type': 'message_stop'};
}

/// Describe an A2UI message for logging.
String _describeMessage(A2uiMessageData message) {
  return switch (message) {
    BeginRenderingData(:final surfaceId) => 'BeginRendering($surfaceId)',
    SurfaceUpdateData(:final surfaceId, :final widgets) =>
      'SurfaceUpdate($surfaceId, ${widgets.length} widgets)',
    DataModelUpdateData(:final updates) =>
      'DataModelUpdate(${updates.keys.length} keys)',
    DeleteSurfaceData(:final surfaceId) => 'DeleteSurface($surfaceId)',
  };
}
