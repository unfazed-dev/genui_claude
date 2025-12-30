import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart' as a2ui;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/src/adapter/message_adapter.dart';
import 'package:genui_claude/src/config/claude_config.dart';
import 'package:genui_claude/src/handler/api_handler.dart';
import 'package:genui_claude/src/models/thinking_content.dart';
import 'package:genui_claude/src/handler/direct_mode_handler.dart';
import 'package:genui_claude/src/handler/proxy_mode_handler.dart';
import 'package:genui_claude/src/search/tool_use_interceptor.dart';
import 'package:genui_claude/src/utils/message_converter.dart';

/// A [ContentGenerator] implementation for Claude AI.
///
/// This class provides the bridge between Claude's API and the GenUI SDK,
/// enabling Claude-powered generative UI in Flutter applications.
///
/// Example usage:
/// ```dart
/// final generator = ClaudeContentGenerator(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
/// );
/// ```
class ClaudeContentGenerator implements ContentGenerator {
  /// Creates a content generator for direct Claude API access.
  ///
  /// Use this constructor for development and prototyping.
  /// For production, consider using [ClaudeContentGenerator.proxy].
  ///
  /// - [tools]: Optional list of tools to make available to Claude.
  /// - [toolInterceptor]: Optional interceptor for handling tool calls locally
  ///   (e.g., for search_catalog and load_tools with tool search enabled).
  ClaudeContentGenerator({
    required String apiKey,
    String model = 'claude-sonnet-4-20250514',
    this.systemInstruction,
    this.tools,
    this.toolInterceptor,
    ClaudeConfig config = ClaudeConfig.defaults,
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
  ///
  /// - [authToken]: Optional static auth token (sent as Bearer token).
  /// - [authTokenProvider]: Optional callback to get fresh token for each request.
  ///   When provided, this is preferred over [authToken]. Use this when the token
  ///   may change during the session (e.g., automatic refresh by Supabase).
  ClaudeContentGenerator.proxy({
    required Uri proxyEndpoint,
    String? authToken,
    TokenProvider? authTokenProvider,
    ProxyConfig proxyConfig = ProxyConfig.defaults,
    this.tools,
    this.toolInterceptor,
  })  : _handler = ProxyModeHandler(
          endpoint: proxyEndpoint,
          authToken: authToken,
          authTokenProvider: authTokenProvider,
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
  ClaudeContentGenerator.withHandler({
    required ApiHandler handler,
    String? model,
    this.systemInstruction,
    this.tools,
    this.toolInterceptor,
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

  /// Optional tools to make available to Claude.
  ///
  /// These are passed to the API as available tool definitions.
  /// When Claude calls a tool, the result needs to be handled by the consumer.
  final List<Map<String, dynamic>>? tools;

  /// Optional interceptor for handling certain tool calls locally.
  ///
  /// When provided, tool calls that match [ToolUseInterceptor.shouldIntercept]
  /// can be processed locally without sending to the API. This is used for
  /// search_catalog and load_tools when tool search is enabled.
  ///
  /// Note: Full automatic tool interception requires implementing a
  /// conversation loop. Currently, this is provided for advanced use cases.
  final ToolUseInterceptor? toolInterceptor;

  /// Configuration for direct mode.
  final ClaudeConfig? _config;

  final bool _isDirectMode;

  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _thinkingController = StreamController<ThinkingContent>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  final _streamHandler = a2ui.ClaudeStreamHandler();

  /// Whether this generator is in direct API mode.
  bool get isDirectMode => _isDirectMode;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  /// Stream of thinking content from Claude's extended thinking feature.
  ///
  /// Emits [ThinkingContent] objects as Claude's reasoning is streamed.
  /// Use this to display Claude's thought process in the UI when
  /// interleaved thinking is enabled.
  Stream<ThinkingContent> get thinkingStream => _thinkingController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    // coverage:ignore-start
    // NOTE: Race condition guard - difficult to trigger in tests as it requires
    // concurrent calls that aren't guaranteed to interleave deterministically.
    if (_isProcessing.value) {
      _errorController.add(
        ContentGeneratorError(
          'Request already in progress',
          StackTrace.current,
        ),
      );
      return;
    }
    // coverage:ignore-end

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
        tools: tools,
        topP: _config?.topP,
        topK: _config?.topK,
        stopSequences: _config?.stopSequences,
      );

      // Get stream from handler
      final eventStream = _handler.createStream(request);

      // Process through ClaudeStreamHandler
      await for (final event in _streamHandler.streamRequest(
        messageStream: eventStream,
      )) {
        switch (event) {
          // coverage:ignore-start
          // NOTE: A2uiMessageEvent handling requires mock stream handler setup
          // that returns A2UI widget events. Covered by integration tests.
          case a2ui.A2uiMessageEvent(:final message):
            final genUiMessage = A2uiMessageAdapter.toGenUiMessage(message);
            _a2uiController.add(genUiMessage);
          // coverage:ignore-end

          case a2ui.TextDeltaEvent(:final text):
            _textController.add(text);

          // coverage:ignore-start
          // NOTE: ErrorEvent handling from stream - requires API-level errors
          // that are not reliably triggered in unit tests.
          case a2ui.ErrorEvent(:final error):
            _errorController.add(
              ContentGeneratorError(error, StackTrace.current),
            );
          // coverage:ignore-end

          case a2ui.DeltaEvent():
            // Raw delta events - can be ignored for most use cases
            break;

          case a2ui.CompleteEvent():
            // Stream complete
            break;

          case a2ui.ThinkingEvent(:final content, :final isComplete):
            // Emit thinking content for UI display
            _thinkingController.add(ThinkingContent(
              content: content,
              isComplete: isComplete,
            ));
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
    _thinkingController.close();
    _errorController.close();
    _isProcessing.dispose();
    _streamHandler.dispose();
  }
}
