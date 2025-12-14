import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/utils/message_converter.dart';

void main() {
  group('MessageConverter', () {
    group('toClaudeMessages', () {
      test('converts empty list to empty result', () {
        final messages = <ChatMessage>[];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result, isEmpty);
      });

      test('converts UserMessage to user role message', () {
        final messages = [UserMessage.text('Hello, Claude!')];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        expect(result.first['role'], 'user');
        expect(result.first['content'], contains('Hello, Claude!'));
      });

      test('converts AiTextMessage to assistant role message', () {
        final messages = [AiTextMessage.text('Hello! How can I help?')];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        expect(result.first['role'], 'assistant');
        expect(result.first['content'], contains('Hello! How can I help?'));
      });

      test('converts conversation with multiple turns', () {
        final messages = [
          UserMessage.text('Hi there!'),
          AiTextMessage.text('Hello! How can I help you today?'),
          UserMessage.text('Tell me a joke'),
          AiTextMessage.text('Why did the developer go broke?'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 4);
        expect(result[0]['role'], 'user');
        expect(result[1]['role'], 'assistant');
        expect(result[2]['role'], 'user');
        expect(result[3]['role'], 'assistant');
      });

      test('handles UserMessage with multiple TextParts', () {
        final messages = [
          UserMessage([
            const TextPart('First line'),
            const TextPart('Second line'),
          ]),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        final content = result.first['content'] as String;
        expect(content, contains('First line'));
        expect(content, contains('Second line'));
      });

      test('handles ToolCallPart in AiTextMessage', () {
        final messages = [
          AiTextMessage([
            const TextPart('Let me render a UI for you'),
            const ToolCallPart(
              id: 'tool_call_1',
              toolName: 'begin_rendering',
              arguments: {'surfaceId': 'main'},
            ),
          ]),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        expect(result.first['role'], 'assistant');
        // Should include tool_use content
        final content = result.first['content'];
        expect(content, isA<List<Map<String, dynamic>>>());
      });

      test('handles ToolResponseMessage', () {
        final messages = [
          const ToolResponseMessage([
            ToolResultPart(callId: 'tool_call_1', result: '{"success": true}'),
          ]),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        expect(result.first['role'], 'user');
        final content = result.first['content'];
        expect(content, isA<List<Map<String, dynamic>>>());
      });

      test('skips InternalMessage by default', () {
        final messages = [
          const InternalMessage('System context'),
          UserMessage.text('Hello!'),
        ];

        final result = MessageConverter.toClaudeMessages(messages);

        expect(result.length, 1);
        expect(result.first['role'], 'user');
      });
    });

    group('pruneHistory', () {
      test('returns all messages when under limit', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 10);

        expect(result.length, 2);
      });

      test('keeps most recent messages when over limit', () {
        final messages = [
          {'role': 'user', 'content': 'Message 1'},
          {'role': 'assistant', 'content': 'Response 1'},
          {'role': 'user', 'content': 'Message 2'},
          {'role': 'assistant', 'content': 'Response 2'},
          {'role': 'user', 'content': 'Message 3'},
          {'role': 'assistant', 'content': 'Response 3'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 4);

        expect(result.length, 4);
        expect(result.first['content'], 'Message 2');
        expect(result.last['content'], 'Response 3');
      });

      test('preserves user-assistant pair boundaries', () {
        final messages = [
          {'role': 'user', 'content': 'Message 1'},
          {'role': 'assistant', 'content': 'Response 1'},
          {'role': 'user', 'content': 'Message 2'},
          {'role': 'assistant', 'content': 'Response 2'},
          {'role': 'user', 'content': 'Message 3'},
        ];

        // If we want 3 messages but the boundary would break a pair,
        // we should get 4 instead (or 2 to keep coherence)
        final result = MessageConverter.pruneHistory(messages, maxMessages: 3);

        // Should ensure we don't start with assistant
        expect(result.first['role'], 'user');
      });

      test('handles single message', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
        ];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 1);

        expect(result.length, 1);
        expect(result.first['content'], 'Hello');
      });

      test('returns empty for empty input', () {
        final messages = <Map<String, dynamic>>[];

        final result = MessageConverter.pruneHistory(messages, maxMessages: 10);

        expect(result, isEmpty);
      });
    });

    group('extractSystemContext', () {
      test('extracts InternalMessage as system context', () {
        final messages = [
          const InternalMessage('You are a helpful assistant'),
          UserMessage.text('Hello!'),
        ];

        final context = MessageConverter.extractSystemContext(messages);

        expect(context, 'You are a helpful assistant');
      });

      test('combines multiple InternalMessages', () {
        final messages = [
          const InternalMessage('Context 1'),
          const InternalMessage('Context 2'),
          UserMessage.text('Hello!'),
        ];

        final context = MessageConverter.extractSystemContext(messages);

        expect(context, contains('Context 1'));
        expect(context, contains('Context 2'));
      });

      test('returns null when no InternalMessage', () {
        final messages = [
          UserMessage.text('Hello!'),
          AiTextMessage.text('Hi!'),
        ];

        final context = MessageConverter.extractSystemContext(messages);

        expect(context, isNull);
      });
    });
  });
}
