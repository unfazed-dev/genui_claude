---
name: flutter-package
description: Flutter package development toolkit with widget libraries, platform channels, and plugin architecture. Use when creating Flutter packages, writing widget tests, implementing platform-specific code, or building plugins.
---

# Flutter Package Development

## Quick Start

```bash
# Create Flutter package (widgets only)
flutter create --template=package my_widgets

# Create Flutter plugin (with platform code)
flutter create --template=plugin --platforms=android,ios my_plugin

# Create FFI plugin (native code via dart:ffi)
flutter create --template=plugin_ffi my_ffi_plugin
```

## Package Types

### Pure Dart Package
```
my_package/
├── lib/
│   └── my_package.dart
├── test/
└── pubspec.yaml
```
Use for: Utilities, models, business logic (no Flutter dependency)

### Flutter Package
```
my_widgets/
├── lib/
│   └── my_widgets.dart
├── test/
├── example/
└── pubspec.yaml
```
Use for: Widgets, themes, Flutter-specific utilities

### Flutter Plugin
```
my_plugin/
├── lib/
│   └── my_plugin.dart
├── android/
├── ios/
├── test/
├── example/
└── pubspec.yaml
```
Use for: Platform-specific functionality (camera, sensors, etc.)

## Flutter Package Structure

```
my_widgets/
├── lib/
│   ├── my_widgets.dart           # Main export
│   └── src/
│       ├── widgets/
│       │   ├── custom_button.dart
│       │   └── loading_indicator.dart
│       ├── themes/
│       │   └── app_theme.dart
│       └── utils/
│           └── responsive.dart
├── test/
│   ├── widgets/
│   │   └── custom_button_test.dart
│   └── test_utils.dart
├── example/
│   └── lib/
│       └── main.dart
├── pubspec.yaml
└── analysis_options.yaml
```

## pubspec.yaml (Flutter Package)

```yaml
name: my_widgets
description: A collection of custom Flutter widgets.
version: 1.0.0
repository: https://github.com/username/my_widgets

environment:
  sdk: ^3.0.0
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  # Assets bundled with package
  assets:
    - assets/icons/
```

## Widget Library Patterns

### Exporting Widgets

```dart
// lib/my_widgets.dart
library my_widgets;

// Widgets
export 'src/widgets/custom_button.dart';
export 'src/widgets/loading_indicator.dart';
export 'src/widgets/avatar.dart';

// Themes
export 'src/themes/app_theme.dart';
export 'src/themes/colors.dart';

// Utils
export 'src/utils/responsive.dart' show ResponsiveBreakpoints;
```

### Customizable Widget Pattern

```dart
/// A customizable button with loading state.
class CustomButton extends StatelessWidget {
  /// Creates a custom button.
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
    this.loadingIndicator,
  });

  /// Called when button is pressed. Null disables the button.
  final VoidCallback? onPressed;

  /// Button content.
  final Widget child;

  /// Shows loading indicator when true.
  final bool isLoading;

  /// Custom button style. Uses theme default if null.
  final ButtonStyle? style;

  /// Custom loading indicator. Uses default if null.
  final Widget? loadingIndicator;

  /// Creates a primary styled button.
  factory CustomButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    bool isLoading = false,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      isLoading: isLoading,
      style: _primaryStyle,
      child: child,
    );
  }

  static final _primaryStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Colors.blue),
  );

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? loadingIndicator ?? const _DefaultLoadingIndicator()
          : child,
    );
  }
}
```

### Theme Extension Pattern

```dart
/// Custom theme extension for package widgets.
@immutable
class MyWidgetsTheme extends ThemeExtension<MyWidgetsTheme> {
  const MyWidgetsTheme({
    required this.primaryButtonColor,
    required this.secondaryButtonColor,
    required this.loadingIndicatorColor,
  });

  final Color primaryButtonColor;
  final Color secondaryButtonColor;
  final Color loadingIndicatorColor;

  /// Light theme defaults.
  static const light = MyWidgetsTheme(
    primaryButtonColor: Colors.blue,
    secondaryButtonColor: Colors.grey,
    loadingIndicatorColor: Colors.blue,
  );

  /// Dark theme defaults.
  static const dark = MyWidgetsTheme(
    primaryButtonColor: Colors.lightBlue,
    secondaryButtonColor: Colors.grey,
    loadingIndicatorColor: Colors.lightBlue,
  );

  @override
  MyWidgetsTheme copyWith({
    Color? primaryButtonColor,
    Color? secondaryButtonColor,
    Color? loadingIndicatorColor,
  }) {
    return MyWidgetsTheme(
      primaryButtonColor: primaryButtonColor ?? this.primaryButtonColor,
      secondaryButtonColor: secondaryButtonColor ?? this.secondaryButtonColor,
      loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
    );
  }

  @override
  MyWidgetsTheme lerp(MyWidgetsTheme? other, double t) {
    if (other is! MyWidgetsTheme) return this;
    return MyWidgetsTheme(
      primaryButtonColor: Color.lerp(primaryButtonColor, other.primaryButtonColor, t)!,
      secondaryButtonColor: Color.lerp(secondaryButtonColor, other.secondaryButtonColor, t)!,
      loadingIndicatorColor: Color.lerp(loadingIndicatorColor, other.loadingIndicatorColor, t)!,
    );
  }
}

// Usage in app
MaterialApp(
  theme: ThemeData.light().copyWith(
    extensions: [MyWidgetsTheme.light],
  ),
);

// Access in widgets
final theme = Theme.of(context).extension<MyWidgetsTheme>()!;
```

## Widget Testing

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_widgets/my_widgets.dart';

void main() {
  group('CustomButton', () {
    testWidgets('displays child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomButton(
            onPressed: () {},
            child: Text('Click Me'),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomButton(
            onPressed: () => pressed = true,
            child: Text('Click'),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomButton(
            onPressed: () {},
            isLoading: true,
            child: Text('Submit'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('disables button when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomButton(
            onPressed: null,
            child: Text('Disabled'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```

### Testing with Theme

```dart
testWidgets('uses theme extension colors', (tester) async {
  const customTheme = MyWidgetsTheme(
    primaryButtonColor: Colors.red,
    secondaryButtonColor: Colors.green,
    loadingIndicatorColor: Colors.yellow,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: [customTheme],
      ),
      home: CustomButton.primary(
        onPressed: () {},
        child: Text('Themed'),
      ),
    ),
  );

  // Verify theme is applied
  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  // Assert button style uses theme colors
});
```

### Golden Tests

```dart
testWidgets('matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: CustomButton(
            onPressed: () {},
            child: Text('Golden Test'),
          ),
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(CustomButton),
    matchesGoldenFile('goldens/custom_button.png'),
  );
});

// Update goldens: flutter test --update-goldens
```

### Testing Animations

```dart
testWidgets('animates on state change', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AnimatedWidget(expanded: false),
    ),
  );

  // Initial state
  expect(find.byType(Container), findsOneWidget);

  // Trigger animation
  await tester.tap(find.byType(AnimatedWidget));

  // Advance animation
  await tester.pump(Duration(milliseconds: 100));
  // ... animation in progress

  // Complete animation
  await tester.pumpAndSettle();
  // ... animation complete
});
```

## Platform Channels

### Method Channel (Dart Side)

```dart
// lib/src/my_plugin_platform_interface.dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class MyPluginPlatform extends PlatformInterface {
  MyPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static MyPluginPlatform _instance = MethodChannelMyPlugin();

  static MyPluginPlatform get instance => _instance;

  static set instance(MyPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion();
  Future<void> doSomething(String input);
  Stream<int> get dataStream;
}
```

```dart
// lib/src/my_plugin_method_channel.dart
import 'package:flutter/services.dart';

class MethodChannelMyPlugin extends MyPluginPlatform {
  static const _channel = MethodChannel('com.example.my_plugin');
  static const _eventChannel = EventChannel('com.example.my_plugin/events');

  @override
  Future<String?> getPlatformVersion() async {
    return await _channel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<void> doSomething(String input) async {
    await _channel.invokeMethod('doSomething', {'input': input});
  }

  @override
  Stream<int> get dataStream {
    return _eventChannel.receiveBroadcastStream().map((event) => event as int);
  }
}
```

```dart
// lib/my_plugin.dart
class MyPlugin {
  Future<String?> getPlatformVersion() {
    return MyPluginPlatform.instance.getPlatformVersion();
  }

  Future<void> doSomething(String input) {
    return MyPluginPlatform.instance.doSomething(input);
  }

  Stream<int> get dataStream => MyPluginPlatform.instance.dataStream;
}
```

### Android Implementation (Kotlin)

```kotlin
// android/src/main/kotlin/com/example/my_plugin/MyPlugin.kt
package com.example.my_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MyPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.my_plugin")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.example.my_plugin/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "doSomething" -> {
                val input = call.argument<String>("input")
                // Process input
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Start emitting events
        eventSink?.success(42)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
```

### iOS Implementation (Swift)

```swift
// ios/Classes/MyPlugin.swift
import Flutter

public class MyPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.my_plugin",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.example.my_plugin/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = MyPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "doSomething":
            if let args = call.arguments as? [String: Any],
               let input = args["input"] as? String {
                // Process input
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Start emitting events
        events(42)
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
```

### Testing Platform Channels

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_plugin/my_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MyPlugin', () {
    const channel = MethodChannel('com.example.my_plugin');
    late MyPlugin plugin;

    setUp(() {
      plugin = MyPlugin();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'getPlatformVersion':
            return 'Test Platform 1.0';
          case 'doSomething':
            return null;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getPlatformVersion returns version', () async {
      expect(await plugin.getPlatformVersion(), 'Test Platform 1.0');
    });

    test('doSomething completes', () async {
      await expectLater(plugin.doSomething('test'), completes);
    });
  });
}
```

## Federated Plugins

```
my_plugin/                      # App-facing package
├── lib/
│   └── my_plugin.dart
└── pubspec.yaml

my_plugin_platform_interface/   # Platform interface
├── lib/
│   └── my_plugin_platform_interface.dart
└── pubspec.yaml

my_plugin_android/              # Android implementation
├── android/
├── lib/
│   └── my_plugin_android.dart
└── pubspec.yaml

my_plugin_ios/                  # iOS implementation
├── ios/
├── lib/
│   └── my_plugin_ios.dart
└── pubspec.yaml

my_plugin_web/                  # Web implementation
├── lib/
│   └── my_plugin_web.dart
└── pubspec.yaml
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `MissingPluginException` | Ensure plugin registered in native code |
| Method not found | Check channel name matches exactly |
| Type cast error | Verify argument types match on both sides |
| Event channel not receiving | Check stream handler is set |
| iOS build fails | Run `pod install` in ios/ directory |
| Android build fails | Check minSdkVersion compatibility |

## Resources

- **Platform Channels**: See [references/platform-channels.md](references/platform-channels.md)
- **Widget Testing**: See [references/widget-testing.md](references/widget-testing.md)
