# Dart Package API Design Guide

## Naming Conventions

### Package Names

```
# Good
my_package
json_parser
http_client

# Bad
myPackage      # No camelCase
my-package     # No hyphens
MyPackage      # No PascalCase
```

### Class Names

```dart
// Good - PascalCase, noun
class HttpClient {}
class UserRepository {}
class JsonParser {}

// Bad
class httpClient {}      // lowercase
class ParseJson {}       // verb phrase
class HTTPClient {}      // acronym should be Http
```

### Method Names

```dart
// Good - camelCase, verb phrase
void sendRequest() {}
Future<User> fetchUser() {}
bool isValid() {}
String toString() {}

// Bad
void SendRequest() {}    // PascalCase
void request() {}        // noun, unclear action
void send_request() {}   // snake_case
```

### Boolean Properties/Methods

```dart
// Good - question form
bool get isEmpty => _items.length == 0;
bool get hasError => _error != null;
bool isValid() => _validate();
bool canProceed() => _ready && !_busy;

// Bad
bool get empty => ...;        // Not a question
bool get error => ...;        // Noun, not bool-like
bool validate() => ...;       // Sounds like action
```

## API Patterns

### Factory Constructors

```dart
class Config {
  final String host;
  final int port;

  // Private constructor
  const Config._({required this.host, required this.port});

  // Named factories for common cases
  factory Config.development() => Config._(host: 'localhost', port: 8080);
  factory Config.production() => Config._(host: 'api.example.com', port: 443);

  // Factory from external data
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config._(
      host: json['host'] as String,
      port: json['port'] as int,
    );
  }

  // Factory with validation
  factory Config.parse(String url) {
    final uri = Uri.parse(url);
    if (uri.host.isEmpty) throw FormatException('Invalid URL: $url');
    return Config._(host: uri.host, port: uri.port);
  }
}
```

### Builder Pattern

```dart
class RequestBuilder {
  String? _method;
  String? _path;
  final Map<String, String> _headers = {};
  Object? _body;

  RequestBuilder method(String method) {
    _method = method;
    return this;
  }

  RequestBuilder path(String path) {
    _path = path;
    return this;
  }

  RequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  RequestBuilder body(Object body) {
    _body = body;
    return this;
  }

  Request build() {
    if (_method == null) throw StateError('Method is required');
    if (_path == null) throw StateError('Path is required');
    return Request(
      method: _method!,
      path: _path!,
      headers: Map.unmodifiable(_headers),
      body: _body,
    );
  }
}

// Usage
final request = RequestBuilder()
    .method('POST')
    .path('/users')
    .header('Content-Type', 'application/json')
    .body({'name': 'John'})
    .build();
```

### Extension Methods

```dart
// Add functionality to existing types
extension StringExtensions on String {
  /// Capitalizes the first letter.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns null if string is empty.
  String? get nullIfEmpty => isEmpty ? null : this;
}

extension ListExtensions<T> on List<T> {
  /// Returns element at index or null if out of bounds.
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Returns first element matching predicate or null.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
```

### Typedef for Callbacks

```dart
/// Callback for progress updates.
typedef ProgressCallback = void Function(int current, int total);

/// Predicate for filtering items.
typedef Predicate<T> = bool Function(T item);

/// Async data fetcher.
typedef AsyncFetcher<T> = Future<T> Function();

// Usage
class Downloader {
  Future<void> download(String url, {ProgressCallback? onProgress}) async {
    // ...
    onProgress?.call(bytesReceived, totalBytes);
  }
}
```

## Error Handling

### Custom Exceptions

```dart
/// Base exception for this package.
abstract class PackageException implements Exception {
  final String message;
  final Object? cause;

  const PackageException(this.message, [this.cause]);

  @override
  String toString() => 'PackageException: $message';
}

/// Thrown when parsing fails.
class ParseException extends PackageException {
  final String input;
  final int? position;

  const ParseException(super.message, {required this.input, this.position});

  @override
  String toString() {
    final pos = position != null ? ' at position $position' : '';
    return 'ParseException: $message$pos\nInput: $input';
  }
}

/// Thrown when validation fails.
class ValidationException extends PackageException {
  final List<String> errors;

  const ValidationException(this.errors) : super('Validation failed');

  @override
  String toString() => 'ValidationException:\n${errors.map((e) => '  - $e').join('\n')}';
}
```

### Result Type Pattern

```dart
/// A result that is either a success value or an error.
sealed class Result<T, E> {
  const Result();

  /// Creates a success result.
  const factory Result.success(T value) = Success<T, E>;

  /// Creates an error result.
  const factory Result.error(E error) = Error<T, E>;

  /// Returns true if this is a success.
  bool get isSuccess;

  /// Returns the value or throws if error.
  T get value;

  /// Returns the error or null if success.
  E? get error;

  /// Maps the success value.
  Result<U, E> map<U>(U Function(T) transform);

  /// Executes callback based on result type.
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) error,
  });
}

final class Success<T, E> extends Result<T, E> {
  final T _value;

  const Success(this._value);

  @override
  bool get isSuccess => true;

  @override
  T get value => _value;

  @override
  E? get error => null;

  @override
  Result<U, E> map<U>(U Function(T) transform) => Success(transform(_value));

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) error,
  }) => success(_value);
}

final class Error<T, E> extends Result<T, E> {
  final E _error;

  const Error(this._error);

  @override
  bool get isSuccess => false;

  @override
  T get value => throw StateError('Cannot get value from error result');

  @override
  E? get error => _error;

  @override
  Result<U, E> map<U>(U Function(T) transform) => Error(_error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) error,
  }) => error(_error);
}

// Usage
Result<User, String> fetchUser(String id) {
  try {
    return Result.success(User(id: id, name: 'John'));
  } catch (e) {
    return Result.error('Failed to fetch user: $e');
  }
}

final result = fetchUser('123');
result.when(
  success: (user) => print('Got user: ${user.name}'),
  error: (error) => print('Error: $error'),
);
```

## Async APIs

### Cancellation Support

```dart
class Downloader {
  Future<Uint8List> download(
    String url, {
    CancellationToken? cancellationToken,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(url));

      // Check cancellation before proceeding
      cancellationToken?.throwIfCancelled();

      final response = await request.close();
      final bytes = <int>[];

      await for (final chunk in response) {
        cancellationToken?.throwIfCancelled();
        bytes.addAll(chunk);
      }

      return Uint8List.fromList(bytes);
    } finally {
      client.close();
    }
  }
}

class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;

  void throwIfCancelled() {
    if (_isCancelled) throw CancelledException();
  }
}
```

### Stream APIs

```dart
/// Watches a resource for changes.
abstract class Watcher<T> {
  /// Stream of change events.
  Stream<T> get changes;

  /// Starts watching. Must be called before accessing [changes].
  Future<void> start();

  /// Stops watching and releases resources.
  Future<void> stop();
}

class FileWatcher implements Watcher<FileChange> {
  final String path;
  final StreamController<FileChange> _controller = StreamController.broadcast();
  StreamSubscription? _subscription;

  FileWatcher(this.path);

  @override
  Stream<FileChange> get changes => _controller.stream;

  @override
  Future<void> start() async {
    final directory = Directory(path);
    _subscription = directory.watch().listen((event) {
      _controller.add(FileChange(event.path, event.type));
    });
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
```

## Configuration APIs

### Options Pattern

```dart
/// Options for the HTTP client.
class HttpClientOptions {
  /// Connection timeout.
  final Duration connectTimeout;

  /// Read timeout.
  final Duration readTimeout;

  /// Maximum redirects to follow.
  final int maxRedirects;

  /// Whether to follow redirects.
  final bool followRedirects;

  /// Default headers for all requests.
  final Map<String, String> defaultHeaders;

  const HttpClientOptions({
    this.connectTimeout = const Duration(seconds: 30),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
    this.followRedirects = true,
    this.defaultHeaders = const {},
  });

  /// Default options.
  static const defaults = HttpClientOptions();

  HttpClientOptions copyWith({
    Duration? connectTimeout,
    Duration? readTimeout,
    int? maxRedirects,
    bool? followRedirects,
    Map<String, String>? defaultHeaders,
  }) {
    return HttpClientOptions(
      connectTimeout: connectTimeout ?? this.connectTimeout,
      readTimeout: readTimeout ?? this.readTimeout,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      followRedirects: followRedirects ?? this.followRedirects,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    );
  }
}

class HttpClient {
  final HttpClientOptions options;

  HttpClient({HttpClientOptions? options})
      : options = options ?? HttpClientOptions.defaults;
}
```

## Breaking Change Guidelines

### Major Version (Breaking)

- Removing public API
- Changing method signatures
- Changing return types
- Changing default behavior significantly
- Increasing minimum SDK version

### Minor Version (Non-breaking)

- Adding new classes/methods
- Adding optional parameters
- Deprecating (but not removing) APIs
- Bug fixes that don't change behavior

### Deprecation Process

```dart
// v1.0.0 - Original API
class Parser {
  String parse(String input) => _parse(input);
}

// v1.1.0 - Deprecate, add replacement
class Parser {
  @Deprecated('Use tryParse() instead. Will be removed in v2.0.0')
  String parse(String input) => _parse(input);

  String? tryParse(String input) {
    try {
      return _parse(input);
    } catch (_) {
      return null;
    }
  }
}

// v2.0.0 - Remove deprecated API
class Parser {
  String? tryParse(String input) { ... }
}
```
