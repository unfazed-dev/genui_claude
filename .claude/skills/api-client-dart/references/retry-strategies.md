# Retry Strategies

## Backoff Algorithms

### Fixed Delay

```dart
Duration fixedDelay(int attempt, Duration baseDelay) {
  return baseDelay;
}

// Always waits 1 second: 1s, 1s, 1s, 1s
```

### Linear Backoff

```dart
Duration linearBackoff(int attempt, Duration baseDelay) {
  return baseDelay * attempt;
}

// 1s, 2s, 3s, 4s, 5s
```

### Exponential Backoff

```dart
Duration exponentialBackoff(int attempt, Duration baseDelay) {
  return baseDelay * pow(2, attempt - 1).toInt();
}

// 1s, 2s, 4s, 8s, 16s
```

### Exponential Backoff with Jitter

```dart
Duration exponentialBackoffWithJitter(
  int attempt,
  Duration baseDelay, {
  double jitterFactor = 0.5,
}) {
  final exponential = baseDelay * pow(2, attempt - 1).toInt();
  final jitter = Random().nextDouble() * jitterFactor;
  return exponential * (1 + jitter);
}

// Adds randomness to prevent thundering herd
// ~1s, ~2.3s, ~4.7s, ~9.1s
```

### Decorrelated Jitter

```dart
class DecorrelatedJitter {
  Duration _previous = Duration.zero;

  Duration next(Duration baseDelay, Duration maxDelay) {
    final min = baseDelay;
    final max = _previous * 3;
    final delay = min + Duration(
      milliseconds: Random().nextInt(
        (max - min).inMilliseconds.clamp(0, maxDelay.inMilliseconds),
      ),
    );
    _previous = delay;
    return delay;
  }
}
```

## Retry Interceptor Implementation

```dart
class AdvancedRetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final BackoffStrategy backoffStrategy;
  final Set<int> retryableStatusCodes;
  final bool Function(DioException)? shouldRetry;

  AdvancedRetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffStrategy = BackoffStrategy.exponentialWithJitter,
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
    this.shouldRetry,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retries = err.requestOptions.extra['_retryCount'] ?? 0;

    if (!_shouldRetry(err, retries)) {
      handler.next(err);
      return;
    }

    final delay = _calculateDelay(retries + 1, err);
    await Future.delayed(delay);

    final options = err.requestOptions;
    options.extra['_retryCount'] = retries + 1;

    try {
      final dio = Dio();
      dio.options = BaseOptions(
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
      );
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      // Recursively retry
      onError(e, handler);
    }
  }

  bool _shouldRetry(DioException err, int currentRetries) {
    if (currentRetries >= maxRetries) return false;

    // Custom retry logic
    if (shouldRetry != null) return shouldRetry!(err);

    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  Duration _calculateDelay(int attempt, DioException err) {
    // Handle rate limit with Retry-After header
    final retryAfter = err.response?.headers.value('Retry-After');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    Duration delay;
    switch (backoffStrategy) {
      case BackoffStrategy.fixed:
        delay = baseDelay;
      case BackoffStrategy.linear:
        delay = baseDelay * attempt;
      case BackoffStrategy.exponential:
        delay = baseDelay * pow(2, attempt - 1).toInt();
      case BackoffStrategy.exponentialWithJitter:
        final base = baseDelay * pow(2, attempt - 1).toInt();
        final jitter = Random().nextDouble() * 0.5;
        delay = base * (1 + jitter);
    }

    return delay > maxDelay ? maxDelay : delay;
  }
}

enum BackoffStrategy {
  fixed,
  linear,
  exponential,
  exponentialWithJitter,
}
```

## Circuit Breaker Pattern

```dart
enum CircuitState { closed, open, halfOpen }

class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailure;
  DateTime? _openedAt;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.halfOpenTimeout = const Duration(seconds: 5),
  });

  bool get canExecute {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        if (DateTime.now().difference(_openedAt!) > resetTimeout) {
          _state = CircuitState.halfOpen;
          return true;
        }
        return false;
      case CircuitState.halfOpen:
        return true;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailure = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _trip();
    } else if (_failureCount >= failureThreshold) {
      _trip();
    }
  }

  void _trip() {
    _state = CircuitState.open;
    _openedAt = DateTime.now();
  }
}

class CircuitBreakerInterceptor extends Interceptor {
  final Map<String, CircuitBreaker> _circuits = {};

  CircuitBreaker _getCircuit(String key) {
    return _circuits.putIfAbsent(key, () => CircuitBreaker());
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final circuit = _getCircuit(options.baseUrl);

    if (!circuit.canExecute) {
      handler.reject(DioException(
        requestOptions: options,
        error: CircuitOpenException('Circuit breaker is open'),
        type: DioExceptionType.unknown,
      ));
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _getCircuit(response.requestOptions.baseUrl).recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isServerError(err)) {
      _getCircuit(err.requestOptions.baseUrl).recordFailure();
    }
    handler.next(err);
  }

  bool _isServerError(DioException err) {
    final code = err.response?.statusCode;
    return code != null && code >= 500;
  }
}

class CircuitOpenException implements Exception {
  final String message;
  CircuitOpenException(this.message);
}
```

## Retry with Fallback

```dart
class RetryWithFallbackInterceptor extends Interceptor {
  final int maxRetries;
  final List<String> fallbackUrls;

  RetryWithFallbackInterceptor({
    this.maxRetries = 3,
    required this.fallbackUrls,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retries = err.requestOptions.extra['_retryCount'] ?? 0;
    final urlIndex = err.requestOptions.extra['_urlIndex'] ?? 0;

    // Try next fallback URL
    if (urlIndex < fallbackUrls.length && _isNetworkError(err)) {
      final options = err.requestOptions;
      options.baseUrl = fallbackUrls[urlIndex];
      options.extra['_urlIndex'] = urlIndex + 1;
      options.extra['_retryCount'] = 0;

      try {
        final dio = Dio();
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        onError(e, handler);
        return;
      }
    }

    // Retry on same URL
    if (retries < maxRetries && _shouldRetry(err)) {
      await Future.delayed(Duration(seconds: pow(2, retries).toInt()));

      final options = err.requestOptions;
      options.extra['_retryCount'] = retries + 1;

      try {
        final dio = Dio();
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        onError(e, handler);
        return;
      }
    }

    handler.next(err);
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}
```

## Idempotency Key

```dart
class IdempotencyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only add for mutating requests
    if (['POST', 'PUT', 'PATCH'].contains(options.method)) {
      // Use existing key or generate new one
      final key = options.extra['idempotencyKey'] ?? Uuid().v4();
      options.headers['Idempotency-Key'] = key;
      options.extra['idempotencyKey'] = key;
    }
    handler.next(options);
  }
}

// Usage with retry
Future<Response> safePost(String path, Object data) async {
  final idempotencyKey = Uuid().v4();

  return _dio.post(
    path,
    data: data,
    options: Options(extra: {'idempotencyKey': idempotencyKey}),
  );
}
```

## Retry Configuration Per Request

```dart
class RequestRetryOptions {
  final int? maxRetries;
  final Duration? baseDelay;
  final BackoffStrategy? backoffStrategy;
  final bool? enabled;

  const RequestRetryOptions({
    this.maxRetries,
    this.baseDelay,
    this.backoffStrategy,
    this.enabled,
  });
}

extension RetryOptionsExtension on Options {
  Options withRetry(RequestRetryOptions retry) {
    return copyWith(
      extra: {
        ...?extra,
        '_retryOptions': retry,
      },
    );
  }
}

// Usage
await dio.get(
  '/important-data',
  options: Options().withRetry(RequestRetryOptions(
    maxRetries: 5,
    backoffStrategy: BackoffStrategy.exponentialWithJitter,
  )),
);

// Disable retry for specific request
await dio.post(
  '/webhook',
  options: Options().withRetry(RequestRetryOptions(enabled: false)),
);
```

## Retry Status Dashboard

```dart
class RetryMetrics {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  int totalRetries = 0;
  Map<int, int> retriesByAttempt = {};

  void recordSuccess(int attempts) {
    totalRequests++;
    successfulRequests++;
    if (attempts > 1) {
      totalRetries += attempts - 1;
      retriesByAttempt.update(attempts, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  void recordFailure(int attempts) {
    totalRequests++;
    failedRequests++;
    totalRetries += attempts;
  }

  double get successRate => totalRequests > 0
      ? successfulRequests / totalRequests
      : 0;

  double get averageRetries => totalRequests > 0
      ? totalRetries / totalRequests
      : 0;

  Map<String, dynamic> toJson() => {
    'totalRequests': totalRequests,
    'successfulRequests': successfulRequests,
    'failedRequests': failedRequests,
    'successRate': '${(successRate * 100).toStringAsFixed(1)}%',
    'totalRetries': totalRetries,
    'averageRetries': averageRetries.toStringAsFixed(2),
    'retriesByAttempt': retriesByAttempt,
  };
}
```
