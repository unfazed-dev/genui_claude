import 'dart:async';
import 'dart:convert';

import 'package:genui_anthropic/src/config/anthropic_config.dart';
import 'package:genui_anthropic/src/handler/api_handler.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _log = Logger('ProxyModeHandler');

/// Handler for backend proxy API access.
///
/// Sends requests to a backend proxy that handles Claude API calls,
/// keeping the API key secure on the server.
///
/// The proxy should:
/// 1. Accept requests in Claude API format
/// 2. Add the API key server-side
/// 3. Forward to Claude API
/// 4. Stream SSE responses back unchanged
///
/// Example:
/// ```dart
/// final handler = ProxyModeHandler(
///   endpoint: Uri.parse('https://your-server.com/api/chat'),
///   authToken: 'user-jwt-token',
/// );
///
/// final request = ApiRequest(
///   messages: [{'role': 'user', 'content': 'Hello!'}],
///   maxTokens: 4096,
/// );
///
/// await for (final event in handler.createStream(request)) {
///   print(event);
/// }
/// ```
class ProxyModeHandler implements ApiHandler {
  /// Creates a proxy mode handler.
  ///
  /// - [endpoint]: The backend proxy URL
  /// - [authToken]: Optional auth token (sent as Bearer token)
  /// - [config]: Optional configuration for timeouts, retries, headers
  /// - [client]: Optional HTTP client for testing/customization
  ProxyModeHandler({
    required Uri endpoint,
    String? authToken,
    ProxyConfig config = ProxyConfig.defaults,
    http.Client? client,
  })  : _endpoint = endpoint,
        _authToken = authToken,
        _config = config,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri _endpoint;
  final String? _authToken;
  final ProxyConfig _config;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    try {
      // Build request body for the proxy
      final requestBody = _buildRequestBody(request);

      // Create HTTP request
      final httpRequest = http.Request('POST', _endpoint);
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        ..._config.headers ?? {},
      });
      httpRequest.body = jsonEncode(requestBody);

      // Send request and get streamed response
      final response = await _client
          .send(httpRequest)
          .timeout(_config.timeout);

      // Check for HTTP errors
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _log.warning('HTTP error ${response.statusCode}: $body');
        yield {
          'type': 'error',
          'error': {
            'message': 'HTTP ${response.statusCode}: $body',
            'http_status': response.statusCode,
          },
        };
        return;
      }

      // Parse SSE stream
      yield* _parseSSEStream(response.stream);
    } on TimeoutException catch (e, stackTrace) {
      _log.warning('Request timed out after ${_config.timeout}', e, stackTrace);
      yield {
        'type': 'error',
        'error': {'message': 'Request timed out after ${_config.timeout}'},
      };
    } on Exception catch (e, stackTrace) {
      _log.warning('Request failed', e, stackTrace);
      yield {
        'type': 'error',
        'error': {'message': e.toString()},
      };
    }
  }

  /// Builds the request body to send to the proxy.
  ///
  /// The proxy is expected to understand this format and forward
  /// appropriately to Claude API.
  Map<String, dynamic> _buildRequestBody(ApiRequest request) {
    return {
      'messages': request.messages,
      'max_tokens': request.maxTokens,
      if (request.systemInstruction != null) 'system': request.systemInstruction,
      if (request.tools != null) 'tools': request.tools,
      if (request.model != null) 'model': request.model,
      if (request.temperature != null) 'temperature': request.temperature,
      'stream': true,
    };
  }

  /// Parses SSE stream from HTTP response into Map events.
  Stream<Map<String, dynamic>> _parseSSEStream(
    http.ByteStream stream,
  ) async* {
    final lines = stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (line.isEmpty) continue;

      // SSE format: "data: {...json...}"
      if (line.startsWith('data:')) {
        final data = line.substring(5).trim();

        // Skip [DONE] marker (OpenAI-style) or empty data
        if (data == '[DONE]' || data.isEmpty) continue;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          yield json;
        } on FormatException catch (e, stackTrace) {
          _log.warning('Failed to parse SSE data: $data', e, stackTrace);
          yield {
            'type': 'error',
            'error': {'message': 'Failed to parse SSE data: $e'},
          };
        }
      }
    }
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
