/// Pure Dart package for Claude API to A2UI protocol conversion.
///
/// This library provides protocol-level conversion between Claude API
/// responses and A2UI (Agent-to-UI) messages, enabling seamless integration
/// with any A2UI-compatible renderer including Flutter's GenUI SDK.
///
/// ## Features
///
/// - **Tool Conversion:** Convert A2UI tool schemas to Claude tool definitions
/// - **Message Parsing:** Parse Claude responses into A2UI messages
/// - **Stream Handling:** Manage SSE streaming and progressive parsing
/// - **Type Safety:** Comprehensive Dart type definitions
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:a2ui_claude/a2ui_claude.dart';
/// import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
///
/// // Convert A2UI tools to Claude format
/// final claudeTools = A2uiToolConverter.toClaudeTools(catalogTools);
///
/// // Parse Claude response
/// final result = ClaudeA2uiParser.parseMessage(response);
/// for (final message in result.a2uiMessages) {
///   print('A2UI Message: $message');
/// }
/// ```
///
/// ## Streaming Usage
///
/// ```dart
/// final handler = ClaudeStreamHandler(client);
///
/// await for (final event in handler.streamRequest(...)) {
///   switch (event) {
///     case A2uiMessageEvent(:final message):
///       handleA2uiMessage(message);
///     case TextDeltaEvent(:final text):
///       appendText(text);
///     case CompleteEvent():
///       finishRendering();
///   }
/// }
/// ```
library a2ui_claude;

// Converter
export 'src/converter/converter.dart';
// Exceptions
export 'src/exceptions/exceptions.dart';
// Models
export 'src/models/models.dart';
// Parser
export 'src/parser/parser.dart';
// Stream
export 'src/stream/stream.dart';
