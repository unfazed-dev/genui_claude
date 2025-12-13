# Platform Channels Reference

## Channel Types

| Type | Use Case | Direction |
|------|----------|-----------|
| MethodChannel | Request/response calls | Dart ↔ Native |
| EventChannel | Continuous data streams | Native → Dart |
| BasicMessageChannel | Simple messages | Dart ↔ Native |

## Data Type Mapping

### Dart ↔ Android (Kotlin/Java)

| Dart | Kotlin | Java |
|------|--------|------|
| null | null | null |
| bool | Boolean | java.lang.Boolean |
| int | Int/Long | java.lang.Integer/Long |
| double | Double | java.lang.Double |
| String | String | java.lang.String |
| Uint8List | ByteArray | byte[] |
| Int32List | IntArray | int[] |
| Int64List | LongArray | long[] |
| Float64List | DoubleArray | double[] |
| List | List | java.util.ArrayList |
| Map | HashMap | java.util.HashMap |

### Dart ↔ iOS (Swift/ObjC)

| Dart | Swift | Objective-C |
|------|-------|-------------|
| null | nil | NSNull |
| bool | Bool | NSNumber(boolValue:) |
| int | Int | NSNumber(intValue:) |
| double | Double | NSNumber(doubleValue:) |
| String | String | NSString |
| Uint8List | FlutterStandardTypedData | FlutterStandardTypedData |
| Int32List | FlutterStandardTypedData | FlutterStandardTypedData |
| Int64List | FlutterStandardTypedData | FlutterStandardTypedData |
| Float64List | FlutterStandardTypedData | FlutterStandardTypedData |
| List | Array | NSArray |
| Map | Dictionary | NSDictionary |

## MethodChannel Patterns

### Basic Call

```dart
// Dart
final channel = MethodChannel('com.example.plugin');
final result = await channel.invokeMethod<String>('methodName', {
  'arg1': 'value1',
  'arg2': 42,
});
```

```kotlin
// Kotlin
override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "methodName" -> {
            val arg1 = call.argument<String>("arg1")
            val arg2 = call.argument<Int>("arg2")
            result.success("response")
        }
        else -> result.notImplemented()
    }
}
```

```swift
// Swift
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "methodName":
        if let args = call.arguments as? [String: Any] {
            let arg1 = args["arg1"] as? String
            let arg2 = args["arg2"] as? Int
            result("response")
        }
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

### Error Handling

```dart
// Dart - catching errors
try {
  await channel.invokeMethod('riskyMethod');
} on PlatformException catch (e) {
  print('Error: ${e.code} - ${e.message}');
  print('Details: ${e.details}');
}
```

```kotlin
// Kotlin - sending errors
result.error("ERROR_CODE", "Error message", "Additional details")
```

```swift
// Swift - sending errors
result(FlutterError(code: "ERROR_CODE", message: "Error message", details: "Additional details"))
```

### Async Native Operations

```kotlin
// Kotlin - coroutines
import kotlinx.coroutines.*

class MyPlugin: FlutterPlugin, MethodCallHandler {
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "asyncOperation" -> {
                scope.launch {
                    try {
                        val data = withContext(Dispatchers.IO) {
                            // Long-running operation
                            performAsyncWork()
                        }
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        scope.cancel()
    }
}
```

```swift
// Swift - async/await (iOS 13+)
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "asyncOperation":
        Task {
            do {
                let data = try await performAsyncWork()
                result(data)
            } catch {
                result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
            }
        }
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

## EventChannel Patterns

### Continuous Updates

```dart
// Dart
final eventChannel = EventChannel('com.example.plugin/events');

Stream<SensorData> get sensorUpdates {
  return eventChannel.receiveBroadcastStream().map((event) {
    final map = event as Map<Object?, Object?>;
    return SensorData(
      x: map['x'] as double,
      y: map['y'] as double,
      z: map['z'] as double,
    );
  });
}
```

```kotlin
// Kotlin
class SensorStreamHandler: EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var sensorManager: SensorManager? = null
    private val sensorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            eventSink?.success(mapOf(
                "x" to event.values[0].toDouble(),
                "y" to event.values[1].toDouble(),
                "z" to event.values[2].toDouble()
            ))
        }
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Start sensor updates
        sensorManager?.registerListener(sensorListener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(sensorListener)
        eventSink = null
    }
}
```

```swift
// Swift
class SensorStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var motionManager: CMMotionManager?

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            if let data = data {
                self?.eventSink?([
                    "x": data.acceleration.x,
                    "y": data.acceleration.y,
                    "z": data.acceleration.z
                ])
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager?.stopAccelerometerUpdates()
        eventSink = nil
        return nil
    }
}
```

### Error Events

```kotlin
// Kotlin
eventSink?.error("SENSOR_ERROR", "Sensor unavailable", null)
```

```swift
// Swift
eventSink?(FlutterError(code: "SENSOR_ERROR", message: "Sensor unavailable", details: nil))
```

### End of Stream

```kotlin
// Kotlin
eventSink?.endOfStream()
```

```swift
// Swift
eventSink?(FlutterEndOfEventStream)
```

## BasicMessageChannel Patterns

### JSON Messages

```dart
// Dart
final channel = BasicMessageChannel<String>(
  'com.example.plugin/json',
  StringCodec(),
);

// Send
await channel.send(jsonEncode({'type': 'request', 'data': 'value'}));

// Receive
channel.setMessageHandler((message) async {
  final data = jsonDecode(message!);
  return jsonEncode({'type': 'response', 'result': 'ok'});
});
```

### Binary Messages

```dart
// Dart
final channel = BasicMessageChannel<ByteData>(
  'com.example.plugin/binary',
  BinaryCodec(),
);

// Send binary data
final buffer = Uint8List(1024);
await channel.send(buffer.buffer.asByteData());
```

## Pigeon (Type-Safe Code Generation)

### Define API

```dart
// pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

class SensorData {
  double? x;
  double? y;
  double? z;
}

@HostApi()
abstract class SensorApi {
  @async
  SensorData getLatestReading();
  void startUpdates();
  void stopUpdates();
}

@FlutterApi()
abstract class SensorCallbacks {
  void onSensorUpdate(SensorData data);
  void onError(String message);
}
```

### Generate Code

```bash
dart run pigeon \
  --input pigeons/messages.dart \
  --dart_out lib/src/sensor_api.g.dart \
  --kotlin_out android/src/main/kotlin/com/example/SensorApi.kt \
  --swift_out ios/Classes/SensorApi.swift
```

### pubspec.yaml

```yaml
dev_dependencies:
  pigeon: ^11.0.0
```

## Background Isolates

### Dart Side

```dart
// For heavy computation, use background isolate
@pragma('vm:entry-point')
void backgroundCallback() {
  // Initialize in background
  WidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.example.plugin/background',
    StandardMethodCodec(),
  );

  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'process':
        return heavyComputation(call.arguments);
      default:
        throw MissingPluginException();
    }
  });
}
```

## Platform-Specific Behavior

### Check Platform

```dart
import 'dart:io' show Platform;

Future<void> doPlatformSpecific() async {
  if (Platform.isAndroid) {
    await channel.invokeMethod('androidSpecific');
  } else if (Platform.isIOS) {
    await channel.invokeMethod('iosSpecific');
  }
}
```

### Feature Detection

```dart
Future<bool> isFeatureSupported() async {
  try {
    return await channel.invokeMethod<bool>('isSupported') ?? false;
  } on MissingPluginException {
    return false;
  }
}
```

## Debugging

### Dart

```dart
// Enable verbose logging
debugPrint('Calling native method...');
```

### Android (Logcat)

```kotlin
import android.util.Log

Log.d("MyPlugin", "Method called: ${call.method}")
Log.e("MyPlugin", "Error occurred", exception)
```

### iOS (Console)

```swift
import os.log

let logger = Logger(subsystem: "com.example.plugin", category: "main")
logger.debug("Method called: \(call.method)")
logger.error("Error: \(error.localizedDescription)")
```

## Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| UI thread blocked | Long operation on main thread | Use async/background thread |
| Memory leak | EventSink not cleared | Set null in onCancel |
| Crash on result | Result called twice | Track result completion |
| Type mismatch | Wrong codec | Use StandardMethodCodec |
| Method not found | Channel name mismatch | Verify exact string match |
