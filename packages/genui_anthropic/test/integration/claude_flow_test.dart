/// Integration tests for direct Claude API mode.
///
/// These tests require a valid Anthropic API key and make real API calls.
/// Run with:
/// ```bash
/// flutter test test/integration/claude_flow_test.dart \
///   --dart-define=TEST_ANTHROPIC_API_KEY=your-key
/// ```
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import 'helpers/api_key_config.dart';
import 'helpers/integration_test_utils.dart';

void main() {
  // Note: Don't use TestWidgetsFlutterBinding as it blocks HTTP requests

  group('Direct Mode - Claude Flow Integration Tests', () {
    late AnthropicContentGenerator generator;

    setUpAll(() {
      if (ApiKeyConfig.shouldSkip) return;

      generator = createIntegrationGenerator(
        apiKey: ApiKeyConfig.apiKey!,
        systemInstruction: '''
You are a helpful assistant. When asked to generate UI, describe what UI you would create.
Keep responses concise for testing purposes.
''',
      );
    });

    tearDownAll(() {
      if (!ApiKeyConfig.shouldSkip) {
        generator.dispose();
      }
    });

    test(
      'full Claude to GenUI flow with real API',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // ARRANGE
        final message = UserMessage.text('Say "Hello World" in exactly 2 words');

        // ACT
        final result = await waitForResponse(generator, message);

        // ASSERT
        expect(
          result.timedOut,
          isFalse,
          reason: 'Request should complete within timeout',
        );
        expect(result.hasErrors, isFalse, reason: 'Should not have errors');
        expect(
          result.hasTextResponse,
          isTrue,
          reason: 'Should receive text response from Claude',
        );
        expect(
          result.fullText.toLowerCase(),
          contains('hello'),
          reason: 'Response should contain greeting',
        );
      },
      timeout: const Timeout(claudeResponseTimeout),
    );

    test(
      'tool selection and execution',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // ARRANGE
        final message = UserMessage.text(
          'What is 15 + 27? Just give me the number.',
        );

        // ACT
        final result = await waitForResponse(generator, message);

        // ASSERT
        expect(result.timedOut, isFalse);
        expect(result.hasErrors, isFalse);
        expect(result.hasTextResponse, isTrue);
        expect(
          result.fullText,
          contains('42'),
          reason: 'Claude should calculate 15+27=42',
        );
      },
      timeout: const Timeout(claudeResponseTimeout),
    );

    test(
      'streaming UI rendering',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // ARRANGE
        final message = UserMessage.text(
          'Count from 1 to 5, each number on its own.',
        );

        // Track streaming chunks
        final receivedChunks = <String>[];
        final subscription = generator.textResponseStream.listen(
          receivedChunks.add,
        );

        // ACT
        await generator.sendRequest(message);
        await waitForProcessingComplete(generator);

        await subscription.cancel();

        // ASSERT
        expect(
          receivedChunks,
          isNotEmpty,
          reason: 'Should receive streaming chunks',
        );
        expect(
          receivedChunks.length,
          greaterThan(1),
          reason: 'Should receive multiple streaming chunks (got ${receivedChunks.length})',
        );

        final fullText = receivedChunks.join();
        expect(fullText, contains('1'));
        expect(fullText, contains('5'));
      },
      timeout: const Timeout(claudeResponseTimeout),
    );

    test(
      'conversation continuity',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // ARRANGE - First message
        final firstMessage = UserMessage.text(
          'Remember this code: ALPHA-7749. Just acknowledge.',
        );
        final firstResult = await waitForResponse(generator, firstMessage);

        expect(firstResult.timedOut, isFalse);
        expect(firstResult.hasErrors, isFalse);

        // Build history
        final history = <ChatMessage>[
          firstMessage,
          AiTextMessage.text(firstResult.fullText),
        ];

        // Second message referencing the first
        final secondMessage = UserMessage.text(
          'What was the code I asked you to remember?',
        );

        // ACT
        final secondResult = await waitForResponse(
          generator,
          secondMessage,
          history: history,
        );

        // ASSERT
        expect(secondResult.timedOut, isFalse);
        expect(secondResult.hasErrors, isFalse);
        expect(
          secondResult.fullText.toUpperCase(),
          contains('ALPHA'),
          reason: 'Claude should remember the code from history',
        );
        expect(
          secondResult.fullText,
          contains('7749'),
          reason: 'Claude should remember the full code',
        );
      },
      timeout: const Timeout(extendedTimeout),
    );

    test(
      'error recovery',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // Create generator with invalid API key to trigger error
        final badGenerator = AnthropicContentGenerator(
          apiKey: 'invalid-api-key-12345',
          config: const AnthropicConfig(maxTokens: 100),
        );

        final errors = <ContentGeneratorError>[];
        final subscription = badGenerator.errorStream.listen(errors.add);

        try {
          // ACT - This should fail with auth error
          await badGenerator.sendRequest(UserMessage.text('Hello'));
          await waitForProcessingComplete(
            badGenerator,
            timeout: const Duration(seconds: 15),
          );

          // ASSERT - Generator should recover and not be stuck in processing state
          expect(
            badGenerator.isProcessing.value,
            isFalse,
            reason: 'Generator should not be stuck in processing state',
          );
        } finally {
          await subscription.cancel();
          badGenerator.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'multiple sequential messages',
      skip: ApiKeyConfig.shouldSkip ? ApiKeyConfig.skipMessage : null,
      () async {
        // ARRANGE
        final questions = [
          ('What is 10 + 10?', '20'),
          ('What is 25 + 25?', '50'),
          ('What is 100 - 1?', '99'),
        ];

        final responses = <String>[];

        // ACT - Send messages sequentially
        for (final (question, _) in questions) {
          final result = await waitForResponse(
            generator,
            UserMessage.text('$question Answer with just the number.'),
          );

          expect(result.timedOut, isFalse);
          expect(result.hasErrors, isFalse);
          responses.add(result.fullText);
        }

        // ASSERT
        expect(responses, hasLength(3));
        expect(responses[0], contains(questions[0].$2));
        expect(responses[1], contains(questions[1].$2));
        expect(responses[2], contains(questions[2].$2));
      },
      timeout: const Timeout(Duration(seconds: 180)), // 3 API calls
    );
  });
}
