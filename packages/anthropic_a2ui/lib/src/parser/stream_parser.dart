import 'dart:async';
import 'dart:convert';

import 'package:anthropic_a2ui/src/models/models.dart';

import 'package:anthropic_a2ui/src/parser/message_parser.dart';

/// Parses streaming Claude API responses into A2UI messages.
class StreamParser {
  final _toolBuffer = <String, StringBuffer>{};
  final _currentToolName = <String, String>{};

  /// Parses a stream of message events into A2UI messages.
  ///
  /// Yields [A2uiMessageData] as complete tool_use blocks are parsed.
  Stream<A2uiMessageData> parseStream(
    Stream<Map<String, dynamic>> events,
  ) async* {
    await for (final event in events) {
      final type = event['type'] as String?;

      switch (type) {
        case 'content_block_start':
          final index = event['index'].toString();
          final contentBlock = event['content_block'] as Map<String, dynamic>?;
          if (contentBlock?['type'] == 'tool_use') {
            _currentToolName[index] = contentBlock!['name'] as String;
            _toolBuffer[index] = StringBuffer();
          }

        case 'content_block_delta':
          final index = event['index'].toString();
          final delta = event['delta'] as Map<String, dynamic>?;
          if (delta?['type'] == 'input_json_delta') {
            final partialJson = delta!['partial_json'] as String?;
            if (partialJson != null) {
              _toolBuffer[index]?.write(partialJson);
            }
          }

        case 'content_block_stop':
          final index = event['index'].toString();
          final toolName = _currentToolName[index];
          final buffer = _toolBuffer[index];

          if (toolName != null && buffer != null) {
            try {
              final jsonStr = buffer.toString();
              if (jsonStr.isNotEmpty) {
                // Note: In production, use dart:convert json.decode
                final input = _parseJson(jsonStr);
                final message = ClaudeA2uiParser.parseToolUse(toolName, input);
                if (message != null) {
                  yield message;
                }
              }
            } on FormatException {
              // Skip malformed blocks
            } on Exception {
              // Skip other malformed blocks
            }
          }

          _currentToolName.remove(index);
          _toolBuffer.remove(index);
      }
    }
  }

  /// Resets the parser state.
  void reset() {
    _toolBuffer.clear();
    _currentToolName.clear();
  }

  Map<String, dynamic> _parseJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
