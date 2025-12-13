---
name: api-client-dart
description: Dart HTTP client toolkit with dio/http patterns, interceptors, retry logic, and error handling. Use when building API clients, implementing authentication, handling network errors, or adding request/response interceptors.
---

# Dart API Client Patterns

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0          # Full-featured HTTP client
  http: ^1.2.0         # Lightweight alternative
  retry: ^3.1.0        # Retry utilities
```

## Package Comparison

| Feature | dio | http |
|---------|-----|------|
| Interceptors | Built-in | Manual |
| Request cancellation | Yes | Yes |
| File upload/download | Built-in | Manual |
| Transformers | Yes | No |
| FormData | Built-in | Manual |
| Bundle size | Larger | Smaller |

## Dio Setup

### Basic Configuration

```dart
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'https://api.example.com',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      sendTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return response.data as T;
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }
}
```

### Factory Pattern

```dart
class ApiClientFactory {
  static Dio create({
    required String baseUrl,
    String? authToken,
    List<Interceptor>? interceptors,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    // Add default interceptors
    dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true),
      if (authToken != null) AuthInterceptor(authToken),
      ...?interceptors,
    ]);

    return dio;
  }
}
```

## Interceptors

### Auth Interceptor

```dart
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        await _refreshToken();
        // Retry the request
        final response = await _retry(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Refresh failed, logout user
        _tokenStorage.clear();
      }
    }
    handler.next(err);
  }

  Future<void> _refreshToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) throw Exception('No refresh token');

    final dio = Dio(); // Fresh instance without interceptors
    final response = await dio.post(
      '${_tokenStorage.baseUrl}/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    _tokenStorage.accessToken = response.data['access_token'];
    _tokenStorage.refreshToken = response.data['refresh_token'];
  }

  Future<Response> _retry(RequestOptions options) async {
    final token = _tokenStorage.accessToken;
    options.headers['Authorization'] = 'Bearer $token';

    final dio = Dio();
    return dio.fetch(options);
  }
}
```

### Logging Interceptor

```dart
class CustomLogInterceptor extends Interceptor {
  final void Function(String)? logger;

  CustomLogInterceptor({this.logger});

  void _log(String message) {
    if (logger != null) {
      logger!(message);
    } else {
      print(message);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('→ ${options.method} ${options.uri}');
    _log('  Headers: ${options.headers}');
    if (options.data != null) {
      _log('  Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('← ${response.statusCode} ${response.requestOptions.uri}');
    _log('  Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('✕ ${err.type} ${err.requestOptions.uri}');
    _log('  Message: ${err.message}');
    handler.next(err);
  }
}
```

### Cache Interceptor

```dart
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration cacheDuration;

  CacheInterceptor({this.cacheDuration = const Duration(minutes: 5)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      handler.next(options);
      return;
    }

    final key = _cacheKey(options);
    final cached = _cache[key];

    if (cached != null && !cached.isExpired) {
      handler.resolve(Response(
        requestOptions: options,
        data: cached.data,
        statusCode: 200,
      ));
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET') {
      final key = _cacheKey(response.requestOptions);
      _cache[key] = CacheEntry(
        data: response.data,
        expiry: DateTime.now().add(cacheDuration),
      );
    }
    handler.next(response);
  }

  String _cacheKey(RequestOptions options) {
    return '${options.uri}';
  }

  void clear() => _cache.clear();
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

### Retry Interceptor

```dart
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;
  final Set<int> retryStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const {408, 429, 500, 502, 503, 504},
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final retries = err.requestOptions.extra['retries'] ?? 0;

    final shouldRetry = retries < maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            (statusCode != null && retryStatusCodes.contains(statusCode)));

    if (shouldRetry) {
      await Future.delayed(retryDelay * (retries + 1)); // Exponential backoff

      final options = err.requestOptions;
      options.extra['retries'] = retries + 1;

      try {
        final dio = Dio();
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue to error handler
      }
    }

    handler.next(err);
  }
}
```

## Error Handling

### Custom Exceptions

```dart
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class TimeoutException extends ApiException {
  const TimeoutException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.statusCode});
}

class BadRequestException extends ApiException {
  final Map<String, dynamic>? errors;

  const BadRequestException(super.message, {this.errors, super.statusCode});
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode});
}
```

### Error Transformer

```dart
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _transformError(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
    ));
  }

  ApiException _transformError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');

      case DioExceptionType.badResponse:
        return _handleStatusCode(err.response);

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled');

      default:
        return NetworkException(err.message ?? 'Unknown error');
    }
  }

  ApiException _handleStatusCode(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = data is Map ? data['message'] ?? 'Error' : 'Error';

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message,
          errors: data is Map ? data['errors'] : null,
          statusCode: statusCode,
        );
      case 401:
        return UnauthorizedException(message, statusCode: statusCode);
      case 403:
        return UnauthorizedException('Access denied', statusCode: statusCode);
      case 404:
        return NotFoundException(message, statusCode: statusCode);
      case 422:
        return BadRequestException(
          'Validation failed',
          errors: data is Map ? data['errors'] : null,
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(message, statusCode: statusCode);
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }
}
```

## Request Cancellation

```dart
class SearchService {
  final Dio _dio;
  CancelToken? _cancelToken;

  SearchService(this._dio);

  Future<List<SearchResult>> search(String query) async {
    // Cancel previous request
    _cancelToken?.cancel('New search initiated');
    _cancelToken = CancelToken();

    try {
      final response = await _dio.get<List>(
        '/search',
        queryParameters: {'q': query},
        cancelToken: _cancelToken,
      );
      return response.data!.map((e) => SearchResult.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return []; // Silently handle cancellation
      }
      rethrow;
    }
  }

  void dispose() {
    _cancelToken?.cancel('Service disposed');
  }
}
```

## HTTP Package Alternative

### Basic HTTP Client

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpApiClient {
  final http.Client _client;
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  HttpApiClient({
    http.Client? client,
    required this.baseUrl,
    this.defaultHeaders = const {},
  }) : _client = client ?? http.Client();

  Future<T> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final response = await _client.get(uri, headers: defaultHeaders);
    _checkResponse(response);

    final data = jsonDecode(response.body);
    return fromJson != null ? fromJson(data) : data as T;
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    T Function(dynamic)? fromJson,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final response = await _client.post(
      uri,
      headers: {...defaultHeaders, 'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);

    final data = jsonDecode(response.body);
    return fromJson != null ? fromJson(data) : data as T;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw HttpException(
        response.statusCode,
        response.body,
      );
    }
  }

  void close() => _client.close();
}

class HttpException implements Exception {
  final int statusCode;
  final String body;

  HttpException(this.statusCode, this.body);

  @override
  String toString() => 'HttpException: $statusCode - $body';
}
```

### HTTP with Retry

```dart
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class RetryHttpClient {
  late final http.Client _client;

  RetryHttpClient({
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) {
    _client = RetryClient(
      http.Client(),
      retries: retries,
      delay: (_) => delay,
      when: (response) => response.statusCode >= 500,
      whenError: (error, _) => error is http.ClientException,
    );
  }

  Future<http.Response> get(Uri url) => _client.get(url);

  void close() => _client.close();
}
```

## File Upload/Download

### Upload with Progress

```dart
Future<String> uploadFile(
  File file, {
  void Function(int sent, int total)? onProgress,
}) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      file.path,
      filename: file.path.split('/').last,
    ),
  });

  final response = await _dio.post(
    '/upload',
    data: formData,
    onSendProgress: onProgress,
  );

  return response.data['url'];
}
```

### Download with Progress

```dart
Future<File> downloadFile(
  String url,
  String savePath, {
  void Function(int received, int total)? onProgress,
  CancelToken? cancelToken,
}) async {
  await _dio.download(
    url,
    savePath,
    onReceiveProgress: onProgress,
    cancelToken: cancelToken,
  );

  return File(savePath);
}
```

## Testing API Clients

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiClient apiClient;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    apiClient = ApiClient(dio: dio);
  });

  test('fetches user successfully', () async {
    dioAdapter.onGet(
      '/users/1',
      (server) => server.reply(200, {'id': 1, 'name': 'John'}),
    );

    final user = await apiClient.getUser('1');

    expect(user.name, 'John');
  });

  test('handles 404 error', () async {
    dioAdapter.onGet(
      '/users/999',
      (server) => server.reply(404, {'message': 'Not found'}),
    );

    expect(
      () => apiClient.getUser('999'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('retries on 503', () async {
    var attempts = 0;
    dioAdapter.onGet(
      '/status',
      (server) {
        attempts++;
        if (attempts < 3) {
          server.reply(503, 'Service unavailable');
        } else {
          server.reply(200, {'status': 'ok'});
        }
      },
    );

    final result = await apiClient.getStatus();

    expect(result, 'ok');
    expect(attempts, 3);
  });
}
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `DioException: Connection refused` | Check baseUrl and network connectivity |
| `Certificate error` | Add `badCertificateCallback` for dev/testing |
| `Timeout` | Increase timeout or check network |
| `401 loop` | Check token refresh logic for infinite recursion |
| `JSON parse error` | Verify response content-type and data format |

## Resources

- **Interceptor Patterns**: See [references/interceptor-patterns.md](references/interceptor-patterns.md)
- **Retry Strategies**: See [references/retry-strategies.md](references/retry-strategies.md)
