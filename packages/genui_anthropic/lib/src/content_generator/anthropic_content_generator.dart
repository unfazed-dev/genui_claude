import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/adapter/message_adapter.dart';
import 'package:genui_anthropic/src/config/anthropic_config.dart';
import 'package:genui_anthropic/src/handler/api_handler.dart';
import 'package:genui_anthropic/src/handler/direct_mode_handler.dart';
import 'package:genui_anthropic/src/handler/proxy_mode_handler.dart';
import 'package:genui_anthropic/src/utils/message_converter.dart';

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
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    this.systemInstruction,
    AnthropicConfig config = AnthropicConfig.defaults,
  })  : _handler = DirectModeHandler(
          apiKey: apiKey,
          model: model,
          config: config,
        ),
        _model = model,
        _config = config,
        _isDirectMode = true;

  /// Creates a content generator that uses a backend proxy.
  ///
  /// This is the recommended pattern for production deployments
  /// where the API key should not be exposed to the client.
  AnthropicContentGenerator.proxy({
    required Uri proxyEndpoint,
    String? authToken,
    ProxyConfig proxyConfig = ProxyConfig.defaults,
  })  : _handler = ProxyModeHandler(
          endpoint: proxyEndpoint,
          authToken: authToken,
          config: proxyConfig,
        ),
        _model = null,
        _config = null,
        systemInstruction = null,
        _isDirectMode = false;

  /// Creates a content generator with a custom handler.
  ///
  /// This factory is intended for testing and advanced use cases
  /// where you need to provide a custom [ApiHandler] implementation.
  @visibleForTesting
  AnthropicContentGenerator.withHandler({
    required ApiHandler handler,
    String? model,
    this.systemInstruction,
  })  : _handler = handler,
        _model = model,
        _config = null,
        _isDirectMode = true;

  /// The API handler for making requests.
  final ApiHandler _handler;

  /// Model name for requests.
  final String? _model;

  /// System instruction for requests.
  final String? systemInstruction;

  /// Configuration for direct mode.
  final AnthropicConfig? _config;

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
      // Convert messages to Claude API format
      final allMessages = [...?history, message];
      final claudeMessages = MessageConverter.toClaudeMessages(allMessages);

      // Build API request
      final request = ApiRequest(
        messages: claudeMessages,
        maxTokens: _config?.maxTokens ?? 4096,
        systemInstruction: systemInstruction,
        model: _model,
      );

      // Get stream from handler
      final eventStream = _handler.createStream(request);

      // Process through ClaudeStreamHandler
      await for (final event in _streamHandler.streamRequest(
        messageStream: eventStream,
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

  @override
  void dispose() {
    _handler.dispose();
    _a2uiController.close();
    _textController.close();
    _errorController.close();
    _isProcessing.dispose();
    _streamHandler.dispose();
  }
}
