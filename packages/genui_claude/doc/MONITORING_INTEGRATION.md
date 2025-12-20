# Monitoring & Observability Integration Guide

This guide explains how to integrate the `genui_claude` package with monitoring and observability platforms.

## Table of Contents

1. [MetricsCollector Overview](#metricscollector-overview)
2. [Built-in Observability Adapters](#built-in-observability-adapters)
3. [Built-in Metrics](#built-in-metrics)
4. [DataDog Integration](#datadog-integration)
5. [Firebase Analytics Integration](#firebase-analytics-integration)
6. [Supabase Integration](#supabase-integration)
7. [Prometheus Integration](#prometheus-integration)
8. [Custom Logging Backend](#custom-logging-backend)
9. [Dashboard Templates](#dashboard-templates)
10. [Alerting Recommendations](#alerting-recommendations)
11. [Request Tracing](#request-tracing)

---

## MetricsCollector Overview

The `MetricsCollector` provides real-time metrics for Claude API interactions:

```dart
// Enable metrics collection
final metricsCollector = MetricsCollector(enabled: true);

final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: proxyUri,
  authToken: authToken,
  metricsCollector: metricsCollector,
  catalog: catalog,
);

// Access aggregated statistics
final stats = metricsCollector.stats;
print('Total requests: ${stats.totalRequests}');
print('Success rate: ${stats.successRate}%');
print('Average latency: ${stats.averageLatency.inMilliseconds}ms');
```

### Event Stream

Subscribe to real-time metrics events:

```dart
metricsCollector.eventStream.listen((event) {
  switch (event) {
    case RequestStartEvent(:final requestId, :final timestamp):
      print('Request $requestId started at $timestamp');
    case RequestSuccessEvent(:final requestId, :final duration, :final tokenUsage):
      print('Request $requestId succeeded in ${duration.inMilliseconds}ms');
      print('Tokens: ${tokenUsage?.inputTokens} in, ${tokenUsage?.outputTokens} out');
    case RequestErrorEvent(:final requestId, :final error, :final isRetryable):
      print('Request $requestId failed: $error (retryable: $isRetryable)');
    case RetryEvent(:final requestId, :final attempt, :final delay):
      print('Request $requestId retrying (attempt $attempt after ${delay.inSeconds}s)');
  }
});
```

---

## Built-in Observability Adapters

The package includes built-in adapters for popular monitoring platforms. These adapters handle event formatting and delivery automatically.

### Quick Start

```dart
import 'package:genui_claude/genui_claude.dart';

// DataDog - built-in adapter
final dataDogAdapter = DataDogAdapter(
  apiKey: 'your-datadog-api-key',
  serviceName: 'my-app',
  environment: 'production',
);
dataDogAdapter.connect(globalMetricsCollector);

// Firebase Analytics - built-in adapter
final firebaseAdapter = FirebaseAnalyticsAdapter(
  serviceName: 'my-app',
  environment: 'production',
);
firebaseAdapter.connect(globalMetricsCollector);

// Supabase - built-in adapter (table mode)
final supabaseAdapter = SupabaseAdapter(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-anon-key',
  tableName: 'metrics_events',
);
supabaseAdapter.connect(globalMetricsCollector);

// Custom adapter - for any platform
final customAdapter = CustomObservabilityAdapter(
  onEvent: (event) async {
    await yourPlatform.sendEvent(event);
  },
  serviceName: 'my-app',
);
customAdapter.connect(globalMetricsCollector);
```

### Available Adapters

| Adapter | Use Case | Platform-Specific Features |
|---------|----------|---------------------------|
| `DataDogAdapter` | DataDog APM | ddtags, status levels, ddsource |
| `FirebaseAnalyticsAdapter` | Firebase Analytics | Parameter sanitization, snake_case keys |
| `SupabaseAdapter` | Supabase Database | Table mode, Edge Function mode |
| `ConsoleObservabilityAdapter` | Development/Debug | Pretty print, event filtering |
| `CustomObservabilityAdapter` | Any platform | Callback-based, custom formatting |
| `BatchingObservabilityAdapter` | Reduce API calls | Wraps any adapter with batching |

### Batching for High-Volume Apps

For high-traffic applications, wrap any adapter with `BatchingObservabilityAdapter`:

```dart
final innerAdapter = DataDogAdapter(apiKey: 'your-key');

final adapter = BatchingObservabilityAdapter(
  delegate: innerAdapter,
  batchSize: 20,          // Flush every 20 events
  flushInterval: const Duration(minutes: 1),  // Or every minute
);

adapter.connect(globalMetricsCollector);
```

### Development vs Production

```dart
// Development: Console logging
final adapter = ConsoleObservabilityAdapter(
  prettyPrint: true,
  filter: (event) => event is RequestFailureEvent, // Only failures
);

// Production: Real platform integration
final adapter = DataDogAdapter(
  apiKey: 'your-key',
  environment: kDebugMode ? 'development' : 'production',
);
```

---

## Built-in Metrics

### MetricsStats Properties

| Property | Type | Description |
|----------|------|-------------|
| `totalRequests` | `int` | Total number of requests made |
| `successfulRequests` | `int` | Number of successful requests |
| `failedRequests` | `int` | Number of failed requests |
| `successRate` | `double` | Success percentage (0-100) |
| `averageLatency` | `Duration` | Mean response time |
| `p50Latency` | `Duration` | Median response time |
| `p95Latency` | `Duration` | 95th percentile latency |
| `p99Latency` | `Duration` | 99th percentile latency |
| `totalRetries` | `int` | Total retry attempts |
| `totalTokensUsed` | `int` | Combined input + output tokens |

### Event Types

| Event | Properties | Description |
|-------|------------|-------------|
| `RequestStartEvent` | `requestId`, `timestamp` | Emitted when request begins |
| `RequestSuccessEvent` | `requestId`, `duration`, `tokenUsage` | Emitted on successful completion |
| `RequestErrorEvent` | `requestId`, `error`, `statusCode`, `isRetryable` | Emitted on failure |
| `RetryEvent` | `requestId`, `attempt`, `delay`, `reason` | Emitted before each retry |

---

## DataDog Integration

### Using Built-in Adapter (Recommended)

```dart
import 'package:genui_claude/genui_claude.dart';

// Simple setup with built-in adapter
final adapter = DataDogAdapter(
  apiKey: 'your-datadog-api-key',
  serviceName: 'my-app',
  environment: 'production',
  additionalTags: {'version': '1.0.0'},
);

adapter.connect(globalMetricsCollector);

// Don't forget to dispose when done
adapter.dispose();
```

The built-in `DataDogAdapter` automatically:
- Formats events with DataDog-specific fields (ddsource, ddtags, env)
- Sets appropriate status levels (info, warning, error)
- Includes all event metadata

### Custom DataDog Integration

For advanced use cases requiring DataDog Flutter plugin integration:

```dart
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';

class DataDogMetricsReporter {
  DataDogMetricsReporter(this.metricsCollector) {
    _subscription = metricsCollector.eventStream.listen(_handleEvent);
  }

  final MetricsCollector metricsCollector;
  late final StreamSubscription<MetricsEvent> _subscription;

  void _handleEvent(MetricsEvent event) {
    switch (event) {
      case RequestStartEvent(:final requestId):
        DatadogSdk.instance.rum?.startResource(
          requestId,
          RumHttpMethod.post,
          'claude-api-request',
        );

      case RequestSuccessEvent(:final requestId, :final duration, :final tokenUsage):
        DatadogSdk.instance.rum?.stopResource(
          requestId,
          200,
          RumResourceType.fetch,
        );

        // Custom metrics
        DatadogSdk.instance.rum?.addTiming('claude_request_duration', duration);
        if (tokenUsage != null) {
          DatadogSdk.instance.logs?.info(
            'Claude API tokens used',
            attributes: {
              'input_tokens': tokenUsage.inputTokens,
              'output_tokens': tokenUsage.outputTokens,
              'total_tokens': tokenUsage.totalTokens,
            },
          );
        }

      case RequestErrorEvent(:final requestId, :final error, :final statusCode):
        DatadogSdk.instance.rum?.stopResourceWithErrorInfo(
          requestId,
          error.toString(),
          error.runtimeType.toString(),
        );
        DatadogSdk.instance.logs?.error(
          'Claude API error',
          errorMessage: error.toString(),
          attributes: {'status_code': statusCode},
        );

      case RetryEvent(:final requestId, :final attempt):
        DatadogSdk.instance.logs?.warn(
          'Claude API retry',
          attributes: {
            'request_id': requestId,
            'attempt': attempt,
          },
        );
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
```

### DataDog Dashboard Configuration

```json
{
  "title": "Claude API Metrics",
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "title": "Request Rate",
        "requests": [{
          "q": "sum:claude.requests.count{*}.as_rate()"
        }]
      }
    },
    {
      "definition": {
        "type": "query_value",
        "title": "Success Rate",
        "requests": [{
          "q": "avg:claude.success_rate{*}"
        }]
      }
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "Latency Percentiles",
        "requests": [
          {"q": "p50:claude.latency{*}"},
          {"q": "p95:claude.latency{*}"},
          {"q": "p99:claude.latency{*}"}
        ]
      }
    }
  ]
}
```

---

## Firebase Analytics Integration

### Using Built-in Adapter (Recommended)

```dart
import 'package:genui_claude/genui_claude.dart';

// Simple setup with built-in adapter
final adapter = FirebaseAnalyticsAdapter(
  serviceName: 'my-app',
  environment: 'production',
  additionalTags: {'version': '1.0.0'},
);

adapter.connect(globalMetricsCollector);

// Don't forget to dispose when done
adapter.dispose();
```

The built-in `FirebaseAnalyticsAdapter` automatically:
- Sanitizes parameter names (replaces dashes with underscores)
- Formats events with Firebase-compatible structure
- Uses snake_case keys for all parameters

### Custom Firebase Integration

For advanced use cases requiring custom Firebase Analytics events:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseMetricsReporter {
  FirebaseMetricsReporter(this.metricsCollector) {
    _subscription = metricsCollector.eventStream.listen(_handleEvent);
  }

  final MetricsCollector metricsCollector;
  final _analytics = FirebaseAnalytics.instance;
  late final StreamSubscription<MetricsEvent> _subscription;

  void _handleEvent(MetricsEvent event) {
    switch (event) {
      case RequestStartEvent(:final requestId):
        _analytics.logEvent(
          name: 'claude_request_start',
          parameters: {'request_id': requestId},
        );

      case RequestSuccessEvent(:final requestId, :final duration, :final tokenUsage):
        _analytics.logEvent(
          name: 'claude_request_success',
          parameters: {
            'request_id': requestId,
            'duration_ms': duration.inMilliseconds,
            'input_tokens': tokenUsage?.inputTokens ?? 0,
            'output_tokens': tokenUsage?.outputTokens ?? 0,
          },
        );

      case RequestErrorEvent(:final requestId, :final error, :final statusCode):
        _analytics.logEvent(
          name: 'claude_request_error',
          parameters: {
            'request_id': requestId,
            'error_type': error.runtimeType.toString(),
            'status_code': statusCode ?? 0,
          },
        );

      case RetryEvent(:final requestId, :final attempt):
        _analytics.logEvent(
          name: 'claude_request_retry',
          parameters: {
            'request_id': requestId,
            'attempt': attempt,
          },
        );
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
```

### Firebase Performance Monitoring

```dart
import 'package:firebase_performance/firebase_performance.dart';

class FirebasePerformanceReporter {
  FirebasePerformanceReporter(this.metricsCollector) {
    _subscription = metricsCollector.eventStream.listen(_handleEvent);
  }

  final MetricsCollector metricsCollector;
  final _activeTraces = <String, Trace>{};
  late final StreamSubscription<MetricsEvent> _subscription;

  void _handleEvent(MetricsEvent event) async {
    switch (event) {
      case RequestStartEvent(:final requestId):
        final trace = FirebasePerformance.instance.newTrace('claude_api_call');
        await trace.start();
        _activeTraces[requestId] = trace;

      case RequestSuccessEvent(:final requestId, :final tokenUsage):
        final trace = _activeTraces.remove(requestId);
        if (trace != null) {
          trace.setMetric('input_tokens', tokenUsage?.inputTokens ?? 0);
          trace.setMetric('output_tokens', tokenUsage?.outputTokens ?? 0);
          await trace.stop();
        }

      case RequestErrorEvent(:final requestId, :final error):
        final trace = _activeTraces.remove(requestId);
        if (trace != null) {
          trace.putAttribute('error_type', error.runtimeType.toString());
          await trace.stop();
        }

      case RetryEvent():
        // Handled within the active trace
        break;
    }
  }

  void dispose() {
    _subscription.cancel();
    for (final trace in _activeTraces.values) {
      trace.stop();
    }
  }
}
```

---

## Supabase Integration

The built-in `SupabaseAdapter` supports two modes: direct table insertion and Edge Function forwarding.

### Table Mode (Recommended for Simple Setups)

```dart
import 'package:genui_claude/genui_claude.dart';

final adapter = SupabaseAdapter(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-anon-key',
  tableName: 'metrics_events',
  serviceName: 'my-app',
  environment: 'production',
);

adapter.connect(globalMetricsCollector);
```

### Edge Function Mode (For Custom Processing)

```dart
final adapter = SupabaseAdapter.edgeFunction(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-anon-key',
  functionName: 'process-metrics',
  serviceName: 'my-app',
);

adapter.connect(globalMetricsCollector);
```

### Required Supabase Table Schema

```sql
CREATE TABLE metrics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  request_id TEXT,
  service_name TEXT,
  environment TEXT,
  duration_ms INTEGER,
  error_type TEXT,
  error_message TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_metrics_events_timestamp ON metrics_events(timestamp);
CREATE INDEX idx_metrics_events_type ON metrics_events(event_type);
CREATE INDEX idx_metrics_events_request_id ON metrics_events(request_id);
```

### Sample Edge Function

```typescript
// supabase/functions/process-metrics/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const event = await req.json()

  // Custom processing logic
  const enrichedEvent = {
    ...event,
    processed_at: new Date().toISOString(),
    region: Deno.env.get('DENO_REGION'),
  }

  const { error } = await supabase
    .from('metrics_events')
    .insert(enrichedEvent)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

---

## Prometheus Integration

### Custom Exporter

```dart
import 'dart:io';

class PrometheusMetricsExporter {
  PrometheusMetricsExporter(this.metricsCollector, {this.port = 9090});

  final MetricsCollector metricsCollector;
  final int port;
  HttpServer? _server;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);
  }

  void _handleRequest(HttpRequest request) {
    if (request.uri.path == '/metrics') {
      final stats = metricsCollector.stats;
      final metrics = StringBuffer()
        ..writeln('# HELP claude_requests_total Total number of Claude API requests')
        ..writeln('# TYPE claude_requests_total counter')
        ..writeln('claude_requests_total ${stats.totalRequests}')
        ..writeln()
        ..writeln('# HELP claude_requests_success_total Successful requests')
        ..writeln('# TYPE claude_requests_success_total counter')
        ..writeln('claude_requests_success_total ${stats.successfulRequests}')
        ..writeln()
        ..writeln('# HELP claude_requests_failed_total Failed requests')
        ..writeln('# TYPE claude_requests_failed_total counter')
        ..writeln('claude_requests_failed_total ${stats.failedRequests}')
        ..writeln()
        ..writeln('# HELP claude_success_rate Success rate percentage')
        ..writeln('# TYPE claude_success_rate gauge')
        ..writeln('claude_success_rate ${stats.successRate}')
        ..writeln()
        ..writeln('# HELP claude_latency_milliseconds Request latency in ms')
        ..writeln('# TYPE claude_latency_milliseconds summary')
        ..writeln('claude_latency_milliseconds{quantile="0.5"} ${stats.p50Latency.inMilliseconds}')
        ..writeln('claude_latency_milliseconds{quantile="0.95"} ${stats.p95Latency.inMilliseconds}')
        ..writeln('claude_latency_milliseconds{quantile="0.99"} ${stats.p99Latency.inMilliseconds}')
        ..writeln()
        ..writeln('# HELP claude_retries_total Total retry attempts')
        ..writeln('# TYPE claude_retries_total counter')
        ..writeln('claude_retries_total ${stats.totalRetries}')
        ..writeln()
        ..writeln('# HELP claude_tokens_total Total tokens used')
        ..writeln('# TYPE claude_tokens_total counter')
        ..writeln('claude_tokens_total ${stats.totalTokensUsed}');

      request.response
        ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
        ..write(metrics)
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  Future<void> stop() async {
    await _server?.close();
  }
}
```

### Prometheus Configuration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'flutter_claude_api'
    static_configs:
      - targets: ['your-app-host:9090']
    scrape_interval: 15s
```

### Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Claude API Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [{
          "expr": "rate(claude_requests_total[5m])"
        }]
      },
      {
        "title": "Success Rate",
        "type": "gauge",
        "targets": [{
          "expr": "claude_success_rate"
        }],
        "options": {
          "minValue": 0,
          "maxValue": 100
        }
      },
      {
        "title": "Latency Distribution",
        "type": "graph",
        "targets": [
          {"expr": "claude_latency_milliseconds{quantile=\"0.5\"}", "legendFormat": "p50"},
          {"expr": "claude_latency_milliseconds{quantile=\"0.95\"}", "legendFormat": "p95"},
          {"expr": "claude_latency_milliseconds{quantile=\"0.99\"}", "legendFormat": "p99"}
        ]
      }
    ]
  }
}
```

---

## Custom Logging Backend

### Using Built-in CustomObservabilityAdapter (Recommended)

For most custom logging needs, use the built-in `CustomObservabilityAdapter`:

```dart
import 'package:genui_claude/genui_claude.dart';
import 'dart:convert';

final adapter = CustomObservabilityAdapter(
  onEvent: (event) async {
    // Send to any backend
    final json = jsonEncode(event);
    print(json); // Or send to your logging service
  },
  serviceName: 'my-app',
  environment: 'production',
  additionalTags: {'version': '1.0.0'},
  onErrorCallback: (error, stack) {
    // Handle send failures
    print('Failed to send metrics: $error');
  },
);

adapter.connect(globalMetricsCollector);
```

### Custom Formatter

You can provide a custom formatter to transform events:

```dart
final adapter = CustomObservabilityAdapter(
  onEvent: (event) async {
    await myLoggingService.send(event);
  },
  formatter: (event) => {
    'custom_format': true,
    'type': event.eventType,
    'data': event.toMap(),
    'app_version': '1.0.0',
  },
);
```

### Advanced: Custom Structured Logger

For more control, implement your own logger:

```dart
import 'dart:convert';

class StructuredMetricsLogger {
  StructuredMetricsLogger(this.metricsCollector, {this.logSink});

  final MetricsCollector metricsCollector;
  final void Function(String)? logSink;
  late final StreamSubscription<MetricsEvent> _subscription;

  void start() {
    _subscription = metricsCollector.eventStream.listen(_handleEvent);
  }

  void _handleEvent(MetricsEvent event) {
    final logEntry = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'service': 'genui_claude',
    };

    switch (event) {
      case RequestStartEvent(:final requestId, :final timestamp):
        logEntry.addAll({
          'event': 'request_start',
          'request_id': requestId,
          'event_timestamp': timestamp.toIso8601String(),
        });

      case RequestSuccessEvent(:final requestId, :final duration, :final tokenUsage):
        logEntry.addAll({
          'event': 'request_success',
          'request_id': requestId,
          'duration_ms': duration.inMilliseconds,
          'input_tokens': tokenUsage?.inputTokens,
          'output_tokens': tokenUsage?.outputTokens,
          'total_tokens': tokenUsage?.totalTokens,
        });

      case RequestErrorEvent(:final requestId, :final error, :final statusCode, :final isRetryable):
        logEntry.addAll({
          'event': 'request_error',
          'request_id': requestId,
          'error_type': error.runtimeType.toString(),
          'error_message': error.toString(),
          'status_code': statusCode,
          'is_retryable': isRetryable,
        });

      case RetryEvent(:final requestId, :final attempt, :final delay, :final reason):
        logEntry.addAll({
          'event': 'request_retry',
          'request_id': requestId,
          'attempt': attempt,
          'delay_ms': delay.inMilliseconds,
          'reason': reason,
        });
    }

    final json = jsonEncode(logEntry);
    logSink?.call(json) ?? print(json);
  }

  void dispose() {
    _subscription.cancel();
  }
}
```

---

## Dashboard Templates

### Key Metrics to Display

1. **Request Volume**
   - Requests per minute/hour
   - Success vs failure counts
   - Retry frequency

2. **Latency**
   - Average response time
   - P50, P95, P99 percentiles
   - Latency trends over time

3. **Error Analysis**
   - Error rate percentage
   - Error types breakdown
   - Retryable vs non-retryable errors

4. **Token Usage**
   - Total tokens consumed
   - Input vs output token ratio
   - Token usage trends

5. **Circuit Breaker Status**
   - Current state (closed/open/half-open)
   - State transition history
   - Failure threshold proximity

### Example Dashboard Layout

```
+----------------------------------+----------------------------------+
|       Request Rate (graph)       |      Success Rate (gauge)        |
|   [requests/min over time]       |        [0-100% dial]             |
+----------------------------------+----------------------------------+
|     Latency Percentiles          |      Error Breakdown             |
|   [p50/p95/p99 line chart]       |   [pie: network/rate/server]     |
+----------------------------------+----------------------------------+
|        Token Usage               |    Circuit Breaker Status        |
|  [stacked: input/output]         |    [state + failure count]       |
+----------------------------------+----------------------------------+
```

---

## Alerting Recommendations

### Critical Alerts

| Metric | Threshold | Action |
|--------|-----------|--------|
| Success Rate | < 95% for 5 min | Page on-call |
| P99 Latency | > 30s for 5 min | Page on-call |
| Circuit Breaker Open | Any | Notify team |
| Error Rate | > 10% for 3 min | Page on-call |

### Warning Alerts

| Metric | Threshold | Action |
|--------|-----------|--------|
| Success Rate | < 99% for 15 min | Slack notification |
| P95 Latency | > 10s for 10 min | Slack notification |
| Retry Rate | > 20% for 10 min | Slack notification |
| Token Usage | > 80% of budget | Email notification |

### Example Alert Configuration (Prometheus)

```yaml
groups:
  - name: claude_api_alerts
    rules:
      - alert: ClaudeAPIHighErrorRate
        expr: claude_success_rate < 95
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Claude API error rate is high"
          description: "Success rate is {{ $value }}%"

      - alert: ClaudeAPIHighLatency
        expr: claude_latency_milliseconds{quantile="0.99"} > 30000
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Claude API P99 latency is high"
          description: "P99 latency is {{ $value }}ms"

      - alert: ClaudeAPICircuitBreakerOpen
        expr: claude_circuit_breaker_state == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Claude API circuit breaker is open"
```

---

## Request Tracing

### Distributed Tracing with Request IDs

The package generates unique request IDs for each API call:

```dart
generator.errorStream.listen((error) {
  // Request ID is available in error context
  final requestId = extractRequestId(error);
  logger.error('Request $requestId failed', error: error);
});
```

### Correlating Frontend to Backend

```dart
// Frontend: Include request ID in custom headers
final customHeaders = {
  'X-Request-ID': requestId,
  'X-Trace-ID': traceId,
};

// These headers are forwarded to your proxy backend
// Backend can use them for log correlation
```

### Backend Logging Correlation

```typescript
// Backend proxy (TypeScript/Deno)
Deno.serve(async (req) => {
  const requestId = req.headers.get('X-Request-ID') || crypto.randomUUID();
  const traceId = req.headers.get('X-Trace-ID');

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    request_id: requestId,
    trace_id: traceId,
    action: 'claude_request_start',
  }));

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    // ... request config
  });

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    request_id: requestId,
    trace_id: traceId,
    action: 'claude_request_complete',
    status: response.status,
  }));

  return response;
});
```

---

## Best Practices

1. **Enable Metrics in Production**: Always enable `MetricsCollector` in production builds
2. **Sample High-Volume Events**: For high-traffic apps, consider sampling detailed events
3. **Set Up Alerting Early**: Configure alerts before going to production
4. **Monitor Token Usage**: Track tokens to manage costs and quotas
5. **Correlate with User Sessions**: Link request IDs to user sessions for debugging
6. **Retain Logs**: Keep logs for at least 30 days for incident investigation
7. **Test Alert Thresholds**: Validate alert configurations in staging

---

## Additional Resources

- [Production Guide](./PRODUCTION_GUIDE.md)
- [Security Best Practices](./SECURITY_BEST_PRACTICES.md)
- [API Reference](./API_REFERENCE.md)
- [Anthropic Console](https://console.anthropic.com/) - API usage dashboard
