/// Flutter ContentGenerator implementation for Anthropic's Claude AI.
///
/// This library provides [AnthropicContentGenerator], a production-ready
/// implementation of GenUI's ContentGenerator interface that enables
/// Claude-powered generative UI in Flutter applications.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:genui/genui.dart';
/// import 'package:genui_anthropic/genui_anthropic.dart';
///
/// // Create content generator (development mode)
/// final generator = AnthropicContentGenerator(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
/// );
///
/// // Or use proxy mode for production
/// final prodGenerator = AnthropicContentGenerator.proxy(
///   endpoint: Uri.parse('https://your-backend.com/api/claude'),
///   authToken: userToken,
/// );
/// ```
///
/// See also:
/// - [AnthropicContentGenerator] - Main content generator class
/// - [AnthropicConfig] - Configuration for direct API mode
/// - [ProxyConfig] - Configuration for backend proxy mode
/// - [A2uiMessageAdapter] - Utility for message type conversion
library genui_anthropic;

import 'package:genui_anthropic/genui_anthropic.dart' show AnthropicContentGenerator, AnthropicConfig, ProxyConfig, A2uiMessageAdapter;

export 'src/adapter/a2ui_control_tools.dart';
export 'src/adapter/catalog_tool_bridge.dart';
export 'src/adapter/message_adapter.dart';
export 'src/config/anthropic_config.dart';
export 'src/content_generator/anthropic_content_generator.dart';
export 'src/handler/handler.dart';
export 'src/utils/message_converter.dart';
