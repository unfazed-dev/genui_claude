import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

/// Configuration for request deduplication.
class DeduplicationConfig {
  /// Creates a deduplication configuration.
  const DeduplicationConfig({
    this.enabled = true,
    this.windowMs = 100,
    this.maxCacheSize = 100,
    this.hashMessages = true,
  });

  /// Whether deduplication is enabled.
  final bool enabled;

  /// Time window in milliseconds for considering requests as duplicates.
  ///
  /// Requests with identical content within this window are deduplicated.
  final int windowMs;

  /// Maximum number of in-flight requests to track.
  final int maxCacheSize;

  /// Whether to hash message content for comparison.
  ///
  /// When true, uses hash comparison (faster, less memory).
  /// When false, compares full content (more accurate).
  final bool hashMessages;

  /// Default configuration.
  static const DeduplicationConfig defaults = DeduplicationConfig();

  /// Disabled deduplication.
  static const DeduplicationConfig disabled = DeduplicationConfig(
    enabled: false,
  );
}

/// Request deduplication that prevents duplicate API requests.
///
/// When multiple identical requests are submitted within a short time window,
/// only one is actually executed and others receive the same result.
///
/// Example usage:
/// ```dart
/// final deduplicator = RequestDeduplicator<String>();
///
/// // These two calls will only make one actual request
/// final future1 = deduplicator.execute(
///   'request-key-123',
///   () => api.expensiveCall(),
/// );
/// final future2 = deduplicator.execute(
///   'request-key-123',
///   () => api.expensiveCall(),
/// );
///
/// // Both futures complete with the same result
/// final result1 = await future1;
/// final result2 = await future2;
/// ```
class RequestDeduplicator<T> {
  /// Creates a request deduplicator.
  RequestDeduplicator({this.config = DeduplicationConfig.defaults});

  /// Deduplication configuration.
  final DeduplicationConfig config;

  /// Cache of in-flight requests by key.
  final Map<String, _InFlightRequest<T>> _inFlight = {};

  /// Executes a request, deduplicating if an identical request is in-flight.
  ///
  /// [key] is a unique identifier for the request. Requests with the same
  /// key within the deduplication window share results.
  ///
  /// [request] is the function to execute if not deduplicated.
  Future<T> execute(String key, Future<T> Function() request) async {
    if (!config.enabled) {
      return request();
    }

    _cleanupExpired();

    // Check for existing in-flight request
    final existing = _inFlight[key];
    if (existing != null && !existing.isExpired) {
      existing.incrementCount();
      return existing.future;
    }

    // Create new in-flight request
    final completer = Completer<T>();
    final inFlight = _InFlightRequest(
      future: completer.future,
      expiresAt: DateTime.now().add(Duration(milliseconds: config.windowMs)),
    );

    _inFlight[key] = inFlight;

    // Execute and complete
    try {
      final result = await request();
      completer.complete(result);
      return result;
    } on Exception catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      // Keep in cache briefly for deduplication window
      // Will be cleaned up by _cleanupExpired
    }
  }

  /// Creates a deduplication key from request data.
  ///
  /// Use this to generate consistent keys for requests with the same content.
  String createKey(Map<String, dynamic> requestData) {
    if (config.hashMessages) {
      // Use a simple hash for efficiency
      return _hashRequest(requestData);
    } else {
      // Full JSON comparison
      return jsonEncode(requestData);
    }
  }

  String _hashRequest(Map<String, dynamic> data) {
    // Simple hash combining key fields
    final buffer = StringBuffer();

    // Hash messages if present
    final messages = data['messages'];
    if (messages != null && messages is List) {
      for (final message in messages) {
        if (message is Map) {
          buffer
            ..write(message['role'] ?? '')
            ..write(':');
          final content = message['content'];
          if (content is String) {
            buffer.write(content.hashCode);
          } else if (content is List) {
            buffer.write(content.length);
          }
          buffer.write('|');
        }
      }
    }

    // Include other key fields
    buffer
      ..write(data['model'] ?? '')
      ..write(':')
      ..write(data['max_tokens'] ?? '');

    return buffer.toString().hashCode.toString();
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    _inFlight.removeWhere((_, request) => request.isExpiredAt(now));

    // Enforce max cache size
    while (_inFlight.length > config.maxCacheSize) {
      _inFlight.remove(_inFlight.keys.first);
    }
  }

  /// Returns the number of currently tracked in-flight requests.
  int get inFlightCount => _inFlight.length;

  /// Checks if a request with the given key is currently in-flight.
  bool isInFlight(String key) {
    final request = _inFlight[key];
    return request != null && !request.isExpired;
  }

  /// Clears all tracked requests.
  void clear() {
    _inFlight.clear();
  }

  /// Disposes resources.
  void dispose() {
    clear();
  }
}

class _InFlightRequest<T> {
  _InFlightRequest({
    required this.future,
    required this.expiresAt,
  });

  final Future<T> future;
  final DateTime expiresAt;
  int _count = 1;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isExpiredAt(DateTime time) => time.isAfter(expiresAt);

  void incrementCount() => _count++;

  @visibleForTesting
  int get deduplicationCount => _count;
}
