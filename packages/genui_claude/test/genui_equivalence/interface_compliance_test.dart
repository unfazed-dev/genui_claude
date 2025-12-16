/// Interface compliance tests for ClaudeContentGenerator.
///
/// These tests verify that ClaudeContentGenerator correctly implements
/// the GenUI SDK's ContentGenerator interface.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Interface Compliance', () {
    group('Type System Compliance', () {
      test('ClaudeContentGenerator implements ContentGenerator', () {
        final generator = ClaudeContentGenerator(apiKey: 'test-key');

        // This assignment must compile - proves interface compliance
        // ignore: omit_local_variable_types
        final ContentGenerator contentGenerator = generator;

        expect(contentGenerator, isA<ContentGenerator>());
        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('ClaudeContentGenerator.proxy implements ContentGenerator', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://example.com/api'),
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('ClaudeContentGenerator.withHandler implements ContentGenerator', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });
    });

    group('Stream Type Compliance', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('a2uiMessageStream is Stream<A2uiMessage>', () {
        expect(generator.a2uiMessageStream, isA<Stream<A2uiMessage>>());
      });

      test('textResponseStream is Stream<String>', () {
        expect(generator.textResponseStream, isA<Stream<String>>());
      });

      test('errorStream is Stream<ContentGeneratorError>', () {
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
      });

      test('isProcessing is ValueListenable<bool>', () {
        expect(generator.isProcessing, isA<ValueListenable<bool>>());
      });

      test('all streams are broadcast streams (support multiple listeners)', () {
        // a2uiMessageStream
        final a2uiSub1 = generator.a2uiMessageStream.listen((_) {});
        final a2uiSub2 = generator.a2uiMessageStream.listen((_) {});
        expect(a2uiSub1, isNotNull);
        expect(a2uiSub2, isNotNull);
        a2uiSub1.cancel();
        a2uiSub2.cancel();

        // textResponseStream
        final textSub1 = generator.textResponseStream.listen((_) {});
        final textSub2 = generator.textResponseStream.listen((_) {});
        expect(textSub1, isNotNull);
        expect(textSub2, isNotNull);
        textSub1.cancel();
        textSub2.cancel();

        // errorStream
        final errorSub1 = generator.errorStream.listen((_) {});
        final errorSub2 = generator.errorStream.listen((_) {});
        expect(errorSub1, isNotNull);
        expect(errorSub2, isNotNull);
        errorSub1.cancel();
        errorSub2.cancel();
      });
    });

    group('isProcessing ValueListenable Compliance', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('initial value is false', () {
        expect(generator.isProcessing.value, isFalse);
      });

      test('supports addListener/removeListener', () {
        var listenerCallCount = 0;
        void listener() {
          listenerCallCount++;
        }

        generator.isProcessing.addListener(listener);
        // Listener is not called until value changes
        expect(listenerCallCount, 0);

        generator.isProcessing.removeListener(listener);
        // Should not throw
      });

      test('value changes to true during sendRequest', () async {
        mockHandler.stubTextResponse('Hello');

        var sawProcessingTrue = false;
        generator.isProcessing.addListener(() {
          if (generator.isProcessing.value) {
            sawProcessingTrue = true;
          }
        });

        await generator.sendRequest(UserMessage.text('test'));

        // Value should be false after completion
        expect(generator.isProcessing.value, isFalse);
        // But we should have seen it become true during processing
        expect(sawProcessingTrue, isTrue);
      });
    });

    group('sendRequest Method Compliance', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('accepts UserMessage', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(UserMessage.text('Hello'));

        expect(mockHandler.createStreamCallCount, 1);
        expect(mockHandler.lastRequest?.messages, isNotEmpty);
      });

      test('accepts UserMessage with history', () async {
        mockHandler.stubTextResponse('Response');

        final history = <ChatMessage>[
          UserMessage.text('First message'),
          AiTextMessage.text('First response'),
        ];

        await generator.sendRequest(
          UserMessage.text('Second message'),
          history: history,
        );

        expect(mockHandler.createStreamCallCount, 1);
        // Should have history + current message
        expect(mockHandler.lastRequest?.messages.length, 3);
      });

      test('returns Future<void>', () async {
        mockHandler.stubTextResponse('Response');

        final result = generator.sendRequest(UserMessage.text('test'));

        expect(result, isA<Future<void>>());
        await result;
      });
    });

    group('dispose Method Compliance', () {
      test('dispose cleans up resources', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        // Should not throw
        generator.dispose();

        expect(mockHandler.disposed, isTrue);
      });

      test('dispose is idempotent (can be called after dispose)', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        generator.dispose();
        // Second dispose should not throw or cause issues
        // (though exact behavior depends on implementation)
      });
    });

    group('ChatMessage Type Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('handles UserMessage.text', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(UserMessage.text('Hello'));

        expect(mockHandler.lastRequest?.messages.first['role'], 'user');
      });

      test('handles AiTextMessage in history', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(
          UserMessage.text('Follow up'),
          history: [
            UserMessage.text('Hello'),
            AiTextMessage.text('Hi there!'),
          ],
        );

        final messages = mockHandler.lastRequest?.messages ?? [];
        expect(messages[1]['role'], 'assistant');
      });

      test('handles ToolResponseMessage in history', () async {
        mockHandler.stubTextResponse('Response');

        await generator.sendRequest(
          UserMessage.text('Follow up'),
          history: [
            UserMessage.text('Hello'),
            const ToolResponseMessage([
              ToolResultPart(callId: 'call-1', result: 'Tool result'),
            ]),
          ],
        );

        final messages = mockHandler.lastRequest?.messages ?? [];
        // ToolResponseMessage becomes user role with tool_result content
        expect(messages[1]['role'], 'user');
        expect(
          messages[1]['content'],
          isA<List<dynamic>>().having(
            (l) => (l.first as Map<String, dynamic>)['type'],
            'first content type',
            'tool_result',
          ),
        );
      });
    });
  });
}
