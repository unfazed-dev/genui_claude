#!/usr/bin/env dart
/// Catalog Validation Script for GenUI Anthropic
///
/// Validates that a widget catalog meets requirements for Claude tool integration.
///
/// Usage:
///   dart run .claude/skills/genui-anthropic/scripts/validate_catalog.dart
///
/// Or import in tests:
///   import '.claude/skills/genui-anthropic/scripts/validate_catalog.dart';

import 'dart:io';

/// Validation result for a single catalog item
class ItemValidationResult {
  final String itemName;
  final List<String> errors;
  final List<String> warnings;

  ItemValidationResult({
    required this.itemName,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isValid => errors.isEmpty;
}

/// Overall catalog validation result
class CatalogValidationResult {
  final List<ItemValidationResult> items;
  final List<String> globalErrors;

  CatalogValidationResult({
    required this.items,
    this.globalErrors = const [],
  });

  bool get isValid =>
      globalErrors.isEmpty && items.every((item) => item.isValid);

  int get errorCount =>
      globalErrors.length + items.fold(0, (sum, item) => sum + item.errors.length);

  int get warningCount =>
      items.fold(0, (sum, item) => sum + item.warnings.length);
}

/// Validates a catalog item schema
ItemValidationResult validateCatalogItem(Map<String, dynamic> item) {
  final errors = <String>[];
  final warnings = <String>[];

  final name = item['name'] as String?;
  if (name == null || name.isEmpty) {
    return ItemValidationResult(
      itemName: '<unnamed>',
      errors: ['Missing required field: name'],
    );
  }

  // Validate name format (snake_case)
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    errors.add('Name should be snake_case: $name');
  }

  // Validate name length
  if (name.length > 64) {
    errors.add('Name too long (max 64 chars): ${name.length}');
  }

  // Validate schema exists
  final schema = item['dataSchema'] as Map<String, dynamic>?;
  if (schema == null) {
    errors.add('Missing required field: dataSchema');
  } else {
    // Validate schema structure
    final schemaErrors = validateSchema(schema, 'dataSchema');
    errors.addAll(schemaErrors);

    // Check for description
    if (schema['description'] == null) {
      warnings.add('Consider adding a description to dataSchema');
    }
  }

  // Check for widgetBuilder
  if (item['widgetBuilder'] == null) {
    errors.add('Missing required field: widgetBuilder');
  }

  return ItemValidationResult(
    itemName: name,
    errors: errors,
    warnings: warnings,
  );
}

/// Validates a JSON schema structure
List<String> validateSchema(Map<String, dynamic> schema, String path) {
  final errors = <String>[];

  final type = schema['type'] as String?;
  if (type == null) {
    // Check if it's a ref
    if (schema['\$ref'] == null) {
      errors.add('$path: Missing type or \$ref');
    }
    return errors;
  }

  switch (type) {
    case 'object':
      final properties = schema['properties'] as Map<String, dynamic>?;
      if (properties != null) {
        for (final entry in properties.entries) {
          final propSchema = entry.value as Map<String, dynamic>?;
          if (propSchema != null) {
            errors.addAll(validateSchema(propSchema, '$path.${entry.key}'));
          }
        }
      }

    case 'array':
      final items = schema['items'] as Map<String, dynamic>?;
      if (items == null) {
        errors.add('$path: Array type missing items schema');
      } else {
        errors.addAll(validateSchema(items, '$path.items'));
      }

    case 'string':
    case 'number':
    case 'integer':
    case 'boolean':
      // Valid primitive types
      break;

    default:
      errors.add('$path: Unknown type: $type');
  }

  return errors;
}

/// Validates an entire catalog
CatalogValidationResult validateCatalog(List<Map<String, dynamic>> items) {
  final globalErrors = <String>[];
  final itemResults = <ItemValidationResult>[];

  if (items.isEmpty) {
    globalErrors.add('Catalog is empty');
    return CatalogValidationResult(
      items: itemResults,
      globalErrors: globalErrors,
    );
  }

  // Check for duplicate names
  final names = <String>{};
  for (final item in items) {
    final name = item['name'] as String?;
    if (name != null) {
      if (names.contains(name)) {
        globalErrors.add('Duplicate item name: $name');
      }
      names.add(name);
    }
  }

  // Check for reserved A2UI tool names
  const reservedNames = [
    'begin_rendering',
    'surface_update',
    'data_model_update',
    'delete_surface',
  ];
  for (final reserved in reservedNames) {
    if (names.contains(reserved)) {
      globalErrors.add('Cannot use reserved A2UI tool name: $reserved');
    }
  }

  // Validate each item
  for (final item in items) {
    itemResults.add(validateCatalogItem(item));
  }

  return CatalogValidationResult(
    items: itemResults,
    globalErrors: globalErrors,
  );
}

/// Prints validation results to console
void printResults(CatalogValidationResult result) {
  if (result.isValid) {
    print('✓ Catalog validation passed');
    print('  ${result.items.length} items validated');
    if (result.warningCount > 0) {
      print('  ${result.warningCount} warning(s)');
    }
  } else {
    print('✗ Catalog validation failed');
    print('  ${result.errorCount} error(s)');
  }

  // Print global errors
  for (final error in result.globalErrors) {
    print('  [ERROR] $error');
  }

  // Print item results
  for (final item in result.items) {
    if (!item.isValid || item.warnings.isNotEmpty) {
      print('');
      print('  ${item.itemName}:');
      for (final error in item.errors) {
        print('    [ERROR] $error');
      }
      for (final warning in item.warnings) {
        print('    [WARN] $warning');
      }
    }
  }
}

// Example usage when run directly
void main(List<String> args) {
  print('GenUI Anthropic Catalog Validator');
  print('==================================');
  print('');

  // Example catalog for validation
  final exampleCatalog = [
    {
      'name': 'info_card',
      'dataSchema': {
        'type': 'object',
        'description': 'Display information in a card',
        'properties': {
          'title': {'type': 'string', 'description': 'Card title'},
          'content': {'type': 'string', 'description': 'Card content'},
        },
        'required': ['title', 'content'],
      },
      'widgetBuilder': 'placeholder',
    },
    {
      'name': 'action_button',
      'dataSchema': {
        'type': 'object',
        'description': 'A clickable button',
        'properties': {
          'label': {'type': 'string', 'description': 'Button label'},
          'variant': {
            'type': 'string',
            'enum': ['primary', 'secondary', 'danger'],
          },
        },
        'required': ['label'],
      },
      'widgetBuilder': 'placeholder',
    },
  ];

  final result = validateCatalog(exampleCatalog);
  printResults(result);

  exit(result.isValid ? 0 : 1);
}
