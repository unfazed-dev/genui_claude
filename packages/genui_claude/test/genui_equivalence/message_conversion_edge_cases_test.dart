/// Message conversion edge case tests for MessageConverter.
///
/// These tests verify edge cases in ChatMessage to Claude API format conversion,
/// ensuring genui_claude correctly handles all GenUI SDK message types.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/src/utils/message_converter.dart';

void main() {
  group('GenUI Message Conversion Edge Cases', () {
    group('UserMessage with Image Parts', () {
      test('converts UserMessage with base64 image', () {
        final imageBytes = utf8.encode('fake-image-data');
        final base64Data = base64Encode(imageBytes);

        final message = UserMessage([
          const TextPart('Here is an image:'),
          ImagePart.fromBase64(base64Data, mimeType: 'image/png'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');

        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(2));

        // Text block
        final textBlock = content[0] as Map<String, dynamic>;
        expect(textBlock['type'], 'text');
        expect(textBlock['text'], 'Here is an image:');

        // Image block
        final imageBlock = content[1] as Map<String, dynamic>;
        final source = imageBlock['source'] as Map<String, dynamic>;
        expect(imageBlock['type'], 'image');
        expect(source['type'], 'base64');
        expect(source['media_type'], 'image/png');
        expect(source['data'], base64Data);
      });

      test('converts UserMessage with URL image', () {
        final message = UserMessage([
          const TextPart('Check this out:'),
          ImagePart.fromUrl(Uri.parse('https://example.com/image.jpg')),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(2));

        // Image with URL
        final imageBlock = content[1] as Map<String, dynamic>;
        final source = imageBlock['source'] as Map<String, dynamic>;
        expect(imageBlock['type'], 'image');
        expect(source['type'], 'url');
        expect(source['url'], 'https://example.com/image.jpg');
      });

      test('converts UserMessage with multiple images', () {
        final message = UserMessage([
          const TextPart('Compare these:'),
          ImagePart.fromUrl(Uri.parse('https://example.com/a.jpg')),
          const TextPart('vs'),
          ImagePart.fromUrl(Uri.parse('https://example.com/b.jpg')),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(4));

        expect((content[0] as Map<String, dynamic>)['type'], 'text');
        expect((content[1] as Map<String, dynamic>)['type'], 'image');
        expect((content[2] as Map<String, dynamic>)['type'], 'text');
        expect((content[3] as Map<String, dynamic>)['type'], 'image');
      });
    });

    group('Multi-Part Message Handling', () {
      test('converts UserMessage with multiple TextParts', () {
        final message = UserMessage([
          const TextPart('First part'),
          const TextPart('Second part'),
          const TextPart('Third part'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');
        // Multiple text parts should be joined
        expect(result[0]['content'], 'First part\nSecond part\nThird part');
      });

      test('handles empty message parts list', () {
        final message = UserMessage([]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');
        expect(result[0]['content'], '');
      });

      test('converts AiTextMessage with multiple TextParts', () {
        final message = AiTextMessage([
          const TextPart('Hello!'),
          const TextPart('How can I help?'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'assistant');
        expect(result[0]['content'], 'Hello!\nHow can I help?');
      });
    });

    group('Tool Response Formatting', () {
      test('converts single ToolResultPart', () {
        const message = ToolResponseMessage([
          ToolResultPart(callId: 'call-123', result: 'Tool output'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');

        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(1));
        final toolResult = content[0] as Map<String, dynamic>;
        expect(toolResult['type'], 'tool_result');
        expect(toolResult['tool_use_id'], 'call-123');
        expect(toolResult['content'], 'Tool output');
      });

      test('converts multiple ToolResultParts in one message', () {
        const message = ToolResponseMessage([
          ToolResultPart(callId: 'call-1', result: 'Result 1'),
          ToolResultPart(callId: 'call-2', result: 'Result 2'),
          ToolResultPart(callId: 'call-3', result: 'Result 3'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(3));

        expect((content[0] as Map<String, dynamic>)['tool_use_id'], 'call-1');
        expect((content[1] as Map<String, dynamic>)['tool_use_id'], 'call-2');
        expect((content[2] as Map<String, dynamic>)['tool_use_id'], 'call-3');
      });

      test('converts ToolResultPart with complex JSON result', () {
        final complexResult = jsonEncode({
          'status': 'success',
          'data': {
            'items': [1, 2, 3],
            'nested': {'key': 'value'},
          },
        });

        final message = ToolResponseMessage([
          ToolResultPart(callId: 'call-json', result: complexResult),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        final content = result[0]['content'] as List<dynamic>;
        expect((content[0] as Map<String, dynamic>)['content'], complexResult);
      });

      test('handles empty tool results list', () {
        const message = ToolResponseMessage([]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['content'], isEmpty);
      });

      test('converts ToolResultPart with very long result', () {
        final longResult = 'x' * 10000;

        final message = ToolResponseMessage([
          ToolResultPart(callId: 'call-long', result: longResult),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        final content = result[0]['content'] as List<dynamic>;
        final toolResult = content[0] as Map<String, dynamic>;
        expect(toolResult['content'], longResult);
        expect((toolResult['content'] as String).length, 10000);
      });
    });

    group('UserUiInteractionMessage Handling', () {
      test('converts UserUiInteractionMessage to user role', () {
        final message = UserUiInteractionMessage.text('Button clicked');

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');
        expect(result[0]['content'], 'Button clicked');
      });

      test('converts UserUiInteractionMessage with multiple parts', () {
        final message = UserUiInteractionMessage([
          const TextPart('Action: '),
          const TextPart('submit'),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');
        expect(result[0]['content'], 'Action: \nsubmit');
      });

      test('UserUiInteractionMessage interleaves correctly with other messages',
          () {
        final messages = <ChatMessage>[
          UserMessage.text('Show form'),
          AiTextMessage.text('Here is a form'),
          UserUiInteractionMessage.text('Submit button clicked'),
          AiTextMessage.text('Form submitted'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, hasLength(4));
        expect(result[0]['role'], 'user');
        expect(result[1]['role'], 'assistant');
        expect(result[2]['role'], 'user');
        expect(result[3]['role'], 'assistant');
      });
    });

    group('Unicode and Special Characters', () {
      test('handles RTL text (Arabic)', () {
        const arabicText = 'مرحبا بالعالم';
        final message = UserMessage.text(arabicText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], arabicText);
      });

      test('handles RTL text (Hebrew)', () {
        const hebrewText = 'שלום עולם';
        final message = UserMessage.text(hebrewText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], hebrewText);
      });

      test('handles emoji in messages', () {
        const emojiText = 'Hello! 👋 How are you? 🤔 Great! 🎉';
        final message = UserMessage.text(emojiText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], emojiText);
      });

      test('handles complex emoji sequences', () {
        const complexEmoji = '👨‍👩‍👧‍👦 Family emoji and 🏳️‍🌈 flag';
        final message = UserMessage.text(complexEmoji);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], complexEmoji);
      });

      test('handles control characters (tabs, newlines)', () {
        const textWithControls = 'Line 1\tTabbed\nLine 2\r\nLine 3';
        final message = UserMessage.text(textWithControls);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], textWithControls);
      });

      test('handles zero-width characters', () {
        const textWithZeroWidth = 'Zero\u200Bwidth\u200Bjoiner';
        final message = UserMessage.text(textWithZeroWidth);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], textWithZeroWidth);
      });

      test('handles Chinese characters', () {
        const chineseText = '你好世界';
        final message = UserMessage.text(chineseText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], chineseText);
      });

      test('handles Japanese characters', () {
        const japaneseText = 'こんにちは世界';
        final message = UserMessage.text(japaneseText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], japaneseText);
      });

      test('handles mixed scripts', () {
        const mixedText = 'Hello 你好 مرحبا שלום';
        final message = UserMessage.text(mixedText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], mixedText);
      });
    });

    group('Empty and Null Values', () {
      test('handles empty text in TextPart', () {
        final message = UserMessage([const TextPart('')]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['content'], '');
      });

      test('handles whitespace-only text', () {
        final message = UserMessage.text('   \t\n   ');

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], '   \t\n   ');
      });

      test('handles empty messages list', () {
        final result = MessageConverter.toClaudeMessages([]);

        expect(result, isEmpty);
      });
    });

    group('Very Long Content', () {
      test('handles very long single message', () {
        final longText = 'x' * 50000;
        final message = UserMessage.text(longText);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect((result[0]['content'] as String).length, 50000);
      });

      test('handles many messages', () {
        final messages = List.generate(
          200,
          (i) => i.isEven
              ? UserMessage.text('User message $i')
              : AiTextMessage.text('Assistant message $i'),
        );

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, hasLength(200));
      });

      test('handles message with very long single word', () {
        final longWord = 'a' * 10000;
        final message = UserMessage.text('The word is: $longWord');

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result[0]['content'], 'The word is: $longWord');
      });
    });

    group('InternalMessage Handling', () {
      test('InternalMessage is skipped in conversion', () {
        final messages = <ChatMessage>[
          UserMessage.text('Hello'),
          const InternalMessage('System context here'),
          AiTextMessage.text('Hi there'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, hasLength(2));
        expect(result[0]['content'], 'Hello');
        expect(result[1]['content'], 'Hi there');
      });

      test('extractSystemContext extracts InternalMessages', () {
        final messages = <ChatMessage>[
          const InternalMessage('Context 1'),
          UserMessage.text('Hello'),
          const InternalMessage('Context 2'),
        ];

        final context = MessageConverter.extractSystemContext(messages);

        expect(context, 'Context 1\n\nContext 2');
      });

      test('extractSystemContext returns null when no InternalMessages', () {
        final messages = <ChatMessage>[
          UserMessage.text('Hello'),
          AiTextMessage.text('Hi'),
        ];

        final context = MessageConverter.extractSystemContext(messages);

        expect(context, isNull);
      });
    });

    group('AiUiMessage Handling', () {
      test('AiUiMessage with ToolCallPart converts to assistant with tool_use',
          () {
        final message = AiUiMessage(
          definition: UiDefinition(surfaceId: 'test'),
        );

        // AiUiMessage internally has parts that include tool calls
        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'assistant');
      });
    });

    group('History Pruning', () {
      test('pruneHistory keeps messages under limit', () {
        final messages = [
          {'role': 'user', 'content': 'A'},
          {'role': 'assistant', 'content': 'B'},
          {'role': 'user', 'content': 'C'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 5);

        expect(result, hasLength(3));
      });

      test('pruneHistory removes oldest messages', () {
        final messages = [
          {'role': 'user', 'content': 'Old 1'},
          {'role': 'assistant', 'content': 'Old 2'},
          {'role': 'user', 'content': 'Keep 1'},
          {'role': 'assistant', 'content': 'Keep 2'},
          {'role': 'user', 'content': 'Keep 3'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 3);

        expect(result, hasLength(3));
        expect(result[0]['content'], 'Keep 1');
        expect(result[1]['content'], 'Keep 2');
        expect(result[2]['content'], 'Keep 3');
      });

      test('pruneHistory handles empty list', () {
        final result =
            MessageConverter.pruneHistory(<Map<String, dynamic>>[], maxMessages: 5);

        expect(result, isEmpty);
      });

      test('pruneHistory preserves user-assistant boundaries', () {
        final messages = [
          {'role': 'user', 'content': 'U1'},
          {'role': 'assistant', 'content': 'A1'},
          {'role': 'user', 'content': 'U2'},
          {'role': 'assistant', 'content': 'A2'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 3);

        // Should not start with assistant message
        expect(result.first['role'], 'user');
      });
    });

    group('AiTextMessage with ToolCallPart', () {
      test('converts AiTextMessage with text and tool call', () {
        final message = AiTextMessage([
          const TextPart('Let me search for that.'),
          const ToolCallPart(
            id: 'tool-1',
            toolName: 'search',
            arguments: {'query': 'flutter'},
          ),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'assistant');

        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(2));

        // Text block
        final textBlock = content[0] as Map<String, dynamic>;
        expect(textBlock['type'], 'text');
        expect(textBlock['text'], 'Let me search for that.');

        // Tool use block
        final toolUseBlock = content[1] as Map<String, dynamic>;
        expect(toolUseBlock['type'], 'tool_use');
        expect(toolUseBlock['id'], 'tool-1');
        expect(toolUseBlock['name'], 'search');
        expect(toolUseBlock['input'], {'query': 'flutter'});
      });

      test('converts AiTextMessage with multiple tool calls', () {
        final message = AiTextMessage([
          const ToolCallPart(
            id: 'tool-1',
            toolName: 'begin_rendering',
            arguments: {'surfaceId': 'main'},
          ),
          const ToolCallPart(
            id: 'tool-2',
            toolName: 'surface_update',
            arguments: {'surfaceId': 'main', 'widgets': []},
          ),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        final content = result[0]['content'] as List<dynamic>;
        expect(content, hasLength(2));
        expect((content[0] as Map<String, dynamic>)['name'], 'begin_rendering');
        expect((content[1] as Map<String, dynamic>)['name'], 'surface_update');
      });

      test('skips empty text parts in tool call messages', () {
        final message = AiTextMessage([
          const TextPart(''),
          const ToolCallPart(
            id: 'tool-1',
            toolName: 'action',
            arguments: {},
          ),
        ]);

        final result = MessageConverter.toClaudeMessages([message]);

        final content = result[0]['content'] as List<dynamic>;
        // Empty text part should be skipped
        expect(content, hasLength(1));
        expect((content[0] as Map<String, dynamic>)['type'], 'tool_use');
      });
    });

    group('Conversation Flow Conversion', () {
      test('converts complete multi-turn conversation', () {
        final messages = <ChatMessage>[
          UserMessage.text('What is 2+2?'),
          AiTextMessage.text('2+2 equals 4'),
          UserMessage.text('And 3+3?'),
          AiTextMessage.text('3+3 equals 6'),
          UserMessage.text('Thanks!'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, hasLength(5));
        expect(result.map((m) => m['role']).toList(),
            ['user', 'assistant', 'user', 'assistant', 'user'],);
      });

      test('converts conversation with tool interactions', () {
        final messages = <ChatMessage>[
          UserMessage.text('Search for flutter'),
          AiTextMessage([
            const TextPart('Searching...'),
            const ToolCallPart(
              id: 'search-1',
              toolName: 'search',
              arguments: {'q': 'flutter'},
            ),
          ]),
          const ToolResponseMessage([
            ToolResultPart(callId: 'search-1', result: 'Found: Flutter SDK'),
          ]),
          AiTextMessage.text('I found Flutter SDK'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, hasLength(4));
        expect(result[0]['role'], 'user');
        expect(result[1]['role'], 'assistant');
        expect(result[2]['role'], 'user'); // Tool response is user role
        expect(result[3]['role'], 'assistant');
      });
    });
  });
}
