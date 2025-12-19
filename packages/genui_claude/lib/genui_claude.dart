/// Flutter ContentGenerator implementation for Claude AI.
///
/// This library provides [ClaudeContentGenerator], a production-ready
/// implementation of GenUI's ContentGenerator interface that enables
/// Claude-powered generative UI in Flutter applications.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:genui/genui.dart';
/// import 'package:genui_claude/genui_claude.dart';
///
/// // Create content generator (development mode)
/// final generator = ClaudeContentGenerator(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
/// );
///
/// // Or use proxy mode for production
/// final prodGenerator = ClaudeContentGenerator.proxy(
///   endpoint: Uri.parse('https://your-backend.com/api/claude'),
///   authToken: userToken,
/// );
/// ```
///
/// See also:
/// - [ClaudeContentGenerator] - Main content generator class
/// - [ClaudeConfig] - Configuration for direct API mode
/// - [ProxyConfig] - Configuration for backend proxy mode
/// - [A2uiMessageAdapter] - Utility for message type conversion
library genui_claude;

import 'package:genui_claude/genui_claude.dart'
    show ClaudeContentGenerator, ClaudeConfig, ProxyConfig, A2uiMessageAdapter;

export 'src/adapter/a2ui_control_tools.dart';
export 'src/adapter/catalog_tool_bridge.dart';
export 'src/adapter/message_adapter.dart';
export 'src/binding/binding.dart';
export 'src/config/claude_config.dart';
export 'src/config/retry_config.dart';
export 'src/content_generator/claude_content_generator.dart';
export 'src/exceptions/claude_exceptions.dart';
export 'src/handler/handler.dart';
export 'src/metrics/metrics.dart';
export 'src/resilience/circuit_breaker.dart';
export 'src/search/search.dart';
export 'src/utils/message_converter.dart';
