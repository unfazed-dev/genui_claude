import 'package:anthropic_a2ui/src/exceptions/exceptions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_result.freezed.dart';

/// Result of validating tool input against a schema.
///
/// Contains validation status and any errors found.
@freezed
abstract class ValidationResult with _$ValidationResult {

  /// Creates a validation result.
  const factory ValidationResult({
    /// Whether the input is valid.
    required bool isValid,

    /// List of validation errors (empty if valid).
    required List<ValidationError> errors,
  }) = _ValidationResult;
  const ValidationResult._();

  /// Creates a successful validation result.
  factory ValidationResult.valid() => const ValidationResult(
        isValid: true,
        errors: [],
      );

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
}
