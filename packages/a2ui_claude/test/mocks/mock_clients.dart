// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:mocktail/mocktail.dart';

/// Mock implementation of an HTTP client for testing Claude API interactions.
///
/// Since the a2ui_claude package is decoupled from the SDK and works with
/// raw JSON maps, this mock provides helpers for simulating API responses
/// at the HTTP level.
///
/// Example:
/// ```dart
/// final mockHttpClient = MockHttpClient();
///
/// // Stub a successful response
/// when(() => mockHttpClient.send(any()))
///     .thenAnswer((_) async => MockStreamedResponse(
///       statusCode: 200,
///       stream: stubStreamResponse([
///         {'type': 'content_block_start', ...},
///         {'type': 'message_stop'},
///       ]),
///     ));
/// ```
class MockHttpClient extends Mock {
  /// Simulates sending an HTTP request.
  Future<MockStreamedResponse> send(dynamic request);
}

/// Mock HTTP response for testing.
class MockStreamedResponse {
  MockStreamedResponse({
    required this.statusCode,
    required this.stream,
    this.headers = const {},
  });

  final int statusCode;
  final Stream<Map<String, dynamic>> stream;
  final Map<String, String> headers;
}

/// Helper to create a stream of events from raw JSON data.
///
/// This simulates the Server-Sent Events (SSE) response from the Claude API.
Stream<Map<String, dynamic>> stubStreamResponse(
  List<Map<String, dynamic>> events,
) {
  return Stream.fromIterable(events);
}

/// Helper to create an error stream that throws after optional events.
///
/// Useful for testing error handling during streaming.
Stream<Map<String, dynamic>> stubErrorStream({
  required Exception error, List<Map<String, dynamic>> eventsBeforeError = const [],
}) async* {
  for (final event in eventsBeforeError) {
    yield event;
  }
  throw error;
}

/// Helper to create a delayed stream for timeout testing.
Stream<Map<String, dynamic>> stubDelayedStream(
  List<Map<String, dynamic>> events, {
  required Duration delayBetweenEvents,
}) async* {
  for (final event in events) {
    await Future<void>.delayed(delayBetweenEvents);
    yield event;
  }
}

/// Mock stream handler for testing stream processing.
class MockStreamHandler extends Mock implements ClaudeStreamHandler {}

/// Mock A2UI parser for testing message parsing.
class MockA2uiParser extends Mock {
  A2uiMessageData? parseToolUse(String toolName, Map<String, dynamic> input);
  ParseResult parseMessage(Map<String, dynamic> message);
}

/// Helper to stub a rate-limited response (429).
MockStreamedResponse stubRateLimitResponse({Duration? retryAfter}) {
  return MockStreamedResponse(
    statusCode: 429,
    stream: const Stream.empty(),
    headers: retryAfter != null
        ? {'Retry-After': retryAfter.inSeconds.toString()}
        : {},
  );
}

/// Helper to stub an authentication error response (401).
MockStreamedResponse stubAuthErrorResponse() {
  return MockStreamedResponse(
    statusCode: 401,
    stream: Stream.value({'error': 'Invalid API key'}),
  );
}

/// Helper to stub a server error response (500).
MockStreamedResponse stubServerErrorResponse() {
  return MockStreamedResponse(
    statusCode: 500,
    stream: Stream.value({'error': 'Internal server error'}),
  );
}

/// Factory for common mock stream event sequences.
abstract final class MockEventSequences {
  /// Creates a basic tool_use stream sequence.
  static List<Map<String, dynamic>> beginRenderingSequence(String surfaceId) => [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'tool_use',
            'id': 'tool_1',
            'name': 'begin_rendering',
            'input': <String, dynamic>{},
          },
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': '{"surfaceId":"$surfaceId"}',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {'type': 'message_stop'},
      ];

  /// Creates a text response stream sequence.
  static List<Map<String, dynamic>> textSequence(String text) => [
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': text},
        },
        {'type': 'content_block_stop', 'index': 0},
        {'type': 'message_stop'},
      ];

  /// Creates a mixed content stream sequence with text and tool_use.
  static List<Map<String, dynamic>> mixedSequence({
    required String text,
    required String surfaceId,
  }) =>
      [
        ...textSequence(text).take(3),
        ...beginRenderingSequence(surfaceId),
      ];
}

/// Register all fake values needed for mocktail.
///
/// Call this in setUpAll() before using mocks.
void registerMockFallbackValues() {
  registerFallbackValue(StreamConfig.defaults);
  registerFallbackValue(<String, dynamic>{});
}
