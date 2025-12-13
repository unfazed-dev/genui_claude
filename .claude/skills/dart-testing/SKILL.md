---
name: dart-testing
description: Dart/Flutter testing toolkit with unit tests, mocking (mockito/mocktail), widget tests, and integration tests. Use when writing tests, creating mocks, testing services/viewmodels, or debugging test failures.
---

# Dart Testing Toolkit

## Quick Start

```dart
// pubspec.yaml dependencies
dev_dependencies:
  test: ^1.24.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  build_runner: ^2.4.0
```

Run tests:
```bash
# All tests
flutter test

# Single file
flutter test test/unit/my_service_test.dart

# With coverage
flutter test --coverage
```

## Test File Structure

```
test/
├── unit/           # Pure Dart logic tests
├── widget/         # Flutter widget tests
├── integration/    # Full app integration tests
├── helpers/        # Shared test utilities
│   ├── test_helpers.dart
│   └── mocks.dart
└── fixtures/       # Test data
```

## Unit Tests

### Basic Test Structure

```dart
import 'package:test/test.dart';
import 'package:myapp/services/calculator_service.dart';

void main() {
  group('CalculatorService', () {
    late CalculatorService service;

    setUp(() {
      service = CalculatorService();
    });

    tearDown(() {
      // Cleanup if needed
    });

    test('add returns sum of two numbers', () {
      expect(service.add(2, 3), equals(5));
    });

    test('divide throws on zero divisor', () {
      expect(() => service.divide(10, 0), throwsArgumentError);
    });
  });
}
```

### Testing Async Code

```dart
test('fetchData returns data after delay', () async {
  final result = await service.fetchData();
  expect(result, isNotEmpty);
});

test('stream emits values in order', () {
  expect(
    service.dataStream,
    emitsInOrder([1, 2, 3, emitsDone]),
  );
});

test('completes within timeout', () async {
  await expectLater(
    service.slowOperation(),
    completes,
  ).timeout(Duration(seconds: 5));
});
```

## Mocking with Mocktail

### Setup Mocks

```dart
import 'package:mocktail/mocktail.dart';

// Create mock class
class MockApiService extends Mock implements ApiService {}
class MockNavigationService extends Mock implements NavigationService {}

// Register fallback values for custom types (in setUpAll)
void main() {
  setUpAll(() {
    registerFallbackValue(UserModel(id: '', name: ''));
    registerFallbackValue(Uri.parse('https://example.com'));
  });
}
```

### Stubbing Methods

```dart
late MockApiService mockApi;

setUp(() {
  mockApi = MockApiService();
});

test('returns user when API succeeds', () async {
  // Arrange
  final expectedUser = UserModel(id: '1', name: 'John');
  when(() => mockApi.getUser(any())).thenAnswer((_) async => expectedUser);

  // Act
  final service = UserService(mockApi);
  final result = await service.fetchUser('1');

  // Assert
  expect(result, equals(expectedUser));
  verify(() => mockApi.getUser('1')).called(1);
});

test('handles API failure', () async {
  when(() => mockApi.getUser(any())).thenThrow(ApiException('Network error'));

  final service = UserService(mockApi);

  expect(() => service.fetchUser('1'), throwsA(isA<ApiException>()));
});
```

### Verification Patterns

```dart
// Called exactly once
verify(() => mock.method()).called(1);

// Called multiple times
verify(() => mock.method()).called(greaterThan(0));

// Never called
verifyNever(() => mock.otherMethod());

// Called in order
verifyInOrder([
  () => mock.first(),
  () => mock.second(),
]);

// Capture arguments
final captured = verify(() => mock.save(captureAny())).captured;
expect(captured.first, isA<UserModel>());
```

## Widget Tests

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments when button pressed', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CounterWidget()));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // Rebuild after state change

    expect(find.text('1'), findsOneWidget);
  });
}
```

### Widget Test with Mocks

```dart
testWidgets('displays user name from service', (tester) async {
  final mockService = MockUserService();
  when(() => mockService.currentUser)
      .thenReturn(UserModel(name: 'John Doe'));

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<UserService>.value(
        value: mockService,
        child: ProfileWidget(),
      ),
    ),
  );

  expect(find.text('John Doe'), findsOneWidget);
});
```

### Common Widget Test Actions

```dart
// Tap
await tester.tap(find.byKey(Key('submit')));

// Enter text
await tester.enterText(find.byType(TextField), 'test input');

// Scroll
await tester.drag(find.byType(ListView), Offset(0, -300));

// Long press
await tester.longPress(find.byType(ListTile));

// Wait for animations
await tester.pumpAndSettle();

// Wait for specific duration
await tester.pump(Duration(seconds: 1));
```

### Finder Patterns

```dart
find.text('Hello');                    // By text content
find.byType(ElevatedButton);           // By widget type
find.byKey(Key('my_key'));             // By key
find.byIcon(Icons.add);                // By icon
find.byWidgetPredicate((w) => w is Text && w.data!.contains('error'));
find.descendant(of: find.byType(Card), matching: find.text('Title'));
find.ancestor(of: find.text('Child'), matching: find.byType(Container));
```

## Integration Tests

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Integration Test Structure

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );

      // Submit
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify navigation to home
      expect(find.byType(HomeView), findsOneWidget);
    });
  });
}
```

Run integration tests:
```bash
flutter test integration_test/app_test.dart
```

## Test Matchers

```dart
// Equality
expect(value, equals(expected));
expect(value, isNot(equals(other)));

// Type checking
expect(value, isA<String>());
expect(value, isNull);
expect(value, isNotNull);

// Collections
expect(list, contains(item));
expect(list, containsAll([a, b]));
expect(list, hasLength(3));
expect(list, isEmpty);
expect(map, containsKey('id'));

// Numeric
expect(value, greaterThan(5));
expect(value, inInclusiveRange(1, 10));
expect(value, closeTo(3.14, 0.01));

// Strings
expect(string, startsWith('Hello'));
expect(string, contains('world'));
expect(string, matches(RegExp(r'\d+')));

// Exceptions
expect(() => fn(), throws);
expect(() => fn(), throwsA(isA<CustomException>()));
expect(() => fn(), throwsArgumentError);
```

## Test Helpers Pattern

```dart
// test/helpers/test_helpers.dart
import 'package:mocktail/mocktail.dart';

// Centralized mock definitions
class MockApiService extends Mock implements ApiService {}
class MockStorageService extends Mock implements StorageService {}
class MockAuthService extends Mock implements AuthService {}

// Factory functions for consistent mock creation
MockApiService createMockApiService({
  Future<User> Function()? getUser,
}) {
  final mock = MockApiService();
  if (getUser != null) {
    when(() => mock.getUser(any())).thenAnswer((_) => getUser());
  }
  return mock;
}

// Shared test fixtures
class TestFixtures {
  static User get testUser => User(id: '1', name: 'Test User');
  static List<User> get testUsers => [testUser];
}
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `MissingStubError` | Add `when()` stub for the method |
| `type 'Null' is not a subtype` | Register fallback value with `registerFallbackValue()` |
| Widget test timeout | Use `pumpAndSettle()` or increase timeout |
| Async test hangs | Ensure all Futures complete; check for unawaited calls |
| Mock not working | Verify mock is registered before SUT instantiation |

## Resources

- **Advanced Mocking**: See [references/mocking-patterns.md](references/mocking-patterns.md)
- **Test Templates**: See [references/test-templates.md](references/test-templates.md)
