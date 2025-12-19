import 'dart:async';

/// Configuration for proactive rate limiting.
class RateLimitConfig {
  /// Creates a rate limit configuration.
  const RateLimitConfig({
    this.requestsPerMinute = 60,
    this.requestsPerDay = 1000,
    this.tokensPerMinute = 100000,
    this.enabled = true,
  });

  /// Maximum requests allowed per minute.
  ///
  /// Claude API typically allows 60 requests per minute on lower tiers.
  final int requestsPerMinute;

  /// Maximum requests allowed per day.
  ///
  /// Some tiers have daily limits.
  final int requestsPerDay;

  /// Maximum tokens per minute (for token-based rate limiting).
  ///
  /// Claude API has token-per-minute limits that vary by tier.
  final int tokensPerMinute;

  /// Whether proactive rate limiting is enabled.
  final bool enabled;

  /// Default configuration for standard Claude API tier.
  static const RateLimitConfig defaults = RateLimitConfig();

  /// Configuration with no limits (for testing or unlimited tiers).
  static const RateLimitConfig unlimited = RateLimitConfig(
    requestsPerMinute: 999999,
    requestsPerDay: 999999,
    tokensPerMinute: 999999999,
    enabled: false,
  );

  /// Creates a copy with modified values.
  RateLimitConfig copyWith({
    int? requestsPerMinute,
    int? requestsPerDay,
    int? tokensPerMinute,
    bool? enabled,
  }) {
    return RateLimitConfig(
      requestsPerMinute: requestsPerMinute ?? this.requestsPerMinute,
      requestsPerDay: requestsPerDay ?? this.requestsPerDay,
      tokensPerMinute: tokensPerMinute ?? this.tokensPerMinute,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Proactive rate limiter that prevents exceeding API limits before getting 429.
///
/// Uses a sliding window algorithm to track requests and tokens over time,
/// proactively delaying requests to stay within configured limits.
///
/// Example usage:
/// ```dart
/// final limiter = ProactiveRateLimiter(
///   config: RateLimitConfig(requestsPerMinute: 60),
/// );
///
/// // Execute request with automatic throttling
/// final result = await limiter.execute(
///   () => api.sendRequest(message),
///   estimatedTokens: 1000,
/// );
/// ```
class ProactiveRateLimiter {
  /// Creates a proactive rate limiter.
  ProactiveRateLimiter({this.config = RateLimitConfig.defaults});

  /// Rate limit configuration.
  final RateLimitConfig config;

  /// Timestamps of recent requests (for sliding window).
  final List<DateTime> _requestTimestamps = [];

  /// Token counts with timestamps for token-based limiting.
  final List<_TokenRecord> _tokenRecords = [];

  /// Daily request count (resets at midnight UTC).
  int _dailyRequestCount = 0;

  /// Last day the daily counter was reset.
  DateTime? _lastDayReset;

  /// Returns true if rate limiting is currently needed.
  bool get isThrottled {
    if (!config.enabled) return false;
    _cleanupOldRecords();
    return _requestTimestamps.length >= config.requestsPerMinute ||
        _dailyRequestCount >= config.requestsPerDay;
  }

  /// Current requests per minute count.
  int get currentRequestsPerMinute {
    _cleanupOldRecords();
    return _requestTimestamps.length;
  }

  /// Current daily request count.
  int get currentDailyRequests => _dailyRequestCount;

  /// Remaining requests allowed this minute.
  int get remainingRequestsPerMinute {
    _cleanupOldRecords();
    return (config.requestsPerMinute - _requestTimestamps.length)
        .clamp(0, config.requestsPerMinute);
  }

  /// Remaining daily requests.
  int get remainingDailyRequests =>
      (config.requestsPerDay - _dailyRequestCount)
          .clamp(0, config.requestsPerDay);

  /// Executes a request with proactive rate limiting.
  ///
  /// If rate limits would be exceeded, waits until a slot is available.
  /// [estimatedTokens] can be provided for token-based rate limiting.
  Future<T> execute<T>(
    Future<T> Function() request, {
    int estimatedTokens = 0,
  }) async {
    if (!config.enabled) {
      return request();
    }

    // Wait for a slot if needed
    final waitTime = _calculateWaitTime(estimatedTokens);
    if (waitTime > Duration.zero) {
      await Future<void>.delayed(waitTime);
    }

    // Record this request
    _recordRequest(estimatedTokens);

    return request();
  }

  /// Checks if a request can be made immediately.
  ///
  /// Returns `true` if the request can proceed without waiting,
  /// `false` if rate limiting would require a delay.
  bool canProceed({int estimatedTokens = 0}) {
    if (!config.enabled) return true;
    return _calculateWaitTime(estimatedTokens) == Duration.zero;
  }

  /// Calculates how long to wait before the next request.
  Duration getWaitTime({int estimatedTokens = 0}) {
    if (!config.enabled) return Duration.zero;
    return _calculateWaitTime(estimatedTokens);
  }

  Duration _calculateWaitTime(int estimatedTokens) {
    _cleanupOldRecords();
    _maybeResetDailyCounter();

    // Check daily limit
    if (_dailyRequestCount >= config.requestsPerDay) {
      // Would need to wait until next day - return a long duration
      return const Duration(hours: 24);
    }

    // Check per-minute request limit
    if (_requestTimestamps.length >= config.requestsPerMinute) {
      // Wait until the oldest request falls outside the window
      final oldest = _requestTimestamps.first;
      final windowEnd = oldest.add(const Duration(minutes: 1));
      final waitTime = windowEnd.difference(DateTime.now());
      return waitTime > Duration.zero ? waitTime : Duration.zero;
    }

    // Check token limit
    if (estimatedTokens > 0) {
      final currentTokens = _currentTokensPerMinute();
      if (currentTokens + estimatedTokens > config.tokensPerMinute) {
        if (_tokenRecords.isNotEmpty) {
          final oldest = _tokenRecords.first;
          final windowEnd = oldest.timestamp.add(const Duration(minutes: 1));
          final waitTime = windowEnd.difference(DateTime.now());
          return waitTime > Duration.zero ? waitTime : Duration.zero;
        }
      }
    }

    return Duration.zero;
  }

  void _recordRequest(int tokens) {
    final now = DateTime.now();
    _requestTimestamps.add(now);
    _dailyRequestCount++;

    if (tokens > 0) {
      _tokenRecords.add(_TokenRecord(timestamp: now, tokens: tokens));
    }
  }

  void _cleanupOldRecords() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));

    _requestTimestamps.removeWhere((t) => t.isBefore(cutoff));
    _tokenRecords.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

  void _maybeResetDailyCounter() {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    if (_lastDayReset == null || _lastDayReset!.isBefore(today)) {
      _dailyRequestCount = 0;
      _lastDayReset = today;
    }
  }

  int _currentTokensPerMinute() {
    return _tokenRecords.fold(0, (sum, record) => sum + record.tokens);
  }

  /// Records a rate limit response from the server.
  ///
  /// When a 429 is received, this updates internal tracking to
  /// synchronize with server-side limits.
  void recordServerRateLimit({Duration? retryAfter}) {
    // When server tells us we're rate limited, assume we've hit the limit
    // Add synthetic entries to prevent further requests
    final now = DateTime.now();
    while (_requestTimestamps.length < config.requestsPerMinute) {
      _requestTimestamps.add(now);
    }
  }

  /// Resets all counters (useful for testing).
  void reset() {
    _requestTimestamps.clear();
    _tokenRecords.clear();
    _dailyRequestCount = 0;
    _lastDayReset = null;
  }

  /// Disposes resources.
  void dispose() {
    reset();
  }
}

class _TokenRecord {
  _TokenRecord({required this.timestamp, required this.tokens});

  final DateTime timestamp;
  final int tokens;
}
