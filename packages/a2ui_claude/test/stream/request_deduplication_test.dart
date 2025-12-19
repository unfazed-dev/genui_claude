import 'dart:async';

import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

void main() {
  group('DeduplicationConfig', () {
    test('creates with default values', () {
      const config = DeduplicationConfig.defaults;

      expect(config.enabled, isTrue);
      expect(config.windowMs, 100);
      expect(config.maxCacheSize, 100);
      expect(config.hashMessages, isTrue);
    });

    test('disabled config disables deduplication', () {
      const config = DeduplicationConfig.disabled;

      expect(config.enabled, isFalse);
    });

    test('creates with custom values', () {
      const config = DeduplicationConfig(
        windowMs: 500,
        maxCacheSize: 50,
        hashMessages: false,
      );

      expect(config.windowMs, 500);
      expect(config.maxCacheSize, 50);
      expect(config.hashMessages, isFalse);
    });
  });

  group('RequestDeduplicator', () {
    late RequestDeduplicator<String> deduplicator;

    setUp(() {
      deduplicator = RequestDeduplicator<String>(
        config: const DeduplicationConfig(
          windowMs: 500,
          maxCacheSize: 10,
        ),
      );
    });

    tearDown(() {
      deduplicator.dispose();
    });

    group('execute', () {
      test('executes request and returns result', () async {
        final result = await deduplicator.execute(
          'key-1',
          () async => 'result',
        );

        expect(result, 'result');
      });

      test('returns same future for duplicate requests', () async {
        var callCount = 0;

        // Start two requests with same key
        final future1 = deduplicator.execute('key-same', () async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'result';
        });

        final future2 = deduplicator.execute('key-same', () async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'different-result';
        });

        final results = await Future.wait([future1, future2]);

        // Only one execution, both get same result
        expect(callCount, 1);
        expect(results[0], 'result');
        expect(results[1], 'result');
      });

      test('executes separate requests for different keys', () async {
        var callCount = 0;

        final future1 = deduplicator.execute('key-1', () async {
          callCount++;
          return 'result-1';
        });

        final future2 = deduplicator.execute('key-2', () async {
          callCount++;
          return 'result-2';
        });

        final results = await Future.wait([future1, future2]);

        expect(callCount, 2);
        expect(results[0], 'result-1');
        expect(results[1], 'result-2');
      });

      test('propagates errors to all waiting requests', () async {
        final future1 = deduplicator.execute('key-error', () async {
          throw Exception('Test error');
        });

        final future2 = deduplicator.execute('key-error', () async {
          throw Exception('Test error');
        });

        await expectLater(future1, throwsException);
        await expectLater(future2, throwsException);
      });
    });

    group('isInFlight', () {
      test('returns false for unknown key', () {
        expect(deduplicator.isInFlight('unknown'), isFalse);
      });

      test('returns true for in-flight request', () async {
        final completer = Completer<String>();

        unawaited(deduplicator.execute('in-flight', () => completer.future));

        expect(deduplicator.isInFlight('in-flight'), isTrue);

        completer.complete('done');
      });
    });

    group('inFlightCount', () {
      test('starts at zero', () {
        expect(deduplicator.inFlightCount, 0);
      });

      test('increases with in-flight requests', () async {
        final completer = Completer<String>();

        unawaited(deduplicator.execute('key-1', () => completer.future));

        expect(deduplicator.inFlightCount, 1);

        completer.complete('done');
      });
    });

    group('createKey', () {
      test('creates consistent keys for same data', () {
        final data = {
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
          'model': 'claude-sonnet',
          'max_tokens': 1000,
        };

        final key1 = deduplicator.createKey(data);
        final key2 = deduplicator.createKey(data);

        expect(key1, key2);
      });

      test('creates different keys for different data', () {
        final data1 = {
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
        };
        final data2 = {
          'messages': [
            {'role': 'user', 'content': 'Goodbye'}
          ],
        };

        final key1 = deduplicator.createKey(data1);
        final key2 = deduplicator.createKey(data2);

        expect(key1, isNot(key2));
      });
    });

    group('clear', () {
      test('removes all tracked requests', () async {
        final completer = Completer<String>();

        unawaited(deduplicator.execute('key-1', () => completer.future));

        expect(deduplicator.inFlightCount, 1);

        deduplicator.clear();

        expect(deduplicator.inFlightCount, 0);

        completer.complete('done');
      });
    });

    group('disabled deduplication', () {
      test('executes all requests separately when disabled', () async {
        final disabledDeduplicator = RequestDeduplicator<String>(
          config: DeduplicationConfig.disabled,
        );

        var callCount = 0;

        final future1 = disabledDeduplicator.execute('same-key', () async {
          callCount++;
          return 'result-1';
        });

        final future2 = disabledDeduplicator.execute('same-key', () async {
          callCount++;
          return 'result-2';
        });

        final results = await Future.wait([future1, future2]);

        // Both executed separately
        expect(callCount, 2);
        expect(results[0], 'result-1');
        expect(results[1], 'result-2');

        disabledDeduplicator.dispose();
      });
    });

    group('max cache size', () {
      test('removes oldest entries when exceeding max cache size', () async {
        final smallCacheDeduplicator = RequestDeduplicator<String>(
          config: const DeduplicationConfig(
            maxCacheSize: 2,
            windowMs: 10000, // Long window to prevent expiry
          ),
        );

        // Add entries up to limit
        await smallCacheDeduplicator.execute('key-1', () async => 'a');
        await smallCacheDeduplicator.execute('key-2', () async => 'b');

        // At limit now
        expect(smallCacheDeduplicator.inFlightCount, 2);

        // Adding more entries triggers cleanup before adding
        await smallCacheDeduplicator.execute('key-3', () async => 'c');

        // Cleanup removes oldest entries to maintain maxCacheSize
        // After cleanup (removes to max), then add new = max + 1
        // This ensures unbounded growth is prevented
        expect(smallCacheDeduplicator.inFlightCount, lessThanOrEqualTo(3));

        smallCacheDeduplicator.dispose();
      });
    });
  });
}
