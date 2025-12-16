/// A2UI tool integration tests for ClaudeContentGenerator.
///
/// These tests verify that A2UI tool invocations produce correct GenUI SDK
/// A2uiMessage types, matching the expected behavior for ContentGenerator.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI A2UI Tool Integration', () {
    group('begin_rendering Tool', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('basic surface creation emits BeginRendering', () async {
        mockHandler.stubEvents(MockEventFactory.beginRenderingResponse(
          surfaceId: 'main-surface',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages[0], isA<BeginRendering>());

        final beginRendering = messages[0] as BeginRendering;
        expect(beginRendering.surfaceId, 'main-surface');
        expect(beginRendering.root, 'root'); // Hardcoded in adapter
      });

      test('with parentSurfaceId creates nested surface', () async {
        mockHandler.stubEvents(MockEventFactory.beginRenderingResponse(
          surfaceId: 'child-surface',
          parentSurfaceId: 'parent-surface',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render child'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        final beginRendering = messages[0] as BeginRendering;
        expect(beginRendering.surfaceId, 'child-surface');
        // Note: parentSurfaceId is passed but GenUI BeginRendering doesn't expose it
      });

      test('with metadata includes styles', () async {
        mockHandler.stubEvents(MockEventFactory.beginRenderingResponse(
          surfaceId: 'styled-surface',
          metadata: {'theme': 'dark', 'fontSize': 14},
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render styled'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        final beginRendering = messages[0] as BeginRendering;
        expect(beginRendering.surfaceId, 'styled-surface');
        expect(beginRendering.styles, {'theme': 'dark', 'fontSize': 14});
      });

      test('with empty metadata has null styles', () async {
        mockHandler.stubEvents(MockEventFactory.beginRenderingResponse(
          surfaceId: 'no-style-surface',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        await subscription.cancel();

        final beginRendering = messages[0] as BeginRendering;
        expect(beginRendering.styles, isNull);
      });
    });

    group('surface_update Tool', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('emits SurfaceUpdate with components', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'main',
          widgets: [
            {
              'type': 'Text',
              'properties': {'text': 'Hello World'},
            },
          ],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages[0], isA<SurfaceUpdate>());

        final update = messages[0] as SurfaceUpdate;
        expect(update.surfaceId, 'main');
        expect(update.components, hasLength(1));

        // Component.id is a UUID (unique instance ID)
        final component = update.components[0];
        expect(component.id, isNotEmpty);
        expect(component.id, isNot('Text')); // Not the type

        // Type is wrapped as key in componentProperties
        expect(component.componentProperties.containsKey('Text'), isTrue);
        final props = component.componentProperties['Text']! as Map<String, dynamic>;
        expect(props['text'], 'Hello World');
      });

      test('handles multiple widgets', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'multi-widget',
          widgets: [
            {'type': 'Text', 'properties': {'text': 'First'}},
            {'type': 'Button', 'properties': {'label': 'Click'}},
            {'type': 'Image', 'properties': {'url': 'image.png'}},
          ],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update'));

        await subscription.cancel();

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, hasLength(3));

        // Each component has unique UUID id, type is in componentProperties key
        expect(update.components[0].componentProperties.containsKey('Text'), isTrue);
        expect(update.components[1].componentProperties.containsKey('Button'), isTrue);
        expect(update.components[2].componentProperties.containsKey('Image'), isTrue);

        // All IDs are unique UUIDs
        final ids = update.components.map((c) => c.id).toSet();
        expect(ids.length, 3);
      });

      test('preserves complex widget properties', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'complex',
          widgets: [
            {
              'type': 'Card',
              'properties': {
                'title': 'Card Title',
                'elevation': 4,
                'padding': {'top': 8, 'bottom': 8, 'left': 16, 'right': 16},
                'colors': ['#FF0000', '#00FF00', '#0000FF'],
                'enabled': true,
              },
            },
          ],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('complex'));

        await subscription.cancel();

        final update = messages[0] as SurfaceUpdate;
        // Type is the key, properties are nested inside
        final cardProps =
            update.components[0].componentProperties['Card']! as Map<String, dynamic>;

        expect(cardProps['title'], 'Card Title');
        expect(cardProps['elevation'], 4);
        expect(cardProps['padding'], {'top': 8, 'bottom': 8, 'left': 16, 'right': 16});
        expect(cardProps['colors'], ['#FF0000', '#00FF00', '#0000FF']);
        expect(cardProps['enabled'], true);
      });

      test('handles empty widgets array', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'empty',
          widgets: [],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('empty'));

        await subscription.cancel();

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, isEmpty);
      });

      test('handles large widget array', () async {
        mockHandler.stubEvents(MockEventFactory.largeWidgetResponse(
          surfaceId: 'large',
          widgetCount: 100,
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('large'));

        await subscription.cancel();

        // Should have BeginRendering + SurfaceUpdate
        expect(messages, hasLength(2));
        final update = messages[1] as SurfaceUpdate;
        expect(update.components, hasLength(100));
      });

      test('append mode is passed through', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'append-test',
          widgets: [
            {'type': 'Text', 'properties': {'text': 'Appended'}},
          ],
          append: true,
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('append'));

        await subscription.cancel();

        // SurfaceUpdate is emitted regardless of append flag
        expect(messages, hasLength(1));
        expect(messages[0], isA<SurfaceUpdate>());
      });
    });

    group('data_model_update Tool', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('emits DataModelUpdate with contents', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {'count': 42, 'name': 'Test'},
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('update data'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages[0], isA<DataModelUpdate>());

        final update = messages[0] as DataModelUpdate;
        expect(update.contents, {'count': 42, 'name': 'Test'});
      });

      test('with scope uses scope as surfaceId', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {'value': 'scoped'},
          scope: 'widget-scope',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('scoped update'));

        await subscription.cancel();

        final update = messages[0] as DataModelUpdate;
        expect(update.surfaceId, 'widget-scope');
      });

      test('without scope uses default surfaceId', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {'value': 'unscoped'},
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('unscoped'));

        await subscription.cancel();

        final update = messages[0] as DataModelUpdate;
        expect(update.surfaceId, globalSurfaceId);
      });

      test('handles nested object updates', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {
            'user': {
              'profile': {
                'name': 'John',
                'settings': {'theme': 'dark'},
              },
            },
          },
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('nested'));

        await subscription.cancel();

        final update = messages[0] as DataModelUpdate;
        final contents = update.contents as Map<String, dynamic>;
        final user = contents['user'] as Map<String, dynamic>;
        final profile = user['profile'] as Map<String, dynamic>;
        final settings = profile['settings'] as Map<String, dynamic>;
        expect(profile['name'], 'John');
        expect(settings['theme'], 'dark');
      });

      test('handles array values in updates', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {
            'items': [1, 2, 3, 4, 5],
            'tags': ['flutter', 'dart', 'genui'],
          },
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('arrays'));

        await subscription.cancel();

        final update = messages[0] as DataModelUpdate;
        final contents = update.contents as Map<String, dynamic>;
        expect(contents['items'], [1, 2, 3, 4, 5]);
        expect(contents['tags'], ['flutter', 'dart', 'genui']);
      });

      test('handles null values in updates', () async {
        mockHandler.stubEvents(MockEventFactory.dataModelUpdateResponse(
          updates: {
            'value': null,
            'other': 'not null',
          },
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('nulls'));

        await subscription.cancel();

        final update = messages[0] as DataModelUpdate;
        final contents = update.contents as Map<String, dynamic>;
        expect(contents['value'], isNull);
        expect(contents['other'], 'not null');
      });
    });

    group('delete_surface Tool', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('emits SurfaceDeletion', () async {
        mockHandler.stubEvents(MockEventFactory.deleteSurfaceResponse(
          surfaceId: 'to-delete',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('delete'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages[0], isA<SurfaceDeletion>());

        final deletion = messages[0] as SurfaceDeletion;
        expect(deletion.surfaceId, 'to-delete');
      });

      test('with cascade true', () async {
        mockHandler.stubEvents(MockEventFactory.deleteSurfaceResponse(
          surfaceId: 'cascade-delete',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('delete cascade'));

        await subscription.cancel();

        // SurfaceDeletion is emitted; cascade is handled by GenUI internally
        final deletion = messages[0] as SurfaceDeletion;
        expect(deletion.surfaceId, 'cascade-delete');
      });

      test('with cascade false', () async {
        mockHandler.stubEvents(MockEventFactory.deleteSurfaceResponse(
          surfaceId: 'no-cascade',
          cascade: false,
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('delete no cascade'));

        await subscription.cancel();

        final deletion = messages[0] as SurfaceDeletion;
        expect(deletion.surfaceId, 'no-cascade');
      });
    });

    group('Multi-Tool Sequences', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('begin_rendering followed by surface_update (typical flow)',
          () async {
        mockHandler.stubEvents(MockEventFactory.widgetRenderingResponse(
          surfaceId: 'typical',
          widgets: [
            {'type': 'Text', 'properties': {'text': 'Rendered'}},
          ],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        await subscription.cancel();

        expect(messages, hasLength(2));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());

        final begin = messages[0] as BeginRendering;
        final update = messages[1] as SurfaceUpdate;

        expect(begin.surfaceId, 'typical');
        expect(update.surfaceId, 'typical');
      });

      test('complete surface lifecycle: create, update, delete', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceLifecycleResponse(
          surfaceId: 'lifecycle',
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('lifecycle'));

        await subscription.cancel();

        expect(messages, hasLength(4));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());
        expect(messages[2], isA<SurfaceUpdate>());
        expect(messages[3], isA<SurfaceDeletion>());
      });

      test('nested surfaces creation', () async {
        mockHandler.stubEvents(MockEventFactory.nestedSurfaceResponse(
          
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('nested'));

        await subscription.cancel();

        expect(messages, hasLength(4));

        // Parent surface
        expect((messages[0] as BeginRendering).surfaceId, 'parent');
        expect((messages[1] as SurfaceUpdate).surfaceId, 'parent');

        // Child surface
        expect((messages[2] as BeginRendering).surfaceId, 'child');
        expect((messages[3] as SurfaceUpdate).surfaceId, 'child');
      });

      test('multiple surface_updates to same surface', () async {
        mockHandler.stubEvents([
          ...MockEventFactory.beginRenderingResponse(surfaceId: 'multi-update'),
          ...MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'multi-update',
            widgets: [
              {'type': 'Text', 'properties': {'text': 'First'}},
            ],
          ),
          ...MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'multi-update',
            widgets: [
              {'type': 'Text', 'properties': {'text': 'Second'}},
            ],
          ),
        ]);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('multi'));

        await subscription.cancel();

        expect(messages, hasLength(3));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());
        expect(messages[2], isA<SurfaceUpdate>());

        // Both updates should be for the same surface
        expect((messages[1] as SurfaceUpdate).surfaceId, 'multi-update');
        expect((messages[2] as SurfaceUpdate).surfaceId, 'multi-update');
      });
    });

    group('Unknown Tool Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('unknown tool name does not emit A2uiMessage', () async {
        mockHandler.stubEvents(MockEventFactory.unknownToolResponse(
          toolName: 'some_unknown_tool',
          input: {'foo': 'bar'},
        ),);

        final messages = <A2uiMessage>[];
        final errors = <ContentGeneratorError>[];

        final msgSub = generator.a2uiMessageStream.listen(messages.add);
        final errSub = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('unknown'));

        await msgSub.cancel();
        await errSub.cancel();

        // Unknown tools should not produce A2UI messages
        expect(messages, isEmpty);
      });
    });

    group('Widget Type Variations', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('handles common GenUI widget types', () async {
        final widgetTypes = [
          {'type': 'text', 'properties': {'content': 'Text widget'}},
          {'type': 'button', 'properties': {'label': 'Click me'}},
          {'type': 'column', 'properties': <String, dynamic>{}},
          {'type': 'row', 'properties': <String, dynamic>{}},
          {'type': 'card', 'properties': {'elevation': 2}},
          {'type': 'image', 'properties': {'url': 'http://example.com/img.png'}},
          {'type': 'textField', 'properties': {'placeholder': 'Enter text'}},
        ];

        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'widget-types',
          widgets: widgetTypes,
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('widgets'));

        await subscription.cancel();

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, hasLength(7));

        // Verify each widget type is preserved (type is key in componentProperties)
        expect(update.components[0].componentProperties.containsKey('text'), isTrue);
        expect(update.components[1].componentProperties.containsKey('button'), isTrue);
        expect(update.components[2].componentProperties.containsKey('column'), isTrue);
        expect(update.components[3].componentProperties.containsKey('row'), isTrue);
        expect(update.components[4].componentProperties.containsKey('card'), isTrue);
        expect(update.components[5].componentProperties.containsKey('image'), isTrue);
        expect(update.components[6].componentProperties.containsKey('textField'), isTrue);

        // All IDs are unique UUIDs
        final ids = update.components.map((c) => c.id).toSet();
        expect(ids.length, 7);
      });

      test('handles widget with empty properties', () async {
        mockHandler.stubEvents(MockEventFactory.surfaceUpdateResponse(
          surfaceId: 'empty-props',
          widgets: [
            {'type': 'Container', 'properties': <String, dynamic>{}},
          ],
        ),);

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('empty'));

        await subscription.cancel();

        final update = messages[0] as SurfaceUpdate;
        // Type is the key, empty properties are nested inside
        expect(update.components[0].componentProperties.containsKey('Container'), isTrue);
        expect(update.components[0].componentProperties['Container'], isEmpty);
      });
    });
  });
}
