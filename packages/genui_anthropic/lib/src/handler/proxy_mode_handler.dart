import 'dart:async' as async;
import 'dart:convert';

import 'package:genui_anthropic/src/config/anthropic_config.dart';
import 'package:genui_anthropic/src/config/retry_config.dart';
import 'package:genui_anthropic/src/exceptions/anthropic_exceptions.dart';
import 'package:genui_anthropic/src/handler/api_handler.dart';
import 'package:genui_anthropic/src/metrics/metrics_collector.dart';
import 'package:genui_anthropic/src/resilience/circuit_breaker.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('ProxyModeHandler');
const _uuid = Uuid();

/// Handler for backend proxy API access with production resilience.
///
/// Sends requests to a backend proxy that handles Claude API calls,
/// keeping the API key secure on the server.
///
/// Features:
/// - Automatic retry with exponential backoff
/// - Rate limit detection and handling
/// - Circuit breaker for cascading failure prevention
/// - Request ID tracking for debugging
/// - Stream inactivity timeout
///
/// The proxy should:
/// 1. Accept requests in Claude API format
/// 2. Add the API key server-side
/// 3. Forward to Claude API
/// 4. Stream SSE responses back unchanged
///
/// Example:
/// ```dart
/// final handler = ProxyModeHandler(
///   endpoint: Uri.parse('https://your-server.com/api/chat'),
///   authToken: 'user-jwt-token',
/// );
///
/// final request = ApiRequest(
///   messages: [{'role': 'user', 'content': 'Hello!'}],
///   maxTokens: 4096,
/// );
///
/// await for (final event in handler.createStream(request)) {
///   print(event);
/// }
/// ```
class ProxyModeHandler implements ApiHandler {
  /// Creates a proxy mode handler with production resilience.
  ///
  /// - [endpoint]: The backend proxy URL (must have http or https scheme)
  /// - [authToken]: Optional auth token (sent as Bearer token)
  /// - [config]: Optional configuration for timeouts, retries, headers
  /// - [retryConfig]: Optional retry configuration
  /// - [circuitBreaker]: Optional circuit breaker instance
  /// - [streamInactivityTimeout]: Timeout for stream inactivity
  /// - [metricsCollector]: Optional metrics collector for observability
  /// - [client]: Optional HTTP client for testing/customization
  ///
  /// Throws [AssertionError] if [endpoint] does not have http or https scheme.
  ProxyModeHandler({
    required Uri endpoint,
    String? authToken,
    ProxyConfig config = ProxyConfig.defaults,
    RetryConfig? retryConfig,
    CircuitBreaker? circuitBreaker,
    Duration? streamInactivityTimeout,
    MetricsCollector? metricsCollector,
    http.Client? client,
  })  : assert(
          endpoint.scheme == 'http' || endpoint.scheme == 'https',
          'endpoint must have http or https scheme',
        ),
        _endpoint = endpoint,
        _authToken = authToken,
        _config = config,
        _retryConfig = retryConfig ?? RetryConfig.defaults,
        _circuitBreaker = circuitBreaker,
        _streamInactivityTimeout =
            streamInactivityTimeout ?? const Duration(seconds: 60),
        _metricsCollector = metricsCollector,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri _endpoint;
  final String? _authToken;
  final ProxyConfig _config;
  final RetryConfig _retryConfig;
  final CircuitBreaker? _circuitBreaker;
  final Duration _streamInactivityTimeout;
  final MetricsCollector? _metricsCollector;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Stream<Map<String, dynamic>> createStream(ApiRequest request) async* {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();
    _log.fine('[Request $requestId] Starting proxy request');

    // Record request start
    _metricsCollector?.recordRequestStart(
      requestId: requestId,
      endpoint: _endpoint.toString(),
      model: request.model,
    );

    // Check circuit breaker
    if (_circuitBreaker != null) {
      try {
        _circuitBreaker.checkState();
      } on CircuitBreakerOpenException catch (e) {
        _log.warning('[Request $requestId] Circuit breaker is open');
        _metricsCollector?.recordRequestFailure(
          requestId: requestId,
          duration: DateTime.now().difference(startTime),
          errorType: e.typeName,
          errorMessage: e.message,
          isRetryable: e.isRetryable,
        );
        yield _createErrorEvent(e, requestId);
        return;
      }
    }

    AnthropicException? lastException;
    var attempt = 0;
    var totalRetries = 0;

    while (attempt <= _retryConfig.maxAttempts) {
      try {
        await for (final event in _executeRequest(request, requestId, attempt)) {
          yield event;
        }
        _circuitBreaker?.recordSuccess();
        _metricsCollector?.recordRequestSuccess(
          requestId: requestId,
          duration: DateTime.now().difference(startTime),
          totalRetries: totalRetries,
        );
        return;
      } on RateLimitException catch (e) {
        lastException = e;
        _circuitBreaker?.recordFailure();

        // Record rate limit event
        _metricsCollector?.recordRateLimit(
          retryAfter: e.retryAfter,
          requestId: requestId,
        );

        if (attempt >= _retryConfig.maxAttempts) {
          _log.warning(
            '[Request $requestId] Rate limited, no retries remaining',
          );
          _metricsCollector?.recordRequestFailure(
            requestId: requestId,
            duration: DateTime.now().difference(startTime),
            errorType: e.typeName,
            errorMessage: e.message,
            statusCode: e.statusCode,
            totalRetries: totalRetries,
            isRetryable: e.isRetryable,
          );
          yield _createErrorEvent(e, requestId);
          return;
        }

        // Use Retry-After if available, otherwise use exponential backoff
        final delay = e.retryAfter ?? _retryConfig.getDelayForAttempt(attempt);
        _log.info(
          '[Request $requestId] Rate limited, retrying in ${delay.inMilliseconds}ms '
          '(attempt ${attempt + 1}/${_retryConfig.maxAttempts})',
        );

        // Record retry attempt
        _metricsCollector?.recordRetryAttempt(
          attempt: attempt,
          maxAttempts: _retryConfig.maxAttempts,
          delay: delay,
          reason: 'rate_limit',
          statusCode: e.statusCode,
          requestId: requestId,
        );

        await Future<void>.delayed(delay);
        attempt++;
        totalRetries++;
      } on AnthropicException catch (e) {
        lastException = e;
        _circuitBreaker?.recordFailure();

        if (!e.isRetryable || attempt >= _retryConfig.maxAttempts) {
          _log.warning(
            '[Request $requestId] Non-retryable error or max attempts reached',
          );
          _metricsCollector?.recordRequestFailure(
            requestId: requestId,
            duration: DateTime.now().difference(startTime),
            errorType: e.typeName,
            errorMessage: e.message,
            statusCode: e.statusCode,
            totalRetries: totalRetries,
            isRetryable: e.isRetryable,
          );
          yield _createErrorEvent(e, requestId);
          return;
        }

        final delay = _retryConfig.getDelayForAttempt(attempt);
        _log.info(
          '[Request $requestId] Retrying in ${delay.inMilliseconds}ms '
          '(attempt ${attempt + 1}/${_retryConfig.maxAttempts})',
        );

        // Record retry attempt
        _metricsCollector?.recordRetryAttempt(
          attempt: attempt,
          maxAttempts: _retryConfig.maxAttempts,
          delay: delay,
          reason: e.typeName,
          statusCode: e.statusCode,
          requestId: requestId,
        );

        await Future<void>.delayed(delay);
        attempt++;
        totalRetries++;
      }
    }

    // Shouldn't reach here, but handle gracefully
    if (lastException != null) {
      _metricsCollector?.recordRequestFailure(
        requestId: requestId,
        duration: DateTime.now().difference(startTime),
        errorType: lastException.typeName,
        errorMessage: lastException.message,
        statusCode: lastException.statusCode,
        totalRetries: totalRetries,
        isRetryable: lastException.isRetryable,
      );
      yield _createErrorEvent(lastException, requestId);
    }
  }

  /// Executes a single request attempt.
  Stream<Map<String, dynamic>> _executeRequest(
    ApiRequest request,
    String requestId,
    int attempt,
  ) async* {
    try {
      // Build request body for the proxy
      final requestBody = _buildRequestBody(request);

      // Create HTTP request
      final httpRequest = http.Request('POST', _endpoint);
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'X-Request-ID': requestId,
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        ..._config.headers ?? {},
      });
      httpRequest.body = jsonEncode(requestBody);

      _log.fine('[Request $requestId] Sending request (attempt $attempt)');

      // Send request and get streamed response
      final response = await _client.send(httpRequest).timeout(_config.timeout);

      // Check for HTTP errors
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _log.warning(
          '[Request $requestId] HTTP error ${response.statusCode}: $body',
        );

        // Parse Retry-After header for rate limiting
        final retryAfter = ExceptionFactory.parseRetryAfter(
          response.headers['retry-after'],
        );

        throw ExceptionFactory.fromHttpStatus(
          statusCode: response.statusCode,
          body: body,
          requestId: requestId,
          retryAfter: retryAfter,
        );
      }

      // Parse SSE stream with inactivity timeout
      yield* _parseSSEStreamWithTimeout(response.stream, requestId);
    } on async.TimeoutException catch (e, stackTrace) {
      _log.warning(
        '[Request $requestId] Request timed out after ${_config.timeout}',
        e,
        stackTrace,
      );
      throw TimeoutException(
        message: 'Request timed out after ${_config.timeout}',
        timeout: _config.timeout,
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    } on AnthropicException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      _log.warning('[Request $requestId] Request failed', e, stackTrace);
      throw NetworkException(
        message: e.toString(),
        requestId: requestId,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Builds the request body to send to the proxy.
  Map<String, dynamic> _buildRequestBody(ApiRequest request) {
    return {
      'messages': request.messages,
      'max_tokens': request.maxTokens,
      if (request.systemInstruction != null) 'system': request.systemInstruction,
      if (request.tools != null) 'tools': request.tools,
      if (request.model != null) 'model': request.model,
      if (request.temperature != null) 'temperature': request.temperature,
      'stream': true,
    };
  }

  /// Parses SSE stream with inactivity timeout.
  Stream<Map<String, dynamic>> _parseSSEStreamWithTimeout(
    http.ByteStream stream,
    String requestId,
  ) async* {
    final lines = stream.transform(utf8.decoder).transform(const LineSplitter());

    async.Timer? inactivityTimer;
    final completer = async.Completer<void>();

    void resetInactivityTimer() {
      inactivityTimer?.cancel();
      final timerStartTime = DateTime.now();
      inactivityTimer = async.Timer(_streamInactivityTimeout, () {
        _log.warning(
          '[Request $requestId] Stream inactivity timeout after $_streamInactivityTimeout',
        );
        _metricsCollector?.recordStreamInactivity(
          timeout: _streamInactivityTimeout,
          lastActivity: DateTime.now().difference(timerStartTime),
          requestId: requestId,
        );
        completer.completeError(
          TimeoutException(
            message: 'Stream inactivity timeout after $_streamInactivityTimeout',
            timeout: _streamInactivityTimeout,
            requestId: requestId,
          ),
        );
      });
    }

    try {
      resetInactivityTimer();

      await for (final line in lines) {
        // Check if we've timed out
        if (completer.isCompleted) break;

        resetInactivityTimer();

        if (line.isEmpty) continue;

        // SSE format: "data: {...json...}"
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();

          // Skip [DONE] marker (OpenAI-style) or empty data
          if (data == '[DONE]' || data.isEmpty) continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            // Add request ID to events for tracking
            json['_requestId'] = requestId;
            yield json;
          } on FormatException catch (e, stackTrace) {
            _log.warning(
              '[Request $requestId] Failed to parse SSE data: $data',
              e,
              stackTrace,
            );
            yield {
              'type': 'error',
              'error': {'message': 'Failed to parse SSE data: $e'},
              '_requestId': requestId,
            };
          }
        }
      }
    } finally {
      inactivityTimer?.cancel();
    }
  }

  /// Creates an error event from an exception.
  Map<String, dynamic> _createErrorEvent(
    AnthropicException exception,
    String requestId,
  ) {
    return {
      'type': 'error',
      'error': {
        'message': exception.message,
        'type': exception.typeName,
        if (exception.statusCode != null) 'http_status': exception.statusCode,
        'retryable': exception.isRetryable,
      },
      '_requestId': requestId,
    };
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    _log.fine('ProxyModeHandler disposed');
  }
}
