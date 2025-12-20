# API Reference

Complete API documentation for the `genui_claude` package.

## Table of Contents

- [Installation](#installation)
- [Core Classes](#core-classes)
  - [ClaudeContentGenerator](#claudecontentgenerator)
  - [ClaudeConfig](#claudeconfig)
  - [ProxyConfig](#proxyconfig)
  - [RetryConfig](#retryconfig)
- [Resilience Classes](#resilience-classes)
  - [CircuitBreaker](#circuitbreaker)
  - [CircuitBreakerConfig](#circuitbreakerconfig)
  - [CircuitState](#circuitstate)
- [Metrics Classes](#metrics-classes)
  - [MetricsCollector](#metricscollector)
  - [MetricsStats](#metricsstats)
  - [MetricsEvent](#metricsevent)
  - [globalMetricsCollector](#globalmetricscollector)
- [Observability Classes](#observability-classes)
  - [ObservabilityAdapter](#observabilityadapter)
  - [CustomObservabilityAdapter](#customobservabilityadapter)
  - [DataDogAdapter](#datadogadapter)
  - [FirebaseAnalyticsAdapter](#firebaseanalyticsadapter)
  - [SupabaseAdapter](#supabaseadapter)
  - [ConsoleObservabilityAdapter](#consoleobservabilityadapter)
  - [BatchingObservabilityAdapter](#batchingobservabilityadapter)
- [Exception Classes](#exception-classes)
  - [ClaudeException](#claudeexception)
  - [Exception Types](#exception-types)
  - [ExceptionFactory](#exceptionfactory)
- [Adapter Classes](#adapter-classes)
  - [A2uiMessageAdapter](#a2uimessageadapter)
  - [CatalogToolBridge](#catalogtoolbridge)
  - [A2uiControlTools](#a2uicontroltools)
- [Utility Classes](#utility-classes)
  - [MessageConverter](#messageconverter)
- [Data Binding Classes](#data-binding-classes)
  - [BindingController](#bindingcontroller)
  - [BindingPath](#bindingpath)
  - [BindingDefinition](#bindingdefinition)
  - [BindingMode](#bindingmode)
  - [BindingRegistry](#bindingregistry)
- [Tool Search Classes](#tool-search-classes)
  - [ToolCatalogIndex](#toolcatalogindex)
  - [KeywordExtractor](#keywordextractor)
  - [IndexedCatalogItem](#indexedcatalogitem)
  - [ToolSearchHandler](#toolsearchhandler)
- [Handler Classes](#handler-classes)
  - [ApiHandler](#apihandler)
  - [ApiRequest](#apirequest)
  - [DirectModeHandler](#directmodehandler)
  - [ProxyModeHandler](#proxymodehandler)

---

## Installation

```yaml
dependencies:
  genui: ^0.6.0
  genui_claude:
    git:
      url: https://github.com/unfazed-dev/genui_claude.git
      path: packages/genui_claude
```

---

## Core Classes

### ClaudeContentGenerator

Main ContentGenerator implementation for Claude AI. Provides the bridge between Claude's API and the GenUI SDK.

**Implements:** `ContentGenerator`

#### Constructors

##### Default Constructor (Direct Mode)

```dart
ClaudeContentGenerator({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  String? systemInstruction,
  ClaudeConfig config = ClaudeConfig.defaults,
})
```

Use for development and prototyping. API key is used directly in the client.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | `String` | Yes | - | Your Claude API key |
| `model` | `String` | No | `'claude-sonnet-4-20250514'` | Claude model ID |
| `systemInstruction` | `String?` | No | `null` | System prompt for Claude |
| `config` | `ClaudeConfig` | No | `ClaudeConfig.defaults` | Configuration options |

##### Proxy Constructor (Production)

```dart
ClaudeContentGenerator.proxy({
  required Uri proxyEndpoint,
  String? authToken,
  ProxyConfig proxyConfig = ProxyConfig.defaults,
})
```

Recommended for production. API key stays on your backend server.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `proxyEndpoint` | `Uri` | Yes | - | Backend proxy URL |
| `authToken` | `String?` | No | `null` | User authentication token |
| `proxyConfig` | `ProxyConfig` | No | `ProxyConfig.defaults` | Proxy configuration |

##### Handler Constructor (Testing)

```dart
@visibleForTesting
ClaudeContentGenerator.withHandler({
  required ApiHandler handler,
  String? model,
  String? systemInstruction,
})
```

For testing and advanced use cases with custom handlers.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isDirectMode` | `bool` | Whether using direct API mode |
| `systemInstruction` | `String?` | System instruction for requests |
| `a2uiMessageStream` | `Stream<A2uiMessage>` | Stream of UI generation messages |
| `textResponseStream` | `Stream<String>` | Stream of text response chunks |
| `errorStream` | `Stream<ContentGeneratorError>` | Stream of errors |
| `isProcessing` | `ValueListenable<bool>` | Processing state notifier |

#### Methods

##### sendRequest

```dart
Future<void> sendRequest(
  ChatMessage message, {
  Iterable<ChatMessage>? history,
})
```

Sends a request to Claude and processes the streaming response.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | `ChatMessage` | Yes | The user message to send |
| `history` | `Iterable<ChatMessage>?` | No | Previous conversation messages |

**Behavior:**
- Returns immediately if already processing (emits error)
- Sets `isProcessing` to `true` during request
- Emits A2UI messages, text chunks, and errors to respective streams
- Sets `isProcessing` to `false` when complete

##### dispose

```dart
void dispose()
```

Releases all resources. Call when the generator is no longer needed.

---

### ClaudeConfig

Configuration for direct Claude API mode.

```dart
const ClaudeConfig({
  int maxTokens = 4096,
  Duration timeout = const Duration(seconds: 60),
  int retryAttempts = 3,
  bool enableStreaming = true,
  Map<String, String>? headers,
  double? topP,
  int? topK,
  List<String>? stopSequences,
  bool enableFineGrainedStreaming = false,
  bool enableInterleavedThinking = false,
  int? thinkingBudgetTokens,
  bool enableToolSearch = false,
  int maxLoadedToolsPerSession = 50,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `maxTokens` | `int` | `4096` | Maximum tokens in response |
| `timeout` | `Duration` | `60 seconds` | Request timeout duration |
| `retryAttempts` | `int` | `3` | Retry attempts for transient failures |
| `enableStreaming` | `bool` | `true` | Enable streaming responses |
| `headers` | `Map<String, String>?` | `null` | Custom HTTP headers |
| `topP` | `double?` | `null` | Nucleus sampling (0.0 < x ≤ 1.0). Controls cumulative probability cutoff. |
| `topK` | `int?` | `null` | Top-k sampling (≥1). Limits token selection to k most likely. |
| `stopSequences` | `List<String>?` | `null` | Sequences that stop generation (max 4, each ≤100 chars) |
| `enableFineGrainedStreaming` | `bool` | `false` | Enable fine-grained tool streaming beta |
| `enableInterleavedThinking` | `bool` | `false` | Enable interleaved thinking beta for Claude 4+ |
| `thinkingBudgetTokens` | `int?` | `null` | Max tokens for thinking (when thinking enabled) |
| `enableToolSearch` | `bool` | `false` | Enable dynamic tool discovery for large catalogs |
| `maxLoadedToolsPerSession` | `int` | `50` | Max tools loadable per session (when tool search enabled) |

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `defaults` | `ClaudeConfig` | Default configuration instance |

#### Methods

##### copyWith

```dart
ClaudeConfig copyWith({
  int? maxTokens,
  Duration? timeout,
  int? retryAttempts,
  bool? enableStreaming,
  Map<String, String>? headers,
  double? topP,
  int? topK,
  List<String>? stopSequences,
  bool? enableFineGrainedStreaming,
  bool? enableInterleavedThinking,
  int? thinkingBudgetTokens,
  bool? enableToolSearch,
  int? maxLoadedToolsPerSession,
})
```

Creates a copy with specified fields replaced.

---

### ProxyConfig

Configuration for backend proxy mode.

```dart
const ProxyConfig({
  Duration timeout = const Duration(seconds: 120),
  int retryAttempts = 3,
  Map<String, String>? headers,
  bool includeHistory = true,
  int maxHistoryMessages = 20,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `timeout` | `Duration` | `120 seconds` | Request timeout duration |
| `retryAttempts` | `int` | `3` | Retry attempts for failures |
| `headers` | `Map<String, String>?` | `null` | Custom HTTP headers (in addition to auth) |
| `includeHistory` | `bool` | `true` | Whether to send conversation history |
| `maxHistoryMessages` | `int` | `20` | Maximum history messages to include |

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `defaults` | `ProxyConfig` | Default configuration instance |

#### Methods

##### copyWith

```dart
ProxyConfig copyWith({
  Duration? timeout,
  int? retryAttempts,
  Map<String, String>? headers,
  bool? includeHistory,
  int? maxHistoryMessages,
})
```

Creates a copy with specified fields replaced.

---

### RetryConfig

Configuration for retry behavior with exponential backoff.

```dart
const RetryConfig({
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  double backoffMultiplier = 2.0,
  double jitterFactor = 0.1,
  Set<int> retryableStatusCodes = defaultRetryableStatusCodes,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `maxAttempts` | `int` | `3` | Maximum retry attempts (0 = no retries) |
| `initialDelay` | `Duration` | `1 second` | Initial delay before first retry |
| `maxDelay` | `Duration` | `30 seconds` | Maximum delay cap |
| `backoffMultiplier` | `double` | `2.0` | Exponential backoff multiplier |
| `jitterFactor` | `double` | `0.1` | Random jitter factor (0.0-1.0) |
| `retryableStatusCodes` | `Set<int>` | `{429, 500, 502, 503, 504}` | HTTP codes that trigger retry |

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `defaults` | `RetryConfig` | Default configuration |
| `noRetry` | `RetryConfig` | No retries (maxAttempts: 0) |
| `aggressive` | `RetryConfig` | More retries, longer waits |
| `defaultRetryableStatusCodes` | `Set<int>` | Default retryable status codes |

#### Methods

##### getDelayForAttempt

```dart
Duration getDelayForAttempt(int attempt, [Random? random])
```

Calculates the delay for a given attempt number using exponential backoff with jitter.

```dart
final config = RetryConfig.defaults;
final delay = config.getDelayForAttempt(0); // ~1 second
final delay2 = config.getDelayForAttempt(1); // ~2 seconds
final delay3 = config.getDelayForAttempt(2); // ~4 seconds
```

##### shouldRetryStatusCode

```dart
bool shouldRetryStatusCode(int statusCode)
```

Checks if an HTTP status code should trigger a retry.

##### copyWith

```dart
RetryConfig copyWith({
  int? maxAttempts,
  Duration? initialDelay,
  Duration? maxDelay,
  double? backoffMultiplier,
  double? jitterFactor,
  Set<int>? retryableStatusCodes,
})
```

Creates a copy with specified fields replaced.

---

## Resilience Classes

### CircuitBreaker

Circuit breaker pattern to prevent cascading failures.

```dart
CircuitBreaker({
  CircuitBreakerConfig config = CircuitBreakerConfig.defaults,
  String name = 'default',
  MetricsCollector? metricsCollector,
})
```

#### States

The circuit breaker has three states:

| State | Description | Behavior |
|-------|-------------|----------|
| `closed` | Normal operation | Requests pass through |
| `open` | Failing fast | Requests rejected immediately |
| `halfOpen` | Testing recovery | Limited requests allowed |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Name for logging and identification |
| `state` | `CircuitState` | Current circuit state |
| `failureCount` | `int` | Current failure count |
| `lastFailureTime` | `DateTime?` | Time of last recorded failure |
| `allowsRequest` | `bool` | Whether the circuit allows requests |

#### Methods

##### checkState

```dart
void checkState()
```

Checks if request is allowed. Throws `CircuitBreakerOpenException` if circuit is open.

```dart
try {
  breaker.checkState();
  final result = await makeRequest();
  breaker.recordSuccess();
  return result;
} catch (e) {
  breaker.recordFailure();
  rethrow;
}
```

##### recordSuccess

```dart
void recordSuccess()
```

Records a successful operation. In half-open state, after enough successes, closes the circuit.

##### recordFailure

```dart
void recordFailure()
```

Records a failed operation. If threshold is reached, opens the circuit.

##### reset

```dart
void reset()
```

Manually resets the circuit breaker to closed state.

#### Example

```dart
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.defaults,
  name: 'claude-api',
  metricsCollector: globalMetricsCollector,
);

// Use in request flow
try {
  breaker.checkState();
  final response = await callApi();
  breaker.recordSuccess();
  return response;
} on CircuitBreakerOpenException catch (e) {
  // Circuit is open, fail fast
  print('Circuit open, retry after: ${e.recoveryTime}');
} catch (e) {
  breaker.recordFailure();
  rethrow;
}
```

---

### CircuitBreakerConfig

Configuration for circuit breaker behavior.

```dart
const CircuitBreakerConfig({
  int failureThreshold = 5,
  Duration recoveryTimeout = const Duration(seconds: 30),
  int halfOpenSuccessThreshold = 2,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `failureThreshold` | `int` | `5` | Failures before opening |
| `recoveryTimeout` | `Duration` | `30 seconds` | Wait time before half-open |
| `halfOpenSuccessThreshold` | `int` | `2` | Successes to close from half-open |

#### Static Presets

| Preset | failureThreshold | recoveryTimeout | halfOpenSuccessThreshold | Use Case |
|--------|-----------------|-----------------|--------------------------|----------|
| `defaults` | 5 | 30s | 2 | Balanced |
| `lenient` | 10 | 60s | 3 | High tolerance |
| `strict` | 3 | 15s | 1 | Fast failure detection |
| `sla999` | 3 | 15s | 1 | 99.9% SLA (3 nines) |
| `sla9999` | 2 | 10s | 2 | 99.99% SLA (4 nines) |
| `highAvailability` | 1 | 5s | 3 | Mission-critical systems |

#### SLA-Based Presets

Choose circuit breaker presets based on your SLA requirements:

```dart
// 99.9% SLA - 8.76 hours/year downtime tolerance
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.sla999,
);

// 99.99% SLA - 52.6 minutes/year downtime tolerance
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.sla9999,
);

// Maximum resilience for mission-critical systems
final breaker = CircuitBreaker(
  config: CircuitBreakerConfig.highAvailability,
);
```

| SLA Level | Allowed Downtime/Year | Recommended Preset |
|-----------|----------------------|-------------------|
| 99.9% (3 nines) | 8.76 hours | `sla999` |
| 99.99% (4 nines) | 52.6 minutes | `sla9999` |
| 99.999% (5 nines) | 5.26 minutes | `highAvailability` |

#### Methods

##### copyWith

```dart
CircuitBreakerConfig copyWith({
  int? failureThreshold,
  Duration? recoveryTimeout,
  int? halfOpenSuccessThreshold,
})
```

---

### CircuitState

Enum representing circuit breaker states.

```dart
enum CircuitState {
  closed,   // Normal operation
  open,     // Failing fast
  halfOpen, // Testing recovery
}
```

---

## Metrics Classes

### MetricsCollector

Collects and streams metrics events for monitoring and observability.

```dart
MetricsCollector({
  bool enabled = true,
  bool aggregationEnabled = true,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `enabled` | `bool` | Whether metrics collection is enabled |
| `aggregationEnabled` | `bool` | Whether to maintain aggregated statistics |
| `eventStream` | `Stream<MetricsEvent>` | Broadcast stream of metrics events |
| `stats` | `MetricsStats` | Aggregated statistics |

#### Methods

##### Record Methods

```dart
void recordCircuitBreakerStateChange({...})
void recordRetryAttempt({...})
void recordRequestStart({...})
void recordRequestSuccess({...})
void recordRequestFailure({...})
void recordRateLimit({...})
void recordLatency({...})
void recordStreamInactivity({...})
```

##### resetStats

```dart
void resetStats()
```

Resets all aggregated statistics.

##### dispose

```dart
void dispose()
```

Disposes of the collector and closes the event stream.

#### Example

```dart
final collector = MetricsCollector();

// Listen to metrics events
collector.eventStream.listen((event) {
  // Send to your monitoring system
  datadog.track(event.eventType, event.toMap());
});

// Access aggregated statistics
print('Success rate: ${collector.stats.successRate}%');
print('P95 latency: ${collector.stats.p95LatencyMs}ms');
```

---

### MetricsStats

Aggregated statistics from collected metrics. Access via `MetricsCollector.stats`.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `totalRequests` | `int` | Total requests started |
| `activeRequests` | `int` | Currently active requests |
| `successfulRequests` | `int` | Successful requests |
| `failedRequests` | `int` | Failed requests |
| `totalRetries` | `int` | Total retry attempts |
| `rateLimitEvents` | `int` | Rate limit events |
| `circuitBreakerEvents` | `int` | Circuit breaker state changes |
| `circuitBreakerOpens` | `int` | Times circuit breaker opened |
| `streamInactivityEvents` | `int` | Stream inactivity events |
| `successRate` | `double` | Success rate percentage (0-100) |
| `averageLatencyMs` | `double` | Average latency in ms |
| `p50LatencyMs` | `int` | 50th percentile (median) latency |
| `p95LatencyMs` | `int` | 95th percentile latency |
| `p99LatencyMs` | `int` | 99th percentile latency |

#### Methods

##### toMap

```dart
Map<String, dynamic> toMap()
```

Converts statistics to a map for serialization.

---

### MetricsEvent

Sealed base class for all metrics events.

```dart
sealed class MetricsEvent {
  DateTime get timestamp;
  String? get requestId;
  String get eventType;
  Map<String, dynamic> toMap();
}
```

#### Event Types

| Event Type | Description |
|------------|-------------|
| `CircuitBreakerStateChangeEvent` | Circuit breaker state transitions |
| `RetryAttemptEvent` | Retry attempts with delay info |
| `RequestStartEvent` | Request started |
| `RequestSuccessEvent` | Request completed successfully |
| `RequestFailureEvent` | Request failed |
| `RateLimitEvent` | Rate limit encountered |
| `LatencyEvent` | Custom latency measurement |
| `StreamInactivityEvent` | Stream stall detected |

---

### globalMetricsCollector

Global metrics collector instance for convenience.

```dart
MetricsCollector get globalMetricsCollector
```

Use when you don't need multiple isolated collectors.

```dart
// Enable global metrics
globalMetricsCollector.eventStream.listen((event) {
  print('Metrics: ${event.toMap()}');
});

// Access stats
print('Success rate: ${globalMetricsCollector.stats.successRate}%');
```

---

## Observability Classes

### ObservabilityAdapter

Abstract base class for observability platform integrations. Connect to a `MetricsCollector` to receive and forward events.

```dart
abstract class ObservabilityAdapter {
  void connect(MetricsCollector collector);
  void disconnect();
  void dispose();
  bool get isConnected;
  Future<void> sendEvent(MetricsEvent event);
  Map<String, dynamic> formatEvent(MetricsEvent event);
}
```

#### Methods

| Method | Description |
|--------|-------------|
| `connect(collector)` | Start receiving events from a collector |
| `disconnect()` | Stop receiving events |
| `dispose()` | Release all resources |
| `sendEvent(event)` | Send a single event (override in subclasses) |
| `formatEvent(event)` | Format event for the platform (override in subclasses) |

---

### CustomObservabilityAdapter

Callback-based adapter for custom integrations.

```dart
CustomObservabilityAdapter({
  required Future<void> Function(Map<String, dynamic>) onEvent,
  String serviceName = 'genui_claude',
  String? environment,
  Map<String, String> additionalTags = const {},
  Map<String, dynamic> Function(MetricsEvent)? formatter,
  void Function(Object, StackTrace)? onErrorCallback,
})
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `onEvent` | `Future<void> Function(Map<String, dynamic>)` | Yes | - | Callback for each event |
| `serviceName` | `String` | No | `'genui_claude'` | Service name in events |
| `environment` | `String?` | No | `null` | Environment tag |
| `additionalTags` | `Map<String, String>` | No | `{}` | Extra tags added to events |
| `formatter` | `Function?` | No | `null` | Custom event formatter |
| `onErrorCallback` | `Function?` | No | `null` | Error handler |

#### Example

```dart
final adapter = CustomObservabilityAdapter(
  onEvent: (event) async {
    await myAnalytics.track(event['event_type'], event);
  },
  serviceName: 'my-app',
  environment: 'production',
  additionalTags: {'version': '1.0.0'},
);

adapter.connect(globalMetricsCollector);
```

---

### DataDogAdapter

DataDog-specific event formatting and delivery.

```dart
DataDogAdapter({
  required String apiKey,
  String serviceName = 'genui_claude',
  String? environment,
  String? host,
  Map<String, String> additionalTags = const {},
})
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | `String` | Yes | - | DataDog API key |
| `serviceName` | `String` | No | `'genui_claude'` | Service name |
| `environment` | `String?` | No | `null` | Environment (staging, production) |
| `host` | `String?` | No | `null` | Host identifier |
| `additionalTags` | `Map<String, String>` | No | `{}` | Additional tags |

#### Event Format

Events are formatted with DataDog-specific fields:

```json
{
  "ddsource": "genui_claude",
  "service": "my-app",
  "env": "production",
  "ddtags": "event_type:request_success,service:my-app,env:production",
  "message": "Request completed successfully",
  "status": "info",
  "timestamp": "2024-01-15T10:30:00Z",
  ...event_data
}
```

#### Status Mapping

| Event Type | Status |
|------------|--------|
| `RequestFailureEvent` | `error` |
| `CircuitBreakerStateChangeEvent` (to open) | `warning` |
| `RateLimitEvent` | `warning` |
| Other events | `info` |

---

### FirebaseAnalyticsAdapter

Firebase Analytics integration with parameter name sanitization.

```dart
FirebaseAnalyticsAdapter({
  String serviceName = 'genui_claude',
  String? environment,
  Map<String, String> additionalTags = const {},
})
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `serviceName` | `String` | No | `'genui_claude'` | Service name |
| `environment` | `String?` | No | `null` | Environment tag |
| `additionalTags` | `Map<String, String>` | No | `{}` | Additional tags |

#### Features

- Automatically sanitizes parameter names (replaces dashes with underscores)
- Firebase-compatible event structure
- All keys use snake_case format

---

### SupabaseAdapter

Supabase table insertion and Edge Function support.

#### Table Mode Constructor

```dart
SupabaseAdapter({
  required String supabaseUrl,
  required String supabaseKey,
  String tableName = 'metrics_events',
  String serviceName = 'genui_claude',
  String? environment,
  Map<String, String> additionalTags = const {},
})
```

#### Edge Function Mode Constructor

```dart
SupabaseAdapter.edgeFunction({
  required String supabaseUrl,
  required String supabaseKey,
  required String functionName,
  String serviceName = 'genui_claude',
  String? environment,
  Map<String, String> additionalTags = const {},
})
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `supabaseUrl` | `String` | Yes | - | Supabase project URL |
| `supabaseKey` | `String` | Yes | - | Supabase anon/service key |
| `tableName` | `String` | No | `'metrics_events'` | Target table name |
| `functionName` | `String` | Yes (edge) | - | Edge Function name |
| `serviceName` | `String` | No | `'genui_claude'` | Service name |
| `environment` | `String?` | No | `null` | Environment tag |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `tableName` | `String` | Target table (empty for edge function mode) |

#### Supabase Table Schema

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

CREATE INDEX idx_metrics_events_timestamp ON metrics_events(timestamp);
CREATE INDEX idx_metrics_events_type ON metrics_events(event_type);
CREATE INDEX idx_metrics_events_request_id ON metrics_events(request_id);
```

#### Example

```dart
// Table mode
final adapter = SupabaseAdapter(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-anon-key',
  tableName: 'metrics_events',
  environment: 'production',
);

// Edge Function mode
final adapter = SupabaseAdapter.edgeFunction(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-anon-key',
  functionName: 'process-metrics',
);

adapter.connect(globalMetricsCollector);
```

---

### ConsoleObservabilityAdapter

Console logging adapter for development and debugging.

```dart
ConsoleObservabilityAdapter({
  bool prettyPrint = false,
  bool Function(MetricsEvent)? filter,
})
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prettyPrint` | `bool` | `false` | Pretty-print JSON output |
| `filter` | `Function?` | `null` | Filter function for events |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `prettyPrint` | `bool` | Whether to pretty-print output |
| `filter` | `Function?` | Current filter function |

#### Example

```dart
// Log only failure events
final adapter = ConsoleObservabilityAdapter(
  prettyPrint: true,
  filter: (event) => event is RequestFailureEvent,
);

adapter.connect(globalMetricsCollector);
```

---

### BatchingObservabilityAdapter

Batches events before sending to reduce API calls.

```dart
BatchingObservabilityAdapter({
  required ObservabilityAdapter delegate,
  int batchSize = 10,
  Duration flushInterval = const Duration(seconds: 30),
})
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `delegate` | `ObservabilityAdapter` | Yes | - | Underlying adapter |
| `batchSize` | `int` | No | `10` | Events before auto-flush |
| `flushInterval` | `Duration` | No | `30 seconds` | Max time before flush |

#### Methods

| Method | Description |
|--------|-------------|
| `flush()` | Manually flush all buffered events |

#### Behavior

- Buffers events until `batchSize` is reached
- Auto-flushes after `flushInterval`
- Flushes remaining events on `disconnect()` or `dispose()`

#### Example

```dart
final innerAdapter = DataDogAdapter(apiKey: 'your-key');

final adapter = BatchingObservabilityAdapter(
  delegate: innerAdapter,
  batchSize: 20,
  flushInterval: const Duration(minutes: 1),
);

adapter.connect(globalMetricsCollector);

// Force flush when needed
await adapter.flush();
```

---

## Exception Classes

### ClaudeException

Sealed base class for all Claude API errors.

```dart
sealed class ClaudeException implements Exception {
  String get message;
  String? get requestId;
  int? get statusCode;
  Object? get originalError;
  StackTrace? get stackTrace;
  bool get isRetryable;
  String get typeName;
}
```

Use pattern matching for exhaustive error handling:

```dart
try {
  await generator.sendRequest(message);
} on ClaudeException catch (e) {
  switch (e) {
    case NetworkException():
      // Handle network error
    case TimeoutException(:final timeout):
      // Handle timeout
    case AuthenticationException():
      // Handle auth error
    case RateLimitException(:final retryAfter):
      // Handle rate limit
    case ValidationException():
      // Handle validation error
    case ServerException():
      // Handle server error
    case StreamException():
      // Handle stream error
    case CircuitBreakerOpenException(:final recoveryTime):
      // Handle circuit open
  }
}
```

---

### Exception Types

| Exception | Status Code | isRetryable | Description |
|-----------|-------------|-------------|-------------|
| `NetworkException` | - | `true` | Network failures (DNS, connection refused) |
| `TimeoutException` | - | `true` | Request timeout exceeded |
| `AuthenticationException` | 401, 403 | `false` | Invalid credentials |
| `RateLimitException` | 429 | `true` | Rate limit exceeded |
| `ValidationException` | 400, 422 | `false` | Request validation errors |
| `ServerException` | 5xx | `true` | Server-side errors |
| `StreamException` | - | `false` | SSE parsing errors |
| `CircuitBreakerOpenException` | - | `true` | Circuit breaker is open |

#### TimeoutException

```dart
final class TimeoutException extends ClaudeException {
  Duration get timeout;  // The timeout duration that was exceeded
}
```

#### RateLimitException

```dart
final class RateLimitException extends ClaudeException {
  Duration? get retryAfter;  // Suggested wait time before retrying
}
```

#### CircuitBreakerOpenException

```dart
final class CircuitBreakerOpenException extends ClaudeException {
  DateTime? get recoveryTime;  // When the circuit will attempt recovery
}
```

---

### ExceptionFactory

Factory for creating appropriate exceptions from HTTP responses.

#### Static Methods

##### fromHttpStatus

```dart
static ClaudeException fromHttpStatus({
  required int statusCode,
  required String body,
  String? requestId,
  Duration? retryAfter,
})
```

Creates an appropriate exception based on HTTP status code.

```dart
final exception = ExceptionFactory.fromHttpStatus(
  statusCode: 429,
  body: 'Rate limit exceeded',
  requestId: 'req_123',
  retryAfter: Duration(seconds: 30),
);
// Returns RateLimitException
```

##### parseRetryAfter

```dart
static Duration? parseRetryAfter(String? value)
```

Parses Retry-After header value to Duration. Supports both seconds (integer) and HTTP-date formats.

---

## Adapter Classes

### A2uiMessageAdapter

Converts a2ui_claude message types to GenUI A2uiMessage types.

#### Static Methods

##### toGenUiMessage

```dart
static A2uiMessage toGenUiMessage(A2uiMessageData data)
```

Converts a single a2ui_claude message to GenUI format.

| Input Type | Output Type |
|------------|-------------|
| `BeginRenderingData` | `BeginRendering` |
| `SurfaceUpdateData` | `SurfaceUpdate` |
| `DataModelUpdateData` | `DataModelUpdate` |
| `DeleteSurfaceData` | `SurfaceDeletion` |

##### toGenUiMessages

```dart
static List<A2uiMessage> toGenUiMessages(List<A2uiMessageData> messages)
```

Converts a list of messages.

---

### CatalogToolBridge

Bridges GenUI Catalog items to A2UI tool schemas for Claude.

#### Static Methods

##### fromItems

```dart
static List<A2uiToolSchema> fromItems(List<CatalogItem> items)
```

Converts catalog items to tool schemas.

```dart
final tools = CatalogToolBridge.fromItems(myCatalog.items.toList());
```

##### fromCatalog

```dart
static List<A2uiToolSchema> fromCatalog(Catalog catalog)
```

Extracts and converts tools from a Catalog instance.

```dart
final tools = CatalogToolBridge.fromCatalog(myCatalog);
```

##### withA2uiTools

```dart
static List<A2uiToolSchema> withA2uiTools(List<A2uiToolSchema> widgetTools)
```

Prepends A2UI control tools to widget tools.

```dart
final allTools = CatalogToolBridge.withA2uiTools(widgetTools);
// Returns: [begin_rendering, surface_update, data_model_update, delete_surface, ...widgetTools]
```

---

### A2uiControlTools

Pre-defined A2UI control tool schemas for Claude.

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `beginRendering` | `A2uiToolSchema` | Signal start of UI generation |
| `surfaceUpdate` | `A2uiToolSchema` | Update widget tree of a surface |
| `dataModelUpdate` | `A2uiToolSchema` | Update data model |
| `deleteSurface` | `A2uiToolSchema` | Delete a UI surface |
| `all` | `List<A2uiToolSchema>` | All control tools |

#### Tool Schemas

##### begin_rendering

Signal the start of UI generation for a surface.

```json
{
  "surfaceId": "string (required)",
  "parentSurfaceId": "string (optional)"
}
```

##### surface_update

Update the widget tree of a surface.

```json
{
  "surfaceId": "string (required)",
  "widgets": "array (required)",
  "append": "boolean (optional)"
}
```

##### data_model_update

Update data model bound to UI components.

```json
{
  "updates": "object (required)",
  "scope": "string (optional)"
}
```

##### delete_surface

Delete a UI surface.

```json
{
  "surfaceId": "string (required)",
  "cascade": "boolean (optional)"
}
```

---

## Utility Classes

### MessageConverter

Converts GenUI ChatMessage types to Claude API format.

#### Static Methods

##### toClaudeMessages

```dart
static List<Map<String, dynamic>> toClaudeMessages(List<ChatMessage> messages)
```

Converts GenUI messages to Claude API format.

| GenUI Type | Claude Format |
|------------|---------------|
| `UserMessage` | `{role: 'user', content: ...}` |
| `UserUiInteractionMessage` | `{role: 'user', content: ...}` |
| `AiTextMessage` | `{role: 'assistant', content: ...}` |
| `AiUiMessage` | `{role: 'assistant', content: ...}` |
| `ToolResponseMessage` | `{role: 'user', content: [{type: 'tool_result', ...}]}` |
| `InternalMessage` | Skipped (returns `null`) |

##### pruneHistory

```dart
static List<Map<String, dynamic>> pruneHistory(
  List<Map<String, dynamic>> messages, {
  required int maxMessages,
})
```

Prunes conversation history to maximum size while preserving user-assistant pair boundaries.

```dart
final pruned = MessageConverter.pruneHistory(messages, maxMessages: 20);
```

##### extractSystemContext

```dart
static String? extractSystemContext(List<ChatMessage> messages)
```

Extracts system context from InternalMessages.

---

## Data Binding Classes

### BindingController

Orchestrates data binding between widgets and the data model.

```dart
BindingController({
  required BindingRegistry registry,
  required DataModelSubscribe subscribe,
  required DataModelUpdate update,
})
```

#### Type Definitions

```dart
/// Function to subscribe to data model paths
typedef DataModelSubscribe = ValueNotifier<dynamic> Function(BindingPath path);

/// Function to update data model values
typedef DataModelUpdate = void Function(BindingPath path, dynamic value);
```

#### Methods

##### processWidgetBindings

```dart
void processWidgetBindings({
  required String surfaceId,
  required String widgetId,
  required dynamic dataBinding,
})
```

Processes widget bindings from a `dataBinding` specification. Supports:
- String path: `'form.email'` (binds to "value" property)
- Map with paths: `{'value': 'form.email'}`
- Map with config: `{'value': {'path': 'form.email', 'mode': 'twoWay'}}`

##### getValueNotifier

```dart
ValueNotifier<dynamic>? getValueNotifier({
  required String widgetId,
  required String property,
})
```

Gets the `ValueNotifier` for a specific widget property binding. Applies `toWidget` transformer if defined.

##### updateFromWidget

```dart
void updateFromWidget({
  required String widgetId,
  required String property,
  required dynamic value,
})
```

Updates the data model from a widget change (two-way binding only). Applies `toModel` transformer if defined.

##### unregisterWidget / unregisterSurface

```dart
void unregisterWidget(String widgetId)
void unregisterSurface(String surfaceId)
```

Removes all bindings for a widget or surface.

#### Example

```dart
final controller = BindingController(
  registry: BindingRegistry(),
  subscribe: dataModel.subscribe,
  update: dataModel.update,
);

// Process bindings from SurfaceUpdate
controller.processWidgetBindings(
  surfaceId: 'form-surface',
  widgetId: 'email-input',
  dataBinding: {'value': {'path': 'form.email', 'mode': 'twoWay'}},
);

// Get reactive value for widget
final notifier = controller.getValueNotifier(
  widgetId: 'email-input',
  property: 'value',
);

// Two-way binding: widget → model
controller.updateFromWidget(
  widgetId: 'email-input',
  property: 'value',
  value: 'new@example.com',
);
```

---

### BindingPath

Represents a parsed binding path with support for dot and slash notation.

#### Factory Constructors

```dart
// A2UI dot notation: "form.email", "items[0].name"
factory BindingPath.fromDotNotation(String path)

// GenUI slash notation: "/form/email", "/items/0/name"
factory BindingPath.fromSlashNotation(String path)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `segments` | `List<String>` | Path segments (e.g., `['form', 'email']`) |
| `isAbsolute` | `bool` | Whether path starts from root |
| `parent` | `BindingPath?` | Parent path (null if single segment) |
| `leaf` | `String` | Last segment (property name or index) |

#### Methods

```dart
String toDotNotation()   // "form.items[0].name"
String toSlashNotation() // "/form/items/0/name"
BindingPath join(BindingPath other)
bool startsWith(BindingPath other)
```

#### Example

```dart
final path = BindingPath.fromDotNotation('form.items[0].name');
print(path.segments);      // ['form', 'items', '0', 'name']
print(path.toSlashNotation()); // '/form/items/0/name'
print(path.parent?.toDotNotation()); // 'form.items[0]'
print(path.leaf);          // 'name'
```

---

### BindingDefinition

Defines how a widget property binds to a data model path.

```dart
const BindingDefinition({
  required String property,
  required BindingPath path,
  BindingMode mode = BindingMode.oneWay,
  ValueTransformer? toWidget,
  ValueTransformer? toModel,
})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `property` | `String` | - | Widget property being bound (e.g., "value") |
| `path` | `BindingPath` | - | Data model path to bind to |
| `mode` | `BindingMode` | `oneWay` | Binding direction mode |
| `toWidget` | `ValueTransformer?` | `null` | Model → widget value transformer |
| `toModel` | `ValueTransformer?` | `null` | Widget → model value transformer |

#### Static Methods

```dart
static List<BindingDefinition> parse(dynamic dataBinding)
```

Parses binding definitions from A2UI `dataBinding` field formats.

---

### BindingMode

Enum representing binding direction.

```dart
enum BindingMode {
  oneWay,        // Model → Widget only (default)
  twoWay,        // Model ↔ Widget (bidirectional)
  oneWayToSource, // Widget → Model only (rare)
}
```

---

### BindingRegistry

Multi-index registry for efficient binding lookups.

```dart
BindingRegistry()
```

#### Methods

| Method | Description |
|--------|-------------|
| `register(WidgetBinding)` | Registers a binding |
| `getBindingForWidgetProperty(widgetId, property)` | Lookup by widget+property |
| `getBindingsForWidget(widgetId)` | All bindings for a widget |
| `getBindingsForSurface(surfaceId)` | All bindings for a surface |
| `getBindingsForPath(BindingPath)` | All bindings for a data path |
| `unregisterWidget(widgetId)` | Remove all widget bindings |
| `unregisterSurface(surfaceId)` | Remove all surface bindings |
| `clear()` | Remove all bindings |

---

## Tool Search Classes

### ToolCatalogIndex

A searchable index of tool schemas with relevance-based ranking.

```dart
ToolCatalogIndex([KeywordExtractor? extractor])
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `size` | `int` | Number of indexed tools |
| `allNames` | `List<String>` | All indexed tool names |

#### Methods

##### addSchema / addSchemas

```dart
void addSchema(A2uiToolSchema schema)
void addSchemas(Iterable<A2uiToolSchema> schemas)
```

Adds schemas to the index. Automatically extracts keywords for searching.

##### search

```dart
List<A2uiToolSchema> search(String query, {int maxResults = 10})
```

Searches for tools matching the query. Returns results ordered by relevance.

```dart
final index = ToolCatalogIndex();
index.addSchemas(myCatalog.schemas);

final results = index.search('date picker');
// Returns: [date_picker, date_range_picker, calendar_widget, ...]
```

##### getSchemaByName / getSchemasByNames

```dart
A2uiToolSchema? getSchemaByName(String name)
List<A2uiToolSchema> getSchemasByNames(Iterable<String> names)
```

Retrieves schemas by exact name.

##### clear

```dart
void clear()
```

Clears all indexed items.

---

### KeywordExtractor

Extracts searchable keywords from widget schemas and metadata.

```dart
KeywordExtractor()
```

#### Static Constants

| Constant | Type | Description |
|----------|------|-------------|
| `stopWords` | `Set<String>` | Common words filtered out |
| `minWordLength` | `int` | Minimum word length (2) |

#### Methods

```dart
Set<String> extractFromName(String name)
Set<String> extractFromDescription(String? description)
Set<String> extractFromSchema(Map<String, dynamic>? schema)
List<String> extractAll({
  required String name,
  String? description,
  Map<String, dynamic>? schema,
})
```

#### Name Tokenization

Handles camelCase, snake_case, kebab-case, and PascalCase:

```dart
final extractor = KeywordExtractor();
extractor.extractFromName('DateTimePicker'); // {'date', 'time', 'picker'}
extractor.extractFromName('data_table');      // {'data', 'table'}
```

---

### IndexedCatalogItem

A catalog item enriched with searchable keywords.

```dart
factory IndexedCatalogItem.fromSchema(
  A2uiToolSchema schema, [
  KeywordExtractor? extractor,
])
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Tool name |
| `schema` | `A2uiToolSchema` | Original tool schema |
| `keywords` | `List<String>` | Extracted searchable keywords |

#### Methods

```dart
bool matchesQuery(String query)
int relevanceScore(List<String> queryTerms)
```

---

### ToolSearchHandler

Handles `search_catalog` and `load_tools` tool requests.

```dart
ToolSearchHandler({required ToolCatalogIndex index})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `loadedToolNames` | `Set<String>` | Currently loaded tool names |

#### Methods

##### handleSearchCatalog

```dart
SearchCatalogOutput handleSearchCatalog(SearchCatalogInput input)
```

Searches the index and returns results with relevance scores.

##### handleLoadTools

```dart
LoadToolsResult handleLoadTools(LoadToolsInput input)
```

Loads requested tools from the index.

##### getLoadedSchemas

```dart
List<A2uiToolSchema> getLoadedSchemas()
```

Returns schemas for all currently loaded tools.

##### clearLoadedTools

```dart
void clearLoadedTools()
```

Clears all loaded tools.

#### Example

```dart
final index = ToolCatalogIndex();
index.addSchemas(largeCatalog.schemas);

final handler = ToolSearchHandler(index: index);

// Search
final searchResult = handler.handleSearchCatalog(
  SearchCatalogInput(query: 'date picker', maxResults: 5),
);
print(searchResult.results); // [{name: 'date_picker', relevance: 0.9}, ...]

// Load tools
final loadResult = handler.handleLoadTools(
  LoadToolsInput(toolNames: ['date_picker', 'calendar']),
);
print(loadResult.output.loaded); // ['date_picker', 'calendar']
print(handler.loadedToolNames);  // {'date_picker', 'calendar'}
```

---

## Handler Classes

### ApiHandler

Abstract interface for API handlers.

```dart
abstract class ApiHandler {
  Stream<Map<String, dynamic>> createStream(ApiRequest request);
  void dispose();
}
```

#### Methods

##### createStream

```dart
Stream<Map<String, dynamic>> createStream(ApiRequest request)
```

Creates a streaming response. Emits Claude SSE events:

- `{'type': 'content_block_start', 'index': 0, 'content_block': {...}}`
- `{'type': 'content_block_delta', 'index': 0, 'delta': {...}}`
- `{'type': 'content_block_stop', 'index': 0}`
- `{'type': 'message_stop'}`
- `{'type': 'error', 'error': {'message': '...'}}`

##### dispose

```dart
void dispose()
```

Disposes resources held by the handler.

---

### ApiRequest

Request context for API handlers.

```dart
const ApiRequest({
  required List<Map<String, dynamic>> messages,
  required int maxTokens,
  String? systemInstruction,
  List<Map<String, dynamic>>? tools,
  String? model,
  double? temperature,
  double? topP,
  int? topK,
  List<String>? stopSequences,
  bool enableFineGrainedStreaming = false,
  bool enableInterleavedThinking = false,
  int? thinkingBudgetTokens,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `messages` | `List<Map<String, dynamic>>` | Messages in Claude API format |
| `maxTokens` | `int` | Maximum response tokens |
| `systemInstruction` | `String?` | System prompt |
| `tools` | `List<Map<String, dynamic>>?` | Tools in Claude API format |
| `model` | `String?` | Model ID |
| `temperature` | `double?` | Temperature (0.0-1.0) |
| `topP` | `double?` | Nucleus sampling parameter |
| `topK` | `int?` | Top-k sampling parameter |
| `stopSequences` | `List<String>?` | Sequences that stop generation |
| `enableFineGrainedStreaming` | `bool` | Enable fine-grained tool streaming |
| `enableInterleavedThinking` | `bool` | Enable interleaved thinking |
| `thinkingBudgetTokens` | `int?` | Budget tokens for thinking |

---

### DirectModeHandler

Handler for direct Claude API access.

**Implements:** `ApiHandler`

```dart
DirectModeHandler({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  ClaudeConfig config = ClaudeConfig.defaults,
})
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | `String` | Yes | - | Claude API key |
| `model` | `String` | No | `'claude-sonnet-4-20250514'` | Default model |
| `config` | `ClaudeConfig` | No | `ClaudeConfig.defaults` | Configuration |

---

### ProxyModeHandler

Handler for backend proxy API access.

**Implements:** `ApiHandler`

```dart
ProxyModeHandler({
  required Uri endpoint,
  String? authToken,
  ProxyConfig config = ProxyConfig.defaults,
  http.Client? client,
})
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `endpoint` | `Uri` | Yes | - | Proxy endpoint URL |
| `authToken` | `String?` | No | `null` | Bearer token for auth |
| `config` | `ProxyConfig` | No | `ProxyConfig.defaults` | Configuration |
| `client` | `http.Client?` | No | `null` | Custom HTTP client |

#### Expected Proxy Behavior

Your backend proxy should:

1. Accept requests in Claude API format
2. Add API key server-side
3. Forward to Claude API
4. Stream SSE responses back unchanged

---

## Error Handling

### ContentGeneratorError

Error type emitted by the `errorStream`.

```dart
class ContentGeneratorError {
  final dynamic error;
  final StackTrace stackTrace;
}
```

**Common Errors:**

| Error | Cause |
|-------|-------|
| `'Request already in progress'` | Called `sendRequest` while processing |
| API errors | Invalid API key, rate limits, model errors |
| Network errors | Timeout, connection failures |

---

## See Also

- [README.md](../README.md) - Quick start guide
- [EXAMPLES.md](EXAMPLES.md) - Practical code examples
- [genui package](https://pub.dev/packages/genui) - GenUI SDK documentation
