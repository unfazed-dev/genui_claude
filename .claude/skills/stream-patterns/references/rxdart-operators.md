# RxDart Operators Reference

## Creation Operators

```dart
// From various sources
Rx.fromCallable(() async => await fetchData());
Rx.defer(() => Stream.value(getData()));
Rx.timer(value, Duration(seconds: 2));
Rx.range(1, 10);
Rx.repeat((count) => Stream.value(count), 5);

// Periodic
Stream.periodic(Duration(seconds: 1), (i) => i);

// From Future
Future.value(42).asStream();

// Never emits, never completes
Rx.never<int>();

// Empty (completes immediately)
Stream<int>.empty();
```

## Transformation Operators

```dart
// map - transform each value
stream.map((x) => x.toString());

// asyncMap - async transformation
stream.asyncMap((x) => fetchDetails(x));

// expand - one-to-many
stream.expand((x) => [x, x * 2, x * 3]);

// flatMap - flatten inner streams (concurrent)
stream.flatMap((x) => fetchStream(x));

// concatMap - flatten inner streams (sequential)
stream.concatMap((x) => fetchStream(x));

// switchMap - cancel previous inner stream
stream.switchMap((x) => fetchStream(x));

// exhaustMap - ignore new until current completes
stream.exhaustMap((x) => fetchStream(x));

// scan - accumulate values
stream.scan((acc, val, _) => acc + val, 0);

// buffer - collect values
stream.buffer(Stream.periodic(Duration(seconds: 5)));
stream.bufferCount(10);
stream.bufferTime(Duration(seconds: 5));

// window - emit as streams
stream.window(Stream.periodic(Duration(seconds: 5)));
stream.windowCount(10);

// pairwise - emit consecutive pairs
stream.pairwise(); // [1,2], [2,3], [3,4]

// startWith - prepend value
stream.startWith(initialValue);

// endWith - append value
stream.endWith(finalValue);

// mapTo - replace all values
stream.mapTo(constantValue);
```

## Filtering Operators

```dart
// where - filter by predicate
stream.where((x) => x > 0);

// whereType - filter by type
stream.whereType<SuccessEvent>();

// distinct - remove consecutive duplicates
stream.distinct();
stream.distinctUnique(); // Remove all duplicates

// take / skip
stream.take(5);
stream.takeLast(5);
stream.takeWhile((x) => x < 10);
stream.takeUntil(stopSignal);
stream.skip(5);
stream.skipWhile((x) => x < 10);
stream.skipUntil(startSignal);

// first / last / single
stream.first;
stream.last;
stream.single;
stream.firstWhere((x) => x > 5);
stream.singleWhere((x) => x == target);

// elementAt
stream.elementAt(3);

// ignoreElements - only complete/error
stream.ignoreElements();

// sample - emit latest at intervals
stream.sample(Stream.periodic(Duration(seconds: 1)));
stream.sampleTime(Duration(seconds: 1));

// debounce - wait for pause
stream.debounce((_) => Stream.value(null).delay(Duration(ms: 300)));
stream.debounceTime(Duration(milliseconds: 300));

// throttle - rate limit
stream.throttle((_) => Stream.value(null).delay(Duration(ms: 100)));
stream.throttleTime(Duration(milliseconds: 100));
```

## Combining Operators

```dart
// merge - combine multiple streams
Rx.merge([stream1, stream2, stream3]);
stream1.mergeWith([stream2, stream3]);

// concat - sequential streams
Rx.concat([stream1, stream2, stream3]);
stream1.concatWith([stream2, stream3]);

// combineLatest - latest from each
Rx.combineLatest2(stream1, stream2, (a, b) => combine(a, b));
Rx.combineLatest3(s1, s2, s3, (a, b, c) => combine(a, b, c));
Rx.combineLatestList([s1, s2, s3]);

// zip - pair by index
Rx.zip2(stream1, stream2, (a, b) => '$a-$b');
Rx.zipList([s1, s2, s3]);

// forkJoin - wait for all to complete
Rx.forkJoin2(stream1, stream2, (a, b) => [a, b]);

// withLatestFrom - combine on emit
stream1.withLatestFrom(stream2, (a, b) => combine(a, b));

// race - first stream to emit wins
Rx.race([stream1, stream2]);

// amb - alias for race
stream1.amb(stream2);
```

## Error Handling Operators

```dart
// onErrorReturn - replace error with value
stream.onErrorReturn(defaultValue);

// onErrorReturnWith - dynamic fallback
stream.onErrorReturnWith((error, stackTrace) => computeFallback(error));

// onErrorResume - switch to fallback stream
stream.onErrorResume((error, stackTrace) => fallbackStream);

// retry - retry on error
stream.retry(3);
stream.retry(); // Infinite

// retryWhen - conditional retry
stream.retryWhen((errors) =>
  errors.delay(Duration(seconds: 1)).take(3)
);

// handleError
stream.handleError((error) => print('Error: $error'));

// catchError
stream.catchError((error) => Stream.value(fallback));

// materialize / dematerialize - wrap in Notification
stream.materialize().where((n) => !n.isError).dematerialize();
```

## Utility Operators

```dart
// delay - delay all events
stream.delay(Duration(seconds: 1));

// delayWhen - dynamic delay
stream.delayWhen((value) => Stream.value(null).delay(computeDelay(value)));

// timeout
stream.timeout(Duration(seconds: 30));
stream.timeoutAt(DateTime.now().add(Duration(minutes: 5)));

// timestamp - wrap with time
stream.timestamp(); // Timestamped<T>

// timeInterval - time between events
stream.timeInterval(); // TimeInterval<T>

// doOnData / doOnError / doOnDone / doOnListen / doOnCancel
stream
    .doOnData((data) => print('Data: $data'))
    .doOnError((e, st) => print('Error: $e'))
    .doOnDone(() => print('Done'))
    .doOnListen(() => print('Listening'))
    .doOnCancel(() => print('Cancelled'));

// share - make broadcast, replay latest
stream.share();

// shareReplay - broadcast with buffer
stream.shareReplay(maxSize: 3);

// shareValue - broadcast with BehaviorSubject
stream.shareValue();

// publishValue / publish
stream.publishValue().autoConnect();
stream.publish().refCount();

// asBroadcastStream
stream.asBroadcastStream();

// cast / retype
stream.cast<NewType>();

// toList / toSet
await stream.toList();
await stream.toSet();

// forEach
await stream.forEach(print);

// drain
await stream.drain();

// pipe
await stream.pipe(streamConsumer);
```

## Conditional Operators

```dart
// defaultIfEmpty
stream.defaultIfEmpty(defaultValue);

// switchIfEmpty
stream.switchIfEmpty(fallbackStream);

// every / any
await stream.every((x) => x > 0);
await stream.any((x) => x > 0);

// contains
await stream.contains(value);

// isEmpty
await stream.isEmpty;

// length
await stream.length;
```

## Aggregate Operators

```dart
// reduce - single output
await stream.reduce((acc, val) => acc + val);

// fold - with initial value
await stream.fold(0, (acc, val) => acc + val);

// max / min (with RxDart)
await stream.max();
await stream.min();

// count
await stream.length;

// average
await stream.fold<List<int>>([], (acc, val) => [...acc, val])
    .then((list) => list.reduce((a, b) => a + b) / list.length);
```

## Subject Comparison

| Subject | Caches | New Listener Gets |
|---------|--------|-------------------|
| `PublishSubject` | No | Future events only |
| `BehaviorSubject` | Latest | Latest + future |
| `ReplaySubject` | N items | Buffer + future |
| `AsyncSubject` | Last | Last on complete |

```dart
// AsyncSubject - emits only last value, only on complete
final subject = AsyncSubject<int>();
subject.add(1);
subject.add(2);
subject.add(3);
subject.listen(print); // Nothing yet
await subject.close(); // Now prints: 3
```
