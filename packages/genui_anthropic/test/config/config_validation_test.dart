import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/src/config/anthropic_config.dart';
import 'package:genui_anthropic/src/config/retry_config.dart';
import 'package:genui_anthropic/src/resilience/circuit_breaker.dart';

void main() {
  group('AnthropicConfig', () {
    group('constructor defaults', () {
      test('has correct default maxTokens', () {
        const config = AnthropicConfig();

        expect(config.maxTokens, equals(4096));
      });

      test('has correct default timeout', () {
        const config = AnthropicConfig();

        expect(config.timeout, equals(const Duration(seconds: 60)));
      });

      test('has correct default retryAttempts', () {
        const config = AnthropicConfig();

        expect(config.retryAttempts, equals(3));
      });

      test('has correct default enableStreaming', () {
        const config = AnthropicConfig();

        expect(config.enableStreaming, isTrue);
      });

      test('has null default headers', () {
        const config = AnthropicConfig();

        expect(config.headers, isNull);
      });
    });

    group('custom values', () {
      test('accepts custom maxTokens', () {
        const config = AnthropicConfig(maxTokens: 8192);

        expect(config.maxTokens, equals(8192));
      });

      test('accepts custom timeout', () {
        const config = AnthropicConfig(timeout: Duration(seconds: 120));

        expect(config.timeout, equals(const Duration(seconds: 120)));
      });

      test('accepts custom retryAttempts', () {
        const config = AnthropicConfig(retryAttempts: 5);

        expect(config.retryAttempts, equals(5));
      });

      test('accepts custom headers', () {
        const config = AnthropicConfig(headers: {'X-Custom': 'value'});

        expect(config.headers, equals({'X-Custom': 'value'}));
      });

      test('accepts zero retryAttempts', () {
        const config = AnthropicConfig(retryAttempts: 0);

        expect(config.retryAttempts, equals(0));
      });

      test('accepts small timeout', () {
        const config = AnthropicConfig(timeout: Duration(milliseconds: 100));

        expect(config.timeout, equals(const Duration(milliseconds: 100)));
      });

      test('accepts large maxTokens', () {
        const config = AnthropicConfig(maxTokens: 100000);

        expect(config.maxTokens, equals(100000));
      });
    });

    group('defaults preset', () {
      test('defaults preset matches default constructor', () {
        const config = AnthropicConfig.defaults;

        expect(config.maxTokens, equals(4096));
        expect(config.timeout, equals(const Duration(seconds: 60)));
        expect(config.retryAttempts, equals(3));
        expect(config.enableStreaming, isTrue);
        expect(config.headers, isNull);
      });
    });

    group('copyWith', () {
      test('copies with new maxTokens', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(maxTokens: 2048);

        expect(copy.maxTokens, equals(2048));
        expect(copy.timeout, equals(original.timeout));
      });

      test('copies with new timeout', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(timeout: const Duration(seconds: 90));

        expect(copy.timeout, equals(const Duration(seconds: 90)));
        expect(copy.maxTokens, equals(original.maxTokens));
      });

      test('copies with new retryAttempts', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(retryAttempts: 10);

        expect(copy.retryAttempts, equals(10));
      });

      test('copies with new enableStreaming', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(enableStreaming: false);

        expect(copy.enableStreaming, isFalse);
      });

      test('copies with new headers', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(headers: {'Auth': 'token'});

        expect(copy.headers, equals({'Auth': 'token'}));
      });

      test('copies all fields at once', () {
        const original = AnthropicConfig();
        final copy = original.copyWith(
          maxTokens: 1000,
          timeout: const Duration(seconds: 30),
          retryAttempts: 1,
          enableStreaming: false,
          headers: {'X-Test': 'test'},
        );

        expect(copy.maxTokens, equals(1000));
        expect(copy.timeout, equals(const Duration(seconds: 30)));
        expect(copy.retryAttempts, equals(1));
        expect(copy.enableStreaming, isFalse);
        expect(copy.headers, equals({'X-Test': 'test'}));
      });
    });
  });

  group('ProxyConfig', () {
    group('constructor defaults', () {
      test('has correct default timeout', () {
        const config = ProxyConfig();

        expect(config.timeout, equals(const Duration(seconds: 120)));
      });

      test('has correct default retryAttempts', () {
        const config = ProxyConfig();

        expect(config.retryAttempts, equals(3));
      });

      test('has null default headers', () {
        const config = ProxyConfig();

        expect(config.headers, isNull);
      });

      test('has correct default includeHistory', () {
        const config = ProxyConfig();

        expect(config.includeHistory, isTrue);
      });

      test('has correct default maxHistoryMessages', () {
        const config = ProxyConfig();

        expect(config.maxHistoryMessages, equals(20));
      });
    });

    group('custom values', () {
      test('accepts custom timeout', () {
        const config = ProxyConfig(timeout: Duration(seconds: 180));

        expect(config.timeout, equals(const Duration(seconds: 180)));
      });

      test('accepts custom retryAttempts', () {
        const config = ProxyConfig(retryAttempts: 5);

        expect(config.retryAttempts, equals(5));
      });

      test('accepts custom headers', () {
        const config = ProxyConfig(headers: {'X-Proxy': 'value'});

        expect(config.headers, equals({'X-Proxy': 'value'}));
      });

      test('accepts custom includeHistory', () {
        const config = ProxyConfig(includeHistory: false);

        expect(config.includeHistory, isFalse);
      });

      test('accepts custom maxHistoryMessages', () {
        const config = ProxyConfig(maxHistoryMessages: 50);

        expect(config.maxHistoryMessages, equals(50));
      });

      test('accepts zero maxHistoryMessages', () {
        const config = ProxyConfig(maxHistoryMessages: 0);

        expect(config.maxHistoryMessages, equals(0));
      });

      test('accepts large maxHistoryMessages', () {
        const config = ProxyConfig(maxHistoryMessages: 1000);

        expect(config.maxHistoryMessages, equals(1000));
      });
    });

    group('defaults preset', () {
      test('defaults preset matches default constructor', () {
        const config = ProxyConfig.defaults;

        expect(config.timeout, equals(const Duration(seconds: 120)));
        expect(config.retryAttempts, equals(3));
        expect(config.headers, isNull);
        expect(config.includeHistory, isTrue);
        expect(config.maxHistoryMessages, equals(20));
      });
    });

    group('copyWith', () {
      test('copies with new timeout', () {
        const original = ProxyConfig();
        final copy = original.copyWith(timeout: const Duration(seconds: 60));

        expect(copy.timeout, equals(const Duration(seconds: 60)));
        expect(copy.retryAttempts, equals(original.retryAttempts));
      });

      test('copies with new retryAttempts', () {
        const original = ProxyConfig();
        final copy = original.copyWith(retryAttempts: 10);

        expect(copy.retryAttempts, equals(10));
      });

      test('copies with new headers', () {
        const original = ProxyConfig();
        final copy = original.copyWith(headers: {'Auth': 'bearer'});

        expect(copy.headers, equals({'Auth': 'bearer'}));
      });

      test('copies with new includeHistory', () {
        const original = ProxyConfig();
        final copy = original.copyWith(includeHistory: false);

        expect(copy.includeHistory, isFalse);
      });

      test('copies with new maxHistoryMessages', () {
        const original = ProxyConfig();
        final copy = original.copyWith(maxHistoryMessages: 100);

        expect(copy.maxHistoryMessages, equals(100));
      });

      test('copies all fields at once', () {
        const original = ProxyConfig();
        final copy = original.copyWith(
          timeout: const Duration(seconds: 30),
          retryAttempts: 1,
          headers: {'X-Test': 'test'},
          includeHistory: false,
          maxHistoryMessages: 5,
        );

        expect(copy.timeout, equals(const Duration(seconds: 30)));
        expect(copy.retryAttempts, equals(1));
        expect(copy.headers, equals({'X-Test': 'test'}));
        expect(copy.includeHistory, isFalse);
        expect(copy.maxHistoryMessages, equals(5));
      });
    });
  });

  group('RetryConfig validation', () {
    group('boundary values', () {
      test('accepts zero maxAttempts', () {
        const config = RetryConfig(maxAttempts: 0);

        expect(config.maxAttempts, equals(0));
      });

      test('accepts large maxAttempts', () {
        const config = RetryConfig(maxAttempts: 100);

        expect(config.maxAttempts, equals(100));
      });

      test('accepts zero jitter factor', () {
        const config = RetryConfig(jitterFactor: 0);

        expect(config.jitterFactor, equals(0));
      });

      test('accepts full jitter factor', () {
        const config = RetryConfig(jitterFactor: 1);

        expect(config.jitterFactor, equals(1.0));
      });

      test('accepts zero initial delay', () {
        const config = RetryConfig(initialDelay: Duration.zero);

        expect(config.initialDelay, equals(Duration.zero));
      });

      test('accepts very short initial delay', () {
        const config = RetryConfig(initialDelay: Duration(milliseconds: 1));

        expect(config.initialDelay, equals(const Duration(milliseconds: 1)));
      });

      test('accepts very long max delay', () {
        const config = RetryConfig(maxDelay: Duration(hours: 1));

        expect(config.maxDelay, equals(const Duration(hours: 1)));
      });

      test('accepts multiplier of 1.0 (no backoff)', () {
        const config = RetryConfig(backoffMultiplier: 1);

        expect(config.backoffMultiplier, equals(1.0));
      });

      test('accepts high multiplier', () {
        const config = RetryConfig(backoffMultiplier: 10);

        expect(config.backoffMultiplier, equals(10.0));
      });
    });

    group('empty retryableStatusCodes', () {
      test('accepts empty set', () {
        const config = RetryConfig(retryableStatusCodes: {});

        expect(config.retryableStatusCodes, isEmpty);
        expect(config.shouldRetryStatusCode(429), isFalse);
        expect(config.shouldRetryStatusCode(500), isFalse);
      });
    });

    group('custom retryableStatusCodes', () {
      test('accepts single status code', () {
        const config = RetryConfig(retryableStatusCodes: {503});

        expect(config.retryableStatusCodes.length, equals(1));
        expect(config.shouldRetryStatusCode(503), isTrue);
        expect(config.shouldRetryStatusCode(500), isFalse);
      });

      test('accepts unusual status codes', () {
        const config = RetryConfig(retryableStatusCodes: {418, 451});

        expect(config.shouldRetryStatusCode(418), isTrue);
        expect(config.shouldRetryStatusCode(451), isTrue);
      });
    });
  });

  group('CircuitBreakerConfig validation', () {
    group('boundary values', () {
      test('accepts minimum failure threshold', () {
        const config = CircuitBreakerConfig(failureThreshold: 1);

        expect(config.failureThreshold, equals(1));
      });

      test('accepts large failure threshold', () {
        const config = CircuitBreakerConfig(failureThreshold: 1000);

        expect(config.failureThreshold, equals(1000));
      });

      test('accepts zero recovery timeout', () {
        const config = CircuitBreakerConfig(recoveryTimeout: Duration.zero);

        expect(config.recoveryTimeout, equals(Duration.zero));
      });

      test('accepts very short recovery timeout', () {
        const config = CircuitBreakerConfig(
          recoveryTimeout: Duration(milliseconds: 1),
        );

        expect(config.recoveryTimeout, equals(const Duration(milliseconds: 1)));
      });

      test('accepts long recovery timeout', () {
        const config = CircuitBreakerConfig(
          recoveryTimeout: Duration(hours: 1),
        );

        expect(config.recoveryTimeout, equals(const Duration(hours: 1)));
      });

      test('accepts minimum half-open success threshold', () {
        const config = CircuitBreakerConfig(halfOpenSuccessThreshold: 1);

        expect(config.halfOpenSuccessThreshold, equals(1));
      });

      test('accepts large half-open success threshold', () {
        const config = CircuitBreakerConfig(halfOpenSuccessThreshold: 100);

        expect(config.halfOpenSuccessThreshold, equals(100));
      });
    });

    group('preset configurations behavior', () {
      test('strict preset opens circuit faster', () {
        const strict = CircuitBreakerConfig.strict;
        const lenient = CircuitBreakerConfig.lenient;

        expect(strict.failureThreshold, lessThan(lenient.failureThreshold));
      });

      test('strict preset recovers faster', () {
        const strict = CircuitBreakerConfig.strict;
        const defaults = CircuitBreakerConfig.defaults;

        expect(strict.recoveryTimeout, lessThan(defaults.recoveryTimeout));
      });

      test('lenient preset is more tolerant', () {
        const lenient = CircuitBreakerConfig.lenient;
        const defaults = CircuitBreakerConfig.defaults;

        expect(lenient.failureThreshold, greaterThan(defaults.failureThreshold));
        expect(lenient.recoveryTimeout, greaterThan(defaults.recoveryTimeout));
      });
    });
  });

  group('AnthropicConfig validation assertions', () {
    // Note: Duration validation cannot be done in const constructors due to
    // Dart language constraints. Only int values can be validated.

    test('throws on zero maxTokens', () {
      expect(
        () => AnthropicConfig(maxTokens: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative maxTokens', () {
      expect(
        () => AnthropicConfig(maxTokens: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative retryAttempts', () {
      expect(
        () => AnthropicConfig(retryAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ProxyConfig validation assertions', () {
    // Note: Duration validation cannot be done in const constructors due to
    // Dart language constraints. Only int values can be validated.

    test('throws on negative retryAttempts', () {
      expect(
        () => ProxyConfig(retryAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative maxHistoryMessages', () {
      expect(
        () => ProxyConfig(maxHistoryMessages: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RetryConfig validation assertions', () {
    // Note: Duration validation cannot be done in const constructors due to
    // Dart language constraints. Only numeric values can be validated.

    test('throws on negative maxAttempts', () {
      expect(
        () => RetryConfig(maxAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on backoffMultiplier less than 1', () {
      expect(
        () => RetryConfig(backoffMultiplier: 0.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative jitterFactor', () {
      expect(
        () => RetryConfig(jitterFactor: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on jitterFactor greater than 1', () {
      expect(
        () => RetryConfig(jitterFactor: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('CircuitBreakerConfig validation assertions', () {
    // Note: Duration validation cannot be done in const constructors due to
    // Dart language constraints. Only int values can be validated.

    test('throws on zero failureThreshold', () {
      expect(
        () => CircuitBreakerConfig(failureThreshold: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative failureThreshold', () {
      expect(
        () => CircuitBreakerConfig(failureThreshold: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on zero halfOpenSuccessThreshold', () {
      expect(
        () => CircuitBreakerConfig(halfOpenSuccessThreshold: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative halfOpenSuccessThreshold', () {
      expect(
        () => CircuitBreakerConfig(halfOpenSuccessThreshold: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Configuration immutability', () {
    test('AnthropicConfig is immutable', () {
      const config = AnthropicConfig();

      // Can only test that copyWith creates new instance
      final copy = config.copyWith(maxTokens: 1000);
      expect(copy, isNot(same(config)));
      expect(config.maxTokens, equals(4096)); // Original unchanged
    });

    test('ProxyConfig is immutable', () {
      const config = ProxyConfig();

      final copy = config.copyWith(timeout: const Duration(seconds: 30));
      expect(copy, isNot(same(config)));
      expect(config.timeout, equals(const Duration(seconds: 120))); // Original unchanged
    });

    test('RetryConfig is immutable', () {
      const config = RetryConfig();

      final copy = config.copyWith(maxAttempts: 10);
      expect(copy, isNot(same(config)));
      expect(config.maxAttempts, equals(3)); // Original unchanged
    });

    test('CircuitBreakerConfig is immutable', () {
      const config = CircuitBreakerConfig();

      final copy = config.copyWith(failureThreshold: 10);
      expect(copy, isNot(same(config)));
      expect(config.failureThreshold, equals(5)); // Original unchanged
    });
  });
}
