/// Abstract base class for content block handlers.
abstract class BlockHandler {
  /// Handles a delta event for this block.
  void handleDelta(Map<String, dynamic> delta);

  /// Returns the completed block content.
  dynamic complete();

  /// Resets the handler state.
  void reset();
}

/// Handler for tool_use content blocks.
class ToolUseBlockHandler extends BlockHandler {
  final _buffer = StringBuffer();

  /// The tool name for this block.
  String? toolName;

  @override
  void handleDelta(Map<String, dynamic> delta) {
    final partialJson = delta['partial_json'] as String?;
    if (partialJson != null) {
      _buffer.write(partialJson);
    }
  }

  @override
  String complete() => _buffer.toString();

  @override
  void reset() {
    _buffer.clear();
    toolName = null;
  }
}

/// Handler for text content blocks.
class TextBlockHandler extends BlockHandler {
  final _buffer = StringBuffer();

  @override
  void handleDelta(Map<String, dynamic> delta) {
    final text = delta['text'] as String?;
    if (text != null) {
      _buffer.write(text);
    }
  }

  @override
  String complete() => _buffer.toString();

  @override
  void reset() {
    _buffer.clear();
  }
}

/// Factory for creating block handlers by type.
class BlockHandlerFactory {
  BlockHandlerFactory._();

  /// Creates a handler for the given block type.
  static BlockHandler? create(String type) {
    return switch (type) {
      'tool_use' => ToolUseBlockHandler(),
      'text' => TextBlockHandler(),
      _ => null,
    };
  }
}
