import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/src/handler/api_handler.dart';

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
