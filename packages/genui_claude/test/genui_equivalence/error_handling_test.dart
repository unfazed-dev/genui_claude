/// Error handling tests for ClaudeContentGenerator.
///
/// These tests verify that errors are correctly propagated as
/// ContentGeneratorError objects matching GenUI SDK expectations.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('Error Handling', () {
    late MockApiHandler mockHandler;
    late ClaudeContentGenerator generator;

    setUp(() {
      mockHandler = MockApiHandler();
      generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
    });

    tearDown(() {
      generator.dispose();
    });

    group('Exception to ContentGeneratorError Conversion', () {
      test('general Exception emits ContentGeneratorError', () async {
        mockHandler.stubError(Exception('Generic error'));

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first, isA<ContentGeneratorError>());
        expect(errors.first.error.toString(), contains('Generic error'));
      });

      test('NetworkException emits ContentGeneratorError', () async {
        mockHandler.stubError(
          const NetworkException(message: 'Connection refused'),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error, isA<NetworkException>());
      });

      test('AuthenticationException emits ContentGeneratorError', () async {
        mockHandler.stubError(
          const AuthenticationException(
            message: 'Invalid API key',
            statusCode: 401,
          ),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error, isA<AuthenticationException>());
      });

      test('RateLimitException emits ContentGeneratorError', () async {
        mockHandler.stubError(
          const RateLimitException(message: 'Rate limit exceeded'),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error, isA<RateLimitException>());
      });

      test('ServerException emits ContentGeneratorError', () async {
        mockHandler.stubError(
          const ServerException(
            message: 'Internal server error',
            statusCode: 500,
          ),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error, isA<ServerException>());
      });

      test('ValidationException emits ContentGeneratorError', () async {
        mockHandler.stubError(
          const ValidationException(
            message: 'Invalid request',
            statusCode: 400,
          ),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error, isA<ValidationException>());
      });
    });

    group('ContentGeneratorError Properties', () {
      test('error contains the original exception', () async {
        final originalError = Exception('Test error');
        mockHandler.stubError(originalError);

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors.first.error.toString(), contains('Test error'));
      });

      test('stackTrace is captured', () async {
        mockHandler.stubError(Exception('Stack trace test'));

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors.first.stackTrace, isNotNull);
      });
    });

    group('isProcessing State After Error', () {
      test('isProcessing is false after error', () async {
        mockHandler.stubError(Exception('Error during processing'));

        expect(generator.isProcessing.value, isFalse);

        await generator.sendRequest(UserMessage.text('test'));

        // Should be false after error
        expect(generator.isProcessing.value, isFalse);
      });

      test('generator remains usable after error', () async {
        // First request fails
        mockHandler.stubError(Exception('First error'));
        await generator.sendRequest(UserMessage.text('first'));

        // Second request succeeds
        mockHandler.stubTextResponse('Success');

        final textChunks = <String>[];
        final subscription =
            generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('second'));

        await subscription.cancel();

        expect(textChunks, isNotEmpty);
        expect(textChunks.join(), contains('Success'));
      });
    });

    group('Stream Error Events', () {
      test('error events from stream are converted to ContentGeneratorError',
          () async {
        mockHandler.stubEvents(MockEventFactory.errorResponse('Stream error'));

        final errors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(errors.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(errors, hasLength(1));
        expect(errors.first.error.toString(), contains('Stream error'));
      });
    });

    group('Multiple Error Scenarios', () {
      test('consecutive errors are all captured', () async {
        final allErrors = <ContentGeneratorError>[];
        final subscription = generator.errorStream.listen(allErrors.add);

        // First error
        mockHandler.stubError(Exception('Error 1'));
        await generator.sendRequest(UserMessage.text('first'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Second error
        mockHandler.stubError(Exception('Error 2'));
        await generator.sendRequest(UserMessage.text('second'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(allErrors, hasLength(2));
        expect(allErrors[0].error.toString(), contains('Error 1'));
        expect(allErrors[1].error.toString(), contains('Error 2'));
      });
    });

    group('Error Stream Properties', () {
      test('errorStream is a broadcast stream', () {
        final sub1 = generator.errorStream.listen((_) {});
        final sub2 = generator.errorStream.listen((_) {});

        // Should not throw - broadcast streams support multiple listeners
        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });

      test('multiple listeners receive same error', () async {
        mockHandler.stubError(Exception('Shared error'));

        final errors1 = <ContentGeneratorError>[];
        final errors2 = <ContentGeneratorError>[];
        final sub1 = generator.errorStream.listen(errors1.add);
        final sub2 = generator.errorStream.listen(errors2.add);

        await generator.sendRequest(UserMessage.text('test'));

        // Wait for async error emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        expect(errors1, hasLength(1));
        expect(errors2, hasLength(1));
        expect(errors1.first.error.toString(), errors2.first.error.toString());
      });
    });
  });
}
