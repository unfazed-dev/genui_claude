import 'package:anthropic_a2ui/src/exceptions/exceptions.dart';
import 'package:anthropic_a2ui/src/models/models.dart';

/// Converts A2UI tool schemas to Claude API tool format.
///
/// This class provides static methods for converting tool schemas
/// between A2UI and Claude API formats.
class A2uiToolConverter {
  A2uiToolConverter._();

  /// Converts a list of A2UI tool schemas to Claude tool format.
  ///
  /// Returns a list of maps representing Claude API tool definitions.
  static List<Map<String, dynamic>> toClaudeTools(
    List<A2uiToolSchema> schemas,
  ) {
    return schemas.map((schema) {
      return {
        'name': schema.name,
        'description': _enhanceDescription(schema),
        'input_schema': {
          'type': 'object',
          'properties': _convertProperties(schema.inputSchema),
          if (schema.requiredFields != null)
            'required': schema.requiredFields,
        },
      };
    }).toList();
  }

  /// Generates system prompt supplement for tool usage.
  ///
  /// Returns a formatted string describing available tools.
  static String generateToolInstructions(List<A2uiToolSchema> schemas) {
    final buffer = StringBuffer()..writeln('Available UI tools:');
    for (final schema in schemas) {
      buffer.writeln('- ${schema.name}: ${schema.description}');
    }
    return buffer.toString();
  }

  /// Validates tool input against a schema.
  ///
  /// Returns a [ValidationResult] indicating whether the input is valid.
  static ValidationResult validateToolInput(
    String toolName,
    Map<String, dynamic> input,
    List<A2uiToolSchema> schemas,
  ) {
    final schema = schemas.where((s) => s.name == toolName).firstOrNull;
    if (schema == null) {
      return ValidationResult.error(
        field: 'toolName',
        message: 'Unknown tool: $toolName',
        code: 'unknown_tool',
      );
    }

    final errors = <ValidationError>[];

    // Check required fields
    for (final field in schema.requiredFields ?? <String>[]) {
      if (!input.containsKey(field)) {
        errors.add(ValidationError(
          field: field,
          message: 'Required field missing: $field',
          code: 'required_field_missing',
        ),);
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }

    return ValidationResult.valid();
  }

  static String _enhanceDescription(A2uiToolSchema schema) {
    return schema.description;
  }

  static Map<String, dynamic> _convertProperties(Map<String, dynamic> schema) {
    final properties = schema['properties'] as Map<String, dynamic>?;
    return properties ?? {};
  }
}
