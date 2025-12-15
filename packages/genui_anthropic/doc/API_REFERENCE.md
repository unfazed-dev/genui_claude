# API Reference

Complete API documentation for the `genui_anthropic` package.

## Table of Contents

- [Installation](#installation)
- [Core Classes](#core-classes)
  - [AnthropicContentGenerator](#anthropiccontentgenerator)
  - [AnthropicConfig](#anthropicconfig)
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
- [Exception Classes](#exception-classes)
  - [AnthropicException](#anthropicexception)
  - [Exception Types](#exception-types)
  - [ExceptionFactory](#exceptionfactory)
- [Adapter Classes](#adapter-classes)
  - [A2uiMessageAdapter](#a2uimessageadapter)
  - [CatalogToolBridge](#catalogtoolbridge)
  - [A2uiControlTools](#a2uicontroltools)
- [Utility Classes](#utility-classes)
  - [MessageConverter](#messageconverter)
- [Handler Classes](#handler-classes)
  - [ApiHandler](#apihandler)
  - [ApiRequest](#apirequest)
  - [DirectModeHandler](#directmodehandler)
  - [ProxyModeHandler](#proxymodehandler)

---

## Installation

```yaml
dependencies:
  genui: ^0.5.1
  genui_anthropic:
    git:
      url: https://github.com/unfazed-dev/anthropic_genui.git
      path: packages/genui_anthropic
```

---

## Core Classes

### AnthropicContentGenerator

Main ContentGenerator implementation for Anthropic's Claude AI. Provides the bridge between Claude's API and the GenUI SDK.

**Implements:** `ContentGenerator`

#### Constructors

##### Default Constructor (Direct Mode)

```dart
AnthropicContentGenerator({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  String? systemInstruction,
  AnthropicConfig config = AnthropicConfig.defaults,
})
```

Use for development and prototyping. API key is used directly in the client.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | `String` | Yes | - | Your Anthropic API key |
| `model` | `String` | No | `'claude-sonnet-4-20250514'` | Claude model ID |
| `systemInstruction` | `String?` | No | `null` | System prompt for Claude |
| `config` | `AnthropicConfig` | No | `AnthropicConfig.defaults` | Configuration options |

##### Proxy Constructor (Production)

```dart
AnthropicContentGenerator.proxy({
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
AnthropicContentGenerator.withHandler({
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

### AnthropicConfig

Configuration for direct Anthropic API mode.

```dart
const AnthropicConfig({
  int maxTokens = 4096,
  Duration timeout = const Duration(seconds: 60),
  int retryAttempts = 3,
  bool enableStreaming = true,
  Map<String, String>? headers,
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

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `defaults` | `AnthropicConfig` | Default configuration instance |

#### Methods

##### copyWith

```dart
AnthropicConfig copyWith({
  int? maxTokens,
  Duration? timeout,
  int? retryAttempts,
  bool? enableStreaming,
  Map<String, String>? headers,
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

## Exception Classes

### AnthropicException

Sealed base class for all Anthropic API errors.

```dart
sealed class AnthropicException implements Exception {
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
} on AnthropicException catch (e) {
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
final class TimeoutException extends AnthropicException {
  Duration get timeout;  // The timeout duration that was exceeded
}
```

#### RateLimitException

```dart
final class RateLimitException extends AnthropicException {
  Duration? get retryAfter;  // Suggested wait time before retrying
}
```

#### CircuitBreakerOpenException

```dart
final class CircuitBreakerOpenException extends AnthropicException {
  DateTime? get recoveryTime;  // When the circuit will attempt recovery
}
```

---

### ExceptionFactory

Factory for creating appropriate exceptions from HTTP responses.

#### Static Methods

##### fromHttpStatus

```dart
static AnthropicException fromHttpStatus({
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

Converts anthropic_a2ui message types to GenUI A2uiMessage types.

#### Static Methods

##### toGenUiMessage

```dart
static A2uiMessage toGenUiMessage(A2uiMessageData data)
```

Converts a single anthropic_a2ui message to GenUI format.

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

---

### DirectModeHandler

Handler for direct Anthropic API access.

**Implements:** `ApiHandler`

```dart
DirectModeHandler({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  AnthropicConfig config = AnthropicConfig.defaults,
})
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | `String` | Yes | - | Anthropic API key |
| `model` | `String` | No | `'claude-sonnet-4-20250514'` | Default model |
| `config` | `AnthropicConfig` | No | `AnthropicConfig.defaults` | Configuration |

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
