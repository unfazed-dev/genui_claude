---
name: dart-package
description: Pure Dart package development toolkit with project structure, testing patterns, and pub.dev publishing workflow. Use when creating packages, writing library code, preparing releases, or publishing to pub.dev.
---

# Dart Package Development

## Quick Start

```bash
# Create new package
dart create -t package my_package
cd my_package

# Run tests
dart test

# Analyze code
dart analyze

# Format code
dart format .

# Check publish readiness
dart pub publish --dry-run
```

## Package Structure

```
my_package/
├── lib/
│   ├── my_package.dart          # Main library export
│   └── src/                     # Private implementation
│       ├── models/
│       ├── utils/
│       └── core.dart
├── test/
│   ├── my_package_test.dart
│   └── src/
├── example/
│   └── example.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
└── analysis_options.yaml
```

## pubspec.yaml

```yaml
name: my_package
description: A concise description of what the package does.
version: 1.0.0
repository: https://github.com/username/my_package
issue_tracker: https://github.com/username/my_package/issues
documentation: https://pub.dev/documentation/my_package/latest/

environment:
  sdk: ^3.0.0

dependencies:
  meta: ^1.9.0

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
  coverage: ^1.6.0

# For platform-specific packages
platforms:
  android:
  ios:
  linux:
  macos:
  web:
  windows:

# Topics for pub.dev discovery (max 5)
topics:
  - utilities
  - data-structures

# Screenshots for pub.dev
screenshots:
  - description: Main feature showcase
    path: doc/screenshots/feature.png

# Funding links
funding:
  - https://github.com/sponsors/username
```

## Library Exports

### Main Export File (lib/my_package.dart)

```dart
/// A brief description of the package.
///
/// More detailed explanation of what this package provides
/// and how to use it.
library my_package;

// Public API exports
export 'src/models/user.dart';
export 'src/models/config.dart' show Config, ConfigBuilder;
export 'src/utils/helpers.dart' hide internalHelper;
export 'src/core.dart';

// Re-export commonly used types from dependencies
export 'package:meta/meta.dart' show required, visibleForTesting;
```

### Part Files (for large single-library packages)

```dart
// lib/my_package.dart
library my_package;

part 'src/models.dart';
part 'src/utils.dart';

// lib/src/models.dart
part of '../my_package.dart';

class User { ... }
```

## API Design

### Public vs Private

```dart
// Public API - exported from lib/my_package.dart
class PublicClass {
  final String name;

  PublicClass(this.name);

  /// Public method with documentation.
  void doSomething() => _internalMethod();

  // Private to this class
  void _internalMethod() {}
}

// Package-private - in lib/src/, not exported
class InternalHelper {
  static String process(String input) => input.trim();
}
```

### Annotations

```dart
import 'package:meta/meta.dart';

class MyClass {
  /// Internal API, may change without notice.
  @internal
  void internalMethod() {}

  /// Visible only for testing purposes.
  @visibleForTesting
  void testableMethod() {}

  /// This will be removed in v2.0.
  @Deprecated('Use newMethod() instead')
  void oldMethod() {}

  /// Must be overridden by subclasses.
  @mustBeOverridden
  void templateMethod() {}

  /// Subclasses must call super.
  @mustCallSuper
  void lifecycleMethod() {}

  /// Return value must be used.
  @useResult
  int compute() => 42;
}
```

### Immutable Classes

```dart
import 'package:meta/meta.dart';

@immutable
class Config {
  final String apiKey;
  final int timeout;
  final bool debug;

  const Config({
    required this.apiKey,
    this.timeout = 30,
    this.debug = false,
  });

  Config copyWith({
    String? apiKey,
    int? timeout,
    bool? debug,
  }) {
    return Config(
      apiKey: apiKey ?? this.apiKey,
      timeout: timeout ?? this.timeout,
      debug: debug ?? this.debug,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Config &&
          apiKey == other.apiKey &&
          timeout == other.timeout &&
          debug == other.debug;

  @override
  int get hashCode => Object.hash(apiKey, timeout, debug);
}
```

## Documentation

### Class Documentation

```dart
/// A service for managing user authentication.
///
/// This class handles login, logout, and token refresh operations.
///
/// ## Usage
///
/// ```dart
/// final auth = AuthService(apiClient: client);
/// await auth.login('user@example.com', 'password');
/// ```
///
/// ## Error Handling
///
/// Methods throw [AuthException] on authentication failures.
///
/// See also:
/// - [User] for user data model
/// - [TokenManager] for token storage
class AuthService {
  /// Creates an authentication service.
  ///
  /// The [apiClient] is used for all network requests.
  /// Set [enableLogging] to true for debug output.
  AuthService({
    required ApiClient apiClient,
    bool enableLogging = false,
  });

  /// Authenticates a user with email and password.
  ///
  /// Returns the authenticated [User] on success.
  ///
  /// Throws:
  /// - [InvalidCredentialsException] if credentials are wrong
  /// - [NetworkException] if the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await auth.login('email', 'pass');
  ///   print('Welcome ${user.name}');
  /// } on InvalidCredentialsException {
  ///   print('Wrong password');
  /// }
  /// ```
  Future<User> login(String email, String password);
}
```

## Testing

### Test Structure

```dart
// test/my_package_test.dart
import 'package:test/test.dart';
import 'package:my_package/my_package.dart';

void main() {
  group('Calculator', () {
    late Calculator calc;

    setUp(() {
      calc = Calculator();
    });

    test('adds two numbers', () {
      expect(calc.add(2, 3), equals(5));
    });

    test('throws on division by zero', () {
      expect(() => calc.divide(10, 0), throwsArgumentError);
    });
  });

  group('Parser', () {
    test('parses valid JSON', () {
      final result = Parser.parse('{"key": "value"}');
      expect(result['key'], 'value');
    });

    test('returns null for invalid JSON', () {
      expect(Parser.parse('invalid'), isNull);
    });
  });
}
```

### Test Coverage

```bash
# Run tests with coverage
dart test --coverage=coverage

# Generate HTML report (requires coverage package)
dart pub global activate coverage
dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib

# Generate HTML (requires genhtml from lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Testing Private Code

```dart
// lib/src/internal.dart
@visibleForTesting
class InternalProcessor {
  String process(String input) => input.toUpperCase();
}

// test/src/internal_test.dart
import 'package:my_package/src/internal.dart';
import 'package:test/test.dart';

void main() {
  test('internal processor works', () {
    final processor = InternalProcessor();
    expect(processor.process('hello'), 'HELLO');
  });
}
```

## analysis_options.yaml

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_dynamic_calls
    - avoid_print
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - prefer_final_locals
    - prefer_single_quotes
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_await_in_return
    - unnecessary_statements
    - use_string_buffers
```

## Publishing Workflow

### Pre-publish Checklist

```bash
# 1. Update version in pubspec.yaml
# 2. Update CHANGELOG.md

# 3. Run all checks
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart doc .  # Generate docs, check for warnings

# 4. Verify publish readiness
dart pub publish --dry-run
```

### CHANGELOG.md Format

```markdown
# Changelog

## [1.2.0] - 2024-01-15

### Added
- New `Parser.tryParse()` method for safe parsing
- Support for custom date formats

### Changed
- `Config` class is now immutable
- Minimum SDK version is now 3.0.0

### Deprecated
- `Parser.parse()` - use `Parser.tryParse()` instead

### Removed
- `LegacyHelper` class (deprecated in 1.0.0)

### Fixed
- Memory leak in `StreamProcessor`
- Incorrect timezone handling in `DateUtils`

## [1.1.0] - 2024-01-01

### Added
- Initial stable release
```

### Semantic Versioning

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fix (backward compatible) | PATCH | 1.0.0 → 1.0.1 |
| New feature (backward compatible) | MINOR | 1.0.0 → 1.1.0 |
| Breaking change | MAJOR | 1.0.0 → 2.0.0 |
| Pre-release | Suffix | 1.0.0-beta.1 |

### Publish to pub.dev

```bash
# Login (first time)
dart pub login

# Publish
dart pub publish

# For packages with breaking changes
dart pub publish --force  # Skip confirmation
```

## README Template

```markdown
# my_package

[![pub package](https://img.shields.io/pub/v/my_package.svg)](https://pub.dev/packages/my_package)
[![build](https://github.com/user/my_package/actions/workflows/ci.yml/badge.svg)](https://github.com/user/my_package/actions)
[![coverage](https://codecov.io/gh/user/my_package/branch/main/graph/badge.svg)](https://codecov.io/gh/user/my_package)

A brief, compelling description of what this package does.

## Features

- Feature one
- Feature two
- Feature three

## Getting Started

```yaml
dependencies:
  my_package: ^1.0.0
```

## Usage

```dart
import 'package:my_package/my_package.dart';

void main() {
  final result = MyClass().doSomething();
  print(result);
}
```

## Additional Information

- [API Documentation](https://pub.dev/documentation/my_package/latest/)
- [GitHub Repository](https://github.com/user/my_package)
- [Issue Tracker](https://github.com/user/my_package/issues)
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `pub publish` fails validation | Run `dart pub publish --dry-run` for details |
| Missing documentation | Add `///` comments to all public APIs |
| Example not found | Create `example/example.dart` |
| SDK constraint too loose | Use `sdk: ^3.0.0` format |
| Large package size | Add files to `.pubignore` |

## Resources

- **Publishing Checklist**: See [references/publishing-checklist.md](references/publishing-checklist.md)
- **API Design Guide**: See [references/api-design.md](references/api-design.md)
