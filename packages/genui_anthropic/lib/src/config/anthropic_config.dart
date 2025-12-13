import 'package:flutter/foundation.dart';

/// Configuration for direct Anthropic API mode.
@immutable
class AnthropicConfig {
  /// Creates an Anthropic API configuration.
  const AnthropicConfig({
    this.maxTokens = 4096,
    this.timeout = const Duration(seconds: 60),
    this.retryAttempts = 3,
    this.enableStreaming = true,
    this.headers,
  });

  /// Maximum tokens in response.
  final int maxTokens;

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts for transient failures.
  final int retryAttempts;

  /// Enable streaming responses.
  final bool enableStreaming;

  /// Custom HTTP headers.
  final Map<String, String>? headers;

  /// Default configuration.
  static const AnthropicConfig defaults = AnthropicConfig();

  /// Creates a copy with the given fields replaced.
  AnthropicConfig copyWith({
    int? maxTokens,
    Duration? timeout,
    int? retryAttempts,
    bool? enableStreaming,
    Map<String, String>? headers,
  }) {
    return AnthropicConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      timeout: timeout ?? this.timeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      enableStreaming: enableStreaming ?? this.enableStreaming,
      headers: headers ?? this.headers,
    );
  }
}

/// Configuration for backend proxy mode.
@immutable
class ProxyConfig {
  /// Creates a proxy configuration.
  const ProxyConfig({
    this.timeout = const Duration(seconds: 120),
    this.retryAttempts = 3,
    this.headers,
    this.includeHistory = true,
    this.maxHistoryMessages = 20,
  });

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts.
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
