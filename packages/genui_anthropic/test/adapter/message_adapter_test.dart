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
        expect(beginRendering.root, 'root'); // Default when root not provided
        expect(beginRendering.styles, {'key': 'value'});
      });

      test('converts BeginRenderingData with custom root', () {
        const data = a2ui.BeginRenderingData(
          surfaceId: 'surface-1',
          root: 'custom-root',
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<BeginRendering>());
        final beginRendering = result as BeginRendering;
        expect(beginRendering.surfaceId, 'surface-1');
        expect(beginRendering.root, 'custom-root'); // Uses provided root
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

      test('converts SurfaceUpdateData to SurfaceUpdate with UUID component id', () {
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

        // Component.id should be a UUID (not the type)
        final component = surfaceUpdate.components.first;
        expect(component.id, isNot('text_widget'));
        expect(component.id.length, greaterThan(0)); // UUID has content

        // Type should be wrapped in componentProperties
        expect(component.componentProperties.containsKey('text_widget'), isTrue);
        final widgetProps =
            component.componentProperties['text_widget']! as Map<String, dynamic>;
        expect(widgetProps['text'], 'Hello, World!');
      });

      test('converts SurfaceUpdateData uses provided id when available', () {
        const data = a2ui.SurfaceUpdateData(
          surfaceId: 'test-surface',
          widgets: [
            a2ui.WidgetNode(
              id: 'my-custom-id',
              type: 'text_widget',
              properties: {'text': 'Hello'},
            ),
          ],
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<SurfaceUpdate>());
        final surfaceUpdate = result as SurfaceUpdate;
        expect(surfaceUpdate.components.first.id, 'my-custom-id');
      });

      test('converts SurfaceUpdateData with multiple widgets each with unique ids', () {
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

        // Each component should have a unique ID
        final ids = surfaceUpdate.components.map((c) => c.id).toSet();
        expect(ids.length, 3); // All unique

        // Each component type should be wrapped in componentProperties
        expect(
          surfaceUpdate.components[0].componentProperties.containsKey('header'),
          isTrue,
        );
        expect(
          surfaceUpdate.components[1].componentProperties.containsKey('button'),
          isTrue,
        );
        expect(
          surfaceUpdate.components[2].componentProperties.containsKey('text'),
          isTrue,
        );
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

      test('converts DataModelUpdateData without scope uses globalSurfaceId', () {
        const data = a2ui.DataModelUpdateData(
          updates: {'key': 'value'},
        );

        final result = A2uiMessageAdapter.toGenUiMessage(data);

        expect(result, isA<DataModelUpdate>());
        final dataModelUpdate = result as DataModelUpdate;
        expect(dataModelUpdate.surfaceId, globalSurfaceId);
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
      // Helper to extract widget properties from the new structure
      Map<String, dynamic> getWidgetProps(Component component, String type) {
        return component.componentProperties[type]! as Map<String, dynamic>;
      }

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
        final widgetProps = getWidgetProps(result.components.first, 'widget');

        expect(widgetProps['name'], 'test');
        expect(widgetProps['description'], 'A test widget');
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
        final widgetProps = getWidgetProps(result.components.first, 'widget');

        expect(widgetProps['count'], 42);
        expect(widgetProps['price'], 19.99);
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
        final widgetProps = getWidgetProps(result.components.first, 'widget');

        expect(widgetProps['enabled'], true);
        expect(widgetProps['visible'], false);
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
        final widgetProps = getWidgetProps(result.components.first, 'widget');

        expect(widgetProps['items'], ['a', 'b', 'c']);
        expect(widgetProps['numbers'], [1, 2, 3]);
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
        final widgetProps = getWidgetProps(result.components.first, 'widget');
        final config = widgetProps['config'] as Map<String, dynamic>;

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
        final widgetProps = getWidgetProps(result.components.first, 'widget');

        expect(widgetProps['value'], isNull);
        expect(widgetProps['name'], 'test');
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
        final component = result.components.first;

        // componentProperties should have the type key with empty map
        expect(component.componentProperties.containsKey('empty_widget'), isTrue);
        expect(component.componentProperties['empty_widget'], isEmpty);
      });
    });
  });
}
