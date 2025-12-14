import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A mock HTTP server that simulates a Claude proxy backend.
///
/// Used for testing proxy mode without requiring a real backend.
/// Supports SSE (Server-Sent Events) streaming responses.
class MockProxyServer {
  HttpServer? _server;
  Uri? _endpoint;

  /// Stubbed responses to return.
  final _responses = <MockProxyResponse>[];

  /// Recorded requests for verification.
  final _recordedRequests = <RecordedRequest>[];

  /// The endpoint URI for this mock server.
  Uri? get endpoint => _endpoint;

  /// All recorded requests.
  List<RecordedRequest> get recordedRequests =>
      List.unmodifiable(_recordedRequests);

  /// The last recorded request.
  RecordedRequest? get lastRequest =>
      _recordedRequests.isEmpty ? null : _recordedRequests.last;

  /// Starts the mock server on a random available port.
  Future<Uri> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _endpoint = Uri.parse('http://localhost:${_server!.port}/api/chat');

    _server!.listen(_handleRequest);

    return _endpoint!;
  }

  /// Stops the mock server.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _endpoint = null;
  }

  /// Adds a stubbed response.
  void stubResponse(MockProxyResponse response) {
    _responses.add(response);
  }

  /// Clears all stubbed responses.
  void clearResponses() {
    _responses.clear();
  }

  /// Clears all recorded requests.
  void clearRecordedRequests() {
    _recordedRequests.clear();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Parse request body
    final bodyString = await utf8.decodeStream(request);
    final body = jsonDecode(bodyString) as Map<String, dynamic>;

    // Extract auth header
    final authHeader = request.headers.value('Authorization');

    // Extract headers
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });

    // Record the request
    _recordedRequests.add(
      RecordedRequest(
        method: request.method,
        path: request.uri.path,
        headers: headers,
        body: body,
        authToken: authHeader?.replaceFirst('Bearer ', ''),
      ),
    );

    // Find matching response
    final response = _findResponse(body, authHeader);

    // Handle error responses
    if (response.statusCode != 200) {
      request.response.statusCode = response.statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'type': 'error',
          'error': {'message': response.errorMessage ?? 'Error'},
        }),
      );
      await request.response.close();
      return;
    }

    // Send SSE response
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.headers.add('Cache-Control', 'no-cache');
    request.response.headers.add('Connection', 'keep-alive');

    for (final event in response.sseEvents) {
      request.response.write('data: ${jsonEncode(event)}\n\n');
      // Small delay to simulate streaming
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    await request.response.close();
  }

  MockProxyResponse _findResponse(
    Map<String, dynamic> body,
    String? authHeader,
  ) {
    // Check for auth-required responses first
    for (final response in _responses) {
      if (response.requiresAuth && authHeader == null) {
        continue;
      }
      if (response.matches(body, authHeader)) {
        return response;
      }
    }

    // Return default response
    return MockProxyResponse.textResponse('Default mock response');
  }
}

/// A stubbed response for the mock proxy server.
class MockProxyResponse {
  MockProxyResponse({
    required this.sseEvents,
    this.messageContains,
    this.requiresAuth = false,
    this.statusCode = 200,
    this.errorMessage,
  });

  /// Creates a simple text response.
  factory MockProxyResponse.textResponse(String text) {
    return MockProxyResponse(
      sseEvents: [
        {
          'type': 'message_start',
          'message': {
            'id': 'msg_mock',
            'type': 'message',
            'role': 'assistant',
            'content': <dynamic>[],
            'model': 'claude-mock',
            'stop_reason': null,
            'stop_sequence': null,
            'usage': {'input_tokens': 10, 'output_tokens': 10},
          },
        },
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
        {
          'type': 'message_delta',
          'delta': {'stop_reason': 'end_turn', 'stop_sequence': null},
          'usage': {'output_tokens': 10},
        },
        {'type': 'message_stop'},
      ],
    );
  }

  /// Creates an error response.
  factory MockProxyResponse.error({
    int statusCode = 500,
    String message = 'Internal server error',
  }) {
    return MockProxyResponse(
      sseEvents: [],
      statusCode: statusCode,
      errorMessage: message,
    );
  }

  /// Creates an unauthorized response.
  factory MockProxyResponse.unauthorized() {
    return MockProxyResponse.error(
      statusCode: 401,
      message: 'Unauthorized',
    );
  }

  /// Message content to match (optional).
  final String? messageContains;

  /// Whether this response requires an auth token.
  final bool requiresAuth;

  /// SSE events to stream.
  final List<Map<String, dynamic>> sseEvents;

  /// HTTP status code.
  final int statusCode;

  /// Error message for non-200 responses.
  final String? errorMessage;

  /// Checks if this response matches the request.
  bool matches(Map<String, dynamic> body, String? authHeader) {
    if (requiresAuth && authHeader == null) return false;
    if (messageContains == null) return true;

    final messages = body['messages'] as List<dynamic>?;
    if (messages == null) return false;

    for (final msg in messages) {
      final content = (msg as Map<String, dynamic>)['content'];
      if (content is String && content.contains(messageContains!)) {
        return true;
      }
      // Handle array content blocks
      if (content is List) {
        for (final block in content) {
          if (block is Map && block['type'] == 'text') {
            final text = block['text'] as String?;
            if (text != null && text.contains(messageContains!)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }
}

/// A recorded HTTP request for verification.
class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
    this.authToken,
  });

  /// HTTP method (GET, POST, etc.).
  final String method;

  /// Request path.
  final String path;

  /// Request headers.
  final Map<String, String> headers;

  /// Parsed request body.
  final Map<String, dynamic> body;

  /// Extracted auth token (if present).
  final String? authToken;

  /// Gets the messages from the request body.
  List<dynamic>? get messages => body['messages'] as List<dynamic>?;

  /// Gets the max_tokens from the request body.
  int? get maxTokens => body['max_tokens'] as int?;

  /// Gets the model from the request body.
  String? get model => body['model'] as String?;

  /// Gets the system instruction from the request body.
  String? get system => body['system'] as String?;
}
