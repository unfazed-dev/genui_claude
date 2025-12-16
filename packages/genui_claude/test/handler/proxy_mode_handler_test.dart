import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/genui_claude.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'proxy_mode_handler_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ProxyModeHandler', () {
    late MockClient mockClient;
    late Uri testEndpoint;

    setUp(() {
      mockClient = MockClient();
      testEndpoint = Uri.parse('https://api.example.com/chat');
    });

    tearDown(() {
      // Ensure client is closed
    });

    group('constructor', () {
      test('creates handler with required parameters', () {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        expect(handler, isA<ApiHandler>());
        handler.dispose();
      });

      test('throws on endpoint without scheme', () {
        expect(
          () => ProxyModeHandler(
            endpoint: Uri.parse('example.com/api'),
            client: mockClient,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts http scheme', () {
        final handler = ProxyModeHandler(
          endpoint: Uri.parse('http://example.com/api'),
          client: mockClient,
        );

        expect(handler, isA<ApiHandler>());
        handler.dispose();
      });

      test('accepts https scheme', () {
        final handler = ProxyModeHandler(
          endpoint: Uri.parse('https://example.com/api'),
          client: mockClient,
        );

        expect(handler, isA<ApiHandler>());
        handler.dispose();
      });

      test('creates handler with auth token', () {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          authToken: 'test-token',
          client: mockClient,
        );

        expect(handler, isA<ApiHandler>());
        handler.dispose();
      });

      test('creates handler with custom config', () {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          config: const ProxyConfig(
            timeout: Duration(seconds: 180),
            maxHistoryMessages: 50,
          ),
          client: mockClient,
        );

        expect(handler, isA<ApiHandler>());
        handler.dispose();
      });
    });

    group('createStream', () {
      test('sends POST request to endpoint', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final mockResponse = _createMockStreamedResponse(
          statusCode: 200,
          body: 'data: {"type": "message_stop"}\n\n',
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final captured = verify(mockClient.send(captureAny)).captured;
        final sentRequest = captured.first as http.BaseRequest;

        expect(sentRequest.method, equals('POST'));
        expect(sentRequest.url, equals(testEndpoint));

        handler.dispose();
      });

      test('includes correct headers without auth token', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        );

        final mockResponse = _createMockStreamedResponse(
          statusCode: 200,
          body: 'data: {"type": "message_stop"}\n\n',
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final captured = verify(mockClient.send(captureAny)).captured;
        final sentRequest = captured.first as http.Request;

        expect(sentRequest.headers['Content-Type'], equals('application/json'));
        expect(sentRequest.headers['Accept'], equals('text/event-stream'));
        expect(sentRequest.headers.containsKey('Authorization'), isFalse);

        handler.dispose();
      });

      test('includes Authorization header with auth token', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          authToken: 'my-bearer-token',
          client: mockClient,
        );

        final mockResponse = _createMockStreamedResponse(
          statusCode: 200,
          body: 'data: {"type": "message_stop"}\n\n',
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final captured = verify(mockClient.send(captureAny)).captured;
        final sentRequest = captured.first as http.Request;

        expect(
          sentRequest.headers['Authorization'],
          equals('Bearer my-bearer-token'),
        );

        handler.dispose();
      });

      test('includes custom headers from config', () async {
        final handler = ProxyModeHandler(
          endpoint: testEndpoint,
          config: const ProxyConfig(
            headers: {'X-Custom-Header': 'custom-value'},
          ),
          client: mockClient,
        );

        final mockResponse = _createMockStreamedResponse(
          statusCode: 200,
          body: 'data: {"type": "message_stop"}\n\n',
        );
        when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
        );

        await handler.createStream(request).toList();

        final captured = verify(mockClient.send(captureAny)).captured;
        final sentRequest = captured.first as http.Request;

        expect(sentRequest.headers['X-Custom-Header'], equals('custom-value'));

        handler.dispose();
      });

      group('request body', () {
        test('includes messages and max_tokens', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
              {'role': 'assistant', 'content': 'Hi there!'},
            ],
            maxTokens: 2048,
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body['messages'], hasLength(2));
          expect(body['max_tokens'], equals(2048));
          expect(body['stream'], isTrue);

          handler.dispose();
        });

        test('includes system instruction when provided', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
            systemInstruction: 'You are a helpful assistant.',
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body['system'], equals('You are a helpful assistant.'));

          handler.dispose();
        });

        test('includes tools when provided', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          final tools = [
            {
              'name': 'get_weather',
              'description': 'Get weather info',
              'input_schema': {
                'type': 'object',
                'properties': {
                  'location': {'type': 'string'},
                },
              },
            },
          ];

          final request = ApiRequest(
            messages: const [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
            tools: tools,
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body['tools'], equals(tools));

          handler.dispose();
        });

        test('includes model when provided', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
            model: 'claude-opus-4-20250514',
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body['model'], equals('claude-opus-4-20250514'));

          handler.dispose();
        });

        test('includes temperature when provided', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
            temperature: 0.7,
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body['temperature'], equals(0.7));

          handler.dispose();
        });

        test('excludes null optional fields', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: 'data: {"type": "message_stop"}\n\n',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
            // systemInstruction, tools, model, temperature all null
          );

          await handler.createStream(request).toList();

          final captured = verify(mockClient.send(captureAny)).captured;
          final sentRequest = captured.first as http.Request;
          final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;

          expect(body.containsKey('system'), isFalse);
          expect(body.containsKey('tools'), isFalse);
          expect(body.containsKey('model'), isFalse);
          expect(body.containsKey('temperature'), isFalse);

          handler.dispose();
        });
      });

      group('SSE parsing', () {
        test('parses valid SSE data events', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_start", "message": {}}

data: {"type": "content_block_start", "index": 0}

data: {"type": "message_stop"}

''';
          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: sseBody,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(3));
          expect(events[0]['type'], equals('message_start'));
          expect(events[1]['type'], equals('content_block_start'));
          expect(events[2]['type'], equals('message_stop'));

          handler.dispose();
        });

        test('skips empty lines', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''

data: {"type": "message_stop"}


''';
          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: sseBody,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('message_stop'));

          handler.dispose();
        });

        test('skips [DONE] marker', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_stop"}

data: [DONE]
''';
          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: sseBody,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('message_stop'));

          handler.dispose();
        });

        test('handles malformed JSON with error event', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
data: {"type": "message_start"}

data: {invalid json}

data: {"type": "message_stop"}

''';
          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: sseBody,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(3));
          expect(events[0]['type'], equals('message_start'));
          expect(events[1]['type'], equals('error'));
          final errorData = events[1]['error'] as Map<String, dynamic>;
          expect(errorData['message'], contains('Failed to parse'));
          expect(events[2]['type'], equals('message_stop'));

          handler.dispose();
        });

        test('ignores non-data lines', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
          );

          const sseBody = '''
event: message
data: {"type": "message_stop"}

: comment line
''';
          final mockResponse = _createMockStreamedResponse(
            statusCode: 200,
            body: sseBody,
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('message_stop'));

          handler.dispose();
        });
      });

      group('error handling', () {
        test('yields error event for HTTP 400 Bad Request', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: RetryConfig.noRetry,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 400,
            body: '{"error": "Invalid request"}',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['message'], contains('Invalid request'));
          expect(errorData['http_status'], equals(400));

          handler.dispose();
        });

        test('yields error event for HTTP 401 Unauthorized', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: RetryConfig.noRetry,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 401,
            body: 'Unauthorized',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['http_status'], equals(401));

          handler.dispose();
        });

        test('yields error event for HTTP 500 Server Error', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: RetryConfig.noRetry,
          );

          final mockResponse = _createMockStreamedResponse(
            statusCode: 500,
            body: 'Internal Server Error',
          );
          when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['http_status'], equals(500));

          handler.dispose();
        });

        test('yields error event on timeout', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            config: const ProxyConfig(timeout: Duration(milliseconds: 100)),
            client: mockClient,
            retryConfig: RetryConfig.noRetry,
          );

          when(mockClient.send(any)).thenAnswer(
            (_) => Future.delayed(
              const Duration(seconds: 5),
              () => _createMockStreamedResponse(statusCode: 200, body: ''),
            ),
          );

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['message'], contains('timed out'));

          handler.dispose();
        });

        test('yields error event on network exception', () async {
          final handler = ProxyModeHandler(
            endpoint: testEndpoint,
            client: mockClient,
            retryConfig: RetryConfig.noRetry,
          );

          when(mockClient.send(any)).thenThrow(
            Exception('Network error: connection refused'),
          );

          const request = ApiRequest(
            messages: [
              {'role': 'user', 'content': 'Hello'},
            ],
            maxTokens: 1024,
          );

          final events = await handler.createStream(request).toList();

          expect(events, hasLength(1));
          expect(events[0]['type'], equals('error'));
          final errorData = events[0]['error'] as Map<String, dynamic>;
          expect(errorData['message'], contains('Network error'));

          handler.dispose();
        });
      });
    });

    group('dispose', () {
      test('closes owned client', () async {
        // When no client is provided, handler creates and owns one
        // We can't directly test this without reflection, but we can
        // verify no errors are thrown
        final handler = ProxyModeHandler(endpoint: testEndpoint);
        expect(handler.dispose, returnsNormally);
      });

      test('does not close provided client', () async {
        ProxyModeHandler(
          endpoint: testEndpoint,
          client: mockClient,
        ).dispose();

        // Verify close was never called on the mock client
        verifyNever(mockClient.close());
      });
    });
  });
}

/// Helper to create a mock StreamedResponse.
http.StreamedResponse _createMockStreamedResponse({
  required int statusCode,
  required String body,
}) {
  final controller = StreamController<List<int>>()
    ..add(utf8.encode(body))
    ..close();

  return http.StreamedResponse(
    controller.stream,
    statusCode,
  );
}
