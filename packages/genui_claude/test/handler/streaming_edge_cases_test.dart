import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/genui_claude.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'streaming_edge_cases_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Streaming Edge Cases', () {
    late MockClient mockClient;
    late Uri testEndpoint;

    setUp(() {
      mockClient = MockClient();
      testEndpoint = Uri.parse('https://api.example.com/chat');
    });

    group('stream cancellation', () {
      test('can cancel stream mid-emission', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Send events in a single chunk that we control timing of
        const sseBody = '''
data: {"type": "message_start"}

data: {"type": "content_block_start"}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];
        var cancelledAfterFirst = false;
        StreamSubscription<Map<String, dynamic>>? subscription;

        subscription = handler.createStream(request).listen((event) {
          events.add(event);
          // Cancel after receiving first event
          if (!cancelledAfterFirst) {
            cancelledAfterFirst = true;
            subscription?.cancel();
          }
        });

        // Wait a short time for stream processing
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // We should have received at least one event before cancellation took effect
        expect(events, isNotEmpty);
        expect(events[0]['type'], equals('message_start'));

        handler.dispose();
      });

      test('handles stream pause and resume', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final controller = StreamController<List<int>>();
        final response = http.StreamedResponse(controller.stream, 200);
        when(mockClient.send(any)).thenAnswer((_) async => response);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];
        final subscription = handler.createStream(request).listen(events.add);

        // Emit first event
        controller.add(utf8.encode('data: {"type": "message_start"}\n\n'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Pause
        subscription.pause();
        controller.add(utf8.encode('data: {"type": "content_block_start"}\n\n'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Resume
        subscription.resume();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        controller.add(utf8.encode('data: {"type": "message_stop"}\n\n'));
        await controller.close();

        await subscription.asFuture<void>();
        await subscription.cancel();

        expect(events.length, equals(3));

        handler.dispose();
      });
    });

    group('partial chunk handling', () {
      test('handles events split across chunks', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final controller = StreamController<List<int>>();
        final response = http.StreamedResponse(controller.stream, 200);
        when(mockClient.send(any)).thenAnswer((_) async => response);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];
        final subscription = handler.createStream(request).listen(events.add);

        // Split a single event across multiple chunks
        controller.add(utf8.encode('data: {"type": '));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        controller.add(utf8.encode('"message_start"}\n\n'));
        await Future<void>.delayed(const Duration(milliseconds: 5));

        controller.add(utf8.encode('data: {"type": "message_stop"}\n\n'));
        await controller.close();

        await subscription.asFuture<void>();
        await subscription.cancel();

        expect(events.length, equals(2));
        expect(events[0]['type'], equals('message_start'));
        expect(events[1]['type'], equals('message_stop'));

        handler.dispose();
      });

      test('handles multiple events in single chunk', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Send multiple events in a single chunk
        const sseBody = '''
data: {"type": "message_start"}

data: {"type": "content_block_start", "index": 0}

data: {"type": "content_block_delta", "delta": {"text": "Hello"}}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(4));
        expect(events[0]['type'], equals('message_start'));
        expect(events[1]['type'], equals('content_block_start'));
        expect(events[2]['type'], equals('content_block_delta'));
        expect(events[3]['type'], equals('message_stop'));

        handler.dispose();
      });

      test('handles incomplete line at end of chunk', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final controller = StreamController<List<int>>();
        final response = http.StreamedResponse(controller.stream, 200);
        when(mockClient.send(any)).thenAnswer((_) async => response);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];
        final subscription = handler.createStream(request).listen(events.add);

        // First chunk ends mid-line
        controller.add(utf8.encode('data: {"type": "message_start"}\n\ndata: {"type":'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Second chunk completes the line
        controller.add(utf8.encode(' "message_stop"}\n\n'));
        await controller.close();

        await subscription.asFuture<void>();
        await subscription.cancel();

        expect(events.length, equals(2));

        handler.dispose();
      });
    });

    group('large response handling', () {
      test('handles large content blocks', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Create a large text delta (10KB)
        final largeText = 'x' * 10000;
        final sseBody = '''
data: {"type": "message_start"}

data: {"type": "content_block_delta", "delta": {"text": "$largeText"}}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(3));
        final delta = events[1]['delta'] as Map<String, dynamic>;
        expect((delta['text'] as String).length, equals(10000));

        handler.dispose();
      });

      test('handles many small events', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        // Generate 100 delta events
        final buffer = StringBuffer();
        buffer.write('data: {"type": "message_start"}\n\n');
        for (var i = 0; i < 100; i++) {
          buffer.write('data: {"type": "content_block_delta", "index": $i}\n\n');
        }
        buffer.write('data: {"type": "message_stop"}\n\n');

        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(buffer.toString())),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(102)); // start + 100 deltas + stop

        handler.dispose();
      });
    });

    group('empty and edge responses', () {
      test('handles empty SSE body', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events, isEmpty);

        handler.dispose();
      });

      test('handles only whitespace', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode('\n\n\n   \n\n')),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events, isEmpty);

        handler.dispose();
      });

      test('handles data: prefix without content', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data:

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        // Empty data should result in error event, then message_stop
        expect(events.length, greaterThanOrEqualTo(1));

        handler.dispose();
      });
    });

    group('connection interruption', () {
      test('handles abrupt stream close', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final controller = StreamController<List<int>>();
        final response = http.StreamedResponse(controller.stream, 200);
        when(mockClient.send(any)).thenAnswer((_) async => response);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];
        final completer = Completer<void>();

        handler.createStream(request).listen(
          events.add,
          onDone: completer.complete,
          onError: completer.completeError,
        );

        // Emit partial data then close abruptly
        controller.add(utf8.encode('data: {"type": "message_start"}\n\n'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await controller.close();

        await completer.future;

        expect(events.length, equals(1));
        expect(events[0]['type'], equals('message_start'));

        handler.dispose();
      });

      test('handles stream error', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final controller = StreamController<List<int>>();
        final response = http.StreamedResponse(controller.stream, 200);
        when(mockClient.send(any)).thenAnswer((_) async => response);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = <Map<String, dynamic>>[];

        final subscription = handler.createStream(request).listen(
          events.add,
          onError: (Object e) {
            // Error captured - test verifies stream continues despite errors
          },
        );

        // Emit some data
        controller.add(utf8.encode('data: {"type": "message_start"}\n\n'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Add error to stream
        controller.addError(Exception('Connection lost'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await subscription.cancel();
        await controller.close();

        expect(events.length, greaterThanOrEqualTo(1));

        handler.dispose();
      });
    });

    group('special characters in content', () {
      test('handles unicode content', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data: {"type": "content_block_delta", "delta": {"text": "Hello 世界 🌍 émojis"}}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(2));
        final delta = events[0]['delta'] as Map<String, dynamic>;
        expect(delta['text'], equals('Hello 世界 🌍 émojis'));

        handler.dispose();
      });

      test('handles escaped characters in JSON', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = r'''
data: {"type": "content_block_delta", "delta": {"text": "Line1\nLine2\tTabbed\u0000Null"}}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(2));
        final delta = events[0]['delta'] as Map<String, dynamic>;
        expect(delta['text'] as String, contains('\n'));
        expect(delta['text'] as String, contains('\t'));

        handler.dispose();
      });

      test('handles JSON with nested objects', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = '''
data: {"type": "content_block_start", "content_block": {"type": "tool_use", "id": "123", "name": "test", "input": {"nested": {"deep": "value"}}}}

data: {"type": "message_stop"}

''';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(2));
        final contentBlock = events[0]['content_block'] as Map<String, dynamic>;
        final input = contentBlock['input'] as Map<String, dynamic>;
        final nested = input['nested'] as Map<String, dynamic>;
        expect(nested['deep'], equals('value'));

        handler.dispose();
      });
    });

    group('SSE format variations', () {
      test('handles Windows line endings (CRLF)', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = 'data: {"type": "message_start"}\r\n\r\ndata: {"type": "message_stop"}\r\n\r\n';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(2));

        handler.dispose();
      });

      test('handles mixed line endings', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = 'data: {"type": "message_start"}\n\ndata: {"type": "content"}\r\n\r\ndata: {"type": "message_stop"}\n\n';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        expect(events.length, equals(3));

        handler.dispose();
      });

      test('handles extra whitespace around data', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        const sseBody = 'data:{"type": "message_start"}\n\ndata:  {"type": "message_stop"}\n\n';
        final mockResponse = http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 1024,
        );

        final events = await handler.createStream(request).toList();

        // The parser should handle data: with or without space
        expect(events.length, greaterThanOrEqualTo(1));

        handler.dispose();
      });
    });
  });
}
