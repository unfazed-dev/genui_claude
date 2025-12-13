/// Utilities for mapping JSON Schema types between A2UI and Claude formats.
class SchemaMapper {
  SchemaMapper._();

  /// Converts A2UI schema properties to Claude format.
  static Map<String, dynamic> convertProperties(Map<String, dynamic> schema) {
    final result = <String, dynamic>{};
    final properties = schema['properties'] as Map<String, dynamic>?;

    if (properties == null) return result;

    for (final entry in properties.entries) {
      result[entry.key] = _convertProperty(entry.value as Map<String, dynamic>);
    }

    return result;
  }

  static Map<String, dynamic> _convertProperty(Map<String, dynamic> property) {
    final type = property['type'] as String?;

    return switch (type) {
      'string' => _convertStringProperty(property),
      'number' || 'integer' => _convertNumberProperty(property),
      'boolean' => _convertBooleanProperty(property),
      'array' => _convertArrayProperty(property),
      'object' => _convertObjectProperty(property),
      _ => property,
    };
  }

  static Map<String, dynamic> _convertStringProperty(
    Map<String, dynamic> property,
  ) {
    return {
      'type': 'string',
      if (property['description'] != null)
        'description': property['description'],
      if (property['enum'] != null) 'enum': property['enum'],
    };
  }

  static Map<String, dynamic> _convertNumberProperty(
    Map<String, dynamic> property,
  ) {
    return {
      'type': property['type'],
      if (property['description'] != null)
        'description': property['description'],
    };
  }

  static Map<String, dynamic> _convertBooleanProperty(
    Map<String, dynamic> property,
  ) {
    return {
      'type': 'boolean',
      if (property['description'] != null)
        'description': property['description'],
    };
  }

  static Map<String, dynamic> _convertArrayProperty(
    Map<String, dynamic> property,
  ) {
    final items = property['items'] as Map<String, dynamic>?;
    return {
      'type': 'array',
      if (property['description'] != null)
        'description': property['description'],
      if (items != null) 'items': _convertProperty(items),
    };
  }

  static Map<String, dynamic> _convertObjectProperty(
    Map<String, dynamic> property,
  ) {
    return {
      'type': 'object',
      if (property['description'] != null)
        'description': property['description'],
      if (property['properties'] != null)
        'properties': convertProperties(property),
      if (property['required'] != null) 'required': property['required'],
    };
  }
}
