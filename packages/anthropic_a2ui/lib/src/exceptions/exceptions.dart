/// Exception types for A2UI operations.
///
/// This module provides a sealed exception hierarchy:
/// - [A2uiException] - Base exception class
/// - [ToolConversionException] - Tool schema conversion errors
/// - [MessageParseException] - Response parsing errors
/// - [StreamException] - Streaming connection errors
/// - [ValidationException] - Input validation errors
library;

/// Base exception class for all A2UI operations.
///
/// This is a sealed class enabling exhaustive pattern matching.
sealed class A2uiException implements Exception {

  /// Creates an A2UI exception.
  const A2uiException(this.message, [this.stackTrace]);
  /// Human-readable error message.
  final String message;

  /// Optional stack trace for debugging.
  final StackTrace? stackTrace;

  @override
  String toString() => 'A2uiException: $message';
}

/// Exception thrown when tool schema conversion fails.
///
/// Contains details about which tool failed and optionally the invalid schema.
class ToolConversionException extends A2uiException {

  /// Creates a tool conversion exception.
  const ToolConversionException(
    super.message,
    this.toolName, [
    this.invalidSchema,
    super.stackTrace,
  ]);
  /// Name of the tool that failed conversion.
  final String toolName;

  /// The invalid schema that caused the error, if available.
  final Map<String, dynamic>? invalidSchema;

  @override
  String toString() => 'ToolConversionException: $message (tool: $toolName)';
}

/// Exception thrown when message parsing fails.
///
/// Contains the raw content that failed to parse and expected format.
class MessageParseException extends A2uiException {

  /// Creates a message parse exception.
  const MessageParseException(
    super.message, [
    this.rawContent,
    this.expectedFormat,
    super.stackTrace,
  ]);
  /// The raw content that failed to parse.
  final String? rawContent;

  /// The expected format description.
  final String? expectedFormat;

  @override
  String toString() => 'MessageParseException: $message';
}

/// Exception thrown during streaming operations.
///
/// Indicates whether the error is retryable and includes HTTP status if available.
class StreamException extends A2uiException {

  /// Creates a stream exception.
  const StreamException(
    String message, {
    this.httpStatusCode,
    this.isRetryable = false,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);
  /// HTTP status code if this was an HTTP error.
  final int? httpStatusCode;

  /// Whether this error can be retried.
  final bool isRetryable;

  @override
  String toString() =>
      'StreamException: $message${httpStatusCode != null ? ' (HTTP $httpStatusCode)' : ''}';
}

/// Exception thrown when input validation fails.
///
/// Contains a list of validation errors with field-level details.
class ValidationException extends A2uiException {

  /// Creates a validation exception.
  const ValidationException(String message, this.errors, [StackTrace? stackTrace])
      : super(message, stackTrace);
  /// List of specific validation errors.
  final List<ValidationError> errors;

  @override
  String toString() =>
      'ValidationException: $message (${errors.length} errors)';
}

/// Represents a single validation error.
class ValidationError {

  /// Creates a validation error.
  const ValidationError({
    required this.field,
    required this.message,
    required this.code,
  });
  /// The field path that failed validation.
  final String field;

  /// Human-readable error message.
  final String message;

  /// Machine-readable error code.
  final String code;

  @override
  String toString() => '$field: $message ($code)';
}
