# Test Templates

## Service Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/services/user_service.dart';

class MockApiService extends Mock implements ApiService {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  group('UserService -', () {
    late UserService service;
    late MockApiService mockApi;
    late MockStorageService mockStorage;

    setUpAll(() {
      registerFallbackValue(UserModel.empty());
    });

    setUp(() {
      mockApi = MockApiService();
      mockStorage = MockStorageService();
      service = UserService(api: mockApi, storage: mockStorage);
    });

    group('fetchUser -', () {
      test('returns user from API on success', () async {
        // Arrange
        final expected = UserModel(id: '1', name: 'Test');
        when(() => mockApi.getUser('1')).thenAnswer((_) async => expected);

        // Act
        final result = await service.fetchUser('1');

        // Assert
        expect(result, equals(expected));
        verify(() => mockApi.getUser('1')).called(1);
      });

      test('throws on API failure', () async {
        when(() => mockApi.getUser(any())).thenThrow(ApiException('Failed'));

        expect(
          () => service.fetchUser('1'),
          throwsA(isA<ApiException>()),
        );
      });

      test('caches user after successful fetch', () async {
        final user = UserModel(id: '1', name: 'Test');
        when(() => mockApi.getUser('1')).thenAnswer((_) async => user);
        when(() => mockStorage.save(any(), any())).thenAnswer((_) async {});

        await service.fetchUser('1');

        verify(() => mockStorage.save('user_1', any())).called(1);
      });
    });
  });
}
```

## Controller/Notifier Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/controllers/login_controller.dart';

class MockAuthService extends Mock implements AuthService {}
class MockNavigator extends Mock implements NavigatorState {}

void main() {
  group('LoginController -', () {
    late LoginController controller;
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
      controller = LoginController(authService: mockAuth);
    });

    tearDown(() {
      controller.dispose();
    });

    group('initialization -', () {
      test('starts with empty fields', () {
        expect(controller.email, isEmpty);
        expect(controller.password, isEmpty);
        expect(controller.isLoading, isFalse);
      });
    });

    group('login -', () {
      test('sets loading during login', () async {
        when(() => mockAuth.login(any(), any())).thenAnswer((_) async {
          expect(controller.isLoading, isTrue);
          return true;
        });

        await controller.login();

        expect(controller.isLoading, isFalse);
      });

      test('returns true on success', () async {
        when(() => mockAuth.login(any(), any())).thenAnswer((_) async => true);

        controller.email = 'test@test.com';
        controller.password = 'password';
        final result = await controller.login();

        expect(result, isTrue);
        verify(() => mockAuth.login('test@test.com', 'password')).called(1);
      });

      test('sets error on failure', () async {
        when(() => mockAuth.login(any(), any()))
            .thenThrow(AuthException('Invalid credentials'));

        controller.email = 'test@test.com';
        controller.password = 'wrong';
        await controller.login();

        expect(controller.hasError, isTrue);
        expect(controller.errorMessage, contains('Invalid'));
      });
    });

    group('validation -', () {
      test('canLogin false when email empty', () {
        controller.email = '';
        controller.password = 'password';
        expect(controller.canLogin, isFalse);
      });

      test('canLogin true when both filled', () {
        controller.email = 'test@test.com';
        controller.password = 'password';
        expect(controller.canLogin, isTrue);
      });
    });
  });
}
```

## Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:myapp/widgets/login_form.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginForm -', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    Future<void> pumpLoginForm(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<AuthService>.value(
              value: mockAuth,
              child: LoginForm(),
            ),
          ),
        ),
      );
    }

    group('rendering -', () {
      testWidgets('displays email and password fields', (tester) async {
        await pumpLoginForm(tester);

        expect(find.byKey(Key('email_field')), findsOneWidget);
        expect(find.byKey(Key('password_field')), findsOneWidget);
      });

      testWidgets('displays login button', (tester) async {
        await pumpLoginForm(tester);

        expect(find.byKey(Key('login_button')), findsOneWidget);
      });
    });

    group('interaction -', () {
      testWidgets('can enter email', (tester) async {
        await pumpLoginForm(tester);

        await tester.enterText(
          find.byKey(Key('email_field')),
          'test@test.com',
        );

        expect(find.text('test@test.com'), findsOneWidget);
      });

      testWidgets('login button triggers auth', (tester) async {
        when(() => mockAuth.login(any(), any()))
            .thenAnswer((_) async => true);

        await pumpLoginForm(tester);

        await tester.enterText(
          find.byKey(Key('email_field')),
          'test@test.com',
        );
        await tester.enterText(
          find.byKey(Key('password_field')),
          'password',
        );
        await tester.tap(find.byKey(Key('login_button')));
        await tester.pumpAndSettle();

        verify(() => mockAuth.login('test@test.com', 'password')).called(1);
      });

      testWidgets('shows loading indicator during login', (tester) async {
        when(() => mockAuth.login(any(), any())).thenAnswer(
          (_) => Future.delayed(Duration(seconds: 1), () => true),
        );

        await pumpLoginForm(tester);

        await tester.enterText(find.byKey(Key('email_field')), 'test@test.com');
        await tester.enterText(find.byKey(Key('password_field')), 'password');
        await tester.tap(find.byKey(Key('login_button')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error states -', () {
      testWidgets('displays error message on failure', (tester) async {
        when(() => mockAuth.login(any(), any()))
            .thenThrow(AuthException('Invalid credentials'));

        await pumpLoginForm(tester);

        await tester.enterText(find.byKey(Key('email_field')), 'test@test.com');
        await tester.enterText(find.byKey(Key('password_field')), 'wrong');
        await tester.tap(find.byKey(Key('login_button')));
        await tester.pumpAndSettle();

        expect(find.text('Invalid credentials'), findsOneWidget);
      });
    });
  });
}
```

## Test Helpers Template

```dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

// Mock Classes
class MockApiService extends Mock implements ApiService {}
class MockAuthService extends Mock implements AuthService {}
class MockStorageService extends Mock implements StorageService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Factory functions for pre-configured mocks
MockApiService createMockApiService({
  Future<User> Function(String)? getUser,
  Future<List<User>> Function()? getUsers,
}) {
  final mock = MockApiService();
  if (getUser != null) {
    when(() => mock.getUser(any())).thenAnswer((inv) => getUser(inv.positionalArguments[0]));
  }
  if (getUsers != null) {
    when(() => mock.getUsers()).thenAnswer((_) => getUsers());
  }
  return mock;
}

MockAuthService createMockAuthService({
  bool loginSuccess = true,
  String? loginError,
}) {
  final mock = MockAuthService();
  if (loginError != null) {
    when(() => mock.login(any(), any())).thenThrow(AuthException(loginError));
  } else {
    when(() => mock.login(any(), any())).thenAnswer((_) async => loginSuccess);
  }
  return mock;
}

// Test fixtures
class TestFixtures {
  static User get testUser => User(id: '1', name: 'Test User', email: 'test@test.com');
  static List<User> get testUsers => [
    User(id: '1', name: 'User 1', email: 'user1@test.com'),
    User(id: '2', name: 'User 2', email: 'user2@test.com'),
  ];
}

// Widget test helper
Widget wrapWithMaterialApp(Widget child, {
  NavigatorObserver? observer,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    navigatorObservers: observer != null ? [observer] : [],
    home: Scaffold(body: child),
  );
}
```

## Integration Test Template

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete user flow: login -> home -> logout', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login screen
      expect(find.byKey(Key('login_view')), findsOneWidget);

      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'testpassword123',
      );
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Home screen
      expect(find.byKey(Key('home_view')), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('profile_view')), findsOneWidget);

      // Logout
      await tester.tap(find.byKey(Key('logout_button')));
      await tester.pumpAndSettle();

      // Back to login
      expect(find.byKey(Key('login_view')), findsOneWidget);
    });
  });
}
```

## Golden Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/widgets/custom_card.dart';

void main() {
  group('CustomCard Golden Tests', () {
    testWidgets('matches golden file', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: CustomCard(
                title: 'Test Title',
                subtitle: 'Test Subtitle',
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomCard),
        matchesGoldenFile('goldens/custom_card.png'),
      );
    });

    testWidgets('dark theme matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: CustomCard(
                title: 'Test Title',
                subtitle: 'Test Subtitle',
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomCard),
        matchesGoldenFile('goldens/custom_card_dark.png'),
      );
    });
  });
}

// Run: flutter test --update-goldens
```

## Bloc Test Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/blocs/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () {
        when(() => mockRepo.login(any(), any()))
            .thenAnswer((_) async => User(id: '1', name: 'Test'));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoginRequested('test@test.com', 'password')),
      expect: () => [
        AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockRepo.login(any(), any()))
            .thenThrow(AuthException('Invalid'));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoginRequested('test@test.com', 'wrong')),
      expect: () => [
        AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });
}
```

## Riverpod Test Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/providers/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('userProvider', () {
    test('fetches and returns user', () async {
      final mockRepo = MockUserRepository();
      when(() => mockRepo.getUser('1'))
          .thenAnswer((_) async => User(id: '1', name: 'Test'));

      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(userProvider('1').future);

      expect(result.name, 'Test');
      verify(() => mockRepo.getUser('1')).called(1);
    });
  });
}

// Widget test with Riverpod
testWidgets('displays user from provider', (tester) async {
  final mockRepo = MockUserRepository();
  when(() => mockRepo.getUser(any()))
      .thenAnswer((_) async => User(id: '1', name: 'John'));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(home: UserProfile(userId: '1')),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('John'), findsOneWidget);
});
```
