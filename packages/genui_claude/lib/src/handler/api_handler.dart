import 'package:flutter/foundation.dart';

/// Request context for API handlers.
///
/// Contains all the information needed to make an API request to Claude,
/// in a format-agnostic way that both direct and proxy handlers can use.
@immutable
class ApiRequest {
  /// Creates an API request.
  const ApiRequest({
    required this.messages,
    required this.maxTokens,
    this.systemInstruction,
    this.tools,
    this.model,
    this.temperature,
    this.topP,
    this.topK,
    this.stopSequences,
  });

  /// Messages in Claude API format (already converted from ChatMessage).
  ///
  /// Each message is a Map with 'role' and 'content' keys.
  final List<Map<String, dynamic>> messages;

  /// Maximum tokens for the response.
  final int maxTokens;

  /// Optional system prompt/instruction.
  final String? systemInstruction;

  /// Optional tools for the request in Claude API format.
  ///
  /// Each tool has 'name', 'description', and 'input_schema' keys.
  final List<Map<String, dynamic>>? tools;

  /// Model to use (e.g., 'claude-sonnet-4-20250514').
  ///
  /// For direct mode, this determines which model to call.
  /// For proxy mode, this may be forwarded to the backend.
  final String? model;

  /// Temperature setting for response randomness (0.0 to 1.0).
  final double? temperature;

  /// Nucleus sampling parameter (0.0 to 1.0).
  ///
  /// Controls diversity by limiting token selection to a cumulative probability.
  /// Lower values make output more focused, higher values more diverse.
  final double? topP;

  /// Top-k sampling parameter.
  ///
  /// Limits token selection to the k most likely tokens.
  /// Lower values make output more focused.
  final int? topK;

  /// Stop sequences that terminate generation.
  ///
  /// When Claude generates any of these sequences, it stops generating.
  /// Maximum 4 sequences, each up to 100 characters.
  final List<String>? stopSequences;

  @override
  String toString() {
    return 'ApiRequest(messages: ${messages.length}, maxTokens: $maxTokens, '
        'model: $model, hasTools: ${tools != null})';
  }
}

/// Abstract interface for API handlers.
///
/// Handlers are responsible for creating a stream of Claude SSE events
/// in Map format that can be processed by ClaudeStreamHandler.
///
/// The handler pattern allows for different implementations:
/// - DirectModeHandler: Direct API calls using anthropic_sdk_dart
/// - ProxyModeHandler: HTTP calls to a backend proxy
///
/// Example usage:
/// ```dart
/// final handler = DirectModeHandler(apiKey: 'your-api-key');
/// final request = ApiRequest(messages: [...], maxTokens: 4096);
///
/// await for (final event in handler.createStream(request)) {
///   // Process event
/// }
/// ```
abstract class ApiHandler {
  /// Creates a streaming response from the API.
  ///
  /// Returns a stream of raw Claude SSE events as Maps.
  /// The stream emits events in the Claude API format:
  ///
  /// - `{'type': 'content_block_start', 'index': 0, 'content_block': {...}}`
  /// - `{'type': 'content_block_delta', 'index': 0, 'delta': {...}}`
  /// - `{'type': 'content_block_stop', 'index': 0}`
  /// - `{'type': 'message_stop'}`
  /// - `{'type': 'error', 'error': {'message': '...'}}`
  ///
  /// For errors, the stream may either:
  /// - Emit an error event and continue/complete normally
  /// - Throw an exception for fatal errors
  Stream<Map<String, dynamic>> createStream(ApiRequest request);

  /// Disposes any resources held by the handler.
  ///
  /// Call this when the handler is no longer needed to release
  /// HTTP clients, connections, or other resources.
  void dispose();
}
