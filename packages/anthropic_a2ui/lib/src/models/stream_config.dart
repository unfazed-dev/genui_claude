import 'package:meta/meta.dart';

/// Configuration for Claude API streaming requests.
///
/// Controls timeout, retry behavior, and token limits for streaming
/// connections.
@immutable
class StreamConfig {

  /// Creates a stream configuration.
  ///
  /// Defaults:
  /// - [maxTokens]: 4096
  /// - [timeout]: 60 seconds
  /// - [retryAttempts]: 3
  const StreamConfig({
    this.maxTokens = 4096,
    this.timeout = const Duration(seconds: 60),
    this.retryAttempts = 3,
  });
  /// Maximum tokens in the response.
  final int maxTokens;

  /// Connection timeout duration.
  final Duration timeout;

  /// Number of retry attempts for transient failures.
  final int retryAttempts;

  /// Default stream configuration.
  static const StreamConfig defaults = StreamConfig();

  /// Creates a copy with the given fields replaced.
  StreamConfig copyWith({
    int? maxTokens,
    Duration? timeout,
    int? retryAttempts,
  }) {
    return StreamConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      timeout: timeout ?? this.timeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamConfig &&
          maxTokens == other.maxTokens &&
          timeout == other.timeout &&
          retryAttempts == other.retryAttempts;

  @override
  int get hashCode => Object.hash(maxTokens, timeout, retryAttempts);

  @override
  String toString() => 'StreamConfig(maxTokens: $maxTokens, '
      'timeout: ${timeout.inSeconds}s, retryAttempts: $retryAttempts)';
}
