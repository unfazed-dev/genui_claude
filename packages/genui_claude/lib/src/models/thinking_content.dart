/// Represents thinking content from Claude's extended thinking feature.
///
/// This class contains the streamed thinking/reasoning content from Claude
/// when interleaved thinking is enabled.
class ThinkingContent {
  /// Creates a thinking content instance.
  ///
  /// [content] is the thinking text chunk.
  /// [isComplete] indicates if this is the final chunk of the thinking block.
  const ThinkingContent({
    required this.content,
    this.isComplete = false,
  });

  /// The thinking content text.
  ///
  /// This contains Claude's reasoning process as it streams in.
  /// May be partial content unless [isComplete] is true.
  final String content;

  /// Whether this is the final chunk of the current thinking block.
  ///
  /// When true, the thinking block is complete and no more content
  /// will be added to this particular block.
  final bool isComplete;

  @override
  String toString() => 'ThinkingContent(content: "$content", isComplete: $isComplete)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingContent &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          isComplete == other.isComplete;

  @override
  int get hashCode => Object.hash(content, isComplete);
}
