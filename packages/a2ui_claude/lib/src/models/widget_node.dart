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
    List<WidgetNode>? children,

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
