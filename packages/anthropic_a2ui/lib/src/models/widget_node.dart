import 'package:meta/meta.dart';

/// Represents a widget node in the A2UI widget tree.
///
/// Each node has a [type] identifying the widget kind, [properties] for
/// configuration, optional [children] for nested widgets, and an optional
/// [dataBinding] for dynamic data connections.
@immutable
class WidgetNode {

  /// Creates a widget node.
  const WidgetNode({
    required this.type,
    required this.properties,
    this.children,
    this.dataBinding,
  });

  /// Creates a [WidgetNode] from a JSON map.
  ///
  /// Recursively parses children if present.
  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>?;
    return WidgetNode(
      type: json['type'] as String,
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
      children: childrenJson
          ?.map((c) => WidgetNode.fromJson(c as Map<String, dynamic>))
          .toList(),
      dataBinding: json['dataBinding'] as String?,
    );
  }
  /// The widget type identifier (e.g., 'text', 'button', 'container').
  final String type;

  /// Configuration properties for this widget.
  final Map<String, dynamic> properties;

  /// Child widgets for container-type widgets.
  final List<WidgetNode>? children;

  /// Optional data binding key for dynamic content.
  final String? dataBinding;

  /// Converts this widget node to a JSON map.
  ///
  /// Recursively converts children if present.
  Map<String, dynamic> toJson() => {
        'type': type,
        'properties': properties,
        if (children != null)
          'children': children!.map((c) => c.toJson()).toList(),
        if (dataBinding != null) 'dataBinding': dataBinding,
      };

  /// Creates a copy of this widget node with the given fields replaced.
  WidgetNode copyWith({
    String? type,
    Map<String, dynamic>? properties,
    List<WidgetNode>? children,
    String? dataBinding,
  }) {
    return WidgetNode(
      type: type ?? this.type,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      dataBinding: dataBinding ?? this.dataBinding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetNode &&
          type == other.type &&
          dataBinding == other.dataBinding;

  @override
  int get hashCode => Object.hash(type, dataBinding);

  @override
  String toString() =>
      'WidgetNode(type: $type, properties: ${properties.keys.toList()}, '
      'children: ${children?.length ?? 0}, dataBinding: $dataBinding)';
}
