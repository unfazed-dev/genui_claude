import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

void main() {
  group('AnthropicContentGenerator', () {
    group('direct mode', () {
      test('creates with required parameters', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
        );

        expect(generator.apiKey, equals('test-api-key'));
        expect(generator.model, equals('claude-sonnet-4-20250514'));
        expect(generator.isDirectMode, isTrue);
        expect(generator.config, equals(AnthropicConfig.defaults));

        generator.dispose();
      });

      test('creates with custom model and config', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
          model: 'claude-haiku-3-20240307',
          systemInstruction: 'You are a helpful assistant.',
          config: const AnthropicConfig(maxTokens: 8192),
        );

        expect(generator.model, equals('claude-haiku-3-20240307'));
        expect(generator.systemInstruction, equals('You are a helpful assistant.'));
        expect(generator.config?.maxTokens, equals(8192));

        generator.dispose();
      });

      test('implements ContentGenerator interface', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
        );

        expect(generator, isA<ContentGenerator>());
        expect(generator.a2uiMessageStream, isA<Stream<A2uiMessage>>());
        expect(generator.textResponseStream, isA<Stream<String>>());
        expect(generator.errorStream, isA<Stream<ContentGeneratorError>>());
        expect(generator.isProcessing, isA<ValueListenable<bool>>());

        generator.dispose();
      });

      test('isProcessing starts as false', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
        );

        expect(generator.isProcessing.value, isFalse);

        generator.dispose();
      });
    });

    group('proxy mode', () {
      test('creates with required parameters', () {
        final generator = AnthropicContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://example.com/api/claude'),
        );

        expect(generator.proxyEndpoint?.toString(), equals('https://example.com/api/claude'));
        expect(generator.isDirectMode, isFalse);
        expect(generator.apiKey, isNull);
        expect(generator.proxyConfig, equals(ProxyConfig.defaults));

        generator.dispose();
      });

      test('creates with auth token and config', () {
        final generator = AnthropicContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://example.com/api/claude'),
          authToken: 'bearer-token',
          proxyConfig: const ProxyConfig(timeout: Duration(seconds: 180)),
        );

        expect(generator.authToken, equals('bearer-token'));
        expect(generator.proxyConfig?.timeout, equals(const Duration(seconds: 180)));

        generator.dispose();
      });
    });
  });

  group('AnthropicConfig', () {
    test('has default values', () {
      const config = AnthropicConfig.defaults;

      expect(config.maxTokens, equals(4096));
      expect(config.timeout, equals(const Duration(seconds: 60)));
      expect(config.retryAttempts, equals(3));
      expect(config.enableStreaming, isTrue);
      expect(config.headers, isNull);
    });

    test('copyWith creates modified copy', () {
      const original = AnthropicConfig.defaults;
      final modified = original.copyWith(maxTokens: 8192);

      expect(modified.maxTokens, equals(8192));
      expect(original.maxTokens, equals(4096));
    });
  });

  group('ProxyConfig', () {
    test('has default values', () {
      const config = ProxyConfig.defaults;

      expect(config.timeout, equals(const Duration(seconds: 120)));
      expect(config.retryAttempts, equals(3));
      expect(config.includeHistory, isTrue);
      expect(config.maxHistoryMessages, equals(20));
    });

    test('copyWith creates modified copy', () {
      const original = ProxyConfig.defaults;
      final modified = original.copyWith(
        includeHistory: false,
        maxHistoryMessages: 10,
      );

      expect(modified.includeHistory, isFalse);
      expect(modified.maxHistoryMessages, equals(10));
      expect(original.includeHistory, isTrue);
    });
  });
}
