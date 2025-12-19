import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/config/claude_config.dart';
import 'package:genui_claude/src/config/retry_config.dart';
import 'package:genui_claude/src/resilience/circuit_breaker.dart';

void main() {
  group('ClaudeConfig', () {
    group('constructor defaults', () {
      test('has correct default maxTokens', () {
        const config = ClaudeConfig();

        expect(config.maxTokens, equals(4096));
      });

      test('has correct default timeout', () {
        const config = ClaudeConfig();

        expect(config.timeout, equals(const Duration(seconds: 60)));
      });

      test('has correct default retryAttempts', () {
        const config = ClaudeConfig();

        expect(config.retryAttempts, equals(3));
      });

      test('has correct default enableStreaming', () {
        const config = ClaudeConfig();

        expect(config.enableStreaming, isTrue);
      });

      test('has null default headers', () {
        const config = ClaudeConfig();

        expect(config.headers, isNull);
      });

      test('has correct default enableFineGrainedStreaming', () {
        const config = ClaudeConfig();

        expect(config.enableFineGrainedStreaming, isFalse);
      });

      test('has correct default enableInterleavedThinking', () {
        const config = ClaudeConfig();

        expect(config.enableInterleavedThinking, isFalse);
      });

      test('has null default thinkingBudgetTokens', () {
        const config = ClaudeConfig();

        expect(config.thinkingBudgetTokens, isNull);
      });

      test('has correct default enableToolSearch', () {
        const config = ClaudeConfig();

        expect(config.enableToolSearch, isFalse);
      });

      test('has correct default maxLoadedToolsPerSession', () {
        const config = ClaudeConfig();

        expect(config.maxLoadedToolsPerSession, equals(50));
      });

      test('has null default topP', () {
        const config = ClaudeConfig();

        expect(config.topP, isNull);
      });

      test('has null default topK', () {
        const config = ClaudeConfig();

        expect(config.topK, isNull);
      });

      test('has null default stopSequences', () {
        const config = ClaudeConfig();

        expect(config.stopSequences, isNull);
      });
    });

    group('custom values', () {
      test('accepts custom maxTokens', () {
        const config = ClaudeConfig(maxTokens: 8192);

        expect(config.maxTokens, equals(8192));
      });

      test('accepts custom timeout', () {
        const config = ClaudeConfig(timeout: Duration(seconds: 120));

        expect(config.timeout, equals(const Duration(seconds: 120)));
      });

      test('accepts custom retryAttempts', () {
        const config = ClaudeConfig(retryAttempts: 5);

        expect(config.retryAttempts, equals(5));
      });

      test('accepts custom headers', () {
        const config = ClaudeConfig(headers: {'X-Custom': 'value'});

        expect(config.headers, equals({'X-Custom': 'value'}));
      });

      test('accepts zero retryAttempts', () {
        const config = ClaudeConfig(retryAttempts: 0);

        expect(config.retryAttempts, equals(0));
      });

      test('accepts small timeout', () {
        const config = ClaudeConfig(timeout: Duration(milliseconds: 100));

        expect(config.timeout, equals(const Duration(milliseconds: 100)));
      });

      test('accepts large maxTokens', () {
        const config = ClaudeConfig(maxTokens: 100000);

        expect(config.maxTokens, equals(100000));
      });

      test('accepts custom enableFineGrainedStreaming', () {
        const config = ClaudeConfig(enableFineGrainedStreaming: true);

        expect(config.enableFineGrainedStreaming, isTrue);
      });

      test('accepts custom enableInterleavedThinking', () {
        const config = ClaudeConfig(enableInterleavedThinking: true);

        expect(config.enableInterleavedThinking, isTrue);
      });

      test('accepts custom thinkingBudgetTokens', () {
        const config = ClaudeConfig(thinkingBudgetTokens: 10000);

        expect(config.thinkingBudgetTokens, equals(10000));
      });

      test('accepts both streaming features enabled', () {
        const config = ClaudeConfig(
          enableFineGrainedStreaming: true,
          enableInterleavedThinking: true,
          thinkingBudgetTokens: 5000,
        );

        expect(config.enableFineGrainedStreaming, isTrue);
        expect(config.enableInterleavedThinking, isTrue);
        expect(config.thinkingBudgetTokens, equals(5000));
      });

      test('accepts custom enableToolSearch', () {
        const config = ClaudeConfig(enableToolSearch: true);

        expect(config.enableToolSearch, isTrue);
      });

      test('accepts custom maxLoadedToolsPerSession', () {
        const config = ClaudeConfig(maxLoadedToolsPerSession: 100);

        expect(config.maxLoadedToolsPerSession, equals(100));
      });

      test('accepts custom topP', () {
        const config = ClaudeConfig(topP: 0.9);

        expect(config.topP, equals(0.9));
      });

      test('accepts topP at maximum (1.0)', () {
        const config = ClaudeConfig(topP: 1);

        expect(config.topP, equals(1.0));
      });

      test('accepts topP at near-minimum', () {
        const config = ClaudeConfig(topP: 0.01);

        expect(config.topP, equals(0.01));
      });

      test('accepts custom topK', () {
        const config = ClaudeConfig(topK: 40);

        expect(config.topK, equals(40));
      });

      test('accepts topK at minimum (1)', () {
        const config = ClaudeConfig(topK: 1);

        expect(config.topK, equals(1));
      });

      test('accepts large topK', () {
        const config = ClaudeConfig(topK: 1000);

        expect(config.topK, equals(1000));
      });

      test('accepts custom stopSequences', () {
        const config = ClaudeConfig(stopSequences: ['END', 'STOP']);

        expect(config.stopSequences, equals(['END', 'STOP']));
      });

      test('accepts single stopSequence', () {
        const config = ClaudeConfig(stopSequences: ['END']);

        expect(config.stopSequences, equals(['END']));
      });

      test('accepts four stopSequences (max)', () {
        const config = ClaudeConfig(stopSequences: ['A', 'B', 'C', 'D']);

        expect(config.stopSequences, equals(['A', 'B', 'C', 'D']));
      });

      test('accepts empty stopSequences', () {
        const config = ClaudeConfig(stopSequences: []);

        expect(config.stopSequences, equals([]));
      });

      test('accepts all sampling parameters together', () {
        const config = ClaudeConfig(
          topP: 0.95,
          topK: 50,
          stopSequences: ['END'],
        );

        expect(config.topP, equals(0.95));
        expect(config.topK, equals(50));
        expect(config.stopSequences, equals(['END']));
      });
    });

    group('defaults preset', () {
      test('defaults preset matches default constructor', () {
        const config = ClaudeConfig.defaults;

        expect(config.maxTokens, equals(4096));
        expect(config.timeout, equals(const Duration(seconds: 60)));
        expect(config.retryAttempts, equals(3));
        expect(config.enableStreaming, isTrue);
        expect(config.headers, isNull);
        expect(config.enableFineGrainedStreaming, isFalse);
        expect(config.enableInterleavedThinking, isFalse);
        expect(config.thinkingBudgetTokens, isNull);
        expect(config.enableToolSearch, isFalse);
        expect(config.maxLoadedToolsPerSession, equals(50));
      });
    });

    group('copyWith', () {
      test('copies with new maxTokens', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(maxTokens: 2048);

        expect(copy.maxTokens, equals(2048));
        expect(copy.timeout, equals(original.timeout));
      });

      test('copies with new timeout', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(timeout: const Duration(seconds: 90));

        expect(copy.timeout, equals(const Duration(seconds: 90)));
        expect(copy.maxTokens, equals(original.maxTokens));
      });

      test('copies with new retryAttempts', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(retryAttempts: 10);

        expect(copy.retryAttempts, equals(10));
      });

      test('copies with new enableStreaming', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(enableStreaming: false);

        expect(copy.enableStreaming, isFalse);
      });

      test('copies with new headers', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(headers: {'Auth': 'token'});

        expect(copy.headers, equals({'Auth': 'token'}));
      });

      test('copies with new enableFineGrainedStreaming', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(enableFineGrainedStreaming: true);

        expect(copy.enableFineGrainedStreaming, isTrue);
        expect(copy.enableInterleavedThinking, isFalse);
      });

      test('copies with new enableInterleavedThinking', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(enableInterleavedThinking: true);

        expect(copy.enableInterleavedThinking, isTrue);
        expect(copy.enableFineGrainedStreaming, isFalse);
      });

      test('copies with new thinkingBudgetTokens', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(thinkingBudgetTokens: 8000);

        expect(copy.thinkingBudgetTokens, equals(8000));
      });

      test('copies all fields at once', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(
          maxTokens: 1000,
          timeout: const Duration(seconds: 30),
          retryAttempts: 1,
          enableStreaming: false,
          headers: {'X-Test': 'test'},
          enableFineGrainedStreaming: true,
          enableInterleavedThinking: true,
          thinkingBudgetTokens: 5000,
          enableToolSearch: true,
          maxLoadedToolsPerSession: 75,
        );

        expect(copy.maxTokens, equals(1000));
        expect(copy.timeout, equals(const Duration(seconds: 30)));
        expect(copy.retryAttempts, equals(1));
        expect(copy.enableStreaming, isFalse);
        expect(copy.headers, equals({'X-Test': 'test'}));
        expect(copy.enableFineGrainedStreaming, isTrue);
        expect(copy.enableInterleavedThinking, isTrue);
        expect(copy.thinkingBudgetTokens, equals(5000));
        expect(copy.enableToolSearch, isTrue);
        expect(copy.maxLoadedToolsPerSession, equals(75));
      });

      test('copies with new enableToolSearch', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(enableToolSearch: true);

        expect(copy.enableToolSearch, isTrue);
        expect(copy.maxLoadedToolsPerSession, equals(50));
      });

      test('copies with new maxLoadedToolsPerSession', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(maxLoadedToolsPerSession: 25);

        expect(copy.maxLoadedToolsPerSession, equals(25));
        expect(copy.enableToolSearch, isFalse);
      });

      test('copies with new topP', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(topP: 0.85);

        expect(copy.topP, equals(0.85));
        expect(copy.topK, isNull);
      });

      test('copies with new topK', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(topK: 30);

        expect(copy.topK, equals(30));
        expect(copy.topP, isNull);
      });

      test('copies with new stopSequences', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(stopSequences: ['END', 'DONE']);

        expect(copy.stopSequences, equals(['END', 'DONE']));
      });

      test('copies all sampling parameters at once', () {
        const original = ClaudeConfig();
        final copy = original.copyWith(
          topP: 0.9,
          topK: 50,
          stopSequences: ['STOP'],
        );

        expect(copy.topP, equals(0.9));
        expect(copy.topK, equals(50));
        expect(copy.stopSequences, equals(['STOP']));
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

        expect(
            lenient.failureThreshold, greaterThan(defaults.failureThreshold),);
        expect(lenient.recoveryTimeout, greaterThan(defaults.recoveryTimeout));
      });
    });
  });

  group('ClaudeConfig validation assertions', () {
    // Note: Duration validation cannot be done in const constructors due to
    // Dart language constraints. Only int values can be validated.

    test('throws on zero maxTokens', () {
      expect(
        () => ClaudeConfig(maxTokens: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative maxTokens', () {
      expect(
        () => ClaudeConfig(maxTokens: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative retryAttempts', () {
      expect(
        () => ClaudeConfig(retryAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on topP of zero', () {
      expect(
        () => ClaudeConfig(topP: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative topP', () {
      expect(
        () => ClaudeConfig(topP: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on topP greater than 1', () {
      expect(
        () => ClaudeConfig(topP: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on topK of zero', () {
      expect(
        () => ClaudeConfig(topK: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on negative topK', () {
      expect(
        () => ClaudeConfig(topK: -1),
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
    test('ClaudeConfig is immutable', () {
      const config = ClaudeConfig();

      // Can only test that copyWith creates new instance
      final copy = config.copyWith(maxTokens: 1000);
      expect(copy, isNot(same(config)));
      expect(config.maxTokens, equals(4096)); // Original unchanged
    });

    test('ProxyConfig is immutable', () {
      const config = ProxyConfig();

      final copy = config.copyWith(timeout: const Duration(seconds: 30));
      expect(copy, isNot(same(config)));
      expect(config.timeout,
          equals(const Duration(seconds: 120)),); // Original unchanged
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
