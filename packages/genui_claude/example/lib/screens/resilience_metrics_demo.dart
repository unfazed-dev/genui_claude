import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui_claude/genui_claude.dart';

/// Resilience & Metrics demo screen demonstrating ALL resilience features.
///
/// This example shows comprehensive resilience and observability capabilities:
/// - ClaudeException hierarchy: all 8 exception types with properties
/// - CircuitBreaker: states, configs, manual control, state transitions
/// - MetricsCollector: live event stream, aggregated stats, percentiles
/// - MetricsEvent: all 8 event types with their properties
/// - ExceptionFactory: creating exceptions from HTTP status codes
class ResilienceMetricsDemoScreen extends StatefulWidget {
  const ResilienceMetricsDemoScreen({super.key});

  @override
  State<ResilienceMetricsDemoScreen> createState() =>
      _ResilienceMetricsDemoScreenState();
}

class _ResilienceMetricsDemoScreenState
    extends State<ResilienceMetricsDemoScreen> {
  // Circuit breaker with metrics integration
  late final MetricsCollector _metricsCollector;
  late final CircuitBreaker _circuitBreaker;
  StreamSubscription<MetricsEvent>? _metricsSubscription;

  // UI state
  final List<String> _eventLog = [];
  CircuitBreakerConfig _selectedConfig = CircuitBreakerConfig.defaults;
  String _selectedConfigName = 'defaults';

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    // Create metrics collector
    _metricsCollector = MetricsCollector();

    // Create circuit breaker with metrics
    _circuitBreaker = CircuitBreaker(
      config: _selectedConfig,
      name: 'demo-circuit',
      metricsCollector: _metricsCollector,
    );

    // Subscribe to metrics events
    _metricsSubscription = _metricsCollector.eventStream.listen((event) {
      _addEvent('${event.eventType}: ${_formatEventDetails(event)}');
    });
  }

  String _formatEventDetails(MetricsEvent event) {
    return switch (event) {
      final CircuitBreakerStateChangeEvent e =>
        '${e.previousState.name} → ${e.newState.name}',
      final RetryAttemptEvent e => 'attempt ${e.attempt}/${e.maxAttempts}',
      final RequestStartEvent e => 'endpoint: ${e.endpoint}',
      final RequestSuccessEvent e => 'duration: ${e.durationMs}ms',
      final RequestFailureEvent e => '${e.errorType}: ${e.errorMessage}',
      final RateLimitEvent e => 'retry after: ${e.retryAfterMs}ms',
      final LatencyEvent e => '${e.operation}: ${e.durationMs}ms',
      final StreamInactivityEvent e => 'timeout: ${e.timeoutMs}ms',
    };
  }

  void _addEvent(String event) {
    setState(() {
      _eventLog.insert(
          0, '[${DateTime.now().toString().substring(11, 19)}] $event',);
      if (_eventLog.length > 30) {
        _eventLog.removeLast();
      }
    });
  }

  void _updateCircuitBreakerConfig(String configName) {
    setState(() {
      _selectedConfigName = configName;
      _selectedConfig = switch (configName) {
        'defaults' => CircuitBreakerConfig.defaults,
        'lenient' => CircuitBreakerConfig.lenient,
        'strict' => CircuitBreakerConfig.strict,
        _ => CircuitBreakerConfig.defaults,
      };
    });

    // Recreate circuit breaker with new config
    _circuitBreaker = CircuitBreaker(
      config: _selectedConfig,
      name: 'demo-circuit',
      metricsCollector: _metricsCollector,
    );

    _addEvent('Config changed to $_selectedConfigName');
  }

  void _simulateSuccess() {
    try {
      _circuitBreaker.checkState();
      _circuitBreaker.recordSuccess();
      _addEvent('Recorded success');

      // Also record in metrics
      final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
      _metricsCollector.recordRequestStart(
        requestId: requestId,
        endpoint: '/demo/success',
      );
      _metricsCollector.recordRequestSuccess(
        requestId: requestId,
        duration: Duration(milliseconds: 100 + (DateTime.now().millisecond % 400)),
      );
    } on CircuitBreakerOpenException catch (e) {
      _addEvent('Blocked: ${e.message}');
    }
    setState(() {});
  }

  void _simulateFailure() {
    try {
      _circuitBreaker.checkState();
      _circuitBreaker.recordFailure();
      _addEvent('Recorded failure (${_circuitBreaker.failureCount} total)');

      // Also record in metrics
      final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
      _metricsCollector.recordRequestStart(
        requestId: requestId,
        endpoint: '/demo/failure',
      );
      _metricsCollector.recordRequestFailure(
        requestId: requestId,
        duration: const Duration(milliseconds: 50),
        errorType: 'SimulatedError',
        errorMessage: 'Demo failure',
      );
    } on CircuitBreakerOpenException catch (e) {
      _addEvent('Blocked: ${e.message}');
    }
    setState(() {});
  }

  void _simulateRetry() {
    _metricsCollector.recordRetryAttempt(
      attempt: 1,
      maxAttempts: 3,
      delay: const Duration(seconds: 1),
      reason: 'Server error',
      statusCode: 503,
    );
    _addEvent('Simulated retry attempt');
  }

  void _simulateRateLimit() {
    _metricsCollector.recordRateLimit(
      retryAfter: const Duration(seconds: 30),
      retryAfterHeader: '30',
    );
    _addEvent('Simulated rate limit');
  }

  void _resetCircuitBreaker() {
    _circuitBreaker.reset();
    _addEvent('Circuit breaker reset');
    setState(() {});
  }

  void _resetStats() {
    _metricsCollector.resetStats();
    _addEvent('Metrics stats reset');
    setState(() {});
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _metricsCollector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resilience & Metrics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildExceptionTypesSection(),
            const SizedBox(height: 24),
            _buildCircuitBreakerSection(),
            const SizedBox(height: 24),
            _buildMetricsStatsSection(),
            const SizedBox(height: 24),
            _buildMetricsEventsSection(),
            const SizedBox(height: 24),
            _buildEventLogSection(),
            const SizedBox(height: 24),
            _buildCodeSnippet(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Resilience & Observability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This demo showcases ALL resilience and metrics features:\n'
              '• 8 Exception Types (sealed class hierarchy)\n'
              '• Circuit Breaker (3 states, 3 presets, metrics integration)\n'
              '• MetricsCollector (event stream, aggregated stats)\n'
              '• 8 Metrics Event Types (request lifecycle, retries, etc.)\n'
              '• ExceptionFactory (HTTP status to exception mapping)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Exception Hierarchy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'ClaudeException (sealed base class)',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            _buildExceptionRow('NetworkException', 'DNS, connection, socket', true),
            _buildExceptionRow('TimeoutException', 'Request exceeded timeout', true),
            _buildExceptionRow('AuthenticationException', '401/403 responses', false),
            _buildExceptionRow('RateLimitException', '429 + retryAfter', true),
            _buildExceptionRow('ValidationException', '400/422 client errors', false),
            _buildExceptionRow('ServerException', '5xx server errors', true),
            _buildExceptionRow('StreamException', 'SSE parsing errors', false),
            _buildExceptionRow('CircuitBreakerOpenException', 'Circuit tripped', true),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('ExceptionFactory.fromHttpStatus()'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFactoryDemo(401, 'AuthenticationException'),
                      _buildFactoryDemo(403, 'AuthenticationException'),
                      _buildFactoryDemo(429, 'RateLimitException'),
                      _buildFactoryDemo(400, 'ValidationException'),
                      _buildFactoryDemo(500, 'ServerException'),
                      _buildFactoryDemo(503, 'ServerException'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionRow(String name, String description, bool isRetryable) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(
            isRetryable ? Icons.refresh : Icons.block,
            size: 14,
            color: isRetryable ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: Text(
              name,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactoryDemo(int statusCode, String exceptionType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(statusCode),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$statusCode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(' → '),
          Text(
            exceptionType,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int code) {
    if (code >= 500) return Colors.red;
    if (code >= 400) return Colors.orange;
    return Colors.green;
  }

  Widget _buildCircuitBreakerSection() {
    final stateColor = switch (_circuitBreaker.state) {
      CircuitState.closed => Colors.green,
      CircuitState.open => Colors.red,
      CircuitState.halfOpen => Colors.orange,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.electric_bolt, color: stateColor),
                const SizedBox(width: 8),
                Text(
                  'Circuit Breaker',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // State visualization
            Row(
              children: [
                _buildStateChip('closed', CircuitState.closed),
                const Icon(Icons.arrow_forward, size: 16),
                _buildStateChip('open', CircuitState.open),
                const Icon(Icons.arrow_forward, size: 16),
                _buildStateChip('halfOpen', CircuitState.halfOpen),
              ],
            ),
            const SizedBox(height: 16),

            // Current stats
            Row(
              children: [
                _StatChip(
                  label: 'state',
                  value: _circuitBreaker.state.name,
                  icon: Icons.circle,
                  color: stateColor,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'failures',
                  value: _circuitBreaker.failureCount.toString(),
                  icon: Icons.error,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'allowsRequest',
                  value: _circuitBreaker.allowsRequest.toString(),
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Config presets
            Row(
              children: [
                const Text('Config: '),
                DropdownButton<String>(
                  value: _selectedConfigName,
                  items: ['defaults', 'lenient', 'strict'].map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (v) => _updateCircuitBreakerConfig(v ?? 'defaults'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'threshold: ${_selectedConfig.failureThreshold}, '
                    'recovery: ${_selectedConfig.recoveryTimeout.inSeconds}s',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _simulateSuccess,
                  icon: const Icon(Icons.check),
                  label: const Text('Success'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _simulateFailure,
                  icon: const Icon(Icons.close),
                  label: const Text('Failure'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetCircuitBreaker,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(String name, CircuitState state) {
    final isActive = _circuitBreaker.state == state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? switch (state) {
                CircuitState.closed => Colors.green,
                CircuitState.open => Colors.red,
                CircuitState.halfOpen => Colors.orange,
              }
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMetricsStatsSection() {
    final stats = _metricsCollector.stats;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'MetricsStats (Aggregated)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _resetStats,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Request stats
            _buildStatsRow('totalRequests', stats.totalRequests.toString()),
            _buildStatsRow('successfulRequests', stats.successfulRequests.toString()),
            _buildStatsRow('failedRequests', stats.failedRequests.toString()),
            _buildStatsRow('activeRequests', stats.activeRequests.toString()),
            _buildStatsRow('successRate', '${stats.successRate.toStringAsFixed(1)}%'),
            const Divider(),

            // Latency stats
            _buildStatsRow('averageLatencyMs', '${stats.averageLatencyMs.toStringAsFixed(1)}ms'),
            _buildStatsRow('p50LatencyMs', '${stats.p50LatencyMs}ms'),
            _buildStatsRow('p95LatencyMs', '${stats.p95LatencyMs}ms'),
            _buildStatsRow('p99LatencyMs', '${stats.p99LatencyMs}ms'),
            const Divider(),

            // Event counts
            _buildStatsRow('totalRetries', stats.totalRetries.toString()),
            _buildStatsRow('rateLimitEvents', stats.rateLimitEvents.toString()),
            _buildStatsRow('circuitBreakerEvents', stats.circuitBreakerEvents.toString()),
            _buildStatsRow('circuitBreakerOpens', stats.circuitBreakerOpens.toString()),
            _buildStatsRow('streamInactivityEvents', stats.streamInactivityEvents.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsEventsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'MetricsEvent Types',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'MetricsEvent (sealed base class)',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            _buildEventTypeRow('CircuitBreakerStateChangeEvent', 'circuitName, previousState, newState'),
            _buildEventTypeRow('RetryAttemptEvent', 'attempt, maxAttempts, delayMs, reason'),
            _buildEventTypeRow('RequestStartEvent', 'requestId, endpoint, model'),
            _buildEventTypeRow('RequestSuccessEvent', 'durationMs, totalRetries, firstTokenMs'),
            _buildEventTypeRow('RequestFailureEvent', 'errorType, errorMessage, statusCode'),
            _buildEventTypeRow('RateLimitEvent', 'retryAfterMs, retryAfterHeader'),
            _buildEventTypeRow('LatencyEvent', 'operation, durationMs, metadata'),
            _buildEventTypeRow('StreamInactivityEvent', 'timeoutMs, lastActivityMs'),
            const SizedBox(height: 16),

            // Simulate events
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _simulateRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Event'),
                ),
                OutlinedButton.icon(
                  onPressed: _simulateRateLimit,
                  icon: const Icon(Icons.speed, size: 16),
                  label: const Text('Rate Limit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeRow(String name, String properties) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chevron_right, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                Text(
                  properties,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Live Event Log',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(_eventLog.clear),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _eventLog.isEmpty
                  ? const Center(
                      child: Text(
                        'Events will appear here...\nTry clicking Success/Failure above!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _eventLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _eventLog[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSnippet() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Complete API Reference',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                r'''
// === Exception Hierarchy ===
// ClaudeException (sealed base)
//   - message, requestId, statusCode, isRetryable, typeName
// Subclasses:
//   NetworkException, TimeoutException, AuthenticationException
//   RateLimitException, ValidationException, ServerException
//   StreamException, CircuitBreakerOpenException

// Create from HTTP status:
final exception = ExceptionFactory.fromHttpStatus(
  statusCode: 429,
  body: 'Rate limited',
  requestId: 'req-123',
  retryAfter: Duration(seconds: 30),
);

// === Circuit Breaker ===
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults, // or lenient, strict
  name: 'api',
  metricsCollector: collector,
);
breaker.checkState();    // Throws if open
breaker.recordSuccess(); // On success
breaker.recordFailure(); // On failure
breaker.reset();         // Manual reset
breaker.state;           // CircuitState.closed/open/halfOpen
breaker.failureCount;
breaker.allowsRequest;

// === Metrics Collector ===
final collector = MetricsCollector(
  enabled: true,
  aggregationEnabled: true,
);

// Listen to events
collector.eventStream.listen((event) {
  print('${event.eventType}: ${event.toMap()}');
});

// Record events
collector.recordRequestStart(requestId: id, endpoint: url);
collector.recordRequestSuccess(requestId: id, duration: d);
collector.recordRequestFailure(requestId: id, ...);
collector.recordRetryAttempt(attempt: 1, maxAttempts: 3, ...);
collector.recordRateLimit(retryAfter: Duration(seconds: 30));
collector.recordLatency(operation: 'parse', duration: d);

// Access stats
final stats = collector.stats;
stats.totalRequests;
stats.successRate;
stats.averageLatencyMs;
stats.p50LatencyMs / p95LatencyMs / p99LatencyMs;
collector.resetStats();
collector.dispose();''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.2) ??
            Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: color != null ? Border.all(color: color!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
