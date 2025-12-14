# Debug Logging Configuration Guide

Configure logging for debugging and production monitoring in genui_anthropic.

## Table of Contents

- [Overview](#overview)
- [Setting Up Logging](#setting-up-logging)
- [Log Levels](#log-levels)
- [Filtering Logs](#filtering-logs)
- [Request ID Tracking](#request-id-tracking)
- [Integration Examples](#integration-examples)
- [Troubleshooting with Logs](#troubleshooting-with-logs)

---

## Overview

genui_anthropic uses Dart's `logging` package for structured logging. Logs include:
- Request lifecycle events
- Error details with stack traces
- Circuit breaker state changes
- Retry attempts
- SSE parsing issues

---

## Setting Up Logging

### Basic Setup

```dart
import 'package:logging/logging.dart';

void main() {
  // Configure logging before app starts
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack: ${record.stackTrace}');
    }
  });

  runApp(MyApp());
}
```

### Production Setup

```dart
void setupLogging() {
  // Only log warnings and above in production
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;

  Logger.root.onRecord.listen((record) {
    // Format: [LEVEL] LoggerName: Message
    final message = '[${record.level.name}] ${record.loggerName}: ${record.message}';

    if (kDebugMode) {
      // Print to console in debug
      print(message);
    } else {
      // Send to crash reporting in production
      if (record.level >= Level.WARNING) {
        crashReporting.log(message);
      }
      if (record.level >= Level.SEVERE) {
        crashReporting.recordError(
          record.error,
          record.stackTrace,
          reason: message,
        );
      }
    }
  });
}
```

---

## Log Levels

genui_anthropic uses these log levels:

| Level | Usage | Example |
|-------|-------|---------|
| `FINE` | Debug details | Request start, SSE events |
| `INFO` | Normal operations | Retry attempts, circuit recovery |
| `WARNING` | Issues | Errors, timeouts, circuit open |

### Level Recommendations

| Environment | Level |
|-------------|-------|
| Development | `Level.FINE` or `Level.ALL` |
| Staging | `Level.INFO` |
| Production | `Level.WARNING` |

```dart
// Development
Logger.root.level = Level.FINE;

// Production
Logger.root.level = Level.WARNING;
```

---

## Filtering Logs

### Filter by Logger Name

genui_anthropic uses these logger names:
- `DirectModeHandler`
- `ProxyModeHandler`
- `CircuitBreaker`

```dart
// Only show proxy handler logs
Logger.root.onRecord.listen((record) {
  if (record.loggerName == 'ProxyModeHandler') {
    print(record.message);
  }
});
```

### Filter by Level per Logger

```dart
// Different levels for different components
final proxyLogger = Logger('ProxyModeHandler');
proxyLogger.level = Level.FINE;  // Verbose

final circuitLogger = Logger('CircuitBreaker');
circuitLogger.level = Level.INFO;  // Normal
```

### Filter by Request ID

All logs include request IDs in the format `[Request UUID]`:

```dart
Logger.root.onRecord.listen((record) {
  // Extract request ID for filtering
  final requestIdMatch = RegExp(r'\[Request ([a-f0-9-]+)\]')
      .firstMatch(record.message);

  if (requestIdMatch != null) {
    final requestId = requestIdMatch.group(1);
    // Filter or tag by request ID
  }
});
```

---

## Request ID Tracking

Every request gets a unique UUID for correlation.

### In Logs

```
[FINE] ProxyModeHandler: [Request a1b2c3d4-e5f6-...] Starting proxy request
[INFO] ProxyModeHandler: [Request a1b2c3d4-e5f6-...] Retrying in 1000ms (attempt 1/3)
[WARNING] ProxyModeHandler: [Request a1b2c3d4-e5f6-...] Rate limited, no retries remaining
```

### In Error Events

```dart
generator.errorStream.listen((error) {
  final requestId = error['_requestId'] as String?;
  print('Error for request $requestId: ${error['error']}');
});
```

### In Metrics

```dart
collector.eventStream.listen((event) {
  print('Request ${event.requestId}: ${event.eventType}');
});
```

### End-to-End Tracing

```dart
// Client
final requestId = Uuid().v4();
print('Sending request $requestId');

// In logs
// [Request a1b2c3d4] Starting proxy request
// [Request a1b2c3d4] Request completed successfully

// In metrics
// Request a1b2c3d4: request_start
// Request a1b2c3d4: request_success
```

---

## Integration Examples

### Firebase Crashlytics

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;

  Logger.root.onRecord.listen((record) {
    // Log to Crashlytics
    FirebaseCrashlytics.instance.log(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );

    // Record errors
    if (record.error != null && record.level >= Level.WARNING) {
      FirebaseCrashlytics.instance.recordError(
        record.error!,
        record.stackTrace,
        reason: record.message,
        fatal: record.level >= Level.SEVERE,
      );
    }
  });
}
```

### Sentry

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void setupLogging() {
  Logger.root.level = Level.WARNING;

  Logger.root.onRecord.listen((record) {
    // Add breadcrumb
    Sentry.addBreadcrumb(Breadcrumb(
      message: record.message,
      category: record.loggerName,
      level: _toSentryLevel(record.level),
    ));

    // Capture errors
    if (record.error != null) {
      Sentry.captureException(
        record.error!,
        stackTrace: record.stackTrace,
      );
    }
  });
}

SentryLevel _toSentryLevel(Level level) {
  if (level >= Level.SEVERE) return SentryLevel.error;
  if (level >= Level.WARNING) return SentryLevel.warning;
  if (level >= Level.INFO) return SentryLevel.info;
  return SentryLevel.debug;
}
```

### Custom Backend

```dart
void setupLogging() {
  Logger.root.level = Level.INFO;

  Logger.root.onRecord.listen((record) async {
    // Send to your logging backend
    await http.post(
      Uri.parse('https://logs.example.com/ingest'),
      body: jsonEncode({
        'timestamp': record.time.toIso8601String(),
        'level': record.level.name,
        'logger': record.loggerName,
        'message': record.message,
        'error': record.error?.toString(),
        'stack_trace': record.stackTrace?.toString(),
      }),
    );
  });
}
```

### Local File Logging

```dart
import 'dart:io';

void setupFileLogging() async {
  final logFile = File('${Directory.systemTemp.path}/genui_anthropic.log');
  final sink = logFile.openWrite(mode: FileMode.append);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    sink.writeln(
      '${record.time.toIso8601String()} '
      '[${record.level.name}] '
      '${record.loggerName}: '
      '${record.message}',
    );
    if (record.error != null) {
      sink.writeln('  Error: ${record.error}');
    }
  });
}
```

---

## Troubleshooting with Logs

### Debug Request Flow

Enable verbose logging:

```dart
Logger.root.level = Level.FINE;
Logger('ProxyModeHandler').level = Level.FINE;
```

Expected output:
```
[FINE] ProxyModeHandler: [Request abc123] Starting proxy request
[FINE] ProxyModeHandler: [Request abc123] Sending request (attempt 0)
[FINE] ProxyModeHandler: [Request abc123] Request completed successfully
```

### Debug Retry Behavior

```dart
Logger.root.level = Level.INFO;
```

Expected output:
```
[INFO] ProxyModeHandler: [Request abc123] Rate limited, retrying in 1000ms (attempt 1/3)
[INFO] ProxyModeHandler: [Request abc123] Retrying in 2000ms (attempt 2/3)
[FINE] ProxyModeHandler: [Request abc123] Request completed successfully
```

### Debug Circuit Breaker

```dart
Logger('CircuitBreaker').level = Level.FINE;
```

Expected output:
```
[FINE] CircuitBreaker: [claude-api] Failure 1/5
[FINE] CircuitBreaker: [claude-api] Failure 2/5
[WARNING] CircuitBreaker: [claude-api] Circuit opened after 5 failures
[INFO] CircuitBreaker: [claude-api] Circuit entering half-open state
[FINE] CircuitBreaker: [claude-api] Half-open success 1/2
[INFO] CircuitBreaker: [claude-api] Circuit closed after successful recovery
```

### Debug SSE Parsing

```dart
Logger('ProxyModeHandler').level = Level.FINE;
```

If SSE parsing fails:
```
[WARNING] ProxyModeHandler: [Request abc123] Failed to parse SSE data: {invalid json}
```

### Common Log Patterns

**Successful request:**
```
[FINE] ProxyModeHandler: [Request abc] Starting proxy request
[FINE] ProxyModeHandler: [Request abc] Sending request (attempt 0)
[FINE] ProxyModeHandler: [Request abc] Request completed successfully
```

**Request with retry:**
```
[FINE] ProxyModeHandler: [Request abc] Starting proxy request
[FINE] ProxyModeHandler: [Request abc] Sending request (attempt 0)
[WARNING] ProxyModeHandler: [Request abc] HTTP error 500: Internal Server Error
[INFO] ProxyModeHandler: [Request abc] Retrying in 1000ms (attempt 1/3)
[FINE] ProxyModeHandler: [Request abc] Sending request (attempt 1)
[FINE] ProxyModeHandler: [Request abc] Request completed successfully
```

**Request failure:**
```
[FINE] ProxyModeHandler: [Request abc] Starting proxy request
[FINE] ProxyModeHandler: [Request abc] Sending request (attempt 0)
[WARNING] ProxyModeHandler: [Request abc] HTTP error 401: Unauthorized
[WARNING] ProxyModeHandler: [Request abc] Non-retryable error or max attempts reached
```

---

## Log Message Reference

### ProxyModeHandler

| Message Pattern | Level | Meaning |
|-----------------|-------|---------|
| `Starting proxy request` | FINE | Request initiated |
| `Circuit breaker is open` | WARNING | Circuit breaker blocking |
| `Sending request (attempt N)` | FINE | Attempt starting |
| `HTTP error N: ...` | WARNING | HTTP error response |
| `Rate limited, retrying in Nms` | INFO | Rate limit with retry |
| `Retrying in Nms` | INFO | General retry |
| `Non-retryable error or max attempts` | WARNING | Giving up |
| `Request completed successfully` | FINE | Success |
| `Request timed out` | WARNING | Timeout |
| `Stream inactivity timeout` | WARNING | Stream stalled |
| `Failed to parse SSE data` | WARNING | Invalid JSON |

### DirectModeHandler

| Message Pattern | Level | Meaning |
|-----------------|-------|---------|
| `Starting direct API request` | FINE | Request initiated |
| `Request completed successfully` | FINE | Success |
| `Claude API request failed` | WARNING | Error with details |

### CircuitBreaker

| Message Pattern | Level | Meaning |
|-----------------|-------|---------|
| `Failure N/M` | FINE | Failure counted |
| `Circuit opened after N failures` | WARNING | Circuit opened |
| `Circuit entering half-open state` | INFO | Recovery testing |
| `Half-open success N/M` | FINE | Recovery progress |
| `Failure in half-open state, reopening` | INFO | Recovery failed |
| `Circuit closed after successful recovery` | INFO | Fully recovered |
| `Circuit manually reset` | INFO | Manual intervention |
