import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:genui_anthropic/src/config/anthropic_config.dart';
import 'package:genui_anthropic/src/handler/api_handler.dart';
import 'package:logging/logging.dart';

final _log = Logger('DirectModeHandler');

/// Handler for direct Anthropic API access.
///
/// Uses anthropic_sdk_dart to call the Claude API directly.
/// Suitable for development, prototyping, and server-side usage.
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
  /// - [apiKey]: Your Anthropic API key
  /// - [model]: Model to use (default: 'claude-sonnet-4-20250514')
  /// - [config]: Optional configuration for timeouts, retries, etc.
  DirectModeHandler({
    required String apiKey,
    this.model = 'claude-sonnet-4-20250514',
    AnthropicConfig config = AnthropicConfig.defaults,
  }) : _client = sdk.AnthropicClient(
          apiKey: apiKey,
          headers: config.headers,
          retries: config.retryAttempts,
        );

  final sdk.AnthropicClient _client;

  /// The default model to use for requests.
  final String model;

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
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
        stream: true,
      );

      // Stream SDK events and convert to Map format
      await for (final event in _client.createMessageStream(request: sdkRequest)) {
        yield _convertEventToMap(event);
      }
    } on Exception catch (e, stackTrace) {
      _log.warning('Claude API request failed', e, stackTrace);
      yield {
        'type': 'error',
        'error': {'message': e.toString()},
      };
    }
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
          source: sdk.ImageBlockSource(
            type: sdk.ImageBlockSourceType.base64,
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
  sdk.ImageBlockSourceMediaType _parseMediaType(String mediaType) {
    return switch (mediaType) {
      'image/jpeg' => sdk.ImageBlockSourceMediaType.imageJpeg,
      'image/png' => sdk.ImageBlockSourceMediaType.imagePng,
      'image/gif' => sdk.ImageBlockSourceMediaType.imageGif,
      'image/webp' => sdk.ImageBlockSourceMediaType.imageWebp,
      _ => sdk.ImageBlockSourceMediaType.imagePng, // Default fallback
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

  @override
  void dispose() {
    // AnthropicClient from anthropic_sdk_dart manages its own HTTP lifecycle
    // and doesn't expose a close() method. The underlying HTTP client is
    // managed internally by the SDK.
    _log.fine('DirectModeHandler disposed');
  }
}
