/// Integration tests for proxy mode.
///
/// These tests use a mock HTTP server to simulate a backend proxy,
/// allowing testing of proxy mode without requiring a real backend.
///
/// Run with:
/// ```bash
/// dart test test/integration/proxy_flow_test.dart
/// ```
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import 'helpers/integration_test_utils.dart';
import 'helpers/mock_proxy_server.dart';

void main() {
  // Note: Don't use TestWidgetsFlutterBinding as it blocks HTTP requests

  group('Proxy Mode Integration Tests', () {
    late MockProxyServer mockServer;
    late Uri proxyEndpoint;

    setUpAll(() async {
      mockServer = MockProxyServer();
      proxyEndpoint = await mockServer.start();
    });

    tearDownAll(() async {
      await mockServer.stop();
    });

    setUp(() {
      mockServer
        ..clearResponses()
        ..clearRecordedRequests();
    });

    test('proxy mode with test endpoint', () async {
      // ARRANGE
      mockServer.stubResponse(
        MockProxyResponse.textResponse('Hello from proxy server!'),
      );

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
      );

      // ACT
      final result = await waitForResponse(
        generator,
        UserMessage.text('Hello'),
        timeout: const Duration(seconds: 10),
      );

      // ASSERT
      expect(result.timedOut, isFalse, reason: 'Request should complete');
      expect(result.hasErrors, isFalse, reason: 'Should not have errors');
      expect(
        result.fullText,
        equals('Hello from proxy server!'),
        reason: 'Should receive response from mock server',
      );

      // Verify request was made correctly
      expect(mockServer.recordedRequests, hasLength(1));
      final request = mockServer.lastRequest!;
      expect(request.method, equals('POST'));
      expect(request.messages, isNotEmpty);

      generator.dispose();
    });

    test('auth token handling', () async {
      // ARRANGE
      const authToken = 'test-bearer-token-12345';

      mockServer.stubResponse(
        MockProxyResponse(
          sseEvents: _createTextResponseEvents('Authenticated response'),
          requiresAuth: true,
        ),
      );

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
        authToken: authToken,
      );

      // ACT
      final result = await waitForResponse(
        generator,
        UserMessage.text('Test with auth'),
        timeout: const Duration(seconds: 10),
      );

      // ASSERT
      expect(result.timedOut, isFalse);
      expect(result.hasErrors, isFalse);
      expect(result.fullText, contains('Authenticated'));

      // Verify auth token was sent
      expect(mockServer.lastRequest, isNotNull);
      expect(
        mockServer.lastRequest!.authToken,
        equals(authToken),
        reason: 'Auth token should be sent in request',
      );

      // Verify Authorization header was present
      expect(
        mockServer.lastRequest!.headers['authorization'],
        contains('Bearer $authToken'),
      );

      generator.dispose();
    });

    test('history pruning', () async {
      // ARRANGE
      mockServer.stubResponse(
        MockProxyResponse.textResponse('Response with history'),
      );

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
        proxyConfig: const ProxyConfig(
          maxHistoryMessages: 5,
        ),
      );

      // Create history larger than max
      final largeHistory = List<ChatMessage>.generate(
        10,
        (i) => i.isEven
            ? UserMessage.text('User message $i')
            : AiTextMessage.text('Assistant response $i'),
      );

      // ACT
      final result = await waitForResponse(
        generator,
        UserMessage.text('Final message with large history'),
        history: largeHistory,
        timeout: const Duration(seconds: 10),
      );

      // ASSERT
      expect(result.timedOut, isFalse);
      expect(result.hasErrors, isFalse);
      expect(result.hasTextResponse, isTrue);

      // Verify request was recorded
      expect(mockServer.lastRequest, isNotNull);
      expect(
        mockServer.lastRequest!.messages,
        isNotEmpty,
        reason: 'Messages should be included in request',
      );

      generator.dispose();
    });

    test('handles server errors gracefully', () async {
      // ARRANGE
      mockServer.stubResponse(MockProxyResponse.error());

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
      );

      final errors = <ContentGeneratorError>[];
      final subscription = generator.errorStream.listen(errors.add);

      // ACT
      final result = await waitForResponse(
        generator,
        UserMessage.text('Trigger error'),
        timeout: const Duration(seconds: 10),
      );

      await subscription.cancel();

      // ASSERT
      expect(result.timedOut, isFalse);
      // Should have received an error
      expect(
        result.hasErrors || errors.isNotEmpty,
        isTrue,
        reason: 'Should receive error for 500 response',
      );

      generator.dispose();
    });

    test('handles unauthorized errors', () async {
      // ARRANGE - Server requires auth but we don't send it
      mockServer.stubResponse(MockProxyResponse.unauthorized());

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
        // No auth token
      );

      final errors = <ContentGeneratorError>[];
      final subscription = generator.errorStream.listen(errors.add);

      // ACT
      final result = await waitForResponse(
        generator,
        UserMessage.text('Unauthorized request'),
        timeout: const Duration(seconds: 10),
      );

      await subscription.cancel();

      // ASSERT
      expect(result.timedOut, isFalse);
      expect(
        result.hasErrors || errors.isNotEmpty,
        isTrue,
        reason: 'Should receive 401 unauthorized error',
      );

      generator.dispose();
    });

    test('streams multiple text chunks', () async {
      // ARRANGE - Response with multiple delta events
      mockServer.stubResponse(
        MockProxyResponse(
          sseEvents: [
            {
              'type': 'message_start',
              'message': {
                'id': 'msg_test',
                'type': 'message',
                'role': 'assistant',
                'content': <dynamic>[],
                'model': 'claude-mock',
                'stop_reason': null,
                'stop_sequence': null,
                'usage': {'input_tokens': 10, 'output_tokens': 10},
              },
            },
            {
              'type': 'content_block_start',
              'index': 0,
              'content_block': {'type': 'text', 'text': ''},
            },
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'First '},
            },
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'Second '},
            },
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'Third'},
            },
            {'type': 'content_block_stop', 'index': 0},
            {
              'type': 'message_delta',
              'delta': {'stop_reason': 'end_turn', 'stop_sequence': null},
              'usage': {'output_tokens': 10},
            },
            {'type': 'message_stop'},
          ],
        ),
      );

      final generator = ClaudeContentGenerator.proxy(
        proxyEndpoint: proxyEndpoint,
      );

      // Track streaming chunks
      final receivedChunks = <String>[];
      final subscription = generator.textResponseStream.listen(
        receivedChunks.add,
      );

      // ACT
      await generator.sendRequest(UserMessage.text('Stream test'));
      await waitForProcessingComplete(
        generator,
        timeout: const Duration(seconds: 10),
      );

      await subscription.cancel();

      // ASSERT
      expect(
        receivedChunks.length,
        greaterThanOrEqualTo(3),
        reason: 'Should receive multiple streaming chunks',
      );
      expect(receivedChunks.join(), equals('First Second Third'));

      generator.dispose();
    });
  });
}

/// Creates SSE events for a simple text response.
List<Map<String, dynamic>> _createTextResponseEvents(String text) {
  return [
    {
      'type': 'message_start',
      'message': {
        'id': 'msg_test',
        'type': 'message',
        'role': 'assistant',
        'content': <dynamic>[],
        'model': 'claude-mock',
        'stop_reason': null,
        'stop_sequence': null,
        'usage': {'input_tokens': 10, 'output_tokens': 10},
      },
    },
    {
      'type': 'content_block_start',
      'index': 0,
      'content_block': {'type': 'text', 'text': ''},
    },
    {
      'type': 'content_block_delta',
      'index': 0,
      'delta': {'type': 'text_delta', 'text': text},
    },
    {'type': 'content_block_stop', 'index': 0},
    {
      'type': 'message_delta',
      'delta': {'stop_reason': 'end_turn', 'stop_sequence': null},
      'usage': {'output_tokens': 10},
    },
    {'type': 'message_stop'},
  ];
}
