# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **SLA-based Circuit Breaker Presets**: Pre-configured circuit breaker settings for different availability requirements
  - `CircuitBreakerConfig.sla999`: For 99.9% SLA (3 nines) - 8.76 hours/year downtime tolerance
  - `CircuitBreakerConfig.sla9999`: For 99.99% SLA (4 nines) - 52.6 minutes/year downtime tolerance
  - `CircuitBreakerConfig.highAvailability`: Maximum resilience for mission-critical systems

- **Observability Adapters**: Built-in adapters for popular monitoring platforms
  - `ObservabilityAdapter`: Abstract base class for custom integrations
  - `CustomObservabilityAdapter`: Callback-based adapter for any platform
  - `DataDogAdapter`: DataDog-specific event formatting and delivery
  - `FirebaseAnalyticsAdapter`: Firebase Analytics integration
  - `SupabaseAdapter`: Supabase table insertion and Edge Function support
  - `ConsoleObservabilityAdapter`: Console logging for development/debugging
  - `BatchingObservabilityAdapter`: Batches events before sending to reduce API calls

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

- **ClaudeException hierarchy**: Sealed exception class with typed errors
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
  - `ClaudeConfig`: Validates maxTokens, retryAttempts
  - `ProxyConfig`: Validates retryAttempts, maxHistoryMessages

- **Stream inactivity timeout**: Detect and handle stalled streams
  - Configurable timeout for stream inactivity detection
  - Emits `StreamInactivityEvent` when triggered

- **Data Binding Engine**: Two-way data binding between widgets and data models
  - `BindingPath`: JSON pointer path parsing with bracket/dot notation support
  - `BindingDefinition`: Binding configuration with modes (oneWay, twoWay, oneWayToSource)
  - `BindingRegistry`: Multi-index registry for efficient binding lookups
  - `BindingController`: Orchestrates bindings with ValueNotifier integration
  - `WidgetBinding`: Active binding representation with lifecycle management
  - Value transformers: `toWidget` and `toModel` for data conversion
  - Support for nested paths and array indices

- **Tool Search**: Dynamic tool discovery for large widget catalogs
  - `KeywordExtractor`: Automated keyword extraction from tool metadata
  - `ToolCatalogIndex`: Inverted index with relevance-based search
  - `IndexedCatalogItem`: Tool wrapper with extracted searchable keywords
  - `CatalogSearchTool`: `search_catalog` and `load_tools` tool schemas
  - `ToolSearchHandler`: Request processing for search operations
  - `ToolUseInterceptor`: Local search request interception
  - `CatalogToolBridge.searchModeTools()`: Creates search-enabled tool set
  - Session limits via `maxLoadedToolsPerSession` configuration

- **Advanced Model Parameters**: Fine-tuned sampling control
  - `topP`: Nucleus sampling parameter (0.0-1.0)
  - `topK`: Top-k token selection (≥1)
  - `stopSequences`: Custom stop sequences (max 4)
  - Added to `ClaudeConfig` and passed through handlers

- **Circuit Breaker Enabled by Default**: Safer production defaults
  - `ProxyConfig.circuitBreakerConfig`: Configure circuit breaker (default: `CircuitBreakerConfig.defaults`)
  - `ProxyConfig.disableCircuitBreaker`: Opt-out flag (default: `false`)
  - `ClaudeConfig.circuitBreakerConfig`: Configure circuit breaker for direct mode
  - `ClaudeConfig.disableCircuitBreaker`: Opt-out flag for direct mode
  - Both handlers now create circuit breaker automatically unless explicitly disabled
  - Explicit `circuitBreaker` parameter still overrides config

### Changed

- **genui SDK 0.6.0 Migration**: Updated to use new API naming conventions
  - `GenUiManager` → `A2uiMessageProcessor`
  - `catalog:` parameter → `catalogs:` (now accepts a List)
  - `genUiManager:` parameter → `a2uiMessageProcessor:` in GenUiConversation
  - Added `clientCapabilities` parameter to `sendRequest` override
- Enhanced logging with request ID correlation throughout handlers
- Improved error handling with structured exception mapping
- Production hardening improvements across all components
- **Breaking (behavior)**: Handlers now create circuit breakers by default. To preserve
  old behavior without circuit breaker, set `disableCircuitBreaker: true` in config.

## [0.1.0] - 2025-12-14

### Added

- **ClaudeContentGenerator**: Main `ContentGenerator` implementation for Claude AI
  - Direct API mode for development with API key
  - Proxy mode for production deployments (keeps API key on backend)
  - Streaming support for progressive UI rendering
  - Configurable timeouts, retries, and max tokens

- **A2uiMessageAdapter**: Bidirectional message conversion
  - Converts `a2ui_claude` messages to GenUI `A2uiMessage` format
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
  - `ClaudeConfig`: Direct mode settings (maxTokens, timeout, retries, streaming, headers)
  - `ProxyConfig`: Proxy mode settings (timeout, retries, includeHistory, maxHistoryMessages, headers)

### Dependencies

- Requires `genui: ^0.6.0`
- Requires `a2ui_claude` (sibling package)
- Flutter SDK `>=3.22.0`
- Dart SDK `^3.5.0`
