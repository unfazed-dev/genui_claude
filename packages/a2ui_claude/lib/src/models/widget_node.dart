import 'package:freezed_annotation/freezed_annotation.dart';

part 'widget_node.freezed.dart';
part 'widget_node.g.dart';

/// Represents a widget node in the A2UI widget tree.
///
/// Each node has a [type] identifying the widget kind, [properties] for
/// configuration, optional [children] for nested widgets, and an optional
/// [dataBinding] for dynamic data connections.
@freezed
abstract class WidgetNode with _$WidgetNode {
  /// Creates a widget node.
  const factory WidgetNode({
    /// The widget type identifier (e.g., 'text', 'button', 'container').
    required String type,

    /// Optional unique instance identifier for this widget.
    ///
    /// When provided, this ID uniquely identifies this widget instance
    /// within a surface. If not provided, a UUID will be generated
    /// during conversion to GenUI Component.
    String? id,

    /// Configuration properties for this widget.
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,

    /// Child widgets for container-type widgets.
    ///
    /// Supports both:
    /// - Full widget objects (nested [WidgetNode] instances)
    /// - String ID references (converted to placeholder nodes with type='_ref')
    @JsonKey(fromJson: _childrenFromJson) List<WidgetNode>? children,

    /// Optional data binding specification for dynamic content.
    ///
    /// Can be either:
    /// - A [String] path (e.g., 'form.email') for simple one-way binding
    /// - A [Map] with property → path mappings (e.g., {'value': 'form.email'})
    /// - A [Map] with property → binding config (e.g., {'value': {'path': 'form.email', 'mode': 'twoWay'}})
    Object? dataBinding,
  }) = _WidgetNode;

  /// Creates a [WidgetNode] from a JSON map.
  ///
  /// Recursively parses children if present.
  factory WidgetNode.fromJson(Map<String, dynamic> json) =>
      _$WidgetNodeFromJson(json);
}

/// Custom converter that handles children as either:
/// - List of WidgetNode objects (maps) - parsed normally
/// - List of string IDs - converted to placeholder WidgetNode with type='_ref'
///
/// This allows the parser to handle cases where Claude sends children as
/// string ID references instead of full nested widget objects.
List<WidgetNode>? _childrenFromJson(dynamic json) {
  if (json == null) return null;
  if (json is! List) return null;

  return json.map((e) {
    if (e is String) {
      // String ID reference - create placeholder node
      return WidgetNode(type: '_ref', id: e);
    } else if (e is Map<String, dynamic>) {
      // Full widget object - parse recursively
      return WidgetNode.fromJson(e);
    } else {
      throw FormatException('Invalid child element type: ${e.runtimeType}');
    }
  }).toList();
}
