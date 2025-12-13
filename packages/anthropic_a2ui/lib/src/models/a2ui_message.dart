import 'package:anthropic_a2ui/src/models/widget_node.dart';
import 'package:meta/meta.dart';

/// Base class for all A2UI protocol messages.
///
/// This is a sealed class enabling exhaustive pattern matching in switch
/// statements. All A2UI message types extend this class.
///
/// Example:
/// ```dart
/// void handleMessage(A2uiMessageData message) {
///   switch (message) {
///     case BeginRenderingData d:
///       print('Begin rendering surface: ${d.surfaceId}');
///     case SurfaceUpdateData d:
///       print('Update surface: ${d.surfaceId}');
///     case DataModelUpdateData d:
///       print('Update data model');
///     case DeleteSurfaceData d:
///       print('Delete surface: ${d.surfaceId}');
///   }
/// }
/// ```
@immutable
sealed class A2uiMessageData {
  /// Creates an A2UI message.
  const A2uiMessageData();

  /// Converts this message to a JSON map.
  Map<String, dynamic> toJson();
}

/// Signals the start of a UI generation sequence.
///
/// This message indicates that a new UI surface is being created.
/// The [surfaceId] uniquely identifies the surface, and [parentSurfaceId]
/// can be used to create nested surface hierarchies.
@immutable
class BeginRenderingData extends A2uiMessageData {

  /// Creates a begin rendering message.
  const BeginRenderingData({
    required this.surfaceId,
    this.parentSurfaceId,
    this.metadata,
  });

  /// Creates a [BeginRenderingData] from a JSON map.
  factory BeginRenderingData.fromJson(Map<String, dynamic> json) {
    return BeginRenderingData(
      surfaceId: json['surfaceId'] as String,
      parentSurfaceId: json['parentSurfaceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  /// Unique identifier for this surface.
  final String surfaceId;

  /// Parent surface ID for nested surfaces.
  final String? parentSurfaceId;

  /// Additional metadata for the surface.
  final Map<String, dynamic>? metadata;

  @override
  Map<String, dynamic> toJson() => {
        'surfaceId': surfaceId,
        if (parentSurfaceId != null) 'parentSurfaceId': parentSurfaceId,
        if (metadata != null) 'metadata': metadata,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeginRenderingData &&
          surfaceId == other.surfaceId &&
          parentSurfaceId == other.parentSurfaceId;

  @override
  int get hashCode => Object.hash(surfaceId, parentSurfaceId);

  @override
  String toString() =>
      'BeginRenderingData(surfaceId: $surfaceId, parentSurfaceId: $parentSurfaceId)';
}

/// Contains the widget tree definition for a UI surface.
///
/// This message updates the widgets displayed in a surface. The [widgets]
/// list contains the widget tree structure. If [append] is true, widgets
/// are added to existing content rather than replacing it.
@immutable
class SurfaceUpdateData extends A2uiMessageData {

  /// Creates a surface update message.
  const SurfaceUpdateData({
    required this.surfaceId,
    required this.widgets,
    this.append = false,
  });

  /// Creates a [SurfaceUpdateData] from a JSON map.
  factory SurfaceUpdateData.fromJson(Map<String, dynamic> json) {
    final widgetsList = json['widgets'] as List<dynamic>;
    return SurfaceUpdateData(
      surfaceId: json['surfaceId'] as String,
      widgets: widgetsList
          .map((w) => WidgetNode.fromJson(w as Map<String, dynamic>))
          .toList(),
      append: json['append'] as bool? ?? false,
    );
  }
  /// The surface ID to update.
  final String surfaceId;

  /// Widget tree to render.
  final List<WidgetNode> widgets;

  /// Whether to append widgets or replace existing content.
  final bool append;

  @override
  Map<String, dynamic> toJson() => {
        'surfaceId': surfaceId,
        'widgets': widgets.map((w) => w.toJson()).toList(),
        'append': append,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceUpdateData &&
          surfaceId == other.surfaceId &&
          append == other.append;

  @override
  int get hashCode => Object.hash(surfaceId, append);

  @override
  String toString() =>
      'SurfaceUpdateData(surfaceId: $surfaceId, widgets: ${widgets.length}, append: $append)';
}

/// Updates bound data values that widgets observe.
///
/// This message updates the data model that widgets can bind to.
/// The [updates] map contains key-value pairs of data to update.
/// An optional [scope] can limit which widgets see the update.
@immutable
class DataModelUpdateData extends A2uiMessageData {

  /// Creates a data model update message.
  const DataModelUpdateData({
    required this.updates,
    this.scope,
  });

  /// Creates a [DataModelUpdateData] from a JSON map.
  factory DataModelUpdateData.fromJson(Map<String, dynamic> json) {
    return DataModelUpdateData(
      updates: Map<String, dynamic>.from(json['updates'] as Map),
      scope: json['scope'] as String?,
    );
  }
  /// Data updates as key-value pairs.
  final Map<String, dynamic> updates;

  /// Optional scope to limit the update visibility.
  final String? scope;

  @override
  Map<String, dynamic> toJson() => {
        'updates': updates,
        if (scope != null) 'scope': scope,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataModelUpdateData && scope == other.scope;

  @override
  int get hashCode => scope.hashCode;

  @override
  String toString() =>
      'DataModelUpdateData(updates: ${updates.keys.toList()}, scope: $scope)';
}

/// Removes a UI surface from the rendering tree.
///
/// This message deletes a surface. If [cascade] is true, all child
/// surfaces are also deleted.
@immutable
class DeleteSurfaceData extends A2uiMessageData {

  /// Creates a delete surface message.
  const DeleteSurfaceData({
    required this.surfaceId,
    this.cascade = true,
  });

  /// Creates a [DeleteSurfaceData] from a JSON map.
  factory DeleteSurfaceData.fromJson(Map<String, dynamic> json) {
    return DeleteSurfaceData(
      surfaceId: json['surfaceId'] as String,
      cascade: json['cascade'] as bool? ?? true,
    );
  }
  /// The surface ID to delete.
  final String surfaceId;

  /// Whether to delete child surfaces as well.
  final bool cascade;

  @override
  Map<String, dynamic> toJson() => {
        'surfaceId': surfaceId,
        'cascade': cascade,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteSurfaceData &&
          surfaceId == other.surfaceId &&
          cascade == other.cascade;

  @override
  int get hashCode => Object.hash(surfaceId, cascade);

  @override
  String toString() =>
      'DeleteSurfaceData(surfaceId: $surfaceId, cascade: $cascade)';
}
