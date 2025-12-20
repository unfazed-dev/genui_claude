import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:genui_claude/src/metrics/metrics_event.dart';

/// Abstract base class for observability platform adapters.
///
/// Adapters transform [MetricsEvent]s into platform-specific formats
/// and handle their delivery to external monitoring systems.
///
/// ## Implementing Custom Adapters
///
/// ```dart
/// class MyCustomAdapter extends ObservabilityAdapter {
///   @override
///   Future<void> sendEvent(MetricsEvent event) async {
///     final formatted = formatEvent(event);
///     await myHttpClient.post('/metrics', body: formatted);
///   }
///
///   @override
///   Map<String, dynamic> formatEvent(MetricsEvent event) {
///     return {
///       ...event.toMap(),
///       'service': 'my-app',
///       'environment': 'production',
///     };
///   }
/// }
/// ```
abstract class ObservabilityAdapter {
  /// Creates an observability adapter.
  ObservabilityAdapter({
    this.serviceName = 'genui_claude',
    this.environment,
    this.additionalTags = const {},
  });

  /// Service name for tagging metrics.
  final String serviceName;

  /// Environment name (e.g., 'production', 'staging').
  final String? environment;

  /// Additional tags to include with all events.
  final Map<String, String> additionalTags;

  StreamSubscription<MetricsEvent>? _subscription;

  /// Whether the adapter is currently connected.
  bool get isConnected => _subscription != null;

  /// Connects to a metrics collector and starts processing events.
  ///
  /// Events are automatically formatted and sent to the observability
  /// platform as they are emitted from the collector.
  void connect(MetricsCollector collector) {
    disconnect();
    _subscription = collector.eventStream.listen(
      _handleEvent,
      onError: onError,
    );
  }

  /// Disconnects from the metrics collector.
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handleEvent(MetricsEvent event) async {
    try {
      await sendEvent(event);
    } on Exception catch (e, stack) {
      onError(e, stack);
    }
  }

  /// Sends an event to the observability platform.
  ///
  /// Override this to implement platform-specific delivery.
  Future<void> sendEvent(MetricsEvent event);

  /// Formats an event for the observability platform.
  ///
  /// Override this to customize event formatting.
  Map<String, dynamic> formatEvent(MetricsEvent event) {
    return {
      ...event.toMap(),
      'service': serviceName,
      if (environment != null) 'environment': environment,
      if (additionalTags.isNotEmpty) 'tags': additionalTags,
    };
  }

  /// Called when an error occurs during event processing.
  ///
  /// Override to customize error handling.
  void onError(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('ObservabilityAdapter error: $error');
    }
  }

  /// Disposes the adapter and releases resources.
  void dispose() {
    disconnect();
  }
}

/// Callback-based adapter for custom integrations.
///
/// Use this adapter when you need full control over event processing
/// or when integrating with platforms not covered by built-in adapters.
///
/// ## Example
///
/// ```dart
/// final adapter = CustomObservabilityAdapter(
///   onEvent: (event) async {
///     await myAnalytics.logEvent(
///       name: event.eventType,
///       parameters: event.toMap(),
///     );
///   },
///   serviceName: 'my-flutter-app',
/// );
///
/// adapter.connect(globalMetricsCollector);
/// ```
class CustomObservabilityAdapter extends ObservabilityAdapter {
  /// Creates a custom observability adapter.
  CustomObservabilityAdapter({
    required this.onEvent,
    this.onErrorCallback,
    this.formatter,
    super.serviceName,
    super.environment,
    super.additionalTags,
  });

  /// Callback invoked for each metrics event.
  final Future<void> Function(Map<String, dynamic> formattedEvent) onEvent;

  /// Optional custom error handler.
  final void Function(Object error, StackTrace? stackTrace)? onErrorCallback;

  /// Optional custom formatter.
  final Map<String, dynamic> Function(MetricsEvent event)? formatter;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    final formatted = formatter?.call(event) ?? formatEvent(event);
    await onEvent(formatted);
  }

  @override
  void onError(Object error, [StackTrace? stackTrace]) {
    if (onErrorCallback != null) {
      onErrorCallback!(error, stackTrace);
    } else {
      super.onError(error, stackTrace);
    }
  }
}

/// DataDog-compatible observability adapter.
///
/// Formats events according to DataDog's expected structure for
/// custom metrics and traces.
///
/// ## Example
///
/// ```dart
/// final adapter = DataDogAdapter(
///   apiKey: 'your-datadog-api-key',
///   serviceName: 'my-flutter-app',
///   environment: 'production',
///   httpClient: myHttpClient,
/// );
///
/// adapter.connect(globalMetricsCollector);
/// ```
///
/// ## Event Types Mapping
///
/// | GenUI Event | DataDog Metric |
/// |-------------|----------------|
/// | request_start | genui.request.started |
/// | request_success | genui.request.success |
/// | request_failure | genui.request.failure |
/// | circuit_breaker_state_change | genui.circuit_breaker.state |
/// | retry_attempt | genui.retry.attempt |
/// | rate_limit | genui.rate_limit.hit |
class DataDogAdapter extends ObservabilityAdapter {
  /// Creates a DataDog observability adapter.
  DataDogAdapter({
    required this.apiKey,
    this.site = 'datadoghq.com',
    this.httpClient,
    super.serviceName,
    super.environment,
    super.additionalTags,
  });

  /// DataDog API key.
  final String apiKey;

  /// DataDog site (e.g., 'datadoghq.com', 'datadoghq.eu').
  final String site;

  /// Optional HTTP client for sending events.
  ///
  /// If not provided, events are queued but not sent automatically.
  /// Use [formatEvent] to get the DataDog-formatted event for manual sending.
  final dynamic httpClient;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    final formatted = formatEvent(event);

    if (httpClient != null) {
      // Implementation note: Users should inject their preferred HTTP client
      // and handle the actual API call. This is intentionally left abstract
      // to avoid adding HTTP dependencies.
      // ignore: avoid_dynamic_calls
      await httpClient.post(
        'https://api.$site/api/v2/logs',
        headers: {
          'DD-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
        body: formatted,
      );
    }
  }

  @override
  Map<String, dynamic> formatEvent(MetricsEvent event) {
    final baseMap = event.toMap();

    return {
      'ddsource': 'genui_claude',
      'ddtags': _formatTags(event),
      'hostname': serviceName,
      'message': _getMessage(event),
      'service': serviceName,
      'status': _getStatus(event),
      ...baseMap,
      if (environment != null) 'env': environment,
    };
  }

  String _formatTags(MetricsEvent event) {
    final tags = <String>[
      'event_type:${event.eventType}',
      'service:$serviceName',
      if (environment != null) 'env:$environment',
      ...additionalTags.entries.map((e) => '${e.key}:${e.value}'),
    ];
    return tags.join(',');
  }

  String _getMessage(MetricsEvent event) => switch (event) {
        RequestStartEvent(:final endpoint) => 'Request started: $endpoint',
        RequestSuccessEvent(:final durationMs) =>
          'Request succeeded in ${durationMs}ms',
        RequestFailureEvent(:final errorMessage) =>
          'Request failed: $errorMessage',
        CircuitBreakerStateChangeEvent(
          :final circuitName,
          :final previousState,
          :final newState
        ) =>
          'Circuit breaker $circuitName: $previousState -> $newState',
        RetryAttemptEvent(:final attempt, :final maxAttempts, :final reason) =>
          'Retry attempt $attempt/$maxAttempts: $reason',
        RateLimitEvent() => 'Rate limit encountered',
        LatencyEvent(:final operation, :final durationMs) =>
          'Latency $operation: ${durationMs}ms',
        StreamInactivityEvent(:final timeoutMs) =>
          'Stream inactivity detected: ${timeoutMs}ms',
      };

  String _getStatus(MetricsEvent event) => switch (event) {
        RequestFailureEvent() => 'error',
        CircuitBreakerStateChangeEvent(:final newState)
            when newState.name == 'open' =>
          'warning',
        RateLimitEvent() => 'warning',
        _ => 'info',
      };
}

/// Firebase Analytics-compatible observability adapter.
///
/// Formats events for Firebase Analytics custom events and user properties.
///
/// ## Example
///
/// ```dart
/// final adapter = FirebaseAnalyticsAdapter(
///   analytics: FirebaseAnalytics.instance,
///   serviceName: 'my-flutter-app',
/// );
///
/// adapter.connect(globalMetricsCollector);
/// ```
///
/// ## Event Names
///
/// Events are prefixed with `genui_` to namespace them:
/// - `genui_request_start`
/// - `genui_request_success`
/// - `genui_request_failure`
/// - `genui_circuit_breaker`
/// - `genui_retry`
/// - `genui_rate_limit`
class FirebaseAnalyticsAdapter extends ObservabilityAdapter {
  /// Creates a Firebase Analytics observability adapter.
  FirebaseAnalyticsAdapter({
    this.analytics,
    this.eventNamePrefix = 'genui_',
    super.serviceName,
    super.environment,
    super.additionalTags,
  });

  /// Firebase Analytics instance.
  ///
  /// If not provided, events are formatted but not sent.
  /// Use [formatEvent] to get the formatted event for manual logging.
  final dynamic analytics;

  /// Prefix for event names.
  final String eventNamePrefix;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    if (analytics == null) return;

    final eventName = _getEventName(event);
    final parameters = formatEvent(event);

    // Truncate string values to Firebase's 100 character limit
    final truncatedParams = parameters.map((key, value) {
      if (value is String && value.length > 100) {
        return MapEntry(key, value.substring(0, 100));
      }
      return MapEntry(key, value);
    });

    // ignore: avoid_dynamic_calls
    await analytics.logEvent(
      name: eventName,
      parameters: truncatedParams,
    );
  }

  @override
  Map<String, dynamic> formatEvent(MetricsEvent event) {
    final baseMap = event.toMap();

    // Firebase has strict parameter naming - only alphanumeric and underscores
    final sanitized = <String, dynamic>{};
    for (final entry in baseMap.entries) {
      final key = entry.key.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');
      sanitized[key] = entry.value;
    }

    return {
      ...sanitized,
      'service_name': serviceName,
      if (environment != null) 'environment': environment,
    };
  }

  String _getEventName(MetricsEvent event) {
    // Firebase event names: alphanumeric and underscores, max 40 chars
    final baseName = event.eventType.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');
    final fullName = '$eventNamePrefix$baseName';
    return fullName.length > 40 ? fullName.substring(0, 40) : fullName;
  }
}

/// Supabase-compatible observability adapter.
///
/// Sends metrics events to a Supabase table or Edge Function for storage
/// and analysis.
///
/// ## Table Schema
///
/// Create a table in Supabase with this schema:
/// ```sql
/// CREATE TABLE metrics_events (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   created_at TIMESTAMPTZ DEFAULT NOW(),
///   event_type TEXT NOT NULL,
///   service_name TEXT,
///   environment TEXT,
///   request_id TEXT,
///   duration_ms INTEGER,
///   error_type TEXT,
///   error_message TEXT,
///   metadata JSONB
/// );
///
/// -- Enable RLS
/// ALTER TABLE metrics_events ENABLE ROW LEVEL SECURITY;
///
/// -- Index for common queries
/// CREATE INDEX idx_metrics_event_type ON metrics_events(event_type);
/// CREATE INDEX idx_metrics_created_at ON metrics_events(created_at);
/// ```
///
/// ## Example Usage
///
/// ```dart
/// final adapter = SupabaseAdapter(
///   supabaseUrl: 'https://your-project.supabase.co',
///   supabaseKey: 'your-anon-key',
///   tableName: 'metrics_events',
///   serviceName: 'my-flutter-app',
///   environment: 'production',
/// );
///
/// adapter.connect(globalMetricsCollector);
/// ```
///
/// ## Edge Function Mode
///
/// For custom processing, use an Edge Function:
/// ```dart
/// final adapter = SupabaseAdapter.edgeFunction(
///   supabaseUrl: 'https://your-project.supabase.co',
///   supabaseKey: 'your-anon-key',
///   functionName: 'process-metrics',
/// );
/// ```
class SupabaseAdapter extends ObservabilityAdapter {
  /// Creates a Supabase adapter for table insertion.
  SupabaseAdapter({
    required this.supabaseUrl,
    required this.supabaseKey,
    this.tableName = 'metrics_events',
    this.httpClient,
    super.serviceName,
    super.environment,
    super.additionalTags,
  })  : _edgeFunctionName = null,
        _isEdgeFunction = false;

  /// Creates a Supabase adapter that sends to an Edge Function.
  SupabaseAdapter.edgeFunction({
    required this.supabaseUrl,
    required this.supabaseKey,
    required String functionName,
    this.httpClient,
    super.serviceName,
    super.environment,
    super.additionalTags,
  })  : tableName = '',
        _edgeFunctionName = functionName,
        _isEdgeFunction = true;

  /// Supabase project URL (e.g., 'https://your-project.supabase.co').
  final String supabaseUrl;

  /// Supabase API key (anon key or service role key).
  final String supabaseKey;

  /// Table name for storing metrics events.
  final String tableName;

  /// Optional HTTP client for sending events.
  final dynamic httpClient;

  final String? _edgeFunctionName;
  final bool _isEdgeFunction;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    if (httpClient == null) return;

    final formatted = formatEvent(event);
    final url = _isEdgeFunction
        ? '$supabaseUrl/functions/v1/$_edgeFunctionName'
        : '$supabaseUrl/rest/v1/$tableName';

    // ignore: avoid_dynamic_calls
    await httpClient.post(
      url,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        if (!_isEdgeFunction) 'Prefer': 'return=minimal',
      },
      body: formatted,
    );
  }

  @override
  Map<String, dynamic> formatEvent(MetricsEvent event) {
    final baseMap = event.toMap();

    // Format for Supabase table columns
    return {
      'event_type': event.eventType,
      'service_name': serviceName,
      if (environment != null) 'environment': environment,
      'request_id': baseMap['request_id'],
      'duration_ms': baseMap['duration_ms'],
      'error_type': baseMap['error_type'],
      'error_message': baseMap['error_message'],
      'metadata': {
        ...baseMap,
        if (additionalTags.isNotEmpty) 'tags': additionalTags,
      },
    };
  }
}

/// Console logging adapter for development and debugging.
///
/// Outputs formatted metrics events to the console.
///
/// ## Example
///
/// ```dart
/// final adapter = ConsoleObservabilityAdapter(
///   prettyPrint: true,
///   filter: (event) => event is RequestFailureEvent,
/// );
///
/// adapter.connect(globalMetricsCollector);
/// ```
class ConsoleObservabilityAdapter extends ObservabilityAdapter {
  /// Creates a console logging adapter.
  ConsoleObservabilityAdapter({
    this.prettyPrint = false,
    this.filter,
    super.serviceName,
    super.environment,
    super.additionalTags,
  });

  /// Whether to pretty-print JSON output.
  final bool prettyPrint;

  /// Optional filter to only log specific events.
  final bool Function(MetricsEvent event)? filter;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    if (filter != null && !filter!(event)) return;

    final formatted = formatEvent(event);
    final output = prettyPrint
        ? _prettyPrint(formatted)
        : '[${event.eventType}] $formatted';

    // ignore: avoid_print
    print(output);
  }

  String _prettyPrint(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('--- Metrics Event ---');
    for (final entry in map.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln('---');
    return buffer.toString();
  }
}

/// Aggregating adapter that batches events before sending.
///
/// Useful for reducing API calls to observability platforms.
///
/// ## Example
///
/// ```dart
/// final innerAdapter = DataDogAdapter(apiKey: 'xxx');
/// final batchAdapter = BatchingObservabilityAdapter(
///   delegate: innerAdapter,
///   batchSize: 10,
///   flushInterval: Duration(seconds: 30),
/// );
///
/// batchAdapter.connect(globalMetricsCollector);
/// ```
class BatchingObservabilityAdapter extends ObservabilityAdapter {
  /// Creates a batching observability adapter.
  BatchingObservabilityAdapter({
    required this.delegate,
    this.batchSize = 10,
    this.flushInterval = const Duration(seconds: 30),
    super.serviceName,
    super.environment,
    super.additionalTags,
  });

  /// The underlying adapter to send batched events to.
  final ObservabilityAdapter delegate;

  /// Number of events to batch before sending.
  final int batchSize;

  /// Maximum time to wait before flushing events.
  final Duration flushInterval;

  final List<MetricsEvent> _buffer = [];
  Timer? _flushTimer;

  @override
  void connect(MetricsCollector collector) {
    super.connect(collector);
    _startFlushTimer();
  }

  @override
  void disconnect() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _flush();
    super.disconnect();
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(flushInterval, (_) => _flush());
  }

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    _buffer.add(event);

    if (_buffer.length >= batchSize) {
      await _flush();
    }
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    final events = List<MetricsEvent>.from(_buffer);
    _buffer.clear();

    for (final event in events) {
      try {
        await delegate.sendEvent(event);
      } on Exception catch (e, stack) {
        onError(e, stack);
      }
    }
  }

  /// Manually flush all buffered events.
  Future<void> flush() => _flush();

  @override
  void dispose() {
    disconnect();
    delegate.dispose();
    super.dispose();
  }
}
