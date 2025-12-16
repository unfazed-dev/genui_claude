/// Conversation history tests for ClaudeContentGenerator.
///
/// These tests verify that ChatMessage types are correctly converted
/// between GenUI format and Claude API format.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import '../handler/mock_api_handler.dart';

void main() {
  group('Conversation History', () {
    group('MessageConverter.toClaudeMessages', () {
      test('UserMessage converts to user role', () {
        final messages = [UserMessage.text('Hello')];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, hasLength(1));
        expect(claude.first['role'], 'user');
        expect(claude.first['content'], 'Hello');
      });

      test('AiTextMessage converts to assistant role', () {
        final messages = [AiTextMessage.text('Hi there!')];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, hasLength(1));
        expect(claude.first['role'], 'assistant');
        expect(claude.first['content'], 'Hi there!');
      });

      test('ToolResponseMessage converts to user role with tool_result', () {
        const messages = [
          ToolResponseMessage([
            ToolResultPart(callId: 'call-123', result: 'Tool output'),
          ]),
        ];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, hasLength(1));
        expect(claude.first['role'], 'user');

        final content = claude.first['content'] as List<dynamic>;
        expect(content, hasLength(1));

        final toolResult = content.first as Map<String, dynamic>;
        expect(toolResult['type'], 'tool_result');
        expect(toolResult['tool_use_id'], 'call-123');
        expect(toolResult['content'], 'Tool output');
      });

      test('InternalMessage is skipped', () {
        final messages = <ChatMessage>[
          UserMessage.text('Hello'),
          const InternalMessage('System context'),
          AiTextMessage.text('Response'),
        ];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, hasLength(2));
        expect(claude[0]['role'], 'user');
        expect(claude[1]['role'], 'assistant');
      });

      test('multi-turn conversation maintains order', () {
        final messages = <ChatMessage>[
          UserMessage.text('First'),
          AiTextMessage.text('First response'),
          UserMessage.text('Second'),
          AiTextMessage.text('Second response'),
        ];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, hasLength(4));
        expect(claude[0]['role'], 'user');
        expect(claude[0]['content'], 'First');
        expect(claude[1]['role'], 'assistant');
        expect(claude[1]['content'], 'First response');
        expect(claude[2]['role'], 'user');
        expect(claude[2]['content'], 'Second');
        expect(claude[3]['role'], 'assistant');
        expect(claude[3]['content'], 'Second response');
      });

      test('empty history returns empty list', () {
        final messages = <ChatMessage>[];
        final claude = MessageConverter.toClaudeMessages(messages);

        expect(claude, isEmpty);
      });
    });

    group('MessageConverter.pruneHistory', () {
      test('returns all messages when under limit', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi'},
        ];
        final pruned = MessageConverter.pruneHistory(messages, maxMessages: 10);

        expect(pruned, hasLength(2));
      });

      test('truncates to maxMessages from the end', () {
        final messages = [
          {'role': 'user', 'content': 'Message 1'},
          {'role': 'assistant', 'content': 'Response 1'},
          {'role': 'user', 'content': 'Message 2'},
          {'role': 'assistant', 'content': 'Response 2'},
          {'role': 'user', 'content': 'Message 3'},
          {'role': 'assistant', 'content': 'Response 3'},
        ];
        final pruned = MessageConverter.pruneHistory(messages, maxMessages: 4);

        expect(pruned, hasLength(4));
        expect(pruned.first['content'], 'Message 2');
        expect(pruned.last['content'], 'Response 3');
      });

      test('handles empty messages list', () {
        final messages = <Map<String, dynamic>>[];
        final pruned = MessageConverter.pruneHistory(messages, maxMessages: 10);

        expect(pruned, isEmpty);
      });
    });

    group('MessageConverter.extractSystemContext', () {
      test('extracts InternalMessage text', () {
        final messages = <ChatMessage>[
          const InternalMessage('System instruction 1'),
          UserMessage.text('Hello'),
          const InternalMessage('System instruction 2'),
        ];
        final context = MessageConverter.extractSystemContext(messages);

        expect(context, isNotNull);
        expect(context, contains('System instruction 1'));
        expect(context, contains('System instruction 2'));
      });

      test('returns null when no InternalMessages', () {
        final messages = <ChatMessage>[
          UserMessage.text('Hello'),
          AiTextMessage.text('Hi'),
        ];
        final context = MessageConverter.extractSystemContext(messages);

        expect(context, isNull);
      });
    });

    group('History Integration with Generator', () {
      late MockApiHandler mockHandler;
      late ClaudeContentGenerator generator;

      setUp(() {
        mockHandler = MockApiHandler();
        generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
      });

      tearDown(() {
        generator.dispose();
      });

      test('history is included in API request', () async {
        mockHandler.stubTextResponse('Response');

        final history = <ChatMessage>[
          UserMessage.text('First message'),
          AiTextMessage.text('First response'),
        ];

        await generator.sendRequest(
          UserMessage.text('Second message'),
          history: history,
        );

        final request = mockHandler.lastRequest!;
        expect(request.messages, hasLength(3));
        expect(request.messages[0]['content'], 'First message');
        expect(request.messages[1]['content'], 'First response');
        expect(request.messages[2]['content'], 'Second message');
      });

      test('tool responses in history are properly formatted', () async {
        mockHandler.stubTextResponse('Response');

        final history = <ChatMessage>[
          UserMessage.text('Use a tool'),
          const ToolResponseMessage([
            ToolResultPart(callId: 'tool-1', result: 'Tool result'),
          ]),
        ];

        await generator.sendRequest(
          UserMessage.text('Continue'),
          history: history,
        );

        final request = mockHandler.lastRequest!;
        expect(request.messages, hasLength(3));

        // Second message should be tool_result format
        final toolMessage = request.messages[1];
        expect(toolMessage['role'], 'user');
        expect(
          toolMessage['content'],
          isA<List<dynamic>>().having(
            (l) => (l.first as Map<String, dynamic>)['type'],
            'type',
            'tool_result',
          ),
        );
      });

      test('conversation continuity with multiple turns', () async {
        // First turn
        mockHandler.stubTextResponse('First response');
        await generator.sendRequest(UserMessage.text('First'));
        expect(mockHandler.lastRequest?.messages, hasLength(1));

        // Second turn with history
        mockHandler.stubTextResponse('Second response');
        await generator.sendRequest(
          UserMessage.text('Second'),
          history: [
            UserMessage.text('First'),
            AiTextMessage.text('First response'),
          ],
        );
        expect(mockHandler.lastRequest?.messages, hasLength(3));

        // Third turn with full history
        mockHandler.stubTextResponse('Third response');
        await generator.sendRequest(
          UserMessage.text('Third'),
          history: [
            UserMessage.text('First'),
            AiTextMessage.text('First response'),
            UserMessage.text('Second'),
            AiTextMessage.text('Second response'),
          ],
        );
        expect(mockHandler.lastRequest?.messages, hasLength(5));
      });
    });
  });
}
