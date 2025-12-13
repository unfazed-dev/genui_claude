# TDD Templates

Quick-start templates for common TDD scenarios in Flutter/Stacked projects.

## Service Test Template

```dart
// test/unit/services/{name}_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/services/{name}_service.dart';

// Mock dependencies
class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('{Name}Service', () {
    late {Name}Service service;
    late MockApiClient mockApiClient;

    setUpAll(() {
      // Register fallback values for custom types
      registerFallbackValue(ModelType());
    });

    setUp(() {
      mockApiClient = MockApiClient();
      service = {Name}Service(apiClient: mockApiClient);
    });

    group('{methodName}', () {
      test('description of expected behavior', () async {
        // Arrange
        when(() => mockApiClient.method(any()))
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await service.methodName();

        // Assert
        expect(result, equals(expectedResult));
        verify(() => mockApiClient.method(any())).called(1);
      });

      test('handles error correctly', () async {
        when(() => mockApiClient.method(any()))
            .thenThrow(Exception('error'));

        expect(
          () => service.methodName(),
          throwsA(isA<ServiceException>()),
        );
      });
    });
  });
}
```

## ViewModel Test Template

```dart
// test/unit/viewmodels/{name}_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/ui/views/{name}/{name}_viewmodel.dart';

class Mock{Service}Service extends Mock implements {Service}Service {}
class MockRouterService extends Mock implements RouterService {}

void main() {
  group('{Name}ViewModel', () {
    late {Name}ViewModel viewModel;
    late Mock{Service}Service mockService;
    late MockRouterService mockRouterService;

    setUp(() {
      mockService = Mock{Service}Service();
      mockRouterService = MockRouterService();
      viewModel = {Name}ViewModel(
        {service}Service: mockService,
        routerService: mockRouterService,
      );
    });

    group('initialization', () {
      test('has correct initial state', () {
        expect(viewModel.isBusy, isFalse);
        expect(viewModel.hasError, isFalse);
      });
    });

    group('{actionName}', () {
      test('sets busy state during operation', () async {
        when(() => mockService.action())
            .thenAnswer((_) async => result);

        final future = viewModel.actionName();
        expect(viewModel.isBusy, isTrue);

        await future;
        expect(viewModel.isBusy, isFalse);
      });

      test('updates state on success', () async {
        when(() => mockService.action())
            .thenAnswer((_) async => expectedData);

        await viewModel.actionName();

        expect(viewModel.data, equals(expectedData));
      });

      test('sets error on failure', () async {
        when(() => mockService.action())
            .thenThrow(Exception('error'));

        await viewModel.actionName();

        expect(viewModel.hasError, isTrue);
      });
    });

    group('navigation', () {
      test('navigates to {destination} view', () async {
        when(() => mockRouterService.navigateTo{Destination}View())
            .thenAnswer((_) async {});

        await viewModel.goTo{Destination}();

        verify(() => mockRouterService.navigateTo{Destination}View()).called(1);
      });
    });
  });
}
```

## Widget Test Template

```dart
// test/widget/views/{name}_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked/stacked.dart';
import 'package:app/ui/views/{name}/{name}_view.dart';
import 'package:app/ui/views/{name}/{name}_viewmodel.dart';

class Mock{Name}ViewModel extends Mock implements {Name}ViewModel {}

void main() {
  group('{Name}View', () {
    late Mock{Name}ViewModel mockViewModel;

    setUp(() {
      mockViewModel = Mock{Name}ViewModel();
      // Default stubs
      when(() => mockViewModel.isBusy).thenReturn(false);
      when(() => mockViewModel.hasError).thenReturn(false);
    });

    Widget buildWidget() {
      return MaterialApp(
        home: ViewModelBuilder<{Name}ViewModel>.reactive(
          viewModelBuilder: () => mockViewModel,
          disposeViewModel: false,
          builder: (context, model, child) => const {Name}View(),
        ),
      );
    }

    testWidgets('shows loading indicator when busy', (tester) async {
      when(() => mockViewModel.isBusy).thenReturn(true);

      await tester.pumpWidget(buildWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when hasError', (tester) async {
      when(() => mockViewModel.hasError).thenReturn(true);
      when(() => mockViewModel.modelError).thenReturn('Error message');

      await tester.pumpWidget(buildWidget());

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('shows content when loaded', (tester) async {
      when(() => mockViewModel.data).thenReturn(testData);

      await tester.pumpWidget(buildWidget());

      expect(find.text('Expected content'), findsOneWidget);
    });

    testWidgets('calls viewModel action on button tap', (tester) async {
      when(() => mockViewModel.actionName()).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('action_button')));

      verify(() => mockViewModel.actionName()).called(1);
    });
  });
}
```

## Bug Fix Template

```dart
// test/unit/regressions/bug_{number}_test.dart
import 'package:flutter_test/flutter_test.dart';

/// Bug #{number}: {Brief description}
///
/// Original issue: {Link or description}
/// Root cause: {Explanation}
/// Fix: {What was changed}
void main() {
  group('Bug #{number}: {Description}', () {
    test('reproduces original bug behavior', () {
      // This test documents the bug
      // Comment out skip to verify bug exists before fix
      // skip: 'Bug has been fixed',

      // Setup that triggers bug
      // Assert expected (correct) behavior
    });

    test('correct behavior after fix', () {
      // Setup same conditions
      // Assert correct behavior that fix provides
    });
  });
}
```

## Stacked CLI Commands

Generate components with corresponding test files:

```bash
# Generate view (creates viewmodel too)
stacked create view login

# Generate service
stacked create service user

# Generate bottom sheet
stacked create bottom_sheet confirmation

# Generate dialog
stacked create dialog error
```

After generation, immediately create test files:

```bash
# Service test
touch test/unit/services/user_service_test.dart

# ViewModel test
touch test/unit/viewmodels/login_viewmodel_test.dart

# Widget test
touch test/widget/views/login_view_test.dart
```
