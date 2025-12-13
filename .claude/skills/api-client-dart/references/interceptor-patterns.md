# Interceptor Patterns

## Interceptor Order

Interceptors execute in order added. Consider the sequence:

```dart
dio.interceptors.addAll([
  LogInterceptor(),      // 1. Log raw request
  AuthInterceptor(),     // 2. Add auth headers
  CacheInterceptor(),    // 3. Check cache before network
  RetryInterceptor(),    // 4. Retry failed requests
  ErrorInterceptor(),    // 5. Transform errors last
]);
```

**Request flow:** 1 → 2 → 3 → 4 → 5 → Network
**Response flow:** Network → 5 → 4 → 3 → 2 → 1

## Handler Methods

### RequestInterceptorHandler

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  // Continue to next interceptor
  handler.next(options);

  // Short-circuit with response (skip network)
  handler.resolve(Response(
    requestOptions: options,
    data: cachedData,
    statusCode: 200,
  ));

  // Short-circuit with error
  handler.reject(DioException(
    requestOptions: options,
    error: 'Request blocked',
  ));
}
```

### ResponseInterceptorHandler

```dart
@override
void onResponse(Response response, ResponseInterceptorHandler handler) {
  // Continue to next interceptor
  handler.next(response);

  // Modify response
  handler.resolve(response.copyWith(data: transformedData));

  // Convert to error
  handler.reject(DioException(
    requestOptions: response.requestOptions,
    response: response,
    error: 'Unexpected response',
  ));
}
```

### ErrorInterceptorHandler

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  // Continue to next interceptor
  handler.next(err);

  // Recover from error with response
  handler.resolve(Response(
    requestOptions: err.requestOptions,
    data: fallbackData,
  ));

  // Transform error
  handler.reject(DioException(
    requestOptions: err.requestOptions,
    error: CustomException(err.message),
  ));
}
```

## Headers Interceptor

```dart
class HeadersInterceptor extends Interceptor {
  final Map<String, String> Function()? dynamicHeaders;

  HeadersInterceptor({this.dynamicHeaders});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add static headers
    options.headers['X-App-Version'] = '1.0.0';
    options.headers['X-Platform'] = Platform.operatingSystem;

    // Add dynamic headers
    if (dynamicHeaders != null) {
      options.headers.addAll(dynamicHeaders!());
    }

    // Add request ID for tracing
    options.headers['X-Request-ID'] = Uuid().v4();

    handler.next(options);
  }
}
```

## Request Transformer

```dart
class RequestTransformerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Convert DateTime to ISO string
    if (options.data is Map) {
      options.data = _transformMap(options.data);
    }

    // Add timestamp
    options.queryParameters['_t'] = DateTime.now().millisecondsSinceEpoch;

    handler.next(options);
  }

  dynamic _transformMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _transformMap(value));
      }
      return MapEntry(key, value);
    });
  }
}
```

## Response Transformer

```dart
class ResponseTransformerInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Unwrap API envelope
    if (response.data is Map && response.data.containsKey('data')) {
      response = response.copyWith(data: response.data['data']);
    }

    // Convert date strings to DateTime
    if (response.data is Map) {
      response = response.copyWith(
        data: _transformDates(response.data),
      );
    }

    handler.next(response);
  }

  dynamic _transformDates(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        if (value is String && _isIsoDate(value)) {
          return MapEntry(key, DateTime.parse(value));
        }
        return MapEntry(key, _transformDates(value));
      });
    }
    if (data is List) {
      return data.map(_transformDates).toList();
    }
    return data;
  }

  bool _isIsoDate(String value) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value);
  }
}
```

## Queue Interceptor

```dart
/// Queues requests when offline, executes when back online
class QueueInterceptor extends Interceptor {
  final List<_QueuedRequest> _queue = [];
  bool _isOnline = true;

  void setOnline(bool online) {
    _isOnline = online;
    if (online) {
      _processQueue();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isOnline) {
      handler.next(options);
    } else {
      final completer = Completer<Response>();
      _queue.add(_QueuedRequest(options, completer));
      completer.future.then(handler.resolve).catchError(handler.reject);
    }
  }

  Future<void> _processQueue() async {
    final queued = List<_QueuedRequest>.from(_queue);
    _queue.clear();

    for (final request in queued) {
      try {
        final dio = Dio();
        final response = await dio.fetch(request.options);
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }
}

class _QueuedRequest {
  final RequestOptions options;
  final Completer<Response> completer;

  _QueuedRequest(this.options, this.completer);
}
```

## Rate Limit Interceptor

```dart
class RateLimitInterceptor extends Interceptor {
  final int maxRequestsPerSecond;
  final Queue<DateTime> _requestTimes = Queue();

  RateLimitInterceptor({this.maxRequestsPerSecond = 10});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _waitForSlot();
    _requestTimes.add(DateTime.now());
    handler.next(options);
  }

  Future<void> _waitForSlot() async {
    // Remove old timestamps
    final now = DateTime.now();
    while (_requestTimes.isNotEmpty &&
        now.difference(_requestTimes.first).inSeconds >= 1) {
      _requestTimes.removeFirst();
    }

    // Wait if at capacity
    if (_requestTimes.length >= maxRequestsPerSecond) {
      final oldest = _requestTimes.first;
      final waitTime = Duration(seconds: 1) - now.difference(oldest);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime);
      }
    }
  }
}
```

## Encryption Interceptor

```dart
class EncryptionInterceptor extends Interceptor {
  final String Function(String) encrypt;
  final String Function(String) decrypt;

  EncryptionInterceptor({required this.encrypt, required this.decrypt});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data != null) {
      final json = jsonEncode(options.data);
      options.data = {'encrypted': encrypt(json)};
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map && response.data.containsKey('encrypted')) {
      final decrypted = decrypt(response.data['encrypted']);
      response = response.copyWith(data: jsonDecode(decrypted));
    }
    handler.next(response);
  }
}
```

## Analytics Interceptor

```dart
class AnalyticsInterceptor extends Interceptor {
  final AnalyticsService _analytics;

  AnalyticsInterceptor(this._analytics);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _trackRequest(response.requestOptions, response.statusCode, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _trackRequest(
      err.requestOptions,
      err.response?.statusCode,
      err.message,
    );
    handler.next(err);
  }

  void _trackRequest(RequestOptions options, int? statusCode, String? error) {
    final startTime = options.extra['startTime'] as DateTime?;
    final duration = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    _analytics.trackEvent('api_request', {
      'method': options.method,
      'path': options.path,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'error': error,
    });
  }
}
```

## Conditional Interceptor

```dart
class ConditionalInterceptor extends Interceptor {
  final bool Function(RequestOptions) condition;
  final Interceptor interceptor;

  ConditionalInterceptor({
    required this.condition,
    required this.interceptor,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (condition(options)) {
      interceptor.onRequest(options, handler);
    } else {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (condition(response.requestOptions)) {
      interceptor.onResponse(response, handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (condition(err.requestOptions)) {
      interceptor.onError(err, handler);
    } else {
      handler.next(err);
    }
  }
}

// Usage: Only cache GET requests to /api/v1/*
dio.interceptors.add(ConditionalInterceptor(
  condition: (options) =>
      options.method == 'GET' && options.path.startsWith('/api/v1/'),
  interceptor: CacheInterceptor(),
));
```

## Testing Interceptors

```dart
void main() {
  group('AuthInterceptor', () {
    late AuthInterceptor interceptor;
    late MockTokenStorage mockStorage;

    setUp(() {
      mockStorage = MockTokenStorage();
      interceptor = AuthInterceptor(mockStorage);
    });

    test('adds auth header when token exists', () {
      when(() => mockStorage.accessToken).thenReturn('test-token');

      final options = RequestOptions(path: '/test');
      final handler = MockRequestHandler();

      interceptor.onRequest(options, handler);

      verify(() => handler.next(any(that: predicate<RequestOptions>(
        (o) => o.headers['Authorization'] == 'Bearer test-token',
      )))).called(1);
    });

    test('skips auth header when no token', () {
      when(() => mockStorage.accessToken).thenReturn(null);

      final options = RequestOptions(path: '/test');
      final handler = MockRequestHandler();

      interceptor.onRequest(options, handler);

      verify(() => handler.next(any(that: predicate<RequestOptions>(
        (o) => !o.headers.containsKey('Authorization'),
      )))).called(1);
    });
  });
}
```
