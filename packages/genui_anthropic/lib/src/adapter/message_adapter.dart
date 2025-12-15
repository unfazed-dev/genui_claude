import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:genui/genui.dart';

/// Adapts anthropic_a2ui message types to GenUI A2uiMessage types.
///
/// This class bridges the gap between the pure Dart anthropic_a2ui package
/// and the Flutter-based GenUI SDK.
class A2uiMessageAdapter {
  A2uiMessageAdapter._(); // coverage:ignore-line

  /// Converts an anthropic_a2ui message to a GenUI A2uiMessage.
  ///
  /// Returns the appropriate GenUI message type based on the input.
  static A2uiMessage toGenUiMessage(a2ui.A2uiMessageData data) {
    return switch (data) {
      a2ui.BeginRenderingData(:final surfaceId, :final metadata) =>
        BeginRendering(
          surfaceId: surfaceId,
          root: 'root',
          styles: metadata,
        ),
      a2ui.SurfaceUpdateData(:final surfaceId, :final widgets) =>
        SurfaceUpdate(
          surfaceId: surfaceId,
          components: widgets.map(_toComponent).toList(),
        ),
      a2ui.DataModelUpdateData(:final updates, :final scope) => DataModelUpdate(
          surfaceId: scope ?? 'default',
          contents: updates,
        ),
      a2ui.DeleteSurfaceData(:final surfaceId) => SurfaceDeletion(
          surfaceId: surfaceId,
        ),
    };
  }

  /// Converts a WidgetNode to a GenUI Component.
  static Component _toComponent(a2ui.WidgetNode node) {
    return Component(
      id: node.type,
      componentProperties: node.properties,
    );
  }

  /// Converts a list of anthropic_a2ui messages to GenUI messages.
  static List<A2uiMessage> toGenUiMessages(List<a2ui.A2uiMessageData> messages) {
    return messages.map(toGenUiMessage).toList();
  }
}
