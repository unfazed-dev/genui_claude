# Flutter/Dart Package Specifications

Domain-specific guidance for specifying Flutter and Dart packages.

## Package Type Decision Matrix

| Question | Pure Dart | Flutter Package | Flutter Plugin | FFI Plugin |
|----------|-----------|-----------------|----------------|------------|
| Uses Flutter widgets? | No | Yes | Maybe | No |
| Needs platform APIs? | No | No | Yes | Yes (native) |
| UI components? | No | Yes | Optional | No |
| Native code (Java/Kotlin/Swift/ObjC)? | No | No | Yes | C/C++/Rust |
| Web only JavaScript interop? | No | No | Yes (web) | No |

## Package Type Specifications

### Pure Dart Package

**pubspec.yaml Requirements**:
```yaml
name: package_name
description: >-
  A concise description that fits on one line on pub.dev.
version: 1.0.0
repository: https://github.com/org/package_name

environment:
  sdk: ^3.0.0

dependencies:
  # Only Dart packages, no flutter: sdk

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
```

**Spec Sections Required**:
- Package Overview
- Requirements with acceptance criteria
- Public API Contract
- Testing Requirements (unit tests only)
- Implementation Tasks

**Testing Strategy**:
| Test Type | Required | Coverage Target |
|-----------|----------|-----------------|
| Unit Tests | Yes | 80%+ |
| Integration Tests | If external I/O | Key flows |

---

### Flutter Package (Widget Library)

**pubspec.yaml Requirements**:
```yaml
name: package_name
description: >-
  Flutter widgets for {purpose}.
version: 1.0.0
repository: https://github.com/org/package_name

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
```

**Spec Sections Required**:
- Package Overview
- Requirements with UI mockups/descriptions
- Widget API Contract (props, callbacks, theming)
- Theme Extension specifications
- Testing Requirements (unit + widget tests)
- Golden test specifications
- Example app requirements

**Additional Spec Elements**:

```markdown
## Widget Specifications

### {WidgetName}

**Visual Behavior**:
- Default appearance: {description}
- Hover state: {description}
- Pressed state: {description}
- Disabled state: {description}

**Customization Points**:
| Property | Type | Default | Themeable |
|----------|------|---------|-----------|
| color | Color? | Theme primary | Yes |
| padding | EdgeInsets? | EdgeInsets.all(8) | Yes |

**Accessibility**:
- Semantic label: {description}
- Touch target: minimum 48x48
- Focus handling: {description}

**Theme Extension**:
```dart
class PackageTheme extends ThemeExtension<PackageTheme> {
  final Color primaryColor;
  final TextStyle labelStyle;
  // ...
}
```

**Testing Strategy**:
| Test Type | Required | Coverage Target |
|-----------|----------|-----------------|
| Unit Tests | Yes | 80%+ |
| Widget Tests | Yes | All widgets |
| Golden Tests | Recommended | Key states |
| Integration | If navigation | Key flows |

---

### Flutter Plugin

**pubspec.yaml Requirements**:
```yaml
name: package_name
description: >-
  Flutter plugin for {platform feature}.
version: 1.0.0
repository: https://github.com/org/package_name

environment:
  sdk: ^3.0.0
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  plugin:
    platforms:
      android:
        package: com.example.package_name
        pluginClass: PackageNamePlugin
      ios:
        pluginClass: PackageNamePlugin
```

**Spec Sections Required**:
- Package Overview
- Platform Requirements (min SDK versions)
- Platform Interface Contract
- Method Channel specifications
- Native API mapping
- Error code specifications
- Platform-specific behaviors
- Testing Requirements (all levels)

**Additional Spec Elements**:

```markdown
## Platform Interface Contract

### Methods

| Method | Dart Signature | Android | iOS |
|--------|----------------|---------|-----|
| getVersion | `Future<String>` | `Build.VERSION` | `UIDevice.current.systemVersion` |
| doAction | `Future<void>` | `doAction()` | `doAction()` |

### Event Channels

| Channel | Event Type | Description |
|---------|------------|-------------|
| `com.example/events` | `Map<String, dynamic>` | {description} |

### Error Codes

| Code | Platform | Meaning | Recovery |
|------|----------|---------|----------|
| `E001` | Both | {error} | {action} |
| `E002` | Android | {error} | {action} |

## Platform-Specific Requirements

### Android

**Minimum SDK**: {version}
**Permissions Required**:
```xml
<uses-permission android:name="android.permission.{PERMISSION}" />
```

**Gradle Dependencies**:
```groovy
implementation 'com.example:library:1.0.0'
```

### iOS

**Minimum iOS**: {version}
**Info.plist Keys**:
```xml
<key>NSCameraUsageDescription</key>
<string>{description}</string>
```

**CocoaPods Dependencies**:
```ruby
s.dependency 'SomeLibrary', '~> 1.0'
```
```

**Testing Strategy**:
| Test Type | Required | Notes |
|-----------|----------|-------|
| Unit Tests | Yes | Dart logic |
| Platform Tests | Yes | Mock method channels |
| Integration Tests | Yes | Real device/emulator |
| E2E Tests | Recommended | Full flow on device |

---

### FFI Plugin

**pubspec.yaml Requirements**:
```yaml
name: package_name
description: >-
  Dart FFI bindings for {native library}.
version: 1.0.0
repository: https://github.com/org/package_name

environment:
  sdk: ^3.0.0
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.0.0

dev_dependencies:
  ffigen: ^9.0.0
  flutter_test:
    sdk: flutter

flutter:
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true
```

**Spec Sections Required**:
- Package Overview
- Native Library requirements
- FFI bindings specification
- Memory management contracts
- Platform build requirements
- Testing Requirements

**Additional Spec Elements**:

```markdown
## Native Library Specification

**Library**: {name}
**Version**: {version}
**Source**: {URL or bundled}

### Functions to Bind

| C Function | Dart Binding | Memory |
|------------|--------------|--------|
| `void* create()` | `Pointer<Void> create()` | Caller owns |
| `void destroy(void*)` | `void destroy(Pointer<Void>)` | Frees pointer |
| `int process(char*)` | `int process(Pointer<Utf8>)` | Input copied |

### Struct Definitions

```c
// C struct
typedef struct {
    int32_t id;
    char* name;
} MyStruct;
```

```dart
// Dart binding
final class MyStruct extends Struct {
  @Int32()
  external int id;

  external Pointer<Utf8> name;
}
```

### Memory Management Rules

| Allocation | Ownership | Cleanup |
|------------|-----------|---------|
| `create()` | Caller | Must call `destroy()` |
| `getString()` | Library | Do not free |
| Struct fields | Varies | See documentation |
```

---

## pubspec.yaml Checklist

| Field | Required | pub.dev Impact |
|-------|----------|----------------|
| name | Yes | Package identifier |
| description | Yes | Search, listing |
| version | Yes | Versioning |
| repository | Recommended | Links to source |
| homepage | Optional | Alternative to repository |
| documentation | Optional | Links to docs |
| issue_tracker | Optional | Links to issues |
| topics | Recommended | Discovery (max 5) |
| screenshots | Optional | Visual preview |
| funding | Optional | Sponsor links |

## Export Strategy Specification

### Barrel File Pattern

```dart
// lib/package_name.dart
library package_name;

export 'src/models/user.dart';
export 'src/services/auth.dart' show AuthService;
export 'src/widgets/button.dart';
export 'src/exceptions.dart';
```

### Multi-Library Pattern

```dart
// lib/package_name.dart (core)
export 'src/core/...';

// lib/package_name_testing.dart (test utilities)
export 'src/testing/...';

// lib/package_name_widgets.dart (UI components)
export 'src/widgets/...';
```

### Export Rules for Specs

| Export Type | When to Use |
|-------------|-------------|
| Full export | Public API classes |
| `show` | Expose subset of file |
| `hide` | Expose all except specific |
| No export | Internal implementation |

---

## Testing Requirements by Package Type

### Dart Package

```yaml
dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0  # or mockito
```

### Flutter Package

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  golden_toolkit: ^0.15.0  # optional
```

### Flutter Plugin

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  plugin_platform_interface: ^2.0.0
  integration_test:
    sdk: flutter
```

## Example App/Script Specifications

### Dart Package Example

```markdown
## Example Requirements

**File**: `example/example.dart`

**Must Demonstrate**:
1. Basic usage (minimum viable)
2. Configuration options
3. Error handling

**Runnable**: `dart run example/example.dart`
```

### Flutter Package Example

```markdown
## Example App Requirements

**Location**: `example/`

**Must Demonstrate**:
1. All exported widgets
2. Theme customization
3. Common use cases

**Structure**:
```
example/
├── lib/
│   ├── main.dart
│   └── pages/
│       ├── basic_usage_page.dart
│       └── advanced_page.dart
└── pubspec.yaml
```
```
