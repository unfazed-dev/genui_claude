import 'package:anthropic_a2ui/src/models/widget_node.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'a2ui_message.freezed.dart';
part 'a2ui_message.g.dart';

/// Base class for all A2UI protocol messages.
///
/// This is a sealed class enabling exhaustive pattern matching in switch
/// statements. All A2UI message types extend this class.
///
/// Example:
/// ```dart
/// void handleMessage(A2uiMessageData message) {
///   switch (message) {
///     case BeginRenderingData(:final surfaceId):
///       print('Begin rendering surface: $surfaceId');
///     case SurfaceUpdateData(:final surfaceId):
///       print('Update surface: $surfaceId');
///     case DataModelUpdateData(:final updates):
///       print('Update data model: $updates');
///     case DeleteSurfaceData(:final surfaceId):
///       print('Delete surface: $surfaceId');
///   }
/// }
/// ```
@Freezed(unionKey: 'type')
sealed class A2uiMessageData with _$A2uiMessageData {
  /// Signals the start of a UI generation sequence.
  ///
  /// This message indicates that a new UI surface is being created.
  /// The [surfaceId] uniquely identifies the surface, and [parentSurfaceId]
  /// can be used to create nested surface hierarchies.
  @FreezedUnionValue('begin_rendering')
  const factory A2uiMessageData.beginRendering({
    /// Unique identifier for this surface.
    required String surfaceId,

    /// Parent surface ID for nested surfaces.
    String? parentSurfaceId,

    /// Additional metadata for the surface.
    Map<String, dynamic>? metadata,
  }) = BeginRenderingData;

  /// Contains the widget tree definition for a UI surface.
  ///
  /// This message updates the widgets displayed in a surface. The [widgets]
  /// list contains the widget tree structure. If [append] is true, widgets
  /// are added to existing content rather than replacing it.
  @FreezedUnionValue('surface_update')
  const factory A2uiMessageData.surfaceUpdate({
    /// The surface ID to update.
    required String surfaceId,

    /// Widget tree to render.
    required List<WidgetNode> widgets,

    /// Whether to append widgets or replace existing content.
    @Default(false) bool append,
  }) = SurfaceUpdateData;

  /// Updates bound data values that widgets observe.
  ///
  /// This message updates the data model that widgets can bind to.
  /// The [updates] map contains key-value pairs of data to update.
  /// An optional [scope] can limit which widgets see the update.
  @FreezedUnionValue('data_model_update')
  const factory A2uiMessageData.dataModelUpdate({
    /// Data updates as key-value pairs.
    required Map<String, dynamic> updates,

    /// Optional scope to limit the update visibility.
    String? scope,
  }) = DataModelUpdateData;

  /// Removes a UI surface from the rendering tree.
  ///
  /// This message deletes a surface. If [cascade] is true, all child
  /// surfaces are also deleted.
  @FreezedUnionValue('delete_surface')
  const factory A2uiMessageData.deleteSurface({
    /// The surface ID to delete.
    required String surfaceId,

    /// Whether to delete child surfaces as well.
    @Default(true) bool cascade,
  }) = DeleteSurfaceData;

  /// Creates an [A2uiMessageData] from a JSON map.
  factory A2uiMessageData.fromJson(Map<String, dynamic> json) =>
      _$A2uiMessageDataFromJson(json);
}
