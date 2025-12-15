import 'dart:convert';

import 'package:genui_anthropic/genui_anthropic.dart';

/// Mock implementation of [ApiHandler] for testing.
///
/// Allows stubbing of stream events and tracking of calls.
///
/// Example usage:
/// ```dart
/// final mockHandler = MockApiHandler();
/// mockHandler.stubEvents([
///   {'type': 'content_block_start', 'index': 0, 'content_block': {'type': 'text'}},
///   {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'text_delta', 'text': 'Hello'}},
///   {'type': 'message_stop'},
/// ]);
///
/// final generator = AnthropicContentGenerator.withHandler(handler: mockHandler);
/// await generator.sendRequest(UserMessage.text('Hi'));
///
/// expect(mockHandler.createStreamCallCount, 1);
/// expect(mockHandler.lastRequest?.messages.length, 1);
/// ```
class MockApiHandler implements ApiHandler {
  /// Events to return from [createStream].
  List<Map<String, dynamic>> _stubbedEvents = [];

  /// Exception to throw from [createStream].
  Exception? _stubbedException;

  /// Number of times [createStream] was called.
  int createStreamCallCount = 0;

  /// The last request passed to [createStream].
  ApiRequest? lastRequest;

  /// Whether [dispose] was called.
  bool disposed = false;

  /// Stubs the events to be emitted by [createStream].
  void stubEvents(List<Map<String, dynamic>> events) {
    _stubbedEvents = events;
    _stubbedException = null;
  }

  /// Stubs a simple text response.
  void stubTextResponse(String text) {
    _stubbedEvents = [
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text'},
      },
      {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': text},
      },
      {'type': 'content_block_stop', 'index': 0},
      {'type': 'message_stop'},
    ];
    _stubbedException = null;
  }

  /// Stubs an error to be thrown.
  // ignore: use_setters_to_change_properties
  void stubError(Exception error) {
    _stubbedException = error;
  }

  /// Resets all stubbed data and call tracking.
  void reset() {
    _stubbedEvents = [];
    _stubbedException = null;
    createStreamCallCount = 0;
    lastRequest = null;
    disposed = false;
  }

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    createStreamCallCount++;
    lastRequest = request;

    if (_stubbedException != null) {
      throw _stubbedException!;
    }

    for (final event in _stubbedEvents) {
      yield event;
    }
  }

  @override
  void dispose() {
    disposed = true;
  }
}

/// Factory for creating common mock event sequences.
class MockEventFactory {
  MockEventFactory._();

  /// Creates a simple text response sequence.
  static List<Map<String, dynamic>> textResponse(String text) {
    return [
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text'},
      },
      {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': text},
      },
      {'type': 'content_block_stop', 'index': 0},
      {'type': 'message_stop'},
    ];
  }

  /// Creates a streaming text response (multiple deltas).
  static List<Map<String, dynamic>> streamingTextResponse(List<String> chunks) {
    final events = <Map<String, dynamic>>[
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text'},
      },
    ];

    for (final chunk in chunks) {
      events.add({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': chunk},
      });
    }

    events.addAll([
      {'type': 'content_block_stop', 'index': 0},
      {'type': 'message_stop'},
    ]);

    return events;
  }

  /// Creates a tool use response sequence.
  static List<Map<String, dynamic>> toolUseResponse({
    required String toolId,
    required String toolName,
    required Map<String, dynamic> input,
  }) {
    return [
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {
          'type': 'tool_use',
          'id': toolId,
          'name': toolName,
        },
      },
      {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': input.toString(),
        },
      },
      {'type': 'content_block_stop', 'index': 0},
      {'type': 'message_stop'},
    ];
  }

  /// Creates an error event.
  static List<Map<String, dynamic>> errorResponse(String message) {
    return [
      {
        'type': 'error',
        'error': {'message': message},
      },
    ];
  }

  // ========== A2UI Tool Response Methods ==========

  /// Creates a begin_rendering tool use response.
  static List<Map<String, dynamic>> beginRenderingResponse({
    required String surfaceId,
    String? parentSurfaceId,
    Map<String, dynamic>? metadata,
  }) {
    final input = {
      'surfaceId': surfaceId,
      if (parentSurfaceId != null) 'parentSurfaceId': parentSurfaceId,
      if (metadata != null) 'metadata': metadata,
    };
    return _a2uiToolResponse('begin_rendering', 'tool-br-1', input);
  }

  /// Creates a surface_update tool use response.
  static List<Map<String, dynamic>> surfaceUpdateResponse({
    required String surfaceId,
    required List<Map<String, dynamic>> widgets,
    bool append = false,
  }) {
    final input = {
      'surfaceId': surfaceId,
      'widgets': widgets,
      'append': append,
    };
    return _a2uiToolResponse('surface_update', 'tool-su-1', input);
  }

  /// Creates a data_model_update tool use response.
  static List<Map<String, dynamic>> dataModelUpdateResponse({
    required Map<String, dynamic> updates,
    String? scope,
  }) {
    final input = {
      'updates': updates,
      if (scope != null) 'scope': scope,
    };
    return _a2uiToolResponse('data_model_update', 'tool-dm-1', input);
  }

  /// Creates a delete_surface tool use response.
  static List<Map<String, dynamic>> deleteSurfaceResponse({
    required String surfaceId,
    bool cascade = true,
  }) {
    final input = {
      'surfaceId': surfaceId,
      'cascade': cascade,
    };
    return _a2uiToolResponse('delete_surface', 'tool-ds-1', input);
  }

  /// Creates a complete A2UI widget rendering sequence.
  ///
  /// Includes begin_rendering followed by surface_update.
  static List<Map<String, dynamic>> widgetRenderingResponse({
    String surfaceId = 'main',
    List<Map<String, dynamic>>? widgets,
    Map<String, dynamic>? metadata,
  }) {
    final widgetList = widgets ??
        [
          {
            'type': 'Text',
            'properties': {'text': 'Hello, World!'},
          },
        ];

    return [
      // Begin rendering
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-1',
        {
          'surfaceId': surfaceId,
          if (metadata != null) 'metadata': metadata,
        },
        index: 0,
      ),
      // Surface update with widgets
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-1',
        {
          'surfaceId': surfaceId,
          'widgets': widgetList,
          'append': false,
        },
        index: 1,
      ),
      {'type': 'message_stop'},
    ];
  }

  /// Helper to create a proper A2UI tool use event sequence.
  static List<Map<String, dynamic>> _a2uiToolResponse(
    String toolName,
    String toolId,
    Map<String, dynamic> input,
  ) {
    final jsonStr = jsonEncode(input);
    return [
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {
          'type': 'tool_use',
          'id': toolId,
          'name': toolName,
        },
      },
      {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': jsonStr,
        },
      },
      {'type': 'content_block_stop', 'index': 0},
      {'type': 'message_stop'},
    ];
  }

  /// Helper for multi-tool responses with specific index.
  static List<Map<String, dynamic>> _a2uiToolResponseWithIndex(
    String toolName,
    String toolId,
    Map<String, dynamic> input, {
    required int index,
  }) {
    final jsonStr = jsonEncode(input);
    return [
      {
        'type': 'content_block_start',
        'index': index,
        'content_block': {
          'type': 'tool_use',
          'id': toolId,
          'name': toolName,
        },
      },
      {
        'type': 'content_block_delta',
        'index': index,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': jsonStr,
        },
      },
      {'type': 'content_block_stop', 'index': index},
    ];
  }
}
