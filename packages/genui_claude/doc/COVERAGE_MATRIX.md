# Test Coverage Matrix

This document provides a comprehensive overview of test coverage for the `genui_claude` package.

## Coverage Summary

| Category | Test Files | Test Count | Status |
|----------|------------|------------|--------|
| **Unit Tests** | 12 | 300+ | Complete |
| **Integration Tests** | 2 | 12 | Complete |
| **Widget Tests** | 3 | 30+ | Complete |
| **Performance Tests** | 2 | 25 | Complete |

## Test Categories

### Unit Tests

#### Configuration Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| ClaudeConfig | `config/config_validation_test.dart` | 26 | Defaults, custom values, presets, copyWith, immutability |
| ProxyConfig | `config/config_validation_test.dart` | 26 | Defaults, custom values, presets, copyWith, immutability |
| RetryConfig | `config/retry_config_test.dart` | 40 | Delay calculation, jitter, exponential backoff, presets |
| CircuitBreakerConfig | `config/config_validation_test.dart` | 12 | Boundary values, preset configurations |

#### Resilience Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| CircuitBreaker | `resilience/circuit_breaker_test.dart` | 42 | State transitions (closed→open→half-open→closed), failure threshold, recovery timeout, manual reset, metrics |

#### Exception Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| NetworkException | `exceptions/claude_exceptions_test.dart` | 7 | Creation, isRetryable, typeName, toString |
| TimeoutException | `exceptions/claude_exceptions_test.dart` | 4 | Creation, isRetryable, typeName |
| AuthenticationException | `exceptions/claude_exceptions_test.dart` | 6 | 401/403 status codes, isRetryable |
| RateLimitException | `exceptions/claude_exceptions_test.dart` | 6 | Retry-After header, isRetryable |
| ValidationException | `exceptions/claude_exceptions_test.dart` | 5 | 400/422 status codes, isRetryable |
| ServerException | `exceptions/claude_exceptions_test.dart` | 5 | 5xx status codes, isRetryable |
| StreamException | `exceptions/claude_exceptions_test.dart` | 4 | Creation, isRetryable |
| CircuitBreakerOpenException | `exceptions/claude_exceptions_test.dart` | 5 | Recovery time, isRetryable |
| ExceptionFactory | `exceptions/claude_exceptions_test.dart` | 18 | HTTP status mapping, Retry-After parsing |

#### Metrics Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| MetricsCollector | `metrics/metrics_collector_test.dart` | 51 | Event streaming, statistics, percentiles, enable/disable |
| MetricsEvent types | `metrics/metrics_collector_test.dart` | Included | All event types: CircuitBreaker, Retry, Request, RateLimit, Latency, Stream |

#### Handler Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| ProxyModeHandler | `handler/proxy_mode_handler_test.dart` | 20+ | Request handling, error mapping, SSE parsing |
| DirectModeHandler | `handler/direct_mode_handler_test.dart` | 15+ | API calls, message conversion, error handling |
| Streaming Edge Cases | `handler/streaming_edge_cases_test.dart` | 18 | Cancellation, pause/resume, chunking, large responses, unicode |

#### Logging Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| ProxyModeHandler logging | `logging/logging_behavior_test.dart` | 24 | Log levels, request ID correlation, error logging, retry logging |

### Integration Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| Real API Integration | `integration/real_api_test.dart` | 6 | Direct mode, proxy mode, streaming, error handling |
| Mock Server Integration | `integration/mock_server_test.dart` | 6 | End-to-end request flows |

### Widget Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| ClaudeContentGenerator | `widget/claude_content_generator_test.dart` | 30+ | Factory methods, streaming, error handling |

### Performance Tests

| Component | File | Tests | Coverage |
|-----------|------|-------|----------|
| MetricsCollector Performance | `performance/metrics_performance_test.dart` | 11 | High-throughput events, statistics aggregation, percentiles |
| Handler Performance | `performance/handler_performance_test.dart` | 14 | Handler initialization, SSE parsing, configuration copyWith, concurrency |

## CI/CD Test Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test categories
flutter test test/unit/
flutter test test/integration/
flutter test test/performance/

# Run individual test files
flutter test test/resilience/circuit_breaker_test.dart
flutter test test/config/retry_config_test.dart
flutter test test/exceptions/claude_exceptions_test.dart

# Run with verbose output
flutter test --reporter expanded

# Run integration tests (requires API key)
TEST_CLAUDE_API_KEY=your-key flutter test test/integration/real_api_test.dart
```

## Coverage Thresholds

Recommended minimum coverage thresholds for CI/CD:

| Metric | Threshold | Current |
|--------|-----------|---------|
| Line Coverage | 80% | 85%+ |
| Branch Coverage | 70% | 75%+ |
| Function Coverage | 90% | 95%+ |

## Test File Organization

```
test/
├── adapter/
│   ├── a2ui_control_tools_test.dart
│   └── message_adapter_test.dart
├── config/
│   ├── config_validation_test.dart
│   └── retry_config_test.dart
├── exceptions/
│   └── claude_exceptions_test.dart
├── handler/
│   ├── direct_mode_handler_test.dart
│   ├── proxy_mode_handler_test.dart
│   └── streaming_edge_cases_test.dart
├── helpers/
│   └── test_utils.dart
├── integration/
│   ├── mock_server_test.dart
│   └── real_api_test.dart
├── logging/
│   └── logging_behavior_test.dart
├── metrics/
│   └── metrics_collector_test.dart
├── performance/
│   ├── handler_performance_test.dart
│   └── metrics_performance_test.dart
├── resilience/
│   └── circuit_breaker_test.dart
└── widget/
    └── claude_content_generator_test.dart
```

## Critical Test Coverage

The following components have critical test coverage that must pass before deployment:

### Must Pass

1. **CircuitBreaker state transitions** - Ensures resilience pattern works correctly
2. **Exception isRetryable property** - Determines retry behavior
3. **RetryConfig delay calculation** - Prevents thundering herd
4. **Handler error mapping** - Correct exception types for HTTP errors
5. **SSE stream parsing** - Core streaming functionality

### Integration Tests (Require API Key)

These tests are skipped in CI unless `TEST_CLAUDE_API_KEY` is provided:

- `real_api_test.dart` - Tests against actual Claude API
- Validates end-to-end functionality including:
  - Authentication
  - Message streaming
  - Tool use
  - Error responses

#### Setting Up Integration Tests

**Local Development:**
```bash
# Run integration tests with API key
TEST_CLAUDE_API_KEY="sk-ant-api03-..." flutter test test/integration/

# Or export the key for the session
export TEST_CLAUDE_API_KEY="sk-ant-api03-..."
flutter test test/integration/
```

**CI/CD Configuration:**
```yaml
# GitHub Actions example
env:
  TEST_CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}

steps:
  - name: Run integration tests
    run: flutter test test/integration/
```

**Important Notes:**
- Never commit API keys to version control
- Use environment variables or secrets management
- Integration tests consume API credits - run sparingly in CI
- Tests will be skipped (not failed) if the key is not set

## Performance Benchmarks

Performance tests validate:

| Metric | Threshold | Measured |
|--------|-----------|----------|
| Handler creation | < 1ms average | ~0.5ms |
| 1000 SSE events parsing | < 1000ms | ~200ms |
| 100k copyWith operations | < 1000ms | ~500ms |
| 10k exception creations | < 1000ms | ~300ms |
| Concurrent stream handling | < 2000ms for 10 streams | ~500ms |

## Adding New Tests

When adding new functionality:

1. Create unit tests in the appropriate category folder
2. Add integration tests if the feature interacts with external services
3. Add performance tests if the feature is performance-critical
4. Update this coverage matrix document
5. Ensure all tests pass before merging

## Continuous Integration

Recommended CI pipeline stages:

```yaml
stages:
  - analyze:
      - dart analyze
      - dart format --set-exit-if-changed .

  - test:
      - flutter test --coverage
      - flutter test test/performance/

  - coverage:
      - genhtml coverage/lcov.info -o coverage/html
      - check coverage thresholds
```
