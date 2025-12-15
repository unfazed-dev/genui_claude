/// Error edge case tests for AnthropicContentGenerator.
///
/// These tests verify error handling scenarios specific to GenUI integration,
/// ensuring ContentGeneratorError compliance.
///
/// NOTE: Exception propagation from MockApiHandler.stubError() through
/// ClaudeStreamHandler is handled internally by the stream handler.
/// These tests focus on verifiable behaviors and exception type properties.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Error Edge Cases', () {
    group('Mid-Stream Behavior', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('partial content delivered before stream error', () async {
        // Emit BeginRendering then error
        mockHandler.stubStreamError(
          Exception('Mid-stream error'),
          eventsBeforeError: MockEventFactory.beginRenderingResponse(
            surfaceId: 'partial',
          ),
        );

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Should have received BeginRendering before error
        expect(messages, hasLength(1));
        expect(messages[0], isA<BeginRendering>());
      });

      test('text chunks delivered before stream error', () async {
        final partialEvents = [
          {
            'type': 'content_block_start',
            'index': 0,
            'content_block': {'type': 'text'},
          },
          {
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'Partial '},
          },
          {
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'content'},
          },
        ];

        mockHandler.stubStreamError(
          Exception('Stream interrupted'),
          eventsBeforeError: partialEvents,
        );

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Should have received partial content
        expect(textChunks, ['Partial ', 'content']);
      });

      test('isProcessing reset after error', () async {
        mockHandler.stubError(Exception('Test error'));

        expect(generator.isProcessing.value, isFalse);

        await generator.sendRequest(UserMessage.text('fail'));

        // Should be false after completion (even with error)
        expect(generator.isProcessing.value, isFalse);
      });

      test('subsequent request works after error', () async {
        mockHandler.stubError(Exception('First fails'));

        await generator.sendRequest(UserMessage.text('fail'));
        expect(generator.isProcessing.value, isFalse);

        // Second request should work normally
        mockHandler.stubTextResponse('Success');

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('succeed'));

        expect(textChunks, contains('Success'));
      });
    });

    group('Malformed Response Handling', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('handles incomplete response gracefully', () async {
        mockHandler.stubEvents(MockEventFactory.incompleteResponse('Partial'));

        final textChunks = <String>[];
        generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('test'));

        expect(textChunks, ['Partial']);
        expect(generator.isProcessing.value, isFalse);
      });

      test('handles empty response', () async {
        mockHandler.stubEvents(MockEventFactory.emptyResponse());

        final textChunks = <String>[];
        final messages = <A2uiMessage>[];

        generator.textResponseStream.listen(textChunks.add);
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('test'));

        expect(textChunks, isEmpty);
        expect(messages, isEmpty);
        expect(generator.isProcessing.value, isFalse);
      });

      test('unknown tool name does not crash', () async {
        mockHandler.stubEvents(MockEventFactory.unknownToolResponse(
          toolName: 'completely_unknown_tool',
          input: {'random': 'data'},
        ),);

        final messages = <A2uiMessage>[];
        generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('test'));

        expect(messages, isEmpty);
        expect(generator.isProcessing.value, isFalse);
      });
    });

    group('Error Stream Properties', () {
      late MockApiHandler mockHandler;
      late AnthropicContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('error stream is broadcast (supports multiple listeners)', () {
        // Can add multiple listeners without error
        final listener1 = <ContentGeneratorError>[];
        final listener2 = <ContentGeneratorError>[];

        final sub1 = generator.errorStream.listen(listener1.add);
        final sub2 = generator.errorStream.listen(listener2.add);

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });

      test('error stream does not throw on listen', () {
        expect(
          () => generator.errorStream.listen((_) {}),
          returnsNormally,
        );
      });

      test('error stream type is correct', () {
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
      });
    });

    group('ContentGeneratorError Structure', () {
      test('ContentGeneratorError holds error and stackTrace', () {
        final originalError = Exception('Test error');
        final stackTrace = StackTrace.current;

        final error = ContentGeneratorError(originalError, stackTrace);

        expect(error.error, originalError);
        expect(error.stackTrace, stackTrace);
      });

      test('ContentGeneratorError can wrap any object', () {
        const stringError = 'String error';
        final stackTrace = StackTrace.current;

        final error = ContentGeneratorError(stringError, stackTrace);

        expect(error.error, stringError);
      });
    });

    group('AnthropicException Properties', () {
      test('NetworkException properties', () {
        const exception = NetworkException(
          message: 'Connection failed',
          requestId: 'req-123',
        );

        expect(exception.message, 'Connection failed');
        expect(exception.requestId, 'req-123');
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, 'NetworkException');
        expect(exception.statusCode, isNull);
      });

      test('AuthenticationException properties', () {
        const exception = AuthenticationException(
          message: 'Invalid API key',
          statusCode: 401,
          requestId: 'req-123',
        );

        expect(exception.message, 'Invalid API key');
        expect(exception.statusCode, 401);
        expect(exception.isRetryable, isFalse);
        expect(exception.typeName, 'AuthenticationException');
      });

      test('RateLimitException properties', () {
        const exception = RateLimitException(
          message: 'Rate limit exceeded',
          requestId: 'req-123',
          retryAfter: Duration(seconds: 30),
        );

        expect(exception.message, 'Rate limit exceeded');
        expect(exception.statusCode, 429);
        expect(exception.retryAfter, const Duration(seconds: 30));
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, 'RateLimitException');
      });

      test('ServerException properties', () {
        const exception = ServerException(
          message: 'Internal server error',
          statusCode: 500,
          requestId: 'req-123',
        );

        expect(exception.message, 'Internal server error');
        expect(exception.statusCode, 500);
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, 'ServerException');
      });

      test('ValidationException properties', () {
        const exception = ValidationException(
          message: 'Invalid request',
          statusCode: 400,
          requestId: 'req-123',
        );

        expect(exception.message, 'Invalid request');
        expect(exception.statusCode, 400);
        expect(exception.isRetryable, isFalse);
        expect(exception.typeName, 'ValidationException');
      });

      test('TimeoutException properties', () {
        const exception = TimeoutException(
          message: 'Request timed out',
          timeout: Duration(seconds: 60),
          requestId: 'req-123',
        );

        expect(exception.message, 'Request timed out');
        expect(exception.timeout, const Duration(seconds: 60));
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, 'TimeoutException');
      });

      test('StreamException properties', () {
        const exception = StreamException(
          message: 'Stream error occurred',
          requestId: 'req-123',
        );

        expect(exception.message, 'Stream error occurred');
        expect(exception.isRetryable, isFalse);
        expect(exception.typeName, 'StreamException');
      });

      test('CircuitBreakerOpenException properties', () {
        final recoveryTime = DateTime.now().add(const Duration(seconds: 30));
        final exception = CircuitBreakerOpenException(
          message: 'Circuit breaker is open',
          requestId: 'req-123',
          recoveryTime: recoveryTime,
        );

        expect(exception.message, 'Circuit breaker is open');
        expect(exception.recoveryTime, recoveryTime);
        expect(exception.isRetryable, isTrue);
        expect(exception.typeName, 'CircuitBreakerOpenException');
      });
    });

    group('Exception toString', () {
      test('exception toString contains message', () {
        const exception = NetworkException(
          message: 'Connection failed',
          requestId: 'req-123',
        );

        final str = exception.toString();
        expect(str, contains('NetworkException'));
        expect(str, contains('Connection failed'));
        expect(str, contains('req-123'));
      });

      test('exception toString includes status code when present', () {
        const exception = ServerException(
          message: 'Error',
          statusCode: 500,
        );

        final str = exception.toString();
        expect(str, contains('500'));
      });
    });

    group('Exception isRetryable Classification', () {
      test('retryable exceptions', () {
        expect(
          const NetworkException(message: 'm').isRetryable,
          isTrue,
        );
        expect(
          const TimeoutException(
            message: 'm',
            timeout: Duration(seconds: 1),
          ).isRetryable,
          isTrue,
        );
        expect(
          const RateLimitException(message: 'm').isRetryable,
          isTrue,
        );
        expect(
          const ServerException(message: 'm', statusCode: 500).isRetryable,
          isTrue,
        );
        expect(
          const CircuitBreakerOpenException(message: 'm').isRetryable,
          isTrue,
        );
      });

      test('non-retryable exceptions', () {
        expect(
          const AuthenticationException(message: 'm', statusCode: 401)
              .isRetryable,
          isFalse,
        );
        expect(
          const ValidationException(message: 'm', statusCode: 400).isRetryable,
          isFalse,
        );
        expect(
          const StreamException(message: 'm').isRetryable,
          isFalse,
        );
      });
    });

    group('ExceptionFactory', () {
      test('creates AuthenticationException for 401', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 401,
          body: 'Unauthorized',
        );

        expect(exception, isA<AuthenticationException>());
        expect(exception.statusCode, 401);
      });

      test('creates AuthenticationException for 403', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 403,
          body: 'Forbidden',
        );

        expect(exception, isA<AuthenticationException>());
        expect(exception.statusCode, 403);
      });

      test('creates RateLimitException for 429', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 429,
          body: 'Too many requests',
          retryAfter: const Duration(seconds: 30),
        );

        expect(exception, isA<RateLimitException>());
        expect(
          (exception as RateLimitException).retryAfter,
          const Duration(seconds: 30),
        );
      });

      test('creates ValidationException for 400', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 400,
          body: 'Bad request',
        );

        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, 400);
      });

      test('creates ValidationException for 422', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 422,
          body: 'Unprocessable',
        );

        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, 422);
      });

      test('creates ServerException for 500', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 500,
          body: 'Internal error',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 500);
      });

      test('creates ServerException for 502', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 502,
          body: 'Bad gateway',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 502);
      });

      test('creates ServerException for 503', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 503,
          body: 'Service unavailable',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, 503);
      });

      test('creates ValidationException for unknown status codes', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 418,
          body: 'I am a teapot',
        );

        expect(exception, isA<ValidationException>());
      });

      test('parseRetryAfter handles integer seconds', () {
        final duration = ExceptionFactory.parseRetryAfter('30');
        expect(duration, const Duration(seconds: 30));
      });

      test('parseRetryAfter handles null', () {
        final duration = ExceptionFactory.parseRetryAfter(null);
        expect(duration, isNull);
      });

      test('parseRetryAfter handles empty string', () {
        final duration = ExceptionFactory.parseRetryAfter('');
        expect(duration, isNull);
      });

      test('parseRetryAfter handles invalid string', () {
        final duration = ExceptionFactory.parseRetryAfter('invalid');
        expect(duration, isNull);
      });
    });
  });
}
