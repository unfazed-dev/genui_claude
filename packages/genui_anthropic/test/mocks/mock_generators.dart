import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

/// Mock implementation of [AnthropicContentGenerator] for testing.
///
/// Provides controllable streams for testing UI behavior without
/// requiring actual API calls.
class MockAnthropicContentGenerator implements ContentGenerator {
  MockAnthropicContentGenerator();

  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  Stream<String> get textResponseStream => _textController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  /// Simulates sending a request and emitting predefined responses.
  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
  }) async {
    _isProcessing.value = true;

    try {
      // Emit any queued responses
      for (final event in _queuedEvents) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        switch (event) {
          case _A2uiEvent(:final message):
            _a2uiController.add(message);
          case _TextEvent(:final text):
            _textController.add(text);
          case _ErrorEvent(:final error):
            _errorController.add(error);
        }
      }
      _queuedEvents.clear();
    } finally {
      _isProcessing.value = false;
    }
  }

  final _queuedEvents = <_MockEvent>[];

  /// Queue an A2UI message to be emitted on next sendRequest.
  void stubA2uiMessage(A2uiMessage message) {
    _queuedEvents.add(_A2uiEvent(message));
  }

  /// Queue multiple A2UI messages.
  void stubA2uiMessages(List<A2uiMessage> messages) {
    _queuedEvents.addAll(messages.map(_A2uiEvent.new));
  }

  /// Queue a text response.
  void stubTextResponse(String text) {
    _queuedEvents.add(_TextEvent(text));
  }

  /// Queue multiple text chunks.
  void stubTextResponses(List<String> texts) {
    _queuedEvents.addAll(texts.map(_TextEvent.new));
  }

  /// Queue an error.
  void stubError(ContentGeneratorError error) {
    _queuedEvents.add(_ErrorEvent(error));
  }

  /// Directly emit an A2UI message (without calling sendRequest).
  void emitA2uiMessage(A2uiMessage message) {
    _a2uiController.add(message);
  }

  /// Directly emit a text chunk.
  void emitText(String text) {
    _textController.add(text);
  }

  /// Directly emit an error.
  void emitError(ContentGeneratorError error) {
    _errorController.add(error);
  }

  /// Set processing state directly.
  void setProcessing(bool value) {
    _isProcessing.value = value;
  }

  @override
  void dispose() {
    _a2uiController.close();
    _textController.close();
    _errorController.close();
    _isProcessing.dispose();
  }
}

sealed class _MockEvent {}

class _A2uiEvent extends _MockEvent {
  _A2uiEvent(this.message);
  final A2uiMessage message;
}

class _TextEvent extends _MockEvent {
  _TextEvent(this.text);
  final String text;
}

class _ErrorEvent extends _MockEvent {
  _ErrorEvent(this.error);
  final ContentGeneratorError error;
}

/// Factory for creating mock A2UI message data.
class MockA2uiMessageFactory {
  MockA2uiMessageFactory._();

  /// Creates a BeginRenderingData for testing.
  static a2ui.BeginRenderingData beginRendering({
    String surfaceId = 'test-surface',
    Map<String, dynamic>? metadata,
  }) {
    return a2ui.BeginRenderingData(
      surfaceId: surfaceId,
      metadata: metadata,
    );
  }

  /// Creates a SurfaceUpdateData for testing.
  static a2ui.SurfaceUpdateData surfaceUpdate({
    String surfaceId = 'test-surface',
    List<a2ui.WidgetNode>? widgets,
  }) {
    return a2ui.SurfaceUpdateData(
      surfaceId: surfaceId,
      widgets: widgets ?? [],
    );
  }

  /// Creates a SurfaceUpdateData with a text widget.
  static a2ui.SurfaceUpdateData textWidget({
    String surfaceId = 'test-surface',
    String text = 'Test text',
  }) {
    return a2ui.SurfaceUpdateData(
      surfaceId: surfaceId,
      widgets: [
        a2ui.WidgetNode(
          type: 'text',
          properties: {'text': text},
        ),
      ],
    );
  }

  /// Creates a SurfaceUpdateData with a button widget.
  static a2ui.SurfaceUpdateData buttonWidget({
    String surfaceId = 'test-surface',
    String label = 'Click me',
    bool enabled = true,
  }) {
    return a2ui.SurfaceUpdateData(
      surfaceId: surfaceId,
      widgets: [
        a2ui.WidgetNode(
          type: 'button',
          properties: {'label': label, 'enabled': enabled},
        ),
      ],
    );
  }

  /// Creates a DataModelUpdateData for testing.
  static a2ui.DataModelUpdateData dataModelUpdate({
    Map<String, dynamic>? updates,
    String? scope,
  }) {
    return a2ui.DataModelUpdateData(
      updates: updates ?? {},
      scope: scope,
    );
  }

  /// Creates a DeleteSurfaceData for testing.
  static a2ui.DeleteSurfaceData deleteSurface({
    String surfaceId = 'test-surface',
  }) {
    return a2ui.DeleteSurfaceData(surfaceId: surfaceId);
  }
}

/// Factory for creating mock GenUI A2uiMessage objects.
class MockGenUiMessageFactory {
  MockGenUiMessageFactory._();

  /// Creates a BeginRendering message.
  static BeginRendering beginRendering({
    String surfaceId = 'test-surface',
    String root = 'root',
    Map<String, dynamic>? styles,
  }) {
    return BeginRendering(
      surfaceId: surfaceId,
      root: root,
      styles: styles,
    );
  }

  /// Creates a SurfaceUpdate message.
  static SurfaceUpdate surfaceUpdate({
    String surfaceId = 'test-surface',
    List<Component>? components,
  }) {
    return SurfaceUpdate(
      surfaceId: surfaceId,
      components: components ?? [],
    );
  }

  /// Creates a SurfaceUpdate with a single text component.
  static SurfaceUpdate textComponent({
    String surfaceId = 'test-surface',
    String text = 'Test text',
  }) {
    return SurfaceUpdate(
      surfaceId: surfaceId,
      components: [
        Component(id: 'text', componentProperties: {'text': text}),
      ],
    );
  }

  /// Creates a DataModelUpdate message.
  static DataModelUpdate dataModelUpdate({
    String surfaceId = 'default',
    Object? contents,
  }) {
    return DataModelUpdate(
      surfaceId: surfaceId,
      contents: contents ?? <String, dynamic>{},
    );
  }

  /// Creates a SurfaceDeletion message.
  static SurfaceDeletion surfaceDeletion({
    String surfaceId = 'test-surface',
  }) {
    return SurfaceDeletion(surfaceId: surfaceId);
  }
}

/// Factory for creating mock ChatMessage objects.
class MockChatMessageFactory {
  MockChatMessageFactory._();

  /// Creates a simple user text message.
  static UserMessage userText(String text) {
    return UserMessage.text(text);
  }

  /// Creates a user message with multiple text parts.
  static UserMessage userMultiText(List<String> texts) {
    return UserMessage(texts.map(TextPart.new).toList());
  }

  /// Creates a simple AI text message.
  static AiTextMessage aiText(String text) {
    return AiTextMessage.text(text);
  }

  /// Creates an AI message with tool calls.
  static AiTextMessage aiWithToolCalls(List<ToolCallPart> toolCalls) {
    return AiTextMessage(toolCalls);
  }

  /// Creates a tool response message.
  static ToolResponseMessage toolResponse(
    String callId,
    String result,
  ) {
    return ToolResponseMessage([
      ToolResultPart(callId: callId, result: result),
    ]);
  }

  /// Creates an internal context message.
  static InternalMessage internal(String text) {
    return InternalMessage(text);
  }
}

/// Factory for creating mock stream events.
class MockStreamEventFactory {
  MockStreamEventFactory._();

  /// Creates a content_block_start event for text.
  static Map<String, dynamic> textBlockStart({int index = 0}) {
    return {
      'type': 'content_block_start',
      'index': index,
      'content_block': {'type': 'text'},
    };
  }

  /// Creates a content_block_delta event for text.
  static Map<String, dynamic> textDelta(String text, {int index = 0}) {
    return {
      'type': 'content_block_delta',
      'index': index,
      'delta': {'type': 'text_delta', 'text': text},
    };
  }

  /// Creates a content_block_start event for tool_use.
  static Map<String, dynamic> toolUseStart({
    int index = 0,
    required String id,
    required String name,
  }) {
    return {
      'type': 'content_block_start',
      'index': index,
      'content_block': {
        'type': 'tool_use',
        'id': id,
        'name': name,
      },
    };
  }

  /// Creates a content_block_delta event for tool_use input.
  static Map<String, dynamic> toolUseDelta(String json, {int index = 0}) {
    return {
      'type': 'content_block_delta',
      'index': index,
      'delta': {'type': 'input_json_delta', 'partial_json': json},
    };
  }

  /// Creates a content_block_stop event.
  static Map<String, dynamic> blockStop({int index = 0}) {
    return {
      'type': 'content_block_stop',
      'index': index,
    };
  }

  /// Creates a message_stop event.
  static Map<String, dynamic> messageStop() {
    return {'type': 'message_stop'};
  }

  /// Creates a complete sequence for a simple text response.
  static List<Map<String, dynamic>> simpleTextResponse(String text) {
    return [
      textBlockStart(),
      textDelta(text),
      blockStop(),
      messageStop(),
    ];
  }

  /// Creates a complete sequence for a begin_rendering tool call.
  static List<Map<String, dynamic>> beginRenderingCall({
    String id = 'call_1',
    String surfaceId = 'main',
  }) {
    return [
      toolUseStart(id: id, name: 'begin_rendering'),
      toolUseDelta('{"surfaceId": "$surfaceId"}'),
      blockStop(),
      messageStop(),
    ];
  }

  /// Creates a complete sequence for a surface_update tool call.
  static List<Map<String, dynamic>> surfaceUpdateCall({
    String id = 'call_2',
    String surfaceId = 'main',
    String widgetType = 'text',
    Map<String, dynamic>? widgetProps,
  }) {
    final props = widgetProps ?? {'text': 'Hello'};
    return [
      toolUseStart(id: id, name: 'surface_update'),
      toolUseDelta(
        '{"surfaceId": "$surfaceId", '
        '"widgets": [{"type": "$widgetType", "properties": $props}]}',
      ),
      blockStop(),
      messageStop(),
    ];
  }
}
