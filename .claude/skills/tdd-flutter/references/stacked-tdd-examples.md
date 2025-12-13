# Stacked TDD Examples

Complete examples demonstrating TDD workflow for common Stacked patterns.

## Example 1: Complete Service Implementation

### Scenario: Create UserService with CRUD operations

**Step 1: Write first failing test**

```dart
// test/unit/services/user_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// This import will fail initially - that's expected
import 'package:app/services/user_service.dart';
import 'package:app/models/user_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('UserService', () {
    late UserService service;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      service = UserService(apiClient: mockApiClient);
    });

    group('getUser', () {
      test('returns user when API call succeeds', () async {
        // Arrange
        final expectedUser = UserModel(id: '1', name: 'John');
        when(() => mockApiClient.get('/users/1'))
            .thenAnswer((_) async => {'id': '1', 'name': 'John'});

        // Act
        final result = await service.getUser('1');

        // Assert
        expect(result, equals(expectedUser));
        verify(() => mockApiClient.get('/users/1')).called(1);
      });
    });
  });
}
```

**Step 2: Run test - see it fail**

```bash
$ flutter test test/unit/services/user_service_test.dart
# Error: Target of URI doesn't exist: 'package:app/services/user_service.dart'
```

**Step 3: Create minimal service to compile**

```dart
// lib/services/user_service.dart
import 'package:app/api/api_client.dart';
import 'package:app/models/user_model.dart';

class UserService {
  final ApiClient _apiClient;

  UserService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel> getUser(String id) async {
    throw UnimplementedError();
  }
}
```

**Step 4: Run test - see it fail for the right reason**

```bash
$ flutter test test/unit/services/user_service_test.dart
# Expected: UserModel(id: '1', name: 'John')
# Actual: throws UnimplementedError
```

**Step 5: Implement minimal code to pass**

```dart
Future<UserModel> getUser(String id) async {
  final response = await _apiClient.get('/users/$id');
  return UserModel.fromJson(response);
}
```

**Step 6: Run test - confirm green**

```bash
$ flutter test test/unit/services/user_service_test.dart
# All tests passed!
```

**Step 7: Add next failing test for error handling**

```dart
test('throws ServiceException when API fails', () async {
  when(() => mockApiClient.get('/users/1'))
      .thenThrow(ApiException('Network error'));

  expect(
    () => service.getUser('1'),
    throwsA(isA<ServiceException>()),
  );
});
```

**Step 8: Implement error handling**

```dart
Future<UserModel> getUser(String id) async {
  try {
    final response = await _apiClient.get('/users/$id');
    return UserModel.fromJson(response);
  } on ApiException catch (e) {
    throw ServiceException('Failed to get user: ${e.message}');
  }
}
```

## Example 2: ViewModel with Form Validation

### Scenario: LoginViewModel with email/password validation

**Step 1: Failing tests for validation logic**

```dart
// test/unit/viewmodels/login_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/ui/views/login/login_viewmodel.dart';

class MockAuthService extends Mock implements AuthService {}
class MockRouterService extends Mock implements RouterService {}

void main() {
  group('LoginViewModel', () {
    late LoginViewModel viewModel;
    late MockAuthService mockAuthService;
    late MockRouterService mockRouterService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockRouterService = MockRouterService();
      viewModel = LoginViewModel(
        authService: mockAuthService,
        routerService: mockRouterService,
      );
    });

    group('email validation', () {
      test('returns error for empty email', () {
        viewModel.email = '';
        expect(viewModel.emailError, equals('Email is required'));
      });

      test('returns error for invalid email format', () {
        viewModel.email = 'notanemail';
        expect(viewModel.emailError, equals('Invalid email format'));
      });

      test('returns null for valid email', () {
        viewModel.email = 'user@example.com';
        expect(viewModel.emailError, isNull);
      });
    });

    group('password validation', () {
      test('returns error for password under 8 characters', () {
        viewModel.password = '1234567';
        expect(viewModel.passwordError, equals('Password must be at least 8 characters'));
      });

      test('returns null for valid password', () {
        viewModel.password = '12345678';
        expect(viewModel.passwordError, isNull);
      });
    });

    group('canSubmit', () {
      test('returns false when form is invalid', () {
        viewModel.email = '';
        viewModel.password = '';
        expect(viewModel.canSubmit, isFalse);
      });

      test('returns true when form is valid', () {
        viewModel.email = 'user@example.com';
        viewModel.password = 'password123';
        expect(viewModel.canSubmit, isTrue);
      });
    });

    group('login', () {
      setUp(() {
        viewModel.email = 'user@example.com';
        viewModel.password = 'password123';
      });

      test('sets busy state during login', () async {
        when(() => mockAuthService.login(any(), any()))
            .thenAnswer((_) async => AuthResult.success());

        final future = viewModel.login();
        expect(viewModel.isBusy, isTrue);

        await future;
        expect(viewModel.isBusy, isFalse);
      });

      test('navigates to home on successful login', () async {
        when(() => mockAuthService.login(any(), any()))
            .thenAnswer((_) async => AuthResult.success());
        when(() => mockRouterService.replaceWithHomeView())
            .thenAnswer((_) async {});

        await viewModel.login();

        verify(() => mockRouterService.replaceWithHomeView()).called(1);
      });

      test('sets error on failed login', () async {
        when(() => mockAuthService.login(any(), any()))
            .thenAnswer((_) async => AuthResult.failure('Invalid credentials'));

        await viewModel.login();

        expect(viewModel.loginError, equals('Invalid credentials'));
        verifyNever(() => mockRouterService.replaceWithHomeView());
      });
    });
  });
}
```

**Step 2: Implement ViewModel incrementally**

```dart
// lib/ui/views/login/login_viewmodel.dart
class LoginViewModel extends BaseViewModel {
  final AuthService _authService;
  final RouterService _routerService;

  LoginViewModel({
    required AuthService authService,
    required RouterService routerService,
  })  : _authService = authService,
        _routerService = routerService;

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    notifyListeners();
  }

  String _password = '';
  String get password => _password;
  set password(String value) {
    _password = value;
    notifyListeners();
  }

  String? _loginError;
  String? get loginError => _loginError;

  String? get emailError {
    if (_email.isEmpty) return 'Email is required';
    if (!_email.contains('@')) return 'Invalid email format';
    return null;
  }

  String? get passwordError {
    if (_password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  bool get canSubmit => emailError == null && passwordError == null;

  Future<void> login() async {
    setBusy(true);
    final result = await _authService.login(_email, _password);

    if (result.isSuccess) {
      await _routerService.replaceWithHomeView();
    } else {
      _loginError = result.error;
      notifyListeners();
    }
    setBusy(false);
  }
}
```

## Example 3: Testing Reactive ViewModels

### Scenario: ViewModel that reacts to stream data

```dart
// test/unit/viewmodels/notifications_viewmodel_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationsViewModel', () {
    late NotificationsViewModel viewModel;
    late MockNotificationService mockService;
    late StreamController<Notification> notificationController;

    setUp(() {
      mockService = MockNotificationService();
      notificationController = StreamController<Notification>.broadcast();

      when(() => mockService.notificationStream)
          .thenAnswer((_) => notificationController.stream);

      viewModel = NotificationsViewModel(notificationService: mockService);
    });

    tearDown(() {
      notificationController.close();
    });

    test('updates notifications when stream emits', () async {
      final notification = Notification(id: '1', message: 'Test');

      // Trigger stream event
      notificationController.add(notification);

      // Allow stream to process
      await Future.delayed(Duration.zero);

      expect(viewModel.notifications, contains(notification));
    });

    test('removes notification when dismissed', () async {
      final notification = Notification(id: '1', message: 'Test');
      notificationController.add(notification);
      await Future.delayed(Duration.zero);

      viewModel.dismiss('1');

      expect(viewModel.notifications, isEmpty);
    });
  });
}
```

## Example 4: Testing Dialog/BottomSheet Results

```dart
// test/unit/viewmodels/order_viewmodel_test.dart
group('confirmCancelOrder', () {
  test('cancels order when user confirms', () async {
    when(() => mockDialogService.showConfirmationDialog(
      title: any(named: 'title'),
      description: any(named: 'description'),
    )).thenAnswer((_) async => DialogResponse(confirmed: true));

    when(() => mockOrderService.cancelOrder(any()))
        .thenAnswer((_) async => true);

    await viewModel.confirmCancelOrder('order-123');

    verify(() => mockOrderService.cancelOrder('order-123')).called(1);
  });

  test('does not cancel when user declines', () async {
    when(() => mockDialogService.showConfirmationDialog(
      title: any(named: 'title'),
      description: any(named: 'description'),
    )).thenAnswer((_) async => DialogResponse(confirmed: false));

    await viewModel.confirmCancelOrder('order-123');

    verifyNever(() => mockOrderService.cancelOrder(any()));
  });
});
```

## Example 5: Testing setBusyForObject

```dart
group('multiple loading states', () {
  test('tracks individual item loading states', () async {
    when(() => mockService.refreshItem(any()))
        .thenAnswer((_) async => Item(id: '1'));

    final future = viewModel.refreshItem('1');

    // Check specific object is busy
    expect(viewModel.busy('item-1'), isTrue);
    expect(viewModel.busy('item-2'), isFalse);

    await future;

    expect(viewModel.busy('item-1'), isFalse);
  });
});
```

## Test Data Factories

```dart
// test/helpers/factories.dart
class TestFactories {
  static UserModel user({
    String? id,
    String? name,
    String? email,
  }) {
    return UserModel(
      id: id ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
    );
  }

  static List<UserModel> users(int count) {
    return List.generate(count, (i) => user(id: 'user-$i', name: 'User $i'));
  }

  static OrderModel order({
    String? id,
    OrderStatus? status,
  }) {
    return OrderModel(
      id: id ?? 'order-${DateTime.now().millisecondsSinceEpoch}',
      status: status ?? OrderStatus.pending,
    );
  }
}
```

## Mock Registration Helper

```dart
// test/helpers/register_mocks.dart
void registerAllFallbackValues() {
  registerFallbackValue(UserModel(id: '', name: '', email: ''));
  registerFallbackValue(OrderModel(id: '', status: OrderStatus.pending));
  registerFallbackValue(Uri.parse('https://example.com'));
  registerFallbackValue(const Duration(seconds: 1));
}

// In test files:
void main() {
  setUpAll(() {
    registerAllFallbackValues();
  });
}
```
