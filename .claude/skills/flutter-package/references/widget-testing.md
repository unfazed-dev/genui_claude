# Widget Testing Reference

## Test Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Run before all tests
  setUpAll(() {
    // One-time setup
  });

  // Run before each test
  setUp(() {
    // Per-test setup
  });

  // Run after each test
  tearDown(() {
    // Cleanup
  });

  testWidgets('description', (tester) async {
    // Test code
  });
}
```

## Pumping Widgets

```dart
// Pump widget tree
await tester.pumpWidget(
  MaterialApp(home: MyWidget()),
);

// Rebuild after state change
await tester.pump();

// Pump with specific duration
await tester.pump(Duration(milliseconds: 100));

// Pump until animations settle
await tester.pumpAndSettle();

// Pump with timeout
await tester.pumpAndSettle(Duration(seconds: 5));
```

## Finders

### By Type

```dart
find.byType(Text);
find.byType(ElevatedButton);
find.byType(CustomWidget);

// With generic type
find.byType(ListView);
find.bySubtype<StatefulWidget>();
```

### By Text

```dart
find.text('Hello');                    // Exact match
find.textContaining('Hell');           // Contains
find.textContaining(RegExp(r'\d+'));   // Regex
```

### By Key

```dart
find.byKey(Key('submit_button'));
find.byKey(ValueKey('item_1'));
find.byKey(ValueKey(user.id));
```

### By Icon

```dart
find.byIcon(Icons.add);
find.byIcon(Icons.check_circle);
```

### By Semantics

```dart
find.bySemanticsLabel('Submit');
find.bySemanticsLabel(RegExp(r'Item \d+'));
```

### By Widget Predicate

```dart
find.byWidgetPredicate((widget) {
  return widget is Text && widget.data!.startsWith('Error');
});

find.byWidgetPredicate((widget) {
  return widget is Container && widget.color == Colors.red;
});
```

### By Element Predicate

```dart
find.byElementPredicate((element) {
  return element.widget is Text;
});
```

### Descendant/Ancestor

```dart
// Find Text inside a specific Card
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
);

// Find Card containing specific text
find.ancestor(
  of: find.text('Title'),
  matching: find.byType(Card),
);

// Combined
find.descendant(
  of: find.byKey(Key('list_item_1')),
  matching: find.byType(IconButton),
);
```

### First/Last/At

```dart
find.byType(ListTile).first;
find.byType(ListTile).last;
find.byType(ListTile).at(2);
```

## Matchers

```dart
// Widget count
expect(find.text('Hello'), findsOneWidget);
expect(find.text('Hello'), findsNothing);
expect(find.byType(ListTile), findsNWidgets(3));
expect(find.byType(ListTile), findsAtLeast(2));
expect(find.byType(ListTile), findsAtMost(5));
expect(find.byType(Widget), findsWidgets);  // At least one
```

## Interactions

### Tap

```dart
await tester.tap(find.byType(ElevatedButton));
await tester.tap(find.text('Submit'));
await tester.tap(find.byIcon(Icons.add));

// Tap at specific offset
await tester.tapAt(Offset(100, 200));
```

### Long Press

```dart
await tester.longPress(find.byType(ListTile));
await tester.longPressAt(Offset(100, 200));
```

### Double Tap

```dart
await tester.doubleTap(find.byType(TextField));
await tester.doubleTapAt(Offset(100, 200));
```

### Drag

```dart
// Drag by offset
await tester.drag(find.byType(ListView), Offset(0, -300));

// Drag from point to point
await tester.dragFrom(Offset(100, 100), Offset(100, 300));

// Fling (with velocity)
await tester.fling(find.byType(ListView), Offset(0, -300), 1000);

// Drag until visible
await tester.dragUntilVisible(
  find.text('Item 50'),
  find.byType(ListView),
  Offset(0, -100),
);
```

### Text Input

```dart
// Enter text
await tester.enterText(find.byType(TextField), 'Hello World');

// Clear and enter
await tester.enterText(find.byKey(Key('email')), 'test@example.com');

// Show keyboard (focus)
await tester.showKeyboard(find.byType(TextField));

// Type character by character
await tester.testTextInput.receiveAction(TextInputAction.done);
```

### Scrolling

```dart
// Scroll to make widget visible
await tester.ensureVisible(find.text('Item 100'));

// Scroll in scrollable
await tester.scrollUntilVisible(
  find.text('Target'),
  500.0,
  scrollable: find.byType(Scrollable),
);
```

## Getting Widget Properties

```dart
// Get widget
final text = tester.widget<Text>(find.text('Hello'));
expect(text.style?.fontSize, 16);

// Get first widget
final button = tester.firstWidget<ElevatedButton>(find.byType(ElevatedButton));

// Get all widgets
final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
expect(buttons.length, 3);

// Get element
final element = tester.element(find.byType(MyWidget));
final state = (element as StatefulElement).state as MyWidgetState;

// Get render object
final renderBox = tester.renderObject<RenderBox>(find.byType(Container));
expect(renderBox.size.width, 100);
```

## State Access

```dart
testWidgets('access widget state', (tester) async {
  final key = GlobalKey<MyWidgetState>();

  await tester.pumpWidget(
    MaterialApp(home: MyWidget(key: key)),
  );

  // Access state
  expect(key.currentState!.counter, 0);

  // Call state method
  key.currentState!.increment();
  await tester.pump();

  expect(key.currentState!.counter, 1);
});
```

## Testing with Dependencies

### InheritedWidget

```dart
await tester.pumpWidget(
  MaterialApp(
    home: Provider<UserService>.value(
      value: mockUserService,
      child: ProfilePage(),
    ),
  ),
);
```

### Theme

```dart
await tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(
      primaryColor: Colors.blue,
      extensions: [MyCustomTheme.light],
    ),
    home: MyWidget(),
  ),
);
```

### Locale

```dart
await tester.pumpWidget(
  MaterialApp(
    locale: Locale('es'),
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
    ],
    home: MyWidget(),
  ),
);
```

### MediaQuery

```dart
await tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(400, 800),
        devicePixelRatio: 2.0,
        padding: EdgeInsets.only(top: 24),
      ),
      child: MyWidget(),
    ),
  ),
);
```

## Testing Async Operations

### Future

```dart
testWidgets('loads data', (tester) async {
  when(() => mockService.fetchData()).thenAnswer(
    (_) async => ['item1', 'item2'],
  );

  await tester.pumpWidget(MaterialApp(home: DataPage()));

  // Initial loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for async
  await tester.pumpAndSettle();

  // Data loaded
  expect(find.text('item1'), findsOneWidget);
  expect(find.text('item2'), findsOneWidget);
});
```

### Stream

```dart
testWidgets('updates from stream', (tester) async {
  final controller = StreamController<int>();

  await tester.pumpWidget(
    MaterialApp(
      home: StreamBuilder<int>(
        stream: controller.stream,
        builder: (context, snapshot) {
          return Text('Value: ${snapshot.data ?? 0}');
        },
      ),
    ),
  );

  expect(find.text('Value: 0'), findsOneWidget);

  controller.add(42);
  await tester.pump();

  expect(find.text('Value: 42'), findsOneWidget);

  await controller.close();
});
```

## Golden Tests

### Create Golden

```dart
testWidgets('matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: MyWidget(),
    ),
  );

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});

// Run: flutter test --update-goldens
```

### With Device Size

```dart
testWidgets('matches golden on phone', (tester) async {
  tester.view.physicalSize = Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(MaterialApp(home: MyWidget()));

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget_phone.png'),
  );
});
```

### Multiple Variants

```dart
final variants = ValueVariant({
  ThemeData.light(): 'light',
  ThemeData.dark(): 'dark',
});

testWidgets('matches all theme variants', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: variants.currentValue,
      home: MyWidget(),
    ),
  );

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget_${variants.currentValue}.png'),
  );
}, variant: variants);
```

## Testing Navigation

```dart
testWidgets('navigates to detail page', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ListPage(),
      routes: {
        '/detail': (_) => DetailPage(),
      },
    ),
  );

  await tester.tap(find.text('Item 1'));
  await tester.pumpAndSettle();

  expect(find.byType(DetailPage), findsOneWidget);
});

testWidgets('pops back', (tester) async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: ListPage(),
    ),
  );

  // Navigate forward
  navigatorKey.currentState!.push(
    MaterialPageRoute(builder: (_) => DetailPage()),
  );
  await tester.pumpAndSettle();

  // Pop back
  navigatorKey.currentState!.pop();
  await tester.pumpAndSettle();

  expect(find.byType(ListPage), findsOneWidget);
});
```

## Testing Dialogs/BottomSheets

```dart
testWidgets('shows dialog', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyPage()));

  await tester.tap(find.text('Show Dialog'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Dialog Title'), findsOneWidget);

  // Dismiss
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsNothing);
});

testWidgets('shows bottom sheet', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyPage()));

  await tester.tap(find.text('Show Sheet'));
  await tester.pumpAndSettle();

  expect(find.byType(BottomSheet), findsOneWidget);

  // Dismiss by dragging
  await tester.drag(find.byType(BottomSheet), Offset(0, 300));
  await tester.pumpAndSettle();

  expect(find.byType(BottomSheet), findsNothing);
});
```

## Test Helpers

```dart
// test/helpers/pump_helpers.dart
extension PumpHelpers on WidgetTester {
  Future<void> pumpApp(Widget child, {
    ThemeData? theme,
    Locale? locale,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(),
        locale: locale,
        home: child,
      ),
    );
  }

  Future<void> pumpRouted(Widget child, {
    Map<String, WidgetBuilder>? routes,
  }) async {
    await pumpWidget(
      MaterialApp(
        home: child,
        routes: routes ?? {},
      ),
    );
  }
}

// Usage
testWidgets('uses helper', (tester) async {
  await tester.pumpApp(MyWidget());
});
```
