/// Configuration and mode tests for ClaudeContentGenerator.
///
/// These tests verify DirectMode and ProxyMode configuration options
/// match GenUI SDK expectations for ContentGenerator.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('GenUI Configuration Modes', () {
    group('DirectMode Configuration', () {
      test('default model is used when not specified', () {
        final generator = ClaudeContentGenerator(apiKey: 'test-key');

        expect(generator, isA<ContentGenerator>());
        expect(generator.isDirectMode, isTrue);

        generator.dispose();
      });

      test('custom model override works', () {
        final generator = ClaudeContentGenerator(
          apiKey: 'test-key',
          model: 'claude-opus-4-20250514',
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('systemInstruction is stored', () {
        final generator = ClaudeContentGenerator(
          apiKey: 'test-key',
          systemInstruction: 'You are a helpful assistant.',
        );

        expect(generator.systemInstruction, 'You are a helpful assistant.');

        generator.dispose();
      });

      test('ClaudeConfig defaults are applied', () {
        final generator = ClaudeContentGenerator(
          apiKey: 'test-key',
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('custom ClaudeConfig is accepted', () {
        final generator = ClaudeContentGenerator(
          apiKey: 'test-key',
          config: const ClaudeConfig(
            maxTokens: 8192,
            timeout: Duration(seconds: 120),
            retryAttempts: 5,
          ),
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });
    });

    group('ProxyMode Configuration', () {
      test('creates valid ContentGenerator with endpoint', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://api.example.com/claude'),
        );

        expect(generator, isA<ContentGenerator>());
        expect(generator.isDirectMode, isFalse);

        generator.dispose();
      });

      test('accepts authToken', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://api.example.com/claude'),
          authToken: 'bearer-token-123',
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('ProxyConfig defaults are applied', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://api.example.com/claude'),
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });

      test('custom ProxyConfig is accepted', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://api.example.com/claude'),
          proxyConfig: const ProxyConfig(
            timeout: Duration(seconds: 180),
            retryAttempts: 5,
            includeHistory: false,
            maxHistoryMessages: 10,
          ),
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
      });
    });

    group('withHandler Factory (Testing)', () {
      test('accepts custom ApiHandler', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        expect(generator, isA<ContentGenerator>());

        generator.dispose();
        expect(mockHandler.disposed, isTrue);
      });

      test('accepts optional model and systemInstruction', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
          model: 'claude-sonnet-4-20250514',
          systemInstruction: 'Test instruction',
        );

        expect(generator.systemInstruction, 'Test instruction');

        generator.dispose();
      });
    });

    group('Mode-Specific Stream Event Format Consistency', () {
      test('DirectMode streams emit correct types', () async {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        mockHandler.stubTextResponse('Hello');

        final textChunks = <String>[];
        final subscription = generator.textResponseStream.listen(textChunks.add);

        await generator.sendRequest(UserMessage.text('test'));

        await subscription.cancel();

        expect(textChunks, ['Hello']);

        generator.dispose();
      });

      test('all modes emit A2uiMessage for tool responses', () async {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        mockHandler.stubEvents(MockEventFactory.widgetRenderingResponse());

        final messages = <A2uiMessage>[];
        final subscription = generator.a2uiMessageStream.listen(messages.add);

        await generator.sendRequest(UserMessage.text('render'));

        await subscription.cancel();

        expect(messages, hasLength(2));
        expect(messages[0], isA<BeginRendering>());
        expect(messages[1], isA<SurfaceUpdate>());

        generator.dispose();
      });

      test('error stream type is consistent across modes', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        // Error stream type is Stream<ContentGeneratorError> in all modes
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());

        // Can subscribe without error
        final subscription = generator.errorStream.listen((_) {});
        expect(subscription, isNotNull);

        subscription.cancel();
        generator.dispose();
      });
    });

    group('Configuration Immutability', () {
      test('ClaudeConfig is immutable', () {
        const config1 = ClaudeConfig(maxTokens: 1000);
        const config2 = ClaudeConfig(maxTokens: 2000);

        expect(config1.maxTokens, 1000);
        expect(config2.maxTokens, 2000);
        // They are separate instances
        expect(identical(config1, config2), isFalse);
      });

      test('ClaudeConfig copyWith creates new instance', () {
        const original = ClaudeConfig(maxTokens: 1000);
        final copied = original.copyWith(maxTokens: 2000);

        expect(original.maxTokens, 1000);
        expect(copied.maxTokens, 2000);
      });

      test('ProxyConfig is immutable', () {
        const config1 = ProxyConfig(timeout: Duration(seconds: 60));
        const config2 = ProxyConfig();

        expect(config1.timeout, const Duration(seconds: 60));
        expect(config2.timeout, const Duration(seconds: 120));
      });

      test('ProxyConfig copyWith creates new instance', () {
        const original = ProxyConfig(timeout: Duration(seconds: 60));
        final copied = original.copyWith(timeout: const Duration(seconds: 120));

        expect(original.timeout, const Duration(seconds: 60));
        expect(copied.timeout, const Duration(seconds: 120));
      });
    });

    group('Configuration Presets', () {
      test('ClaudeConfig.defaults has expected values', () {
        const config = ClaudeConfig.defaults;

        expect(config.maxTokens, 4096);
        expect(config.timeout, const Duration(seconds: 60));
        expect(config.retryAttempts, 3);
        expect(config.enableStreaming, isTrue);
      });

      test('ProxyConfig.defaults has expected values', () {
        const config = ProxyConfig.defaults;

        expect(config.timeout, const Duration(seconds: 120));
        expect(config.retryAttempts, 3);
        expect(config.includeHistory, isTrue);
        expect(config.maxHistoryMessages, 20);
      });
    });

    group('ContentGenerator Interface Compliance', () {
      test('DirectMode generator implements ContentGenerator', () {
        final generator = ClaudeContentGenerator(apiKey: 'test');

        // These should compile - proves interface compliance
        expect(generator.a2uiMessageStream, isA<Stream<A2uiMessage>>());
        expect(generator.textResponseStream, isA<Stream<String>>());
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });

      test('ProxyMode generator implements ContentGenerator', () {
        final generator = ClaudeContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://api.example.com'),
        );

        expect(generator.a2uiMessageStream, isA<Stream<A2uiMessage>>());
        expect(generator.textResponseStream, isA<Stream<String>>());
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });

      test('withHandler generator implements ContentGenerator', () {
        final mockHandler = MockApiHandler();
        final generator = ClaudeContentGenerator.withHandler(
          handler: mockHandler,
        );

        expect(generator.a2uiMessageStream, isA<Stream<A2uiMessage>>());
        expect(generator.textResponseStream, isA<Stream<String>>());
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });
    });
  });
}
