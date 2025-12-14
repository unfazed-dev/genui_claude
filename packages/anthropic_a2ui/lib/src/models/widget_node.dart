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

    /// Configuration properties for this widget.
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,

    /// Child widgets for container-type widgets.
    List<WidgetNode>? children,

    /// Optional data binding key for dynamic content.
    String? dataBinding,
  }) = _WidgetNode;

  /// Creates a [WidgetNode] from a JSON map.
  ///
  /// Recursively parses children if present.
  factory WidgetNode.fromJson(Map<String, dynamic> json) =>
      _$WidgetNodeFromJson(json);
}
