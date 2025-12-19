import 'package:a2ui_claude/src/exceptions/exceptions.dart';
import 'package:a2ui_claude/src/models/a2ui_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';

/// Base class for stream events emitted during Claude API streaming.
///
/// This is a sealed class enabling exhaustive pattern matching.
///
/// Example:
/// ```dart
/// await for (final event in streamHandler.streamRequest(...)) {
///   switch (event) {
///     case A2uiMessageEvent(:final message):
///       handleA2uiMessage(message);
///     case TextDeltaEvent(:final text):
///       appendText(text);
///     case DeltaEvent(:final data):
///       handleRawDelta(data);
///     case CompleteEvent():
///       finishRendering();
///     case ErrorEvent(:final error):
///       handleError(error);
///   }
/// }
/// ```
@Freezed(copyWith: false, toJson: false, fromJson: false)
sealed class StreamEvent with _$StreamEvent {
  /// Event containing raw content delta from the stream.
  const factory StreamEvent.delta(
    /// The raw delta data from the stream.
    Map<String, dynamic> data,
  ) = DeltaEvent;

  /// Event containing a parsed A2UI message.
  const factory StreamEvent.a2uiMessage(
    /// The parsed A2UI message.
    A2uiMessageData message,
  ) = A2uiMessageEvent;

  /// Event containing a text content delta.
  const factory StreamEvent.textDelta(
    /// The text content chunk.
    String text,
  ) = TextDeltaEvent;

  /// Event containing Claude's thinking/reasoning content.
  ///
  /// Emitted when interleaved thinking is enabled (Claude 4+ models).
  /// Contains partial or complete thinking blocks.
  const factory StreamEvent.thinking(
    /// The thinking content chunk.
    String content, {

    /// Whether this is the final thinking chunk for the current block.
    @Default(false) bool isComplete,
  }) = ThinkingEvent;

  /// Event indicating the stream has completed successfully.
  const factory StreamEvent.complete() = CompleteEvent;

  /// Event indicating an error occurred during streaming.
  const factory StreamEvent.error(
    /// The error that occurred.
    A2uiException error,
  ) = ErrorEvent;
}
