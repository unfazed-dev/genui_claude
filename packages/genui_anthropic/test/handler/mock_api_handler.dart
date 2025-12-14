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
}
