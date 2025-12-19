import 'package:a2ui_claude/src/models/a2ui_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parse_result.freezed.dart';

/// Result of parsing a Claude API response.
///
/// Contains both A2UI messages (from tool_use blocks) and text content
/// (from text blocks). The [hasToolUse] flag indicates whether any
/// A2UI messages were found.
@freezed
abstract class ParseResult with _$ParseResult {
  /// Creates a parse result.
  const factory ParseResult({
    /// Parsed A2UI messages from tool_use blocks.
    required List<A2uiMessageData> a2uiMessages,

    /// Combined text content from text blocks.
    required String textContent,

    /// Whether any tool_use blocks were found.
    required bool hasToolUse,
  }) = _ParseResult;
  const ParseResult._();

  /// Creates an empty parse result.
  factory ParseResult.empty() =>
      const ParseResult(a2uiMessages: [], textContent: '', hasToolUse: false);

  /// Creates a parse result with only text content.
  factory ParseResult.textOnly(String text) =>
      ParseResult(a2uiMessages: const [], textContent: text, hasToolUse: false);

  /// Creates a parse result with only A2UI messages.
  factory ParseResult.messagesOnly(List<A2uiMessageData> messages) =>
      ParseResult(
        a2uiMessages: messages,
        textContent: '',
        hasToolUse: messages.isNotEmpty,
      );

  /// Whether this result is empty (no messages and no text).
  bool get isEmpty => a2uiMessages.isEmpty && textContent.isEmpty;

  /// Whether this result has any content.
  bool get isNotEmpty => !isEmpty;
}
