import 'dart:async';

/// Handles rate limiting for API requests.
///
/// Implements a simple queue-based rate limiter that respects
/// 429 responses and Retry-After headers.
class RateLimiter {
  final _queue = <_QueuedRequest>[];
  Timer? _resetTimer;
  bool _isRateLimited = false;
  Duration _retryAfter = Duration.zero;

  /// Whether the rate limiter is currently limiting requests.
  bool get isRateLimited => _isRateLimited;

  /// Executes a request, queuing if rate limited.
  Future<T> execute<T>(Future<T> Function() request) async {
    if (_isRateLimited) {
      final completer = Completer<T>();
      _queue.add(_QueuedRequest(
        execute: () async => completer.complete(await request()),
      ),);
      return completer.future;
    }

    return request();
  }

  /// Records a rate limit response.
  ///
  /// [statusCode] should be 429 for rate limiting.
  /// [retryAfter] is parsed from the Retry-After header.
  void recordRateLimit({
    required int statusCode,
    Duration? retryAfter,
  }) {
    if (statusCode == 429) {
      _isRateLimited = true;
      _retryAfter = retryAfter ?? const Duration(seconds: 60);

      _resetTimer?.cancel();
      _resetTimer = Timer(_retryAfter, _resetRateLimit);
    }
  }

  void _resetRateLimit() {
    _isRateLimited = false;
    _processQueue();
  }

  Future<void> _processQueue() async {
    while (_queue.isNotEmpty && !_isRateLimited) {
      final request = _queue.removeAt(0);
      try {
        await request.execute();
      } on Exception {
        // Errors are handled by the original caller
      }
    }
  }

  /// Parses the Retry-After header value.
  static Duration? parseRetryAfter(String? value) {
    if (value == null) return null;

    // Try parsing as seconds
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    // Could also parse HTTP date format here
    return null;
  }

  /// Disposes of resources.
  void dispose() {
    _resetTimer?.cancel();
    _queue.clear();
  }
}

class _QueuedRequest {

  _QueuedRequest({required this.execute});
  final Future<void> Function() execute;
}
