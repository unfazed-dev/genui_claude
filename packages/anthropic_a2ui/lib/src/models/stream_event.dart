import 'package:anthropic_a2ui/src/exceptions/exceptions.dart';
import 'package:anthropic_a2ui/src/models/a2ui_message.dart';
import 'package:meta/meta.dart';

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
@immutable
sealed class StreamEvent {
  /// Creates a stream event.
  const StreamEvent();
}

/// Event containing raw content delta from the stream.
@immutable
class DeltaEvent extends StreamEvent {

  /// Creates a delta event.
  const DeltaEvent(this.data);
  /// The raw delta data from the stream.
  final Map<String, dynamic> data;

  @override
  String toString() => 'DeltaEvent(data: $data)';
}

/// Event containing a parsed A2UI message.
@immutable
class A2uiMessageEvent extends StreamEvent {

  /// Creates an A2UI message event.
  const A2uiMessageEvent(this.message);
  /// The parsed A2UI message.
  final A2uiMessageData message;

  @override
  String toString() => 'A2uiMessageEvent(message: $message)';
}

/// Event containing a text content delta.
@immutable
class TextDeltaEvent extends StreamEvent {

  /// Creates a text delta event.
  const TextDeltaEvent(this.text);
  /// The text content chunk.
  final String text;

  @override
  String toString() => 'TextDeltaEvent(text: $text)';
}

/// Event indicating the stream has completed successfully.
@immutable
class CompleteEvent extends StreamEvent {
  /// Creates a complete event.
  const CompleteEvent();

  @override
  String toString() => 'CompleteEvent()';
}

/// Event indicating an error occurred during streaming.
@immutable
class ErrorEvent extends StreamEvent {

  /// Creates an error event.
  const ErrorEvent(this.error);
  /// The error that occurred.
  final A2uiException error;

  @override
  String toString() => 'ErrorEvent(error: $error)';
}
