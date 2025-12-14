import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import 'handler/mock_api_handler.dart';

void main() {
  group('AnthropicContentGenerator', () {
    group('direct mode', () {
      test('creates with required parameters', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
        );

        expect(generator.isDirectMode, isTrue);

        generator.dispose();
      });

      test('creates with custom model and config', () {
        final generator = AnthropicContentGenerator(
          apiKey: 'test-api-key',
          model: 'claude-haiku-3-20240307',
          systemInstruction: 'You are a helpful assistant.',
          config: const AnthropicConfig(maxTokens: 8192),
        );

        expect(generator.systemInstruction, equals('You are a helpful assistant.'));
        expect(generator.isDirectMode, isTrue);

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

        expect(generator.isDirectMode, isFalse);

        generator.dispose();
      });

      test('creates with auth token and config', () {
        final generator = AnthropicContentGenerator.proxy(
          proxyEndpoint: Uri.parse('https://example.com/api/claude'),
          authToken: 'bearer-token',
          proxyConfig: const ProxyConfig(timeout: Duration(seconds: 180)),
        );

        expect(generator.isDirectMode, isFalse);

        generator.dispose();
      });
    });

    group('withHandler factory', () {
      test('creates with custom handler', () {
        final mockHandler = MockApiHandler();
        final generator = AnthropicContentGenerator.withHandler(
          handler: mockHandler,
        );

        expect(generator.isDirectMode, isTrue);

        generator.dispose();
        expect(mockHandler.disposed, isTrue);
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
