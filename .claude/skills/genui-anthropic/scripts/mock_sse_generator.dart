#!/usr/bin/env dart
/// Mock SSE Generator for GenUI Anthropic Testing
///
/// Generates realistic Claude SSE (Server-Sent Events) sequences for testing
/// without hitting the actual API. Useful for unit tests and development.
///
/// Usage:
///   dart run .claude/skills/genui-anthropic/scripts/mock_sse_generator.dart
///
/// Options:
///   --scenario=<name>  Generate specific scenario (text, ui, mixed, error)
///   --output=<file>    Write to file instead of stdout
///   --delay=<ms>       Add delay between events (for streaming simulation)

import 'dart:convert';
import 'dart:io';

/// Generates a unique tool use ID
String _generateToolId() => 'toolu_${DateTime.now().millisecondsSinceEpoch}';

/// SSE Event builder for Claude responses
class SseEventBuilder {
  final List<Map<String, dynamic>> _events = [];
  int _contentBlockIndex = 0;

  /// Add a text content block
  void addTextBlock(String text, {bool streaming = true}) {
    final index = _contentBlockIndex++;

    // Start block
    _events.add({
      'type': 'content_block_start',
      'index': index,
      'content_block': {
        'type': 'text',
        'text': '',
      },
    });

    if (streaming) {
      // Stream text in chunks
      final chunks = _chunkText(text, 20);
      for (final chunk in chunks) {
        _events.add({
          'type': 'content_block_delta',
          'index': index,
          'delta': {
            'type': 'text_delta',
            'text': chunk,
          },
        });
      }
    } else {
      // Single delta with full text
      _events.add({
        'type': 'content_block_delta',
        'index': index,
        'delta': {
          'type': 'text_delta',
          'text': text,
        },
      });
    }

    // Stop block
    _events.add({
      'type': 'content_block_stop',
      'index': index,
    });
  }

  /// Add a tool use block (for A2UI messages)
  void addToolUseBlock(String toolName, Map<String, dynamic> input, {String? toolId}) {
    final index = _contentBlockIndex++;
    final id = toolId ?? _generateToolId();

    // Start block
    _events.add({
      'type': 'content_block_start',
      'index': index,
      'content_block': {
        'type': 'tool_use',
        'id': id,
        'name': toolName,
        'input': {},
      },
    });

    // Stream JSON input in chunks
    final jsonStr = jsonEncode(input);
    final chunks = _chunkText(jsonStr, 50);
    for (final chunk in chunks) {
      _events.add({
        'type': 'content_block_delta',
        'index': index,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': chunk,
        },
      });
    }

    // Stop block
    _events.add({
      'type': 'content_block_stop',
      'index': index,
    });
  }

  /// Add begin_rendering tool call
  void addBeginRendering(
    String surfaceId, {
    String? parentSurfaceId,
    String? root,
    Map<String, dynamic>? metadata,
  }) {
    final input = <String, dynamic>{'surfaceId': surfaceId};
    if (parentSurfaceId != null) {
      input['parentSurfaceId'] = parentSurfaceId;
    }
    if (root != null) {
      input['root'] = root;
    }
    if (metadata != null) {
      input['metadata'] = metadata;
    }
    addToolUseBlock('begin_rendering', input);
  }

  /// Add surface_update tool call
  void addSurfaceUpdate(String surfaceId, List<Map<String, dynamic>> widgets, {bool append = false}) {
    addToolUseBlock('surface_update', {
      'surfaceId': surfaceId,
      'widgets': widgets,
      if (append) 'append': true,
    });
  }

  /// Add data_model_update tool call
  void addDataModelUpdate(Map<String, dynamic> updates, {String? scope}) {
    addToolUseBlock('data_model_update', {
      'updates': updates,
      if (scope != null) 'scope': scope,
    });
  }

  /// Add delete_surface tool call
  void addDeleteSurface(String surfaceId, {bool cascade = true}) {
    addToolUseBlock('delete_surface', {
      'surfaceId': surfaceId,
      'cascade': cascade,
    });
  }

  /// Add message_stop event
  void addMessageStop() {
    _events.add({'type': 'message_stop'});
  }

  /// Add error event
  void addError(String message, {String type = 'api_error'}) {
    _events.add({
      'type': 'error',
      'error': {
        'type': type,
        'message': message,
      },
    });
  }

  /// Get all events
  List<Map<String, dynamic>> build() => List.unmodifiable(_events);

  /// Convert to SSE format (newline-delimited JSON)
  String toSseFormat() {
    return _events.map((e) => jsonEncode(e)).join('\n');
  }

  /// Convert to data: prefixed SSE format
  String toDataPrefixedFormat() {
    return _events.map((e) => 'data: ${jsonEncode(e)}').join('\n');
  }

  List<String> _chunkText(String text, int chunkSize) {
    final chunks = <String>[];
    for (var i = 0; i < text.length; i += chunkSize) {
      chunks.add(text.substring(i, (i + chunkSize).clamp(0, text.length)));
    }
    return chunks;
  }
}

/// Pre-built scenarios for common testing needs
class MockScenarios {
  /// Simple text response
  static List<Map<String, dynamic>> textOnly(String text) {
    final builder = SseEventBuilder();
    builder.addTextBlock(text);
    builder.addMessageStop();
    return builder.build();
  }

  /// UI generation with info card
  static List<Map<String, dynamic>> simpleUi({
    String surfaceId = 'surface_1',
    String title = 'Hello',
    String content = 'This is a generated card.',
  }) {
    final builder = SseEventBuilder();
    builder.addBeginRendering(surfaceId);
    builder.addSurfaceUpdate(surfaceId, [
      {
        'type': 'info_card',
        'properties': {
          'title': title,
          'content': content,
        },
      },
    ]);
    builder.addMessageStop();
    return builder.build();
  }

  /// Mixed response: text + UI
  static List<Map<String, dynamic>> mixedResponse({
    String text = 'Here is the information you requested:',
    String surfaceId = 'surface_1',
    List<Map<String, dynamic>>? widgets,
  }) {
    final builder = SseEventBuilder();
    builder.addTextBlock(text);
    builder.addBeginRendering(surfaceId);
    builder.addSurfaceUpdate(surfaceId, widgets ?? [
      {
        'type': 'info_card',
        'properties': {
          'title': 'Result',
          'content': 'Generated content',
        },
      },
    ]);
    builder.addMessageStop();
    return builder.build();
  }

  /// Form generation
  static List<Map<String, dynamic>> formUi({
    String surfaceId = 'form_surface',
    List<Map<String, dynamic>>? fields,
  }) {
    final builder = SseEventBuilder();
    builder.addTextBlock('Please fill out the form below:');
    builder.addBeginRendering(surfaceId);
    builder.addSurfaceUpdate(surfaceId, [
      {
        'type': 'form_container',
        'properties': {'title': 'User Information'},
        'children': fields ?? [
          {
            'type': 'form_field',
            'properties': {
              'name': 'username',
              'label': 'Username',
              'type': 'text',
              'required': true,
            },
          },
          {
            'type': 'form_field',
            'properties': {
              'name': 'email',
              'label': 'Email',
              'type': 'email',
              'required': true,
            },
          },
          {
            'type': 'action_button',
            'properties': {
              'label': 'Submit',
              'action': 'submit_form',
              'variant': 'primary',
            },
          },
        ],
      },
    ]);
    builder.addMessageStop();
    return builder.build();
  }

  /// Multiple surfaces
  static List<Map<String, dynamic>> multipleSurfaces() {
    final builder = SseEventBuilder();
    builder.addTextBlock('Here are multiple results:');

    builder.addBeginRendering('surface_1');
    builder.addSurfaceUpdate('surface_1', [
      {'type': 'info_card', 'properties': {'title': 'Card 1', 'content': 'First card'}},
    ]);

    builder.addBeginRendering('surface_2');
    builder.addSurfaceUpdate('surface_2', [
      {'type': 'info_card', 'properties': {'title': 'Card 2', 'content': 'Second card'}},
    ]);

    builder.addMessageStop();
    return builder.build();
  }

  /// Error scenario
  static List<Map<String, dynamic>> apiError({
    String message = 'Rate limit exceeded',
    String type = 'rate_limit_error',
  }) {
    final builder = SseEventBuilder();
    builder.addError(message, type: type);
    return builder.build();
  }

  /// Streaming text with incremental updates
  static List<Map<String, dynamic>> streamingText(String fullText) {
    final builder = SseEventBuilder();
    builder.addTextBlock(fullText, streaming: true);
    builder.addMessageStop();
    return builder.build();
  }
}

/// Utility to write events with delay (for simulating streaming)
Future<void> writeWithDelay(
  List<Map<String, dynamic>> events,
  IOSink sink, {
  Duration delay = const Duration(milliseconds: 50),
}) async {
  for (final event in events) {
    sink.writeln(jsonEncode(event));
    await Future.delayed(delay);
  }
}

void main(List<String> args) {
  // Parse arguments
  String scenario = 'mixed';
  String? outputFile;
  int delayMs = 0;

  for (final arg in args) {
    if (arg.startsWith('--scenario=')) {
      scenario = arg.substring('--scenario='.length);
    } else if (arg.startsWith('--output=')) {
      outputFile = arg.substring('--output='.length);
    } else if (arg.startsWith('--delay=')) {
      delayMs = int.tryParse(arg.substring('--delay='.length)) ?? 0;
    }
  }

  print('GenUI Anthropic Mock SSE Generator');
  print('===================================');
  print('');
  print('Scenario: $scenario');
  print('');

  // Generate events based on scenario
  List<Map<String, dynamic>> events;
  switch (scenario) {
    case 'text':
      events = MockScenarios.textOnly('Hello! I am Claude, ready to help you build interactive UIs.');
      break;
    case 'ui':
      events = MockScenarios.simpleUi(
        title: 'Welcome',
        content: 'This is a dynamically generated UI card.',
      );
      break;
    case 'form':
      events = MockScenarios.formUi();
      break;
    case 'multiple':
      events = MockScenarios.multipleSurfaces();
      break;
    case 'error':
      events = MockScenarios.apiError();
      break;
    case 'streaming':
      events = MockScenarios.streamingText(
        'This is a longer text response that will be streamed in chunks to simulate the real Claude API behavior.',
      );
      break;
    case 'mixed':
    default:
      events = MockScenarios.mixedResponse(
        text: 'I have generated an info card for you:',
        widgets: [
          {
            'type': 'info_card',
            'properties': {
              'title': 'Generated Card',
              'content': 'This card was created by Claude using the GenUI Anthropic SDK.',
              'variant': 'elevated',
            },
          },
        ],
      );
  }

  print('Events generated: ${events.length}');
  print('');

  // Output
  final output = events.map((e) => jsonEncode(e)).join('\n');

  if (outputFile != null) {
    File(outputFile).writeAsStringSync(output);
    print('Written to: $outputFile');
  } else {
    print('--- SSE Output ---');
    print(output);
  }

  print('');
  print('Available scenarios: text, ui, form, multiple, error, streaming, mixed');
}
