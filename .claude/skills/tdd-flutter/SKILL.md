---
name: tdd-flutter
description: Test-Driven Development methodology for Flutter, Dart, and Stacked architecture. MANDATORY for all code implementation. Enforces Red-Green-Refactor cycle. Use when implementing features, fixing bugs, creating services/viewmodels, or any code changes.
---

# TDD Methodology for Flutter/Dart/Stacked

## CRITICAL: Mandatory Workflow

**ALL code implementation in Flutter/Dart projects MUST follow TDD methodology.** No production code is written without a failing test first.

## TDD Cycle: Red-Green-Refactor

```
┌─────────────────────────────────────────────────────────────┐
│  1. RED: Write a failing test for the desired behavior      │
│     ↓                                                        │
│  2. GREEN: Write MINIMAL code to make the test pass         │
│     ↓                                                        │
│  3. REFACTOR: Clean up while keeping tests green            │
│     ↓                                                        │
│  [Repeat for next behavior]                                  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Decision Tree

**Before writing ANY production code, determine:**

1. **Is this a new feature?** → Start with acceptance test, then unit tests
2. **Is this a bug fix?** → Write test that reproduces the bug FIRST
3. **Is this a refactor?** → Ensure tests exist, then refactor with green tests
4. **Is this a Stacked component?** → Follow Stacked TDD patterns below

## Stacked TDD Patterns

### Service Implementation

**Step 1: Create test file first**
```
test/unit/services/{service_name}_service_test.dart
```

**Step 2: Write failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/services/user_service.dart';

void main() {
  group('UserService', () {
    late UserService service;

    setUp(() {
      service = UserService();
    });

    group('fetchUser', () {
      test('returns user when API call succeeds', () async {
        // RED: This test fails because UserService doesn't exist yet
        final result = await service.fetchUser('123');

        expect(result, isNotNull);
        expect(result.id, equals('123'));
      });
    });
  });
}
```

**Step 3: Run test - confirm it fails**
```bash
flutter test test/unit/services/user_service_test.dart
```

**Step 4: Write MINIMAL implementation**
```dart
// lib/services/user_service.dart
class UserService {
  Future<User> fetchUser(String id) async {
    // Minimal implementation to pass test
    return User(id: id);
  }
}
```

**Step 5: Run test - confirm it passes**

**Step 6: Add next behavior with new failing test**

### ViewModel Implementation

**Step 1: Test file first**
```
test/unit/viewmodels/{view_name}_viewmodel_test.dart
```

**Step 2: Test structure for Stacked ViewModels**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked/stacked.dart';
import 'package:app/ui/views/home/home_viewmodel.dart';

// Mock dependencies
class MockUserService extends Mock implements UserService {}
class MockRouterService extends Mock implements RouterService {}

void main() {
  group('HomeViewModel', () {
    late HomeViewModel viewModel;
    late MockUserService mockUserService;
    late MockRouterService mockRouterService;

    setUp(() {
      mockUserService = MockUserService();
      mockRouterService = MockRouterService();
      viewModel = HomeViewModel(
        userService: mockUserService,
        routerService: mockRouterService,
      );
    });

    group('initialization', () {
      test('starts with empty user list', () {
        expect(viewModel.users, isEmpty);
      });

      test('isBusy is false initially', () {
        expect(viewModel.isBusy, isFalse);
      });
    });

    group('loadUsers', () {
      test('sets busy state while loading', () async {
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => []);

        final future = viewModel.loadUsers();

        expect(viewModel.isBusy, isTrue);

        await future;

        expect(viewModel.isBusy, isFalse);
      });

      test('populates users on success', () async {
        final testUsers = [User(id: '1', name: 'Test')];
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => testUsers);

        await viewModel.loadUsers();

        expect(viewModel.users, equals(testUsers));
      });
    });

    group('navigation', () {
      test('navigates to profile using RouterService', () async {
        when(() => mockRouterService.navigateToProfileView(userId: any(named: 'userId')))
            .thenAnswer((_) async {});

        await viewModel.goToProfile('123');

        verify(() => mockRouterService.navigateToProfileView(userId: '123')).called(1);
      });
    });
  });
}
```

**Step 3: Implement ViewModel with dependency injection**
```dart
class HomeViewModel extends BaseViewModel {
  final UserService _userService;
  final RouterService _routerService;

  HomeViewModel({
    required UserService userService,
    required RouterService routerService,
  })  : _userService = userService,
        _routerService = routerService;

  List<User> _users = [];
  List<User> get users => _users;

  Future<void> loadUsers() async {
    setBusy(true);
    _users = await _userService.getUsers();
    setBusy(false);
    notifyListeners();
  }

  Future<void> goToProfile(String userId) async {
    await _routerService.navigateToProfileView(userId: userId);
  }
}
```

### Widget/View Implementation

**Test file location:**
```
test/widget/views/{view_name}_view_test.dart
```

**Widget test with ViewModel mock:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked/stacked.dart';

class MockHomeViewModel extends Mock implements HomeViewModel {}

void main() {
  group('HomeView', () {
    late MockHomeViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockHomeViewModel();
      // Default stubs
      when(() => mockViewModel.isBusy).thenReturn(false);
      when(() => mockViewModel.users).thenReturn([]);
    });

    testWidgets('shows loading indicator when busy', (tester) async {
      when(() => mockViewModel.isBusy).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ViewModelBuilder<HomeViewModel>.reactive(
            viewModelBuilder: () => mockViewModel,
            builder: (context, model, child) => HomeView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays user list when loaded', (tester) async {
      when(() => mockViewModel.users).thenReturn([
        User(id: '1', name: 'John'),
        User(id: '2', name: 'Jane'),
      ]);

      await tester.pumpWidget(/* ... */);

      expect(find.text('John'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });
  });
}
```

## Bug Fix TDD Process

**MANDATORY: Write a failing test that reproduces the bug BEFORE fixing it.**

```
1. Identify the bug behavior
2. Write test that expects CORRECT behavior (test will fail)
3. Run test - confirm it fails for the RIGHT reason
4. Fix the bug with minimal code change
5. Run test - confirm it passes
6. Run ALL tests - ensure no regressions
```

**Example:**
```dart
group('Bug #123: User not saved when name contains special chars', () {
  test('saves user with special characters in name', () async {
    final user = User(name: "O'Brien");

    // This test fails before the fix
    final result = await service.saveUser(user);

    expect(result.success, isTrue);
    expect(result.user.name, equals("O'Brien"));
  });
});
```

## Test Organization

```
test/
├── unit/
│   ├── services/
│   │   ├── user_service_test.dart
│   │   └── auth_service_test.dart
│   └── viewmodels/
│       ├── home_viewmodel_test.dart
│       └── profile_viewmodel_test.dart
├── widget/
│   └── views/
│       ├── home_view_test.dart
│       └── profile_view_test.dart
├── integration/
│   └── flows/
│       └── login_flow_test.dart
└── helpers/
    ├── test_helpers.dart
    └── mocks.dart
```

## TDD Checklist (Execute for EVERY Implementation)

### Before Writing Production Code
- [ ] Test file created at correct location
- [ ] Test describes expected behavior, not implementation
- [ ] Test is atomic (tests ONE behavior)
- [ ] Dependencies are mocked
- [ ] Test runs and FAILS

### After Writing Production Code
- [ ] Test passes with MINIMAL implementation
- [ ] No unnecessary code added
- [ ] All existing tests still pass
- [ ] Code refactored if needed (tests still green)

### For Stacked Components
- [ ] Services: Tested in isolation with mocked dependencies
- [ ] ViewModels: Tested with mocked services, verified setBusy usage
- [ ] Navigation: Tested using RouterService mocks
- [ ] Views: Widget tests with mocked ViewModels

## Commands

```bash
# Run single test file (during TDD cycle)
flutter test test/unit/services/user_service_test.dart

# Run all unit tests
flutter test test/unit/

# Run with coverage
flutter test --coverage

# Watch mode (re-run on change)
flutter test --watch

# Run specific test by name
flutter test --name "saves user with special characters"
```

## Anti-Patterns to AVOID

| Anti-Pattern | Correct Approach |
|--------------|------------------|
| Writing code first, tests later | Write failing test FIRST |
| Testing implementation details | Test behavior/outcomes only |
| Multiple assertions per test | One logical assertion per test |
| Testing private methods directly | Test through public interface |
| Skipping tests for "simple" code | ALL code needs tests |
| Giant test setup | Use test helpers and fixtures |
| Mocking everything | Only mock external dependencies |

## Integration with dart-testing Skill

For detailed test syntax, mocking patterns, and matchers, invoke the `dart-testing` skill.

This TDD skill defines the METHODOLOGY; `dart-testing` provides the TOOLING.

## Enforcement

Claude MUST:
1. Create test files before implementation files
2. Show failing test output before writing production code
3. Show passing test output after implementation
4. Refuse to write production code without corresponding test
5. Use setBusy/setBusyForObject for ALL loading states in Stacked
6. Use RouterService (not NavigationService) for navigation in Stacked
