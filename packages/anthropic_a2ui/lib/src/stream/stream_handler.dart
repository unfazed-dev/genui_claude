import 'dart:async';

import 'package:anthropic_a2ui/src/exceptions/exceptions.dart';
import 'package:anthropic_a2ui/src/models/models.dart';
import 'package:anthropic_a2ui/src/parser/parser.dart';

/// Manages streaming connections to Claude API.
///
/// Provides progressive message delivery as tool_use blocks complete.
class ClaudeStreamHandler {

  /// Creates a stream handler with optional configuration.
  ClaudeStreamHandler({this.config = StreamConfig.defaults});
  /// Configuration for streaming requests.
  final StreamConfig config;

  final _parser = StreamParser();

  /// Creates a streaming request and parses responses.
  ///
  /// Yields [StreamEvent] objects as the response streams in.
  Stream<StreamEvent> streamRequest({
    required Stream<Map<String, dynamic>> messageStream,
  }) async* {
    final textBuffer = StringBuffer();

    await for (final event in messageStream) {
      final type = event['type'] as String?;

      switch (type) {
        case 'content_block_start':
          final contentBlock = event['content_block'] as Map<String, dynamic>?;
          if (contentBlock?['type'] == 'tool_use') {
            // Tool block starting - handled by parser
          }

        case 'content_block_delta':
          final delta = event['delta'] as Map<String, dynamic>?;
          if (delta != null) {
            final deltaType = delta['type'] as String?;
            if (deltaType == 'text_delta') {
              final text = delta['text'] as String?;
              if (text != null) {
                textBuffer.write(text);
                yield TextDeltaEvent(text);
              }
            }
            yield DeltaEvent(delta);
          }

        case 'content_block_stop':
          // Check if this was a tool block
          final index = event['index'];
          if (index != null) {
            // Tool blocks are parsed separately
          }

        case 'message_stop':
          yield const CompleteEvent();

        case 'error':
          final errorData = event['error'] as Map<String, dynamic>?;
          final message = errorData?['message'] as String? ?? 'Unknown error';
          yield ErrorEvent(StreamException(message));
      }
    }

    // Parse tool use blocks
    await for (final message in _parser.parseStream(messageStream)) {
      yield A2uiMessageEvent(message);
    }
  }

  /// Disposes of resources.
  void dispose() {
    _parser.reset();
  }
}
