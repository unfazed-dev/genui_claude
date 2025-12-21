import 'dart:async' as async;

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:genui_claude/src/config/claude_config.dart';
import 'package:genui_claude/src/exceptions/claude_exceptions.dart' as exc;
import 'package:genui_claude/src/handler/api_handler.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:genui_claude/src/resilience/circuit_breaker.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('DirectModeHandler');
const _uuid = Uuid();

/// Handler for direct Claude API access.
///
/// Uses anthropic_sdk_dart to call the Claude API directly.
/// Suitable for development, prototyping, and server-side usage.
///
/// Features:
/// - Request ID tracking for debugging
/// - Structured error handling with categorization
/// - Automatic retry via SDK (configured through ClaudeConfig)
///
/// Example:
/// ```dart
/// final handler = DirectModeHandler(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
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
class DirectModeHandler implements ApiHandler {
  /// Creates a direct mode handler.
  ///
  /// - [apiKey]: Your Claude API key
  /// - [model]: Model to use (default: 'claude-sonnet-4-20250514')
  /// - [config]: Optional configuration for timeouts, retries, etc.
  ///   By default, a circuit breaker is enabled via [ClaudeConfig.circuitBreakerConfig].
  ///   Set [ClaudeConfig.disableCircuitBreaker] to true to opt-out.
  /// - [circuitBreaker]: Optional circuit breaker instance (overrides config)
  /// - [metricsCollector]: Optional metrics collector for observability
  DirectModeHandler({
    required String apiKey,
    this.model = 'claude-sonnet-4-20250514',
    ClaudeConfig config = ClaudeConfig.defaults,
    CircuitBreaker? circuitBreaker,
    MetricsCollector? metricsCollector,
  })  : _client = sdk.AnthropicClient(
          apiKey: apiKey,
          headers: config.headers,
          retries: config.retryAttempts,
        ),
        // Use explicit circuitBreaker if provided, otherwise create from config
        // unless disabled
        _circuitBreaker = circuitBreaker ??
            (config.disableCircuitBreaker
                ? null
                : CircuitBreaker(config: config.circuitBreakerConfig)),
        _metricsCollector = metricsCollector;

  final sdk.AnthropicClient _client;
  final CircuitBreaker? _circuitBreaker;
  final MetricsCollector? _metricsCollector;

  /// The default model to use for requests.
  final String model;

  // coverage:ignore-start
  // NOTE: This method requires a live Claude SDK connection.
  // Testing is done via integration tests with TEST_CLAUDE_API_KEY.
  // Unit tests use MockApiHandler which implements the ApiHandler interface.
  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();
    _log.fine('[Request $requestId] Starting direct API request');

    // Record request start
    _metricsCollector?.recordRequestStart(
      requestId: requestId,
      endpoint: 'api.anthropic.com',
      model: request.model ?? model,
    );

    // Check circuit breaker state
    if (_circuitBreaker != null) {
      try {
        _circuitBreaker.checkState();
      } on exc.CircuitBreakerOpenException catch (e) {
        _log.warning('[Request $requestId] Circuit breaker is open');
        _metricsCollector?.recordRequestFailure(
          requestId: requestId,
          duration: DateTime.now().difference(startTime),
          errorType: e.typeName,
          errorMessage: e.message,
          isRetryable: e.isRetryable,
        );
        yield {
          'type': 'error',
          'error': {
            'message': e.message,
            'type': e.typeName,
            'retryable': e.isRetryable,
          },
          '_requestId': requestId,
        };
        return;
      }
    }

    try {
      // Build the SDK request
      final sdkRequest = sdk.CreateMessageRequest(
        model: sdk.Model.modelId(request.model ?? model),
        messages: _convertMessages(request.messages),
        maxTokens: request.maxTokens,
        system: request.systemInstruction != null
            ? sdk.CreateMessageRequestSystem.text(request.systemInstruction!)
            : null,
        tools: request.tools != null ? _convertTools(request.tools!) : null,
        temperature: request.temperature,
        topP: request.topP,
        topK: request.topK,
        stopSequences: request.stopSequences,
        stream: true,
      );

      // Stream SDK events and convert to Map format
      await for (final event
          in _client.createMessageStream(request: sdkRequest)) {
        final eventMap = _convertEventToMap(event);
        eventMap['_requestId'] = requestId;
        yield eventMap;
      }

      _log.fine('[Request $requestId] Request completed successfully');
      _circuitBreaker?.recordSuccess();
      _metricsCollector?.recordRequestSuccess(
        requestId: requestId,
        duration: DateTime.now().difference(startTime),
      );
    } on Exception catch (e, stackTrace) {
      _log.warning(
          '[Request $requestId] Claude API request failed', e, stackTrace,);
      _circuitBreaker?.recordFailure();

      // Map exception to our exception types based on message content
      final exception = _mapException(e, requestId, stackTrace);

      _metricsCollector?.recordRequestFailure(
        requestId: requestId,
        duration: DateTime.now().difference(startTime),
        errorType: exception.typeName,
        errorMessage: exception.message,
        statusCode: exception.statusCode,
        isRetryable: exception.isRetryable,
      );

      yield {
        'type': 'error',
        'error': {
          'message': exception.message,
          'type': exception.typeName,
          if (exception.statusCode != null) 'http_status': exception.statusCode,
          'retryable': exception.isRetryable,
        },
        '_requestId': requestId,
      };
    }
  }
  // coverage:ignore-end

  // coverage:ignore-start
  // NOTE: These private methods are SDK conversion helpers called only from createStream.
  // They are tested indirectly via integration tests with TEST_CLAUDE_API_KEY.
  // The DirectModeHandler is designed as an SDK wrapper - unit testing individual
  // methods would require mocking SDK types which provides limited value.

  /// Maps exceptions to our exception hierarchy.
  ///
  /// Uses multiple detection strategies for robust error classification:
  /// 1. Check for dart:async TimeoutException
  /// 2. Semantic classification based on error message content
  /// 3. Regex-based status code extraction as fallback
  /// 4. Default to NetworkException for unknown errors
  exc.ClaudeException _mapException(
    Exception e,
    String requestId,
    StackTrace stackTrace,
  ) {
    // 1. Check for dart:async TimeoutException
    if (e is async.TimeoutException) {
      return exc.TimeoutException(
        message: 'Request timed out',
        timeout: e.duration ?? const Duration(seconds: 60),
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    final message = e.toString();
    final messageLower = message.toLowerCase();

    // 2. Semantic classification based on error message content
    // Authentication errors
    if (messageLower.contains('401') ||
        messageLower.contains('unauthorized') ||
        messageLower.contains('invalid api key') ||
        messageLower.contains('invalid_api_key') ||
        messageLower.contains('authentication')) {
      return exc.AuthenticationException(
        message: message,
        statusCode: 401,
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Rate limiting
    if (messageLower.contains('429') ||
        messageLower.contains('rate limit') ||
        messageLower.contains('rate_limit') ||
        messageLower.contains('too many requests')) {
      return exc.RateLimitException(
        message: message,
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Server errors
    if (messageLower.contains('500') ||
        messageLower.contains('502') ||
        messageLower.contains('503') ||
        messageLower.contains('504') ||
        messageLower.contains('internal server error') ||
        messageLower.contains('service unavailable') ||
        messageLower.contains('bad gateway') ||
        messageLower.contains('gateway timeout')) {
      return exc.ServerException(
        message: message,
        statusCode: _extractStatusCode(messageLower) ?? 500,
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Validation errors
    if (messageLower.contains('400') ||
        messageLower.contains('422') ||
        messageLower.contains('invalid') ||
        messageLower.contains('validation')) {
      final extractedCode = _extractStatusCode(messageLower);
      if (extractedCode != null && (extractedCode == 400 || extractedCode == 422)) {
        return exc.ValidationException(
          message: message,
          statusCode: extractedCode,
          requestId: requestId,
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }

    // 3. Fallback: Extract status code with regex
    final statusCode = _extractStatusCode(messageLower);
    if (statusCode != null) {
      return exc.ExceptionFactory.fromHttpStatus(
        statusCode: statusCode,
        body: message,
        requestId: requestId,
      );
    }

    // 4. Network or unknown error
    return exc.NetworkException(
      message: message,
      requestId: requestId,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  /// Extracts HTTP status code from an error message.
  int? _extractStatusCode(String message) {
    final statusMatch =
        RegExp(r'(?:status|code|error)[:\s]*(\d{3})').firstMatch(message);
    if (statusMatch != null) {
      return int.tryParse(statusMatch.group(1) ?? '');
    }
    // Also check for standalone 3-digit codes that look like HTTP status
    final standaloneMatch = RegExp(r'\b([45]\d{2})\b').firstMatch(message);
    if (standaloneMatch != null) {
      return int.tryParse(standaloneMatch.group(1) ?? '');
    }
    return null;
  }

  /// Converts message maps to SDK Message objects.
  List<sdk.Message> _convertMessages(List<Map<String, dynamic>> messages) {
    return messages.map((m) {
      final role = m['role'] as String;
      final content = m['content'];

      return sdk.Message(
        role: role == 'user' ? sdk.MessageRole.user : sdk.MessageRole.assistant,
        content: _convertContent(content),
      );
    }).toList();
  }

  /// Converts content to SDK MessageContent.
  sdk.MessageContent _convertContent(dynamic content) {
    if (content is String) {
      return sdk.MessageContent.text(content);
    }
    if (content is List) {
      return sdk.MessageContent.blocks(
        content.map<sdk.Block>(_convertBlock).toList(),
      );
    }
    throw ArgumentError('Invalid content type: ${content.runtimeType}');
  }

  /// Converts a content block map to SDK Block.
  sdk.Block _convertBlock(dynamic block) {
    final map = block as Map<String, dynamic>;
    final type = map['type'] as String;

    switch (type) {
      case 'text':
        return sdk.Block.text(text: map['text'] as String);
      case 'image':
        final source = map['source'] as Map<String, dynamic>;
        return sdk.Block.image(
          source: sdk.ImageBlockSource.base64ImageSource(
            type: 'base64',
            mediaType: _parseMediaType(source['media_type'] as String),
            data: source['data'] as String,
          ),
        );
      case 'tool_use':
        return sdk.Block.toolUse(
          id: map['id'] as String,
          name: map['name'] as String,
          input: map['input'] as Map<String, dynamic>,
        );
      case 'tool_result':
        return sdk.Block.toolResult(
          toolUseId: map['tool_use_id'] as String,
          content: sdk.ToolResultBlockContent.text(
            _extractToolResultContent(map['content']),
          ),
          isError: map['is_error'] as bool?,
        );
      default:
        throw ArgumentError('Unknown block type: $type');
    }
  }

  /// Extracts text content from tool result content.
  String _extractToolResultContent(dynamic content) {
    if (content is String) return content;
    if (content is List && content.isNotEmpty) {
      final first = content.first as Map<String, dynamic>;
      if (first['type'] == 'text') {
        return first['text'] as String;
      }
    }
    return content.toString();
  }

  /// Parses a media type string to the SDK enum.
  sdk.Base64ImageSourceMediaType _parseMediaType(String mediaType) {
    return switch (mediaType) {
      'image/jpeg' => sdk.Base64ImageSourceMediaType.imageJpeg,
      'image/png' => sdk.Base64ImageSourceMediaType.imagePng,
      'image/gif' => sdk.Base64ImageSourceMediaType.imageGif,
      'image/webp' => sdk.Base64ImageSourceMediaType.imageWebp,
      _ => sdk.Base64ImageSourceMediaType.imagePng, // Default fallback
    };
  }

  /// Converts tool maps to SDK Tool objects.
  List<sdk.Tool> _convertTools(List<Map<String, dynamic>> tools) {
    return tools.map((t) {
      return sdk.Tool.custom(
        name: t['name'] as String,
        description: t['description'] as String?,
        inputSchema: t['input_schema'] as Map<String, dynamic>,
      );
    }).toList();
  }

  /// Converts SDK MessageStreamEvent to the Map format expected by ClaudeStreamHandler.
  Map<String, dynamic> _convertEventToMap(sdk.MessageStreamEvent event) {
    return switch (event) {
      sdk.MessageStartEvent(:final message) => {
          'type': 'message_start',
          'message': message.toJson(),
        },
      sdk.MessageDeltaEvent(:final delta, :final usage) => {
          'type': 'message_delta',
          'delta': delta.toJson(),
          'usage': usage.toJson(),
        },
      sdk.MessageStopEvent() => {
          'type': 'message_stop',
        },
      sdk.ContentBlockStartEvent(:final contentBlock, :final index) => {
          'type': 'content_block_start',
          'index': index,
          'content_block': contentBlock.toJson(),
        },
      sdk.ContentBlockDeltaEvent(:final delta, :final index) => {
          'type': 'content_block_delta',
          'index': index,
          'delta': delta.toJson(),
        },
      sdk.ContentBlockStopEvent(:final index) => {
          'type': 'content_block_stop',
          'index': index,
        },
      sdk.PingEvent() => {
          'type': 'ping',
        },
      sdk.ErrorEvent(:final error) => {
          'type': 'error',
          'error': {'message': error.message},
        },
    };
  }
  // coverage:ignore-end

  @override
  void dispose() {
    // AnthropicClient from anthropic_sdk_dart manages its own HTTP lifecycle
    // and doesn't expose a close() method. The underlying HTTP client is
    // managed internally by the SDK.
    _log.fine('DirectModeHandler disposed');
  }
}
