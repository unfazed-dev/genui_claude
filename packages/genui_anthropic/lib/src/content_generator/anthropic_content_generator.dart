import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/adapter/message_adapter.dart';
import 'package:genui_anthropic/src/config/anthropic_config.dart';

/// A [ContentGenerator] implementation for Anthropic's Claude AI.
///
/// This class provides the bridge between Claude's API and the GenUI SDK,
/// enabling Claude-powered generative UI in Flutter applications.
///
/// Example usage:
/// ```dart
/// final generator = AnthropicContentGenerator(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
/// );
/// ```
class AnthropicContentGenerator implements ContentGenerator {
  /// Creates a content generator for direct Anthropic API access.
  ///
  /// Use this constructor for development and prototyping.
  /// For production, consider using [AnthropicContentGenerator.proxy].
  AnthropicContentGenerator({
    required this.apiKey,
    this.model = 'claude-sonnet-4-20250514',
    this.systemInstruction,
    this.config = AnthropicConfig.defaults,
  })  : proxyEndpoint = null,
        authToken = null,
        proxyConfig = null,
        _isDirectMode = true;

  /// Creates a content generator that uses a backend proxy.
  ///
  /// This is the recommended pattern for production deployments
  /// where the API key should not be exposed to the client.
  AnthropicContentGenerator.proxy({
    required this.proxyEndpoint,
    this.authToken,
    this.proxyConfig = ProxyConfig.defaults,
  })  : apiKey = null,
        model = null,
        systemInstruction = null,
        config = null,
        _isDirectMode = false;

  /// API key for direct mode.
  final String? apiKey;

  /// Model name for direct mode.
  final String? model;

  /// System instruction for direct mode.
  final String? systemInstruction;

  /// Configuration for direct mode.
  final AnthropicConfig? config;

  /// Proxy endpoint URI for proxy mode.
  final Uri? proxyEndpoint;

  /// Auth token for proxy mode.
  final String? authToken;

  /// Configuration for proxy mode.
  final ProxyConfig? proxyConfig;

  final bool _isDirectMode;

  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  final _streamHandler = a2ui.ClaudeStreamHandler();

  /// Whether this generator is in direct API mode.
  bool get isDirectMode => _isDirectMode;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  }) async {
    if (_isProcessing.value) {
      _errorController.add(
        ContentGeneratorError(
          'Request already in progress',
          StackTrace.current,
        ),
      );
      return;
    }

    _isProcessing.value = true;

    try {
      // Convert ChatMessage to text for processing
      final prompt = _extractTextFromMessage(message);

      // Create a mock stream for now - in production this would call the actual API
      // The anthropic_a2ui package provides the parsing infrastructure
      final mockEvents = _createMockStream(prompt);

      await for (final event in _streamHandler.streamRequest(
        messageStream: mockEvents,
      )) {
        switch (event) {
          case a2ui.A2uiMessageEvent(:final message):
            final genUiMessage = A2uiMessageAdapter.toGenUiMessage(message);
            _a2uiController.add(genUiMessage);

          case a2ui.TextDeltaEvent(:final text):
            _textController.add(text);

          case a2ui.ErrorEvent(:final error):
            _errorController.add(
              ContentGeneratorError(error, StackTrace.current),
            );

          case a2ui.DeltaEvent():
            // Raw delta events - can be ignored for most use cases
            break;

          case a2ui.CompleteEvent():
            // Stream complete
            break;
        }
      }
    } on Exception catch (e, stackTrace) {
      _errorController.add(ContentGeneratorError(e, stackTrace));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Extracts text content from a ChatMessage.
  String _extractTextFromMessage(ChatMessage message) {
    if (message is UserMessage) {
      return message.text;
    }
    return message.toString();
  }

  /// Creates a mock event stream for demonstration.
  ///
  /// In a production implementation, this would be replaced with
  /// actual API calls to Claude using anthropic_sdk_dart.
  Stream<Map<String, dynamic>> _createMockStream(String prompt) async* {
    // This is a placeholder - real implementation would use:
    // - anthropic_sdk_dart for direct API calls
    // - HTTP client for proxy mode
    yield {
      'type': 'content_block_start',
      'index': 0,
      'content_block': {'type': 'text'},
    };
    yield {
      'type': 'content_block_delta',
      'index': 0,
      'delta': {'type': 'text_delta', 'text': 'Processing: $prompt'},
    };
    yield {'type': 'message_stop'};
  }

  @override
  void dispose() {
    _a2uiController.close();
    _textController.close();
    _errorController.close();
    _isProcessing.dispose();
    _streamHandler.dispose();
  }
}
