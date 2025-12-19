/// Integration scenario tests for ClaudeContentGenerator.
///
/// These tests verify real-world usage patterns with GenUiConversation,
/// ensuring genui_claude works correctly in typical integration scenarios.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Integration Scenarios', () {
    group('Multiple Conversation Management', () {
      test('two generators with separate mock handlers work independently',
          () async {
        final handler1 = MockApiHandler();
        final handler2 = MockApiHandler();

        final gen1 = ClaudeContentGenerator.withHandler(handler: handler1);
        final gen2 = ClaudeContentGenerator.withHandler(handler: handler2);

        handler1.stubTextResponse('Response from gen1');
        handler2.stubTextResponse('Response from gen2');

        final text1 = <String>[];
        final text2 = <String>[];

        gen1.textResponseStream.listen(text1.add);
        gen2.textResponseStream.listen(text2.add);

        await gen1.sendRequest(UserMessage.text('Message to gen1'));
        await gen2.sendRequest(UserMessage.text('Message to gen2'));

        expect(text1, ['Response from gen1']);
        expect(text2, ['Response from gen2']);

        // Verify they tracked separate requests
        expect(handler1.createStreamCallCount, 1);
        expect(handler2.createStreamCallCount, 1);

        gen1.dispose();
        gen2.dispose();
      });

      test('surface IDs are isolated between generators', () async {
        final handler1 = MockApiHandler();
        final handler2 = MockApiHandler();

        final gen1 = ClaudeContentGenerator.withHandler(handler: handler1);
        final gen2 = ClaudeContentGenerator.withHandler(handler: handler2);

        handler1.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'surface-gen1',
          ),
        );
        handler2.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'surface-gen2',
          ),
        );

        final messages1 = <A2uiMessage>[];
        final messages2 = <A2uiMessage>[];

        gen1.a2uiMessageStream.listen(messages1.add);
        gen2.a2uiMessageStream.listen(messages2.add);

        await gen1.sendRequest(UserMessage.text('render'));
        await gen2.sendRequest(UserMessage.text('render'));

        expect(messages1, hasLength(2));
        expect(messages2, hasLength(2));

        expect((messages1[0] as BeginRendering).surfaceId, 'surface-gen1');
        expect((messages2[0] as BeginRendering).surfaceId, 'surface-gen2');

        gen1.dispose();
        gen2.dispose();
      });
    });

    group('Rapid Request Sequences', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('sequential requests all complete successfully', () async {
        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        for (var i = 0; i < 10; i++) {
          mockHandler.stubTextResponse('Response $i');
          await generator.sendRequest(UserMessage.text('Request $i'));
        }

        expect(textChunks, hasLength(10));
        for (var i = 0; i < 10; i++) {
          expect(textChunks[i], 'Response $i');
        }
      });

      test('responses are received in order', () async {
        final responses = <String>[];
        generator.textResponseStream.listen(responses.add);

        for (var i = 0; i < 5; i++) {
          mockHandler.stubTextResponse('[$i]');
          await generator.sendRequest(UserMessage.text('msg $i'));
        }

        expect(responses, ['[0]', '[1]', '[2]', '[3]', '[4]']);
      });

      test('all requests tracked correctly', () async {
        mockHandler.stubTextResponse('Response');

        for (var i = 0; i < 5; i++) {
          await generator.sendRequest(UserMessage.text('Request $i'));
        }

        expect(mockHandler.createStreamCallCount, 5);
        expect(mockHandler.capturedRequests, hasLength(5));
      });
    });

    group('Large Payload Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('handles very long user message', () async {
        final longMessage = 'x' * 10000;
        mockHandler.stubTextResponse('Received');

        await generator.sendRequest(UserMessage.text(longMessage));

        expect(mockHandler.lastRequest?.messages.last['content'], longMessage);
      });

      test('handles many messages in history', () async {
        mockHandler.stubTextResponse('Response');

        final history = List.generate(
          100,
          (i) => i.isEven
              ? UserMessage.text('User $i')
              : AiTextMessage.text('AI $i'),
        );

        await generator.sendRequest(
          UserMessage.text('Current'),
          history: history,
        );

        // History + current message
        expect(mockHandler.lastRequest?.messages, hasLength(101));
      });

      test('handles large widget response', () async {
        mockHandler.stubEvents(
          MockEventFactory.largeWidgetResponse(
            surfaceId: 'large',
            widgetCount: 100,
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render large'));

        // BeginRendering + SurfaceUpdate
        expect(messages, hasLength(2));

        final update = messages[1] as SurfaceUpdate;
        expect(update.components, hasLength(100));
      });

      test('handles large data model update', () async {
        final largeData = <String, dynamic>{};
        for (var i = 0; i < 100; i++) {
          largeData['key$i'] = 'value$i';
        }

        mockHandler.stubEvents(
          MockEventFactory.dataModelUpdateResponse(
            updates: largeData,
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('large data'));

        expect(messages, hasLength(1));
        final update = messages[0] as DataModelUpdate;
        final contents = update.contents as Map<String, dynamic>;
        expect(contents.keys, hasLength(100));
      });
    });

    group('Real-World Conversation Flows', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('chat flow: user -> AI text -> user -> AI UI', () async {
        final textResponses = <String>[];
        final a2uiMessages = <A2uiMessage>[];

        generator.textResponseStream.listen(textResponses.add);
        generator.a2uiMessageStream.listen(a2uiMessages.add);

        // First exchange: text response
        mockHandler.stubTextResponse('Hello! How can I help?');
        await generator.sendRequest(UserMessage.text('Hi'));

        expect(textResponses, ['Hello! How can I help?']);

        // Second exchange: UI response
        mockHandler.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'form',
            widgets: [
              {
                'type': 'textField',
                'properties': {'label': 'Name'},
              },
            ],
          ),
        );

        await generator.sendRequest(
          UserMessage.text('Show me a form'),
          history: [
            UserMessage.text('Hi'),
            AiTextMessage.text('Hello! How can I help?'),
          ],
        );

        expect(a2uiMessages, hasLength(2));
        expect(a2uiMessages[0], isA<BeginRendering>());
        expect(a2uiMessages[1], isA<SurfaceUpdate>());
      });

      test('form generation flow', () async {
        mockHandler.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'contact-form',
            widgets: [
              {
                'type': 'text',
                'properties': {'content': 'Contact Form'},
              },
              {
                'type': 'textField',
                'properties': {'label': 'Name', 'required': true},
              },
              {
                'type': 'textField',
                'properties': {'label': 'Email', 'required': true},
              },
              {
                'type': 'textField',
                'properties': {'label': 'Message', 'multiline': true},
              },
              {
                'type': 'button',
                'properties': {'label': 'Submit'},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('Create a contact form'));

        expect(messages, hasLength(2));

        final update = messages[1] as SurfaceUpdate;
        expect(update.components, hasLength(5));
        // Type is the key in componentProperties, id is a UUID
        expect(update.components[0].componentProperties.containsKey('text'),
            isTrue,);
        expect(update.components[4].componentProperties.containsKey('button'),
            isTrue,);
      });

      test('recovery after failed request', () async {
        final texts = <String>[];
        generator.textResponseStream.listen(texts.add);

        // First request fails (error handled internally by stream handler)
        mockHandler.stubError(
          const NetworkException(message: 'Network error', requestId: 'r1'),
        );
        await generator.sendRequest(UserMessage.text('Hello'));

        // isProcessing should be false after completion
        expect(generator.isProcessing.value, isFalse);

        // User retries, succeeds
        mockHandler.stubTextResponse('Connection restored. Hello!');
        await generator.sendRequest(UserMessage.text('Hello again'));

        expect(texts, ['Connection restored. Hello!']);
      });
    });

    group('Catalog Integration', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('widgets from catalog are rendered correctly', () async {
        // Use test catalog widgets
        mockHandler.stubEvents(
          MockEventFactory.surfaceUpdateResponse(
            surfaceId: 'catalog-test',
            widgets: [
              {
                'type': 'Text',
                'properties': {'text': 'Hello', 'style': 'normal'},
              },
              {
                'type': 'Button',
                'properties': {'label': 'Click', 'action': 'submit'},
              },
              {
                'type': 'Container',
                'properties': {'color': '#FF0000', 'padding': 8},
              },
            ],
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        final update = messages[0] as SurfaceUpdate;
        expect(update.components, hasLength(3));

        // Type is the key in componentProperties, id is a UUID
        expect(update.components[0].componentProperties.containsKey('Text'),
            isTrue,);
        expect(update.components[1].componentProperties.containsKey('Button'),
            isTrue,);
        expect(
            update.components[2].componentProperties.containsKey('Container'),
            isTrue,);

        // All IDs are unique UUIDs
        final ids = update.components.map((c) => c.id).toSet();
        expect(ids.length, 3);
      });
    });

    group('Mixed Content Responses', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('text and UI in same response go to correct streams', () async {
        mockHandler.stubEvents(
          MockEventFactory.mixedTextAndWidgetResponse(
            text: 'Here is your widget:',
            surfaceId: 'mixed',
            widgets: [
              {
                'type': 'Card',
                'properties': {'title': 'Result'},
              },
            ],
          ),
        );

        final texts = <String>[];
        final messages = <A2uiMessage>[];

        generator.textResponseStream.listen(texts.add);
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('show mixed'));

        expect(texts, ['Here is your widget:']);
        expect(messages, hasLength(2)); // BeginRendering + SurfaceUpdate
      });

      test('multiple text chunks and widgets interleaved', () async {
        // Complex response with text, then widget, demonstrating stream separation
        mockHandler.stubEvents([
          {
            'type': 'content_block_start',
            'index': 0,
            'content_block': {'type': 'text'},
          },
          {
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'Part 1. '},
          },
          {
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'Part 2.'},
          },
          {'type': 'content_block_stop', 'index': 0},
          ...MockEventFactory.beginRenderingResponse(surfaceId: 'inline'),
          {'type': 'message_stop'},
        ]);

        final texts = <String>[];
        final messages = <A2uiMessage>[];

        generator.textResponseStream.listen(texts.add);
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('complex'));

        expect(texts, ['Part 1. ', 'Part 2.']);
        expect(messages, hasLength(1)); // Just BeginRendering
      });
    });

    group('History Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('history is passed correctly to handler', () async {
        mockHandler.stubTextResponse('Response');

        final history = <ChatMessage>[
          UserMessage.text('First'),
          AiTextMessage.text('First response'),
          UserMessage.text('Second'),
          AiTextMessage.text('Second response'),
        ];

        await generator.sendRequest(
          UserMessage.text('Third'),
          history: history,
        );

        final messages = mockHandler.lastRequest!.messages;
        expect(messages, hasLength(5));

        expect(messages[0]['role'], 'user');
        expect(messages[0]['content'], 'First');
        expect(messages[4]['role'], 'user');
        expect(messages[4]['content'], 'Third');
      });

      test('empty history works correctly', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(
          UserMessage.text('Message'),
          history: [],
        );

        expect(mockHandler.lastRequest!.messages, hasLength(1));
      });

      test('null history works correctly', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(UserMessage.text('Message'));

        expect(mockHandler.lastRequest!.messages, hasLength(1));
      });
    });
  });
}
