import 'package:meta/meta.dart';

/// Represents a UI tool schema that can be converted to Claude's tool format.
///
/// Each tool has a [name], [description], and [inputSchema] defining
/// the expected parameters. The [requiredFields] list specifies which
/// fields must be provided.
@immutable
class A2uiToolSchema {

  /// Creates a tool schema.
  const A2uiToolSchema({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.requiredFields,
  });

  /// Creates an [A2uiToolSchema] from a JSON map.
  factory A2uiToolSchema.fromJson(Map<String, dynamic> json) {
    return A2uiToolSchema(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: Map<String, dynamic>.from(json['inputSchema'] as Map),
      requiredFields: (json['requiredFields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
  /// Unique tool name identifier.
  final String name;

  /// Human-readable description of what the tool does.
  final String description;

  /// JSON Schema defining the tool's input parameters.
  final Map<String, dynamic> inputSchema;

  /// List of required field names.
  final List<String>? requiredFields;

  /// Converts this schema to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
        if (requiredFields != null) 'requiredFields': requiredFields,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2uiToolSchema &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() => 'A2uiToolSchema(name: $name, description: $description)';
}
