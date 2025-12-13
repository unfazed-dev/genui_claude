# Stream Testing Patterns

## Basic Stream Assertions

```dart
import 'package:test/test.dart';

test('stream emits values in order', () {
  final stream = Stream.fromIterable([1, 2, 3]);

  expect(stream, emitsInOrder([1, 2, 3]));
});

test('stream emits and completes', () {
  final stream = Stream.fromIterable([1, 2, 3]);

  expect(stream, emitsInOrder([1, 2, 3, emitsDone]));
});

test('stream emits then errors', () {
  final controller = StreamController<int>();
  controller.add(1);
  controller.addError(Exception('Failed'));
  controller.close();

  expect(controller.stream, emitsInOrder([
    1,
    emitsError(isA<Exception>()),
  ]));
});
```

## Stream Matchers

```dart
// emits - single value
expect(stream, emits(42));

// emitsInOrder - sequence of values
expect(stream, emitsInOrder([1, 2, 3]));

// emitsAnyOf - any of these
expect(stream, emitsAnyOf([1, 2, 3]));

// emitsThrough - until this value
expect(stream, emitsThrough(5));

// emitsDone - stream completes
expect(stream, emitsDone);

// emitsError - error emitted
expect(stream, emitsError(isA<Exception>()));
expect(stream, emitsError(isStateError));

// neverEmits - value never appears
expect(stream, neverEmits(negativeValue));

// mayEmit - might emit
expect(stream, mayEmit(optionalValue));

// mayEmitMultiple - might emit multiple
expect(stream, mayEmitMultiple([a, b, c]));
```

## Testing StreamControllers

```dart
test('controller broadcasts to multiple listeners', () async {
  final controller = StreamController<int>.broadcast();
  final results1 = <int>[];
  final results2 = <int>[];

  controller.stream.listen(results1.add);
  controller.stream.listen(results2.add);

  controller.add(1);
  controller.add(2);
  await controller.close();

  expect(results1, [1, 2]);
  expect(results2, [1, 2]);
});

test('controller handles errors', () async {
  final controller = StreamController<int>();
  Object? caughtError;

  controller.stream.listen(
    (data) {},
    onError: (e) => caughtError = e,
  );

  controller.addError(ArgumentError('bad'));
  await Future.delayed(Duration.zero);

  expect(caughtError, isArgumentError);
});
```

## Testing BehaviorSubject

```dart
test('BehaviorSubject emits latest to new listeners', () async {
  final subject = BehaviorSubject.seeded(0);

  subject.add(1);
  subject.add(2);

  final values = <int>[];
  subject.listen(values.add);

  await Future.delayed(Duration.zero);

  expect(values, [2]); // Only latest
  expect(subject.value, 2);

  await subject.close();
});

test('BehaviorSubject value is synchronously available', () {
  final subject = BehaviorSubject.seeded(42);

  expect(subject.value, 42);
  expect(subject.hasValue, isTrue);

  subject.add(100);
  expect(subject.value, 100);
});
```

## Testing PublishSubject

```dart
test('PublishSubject does not replay', () async {
  final subject = PublishSubject<int>();

  subject.add(1); // Lost - no listeners

  final values = <int>[];
  subject.listen(values.add);

  subject.add(2);
  subject.add(3);

  await Future.delayed(Duration.zero);

  expect(values, [2, 3]); // 1 was lost

  await subject.close();
});
```

## Testing ReplaySubject

```dart
test('ReplaySubject replays buffered values', () async {
  final subject = ReplaySubject<int>(maxSize: 2);

  subject.add(1);
  subject.add(2);
  subject.add(3);

  final values = <int>[];
  subject.listen(values.add);

  await Future.delayed(Duration.zero);

  expect(values, [2, 3]); // Only last 2

  await subject.close();
});
```

## Testing Transformations

```dart
test('map transforms values', () {
  final stream = Stream.fromIterable([1, 2, 3]).map((x) => x * 2);

  expect(stream, emitsInOrder([2, 4, 6]));
});

test('where filters values', () {
  final stream = Stream.fromIterable([1, 2, 3, 4, 5])
      .where((x) => x.isEven);

  expect(stream, emitsInOrder([2, 4]));
});

test('distinct removes duplicates', () {
  final stream = Stream.fromIterable([1, 1, 2, 2, 3])
      .distinct();

  expect(stream, emitsInOrder([1, 2, 3]));
});
```

## Testing Debounce/Throttle

```dart
test('debounce waits for pause', () async {
  final subject = PublishSubject<int>();
  final results = <int>[];

  subject.stream
      .debounceTime(Duration(milliseconds: 100))
      .listen(results.add);

  subject.add(1);
  subject.add(2);
  subject.add(3);

  await Future.delayed(Duration(milliseconds: 150));

  expect(results, [3]); // Only last after pause

  await subject.close();
});

test('throttle limits rate', () async {
  final subject = PublishSubject<int>();
  final results = <int>[];

  subject.stream
      .throttleTime(Duration(milliseconds: 100))
      .listen(results.add);

  subject.add(1);
  await Future.delayed(Duration(milliseconds: 10));
  subject.add(2); // Ignored
  subject.add(3); // Ignored

  await Future.delayed(Duration(milliseconds: 100));
  subject.add(4);

  await Future.delayed(Duration(milliseconds: 50));

  expect(results, [1, 4]);

  await subject.close();
});
```

## Testing CombineLatest

```dart
test('combineLatest combines latest values', () async {
  final s1 = BehaviorSubject.seeded(1);
  final s2 = BehaviorSubject.seeded('a');
  final results = <String>[];

  Rx.combineLatest2(s1, s2, (int a, String b) => '$a$b')
      .listen(results.add);

  await Future.delayed(Duration.zero);
  expect(results, ['1a']);

  s1.add(2);
  await Future.delayed(Duration.zero);
  expect(results, ['1a', '2a']);

  s2.add('b');
  await Future.delayed(Duration.zero);
  expect(results, ['1a', '2a', '2b']);

  await s1.close();
  await s2.close();
});
```

## Testing SwitchMap

```dart
test('switchMap cancels previous inner stream', () async {
  final outer = PublishSubject<int>();
  final results = <String>[];
  var innerStreamCount = 0;

  outer.stream
      .switchMap((x) {
        innerStreamCount++;
        return Stream.periodic(
          Duration(milliseconds: 50),
          (i) => '$x-$i',
        ).take(3);
      })
      .listen(results.add);

  outer.add(1);
  await Future.delayed(Duration(milliseconds: 60));
  outer.add(2); // Cancels stream 1
  await Future.delayed(Duration(milliseconds: 200));

  // Stream 1 only emitted once before cancellation
  // Stream 2 emitted all 3
  expect(results.where((s) => s.startsWith('1')).length, lessThan(3));
  expect(results.where((s) => s.startsWith('2')).length, 3);

  await outer.close();
});
```

## Testing Error Handling

```dart
test('onErrorReturn provides fallback', () {
  final stream = Stream<int>.error(Exception('fail'))
      .onErrorReturn(-1);

  expect(stream, emitsInOrder([-1, emitsDone]));
});

test('retry retries on error', () async {
  var attempts = 0;

  final stream = Rx.defer(() {
    attempts++;
    if (attempts < 3) {
      return Stream<int>.error(Exception('fail'));
    }
    return Stream.value(42);
  }).retry(3);

  expect(stream, emits(42));
  await stream.drain();
  expect(attempts, 3);
});
```

## Testing Async Generators

```dart
test('async generator yields values', () async {
  Stream<int> generator() async* {
    yield 1;
    await Future.delayed(Duration(milliseconds: 10));
    yield 2;
    yield 3;
  }

  expect(generator(), emitsInOrder([1, 2, 3, emitsDone]));
});

test('async generator handles errors', () async {
  Stream<int> failingGenerator() async* {
    yield 1;
    throw Exception('Generator failed');
  }

  expect(failingGenerator(), emitsInOrder([
    1,
    emitsError(isException),
  ]));
});
```

## Collecting Stream Results

```dart
test('collect all values', () async {
  final stream = Stream.fromIterable([1, 2, 3]);
  final values = await stream.toList();

  expect(values, [1, 2, 3]);
});

test('collect with timeout', () async {
  final controller = StreamController<int>();

  Future.delayed(Duration(milliseconds: 50), () {
    controller.add(1);
    controller.add(2);
    controller.close();
  });

  final values = await controller.stream
      .timeout(Duration(seconds: 1))
      .toList();

  expect(values, [1, 2]);
});
```

## Testing Memory/Cleanup

```dart
test('subscription cancellation', () async {
  var disposed = false;
  final controller = StreamController<int>(
    onCancel: () => disposed = true,
  );

  final subscription = controller.stream.listen((_) {});

  expect(disposed, isFalse);

  await subscription.cancel();

  expect(disposed, isTrue);
});

test('subject closes properly', () async {
  final subject = BehaviorSubject<int>();

  expect(subject.isClosed, isFalse);

  await subject.close();

  expect(subject.isClosed, isTrue);
  expect(() => subject.add(1), throwsStateError);
});
```

## FakeAsync for Time-Based Tests

```dart
import 'package:fake_async/fake_async.dart';

test('debounce with fake time', () {
  fakeAsync((async) {
    final subject = PublishSubject<int>();
    final results = <int>[];

    subject.stream
        .debounceTime(Duration(milliseconds: 300))
        .listen(results.add);

    subject.add(1);
    async.elapse(Duration(milliseconds: 100));
    subject.add(2);
    async.elapse(Duration(milliseconds: 100));
    subject.add(3);

    expect(results, isEmpty); // Not enough time

    async.elapse(Duration(milliseconds: 300));

    expect(results, [3]); // Now debounced

    subject.close();
  });
});
```
