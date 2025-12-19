/// Stream handling utilities for Claude API streaming responses.
///
/// This module exports:
/// - [ClaudeStreamHandler] - Main stream handler class
/// - Retry policy configuration
/// - Rate limiter for API requests
/// - Proactive rate limiting for preventing 429 errors
/// - Request deduplication for preventing duplicate requests
library;

import 'package:a2ui_claude/a2ui_claude.dart' show ClaudeStreamHandler;
import 'package:a2ui_claude/src/stream/stream.dart' show ClaudeStreamHandler;
import 'package:a2ui_claude/src/stream/stream_handler.dart'
    show ClaudeStreamHandler;

export 'proactive_rate_limiter.dart';
export 'rate_limiter.dart';
export 'request_deduplication.dart';
export 'retry_policy.dart';
export 'stream_handler.dart';
