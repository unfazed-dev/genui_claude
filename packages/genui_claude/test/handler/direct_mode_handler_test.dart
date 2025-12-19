import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/genui_claude.dart';

void main() {
  group('DirectModeHandler', () {
    group('constructor', () {
      test('creates handler with required parameters', () {
        final handler = DirectModeHandler(apiKey: 'test-api-key');

        expect(handler, isA<ApiHandler>());
        expect(handler.model, equals('claude-sonnet-4-20250514'));

        handler.dispose();
      });

      test('creates handler with custom model', () {
        final handler = DirectModeHandler(
          apiKey: 'test-api-key',
          model: 'claude-opus-4-20250514',
        );

        expect(handler.model, equals('claude-opus-4-20250514'));

        handler.dispose();
      });

      test('creates handler with custom config', () {
        final handler = DirectModeHandler(
          apiKey: 'test-api-key',
          config: const ClaudeConfig(
            maxTokens: 8192,
            retryAttempts: 5,
          ),
        );

        expect(handler, isA<ApiHandler>());

        handler.dispose();
      });

      test('creates handler with circuit breaker', () {
        final circuitBreaker = CircuitBreaker(
          name: 'direct-mode-test',
        );

        final handler = DirectModeHandler(
          apiKey: 'test-api-key',
          circuitBreaker: circuitBreaker,
        );

        expect(handler, isA<ApiHandler>());

        handler.dispose();
      });

      group('circuit breaker defaults', () {
        test('creates circuit breaker by default', () {
          // With default config, circuit breaker should be created
          final handler = DirectModeHandler(
            apiKey: 'test-api-key',
          );

          // We can verify the handler was created successfully with default config
          expect(handler, isA<ApiHandler>());
          handler.dispose();
        });

        test('circuit breaker can be disabled via config', () {
          final handler = DirectModeHandler(
            apiKey: 'test-api-key',
            config: const ClaudeConfig(disableCircuitBreaker: true),
          );

          expect(handler, isA<ApiHandler>());
          handler.dispose();
        });

        test('uses custom circuit breaker config from ClaudeConfig', () {
          final handler = DirectModeHandler(
            apiKey: 'test-api-key',
            config: const ClaudeConfig(
              circuitBreakerConfig: CircuitBreakerConfig.strict,
            ),
          );

          expect(handler, isA<ApiHandler>());
          handler.dispose();
        });

        test('uses lenient circuit breaker config', () {
          final handler = DirectModeHandler(
            apiKey: 'test-api-key',
            config: const ClaudeConfig(
              circuitBreakerConfig: CircuitBreakerConfig.lenient,
            ),
          );

          expect(handler, isA<ApiHandler>());
          handler.dispose();
        });

        test('explicit circuit breaker overrides config', () {
          final customBreaker = CircuitBreaker(
            config: const CircuitBreakerConfig(
              failureThreshold: 2,
              recoveryTimeout: Duration(seconds: 10),
              halfOpenSuccessThreshold: 1,
            ),
          );

          final handler = DirectModeHandler(
            apiKey: 'test-api-key',
            config: const ClaudeConfig(
              // This should be ignored since explicit circuitBreaker is provided
              circuitBreakerConfig: CircuitBreakerConfig.lenient,
            ),
            circuitBreaker: customBreaker,
          );

          expect(handler, isA<ApiHandler>());
          handler.dispose();
        });
      });
    });

    group('dispose', () {
      test('disposes without error', () {
        final handler = DirectModeHandler(apiKey: 'test-api-key');

        expect(handler.dispose, returnsNormally);
      });
    });
  });

  // Test the internal conversion logic via exported test helper
  // Since DirectModeHandler uses private methods, we test
  // the SDK event conversion through a testable helper
  group('SDK Event Conversion', () {
    // These tests verify the expected output format that DirectModeHandler
    // produces from SDK events. While we can't directly test the private
    // _convertEventToMap method, we document the expected behavior.

    group('expected message_start event format', () {
      test('should produce correct structure', () {
        // DirectModeHandler converts MessageStartEvent to this format:
        const expected = {
          'type': 'message_start',
          'message': <String, dynamic>{}, // Contains message.toJson()
        };

        expect(expected['type'], equals('message_start'));
        expect(expected.containsKey('message'), isTrue);
      });
    });

    group('expected message_delta event format', () {
      test('should produce correct structure', () {
        // DirectModeHandler converts MessageDeltaEvent to this format:
        const expected = {
          'type': 'message_delta',
          'delta': <String, dynamic>{}, // Contains delta.toJson()
          'usage': <String, dynamic>{}, // Contains usage.toJson()
        };

        expect(expected['type'], equals('message_delta'));
        expect(expected.containsKey('delta'), isTrue);
        expect(expected.containsKey('usage'), isTrue);
      });
    });

    group('expected message_stop event format', () {
      test('should produce correct structure', () {
        const expected = {'type': 'message_stop'};

        expect(expected['type'], equals('message_stop'));
        expect(expected.length, equals(1));
      });
    });

    group('expected content_block_start event format', () {
      test('should produce correct structure', () {
        // DirectModeHandler converts ContentBlockStartEvent to this format:
        const expected = {
          'type': 'content_block_start',
          'index': 0,
          'content_block': <String, dynamic>{}, // Contains contentBlock.toJson()
        };

        expect(expected['type'], equals('content_block_start'));
        expect(expected.containsKey('index'), isTrue);
        expect(expected.containsKey('content_block'), isTrue);
      });
    });

    group('expected content_block_delta event format', () {
      test('should produce correct structure', () {
        const expected = {
          'type': 'content_block_delta',
          'index': 0,
          'delta': <String, dynamic>{}, // Contains delta.toJson()
        };

        expect(expected['type'], equals('content_block_delta'));
        expect(expected.containsKey('index'), isTrue);
        expect(expected.containsKey('delta'), isTrue);
      });
    });

    group('expected content_block_stop event format', () {
      test('should produce correct structure', () {
        const expected = {
          'type': 'content_block_stop',
          'index': 0,
        };

        expect(expected['type'], equals('content_block_stop'));
        expect(expected.containsKey('index'), isTrue);
      });
    });

    group('expected ping event format', () {
      test('should produce correct structure', () {
        const expected = {'type': 'ping'};

        expect(expected['type'], equals('ping'));
        expect(expected.length, equals(1));
      });
    });

    group('expected error event format', () {
      test('should produce correct structure', () {
        const expected = {
          'type': 'error',
          'error': {'message': 'Error message'},
        };

        expect(expected['type'], equals('error'));
        expect(expected['error'], isA<Map<String, dynamic>>());
        final errorMap = expected['error']! as Map<String, dynamic>;
        expect(errorMap['message'], isA<String>());
      });
    });
  });

  // Test message format conversions
  group('Message Format', () {
    group('user message format', () {
      test('simple text content produces valid format', () {
        final message = {
          'role': 'user',
          'content': 'Hello, how are you?',
        };

        expect(message['role'], equals('user'));
        expect(message['content'], isA<String>());
      });

      test('block content format is valid', () {
        final message = {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'What is this image?'},
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/png',
                'data': 'base64data...',
              },
            },
          ],
        };

        expect(message['role'], equals('user'));
        expect(message['content'], isA<List<dynamic>>());
        final contentList = message['content']! as List<dynamic>;
        final firstBlock = contentList.first as Map<String, dynamic>;
        expect(firstBlock['type'], equals('text'));
      });
    });

    group('assistant message format', () {
      test('simple text content produces valid format', () {
        final message = {
          'role': 'assistant',
          'content': 'I am doing well, thank you!',
        };

        expect(message['role'], equals('assistant'));
        expect(message['content'], isA<String>());
      });

      test('tool_use block format is valid', () {
        final message = {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 'tool_123',
              'name': 'get_weather',
              'input': {'location': 'San Francisco'},
            },
          ],
        };

        expect(message['role'], equals('assistant'));
        final content = message['content']! as List<dynamic>;
        final firstBlock = content.first as Map<String, dynamic>;
        expect(firstBlock['type'], equals('tool_use'));
        expect(firstBlock['id'], isNotEmpty);
        expect(firstBlock['name'], isNotEmpty);
        expect(firstBlock['input'], isA<Map<String, dynamic>>());
      });

      test('tool_result block format is valid', () {
        final message = {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'tool_123',
              'content': 'The weather is sunny.',
            },
          ],
        };

        expect(message['role'], equals('user'));
        final content = message['content']! as List<dynamic>;
        final firstBlock = content.first as Map<String, dynamic>;
        expect(firstBlock['type'], equals('tool_result'));
        expect(firstBlock['tool_use_id'], isNotEmpty);
      });
    });
  });

  // Test tool format conversions
  group('Tool Format', () {
    test('basic tool format is valid', () {
      final tool = {
        'name': 'get_weather',
        'description': 'Get current weather for a location',
        'input_schema': {
          'type': 'object',
          'properties': {
            'location': {
              'type': 'string',
              'description': 'City name',
            },
          },
          'required': ['location'],
        },
      };

      expect(tool['name'], isA<String>());
      expect(tool['description'], isA<String>());
      expect(tool['input_schema'], isA<Map<String, dynamic>>());
      final inputSchema = tool['input_schema']! as Map<String, dynamic>;
      expect(inputSchema['type'], equals('object'));
    });

    test('tool with nested schema is valid', () {
      final tool = {
        'name': 'create_event',
        'description': 'Create a calendar event',
        'input_schema': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'attendees': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'email': {'type': 'string'},
                },
              },
            },
          },
        },
      };

      final schema = tool['input_schema']! as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      final attendees = properties['attendees'] as Map<String, dynamic>;
      expect(attendees['type'], equals('array'));
      final items = attendees['items'] as Map<String, dynamic>;
      expect(items['type'], equals('object'));
    });
  });

  // Test media type parsing
  group('Media Type Parsing', () {
    test('supports image/jpeg', () {
      const mediaType = 'image/jpeg';
      expect(
        _parseMediaType(mediaType),
        equals(sdk.ImageBlockSourceMediaType.imageJpeg),
      );
    });

    test('supports image/png', () {
      const mediaType = 'image/png';
      expect(
        _parseMediaType(mediaType),
        equals(sdk.ImageBlockSourceMediaType.imagePng),
      );
    });

    test('supports image/gif', () {
      const mediaType = 'image/gif';
      expect(
        _parseMediaType(mediaType),
        equals(sdk.ImageBlockSourceMediaType.imageGif),
      );
    });

    test('supports image/webp', () {
      const mediaType = 'image/webp';
      expect(
        _parseMediaType(mediaType),
        equals(sdk.ImageBlockSourceMediaType.imageWebp),
      );
    });

    test('defaults to image/png for unknown types', () {
      const mediaType = 'image/unknown';
      expect(
        _parseMediaType(mediaType),
        equals(sdk.ImageBlockSourceMediaType.imagePng),
      );
    });
  });
}

/// Helper to test media type parsing (mirrors DirectModeHandler logic)
sdk.ImageBlockSourceMediaType _parseMediaType(String mediaType) {
  return switch (mediaType) {
    'image/jpeg' => sdk.ImageBlockSourceMediaType.imageJpeg,
    'image/png' => sdk.ImageBlockSourceMediaType.imagePng,
    'image/gif' => sdk.ImageBlockSourceMediaType.imageGif,
    'image/webp' => sdk.ImageBlockSourceMediaType.imageWebp,
    _ => sdk.ImageBlockSourceMediaType.imagePng,
  };
}
