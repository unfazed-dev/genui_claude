import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_config.freezed.dart';

/// Configuration for Claude API streaming requests.
///
/// Controls timeout, retry behavior, and token limits for streaming
/// connections.
@freezed
abstract class StreamConfig with _$StreamConfig {
  /// Creates a stream configuration.
  ///
  /// Defaults:
  /// - [maxTokens]: 4096
  /// - [timeout]: 60 seconds
  /// - [retryAttempts]: 3
  const factory StreamConfig({
    /// Maximum tokens in the response.
    @Default(4096) int maxTokens,

    /// Connection timeout duration.
    @Default(Duration(seconds: 60)) Duration timeout,

    /// Number of retry attempts for transient failures.
    @Default(3) int retryAttempts,
  }) = _StreamConfig;

  /// Default stream configuration.
  static const StreamConfig defaults = StreamConfig();
}
