import 'dart:async';
import 'dart:convert';

import 'package:a2ui_claude/src/exceptions/exceptions.dart';
import 'package:a2ui_claude/src/models/models.dart';
import 'package:a2ui_claude/src/parser/parser.dart';
import 'package:logging/logging.dart';

final _log = Logger('ClaudeStreamHandler');

/// Manages streaming connections to Claude API.
///
/// Provides progressive message delivery as tool_use blocks complete.
class ClaudeStreamHandler {
  /// Creates a stream handler with optional configuration.
  ClaudeStreamHandler({this.config = StreamConfig.defaults});

  /// Configuration for streaming requests.
  final StreamConfig config;

  /// Creates a streaming request and parses responses.
  ///
  /// Yields [StreamEvent] objects as the response streams in.
  /// Processes both text deltas and tool use blocks in a single pass.
  Stream<StreamEvent> streamRequest({
    required Stream<Map<String, dynamic>> messageStream,
  }) async* {
    // Tool use tracking for parsing A2UI messages
    final toolBuffers = <String, StringBuffer>{};
    final toolNames = <String, String>{};

    // Thinking block tracking
    final thinkingBlocks = <String>{};

    await for (final event in messageStream) {
      final type = event['type'] as String?;

      switch (type) {
        case 'content_block_start':
          final index = event['index']?.toString() ?? '0';
          final contentBlock = event['content_block'] as Map<String, dynamic>?;
          final blockType = contentBlock?['type'] as String?;

          if (blockType == 'tool_use') {
            // Start tracking this tool use block
            toolNames[index] = contentBlock!['name'] as String;
            toolBuffers[index] = StringBuffer();
          } else if (blockType == 'thinking') {
            // Start tracking this thinking block
            thinkingBlocks.add(index);
          }

        case 'content_block_delta':
          final index = event['index']?.toString() ?? '0';
          final delta = event['delta'] as Map<String, dynamic>?;
          if (delta != null) {
            final deltaType = delta['type'] as String?;

            if (deltaType == 'text_delta') {
              // Emit text delta events
              final text = delta['text'] as String?;
              if (text != null) {
                yield TextDeltaEvent(text);
              }
            } else if (deltaType == 'input_json_delta') {
              // Accumulate tool input JSON
              final partialJson = delta['partial_json'] as String?;
              if (partialJson != null) {
                toolBuffers[index]?.write(partialJson);
              }
            } else if (deltaType == 'thinking_delta') {
              // Emit thinking delta events
              final thinking = delta['thinking'] as String?;
              if (thinking != null) {
                yield ThinkingEvent(thinking);
              }
            }

            yield DeltaEvent(delta);
          }

        case 'content_block_stop':
          final index = event['index']?.toString() ?? '0';
          final toolName = toolNames[index];
          final buffer = toolBuffers[index];

          // If this was a thinking block, emit completion event
          if (thinkingBlocks.contains(index)) {
            yield const ThinkingEvent('', isComplete: true);
            thinkingBlocks.remove(index);
          }

          // If this was a tool use block, parse and emit A2UI message
          if (toolName != null && buffer != null) {
            final jsonStr = buffer.toString();
            if (jsonStr.isNotEmpty) {
              try {
                final input = jsonDecode(jsonStr) as Map<String, dynamic>;
                final message = ClaudeA2uiParser.parseToolUse(toolName, input);
                if (message != null) {
                  yield A2uiMessageEvent(message);
                }
              } on FormatException catch (e, stackTrace) {
                _log.warning(
                  'Malformed JSON in tool "$toolName": $jsonStr',
                  e,
                  stackTrace,
                );
                // coverage:ignore-start
              } on Exception catch (e, stackTrace) {
                _log.warning('Failed to parse tool "$toolName"', e, stackTrace);
              }
              // coverage:ignore-end
            }
          }

          // Clean up tracking for this block
          toolNames.remove(index);
          toolBuffers.remove(index);

        case 'message_stop':
          yield const CompleteEvent();

        case 'error':
          final errorData = event['error'] as Map<String, dynamic>?;
          final message = errorData?['message'] as String? ?? 'Unknown error';
          yield ErrorEvent(StreamException(message));
      }
    }
  }

  /// Disposes of resources.
  void dispose() {
    // No resources to dispose - tool tracking is local to each stream
  }
}
