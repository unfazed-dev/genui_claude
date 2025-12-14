import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart' as a2ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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
  // ignore: avoid_positional_boolean_parameters, use_setters_to_change_properties
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
    required String id, required String name, int index = 0,
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

/// Mock implementation of [a2ui.ClaudeStreamHandler] for testing.
///
/// Provides controllable stream output without actual API calls.
class MockClaudeStreamHandler {
  MockClaudeStreamHandler({this.config = a2ui.StreamConfig.defaults});

  final a2ui.StreamConfig config;

  final _queuedEvents = <a2ui.StreamEvent>[];

  /// Queue events to be emitted on next streamRequest.
  void stubEvents(List<a2ui.StreamEvent> events) {
    _queuedEvents.addAll(events);
  }

  /// Queue a single A2UI message event.
  void stubA2uiMessage(a2ui.A2uiMessageData message) {
    _queuedEvents.add(a2ui.A2uiMessageEvent(message));
  }

  /// Queue a text delta event.
  void stubTextDelta(String text) {
    _queuedEvents.add(a2ui.TextDeltaEvent(text));
  }

  /// Queue a complete event.
  void stubComplete() {
    _queuedEvents.add(const a2ui.CompleteEvent());
  }

  /// Queue an error event.
  void stubError(a2ui.A2uiException error) {
    _queuedEvents.add(a2ui.ErrorEvent(error));
  }

  /// Simulates streaming request by yielding queued events.
  Stream<a2ui.StreamEvent> streamRequest({
    required Stream<Map<String, dynamic>> messageStream,
  }) async* {
    for (final event in _queuedEvents) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      yield event;
    }
    _queuedEvents.clear();
  }

  /// Resets queued events.
  void reset() {
    _queuedEvents.clear();
  }

  void dispose() {
    _queuedEvents.clear();
  }
}

/// Factory for creating mock [a2ui.A2uiToolSchema] objects.
class MockToolFactory {
  MockToolFactory._();

  /// Creates a simple tool schema for testing.
  static a2ui.A2uiToolSchema tool({
    required String name,
    String description = 'A test tool',
    Map<String, dynamic>? inputSchema,
    List<String>? requiredFields,
  }) {
    return a2ui.A2uiToolSchema(
      name: name,
      description: description,
      inputSchema: inputSchema ??
          {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
          },
      requiredFields: requiredFields,
    );
  }

  /// Creates a tool schema with string property.
  static a2ui.A2uiToolSchema stringTool({
    String name = 'string_tool',
    String propertyName = 'text',
    bool required = false,
  }) {
    return a2ui.A2uiToolSchema(
      name: name,
      description: 'Tool with string input',
      inputSchema: {
        'type': 'object',
        'properties': {
          propertyName: {'type': 'string', 'description': 'Text input'},
        },
      },
      requiredFields: required ? [propertyName] : null,
    );
  }

  /// Creates a tool schema mimicking a widget tool.
  static a2ui.A2uiToolSchema widgetTool({
    String name = 'test_widget',
    Map<String, dynamic>? properties,
    List<String>? requiredFields,
  }) {
    return a2ui.A2uiToolSchema(
      name: name,
      description: 'Renders a $name widget',
      inputSchema: {
        'type': 'object',
        'properties': properties ??
            {
              'title': {'type': 'string'},
              'subtitle': {'type': 'string'},
            },
      },
      requiredFields: requiredFields ?? ['title'],
    );
  }

  /// Creates begin_rendering control tool.
  static a2ui.A2uiToolSchema beginRenderingTool() {
    return const a2ui.A2uiToolSchema(
      name: 'begin_rendering',
      description: 'Begin rendering a new UI surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string'},
          'metadata': {'type': 'object'},
        },
      },
      requiredFields: ['surfaceId'],
    );
  }

  /// Creates surface_update control tool.
  static a2ui.A2uiToolSchema surfaceUpdateTool() {
    return const a2ui.A2uiToolSchema(
      name: 'surface_update',
      description: 'Update widgets on a surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string'},
          'widgets': {'type': 'array'},
        },
      },
      requiredFields: ['surfaceId', 'widgets'],
    );
  }
}

/// Factory for creating mock [CatalogItem] objects.
class MockCatalogItemFactory {
  MockCatalogItemFactory._();

  /// Creates a simple catalog item for testing.
  static CatalogItem item({
    required String name,
    String? description,
    ObjectSchema? dataSchema,
    Widget Function(dynamic)? widgetBuilder,
  }) {
    return CatalogItem(
      name: name,
      dataSchema: dataSchema ??
          S.object(
            description: description ?? 'A test $name widget',
            properties: {
              'value': S.string(description: 'Widget value'),
            },
          ),
      widgetBuilder: widgetBuilder ?? (_) => const SizedBox(),
    );
  }

  /// Creates a text widget catalog item.
  static CatalogItem textWidget({
    String name = 'text_widget',
  }) {
    return CatalogItem(
      name: name,
      dataSchema: S.object(
        description: 'Displays text content',
        properties: {
          'text': S.string(description: 'The text to display'),
          'style': S.string(description: 'Text style'),
        },
        required: ['text'],
      ),
      widgetBuilder: (data) => Text(
        (data as Map<String, dynamic>?)?['text']?.toString() ?? '',
      ),
    );
  }

  /// Creates a card widget catalog item.
  static CatalogItem cardWidget({
    String name = 'card_widget',
  }) {
    return CatalogItem(
      name: name,
      dataSchema: S.object(
        description: 'Displays a card with title and content',
        properties: {
          'title': S.string(description: 'Card title'),
          'subtitle': S.string(description: 'Card subtitle'),
          'content': S.string(description: 'Card content'),
        },
        required: ['title'],
      ),
      widgetBuilder: (_) => const Card(child: SizedBox()),
    );
  }

  /// Creates a button widget catalog item.
  static CatalogItem buttonWidget({
    String name = 'button_widget',
  }) {
    return CatalogItem(
      name: name,
      dataSchema: S.object(
        description: 'Interactive button',
        properties: {
          'label': S.string(description: 'Button label'),
          'enabled': S.boolean(description: 'Whether button is enabled'),
          'action': S.string(description: 'Action identifier'),
        },
        required: ['label'],
      ),
      widgetBuilder: (data) => ElevatedButton(
        onPressed: () {},
        child: Text(
          (data as Map<String, dynamic>?)?['label']?.toString() ?? 'Button',
        ),
      ),
    );
  }

  /// Creates a form widget catalog item.
  static CatalogItem formWidget({
    String name = 'form_widget',
  }) {
    return CatalogItem(
      name: name,
      dataSchema: S.object(
        description: 'Form with input fields',
        properties: {
          'fields': S.list(
            items: S.object(
              properties: {
                'name': S.string(),
                'type': S.string(),
                'required': S.boolean(),
              },
            ),
          ),
          'submitLabel': S.string(),
        },
        required: ['fields'],
      ),
      widgetBuilder: (_) => const SizedBox(),
    );
  }

  /// Creates a list of common catalog items for testing.
  static List<CatalogItem> commonItems() {
    return [
      textWidget(),
      cardWidget(),
      buttonWidget(),
    ];
  }

  /// Creates a Catalog with the given items.
  static Catalog catalog(List<CatalogItem> items) {
    return Catalog(items);
  }

  /// Creates a Catalog with common test items.
  static Catalog commonCatalog() {
    return Catalog(commonItems());
  }
}
