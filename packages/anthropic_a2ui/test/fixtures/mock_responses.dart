/// Mock response fixtures for anthropic_a2ui tests.
///
/// Provides pre-built mock data for MessageStreamEvent sequences,
/// tool_use blocks, and error responses.
library;

/// Mock stream event sequences for testing streaming functionality.
class MockStreamEvents {
  MockStreamEvents._();

  /// A simple message_start event.
  static Map<String, dynamic> messageStart({
    String id = 'msg_test123',
    String model = 'claude-3-opus-20240229',
  }) =>
      {
        'type': 'message_start',
        'message': {
          'id': id,
          'type': 'message',
          'role': 'assistant',
          'model': model,
          'content': <dynamic>[],
          'stop_reason': null,
          'stop_sequence': null,
        },
      };

  /// A content_block_start event for tool_use.
  static Map<String, dynamic> toolUseStart({
    required int index,
    required String toolName,
    String id = 'toolu_test123',
  }) =>
      {
        'type': 'content_block_start',
        'index': index,
        'content_block': {
          'type': 'tool_use',
          'id': id,
          'name': toolName,
          'input': <String, dynamic>{},
        },
      };

  /// A content_block_start event for text.
  static Map<String, dynamic> textStart({
    required int index,
    String text = '',
  }) =>
      {
        'type': 'content_block_start',
        'index': index,
        'content_block': {
          'type': 'text',
          'text': text,
        },
      };

  /// A content_block_delta event for JSON input.
  static Map<String, dynamic> inputJsonDelta({
    required int index,
    required String partialJson,
  }) =>
      {
        'type': 'content_block_delta',
        'index': index,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': partialJson,
        },
      };

  /// A content_block_delta event for text.
  static Map<String, dynamic> textDelta({
    required int index,
    required String text,
  }) =>
      {
        'type': 'content_block_delta',
        'index': index,
        'delta': {
          'type': 'text_delta',
          'text': text,
        },
      };

  /// A content_block_stop event.
  static Map<String, dynamic> contentBlockStop({required int index}) => {
        'type': 'content_block_stop',
        'index': index,
      };

  /// A message_delta event.
  static Map<String, dynamic> messageDelta({
    String? stopReason = 'end_turn',
  }) =>
      {
        'type': 'message_delta',
        'delta': {
          'stop_reason': stopReason,
          'stop_sequence': null,
        },
        'usage': {
          'output_tokens': 50,
        },
      };

  /// A message_stop event.
  static const Map<String, dynamic> messageStop = {
    'type': 'message_stop',
  };

  /// An error event.
  static Map<String, dynamic> error({
    required String message,
    String type = 'api_error',
  }) =>
      {
        'type': 'error',
        'error': {
          'type': type,
          'message': message,
        },
      };
}

/// Mock tool_use block fixtures for A2UI tools.
class MockToolUseBlocks {
  MockToolUseBlocks._();

  /// A begin_rendering tool_use block.
  static Map<String, dynamic> beginRendering({
    String surfaceId = 'surface-test-1',
    String? title,
    Map<String, dynamic>? initialState,
    String id = 'toolu_begin_1',
  }) =>
      {
        'type': 'tool_use',
        'id': id,
        'name': 'begin_rendering',
        'input': {
          'surfaceId': surfaceId,
          if (title != null) 'title': title,
          if (initialState != null) 'initialState': initialState,
        },
      };

  /// A simple surface_update tool_use block with basic widgets.
  static Map<String, dynamic> surfaceUpdateSimple({
    String surfaceId = 'surface-test-1',
    String id = 'toolu_update_1',
  }) =>
      {
        'type': 'tool_use',
        'id': id,
        'name': 'surface_update',
        'input': {
          'surfaceId': surfaceId,
          'widgets': [
            {
              'type': 'text',
              'id': 'text-1',
              'props': {'content': 'Hello World'},
            },
            {
              'type': 'button',
              'id': 'btn-1',
              'props': {'label': 'Click Me'},
            },
          ],
        },
      };

  /// A surface_update tool_use block with nested widgets.
  static Map<String, dynamic> surfaceUpdateNested({
    String surfaceId = 'surface-test-1',
    String id = 'toolu_update_nested_1',
  }) =>
      {
        'type': 'tool_use',
        'id': id,
        'name': 'surface_update',
        'input': {
          'surfaceId': surfaceId,
          'widgets': [
            {
              'type': 'column',
              'id': 'col-1',
              'props': {'spacing': 16},
              'children': [
                {
                  'type': 'text',
                  'id': 'text-1',
                  'props': {'content': 'Header'},
                },
                {
                  'type': 'row',
                  'id': 'row-1',
                  'props': {'alignment': 'center'},
                  'children': [
                    {
                      'type': 'button',
                      'id': 'btn-1',
                      'props': {'label': 'Cancel'},
                    },
                    {
                      'type': 'button',
                      'id': 'btn-2',
                      'props': {'label': 'Submit'},
                    },
                  ],
                },
              ],
            },
          ],
        },
      };

  /// A data_model_update tool_use block.
  static Map<String, dynamic> dataModelUpdate({
    String surfaceId = 'surface-test-1',
    Map<String, dynamic>? updates,
    String? scope,
    String id = 'toolu_data_1',
  }) =>
      {
        'type': 'tool_use',
        'id': id,
        'name': 'data_model_update',
        'input': {
          'surfaceId': surfaceId,
          'updates': updates ?? {'count': 42, 'name': 'Test'},
          if (scope != null) 'scope': scope,
        },
      };

  /// A delete_surface tool_use block.
  static Map<String, dynamic> deleteSurface({
    String surfaceId = 'surface-test-1',
    bool cascade = true,
    String id = 'toolu_delete_1',
  }) =>
      {
        'type': 'tool_use',
        'id': id,
        'name': 'delete_surface',
        'input': {
          'surfaceId': surfaceId,
          'cascade': cascade,
        },
      };
}

/// Mock error response fixtures.
class MockErrorResponses {
  MockErrorResponses._();

  /// A 429 rate limit error response.
  static Map<String, dynamic> rateLimit({
    String retryAfter = '30',
  }) =>
      {
        'type': 'error',
        'error': {
          'type': 'rate_limit_error',
          'message': 'Rate limit exceeded. Please retry after $retryAfter seconds.',
        },
      };

  /// A 500 server error response.
  static const Map<String, dynamic> serverError = {
    'type': 'error',
    'error': {
      'type': 'api_error',
      'message': 'Internal server error. Please try again later.',
    },
  };

  /// A malformed JSON response (simulated as a string that would fail parsing).
  static const String malformedJson = '{"type": "message", "content": [}';

  /// An authentication error response.
  static const Map<String, dynamic> authenticationError = {
    'type': 'error',
    'error': {
      'type': 'authentication_error',
      'message': 'Invalid API key provided.',
    },
  };

  /// An overloaded error response.
  static const Map<String, dynamic> overloadedError = {
    'type': 'error',
    'error': {
      'type': 'overloaded_error',
      'message': 'The API is temporarily overloaded. Please try again.',
    },
  };

  /// An invalid request error response.
  static Map<String, dynamic> invalidRequest({
    String message = 'Invalid request parameters.',
  }) =>
      {
        'type': 'error',
        'error': {
          'type': 'invalid_request_error',
          'message': message,
        },
      };
}

/// Complete stream event sequences for integration testing.
class MockStreamSequences {
  MockStreamSequences._();

  /// A complete begin_rendering sequence.
  static List<Map<String, dynamic>> beginRenderingSequence({
    String surfaceId = 'surface-test-1',
    String? title,
  }) =>
      [
        MockStreamEvents.messageStart(),
        MockStreamEvents.toolUseStart(index: 0, toolName: 'begin_rendering'),
        MockStreamEvents.inputJsonDelta(
          index: 0,
          partialJson: '{"surfaceId":"$surfaceId"',
        ),
        if (title != null)
          MockStreamEvents.inputJsonDelta(
            index: 0,
            partialJson: ',"title":"$title"',
          ),
        MockStreamEvents.inputJsonDelta(index: 0, partialJson: '}'),
        MockStreamEvents.contentBlockStop(index: 0),
        MockStreamEvents.messageDelta(),
        MockStreamEvents.messageStop,
      ];

  /// A complete surface_update sequence with simple widgets.
  static List<Map<String, dynamic>> surfaceUpdateSequence({
    String surfaceId = 'surface-test-1',
  }) =>
      [
        MockStreamEvents.messageStart(),
        MockStreamEvents.toolUseStart(index: 0, toolName: 'surface_update'),
        MockStreamEvents.inputJsonDelta(
          index: 0,
          partialJson: '{"surfaceId":"$surfaceId","widgets":[',
        ),
        MockStreamEvents.inputJsonDelta(
          index: 0,
          partialJson: '{"type":"text","id":"t1","props":{"content":"Hello"}}',
        ),
        MockStreamEvents.inputJsonDelta(index: 0, partialJson: ']}'),
        MockStreamEvents.contentBlockStop(index: 0),
        MockStreamEvents.messageDelta(),
        MockStreamEvents.messageStop,
      ];

  /// A mixed sequence with text and tool_use blocks.
  static List<Map<String, dynamic>> mixedContentSequence({
    String surfaceId = 'surface-test-1',
  }) =>
      [
        MockStreamEvents.messageStart(),
        // Text block first
        MockStreamEvents.textStart(index: 0),
        MockStreamEvents.textDelta(index: 0, text: 'Let me create a UI for you.'),
        MockStreamEvents.contentBlockStop(index: 0),
        // Then tool_use block
        MockStreamEvents.toolUseStart(index: 1, toolName: 'begin_rendering'),
        MockStreamEvents.inputJsonDelta(
          index: 1,
          partialJson: '{"surfaceId":"$surfaceId"}',
        ),
        MockStreamEvents.contentBlockStop(index: 1),
        MockStreamEvents.messageDelta(),
        MockStreamEvents.messageStop,
      ];

  /// A sequence that ends with an error.
  static List<Map<String, dynamic>> errorSequence({
    String errorMessage = 'Connection lost',
  }) =>
      [
        MockStreamEvents.messageStart(),
        MockStreamEvents.toolUseStart(index: 0, toolName: 'begin_rendering'),
        MockStreamEvents.inputJsonDelta(
          index: 0,
          partialJson: '{"surfaceId":',
        ),
        MockStreamEvents.error(message: errorMessage),
      ];

  /// A complete flow with multiple tool calls.
  static List<Map<String, dynamic>> multiToolSequence({
    String surfaceId = 'surface-test-1',
  }) =>
      [
        MockStreamEvents.messageStart(),
        // begin_rendering
        MockStreamEvents.toolUseStart(index: 0, toolName: 'begin_rendering'),
        MockStreamEvents.inputJsonDelta(
          index: 0,
          partialJson: '{"surfaceId":"$surfaceId","title":"Test UI"}',
        ),
        MockStreamEvents.contentBlockStop(index: 0),
        // surface_update
        MockStreamEvents.toolUseStart(index: 1, toolName: 'surface_update'),
        MockStreamEvents.inputJsonDelta(
          index: 1,
          partialJson:
              '{"surfaceId":"$surfaceId","widgets":[{"type":"text","id":"t1","props":{"content":"Content"}}]}',
        ),
        MockStreamEvents.contentBlockStop(index: 1),
        MockStreamEvents.messageDelta(),
        MockStreamEvents.messageStop,
      ];
}
