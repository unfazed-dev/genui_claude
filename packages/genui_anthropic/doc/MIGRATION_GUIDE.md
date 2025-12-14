# Migration Guide

This guide helps you migrate between versions of the `genui_anthropic` package.

## Table of Contents

1. [Version Compatibility Matrix](#version-compatibility-matrix)
2. [Breaking Changes Log](#breaking-changes-log)
3. [Migration Steps](#migration-steps)
4. [Configuration Migration Helpers](#configuration-migration-helpers)
5. [Testing During Migration](#testing-during-migration)
6. [Rollback Procedures](#rollback-procedures)

---

## Version Compatibility Matrix

| genui_anthropic | genui | anthropic_sdk_dart | anthropic_a2ui | Dart SDK | Flutter |
|-----------------|-------|--------------------|----------------|----------|---------|
| 0.1.x | ^0.5.1 | ^0.3.0 | ^0.1.0 | ^3.6.0 | ^3.27.0 |

### Dependency Notes

- **genui**: Core GenUI framework - provides `ContentGenerator` interface
- **anthropic_sdk_dart**: Official Anthropic Dart SDK for direct API access
- **anthropic_a2ui**: A2UI protocol parsing and message types

---

## Breaking Changes Log

### Version 0.1.x (Current)

Initial release - no breaking changes from previous versions.

### Future Breaking Changes (Planned for 0.2.0)

The following changes are planned but not yet implemented:

1. **Configuration Consolidation**
   - `ProxyConfig.retryAttempts` will be removed in favor of explicit `RetryConfig`
   - Migration: Use `RetryConfig` constructor directly

2. **Exception Hierarchy Refinements**
   - Some exception types may be consolidated
   - Migration: Use pattern matching with `AnthropicException` base type

---

## Migration Steps

### From Pre-release to 0.1.x

If you were using a pre-release version, follow these steps:

#### Step 1: Update pubspec.yaml

```yaml
# Before (pre-release)
dependencies:
  genui_anthropic:
    path: ../genui_anthropic

# After (0.1.x)
dependencies:
  genui_anthropic: ^0.1.0
```

#### Step 2: Update Imports

```dart
// All public APIs are exported from the main library
import 'package:genui_anthropic/genui_anthropic.dart';
```

#### Step 3: Configuration Changes

```dart
// Before: Separate handler creation
final handler = ProxyModeHandler(
  endpoint: Uri.parse('https://api.example.com/claude'),
  authToken: token,
);

// After: Use factory constructor
final generator = AnthropicContentGenerator.proxy(
  proxyEndpoint: Uri.parse('https://api.example.com/claude'),
  authToken: token,
  catalog: myCatalog,
);
```

### From 0.1.x to 0.2.x (Template)

This section will be updated when 0.2.0 is released.

```dart
// Example migration pattern (placeholder)

// Before (0.1.x)
final config = ProxyConfig(
  retryAttempts: 3,
  timeout: Duration(seconds: 120),
);

// After (0.2.x) - hypothetical
final config = ProxyConfig(
  timeout: Duration(seconds: 120),
);
final retryConfig = RetryConfig(maxAttempts: 3);
```

---

## Configuration Migration Helpers

### ProxyConfig Migration

```dart
/// Helper to migrate legacy configuration to current format.
ProxyConfig migrateProxyConfig({
  required Uri endpoint,
  String? authToken,
  int retryAttempts = 3,
  Duration timeout = const Duration(seconds: 120),
  int? maxHistoryMessages,
}) {
  return ProxyConfig(
    retryAttempts: retryAttempts,
    timeout: timeout,
    maxHistoryMessages: maxHistoryMessages,
  );
}
```

### RetryConfig Migration

```dart
/// Convert legacy retry settings to RetryConfig.
RetryConfig migrateRetryConfig({
  int maxRetries = 3,
  int initialDelayMs = 1000,
  int maxDelayMs = 30000,
  double backoffMultiplier = 2.0,
}) {
  return RetryConfig(
    maxAttempts: maxRetries,
    initialDelay: Duration(milliseconds: initialDelayMs),
    maxDelay: Duration(milliseconds: maxDelayMs),
    backoffMultiplier: backoffMultiplier,
  );
}
```

### CircuitBreakerConfig Migration

```dart
/// Convert legacy circuit breaker settings.
CircuitBreakerConfig migrateCircuitBreakerConfig({
  int failureThreshold = 5,
  int recoveryTimeoutSeconds = 30,
  int halfOpenMaxAttempts = 3,
}) {
  return CircuitBreakerConfig(
    failureThreshold: failureThreshold,
    recoveryTimeout: Duration(seconds: recoveryTimeoutSeconds),
    halfOpenMaxAttempts: halfOpenMaxAttempts,
  );
}
```

---

## Testing During Migration

### Pre-Migration Checklist

Before upgrading:

- [ ] Review breaking changes for target version
- [ ] Back up current `pubspec.lock`
- [ ] Run existing test suite and verify all tests pass
- [ ] Document current configuration values
- [ ] Create rollback plan

### Migration Test Script

```dart
// test/migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

void main() {
  group('Migration Verification', () {
    test('ProxyConfig maintains expected defaults', () {
      const config = ProxyConfig.defaults;

      expect(config.retryAttempts, equals(3));
      expect(config.timeout, equals(const Duration(seconds: 120)));
      expect(config.maxHistoryMessages, isNull);
    });

    test('RetryConfig maintains expected defaults', () {
      const config = RetryConfig.defaults;

      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(seconds: 1)));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
    });

    test('CircuitBreakerConfig maintains expected defaults', () {
      const config = CircuitBreakerConfig.defaults;

      expect(config.failureThreshold, equals(5));
      expect(config.recoveryTimeout, equals(const Duration(seconds: 30)));
    });

    test('Exception types are correctly exported', () {
      // Verify all exception types are available
      expect(NetworkException, isNotNull);
      expect(TimeoutException, isNotNull);
      expect(AuthenticationException, isNotNull);
      expect(RateLimitException, isNotNull);
      expect(ValidationException, isNotNull);
      expect(ServerException, isNotNull);
      expect(StreamException, isNotNull);
      expect(CircuitBreakerOpenException, isNotNull);
    });

    test('Factory constructor creates valid generator', () {
      // This test verifies the API surface is intact
      // Note: This won't actually call the API in tests
      final generator = AnthropicContentGenerator.proxy(
        proxyEndpoint: Uri.parse('https://test.example.com'),
        authToken: 'test-token',
        catalog: const [],
      );

      expect(generator, isNotNull);
      expect(generator.isProcessing.value, isFalse);

      generator.dispose();
    });
  });
}
```

### Post-Migration Verification

```dart
// Run after migration
void verifyMigration() async {
  final generator = AnthropicContentGenerator.proxy(
    proxyEndpoint: productionEndpoint,
    authToken: await getAuthToken(),
    config: ProxyConfig.defaults,
    retryConfig: RetryConfig.defaults,
    circuitBreaker: CircuitBreaker(),
    metricsCollector: MetricsCollector(enabled: true),
    catalog: widgetCatalog,
  );

  // Verify streams are operational
  generator.textResponseStream.listen((text) {
    print('Text stream operational: received ${text.length} chars');
  });

  generator.errorStream.listen((error) {
    print('Error stream operational: ${error.error}');
  });

  generator.a2uiMessageStream.listen((message) {
    print('A2UI stream operational: ${message.runtimeType}');
  });

  // Make a test request
  await generator.sendRequest(userMessage: 'Migration test');

  // Check metrics
  final stats = generator.metricsCollector?.stats;
  print('Metrics operational: ${stats?.totalRequests} requests tracked');
}
```

---

## Rollback Procedures

### Quick Rollback

If issues are discovered after migration:

```bash
# 1. Restore previous pubspec.lock
git checkout HEAD~1 -- pubspec.lock

# 2. Revert pubspec.yaml changes
git checkout HEAD~1 -- pubspec.yaml

# 3. Re-fetch dependencies
flutter pub get

# 4. Verify rollback
flutter test
```

### Gradual Rollback with Feature Flags

```dart
class FeatureFlags {
  static const useNewGenerator = bool.fromEnvironment(
    'USE_NEW_GENERATOR',
    defaultValue: false,
  );
}

ContentGenerator createGenerator() {
  if (FeatureFlags.useNewGenerator) {
    return AnthropicContentGenerator.proxy(/* new config */);
  } else {
    return LegacyGenerator(/* old config */);
  }
}
```

### Version Pinning for Stability

```yaml
# pubspec.yaml - Pin to exact version during migration
dependencies:
  genui_anthropic: 0.1.0  # Exact version, no caret
```

---

## Deprecation Timeline

| Feature | Deprecated In | Removed In | Migration Path |
|---------|--------------|------------|----------------|
| TBD | - | - | - |

*This table will be updated as features are deprecated.*

---

## Getting Help

If you encounter issues during migration:

1. **Check the Changelog**: Review [CHANGELOG.md](../CHANGELOG.md) for detailed changes
2. **Review Tests**: Look at package tests for usage examples
3. **API Reference**: Consult [API_REFERENCE.md](./API_REFERENCE.md) for current API
4. **Report Issues**: File bugs at the package repository

---

## Version History Quick Reference

| Version | Release Date | Key Changes |
|---------|--------------|-------------|
| 0.1.0 | 2024-12 | Initial release |

---

## Additional Resources

- [Production Guide](./PRODUCTION_GUIDE.md)
- [Security Best Practices](./SECURITY_BEST_PRACTICES.md)
- [Monitoring Integration](./MONITORING_INTEGRATION.md)
- [API Reference](./API_REFERENCE.md)
