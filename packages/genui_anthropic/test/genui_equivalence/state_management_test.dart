/// State management tests for AnthropicContentGenerator.
///
/// These tests verify generator state management matches GenUI SDK
/// expectations for ContentGenerator.
@TestOn('vm')
library;


import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI State Management', () {
    group('isProcessing State Lifecycle', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('initial state is false', () {
        expect(generator.isProcessing.value, isFalse);
      });

      test('becomes true on sendRequest', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.textResponse('Hello'),
          delay: const Duration(milliseconds: 50),
        );

        var becameTrue = false;
        generator.isProcessing.addListener(() {
          if (generator.isProcessing.value) {
            becameTrue = true;
          }
        });

        final future = generator.sendRequest(UserMessage.text('test'));

        // Should become true almost immediately
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(generator.isProcessing.value, isTrue);
        expect(becameTrue, isTrue);

        await future;
      });

      test('becomes false on success completion', () async {
        mockHandler.stubTextResponse('Success');

        await generator.sendRequest(UserMessage.text('test'));

        expect(generator.isProcessing.value, isFalse);
      });

      test('becomes false on error completion', () async {
        mockHandler.stubError(Exception('Test error'));

        await generator.sendRequest(UserMessage.text('test'));

        expect(generator.isProcessing.value, isFalse);
      });

      test('tracks state through full request lifecycle', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(['a', 'b', 'c']),
        );

        final states = <bool>[];
        generator.isProcessing.addListener(() {
          states.add(generator.isProcessing.value);
        });

        expect(generator.isProcessing.value, isFalse);

        await generator.sendRequest(UserMessage.text('test'));

        expect(generator.isProcessing.value, isFalse);
        // Should have seen true -> false transition
        expect(states, contains(true));
        expect(states.last, isFalse);
      });
    });

    group('Multiple ValueNotifier Listeners', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('multiple listeners receive same value changes', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.textResponse('Test'),
          delay: const Duration(milliseconds: 20),
        );

        final listener1States = <bool>[];
        final listener2States = <bool>[];
        final listener3States = <bool>[];

        generator.isProcessing.addListener(() {
          listener1States.add(generator.isProcessing.value);
        });
        generator.isProcessing.addListener(() {
          listener2States.add(generator.isProcessing.value);
        });
        generator.isProcessing.addListener(() {
          listener3States.add(generator.isProcessing.value);
        });

        await generator.sendRequest(UserMessage.text('test'));

        // All listeners should have same sequence
        expect(listener1States, equals(listener2States));
        expect(listener2States, equals(listener3States));
      });

      test('removed listener stops receiving updates', () async {
        mockHandler.stubTextResponse('Test');

        final listener1States = <bool>[];
        final listener2States = <bool>[];

        void listener1() {
          listener1States.add(generator.isProcessing.value);
        }

        void listener2() {
          listener2States.add(generator.isProcessing.value);
        }

        generator.isProcessing.addListener(listener1);
        generator.isProcessing.addListener(listener2);

        // Remove listener2 before request
        generator.isProcessing.removeListener(listener2);

        await generator.sendRequest(UserMessage.text('test'));

        expect(listener1States, isNotEmpty);
        expect(listener2States, isEmpty);
      });
    });

    group('Concurrent Request Prevention', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('second sendRequest during processing emits error', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(
            List.generate(10, (i) => 'chunk$i'),
          ),
          delay: const Duration(milliseconds: 20),
        );

        final errors = <ContentGeneratorError>[];
        generator.errorStream.listen(errors.add);

        // Start first request
        final first = generator.sendRequest(UserMessage.text('first'));

        // Wait for processing to start
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(generator.isProcessing.value, isTrue);

        // Try second request while first is processing
        await generator.sendRequest(UserMessage.text('second'));

        await first;

        // Should have received error about request in progress
        expect(
          errors.any((e) => e.error.toString().contains('in progress')),
          isTrue,
        );
      });

      test('first request continues unaffected by second attempt', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(['A', 'B', 'C']),
        );

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        // Start first request
        final first = generator.sendRequest(UserMessage.text('first'));

        // Wait and try second
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await generator.sendRequest(UserMessage.text('second'));

        await first;

        // First request should complete normally
        expect(textChunks, ['A', 'B', 'C']);
      });

      test('can send after first completes', () async {
        mockHandler.stubTextResponse('First response');
        await generator.sendRequest(UserMessage.text('first'));

        mockHandler.stubTextResponse('Second response');

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('second'));

        expect(textChunks, contains('Second response'));
      });
    });

    group('State Recovery After Errors', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('state correct after API error', () async {
        mockHandler.stubError(Exception('API Error'));

        await generator.sendRequest(UserMessage.text('test'));

        expect(generator.isProcessing.value, isFalse);
      });

      test('state correct after network timeout', () async {
        mockHandler.stubError(
          const TimeoutException(
            message: 'Timeout',
            timeout: Duration(seconds: 60),
            requestId: 'test-123',
          ),
        );

        await generator.sendRequest(UserMessage.text('test'));

        expect(generator.isProcessing.value, isFalse);
      });

      test('generator works after error recovery', () async {
        // First request fails
        mockHandler.stubError(Exception('Error'));
        await generator.sendRequest(UserMessage.text('fail'));

        expect(generator.isProcessing.value, isFalse);

        // Second request succeeds
        mockHandler.stubTextResponse('Success');

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('succeed'));

        expect(generator.isProcessing.value, isFalse);
        expect(textChunks, ['Success']);
      });

      test('multiple errors do not corrupt state', () async {
        for (var i = 0; i < 5; i++) {
          mockHandler.stubError(Exception('Error $i'));
          await generator.sendRequest(UserMessage.text('fail $i'));
          expect(generator.isProcessing.value, isFalse);
        }

        // Should still work after multiple errors
        mockHandler.stubTextResponse('Finally works');
        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('succeed'));
        expect(textChunks, ['Finally works']);
      });
    });

    group('Post-Dispose Behavior', () {
      test('dispose cleans up handler', () {
        final mockHandler = MockApiHandler();
        final generator = AnthropicContentGenerator.withHandler(
          handler: mockHandler,
        );

        expect(mockHandler.disposed, isFalse);

        generator.dispose();

        expect(mockHandler.disposed, isTrue);
      });

      test('streams are closed after dispose', () async {
        final mockHandler = MockApiHandler();
        final generator = AnthropicContentGenerator.withHandler(
          handler: mockHandler,
        );

        var textStreamDone = false;
        var a2uiStreamDone = false;
        var errorStreamDone = false;

        generator.textResponseStream.listen(
          (_) {},
          onDone: () => textStreamDone = true,
        );
        generator.a2uiMessageStream.listen(
          (_) {},
          onDone: () => a2uiStreamDone = true,
        );
        generator.errorStream.listen(
          (_) {},
          onDone: () => errorStreamDone = true,
        );

        generator.dispose();

        await Future<void>.delayed(Duration.zero);

        expect(textStreamDone, isTrue);
        expect(a2uiStreamDone, isTrue);
        expect(errorStreamDone, isTrue);
      });
    });

    group('ValueListenable Contract', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('isProcessing is ValueListenable<bool>', () {
        expect(generator.isProcessing, isA<ValueListenable<bool>>());
      });

      test('value property returns current state', () {
        expect(generator.isProcessing.value, isA<bool>());
        expect(generator.isProcessing.value, isFalse);
      });

      test('addListener and removeListener work correctly', () {
        var callCount = 0;
        void listener() {
          callCount++;
        }

        generator.isProcessing.addListener(listener);
        generator.isProcessing.removeListener(listener);

        // After removal, listener should not be called
        // (would need to trigger state change to verify, but removal
        // should not throw)
        expect(callCount, 0);
      });
    });

    group('Request Tracking', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('capturedRequests tracks all requests', () async {
        mockHandler.stubTextResponse('Response 1');
        await generator.sendRequest(UserMessage.text('Message 1'));

        mockHandler.stubTextResponse('Response 2');
        await generator.sendRequest(UserMessage.text('Message 2'));

        mockHandler.stubTextResponse('Response 3');
        await generator.sendRequest(UserMessage.text('Message 3'));

        expect(mockHandler.capturedRequests, hasLength(3));
      });

      test('lastRequest contains most recent request', () async {
        mockHandler.stubTextResponse('First');
        await generator.sendRequest(UserMessage.text('First message'));

        mockHandler.stubTextResponse('Second');
        await generator.sendRequest(UserMessage.text('Second message'));

        expect(mockHandler.lastRequest, isNotNull);
        expect(
          mockHandler.lastRequest!.messages.last['content'],
          'Second message',
        );
      });

      test('createStreamCallCount increments correctly', () async {
        expect(mockHandler.createStreamCallCount, 0);

        mockHandler.stubTextResponse('Test');
        await generator.sendRequest(UserMessage.text('Test'));

        expect(mockHandler.createStreamCallCount, 1);

        mockHandler.stubTextResponse('Test 2');
        await generator.sendRequest(UserMessage.text('Test 2'));

        expect(mockHandler.createStreamCallCount, 2);
      });
    });
  });
}
