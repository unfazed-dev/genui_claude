import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/handler/api_handler.dart';

void main() {
  group('ApiRequest', () {
    test('creates with required fields', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
      );

      expect(request.messages.length, 1);
      expect(request.maxTokens, 1024);
      expect(request.systemInstruction, isNull);
      expect(request.tools, isNull);
      expect(request.model, isNull);
      expect(request.temperature, isNull);
    });

    test('creates with all fields', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there!'},
        ],
        maxTokens: 2048,
        systemInstruction: 'You are a helpful assistant.',
        tools: [
          {
            'name': 'test_tool',
            'description': 'A test tool',
            'input_schema': {'type': 'object'},
          },
        ],
        model: 'claude-sonnet-4-20250514',
        temperature: 0.7,
      );

      expect(request.messages.length, 2);
      expect(request.maxTokens, 2048);
      expect(request.systemInstruction, 'You are a helpful assistant.');
      expect(request.tools, isNotNull);
      expect(request.tools!.length, 1);
      expect(request.model, 'claude-sonnet-4-20250514');
      expect(request.temperature, 0.7);
    });

    test('creates with advanced model parameters (topP, topK, stopSequences)',
        () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
        topP: 0.9,
        topK: 40,
        stopSequences: ['END', 'STOP'],
      );

      expect(request.topP, 0.9);
      expect(request.topK, 40);
      expect(request.stopSequences, ['END', 'STOP']);
    });

    test('advanced parameters default to null', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
      );

      expect(request.topP, isNull);
      expect(request.topK, isNull);
      expect(request.stopSequences, isNull);
    });

    test('streaming/thinking parameters default to false/null', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
      );

      expect(request.enableFineGrainedStreaming, isFalse);
      expect(request.enableInterleavedThinking, isFalse);
      expect(request.thinkingBudgetTokens, isNull);
    });

    test('creates with fine-grained streaming enabled', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
        enableFineGrainedStreaming: true,
      );

      expect(request.enableFineGrainedStreaming, isTrue);
    });

    test('creates with interleaved thinking enabled', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
        enableInterleavedThinking: true,
        thinkingBudgetTokens: 10000,
      );

      expect(request.enableInterleavedThinking, isTrue);
      expect(request.thinkingBudgetTokens, 10000);
    });

    test('creates with both streaming features enabled', () {
      const request = ApiRequest(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 1024,
        enableFineGrainedStreaming: true,
        enableInterleavedThinking: true,
        thinkingBudgetTokens: 5000,
      );

      expect(request.enableFineGrainedStreaming, isTrue);
      expect(request.enableInterleavedThinking, isTrue);
      expect(request.thinkingBudgetTokens, 5000);
    });

    group('toString', () {
      test('returns formatted string with message count', () {
        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
            {'role': 'assistant', 'content': 'Hi'},
            {'role': 'user', 'content': 'How are you?'},
          ],
          maxTokens: 1024,
          model: 'claude-3-opus',
        );

        final result = request.toString();

        expect(result, contains('messages: 3'));
        expect(result, contains('maxTokens: 1024'));
        expect(result, contains('model: claude-3-opus'));
        expect(result, contains('hasTools: false'));
      });

      test('shows hasTools: true when tools provided', () {
        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 1024,
          tools: [
            {'name': 'tool1', 'description': 'Tool 1'},
          ],
        );

        final result = request.toString();

        expect(result, contains('hasTools: true'));
      });

      test('shows null model when not specified', () {
        const request = ApiRequest(
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
          maxTokens: 512,
        );

        final result = request.toString();

        expect(result, contains('model: null'));
        expect(result, contains('maxTokens: 512'));
      });
    });
  });
}
