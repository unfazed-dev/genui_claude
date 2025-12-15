/// A2UI message flow tests for AnthropicContentGenerator.
///
/// These tests verify that A2UI messages are correctly parsed and emitted
/// in the proper format for the GenUI SDK.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import '../handler/mock_api_handler.dart';
import 'test_catalog.dart';

void main() {
  group('A2UI Message Flow', () {
    late MockApiHandler mockHandler;
    late AnthropicContentGenerator generator;

    setUp(() {
      mockHandler = MockApiHandler();
      generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
    });

    tearDown(() {
      generator.dispose();
    });

    group('BeginRendering Message', () {
      test('begin_rendering tool emits BeginRendering message', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(surfaceId: 'test-surface'),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Create a widget'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages.first, isA<BeginRendering>());

        final beginRendering = messages.first as BeginRendering;
        expect(beginRendering.surfaceId, 'test-surface');
      });

      test('begin_rendering with metadata preserves metadata', () async {
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(
            surfaceId: 'styled-surface',
            metadata: {'theme': 'dark', 'layout': 'compact'},
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Create styled widget'));

        await subscription.cancel();

        expect(messages.first, isA<BeginRendering>());
        final beginRendering = messages.first as BeginRendering;
        expect(beginRendering.styles?['theme'], 'dark');
        expect(beginRendering.styles?['layout'], 'compact');
      });
    });

    group('SurfaceUpdate Message', () {
      test('surface_update tool emits SurfaceUpdate message', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'main',
            widgets: [TestWidgets.text('Hello, World!')],
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Show greeting'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages.first, isA<SurfaceUpdate>());

        final surfaceUpdate = messages.first as SurfaceUpdate;
        expect(surfaceUpdate.surfaceId, 'main');
        expect(surfaceUpdate.components, hasLength(1));
        expect(surfaceUpdate.components.first.id, 'Text');
      });

      test('surface_update with multiple widgets preserves all widgets', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'multi-widget',
            widgets: [
              TestWidgets.text('Title'),
              TestWidgets.button('Click me'),
              TestWidgets.container(color: '#FF0000'),
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Create complex UI'));

        await subscription.cancel();

        final surfaceUpdate = messages.first as SurfaceUpdate;
        expect(surfaceUpdate.components, hasLength(3));
        expect(surfaceUpdate.components[0].id, 'Text');
        expect(surfaceUpdate.components[1].id, 'Button');
        expect(surfaceUpdate.components[2].id, 'Container');
      });

      test('widget properties are preserved in Component', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'props-test',
            widgets: [
              {
                'type': 'Text',
                'properties': {
                  'text': 'Test content',
                  'style': 'bold',
                },
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Create text'));

        await subscription.cancel();

        final surfaceUpdate = messages.first as SurfaceUpdate;
        final component = surfaceUpdate.components.first;
        expect(component.componentProperties['text'], 'Test content');
        expect(component.componentProperties['style'], 'bold');
      });
    });

    group('DataModelUpdate Message', () {
      test('data_model_update tool emits DataModelUpdate message', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'count': 42, 'name': 'Test'},
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Update data'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages.first, isA<DataModelUpdate>());

        final dataModelUpdate = messages.first as DataModelUpdate;
        final contents = dataModelUpdate.contents as Map<String, dynamic>;
        expect(contents['count'], 42);
        expect(contents['name'], 'Test');
      });

      test('data_model_update with scope uses scope as surfaceId', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'value': 'scoped'},
            scope: 'form-data',
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Update scoped data'));

        await subscription.cancel();

        final dataModelUpdate = messages.first as DataModelUpdate;
        expect(dataModelUpdate.surfaceId, 'form-data');
      });

      test('data_model_update without scope uses default surfaceId', () async {
        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: {'key': 'value'},
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Update default data'));

        await subscription.cancel();

        final dataModelUpdate = messages.first as DataModelUpdate;
        expect(dataModelUpdate.surfaceId, 'default');
      });
    });

    group('SurfaceDeletion Message', () {
      test('delete_surface tool emits SurfaceDeletion message', () async {
        mockHandler.stubEvents(
          MockEventFactory.deleteSurfaceResponse(surfaceId: 'to-delete'),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Delete surface'));

        await subscription.cancel();

        expect(messages, hasLength(1));
        expect(messages.first, isA<SurfaceDeletion>());

        final deletion = messages.first as SurfaceDeletion;
        expect(deletion.surfaceId, 'to-delete');
      });
    });

    group('Complete Rendering Flow', () {
      test('BeginRendering followed by SurfaceUpdate', () async {
        mockHandler.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'complete-flow',
            widgets: [TestWidgets.text('Complete!')],
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Render widget'));

        await subscription.cancel();

        expect(messages, hasLength(2));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());

        final beginRendering = messages[0] as BeginRendering;
        final surfaceUpdate = messages[1] as SurfaceUpdate;

        expect(beginRendering.surfaceId, 'complete-flow');
        expect(surfaceUpdate.surfaceId, 'complete-flow');
        expect(surfaceUpdate.components.first.id, 'Text');
      });

      test('message order is preserved', () async {
        mockHandler.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'ordered',
            widgets: [
              TestWidgets.text('First'),
              TestWidgets.text('Second'),
              TestWidgets.text('Third'),
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Render ordered'));

        await subscription.cancel();

        // First BeginRendering, then SurfaceUpdate
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());

        // Widgets in order
        final surfaceUpdate = messages[1] as SurfaceUpdate;
        expect(surfaceUpdate.components[0].componentProperties['text'], 'First');
        expect(surfaceUpdate.components[1].componentProperties['text'], 'Second');
        expect(surfaceUpdate.components[2].componentProperties['text'], 'Third');
      });
    });

    group('Mixed Content (Text + A2UI)', () {
      test('text content is emitted to textResponseStream', () async {
        mockHandler.stubTextResponse('Hello from Claude!');

        final textChunks = <String>[];
        final subscription = generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('Say hello'));

        await subscription.cancel();

        expect(textChunks, isNotEmpty);
        expect(textChunks.join(), contains('Hello'));
      });

      test('A2UI and text streams are independent', () async {
        // First send a text response
        mockHandler.stubTextResponse('Text response');
        await generator.sendRequest(UserMessage.text('First'));

        // Then send an A2UI response
        mockHandler.stubEvents(
          MockEventFactory.beginRenderingResponse(surfaceId: 'second'),
        );

        final a2uiMessages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(a2uiMessages.add);

        await generator.sendRequest(UserMessage.text('Second'));

        await subscription.cancel();

        expect(a2uiMessages, hasLength(1));
        expect(a2uiMessages.first, isA<BeginRendering>());
      });
    });
  });
}
