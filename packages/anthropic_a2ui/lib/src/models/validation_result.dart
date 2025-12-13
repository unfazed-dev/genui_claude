import 'package:anthropic_a2ui/src/exceptions/exceptions.dart';
import 'package:meta/meta.dart';

/// Result of validating tool input against a schema.
///
/// Contains validation status and any errors found.
@immutable
class ValidationResult {

  /// Creates a validation result.
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  /// Creates a successful validation result.
  const ValidationResult.valid()
      : isValid = true,
        errors = const [];

  /// Creates a failed validation result with errors.
  factory ValidationResult.invalid(List<ValidationError> errors) =>
      ValidationResult(
        isValid: false,
        errors: errors,
      );

  /// Creates a failed validation result with a single error.
  factory ValidationResult.error({
    required String field,
    required String message,
    required String code,
  }) =>
      ValidationResult(
        isValid: false,
        errors: [ValidationError(field: field, message: message, code: code)],
      );
  /// Whether the input is valid.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<ValidationError> errors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult && isValid == other.isValid;

  @override
  int get hashCode => isValid.hashCode;

  @override
  String toString() => isValid
      ? 'ValidationResult.valid()'
      : 'ValidationResult.invalid(${errors.length} errors)';
}
