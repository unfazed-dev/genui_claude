# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **RetryConfig**: Configurable retry behavior with exponential backoff
  - `maxAttempts`: Maximum retry attempts (default: 3)
  - `initialDelay`: First retry delay (default: 1 second)
  - `maxDelay`: Maximum delay cap (default: 30 seconds)
  - `backoffMultiplier`: Exponential factor (default: 2.0)
  - `jitterFactor`: Random jitter to prevent thundering herd (default: 0.1)
  - `retryableStatusCodes`: HTTP status codes that trigger retry
  - Presets: `defaults`, `noRetry`, `aggressive`

- **CircuitBreaker**: Circuit breaker pattern to prevent cascading failures
  - Three states: `closed`, `open`, `halfOpen`
  - Configurable via `CircuitBreakerConfig`
  - Methods: `checkState()`, `recordSuccess()`, `recordFailure()`, `reset()`
  - Integrates with `MetricsCollector` for state change tracking
  - Presets: `defaults`, `lenient`, `strict`

- **MetricsCollector**: Production observability and monitoring
  - `eventStream`: Broadcast stream of all metrics events
  - `stats`: Aggregated statistics (success rate, latency percentiles)
  - Record methods for various event types
  - `globalMetricsCollector`: Shared instance for convenience

- **MetricsEvent hierarchy**: Typed events for monitoring integration
  - `CircuitBreakerStateChangeEvent`: Circuit breaker transitions
  - `RetryAttemptEvent`: Retry attempts with delay info
  - `RequestStartEvent`, `RequestSuccessEvent`, `RequestFailureEvent`: Request lifecycle
  - `RateLimitEvent`: Rate limit encounters
  - `LatencyEvent`: Custom latency measurements
  - `StreamInactivityEvent`: Stream stall detection

- **MetricsStats**: Aggregated statistics from collected metrics
  - Request counts: `totalRequests`, `successfulRequests`, `failedRequests`
  - `successRate`: Percentage of successful requests
  - Latency percentiles: `p50LatencyMs`, `p95LatencyMs`, `p99LatencyMs`
  - Event counts: `rateLimitEvents`, `circuitBreakerOpens`, etc.

- **AnthropicException hierarchy**: Sealed exception class with typed errors
  - `NetworkException`: Network failures (retryable)
  - `TimeoutException`: Request timeouts with duration (retryable)
  - `AuthenticationException`: Auth failures (not retryable)
  - `RateLimitException`: Rate limiting with retry-after (retryable)
  - `ValidationException`: Request validation errors (not retryable)
  - `ServerException`: Server errors 5xx (retryable)
  - `StreamException`: SSE parsing errors (not retryable)
  - `CircuitBreakerOpenException`: Circuit open with recovery time (retryable)
  - `ExceptionFactory`: Create exceptions from HTTP responses

- **Constructor validation assertions**: Fail-fast on invalid configuration
  - `RetryConfig`: Validates maxAttempts, backoffMultiplier, jitterFactor
  - `CircuitBreakerConfig`: Validates failureThreshold, halfOpenSuccessThreshold
  - `AnthropicConfig`: Validates maxTokens, retryAttempts
  - `ProxyConfig`: Validates retryAttempts, maxHistoryMessages

- **Stream inactivity timeout**: Detect and handle stalled streams
  - Configurable timeout for stream inactivity detection
  - Emits `StreamInactivityEvent` when triggered

### Changed

- Enhanced logging with request ID correlation throughout handlers
- Improved error handling with structured exception mapping
- Production hardening improvements across all components

## [0.1.0] - 2025-12-14

### Added

- **AnthropicContentGenerator**: Main `ContentGenerator` implementation for Claude AI
  - Direct API mode for development with API key
  - Proxy mode for production deployments (keeps API key on backend)
  - Streaming support for progressive UI rendering
  - Configurable timeouts, retries, and max tokens

- **A2uiMessageAdapter**: Bidirectional message conversion
  - Converts `anthropic_a2ui` messages to GenUI `A2uiMessage` format
  - Supports all A2UI message types: BeginRendering, SurfaceUpdate, DataModelUpdate, SurfaceDeletion
  - Preserves all properties including metadata and component data

- **CatalogToolBridge**: Catalog-to-tool conversion utilities
  - `fromItems()`: Convert list of `CatalogItem` to Claude tool schemas
  - `fromCatalog()`: Convert `Catalog` instance to tool schemas
  - `withA2uiTools()`: Combine widget tools with A2UI control tools
  - Automatic JSON schema conversion from `json_schema_builder`

- **A2uiControlTools**: Pre-defined A2UI control tool schemas
  - `beginRendering`: Initialize surface rendering
  - `surfaceUpdate`: Add/update UI components
  - `dataModelUpdate`: Update surface data model
  - `deleteSurface`: Remove a surface

- **MessageConverter**: GenUI to Claude message conversion
  - Converts `ChatMessage` history to Claude API format
  - Handles user messages, assistant messages, and tool results
  - Supports text and tool use content blocks

- **Configuration classes**:
  - `AnthropicConfig`: Direct mode settings (maxTokens, timeout, retries, streaming, headers)
  - `ProxyConfig`: Proxy mode settings (timeout, retries, includeHistory, maxHistoryMessages, headers)

### Dependencies

- Requires `genui: ^0.5.1`
- Requires `anthropic_a2ui` (sibling package)
- Flutter SDK `>=3.22.0`
- Dart SDK `^3.5.0`
