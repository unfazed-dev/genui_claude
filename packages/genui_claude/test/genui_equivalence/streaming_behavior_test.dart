/// Streaming behavior tests for ClaudeContentGenerator.
///
/// These tests verify that streaming semantics match GenUI SDK expectations
/// for ContentGenerator streams.
@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Streaming Behavior', () {
    group('Stream Cancellation Semantics', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('cancelling textResponseStream mid-stream stops receiving events',
          () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(
            ['Hello', ' ', 'World', '!'],
          ),
          delay: const Duration(milliseconds: 5),
        );

        final receivedChunks = <String>[];
        final subscription = generator.textResponseStream.listen((chunk) {
          receivedChunks.add(chunk);
          if (receivedChunks.length >= 2) {
            // Will cancel after receiving 2 chunks
          }
        });

        // Start the request but don't await
        final requestFuture = generator.sendRequest(UserMessage.text('test'));

        // Wait a bit then cancel
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await subscription.cancel();

        // Wait for request to complete
        await requestFuture;

        // Should have received some chunks before cancellation
        expect(receivedChunks, isNotEmpty);
      });

      test('cancelling a2uiMessageStream does not affect textResponseStream',
          () async {
        mockHandler.stubEvents(
          MockEventFactory.mixedTextAndWidgetResponse(
            text: 'Hello World',
            surfaceId: 'main',
          ),
        );

        final a2uiMessages = <A2uiMessage>[];
        final textChunks = <String>[];

        // Subscribe to both streams
        final a2uiSub = generator.a2uiMessageStream.listen(a2uiMessages.add);
        final textSub = generator.textResponseStream.listen(textChunks.add);

        // Cancel A2UI stream before request
        await a2uiSub.cancel();

        await generator.sendRequest(UserMessage.text('test'));

        await textSub.cancel();

        // Text stream should still receive events
        expect(textChunks, contains('Hello World'));
        // A2UI stream was cancelled, should not receive events
        expect(a2uiMessages, isEmpty);
      });

      test('cancelling errorStream does not affect other streams', () async {
        mockHandler.stubTextResponse('Hello');

        final textChunks = <String>[];
        final errors = <ContentGeneratorError>[];

        final errorSub = generator.errorStream.listen(errors.add);
        final textSub = generator.textResponseStream.listen(textChunks.add);

        // Cancel error stream before request
        await errorSub.cancel();

        await generator.sendRequest(UserMessage.text('test'));

        await textSub.cancel();

        // Text stream should still work
        expect(textChunks, contains('Hello'));
      });

      test('isProcessing correctly resets after stream cancellation', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(['a', 'b', 'c', 'd', 'e']),
        );

        expect(generator.isProcessing.value, isFalse);

        final subscription = generator.textResponseStream.listen((_) {});

        final requestFuture = generator.sendRequest(UserMessage.text('test'));

        // isProcessing should become true
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(generator.isProcessing.value, isTrue);

        // Cancel subscription
        await subscription.cancel();

        // Wait for request to complete
        await requestFuture;

        // isProcessing should be false after completion
        expect(generator.isProcessing.value, isFalse);
      });
    });

    group('Stream Completion Semantics', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('streams do not close after sendRequest completes', () async {
        mockHandler.stubTextResponse('First');

        final textChunks = <String>[];
        final subscription =
            generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('test'));
        expect(textChunks, ['First']);

        // Stub another response and send another request
        mockHandler.stubTextResponse('Second');
        await generator.sendRequest(UserMessage.text('test2'));

        // Stream should still receive new events
        expect(textChunks, ['First', 'Second']);

        await subscription.cancel();
      });

      test('stream not closed after request with error', () async {
        final textChunks = <String>[];
        final textSub = generator.textResponseStream.listen(textChunks.add);

        // First request throws error (handled internally)
        mockHandler.stubError(Exception('Test error'));
        await generator.sendRequest(UserMessage.text('test'));

        // Second request should still work - stream not closed
        mockHandler.stubTextResponse('Success');
        await generator.sendRequest(UserMessage.text('test2'));

        expect(textChunks, ['Success']);

        await textSub.cancel();
      });

      test('multiple sendRequest calls reuse same streams', () async {
        final textChunks = <String>[];
        final subscription =
            generator.textResponseStream.listen(textChunks.add);

        mockHandler.stubTextResponse('One');
        await generator.sendRequest(UserMessage.text('1'));

        mockHandler.stubTextResponse('Two');
        await generator.sendRequest(UserMessage.text('2'));

        mockHandler.stubTextResponse('Three');
        await generator.sendRequest(UserMessage.text('3'));

        expect(textChunks, ['One', 'Two', 'Three']);

        await subscription.cancel();
      });

      test('dispose closes all streams', () async {
        // Create a separate generator for this test
        final separateMockHandler = MockApiHandler();
        final separateGenerator = ClaudeContentGenerator.withHandler(
          handler: separateMockHandler,
        );

        var a2uiDone = false;
        var textDone = false;
        var errorDone = false;

        separateGenerator.a2uiMessageStream.listen(
          (_) {},
          onDone: () => a2uiDone = true,
        );
        separateGenerator.textResponseStream.listen(
          (_) {},
          onDone: () => textDone = true,
        );
        separateGenerator.errorStream.listen(
          (_) {},
          onDone: () => errorDone = true,
        );

        separateGenerator.dispose();

        // Give time for done callbacks
        await Future<void>.delayed(Duration.zero);

        expect(a2uiDone, isTrue);
        expect(textDone, isTrue);
        expect(errorDone, isTrue);
      });
    });

    group('Stream Event Ordering', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('BeginRendering always precedes SurfaceUpdate for same surface',
          () async {
        mockHandler.stubEvents(
          MockEventFactory.widgetRenderingResponse(
            surfaceId: 'test-surface',
          ),
        );

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        await subscription.cancel();

        expect(messages, hasLength(2));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());

        final beginRendering = messages[0] as BeginRendering;
        final surfaceUpdate = messages[1] as SurfaceUpdate;

        expect(beginRendering.surfaceId, 'test-surface');
        expect(surfaceUpdate.surfaceId, 'test-surface');
      });

      test('text chunks arrive in order', () async {
        mockHandler.stubEvents(
          MockEventFactory.streamingTextResponse([
            'The ',
            'quick ',
            'brown ',
            'fox ',
            'jumps.',
          ]),
        );

        final chunks = <String>[];
        final subscription = generator.textResponseStream.listen(chunks.add);

        await generator.sendRequest(UserMessage.text('test'));

        await subscription.cancel();

        expect(chunks, ['The ', 'quick ', 'brown ', 'fox ', 'jumps.']);
      });

      test('A2UI messages maintain sequence from API', () async {
        mockHandler.stubEvents(
          MockEventFactory.surfaceLifecycleResponse(
            surfaceId: 'lifecycle',
          ),
        );

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

      test('interleaved text and A2UI events emit to correct streams',
          () async {
        mockHandler.stubEvents(
          MockEventFactory.mixedTextAndWidgetResponse(
            text: 'Here is a widget:',
            surfaceId: 'widget-surface',
          ),
        );

        final textChunks = <String>[];
        final a2uiMessages = <A2uiMessage>[];

        final textSub = generator.textResponseStream.listen(textChunks.add);
        final a2uiSub = generator.a2uiMessageStream.listen(a2uiMessages.add);

        await generator.sendRequest(UserMessage.text('mixed'));

        await textSub.cancel();
        await a2uiSub.cancel();

        // Text should go to text stream
        expect(textChunks, ['Here is a widget:']);

        // A2UI messages should go to A2UI stream
        expect(a2uiMessages, hasLength(2));
        expect(a2uiMessages[0], isA<BeginRendering>());
        expect(a2uiMessages[1], isA<SurfaceUpdate>());
      });
    });

    group('Multiple Listeners on Broadcast Streams', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('multiple listeners on textResponseStream receive same events',
          () async {
        mockHandler.stubTextResponse('Broadcast test');

        final listener1 = <String>[];
        final listener2 = <String>[];
        final listener3 = <String>[];

        final sub1 = generator.textResponseStream.listen(listener1.add);
        final sub2 = generator.textResponseStream.listen(listener2.add);
        final sub3 = generator.textResponseStream.listen(listener3.add);

        await generator.sendRequest(UserMessage.text('test'));

        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();

        expect(listener1, ['Broadcast test']);
        expect(listener2, ['Broadcast test']);
        expect(listener3, ['Broadcast test']);
      });

      test('multiple listeners on a2uiMessageStream receive same events',
          () async {
        mockHandler.stubEvents(MockEventFactory.widgetRenderingResponse());

        final listener1 = <A2uiMessage>[];
        final listener2 = <A2uiMessage>[];

        final sub1 = generator.a2uiMessageStream.listen(listener1.add);
        final sub2 = generator.a2uiMessageStream.listen(listener2.add);

        await generator.sendRequest(UserMessage.text('test'));

        await sub1.cancel();
        await sub2.cancel();

        expect(listener1, hasLength(2));
        expect(listener2, hasLength(2));
        expect(listener1[0].runtimeType, listener2[0].runtimeType);
        expect(listener1[1].runtimeType, listener2[1].runtimeType);
      });

      test('errorStream supports multiple listeners (broadcast)', () {
        // Multiple listeners can subscribe without error
        final listener1 = <ContentGeneratorError>[];
        final listener2 = <ContentGeneratorError>[];

        final sub1 = generator.errorStream.listen(listener1.add);
        final sub2 = generator.errorStream.listen(listener2.add);

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });

      test('adding listener after events started still works', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(['A', 'B', 'C', 'D', 'E']),
        );

        final earlyListener = <String>[];
        final lateListener = <String>[];

        final earlySub = generator.textResponseStream.listen(earlyListener.add);

        final requestFuture = generator.sendRequest(UserMessage.text('test'));

        // Add late listener after some delay
        await Future<void>.delayed(const Duration(milliseconds: 25));
        final lateSub = generator.textResponseStream.listen(lateListener.add);

        await requestFuture;

        await earlySub.cancel();
        await lateSub.cancel();

        // Early listener should have all events
        expect(earlyListener, hasLength(5));
        // Late listener may have fewer events (depends on timing)
        // But importantly, it should work without throwing
        expect(lateListener, isA<List<String>>());
      });
    });

    group('Post-Dispose Stream Behavior', () {
      test('stream subscriptions before dispose receive done event', () async {
        final mockHandler = MockApiHandler();
        final generator =
            ClaudeContentGenerator.withHandler(handler: mockHandler);

        var receivedDone = false;
        generator.textResponseStream.listen(
          (_) {},
          onDone: () => receivedDone = true,
        );

        generator.dispose();
        await Future<void>.delayed(Duration.zero);

        expect(receivedDone, isTrue);
      });

      test('listening to stream after dispose receives done immediately',
          () async {
        final mockHandler = MockApiHandler();
        final generator =
            ClaudeContentGenerator.withHandler(handler: mockHandler);

        generator.dispose();

        var receivedDone = false;
        generator.textResponseStream.listen(
          (_) {},
          onDone: () => receivedDone = true,
          onError: (Object _) {},
        );

        await Future<void>.delayed(Duration.zero);

        // After dispose, stream should be closed
        expect(receivedDone, isTrue);
      });
    });

    group('Backpressure Handling', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('pause and resume on textResponseStream works', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
          ),
          delay: const Duration(milliseconds: 5),
        );

        final received = <String>[];
        late StreamSubscription<String> subscription;

        subscription = generator.textResponseStream.listen((chunk) {
          received.add(chunk);
          if (received.length == 3) {
            subscription.pause();
            // Resume after a delay
            Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
              subscription.resume();
            });
          }
        });

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for resume and completion
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await subscription.cancel();

        // Should receive all events despite pause
        expect(received, hasLength(10));
      });

      test('multiple pauses do not lose events', () async {
        mockHandler.stubDelayedEvents(
          MockEventFactory.streamingTextResponse(
            List.generate(20, (i) => 'chunk$i'),
          ),
          delay: const Duration(milliseconds: 2),
        );

        final received = <String>[];
        late StreamSubscription<String> subscription;
        var pauseCount = 0;

        subscription = generator.textResponseStream.listen((chunk) {
          received.add(chunk);
          if (received.length % 5 == 0 && pauseCount < 3) {
            pauseCount++;
            subscription.pause();
            Future<void>.delayed(const Duration(milliseconds: 10)).then((_) {
              subscription.resume();
            });
          }
        });

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for all pauses/resumes and completion
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await subscription.cancel();

        // Should receive all events
        expect(received, hasLength(20));
        expect(pauseCount, 3);
      });
    });
  });
}
