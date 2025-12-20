import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/metrics/metrics_collector.dart';
import 'package:genui_claude/src/metrics/metrics_event.dart';
import 'package:genui_claude/src/metrics/observability.dart';
import 'package:genui_claude/src/resilience/circuit_breaker.dart';

void main() {
  group('ObservabilityAdapter', () {
    late MetricsCollector collector;

    setUp(() {
      collector = MetricsCollector();
    });

    tearDown(() {
      collector.dispose();
    });

    group('CustomObservabilityAdapter', () {
      test('receives events from collector', () async {
        final receivedEvents = <Map<String, dynamic>>[];

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            receivedEvents.add(event);
          },
        );

        adapter.connect(collector);

        // Emit an event
        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        // Allow async processing
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first['request_id'], equals('test-123'));
        expect(receivedEvents.first['service'], equals('genui_claude'));

        adapter.dispose();
      });

      test('formats events with service name and environment', () async {
        final receivedEvents = <Map<String, dynamic>>[];

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            receivedEvents.add(event);
          },
          serviceName: 'my-app',
          environment: 'production',
        );

        adapter.connect(collector);

        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(receivedEvents.first['service'], equals('my-app'));
        expect(receivedEvents.first['environment'], equals('production'));

        adapter.dispose();
      });

      test('includes additional tags', () async {
        final receivedEvents = <Map<String, dynamic>>[];

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            receivedEvents.add(event);
          },
          additionalTags: {'version': '1.0.0', 'region': 'us-east-1'},
        );

        adapter.connect(collector);

        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final tags = receivedEvents.first['tags'] as Map<String, String>;
        expect(tags['version'], equals('1.0.0'));
        expect(tags['region'], equals('us-east-1'));

        adapter.dispose();
      });

      test('uses custom formatter when provided', () async {
        final receivedEvents = <Map<String, dynamic>>[];

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            receivedEvents.add(event);
          },
          formatter: (event) => {'custom': 'format', 'type': event.eventType},
        );

        adapter.connect(collector);

        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(receivedEvents.first, equals({'custom': 'format', 'type': 'request_start'}));

        adapter.dispose();
      });

      test('calls error callback on failure', () async {
        Object? capturedError;

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            throw Exception('Send failed');
          },
          onErrorCallback: (error, stack) {
            capturedError = error;
          },
        );

        adapter.connect(collector);

        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(capturedError, isA<Exception>());

        adapter.dispose();
      });

      test('disconnect stops receiving events', () async {
        final receivedEvents = <Map<String, dynamic>>[];

        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {
            receivedEvents.add(event);
          },
        );

        adapter.connect(collector);
        adapter.disconnect();

        collector.recordRequestStart(
          requestId: 'test-123',
          endpoint: 'https://api.example.com',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(receivedEvents, isEmpty);

        adapter.dispose();
      });

      test('isConnected reflects connection state', () async {
        final adapter = CustomObservabilityAdapter(
          onEvent: (event) async {},
        );

        expect(adapter.isConnected, isFalse);

        adapter.connect(collector);
        expect(adapter.isConnected, isTrue);

        adapter.disconnect();
        expect(adapter.isConnected, isFalse);

        adapter.dispose();
      });
    });

    group('DataDogAdapter', () {
      test('formats events with DataDog structure', () {
        final adapter = DataDogAdapter(
          apiKey: 'test-api-key',
          serviceName: 'test-service',
          environment: 'staging',
        );

        final event = RequestStartEvent(
          timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
          requestId: 'req-123',
          endpoint: 'https://api.example.com',
          model: 'claude-3-opus',
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['ddsource'], equals('genui_claude'));
        expect(formatted['service'], equals('test-service'));
        expect(formatted['env'], equals('staging'));
        expect(formatted['ddtags'], contains('event_type:request_start'));
        expect(formatted['ddtags'], contains('service:test-service'));
        expect(formatted['ddtags'], contains('env:staging'));
        expect(formatted['message'], contains('Request started'));
        expect(formatted['status'], equals('info'));

        adapter.dispose();
      });

      test('sets error status for failure events', () {
        final adapter = DataDogAdapter(apiKey: 'test-key');

        final event = RequestFailureEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 500,
          errorType: 'NetworkException',
          errorMessage: 'Connection refused',
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['status'], equals('error'));
        expect(formatted['message'], contains('Request failed'));

        adapter.dispose();
      });

      test('sets warning status for circuit breaker open', () {
        final adapter = DataDogAdapter(apiKey: 'test-key');

        final event = CircuitBreakerStateChangeEvent(
          timestamp: DateTime.now(),
          circuitName: 'api',
          previousState: CircuitState.closed,
          newState: CircuitState.open,
          failureCount: 5,
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['status'], equals('warning'));
        expect(formatted['message'], contains('Circuit breaker'));

        adapter.dispose();
      });

      test('sets warning status for rate limit events', () {
        final adapter = DataDogAdapter(apiKey: 'test-key');

        final event = RateLimitEvent(
          timestamp: DateTime.now(),
          retryAfterMs: 5000,
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['status'], equals('warning'));
        expect(formatted['message'], equals('Rate limit encountered'));

        adapter.dispose();
      });
    });

    group('FirebaseAnalyticsAdapter', () {
      test('formats events with Firebase structure', () {
        final adapter = FirebaseAnalyticsAdapter(
          serviceName: 'test-app',
          environment: 'production',
        );

        final event = RequestSuccessEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 1500,
          totalRetries: 1,
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['service_name'], equals('test-app'));
        expect(formatted['environment'], equals('production'));
        expect(formatted['request_id'], equals('req-123'));
        expect(formatted['duration_ms'], equals(1500));

        adapter.dispose();
      });

      test('sanitizes parameter names for Firebase', () {
        final adapter = FirebaseAnalyticsAdapter();

        final event = LatencyEvent(
          timestamp: DateTime.now(),
          operation: 'test-operation',
          durationMs: 100,
          metadata: const {'key-with-dash': 'value'},
        );

        final formatted = adapter.formatEvent(event);

        // Keys should have dashes replaced with underscores
        expect(formatted.keys, everyElement(matches(RegExp(r'^[a-zA-Z0-9_]+$'))));

        adapter.dispose();
      });
    });

    group('SupabaseAdapter', () {
      test('formats events with Supabase table structure', () {
        final adapter = SupabaseAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseKey: 'test-key',
          serviceName: 'test-service',
          environment: 'staging',
        );

        final event = RequestSuccessEvent(
          timestamp: DateTime.now(),
          requestId: 'req-123',
          durationMs: 500,
          totalRetries: 0,
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['event_type'], equals('request_success'));
        expect(formatted['service_name'], equals('test-service'));
        expect(formatted['environment'], equals('staging'));
        expect(formatted['request_id'], equals('req-123'));
        expect(formatted['duration_ms'], equals(500));
        expect(formatted['metadata'], isA<Map<String, dynamic>>());

        adapter.dispose();
      });

      test('includes metadata in formatted event', () {
        final adapter = SupabaseAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseKey: 'test-key',
          additionalTags: {'version': '1.0.0'},
        );

        final event = RequestFailureEvent(
          timestamp: DateTime.now(),
          requestId: 'req-456',
          durationMs: 1000,
          errorType: 'NetworkException',
          errorMessage: 'Connection refused',
        );

        final formatted = adapter.formatEvent(event);

        expect(formatted['error_type'], equals('NetworkException'));
        expect(formatted['error_message'], equals('Connection refused'));
        final metadata = formatted['metadata'] as Map<String, dynamic>;
        final tags = metadata['tags'] as Map<String, String>;
        expect(tags['version'], equals('1.0.0'));

        adapter.dispose();
      });

      test('edgeFunction constructor sets correct mode', () {
        final adapter = SupabaseAdapter.edgeFunction(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseKey: 'test-key',
          functionName: 'process-metrics',
        );

        // Table name should be empty for edge function mode
        expect(adapter.tableName, isEmpty);

        adapter.dispose();
      });

      test('default table name is metrics_events', () {
        final adapter = SupabaseAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseKey: 'test-key',
        );

        expect(adapter.tableName, equals('metrics_events'));

        adapter.dispose();
      });
    });

    group('ConsoleObservabilityAdapter', () {
      test('creates adapter with default settings', () {
        final adapter = ConsoleObservabilityAdapter();

        expect(adapter.prettyPrint, isFalse);
        expect(adapter.filter, isNull);

        adapter.dispose();
      });

      test('filter excludes non-matching events', () async {
        var callCount = 0;

        final adapter = ConsoleObservabilityAdapter(
          filter: (event) => event is RequestFailureEvent,
        );

        // Override sendEvent to count calls
        final testAdapter = _TestConsoleAdapter(
          filter: (event) => event is RequestFailureEvent,
          onSend: () => callCount++,
        );

        testAdapter.connect(collector);

        // Emit a success event (should be filtered out)
        collector.recordRequestSuccess(
          requestId: 'test-123',
          duration: const Duration(milliseconds: 100),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(callCount, equals(0));

        testAdapter.dispose();
        adapter.dispose();
      });
    });

    group('BatchingObservabilityAdapter', () {
      test('batches events before sending', () async {
        final sentEvents = <MetricsEvent>[];

        final innerAdapter = _TestBatchingDelegate(
          onSend: sentEvents.add,
        );

        final adapter = BatchingObservabilityAdapter(
          delegate: innerAdapter,
          batchSize: 3,
          flushInterval: const Duration(seconds: 60),
        );

        adapter.connect(collector);

        // Send 2 events (below threshold)
        collector.recordRequestStart(requestId: '1', endpoint: 'test');
        collector.recordRequestStart(requestId: '2', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sentEvents, isEmpty);

        // Send 3rd event (triggers flush)
        collector.recordRequestStart(requestId: '3', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sentEvents, hasLength(3));

        adapter.dispose();
      });

      test('flushes on disconnect', () async {
        final sentEvents = <MetricsEvent>[];

        final innerAdapter = _TestBatchingDelegate(
          onSend: sentEvents.add,
        );

        final adapter = BatchingObservabilityAdapter(
          delegate: innerAdapter,
          flushInterval: const Duration(seconds: 60),
        );

        adapter.connect(collector);

        collector.recordRequestStart(requestId: '1', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sentEvents, isEmpty);

        adapter.disconnect();

        expect(sentEvents, hasLength(1));

        adapter.dispose();
      });

      test('manual flush sends all buffered events', () async {
        final sentEvents = <MetricsEvent>[];

        final innerAdapter = _TestBatchingDelegate(
          onSend: sentEvents.add,
        );

        final adapter = BatchingObservabilityAdapter(
          delegate: innerAdapter,
          batchSize: 100,
          flushInterval: const Duration(seconds: 60),
        );

        adapter.connect(collector);

        collector.recordRequestStart(requestId: '1', endpoint: 'test');
        collector.recordRequestStart(requestId: '2', endpoint: 'test');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sentEvents, isEmpty);

        await adapter.flush();

        expect(sentEvents, hasLength(2));

        adapter.dispose();
      });
    });
  });
}

/// Test helper for ConsoleObservabilityAdapter.
class _TestConsoleAdapter extends ConsoleObservabilityAdapter {
  _TestConsoleAdapter({
    required this.onSend,
    super.filter,
  });

  final void Function() onSend;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    if (filter != null && !filter!(event)) return;
    onSend();
  }
}

/// Test helper for BatchingObservabilityAdapter delegate.
class _TestBatchingDelegate extends ObservabilityAdapter {
  _TestBatchingDelegate({required this.onSend});

  final void Function(MetricsEvent) onSend;

  @override
  Future<void> sendEvent(MetricsEvent event) async {
    onSend(event);
  }
}
