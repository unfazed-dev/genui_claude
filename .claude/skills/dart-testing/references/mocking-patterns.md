# Advanced Mocking Patterns

## Custom Argument Matchers

```dart
// Match any string starting with 'user_'
when(() => mock.findUser(any(that: startsWith('user_'))))
    .thenAnswer((_) async => mockUser);

// Match custom objects
when(() => mock.save(any(that: isA<UserModel>())))
    .thenAnswer((_) async => true);

// Predicate matching
when(() => mock.process(any(that: predicate<int>((v) => v > 0))))
    .thenReturn('positive');
```

## Stubbing Sequences

```dart
// Return different values on successive calls
var callCount = 0;
when(() => mock.fetch()).thenAnswer((_) async {
  callCount++;
  if (callCount == 1) return 'first';
  if (callCount == 2) return 'second';
  return 'subsequent';
});

// Throw then succeed
var attempts = 0;
when(() => mock.retry()).thenAnswer((_) async {
  attempts++;
  if (attempts < 3) throw RetryException();
  return 'success';
});
```

## Mocking Streams

```dart
class MockStreamService extends Mock implements StreamService {}

test('handles stream events', () async {
  final controller = StreamController<int>();
  when(() => mock.dataStream).thenAnswer((_) => controller.stream);

  final results = <int>[];
  mock.dataStream.listen(results.add);

  controller.add(1);
  controller.add(2);
  await controller.close();

  expect(results, [1, 2]);
});

// Pre-built stream
when(() => mock.dataStream).thenAnswer(
  (_) => Stream.fromIterable([1, 2, 3]),
);
```

## Mocking Getters and Setters

```dart
test('mock getters', () {
  when(() => mock.currentValue).thenReturn(42);
  expect(mock.currentValue, 42);
});

test('mock setters', () {
  // Setters return void, use thenReturn without value
  when(() => mock.currentValue = any()).thenReturn(null);
  mock.currentValue = 100;
  verify(() => mock.currentValue = 100).called(1);
});
```

## Partial Mocking (Spy Pattern)

```dart
// Use real implementation but override specific methods
class SpyService extends RealService {
  @override
  Future<Data> fetchFromNetwork() async {
    // Return mock data instead of making network call
    return Data.mock();
  }
}

// Or use mocktail's spy
test('spy on real object', () {
  final real = RealService();
  final spy = MockRealService();

  // Delegate to real by default
  when(() => spy.calculate(any())).thenAnswer(
    (inv) => real.calculate(inv.positionalArguments[0] as int),
  );

  // Override specific case
  when(() => spy.calculate(0)).thenReturn(-1);
});
```

## Mocking Static/Factory Methods

```dart
// Wrap static methods in injectable service
abstract class DateTimeService {
  DateTime now();
}

class RealDateTimeService implements DateTimeService {
  @override
  DateTime now() => DateTime.now();
}

class MockDateTimeService extends Mock implements DateTimeService {}

// Usage in tests
when(() => mockDateTime.now()).thenReturn(DateTime(2024, 1, 1));
```

## Mocking HTTP Clients

```dart
class MockHttpClient extends Mock implements http.Client {}

test('fetches data from API', () async {
  final mockClient = MockHttpClient();

  when(() => mockClient.get(any())).thenAnswer(
    (_) async => http.Response('{"id": 1}', 200),
  );

  final service = ApiService(mockClient);
  final result = await service.fetchItem();

  expect(result.id, 1);
});

// Mock errors
when(() => mockClient.get(any())).thenAnswer(
  (_) async => http.Response('Not Found', 404),
);

// Mock network failure
when(() => mockClient.get(any())).thenThrow(SocketException('No internet'));
```

## Mocking Callbacks

```dart
test('invokes callback with result', () async {
  final callback = MockFunction<void, String>();
  when(() => callback(any())).thenReturn(null);

  await service.processWithCallback(callback);

  verify(() => callback('result')).called(1);
});

// Using real function for capture
String? capturedValue;
await service.processWithCallback((v) => capturedValue = v);
expect(capturedValue, 'result');
```

## Reset and Clear

```dart
setUp(() {
  reset(mock);  // Clear all stubs and interactions
});

test('clear interactions only', () {
  clearInteractions(mock);  // Keep stubs, clear call history
  verifyNever(() => mock.anyMethod());
});
```

## Testing Error Scenarios

```dart
group('error handling', () {
  test('network timeout', () async {
    when(() => mock.fetch()).thenAnswer(
      (_) => Future.delayed(Duration(seconds: 30), () => throw TimeoutException()),
    );

    expect(
      () => service.fetchWithTimeout(Duration(seconds: 5)),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('retry on transient failure', () async {
    var attempts = 0;
    when(() => mock.fetch()).thenAnswer((_) async {
      attempts++;
      if (attempts < 3) throw TransientException();
      return 'success';
    });

    final result = await service.fetchWithRetry(maxAttempts: 3);

    expect(result, 'success');
    expect(attempts, 3);
  });
});
```

## Mocking with GetIt (Service Locator)

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupTestLocator() {
  getIt.allowReassignment = true;
}

void resetTestLocator() {
  getIt.reset();
}

T registerMock<T extends Object>(T mock) {
  if (getIt.isRegistered<T>()) {
    getIt.unregister<T>();
  }
  getIt.registerSingleton<T>(mock);
  return mock;
}

// Usage in tests
setUp(() {
  setupTestLocator();
  registerMock<ApiService>(MockApiService());
});

tearDown(() => resetTestLocator());
```

## Mocking with Provider (Constructor Injection)

```dart
// Prefer constructor injection over service locators
class UserRepository {
  final ApiService api;
  final CacheService cache;

  UserRepository({required this.api, required this.cache});
}

// Test setup is straightforward
test('fetches user', () async {
  final mockApi = MockApiService();
  final mockCache = MockCacheService();
  final repo = UserRepository(api: mockApi, cache: mockCache);

  when(() => mockApi.getUser('1')).thenAnswer((_) async => testUser);

  final result = await repo.fetchUser('1');
  expect(result, testUser);
});
```
