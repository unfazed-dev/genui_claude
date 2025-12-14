import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_schema.freezed.dart';
part 'tool_schema.g.dart';

/// Represents a UI tool schema that can be converted to Claude's tool format.
///
/// Each tool has a [name], [description], and [inputSchema] defining
/// the expected parameters. The [requiredFields] list specifies which
/// fields must be provided.
@freezed
abstract class A2uiToolSchema with _$A2uiToolSchema {
  /// Creates a tool schema.
  const factory A2uiToolSchema({
    /// Unique tool name identifier.
    required String name,

    /// Human-readable description of what the tool does.
    required String description,

    /// JSON Schema defining the tool's input parameters.
    required Map<String, dynamic> inputSchema,

    /// List of required field names.
    List<String>? requiredFields,
  }) = _A2uiToolSchema;

  /// Creates an [A2uiToolSchema] from a JSON map.
  factory A2uiToolSchema.fromJson(Map<String, dynamic> json) =>
      _$A2uiToolSchemaFromJson(json);
}
