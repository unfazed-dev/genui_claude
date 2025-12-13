---
name: stream-patterns
description: Dart reactive programming toolkit with StreamController, broadcast streams, and RxDart operators. Use when working with async data flows, event handling, real-time updates, or reactive state management.
---

# Dart Stream Patterns

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  rxdart: ^0.28.0
```

```dart
import 'dart:async';
import 'package:rxdart/rxdart.dart';
```

## StreamController Basics

### Single-Subscription Stream

```dart
// One listener only - throws if listened twice
final controller = StreamController<int>();

controller.stream.listen(
  (data) => print('Data: $data'),
  onError: (error) => print('Error: $error'),
  onDone: () => print('Done'),
);

controller.add(1);
controller.add(2);
controller.addError(Exception('Failed'));
await controller.close();
```

### Broadcast Stream

```dart
// Multiple listeners allowed
final controller = StreamController<int>.broadcast();

// First listener
controller.stream.listen((data) => print('Listener 1: $data'));

// Second listener
controller.stream.listen((data) => print('Listener 2: $data'));

controller.add(1); // Both listeners receive this
await controller.close();
```

### Async Generator

```dart
Stream<int> countStream(int max) async* {
  for (var i = 0; i < max; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

// Usage
await for (final count in countStream(5)) {
  print(count);
}
```

## RxDart Subjects

### BehaviorSubject (Latest Value)

```dart
// Caches latest value, emits to new listeners immediately
final subject = BehaviorSubject<int>.seeded(0);

subject.add(1);
subject.add(2);

// New listener gets 2 immediately
subject.listen(print); // Prints: 2

print(subject.value); // Direct access: 2
await subject.close();
```

### PublishSubject (No Cache)

```dart
// No caching, listeners only get future events
final subject = PublishSubject<int>();

subject.add(1); // Lost - no listeners yet

subject.listen(print);
subject.add(2); // Prints: 2
subject.add(3); // Prints: 3

await subject.close();
```

### ReplaySubject (Buffer History)

```dart
// Replays N previous events to new listeners
final subject = ReplaySubject<int>(maxSize: 3);

subject.add(1);
subject.add(2);
subject.add(3);
subject.add(4);

// New listener gets: 2, 3, 4 (last 3)
subject.listen(print);

await subject.close();
```

## Stream Operators

### Transformation

```dart
stream
    .map((x) => x * 2)                    // Transform each value
    .where((x) => x > 10)                 // Filter values
    .distinct()                           // Remove consecutive duplicates
    .take(5)                              // Take first N
    .skip(2)                              // Skip first N
    .listen(print);
```

### Debounce & Throttle

```dart
// Wait for pause in events (search input)
searchController.stream
    .debounceTime(Duration(milliseconds: 300))
    .listen((query) => performSearch(query));

// Limit event rate (scroll events)
scrollController.stream
    .throttleTime(Duration(milliseconds: 100))
    .listen((position) => updateUI(position));
```

### Combining Streams

```dart
// Combine latest values from multiple streams
Rx.combineLatest2(
  usernameStream,
  passwordStream,
  (String user, String pass) => '$user:$pass',
).listen(print);

// Merge multiple streams into one
Rx.merge([stream1, stream2, stream3]).listen(print);

// Zip streams (pair values by index)
Rx.zip2(stream1, stream2, (a, b) => '$a-$b').listen(print);

// Wait for all to complete
Rx.forkJoin2(future1.asStream(), future2.asStream(), (a, b) => [a, b]);
```

### FlatMap / SwitchMap

```dart
// flatMap: All inner streams run concurrently
searchStream
    .flatMap((query) => apiService.search(query).asStream())
    .listen(print);

// switchMap: Cancel previous, only latest matters
searchStream
    .switchMap((query) => apiService.search(query).asStream())
    .listen(print); // Use for search - cancels stale requests
```

### Error Handling

```dart
stream
    .onErrorReturn(-1)                              // Return default on error
    .onErrorReturnWith((e, st) => fallbackValue)   // Dynamic fallback
    .onErrorResume((e, st) => fallbackStream)      // Switch to backup stream
    .retry(3)                                       // Retry N times
    .retryWhen((errors) => errors.delay(Duration(seconds: 1))) // Retry with delay
    .listen(print);
```

## Common Patterns

### Event Bus

```dart
class EventBus {
  final _controller = PublishSubject<dynamic>();

  Stream<T> on<T>() => _controller.stream.whereType<T>();

  void fire(event) => _controller.add(event);

  void dispose() => _controller.close();
}

// Usage
final bus = EventBus();
bus.on<UserLoggedIn>().listen((event) => print('User: ${event.userId}'));
bus.fire(UserLoggedIn(userId: '123'));
```

### Value Notifier Pattern

```dart
class ReactiveValue<T> {
  final BehaviorSubject<T> _subject;

  ReactiveValue(T initial) : _subject = BehaviorSubject.seeded(initial);

  T get value => _subject.value;
  set value(T newValue) => _subject.add(newValue);

  Stream<T> get stream => _subject.stream;

  void dispose() => _subject.close();
}

// Usage
final counter = ReactiveValue(0);
counter.stream.listen(print);
counter.value = 1; // Prints: 1
counter.value = 2; // Prints: 2
```

### Paginated Data Stream

```dart
class PaginatedStream<T> {
  final Future<List<T>> Function(int page) fetcher;
  final _controller = BehaviorSubject<List<T>>.seeded([]);
  int _page = 0;
  bool _hasMore = true;

  PaginatedStream(this.fetcher);

  Stream<List<T>> get stream => _controller.stream;
  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final items = await fetcher(_page);
    if (items.isEmpty) {
      _hasMore = false;
    } else {
      _page++;
      _controller.add([..._controller.value, ...items]);
    }
  }

  void dispose() => _controller.close();
}
```

### Debounced Search

```dart
class SearchController {
  final _querySubject = PublishSubject<String>();
  late final Stream<List<Result>> results;

  SearchController(ApiService api) {
    results = _querySubject.stream
        .debounceTime(Duration(milliseconds: 300))
        .distinct()
        .where((q) => q.length >= 2)
        .switchMap((query) => api.search(query).asStream())
        .share(); // Share stream among multiple listeners
  }

  void search(String query) => _querySubject.add(query);

  void dispose() => _querySubject.close();
}
```

## Memory Management

### Always Close Controllers

```dart
class MyService {
  final _controller = StreamController<int>.broadcast();

  Stream<int> get stream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
```

### Cancel Subscriptions

```dart
class MyWidget extends StatefulWidget { ... }

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      if (mounted) setState(() => _data = data);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### CompositeSubscription

```dart
class MyController {
  final _subscriptions = CompositeSubscription();

  void init() {
    stream1.listen(handle1).addTo(_subscriptions);
    stream2.listen(handle2).addTo(_subscriptions);
    stream3.listen(handle3).addTo(_subscriptions);
  }

  void dispose() {
    _subscriptions.dispose(); // Cancels all at once
  }
}
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Bad state: Stream already listened` | Use `.broadcast()` or `.asBroadcastStream()` |
| Stream not emitting | Check if controller is closed; verify `add()` called |
| Memory leak | Cancel subscriptions in `dispose()` |
| Missing events | BehaviorSubject for late listeners; ReplaySubject for history |
| Stale search results | Use `switchMap` instead of `flatMap` |
| Too many events | Use `debounceTime` or `throttleTime` |

## Resources

- **RxDart Operators**: See [references/rxdart-operators.md](references/rxdart-operators.md)
- **Stream Testing**: See [references/stream-testing.md](references/stream-testing.md)
