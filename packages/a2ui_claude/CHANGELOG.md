# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **ProactiveRateLimiter**: Proactive rate limiting with sliding window algorithm
  - Prevents hitting API rate limits by tracking request patterns
  - `maxRequests`: Maximum requests allowed in window
  - `window`: Duration of sliding window
  - `minInterval`: Optional minimum interval between requests
  - Methods: `waitForCapacity()`, `recordRequest()`, `isWithinLimits`
  - Automatic cleanup of expired request timestamps

- **RequestDeduplication**: Prevents duplicate API calls for identical requests
  - Uses content-addressable hashing with TTL-based cache
  - `cacheTtl`: Time-to-live for cached request hashes (default: 30 seconds)
  - Methods: `isDuplicate()`, `recordRequest()`, `clear()`
  - Automatic expiration of stale entries

### Changed

- Upgraded dev dependencies (lints 4.0.0 → 6.0.0)

## [1.0.0] - 2024-12-14

### Added

#### Data Models
- `A2uiMessageData` sealed class with exhaustive pattern matching
- `BeginRenderingData` for signaling UI generation start
- `SurfaceUpdateData` for widget tree updates
- `DataModelUpdateData` for bound data updates
- `DeleteSurfaceData` for surface removal
- `WidgetNode` for widget tree representation
- `A2uiToolSchema` for tool definitions
- `ParseResult` for parser output
- `ValidationResult` and `ValidationError` for input validation

#### Stream Events
- `StreamEvent` sealed class hierarchy
- `TextDeltaEvent` for text content chunks
- `A2uiMessageEvent` for parsed A2UI messages
- `DeltaEvent` for raw delta data
- `CompleteEvent` for stream completion
- `ErrorEvent` for error handling

#### Core Components
- `A2uiToolConverter` for schema conversion
  - `toClaudeTools()` - Convert A2UI schemas to Claude format
  - `generateToolInstructions()` - Generate system prompt text
  - `validateToolInput()` - Validate tool inputs
- `ClaudeA2uiParser` for response parsing
  - `parseToolUse()` - Parse single tool_use block
  - `parseMessage()` - Parse complete message
- `StreamParser` for SSE stream parsing
- `ClaudeStreamHandler` for stream management
- `RateLimiter` for API rate limit handling
- `RetryPolicy` for retry configuration

#### Exceptions
- `A2uiException` sealed class hierarchy
- `ToolConversionException`
- `MessageParseException`
- `StreamException`
- `ValidationException`

#### Configuration
- `StreamConfig` for streaming parameters
- Default configurations with sensible defaults

### Performance
- Tool schema conversion: < 1ms for 10 tools
- Message parsing: < 5ms typical response
- Stream event processing: < 0.1ms per event

### Documentation
- Comprehensive API documentation
- Usage examples for common scenarios
- README with quick start guide
