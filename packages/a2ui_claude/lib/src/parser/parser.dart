/// Message parsing utilities for Claude API responses.
///
/// This module exports:
/// - [ClaudeA2uiParser] - Main parser class
/// - Block handlers for different content types
/// - Stream parser for real-time processing
library;

import 'package:a2ui_claude/a2ui_claude.dart' show ClaudeA2uiParser;
import 'package:a2ui_claude/src/parser/message_parser.dart' show ClaudeA2uiParser;
import 'package:a2ui_claude/src/parser/parser.dart' show ClaudeA2uiParser;

export 'block_handlers.dart';
export 'message_parser.dart';
export 'stream_parser.dart';
