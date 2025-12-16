import 'dart:convert';

import 'package:genui_claude/genui_claude.dart';

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
/// final generator = ClaudeContentGenerator.withHandler(handler: mockHandler);
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

  /// Delay before emitting events.
  Duration? _eventDelay;

  /// Exception to throw after emitting some events (mid-stream error).
  Exception? _midStreamError;

  /// Number of events to emit before throwing mid-stream error.
  int _eventsBeforeError = 0;

  /// All captured requests (for multi-call tracking).
  final List<ApiRequest> capturedRequests = [];

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

  /// Stubs events with a delay between each event.
  ///
  /// Useful for testing timing-sensitive behavior like cancellation.
  void stubDelayedEvents(
    List<Map<String, dynamic>> events, {
    Duration delay = const Duration(milliseconds: 10),
  }) {
    _stubbedEvents = events;
    _eventDelay = delay;
    _stubbedException = null;
    _midStreamError = null;
  }

  /// Stubs a mid-stream error that occurs after emitting some events.
  ///
  /// Useful for testing error recovery during streaming.
  void stubStreamError(
    Exception error, {
    List<Map<String, dynamic>> eventsBeforeError = const [],
  }) {
    _stubbedEvents = eventsBeforeError;
    _midStreamError = error;
    _eventsBeforeError = eventsBeforeError.length;
    _stubbedException = null;
  }

  /// Resets all stubbed data and call tracking.
  void reset() {
    _stubbedEvents = [];
    _stubbedException = null;
    _eventDelay = null;
    _midStreamError = null;
    _eventsBeforeError = 0;
    capturedRequests.clear();
    createStreamCallCount = 0;
    lastRequest = null;
    disposed = false;
  }

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    createStreamCallCount++;
    lastRequest = request;
    capturedRequests.add(request);

    if (_stubbedException != null) {
      throw _stubbedException!;
    }

    var eventIndex = 0;
    for (final event in _stubbedEvents) {
      if (_eventDelay != null) {
        await Future<void>.delayed(_eventDelay!);
      }
      yield event;
      eventIndex++;

      // Check for mid-stream error after emitting specified events
      if (_midStreamError != null && eventIndex >= _eventsBeforeError) {
        throw _midStreamError!;
      }
    }

    // If mid-stream error but no events before it, throw now
    if (_midStreamError != null && _eventsBeforeError == 0) {
      throw _midStreamError!;
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

  // ========== Edge Case Event Generators ==========

  /// Creates a mixed text and A2UI tool response.
  ///
  /// Useful for testing interleaved text and widget content.
  static List<Map<String, dynamic>> mixedTextAndWidgetResponse({
    required String text,
    required String surfaceId,
    List<Map<String, dynamic>>? widgets,
  }) {
    final widgetList = widgets ??
        [
          {
            'type': 'Text',
            'properties': {'text': 'Widget content'},
          },
        ];

    return [
      // Text block first
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
      // Then A2UI tools
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-1',
        {'surfaceId': surfaceId},
        index: 1,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-1',
        {'surfaceId': surfaceId, 'widgets': widgetList, 'append': false},
        index: 2,
      ),
      {'type': 'message_stop'},
    ];
  }

  /// Creates a response with nested surfaces.
  static List<Map<String, dynamic>> nestedSurfaceResponse({
    String parentSurfaceId = 'parent',
    String childSurfaceId = 'child',
  }) {
    return [
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-parent',
        {'surfaceId': parentSurfaceId},
        index: 0,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-parent',
        {
          'surfaceId': parentSurfaceId,
          'widgets': [
            {'type': 'Container', 'properties': <String, dynamic>{}},
          ],
          'append': false,
        },
        index: 1,
      ),
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-child',
        {'surfaceId': childSurfaceId, 'parentSurfaceId': parentSurfaceId},
        index: 2,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-child',
        {
          'surfaceId': childSurfaceId,
          'widgets': [
            {'type': 'Text', 'properties': {'text': 'Child content'}},
          ],
          'append': false,
        },
        index: 3,
      ),
      {'type': 'message_stop'},
    ];
  }

  /// Creates a large widget response for stress testing.
  static List<Map<String, dynamic>> largeWidgetResponse({
    String surfaceId = 'main',
    int widgetCount = 50,
  }) {
    final widgets = List.generate(
      widgetCount,
      (i) => {
        'type': 'Text',
        'properties': {'text': 'Widget $i'},
      },
    );

    return [
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-1',
        {'surfaceId': surfaceId},
        index: 0,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-1',
        {'surfaceId': surfaceId, 'widgets': widgets, 'append': false},
        index: 1,
      ),
      {'type': 'message_stop'},
    ];
  }

  /// Creates a complete surface lifecycle: create, update, delete.
  static List<Map<String, dynamic>> surfaceLifecycleResponse({
    String surfaceId = 'lifecycle-surface',
  }) {
    return [
      ..._a2uiToolResponseWithIndex(
        'begin_rendering',
        'tool-br-1',
        {'surfaceId': surfaceId},
        index: 0,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-1',
        {
          'surfaceId': surfaceId,
          'widgets': [
            {'type': 'Text', 'properties': {'text': 'Initial'}},
          ],
          'append': false,
        },
        index: 1,
      ),
      ..._a2uiToolResponseWithIndex(
        'surface_update',
        'tool-su-2',
        {
          'surfaceId': surfaceId,
          'widgets': [
            {'type': 'Text', 'properties': {'text': 'Updated'}},
          ],
          'append': false,
        },
        index: 2,
      ),
      ..._a2uiToolResponseWithIndex(
        'delete_surface',
        'tool-ds-1',
        {'surfaceId': surfaceId, 'cascade': true},
        index: 3,
      ),
      {'type': 'message_stop'},
    ];
  }

  /// Creates an incomplete/malformed response (no message_stop).
  static List<Map<String, dynamic>> incompleteResponse(String text) {
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
      // Intentionally missing content_block_stop and message_stop
    ];
  }

  /// Creates a response with unknown/invalid tool name.
  static List<Map<String, dynamic>> unknownToolResponse({
    String toolName = 'unknown_tool',
    String toolId = 'tool-unknown-1',
    Map<String, dynamic> input = const {},
  }) {
    return _a2uiToolResponse(toolName, toolId, input);
  }

  /// Creates an empty response (only message_stop).
  static List<Map<String, dynamic>> emptyResponse() {
    return [
      {'type': 'message_stop'},
    ];
  }
}
