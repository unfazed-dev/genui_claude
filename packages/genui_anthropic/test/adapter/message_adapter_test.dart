import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/adapter/message_adapter.dart';

void main() {
  group('A2uiMessageAdapter', () {
    group('toGenUiMessage', () {
      test('converts BeginRenderingData to BeginRendering', () {
        const data = a2ui.BeginRenderingData(
          surfaceId: 'test-surface',
          metadata: {'key': 'value'},
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<BeginRendering>());
        final beginRendering = result as BeginRendering;
        expect(beginRendering.surfaceId, 'test-surface');
        expect(beginRendering.root, 'root');
        expect(beginRendering.styles, {'key': 'value'});
      });

      test('converts BeginRenderingData without metadata', () {
        const data = a2ui.BeginRenderingData(
          surfaceId: 'surface-1',
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<BeginRendering>());
        final beginRendering = result as BeginRendering;
        expect(beginRendering.surfaceId, 'surface-1');
        expect(beginRendering.styles, isNull);
      });

      test('converts SurfaceUpdateData to SurfaceUpdate', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'test-surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'text_widget',
              properties: {'text': 'Hello, World!'},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<SurfaceUpdate>());
        final surfaceUpdate = result as SurfaceUpdate;
        expect(surfaceUpdate.surfaceId, 'test-surface');
        expect(surfaceUpdate.components.length, 1);
        expect(surfaceUpdate.components.first.id, 'text_widget');
        expect(
          surfaceUpdate.components.first.componentProperties['text'],
          'Hello, World!',
        );
      });

      test('converts SurfaceUpdateData with multiple widgets', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'multi-widget-surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'header',
              properties: {'title': 'Welcome'},
            ),
            a2ui.WidgetNode(
              type: 'button',
              properties: {'label': 'Click me', 'enabled': true},
            ),
            a2ui.WidgetNode(
              type: 'text',
              properties: {'content': 'Body text here'},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<SurfaceUpdate>());
        final surfaceUpdate = result as SurfaceUpdate;
        expect(surfaceUpdate.components.length, 3);
        expect(surfaceUpdate.components[0].id, 'header');
        expect(surfaceUpdate.components[1].id, 'button');
        expect(surfaceUpdate.components[2].id, 'text');
      });

      test('converts SurfaceUpdateData with empty widgets list', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'empty-surface',
          widgets: [],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<SurfaceUpdate>());
        final surfaceUpdate = result as SurfaceUpdate;
        expect(surfaceUpdate.surfaceId, 'empty-surface');
        expect(surfaceUpdate.components, isEmpty);
      });

      test('converts DataModelUpdateData to DataModelUpdate', () {
        const data = a2ui.DataModelUpdateData(
          updates: {'name': 'John', 'age': 30},
          scope: 'user-data',
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<DataModelUpdate>());
        final dataModelUpdate = result as DataModelUpdate;
        expect(dataModelUpdate.surfaceId, 'user-data');
        final contents = dataModelUpdate.contents as Map<String, dynamic>;
        expect(contents['name'], 'John');
        expect(contents['age'], 30);
      });

      test('converts DataModelUpdateData without scope uses default', () {
        const data = a2ui.DataModelUpdateData(
          updates: {'key': 'value'},
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<DataModelUpdate>());
        final dataModelUpdate = result as DataModelUpdate;
        expect(dataModelUpdate.surfaceId, 'default');
      });

      test('converts DataModelUpdateData with empty updates', () {
        const data = a2ui.DataModelUpdateData(
          updates: {},
          scope: 'empty-scope',
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<DataModelUpdate>());
        final dataModelUpdate = result as DataModelUpdate;
        expect(dataModelUpdate.contents, isEmpty);
      });

      test('converts DeleteSurfaceData to SurfaceDeletion', () {
        const data = a2ui.DeleteSurfaceData(
          surfaceId: 'surface-to-delete',
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<SurfaceDeletion>());
        final deletion = result as SurfaceDeletion;
        expect(deletion.surfaceId, 'surface-to-delete');
      });
    });

    group('toGenUiMessages', () {
      test('converts empty list to empty result', () {
        final messages = <a2ui.A2uiMessageData>[];

        final result = A2uiMessageAdapter.toGenUiMessages(messages);

        expect(result, isEmpty);
      });

      test('converts single message', () {
        const messages = [
          a2ui.BeginRenderingData(surfaceId: 'surface-1'),
        ];

        final result = A2uiMessageAdapter.toGenUiMessages(messages);

        expect(result.length, 1);
        expect(result.first, isA<BeginRendering>());
      });

      test('converts multiple messages of different types', () {
        const messages = [
          a2ui.BeginRenderingData(surfaceId: 'main'),
          a2ui.SurfaceUpdateData(
            surfaceId: 'main',
            widgets: [
              a2ui.WidgetNode(type: 'text', properties: {'text': 'Hello'}),
            ],
          ),
          a2ui.DataModelUpdateData(updates: {'loaded': true}),
          a2ui.DeleteSurfaceData(surfaceId: 'old-surface'),
        ];

        final result = A2uiMessageAdapter.toGenUiMessages(messages);

        expect(result.length, 4);
        expect(result[0], isA<BeginRendering>());
        expect(result[1], isA<SurfaceUpdate>());
        expect(result[2], isA<DataModelUpdate>());
        expect(result[3], isA<SurfaceDeletion>());
      });

      test('preserves order of messages', () {
        const messages = [
          a2ui.BeginRenderingData(surfaceId: 'first'),
          a2ui.BeginRenderingData(surfaceId: 'second'),
          a2ui.BeginRenderingData(surfaceId: 'third'),
        ];

        final result = A2uiMessageAdapter.toGenUiMessages(messages);

        expect(result.length, 3);
        expect((result[0] as BeginRendering).surfaceId, 'first');
        expect((result[1] as BeginRendering).surfaceId, 'second');
        expect((result[2] as BeginRendering).surfaceId, 'third');
      });
    });

    group('widget properties conversion', () {
      test('preserves string properties', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {'name': 'test', 'description': 'A test widget'},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props['name'], 'test');
        expect(props['description'], 'A test widget');
      });

      test('preserves numeric properties', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {'count': 42, 'price': 19.99},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props['count'], 42);
        expect(props['price'], 19.99);
      });

      test('preserves boolean properties', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {'enabled': true, 'visible': false},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props['enabled'], true);
        expect(props['visible'], false);
      });

      test('preserves list properties', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {
                'items': ['a', 'b', 'c'],
                'numbers': [1, 2, 3],
              },
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props['items'], ['a', 'b', 'c']);
        expect(props['numbers'], [1, 2, 3]);
      });

      test('preserves nested object properties', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {
                'config': {
                  'theme': 'dark',
                  'settings': {'autoSave': true, 'interval': 30},
                },
              },
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;
        final config = props['config']! as Map<String, dynamic>;

        expect(config['theme'], 'dark');
        expect((config['settings'] as Map)['autoSave'], true);
        expect((config['settings'] as Map)['interval'], 30);
      });

      test('handles null property values', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'widget',
              properties: {'value': null, 'name': 'test'},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props['value'], isNull);
        expect(props['name'], 'test');
      });

      test('handles empty properties map', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'surface',
          widgets: [
            a2ui.WidgetNode(
              type: 'empty_widget',
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data) as SurfaceUpdate;
        final props = result.components.first.componentProperties;

        expect(props, isEmpty);
      });
    });
  });
}
