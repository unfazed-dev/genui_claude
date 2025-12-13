import 'package:anthropic_a2ui/src/models/a2ui_message.dart';
import 'package:meta/meta.dart';

/// Result of parsing a Claude API response.
///
/// Contains both A2UI messages (from tool_use blocks) and text content
/// (from text blocks). The [hasToolUse] flag indicates whether any
/// A2UI messages were found.
@immutable
class ParseResult {

  /// Creates a parse result.
  const ParseResult({
    required this.a2uiMessages,
    required this.textContent,
    required this.hasToolUse,
  });

  /// Creates an empty parse result.
  const ParseResult.empty()
      : a2uiMessages = const [],
        textContent = '',
        hasToolUse = false;

  /// Creates a parse result with only text content.
  factory ParseResult.textOnly(String text) => ParseResult(
        a2uiMessages: const [],
        textContent: text,
        hasToolUse: false,
      );

  /// Creates a parse result with only A2UI messages.
  factory ParseResult.messagesOnly(List<A2uiMessageData> messages) =>
      ParseResult(
        a2uiMessages: messages,
        textContent: '',
        hasToolUse: messages.isNotEmpty,
      );
  /// Parsed A2UI messages from tool_use blocks.
  final List<A2uiMessageData> a2uiMessages;

  /// Combined text content from text blocks.
  final String textContent;

  /// Whether any tool_use blocks were found.
  final bool hasToolUse;

  /// Whether this result is empty (no messages and no text).
  bool get isEmpty => a2uiMessages.isEmpty && textContent.isEmpty;

  /// Whether this result has any content.
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParseResult &&
          hasToolUse == other.hasToolUse &&
          textContent == other.textContent;

  @override
  int get hashCode => Object.hash(hasToolUse, textContent);

  @override
  String toString() => 'ParseResult(messages: ${a2uiMessages.length}, '
      'text: ${textContent.length} chars, hasToolUse: $hasToolUse)';
}
