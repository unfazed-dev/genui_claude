import 'package:anthropic_a2ui/src/models/models.dart';

/// Parses Claude API responses into A2UI message streams.
class ClaudeA2uiParser {
  ClaudeA2uiParser._();

  /// Parses a single tool_use block into an A2UI message.
  ///
  /// Returns null for unknown tool names.
  static A2uiMessageData? parseToolUse(
    String toolName,
    Map<String, dynamic> input,
  ) {
    return switch (toolName) {
      'begin_rendering' => BeginRenderingData.fromJson(input),
      'surface_update' => SurfaceUpdateData.fromJson(input),
      'data_model_update' => DataModelUpdateData.fromJson(input),
      'delete_surface' => DeleteSurfaceData.fromJson(input),
      _ => null,
    };
  }

  /// Parses a complete message response.
  ///
  /// Extracts both A2UI messages from tool_use blocks and text content
  /// from text blocks.
  static ParseResult parseMessage(Map<String, dynamic> message) {
    final a2uiMessages = <A2uiMessageData>[];
    final textBlocks = <String>[];

    final content = message['content'] as List<dynamic>?;
    if (content == null) {
      return ParseResult.empty();
    }

    for (final block in content) {
      final blockMap = block as Map<String, dynamic>;
      final type = blockMap['type'] as String?;

      if (type == 'tool_use') {
        final name = blockMap['name'] as String;
        final input = blockMap['input'] as Map<String, dynamic>;
        final parsed = parseToolUse(name, input);
        if (parsed != null) {
          a2uiMessages.add(parsed);
        }
      } else if (type == 'text') {
        final text = blockMap['text'] as String?;
        if (text != null) {
          textBlocks.add(text);
        }
      }
    }

    return ParseResult(
      a2uiMessages: a2uiMessages,
      textContent: textBlocks.join('\n'),
      hasToolUse: a2uiMessages.isNotEmpty,
    );
  }
}
