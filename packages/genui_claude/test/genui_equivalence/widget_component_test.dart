/// Widget and component handling tests for ClaudeContentGenerator.
///
/// These tests verify Component/Widget handling matches GenUI SDK expectations,
/// including WidgetNode to Component conversion and property preservation.
///
/// NOTE: With the updated implementation:
/// - Component.id is a unique UUID (or provided id), NOT the widget type
/// - Component type is derived from componentProperties.keys.first
/// - componentProperties wraps the type: {type: properties}
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Widget and Component Handling', () {
    group('WidgetNode to Component Conversion', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('Component.id is a UUID when not provided', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {'type': 'CustomWidget', 'properties': <String, dynamic>{}},
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        // Component.id is now a UUID, not the type
        expect(update.components[0].id.length, greaterThan(0));
        expect(update.components[0].id, isNot('CustomWidget'));
        // Type is wrapped in componentProperties
        expect(
          update.components[0].componentProperties.containsKey('CustomWidget'),
          isTrue,
        );
      });

      test('componentProperties wraps type with widget properties', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Text',
                'properties': {
                  'content': 'Hello World',
                  'fontSize': 16,
                  'color': '#000000',
                },
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final componentProps = update.components[0].componentProperties;

        // Type is the key, properties are the value
        expect(componentProps.containsKey('Text'), isTrue);
        final widgetProps = componentProps['Text']! as Map<String, dynamic>;
        expect(widgetProps['content'], 'Hello World');
        expect(widgetProps['fontSize'], 16);
        expect(widgetProps['color'], '#000000');
      });

      test('nested properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Card',
                'properties': {
                  'title': 'Card Title',
                  'style': {
                    'elevation': 4,
                    'borderRadius': 8,
                  },
                  'actions': [
                    {'label': 'OK', 'type': 'primary'},
                    {'label': 'Cancel', 'type': 'secondary'},
                  ],
                },
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final widgetProps = update.components[0].componentProperties['Card']!
            as Map<String, dynamic>;

        expect(widgetProps['title'], 'Card Title');
        final style = widgetProps['style'] as Map<String, dynamic>;
        expect(style['elevation'], 4);
        expect(style['borderRadius'], 8);
        final actions = widgetProps['actions'] as List<dynamic>;
        expect(actions, hasLength(2));
        expect((actions[0] as Map<String, dynamic>)['label'], 'OK');
      });

      test('multiple components have unique ids and maintain order', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'A',
                'properties': {'order': 1},
              },
              {
                'type': 'B',
                'properties': {'order': 2},
              },
              {
                'type': 'C',
                'properties': {'order': 3},
              },
              {
                'type': 'D',
                'properties': {'order': 4},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;

        expect(update.components, hasLength(4));

        // Each component has a unique ID
        final ids = update.components.map((c) => c.id).toSet();
        expect(ids.length, 4);

        // Types are wrapped in componentProperties
        expect(
            update.components[0].componentProperties.containsKey('A'), isTrue,);
        expect(
            update.components[1].componentProperties.containsKey('B'), isTrue,);
        expect(
            update.components[2].componentProperties.containsKey('C'), isTrue,);
        expect(
            update.components[3].componentProperties.containsKey('D'), isTrue,);

        // Properties are preserved inside the type wrapper
        expect(
          (update.components[0].componentProperties['A']! as Map)['order'],
          1,
        );
        expect(
          (update.components[3].componentProperties['D']! as Map)['order'],
          4,
        );
      });
    });

    group('Property Type Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      Map<String, dynamic> getWidgetProps(Component comp, String type) {
        return comp.componentProperties[type]! as Map<String, dynamic>;
      }

      test('string properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Text',
                'properties': {'content': 'String value'},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Text');
        expect(props['content'], isA<String>());
        expect(props['content'], 'String value');
      });

      test('integer properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Slider',
                'properties': {'min': 0, 'max': 100, 'value': 50},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Slider');

        expect(props['min'], isA<int>());
        expect(props['min'], 0);
        expect(props['max'], 100);
        expect(props['value'], 50);
      });

      test('double properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Box',
                'properties': {'opacity': 0.5, 'aspectRatio': 1.77},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Box');

        expect(props['opacity'], 0.5);
        expect(props['aspectRatio'], 1.77);
      });

      test('boolean properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Switch',
                'properties': {'enabled': true, 'checked': false},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Switch');

        expect(props['enabled'], isA<bool>());
        expect(props['enabled'], true);
        expect(props['checked'], false);
      });

      test('null properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Optional',
                'properties': {'value': null, 'fallback': 'default'},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Optional');

        expect(props['value'], isNull);
        expect(props['fallback'], 'default');
      });

      test('array properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'List',
                'properties': {
                  'items': ['a', 'b', 'c'],
                  'numbers': [1, 2, 3],
                },
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'List');

        expect(props['items'], ['a', 'b', 'c']);
        expect(props['numbers'], [1, 2, 3]);
      });

      test('object properties preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Custom',
                'properties': {
                  'config': {
                    'nested': {'deep': 'value'},
                  },
                },
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final props = getWidgetProps(update.components[0], 'Custom');

        final config = props['config'] as Map<String, dynamic>;
        final nested = config['nested'] as Map<String, dynamic>;
        expect(nested['deep'], 'value');
      });
    });

    group('Empty and Edge Cases', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('widget with empty properties', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {'type': 'Spacer', 'properties': <String, dynamic>{}},
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        final componentProps = update.components[0].componentProperties;
        // Type key exists with empty map
        expect(componentProps.containsKey('Spacer'), isTrue);
        expect(componentProps['Spacer'], isEmpty);
      });

      test('empty widgets list produces empty components', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, isEmpty);
      });

      test('widget with extra unknown properties does not crash', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [
              {
                'type': 'Button',
                'properties': {'label': 'Click'},
                'unknownField': 'ignored',
                'anotherUnknown': 123,
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, hasLength(1));
        // Has a unique ID (not 'Button')
        expect(update.components[0].id.length, greaterThan(0));
        // Type is wrapped in componentProperties
        expect(
          update.components[0].componentProperties.containsKey('Button'),
          isTrue,
        );
      });
    });

    group('SurfaceUpdate Properties', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('surfaceId is preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'unique-surface-123',
            widgets: [
              {'type': 'Text', 'properties': <String, dynamic>{}},
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        expect(update.surfaceId, 'unique-surface-123');
      });

      test('components list is not null', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'test',
            widgets: [],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, isNotNull);
        expect(update.components, isA<List<Component>>());
      });
    });

    group('BeginRendering Properties', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('surfaceId is preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(
            surfaceId: 'begin-surface-456',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final begin = messages[0] as BeginRendering;
        expect(begin.surfaceId, 'begin-surface-456');
      });

      test('root defaults to "root" when not provided', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(
            surfaceId: 'test',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final begin = messages[0] as BeginRendering;
        expect(begin.root, 'root');
      });

      test('styles from metadata', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(
            surfaceId: 'styled',
            metadata: {'background': '#FFFFFF', 'padding': 16},
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final begin = messages[0] as BeginRendering;
        expect(begin.styles, {'background': '#FFFFFF', 'padding': 16});
      });

      test('styles is null when no metadata', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(
            surfaceId: 'no-style',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final begin = messages[0] as BeginRendering;
        expect(begin.styles, isNull);
      });
    });

    group('DataModelUpdate Properties', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('surfaceId from scope', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'key': 'value'},
            scope: 'my-scope',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update'));

        final update = messages[0] as DataModelUpdate;
        expect(update.surfaceId, 'my-scope');
      });

      test('surfaceId uses globalSurfaceId when no scope', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'key': 'value'},
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update'));

        final update = messages[0] as DataModelUpdate;
        expect(update.surfaceId, globalSurfaceId);
      });

      test('contents contains update data', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'name': 'John', 'age': 30, 'active': true},
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update'));

        final update = messages[0] as DataModelUpdate;
        final contents = update.contents as Map<String, dynamic>;

        expect(contents['name'], 'John');
        expect(contents['age'], 30);
        expect(contents['active'], true);
      });
    });

    group('SurfaceDeletion Properties', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('surfaceId is preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.deleteSurfaceResponse(
            surfaceId: 'delete-me',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('delete'));

        final deletion = messages[0] as SurfaceDeletion;
        expect(deletion.surfaceId, 'delete-me');
      });
    });
  });
}
