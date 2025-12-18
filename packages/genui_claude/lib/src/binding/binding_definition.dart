import 'package:flutter/foundation.dart';
import 'package:genui_claude/src/binding/binding_path.dart';

/// Type for value transformation functions.
typedef ValueTransformer = dynamic Function(dynamic value);

/// Binding direction mode.
enum BindingMode {
  /// Data flows from model to widget only (default).
  oneWay,

  /// Data flows both directions (model ↔ widget).
  twoWay,

  /// Data flows from widget to model only (rare).
  oneWayToSource,
}

/// Defines how a widget property binds to data model paths.
///
/// A binding definition specifies:
/// - Which widget property is bound (e.g., "value", "label")
/// - The data model path to bind to (e.g., "form.email")
/// - The binding mode (one-way, two-way, or one-way-to-source)
/// - Optional transformers for converting values
@immutable
class BindingDefinition {
  /// Creates a binding definition.
  const BindingDefinition({
    required this.property,
    required this.path,
    this.mode = BindingMode.oneWay,
    this.toWidget,
    this.toModel,
  });

  /// The widget property being bound (e.g., "value", "items").
  final String property;

  /// The data model path to bind to.
  final BindingPath path;

  /// Binding mode - one-way or two-way.
  final BindingMode mode;

  /// Optional transform for model-to-widget conversion.
  final ValueTransformer? toWidget;

  /// Optional transform for widget-to-model conversion.
  final ValueTransformer? toModel;

  /// Parses binding definitions from A2UI dataBinding field.
  ///
  /// Supports formats:
  /// - Simple string: "form.email" (binds to "value" property)
  /// - Object with string values: {"value": "form.email", "label": "form.label"}
  /// - Object with config: {"value": {"path": "form.email", "mode": "twoWay"}}
  ///
  /// Returns a list of binding definitions (one per property).
  static List<BindingDefinition> parse(dynamic dataBinding) {
    if (dataBinding == null) {
      return [];
    }

    // Simple string format: binds to "value" property
    if (dataBinding is String) {
      final trimmed = dataBinding.trim();
      if (trimmed.isEmpty) {
        return [];
      }
      return [
        BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation(trimmed),
        ),
      ];
    }

    // Object format: {"property": "path"} or {"property": {"path": "...", "mode": "..."}}
    if (dataBinding is Map<String, dynamic>) {
      if (dataBinding.isEmpty) {
        return [];
      }

      final definitions = <BindingDefinition>[];

      for (final entry in dataBinding.entries) {
        final property = entry.key;
        final value = entry.value;

        if (value is String) {
          // Simple format: {"value": "form.email"}
          definitions.add(
            BindingDefinition(
              property: property,
              path: BindingPath.fromDotNotation(value),
            ),
          );
        } else if (value is Map<String, dynamic>) {
          // Config format: {"value": {"path": "form.email", "mode": "twoWay"}}
          final pathStr = value['path'] as String?;
          if (pathStr != null) {
            definitions.add(
              BindingDefinition(
                property: property,
                path: BindingPath.fromDotNotation(pathStr),
                mode: _parseMode(value['mode']),
              ),
            );
          }
        }
        // Ignore non-string, non-map values
      }

      return definitions;
    }

    return [];
  }

  /// Parses a binding mode from string.
  static BindingMode _parseMode(dynamic mode) {
    if (mode is String) {
      switch (mode) {
        case 'twoWay':
          return BindingMode.twoWay;
        case 'oneWayToSource':
          return BindingMode.oneWayToSource;
        case 'oneWay':
        default:
          return BindingMode.oneWay;
      }
    }
    return BindingMode.oneWay;
  }

  /// Creates a copy with the specified fields replaced.
  BindingDefinition copyWith({
    String? property,
    BindingPath? path,
    BindingMode? mode,
    ValueTransformer? toWidget,
    ValueTransformer? toModel,
  }) {
    return BindingDefinition(
      property: property ?? this.property,
      path: path ?? this.path,
      mode: mode ?? this.mode,
      toWidget: toWidget ?? this.toWidget,
      toModel: toModel ?? this.toModel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BindingDefinition) return false;
    return property == other.property &&
        path == other.path &&
        mode == other.mode;
    // Note: We don't compare functions as they can't be reliably compared
  }

  @override
  int get hashCode => Object.hash(property, path, mode);

  @override
  String toString() =>
      'BindingDefinition(property: $property, path: ${path.toDotNotation()}, mode: ${mode.name})';
}
