import 'package:a2ui_claude/a2ui_claude.dart' as a2ui;
import 'package:genui/genui.dart';
import 'package:uuid/uuid.dart';

/// Surface ID used for global/unscoped data model updates.
///
/// When a [DataModelUpdate] has no scope specified in the A2UI protocol,
/// this constant is used as the surfaceId to indicate a global update.
const String globalSurfaceId = '__global_scope__';

/// UUID generator for component instance IDs.
const _uuid = Uuid();

/// Adapts a2ui_claude message types to GenUI A2uiMessage types.
///
/// This class bridges the gap between the pure Dart a2ui_claude package
/// and the Flutter-based GenUI SDK.
class A2uiMessageAdapter {
  A2uiMessageAdapter._(); // coverage:ignore-line

  /// Converts an a2ui_claude message to a GenUI A2uiMessage.
  ///
  /// Returns the appropriate GenUI message type based on the input.
  static A2uiMessage toGenUiMessage(a2ui.A2uiMessageData data) {
    return switch (data) {
      a2ui.BeginRenderingData(:final surfaceId, :final root, :final metadata) =>
        BeginRendering(
          surfaceId: surfaceId,
          root: root ?? 'root',
          styles: metadata,
        ),
      a2ui.SurfaceUpdateData(:final surfaceId, :final widgets) => SurfaceUpdate(
          surfaceId: surfaceId,
          components: widgets.map(_toComponent).toList(),
        ),
      a2ui.DataModelUpdateData(:final updates, :final scope) => DataModelUpdate(
          surfaceId: scope ?? globalSurfaceId,
          contents: updates,
        ),
      a2ui.DeleteSurfaceData(:final surfaceId) => SurfaceDeletion(
          surfaceId: surfaceId,
        ),
    };
  }

  /// Converts a WidgetNode to a GenUI Component.
  ///
  /// Each component gets a unique instance ID (either from the node's id
  /// field or a generated UUID). The widget type is wrapped as a key in
  /// componentProperties to support GenUI SDK's widget catalog matching.
  static Component _toComponent(a2ui.WidgetNode node) {
    return Component(
      id: node.id ?? _uuid.v4(),
      componentProperties: {
        node.type: node.properties,
      },
    );
  }

  /// Converts a list of a2ui_claude messages to GenUI messages.
  static List<A2uiMessage> toGenUiMessages(
      List<a2ui.A2uiMessageData> messages,) {
    return messages.map(toGenUiMessage).toList();
  }
}
