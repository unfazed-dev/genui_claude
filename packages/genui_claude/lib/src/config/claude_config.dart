import 'package:flutter/foundation.dart';
import 'package:genui_claude/genui_claude.dart' show RetryConfig, ProxyModeHandler;

/// Configuration for direct Claude API mode.
@immutable
class ClaudeConfig {
  /// Creates a Claude API configuration.
  ///
  /// Throws [AssertionError] if:
  /// - [maxTokens] is less than 1
  /// - [retryAttempts] is negative
  ///
  /// Note: [timeout] is not validated at construction time due to const
  /// constructor constraints. Invalid timeouts will be caught at runtime
  /// when making API requests.
  const ClaudeConfig({
    this.maxTokens = 4096,
    this.timeout = const Duration(seconds: 60),
    this.retryAttempts = 3,
    this.enableStreaming = true,
    this.headers,
    this.enableFineGrainedStreaming = false,
    this.enableInterleavedThinking = false,
    this.thinkingBudgetTokens,
    this.enableToolSearch = false,
    this.maxLoadedToolsPerSession = 50,
  })  : assert(maxTokens > 0, 'maxTokens must be greater than 0'),
        assert(retryAttempts >= 0, 'retryAttempts cannot be negative'),
        assert(
          maxLoadedToolsPerSession > 0,
          'maxLoadedToolsPerSession must be greater than 0',
        );

  /// Maximum tokens in response.
  final int maxTokens;

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts for transient failures.
  final int retryAttempts;

  /// Enable streaming responses.
  ///
  /// Note: Currently streaming is always enabled as the GenUI framework
  /// requires streaming for progressive UI rendering. This option is
  /// reserved for potential future non-streaming use cases.
  final bool enableStreaming;

  /// Custom HTTP headers.
  final Map<String, String>? headers;

  /// Enable fine-grained tool streaming for progressive widget rendering.
  ///
  /// When enabled, adds the `fine-grained-tool-streaming-2025-05-14` beta header
  /// to Claude API requests, allowing partial tool call JSON to be streamed
  /// as it's generated.
  final bool enableFineGrainedStreaming;

  /// Enable interleaved thinking for Claude 4+ models.
  ///
  /// When enabled, adds the `interleaved-thinking-2025-05-14` beta header
  /// and includes thinking configuration in the request body. This allows
  /// Claude to emit thinking blocks interleaved with content.
  final bool enableInterleavedThinking;

  /// Budget tokens for thinking (required when [enableInterleavedThinking] is true).
  ///
  /// Specifies the maximum number of tokens Claude can use for thinking.
  /// If null when thinking is enabled, Claude uses its default budget.
  final int? thinkingBudgetTokens;

  /// Enable tool search mode for large catalogs.
  ///
  /// When enabled, Claude will use the search_catalog and load_tools tools
  /// to dynamically discover and load widgets from large catalogs (100+ items)
  /// instead of receiving all tools upfront.
  final bool enableToolSearch;

  /// Maximum number of tools that can be loaded per session.
  ///
  /// Only applies when [enableToolSearch] is true. Limits the number of
  /// widget tools that can be loaded dynamically during a single session.
  final int maxLoadedToolsPerSession;

  /// Default configuration.
  static const ClaudeConfig defaults = ClaudeConfig();

  /// Creates a copy with the given fields replaced.
  ClaudeConfig copyWith({
    int? maxTokens,
    Duration? timeout,
    int? retryAttempts,
    bool? enableStreaming,
    Map<String, String>? headers,
    bool? enableFineGrainedStreaming,
    bool? enableInterleavedThinking,
    int? thinkingBudgetTokens,
    bool? enableToolSearch,
    int? maxLoadedToolsPerSession,
  }) {
    return ClaudeConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      timeout: timeout ?? this.timeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      enableStreaming: enableStreaming ?? this.enableStreaming,
      headers: headers ?? this.headers,
      enableFineGrainedStreaming:
          enableFineGrainedStreaming ?? this.enableFineGrainedStreaming,
      enableInterleavedThinking:
          enableInterleavedThinking ?? this.enableInterleavedThinking,
      thinkingBudgetTokens: thinkingBudgetTokens ?? this.thinkingBudgetTokens,
      enableToolSearch: enableToolSearch ?? this.enableToolSearch,
      maxLoadedToolsPerSession:
          maxLoadedToolsPerSession ?? this.maxLoadedToolsPerSession,
    );
  }
}

/// Configuration for backend proxy mode.
@immutable
class ProxyConfig {
  /// Creates a proxy configuration.
  ///
  /// Throws [AssertionError] if:
  /// - [retryAttempts] is negative
  /// - [maxHistoryMessages] is negative
  ///
  /// Note: [timeout] is not validated at construction time due to const
  /// constructor constraints. Invalid timeouts will be caught at runtime.
  const ProxyConfig({
    this.timeout = const Duration(seconds: 120),
    this.retryAttempts = 3,
    this.headers,
    this.includeHistory = true,
    this.maxHistoryMessages = 20,
  })  : assert(retryAttempts >= 0, 'retryAttempts cannot be negative'),
        assert(maxHistoryMessages >= 0, 'maxHistoryMessages cannot be negative');

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts for transient failures.
  ///
  /// This value is used to create a default [RetryConfig] when no explicit
  /// retry configuration is provided to [ProxyModeHandler]. For more advanced
  /// retry behavior (custom backoff, jitter, etc.), provide a [RetryConfig]
  /// directly to the handler.
  ///
  /// Retries are automatically applied for:
  /// - Rate limit errors (HTTP 429) with Retry-After header support
  /// - Transient server errors (HTTP 500, 502, 503, 504)
  /// - Network timeouts and connection errors
  final int retryAttempts;

  /// Custom HTTP headers (in addition to auth).
  final Map<String, String>? headers;

  /// Whether to send conversation history.
  final bool includeHistory;

  /// Maximum history messages to include.
  final int maxHistoryMessages;

  /// Default configuration.
  static const ProxyConfig defaults = ProxyConfig();

  /// Creates a copy with the given fields replaced.
  ProxyConfig copyWith({
    Duration? timeout,
    int? retryAttempts,
    Map<String, String>? headers,
    bool? includeHistory,
    int? maxHistoryMessages,
  }) {
    return ProxyConfig(
      timeout: timeout ?? this.timeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      headers: headers ?? this.headers,
      includeHistory: includeHistory ?? this.includeHistory,
      maxHistoryMessages: maxHistoryMessages ?? this.maxHistoryMessages,
    );
  }
}
