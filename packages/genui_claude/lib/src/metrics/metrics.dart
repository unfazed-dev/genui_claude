/// Metrics collection and export for production monitoring.
///
/// This module provides comprehensive metrics collection for:
/// - Circuit breaker state changes
/// - Retry attempts and statistics
/// - Request lifecycle (start, success, failure)
/// - Rate limiting events
/// - Latency measurements
/// - Stream inactivity detection
///
/// ## Quick Start
///
/// ```dart
/// import 'package:genui_claude/genui_claude.dart';
///
/// // Listen to metrics events
/// globalMetricsCollector.eventStream.listen((event) {
///   print('${event.eventType}: ${event.toMap()}');
/// });
///
/// // Access aggregated statistics
/// final stats = globalMetricsCollector.stats;
/// print('Success rate: ${stats.successRate}%');
/// print('P95 latency: ${stats.p95LatencyMs}ms');
/// ```
///
/// ## Custom Collector
///
/// For isolated metrics or testing:
///
/// ```dart
/// final collector = MetricsCollector(
///   enabled: true,
///   aggregationEnabled: true,
/// );
///
/// // Inject into handler
/// final handler = ProxyModeHandler(
///   endpoint: proxyEndpoint,
///   metricsCollector: collector,
/// );
/// ```
library;

export 'metrics_collector.dart';
export 'metrics_event.dart';
