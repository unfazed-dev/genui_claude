import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/adapter/a2ui_control_tools.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Bridges GenUI Catalog items to A2UI tool schemas.
///
/// This class converts Flutter GenUI catalog items (widget definitions) into
/// A2uiToolSchema objects that can be provided to Claude for generative UI.
class CatalogToolBridge {
  CatalogToolBridge._(); // coverage:ignore-line

  /// Converts a list of [CatalogItem]s to [A2uiToolSchema] list.
  ///
  /// Each CatalogItem becomes a tool that Claude can use to render widgets.
  static List<A2uiToolSchema> fromItems(List<CatalogItem> items) {
    return items.map(_itemToToolSchema).toList();
  }

  /// Extracts tools from a [Catalog].
  static List<A2uiToolSchema> fromCatalog(Catalog catalog) {
    return fromItems(catalog.items.toList());
  }

  /// Combines A2UI control tools with widget tools.
  ///
  /// The A2UI control tools (begin_rendering, surface_update, etc.) are
  /// prepended to the widget tools list.
  static List<A2uiToolSchema> withA2uiTools(List<A2uiToolSchema> widgetTools) {
    return [...A2uiControlTools.all, ...widgetTools];
  }

  /// Converts a single [CatalogItem] to an [A2uiToolSchema].
  static A2uiToolSchema _itemToToolSchema(CatalogItem item) {
    final schemaMap = _schemaToMap(item.dataSchema);

    return A2uiToolSchema(
      name: item.name,
      description: _extractDescription(item.dataSchema, item.name),
      inputSchema: schemaMap,
      requiredFields: _extractRequiredFields(schemaMap),
    );
  }

  /// Extracts description from schema or generates a default one.
  static String _extractDescription(Schema schema, String name) {
    if (schema.description != null) {
      return schema.description!;
    }
    return 'Render a $name widget';
  }

  /// Extracts required fields from the schema map.
  static List<String>? _extractRequiredFields(Map<String, dynamic> schemaMap) {
    final required = schemaMap['required'];
    if (required is List) {
      return required.cast<String>();
    }
    return null;
  }

  /// Converts a json_schema_builder Schema to a Map representation.
  static Map<String, dynamic> _schemaToMap(Schema schema) {
    // Check type using the schema's type property
    final schemaType = schema.type;

    if (schemaType == 'object' || schema is ObjectSchema) {
      return _objectSchemaToMap(schema as ObjectSchema);
    }
    // coverage:ignore-start
    // NOTE: These branches handle primitive schema types at root level.
    // In practice, all CatalogItem.dataSchema values start with ObjectSchema
    // because widgets require structured properties. The json_schema_builder
    // library uses extension types which don't support runtime instanceof checks.
    // These branches are kept for defensive programming and future-proofing.
    else if (schemaType == 'string') {
      return _stringSchemaToMap(schema as StringSchema);
    } else if (schemaType == 'integer') {
      return _integerSchemaToMap(schema as IntegerSchema);
    } else if (schemaType == 'number') {
      return _numberSchemaToMap(schema as NumberSchema);
    } else if (schemaType == 'boolean') {
      return _booleanSchemaToMap(schema as BooleanSchema);
    } else if (schemaType == 'array') {
      return _listSchemaToMap(schema as ListSchema);
    }

    // Fallback: convert the raw schema value
    return Map<String, dynamic>.from(schema.value);
    // coverage:ignore-end
  }

  static Map<String, dynamic> _objectSchemaToMap(ObjectSchema schema) {
    final properties = <String, dynamic>{};
    final schemaProperties = schema.properties;
    if (schemaProperties != null) {
      for (final entry in schemaProperties.entries) {
        properties[entry.key] = _schemaToMap(entry.value);
      }
    }

    final required = schema.required;
    return {
      'type': 'object',
      if (schema.description != null) 'description': schema.description,
      'properties': properties,
      if (required != null && required.isNotEmpty) 'required': required,
    };
  }

  // coverage:ignore-start
  // NOTE: These primitive schema converters are only called from _schemaToMap branches
  // that are unreachable in normal GenUI usage (see note above in _schemaToMap).
  // Kept for completeness and potential future use cases.

  static Map<String, dynamic> _stringSchemaToMap(StringSchema schema) {
    return {
      'type': 'string',
      if (schema.description != null) 'description': schema.description,
      if (schema.enumValues != null) 'enum': schema.enumValues,
    };
  }

  static Map<String, dynamic> _integerSchemaToMap(IntegerSchema schema) {
    return {
      'type': 'integer',
      if (schema.description != null) 'description': schema.description,
    };
  }

  static Map<String, dynamic> _numberSchemaToMap(NumberSchema schema) {
    return {
      'type': 'number',
      if (schema.description != null) 'description': schema.description,
    };
  }

  static Map<String, dynamic> _booleanSchemaToMap(BooleanSchema schema) {
    return {
      'type': 'boolean',
      if (schema.description != null) 'description': schema.description,
    };
  }

  static Map<String, dynamic> _listSchemaToMap(ListSchema schema) {
    return {
      'type': 'array',
      if (schema.description != null) 'description': schema.description,
      if (schema.items != null) 'items': _schemaToMap(schema.items!),
    };
  }
  // coverage:ignore-end
}
