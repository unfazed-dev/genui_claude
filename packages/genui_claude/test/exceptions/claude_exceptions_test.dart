import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/exceptions/claude_exceptions.dart';

void main() {
  group('ClaudeException hierarchy', () {
    group('NetworkException', () {
      test('creates with required message', () {
        const exception = NetworkException(message: 'Connection failed');

        expect(exception.message, equals('Connection failed'));
        expect(exception.statusCode, isNull);
      });

      test('creates with optional fields', () {
        final stackTrace = StackTrace.current;
        final originalError = Exception('Original');

        final exception = NetworkException(
          message: 'DNS lookup failed',
          requestId: 'req-123',
          originalError: originalError,
          stackTrace: stackTrace,
        );

        expect(exception.requestId, equals('req-123'));
        expect(exception.originalError, equals(originalError));
        expect(exception.stackTrace, equals(stackTrace));
      });

      test('isRetryable returns true', () {
        const exception = NetworkException(message: 'test');

        expect(exception.isRetryable, isTrue);
      });

      test('typeName returns NetworkException', () {
        const exception = NetworkException(message: 'test');

        expect(exception.typeName, equals('NetworkException'));
      });

      test('toString includes message and optional fields', () {
        const exception = NetworkException(
          message: 'Connection refused',
          requestId: 'req-456',
        );

        final str = exception.toString();

        expect(str, contains('NetworkException'));
        expect(str, contains('Connection refused'));
        expect(str, contains('req-456'));
      });
    });

    group('TimeoutException', () {
      test('creates with required fields', () {
        const exception = TimeoutException(
          message: 'Request timed out',
          timeout: Duration(seconds: 30),
        );

        expect(exception.message, equals('Request timed out'));
        expect(exception.timeout, equals(const Duration(seconds: 30)));
        expect(exception.statusCode, isNull);
      });

      test('isRetryable returns true', () {
        const exception = TimeoutException(
          message: 'test',
          timeout: Duration(seconds: 60),
        );

        expect(exception.isRetryable, isTrue);
      });

      test('typeName returns TimeoutException', () {
        const exception = TimeoutException(
          message: 'test',
          timeout: Duration(seconds: 60),
        );

        expect(exception.typeName, equals('TimeoutException'));
      });
    });

    group('AuthenticationException', () {
      test('creates with required fields', () {
        const exception = AuthenticationException(
          message: 'Invalid API key',
          statusCode: 401,
        );

        expect(exception.message, equals('Invalid API key'));
        expect(exception.statusCode, equals(401));
      });

      test('creates with 403 status code', () {
        const exception = AuthenticationException(
          message: 'Forbidden',
          statusCode: 403,
        );

        expect(exception.statusCode, equals(403));
      });

      test('isRetryable returns false', () {
        const exception = AuthenticationException(
          message: 'test',
          statusCode: 401,
        );

        expect(exception.isRetryable, isFalse);
      });

      test('typeName returns AuthenticationException', () {
        const exception = AuthenticationException(
          message: 'test',
          statusCode: 401,
        );

        expect(exception.typeName, equals('AuthenticationException'));
      });

      test('toString includes status code', () {
        const exception = AuthenticationException(
          message: 'Unauthorized',
          statusCode: 401,
          requestId: 'req-789',
        );

        final str = exception.toString();

        expect(str, contains('AuthenticationException'));
        expect(str, contains('401'));
        expect(str, contains('req-789'));
      });
    });

    group('RateLimitException', () {
      test('creates with message only', () {
        const exception = RateLimitException(
          message: 'Rate limit exceeded',
        );

        expect(exception.message, equals('Rate limit exceeded'));
        expect(exception.statusCode, equals(429));
        expect(exception.retryAfter, isNull);
      });

      test('creates with retryAfter duration', () {
        const exception = RateLimitException(
          message: 'Too many requests',
          retryAfter: Duration(seconds: 30),
        );

        expect(exception.retryAfter, equals(const Duration(seconds: 30)));
      });

      test('isRetryable returns true', () {
        const exception = RateLimitException(message: 'test');

        expect(exception.isRetryable, isTrue);
      });

      test('typeName returns RateLimitException', () {
        const exception = RateLimitException(message: 'test');

        expect(exception.typeName, equals('RateLimitException'));
      });

      test('always has 429 status code', () {
        const exception = RateLimitException(message: 'test');

        expect(exception.statusCode, equals(429));
      });
    });

    group('ValidationException', () {
      test('creates with required fields', () {
        const exception = ValidationException(
          message: 'Invalid request',
          statusCode: 400,
        );

        expect(exception.message, equals('Invalid request'));
        expect(exception.statusCode, equals(400));
      });

      test('creates with 422 status code', () {
        const exception = ValidationException(
          message: 'Unprocessable entity',
          statusCode: 422,
        );

        expect(exception.statusCode, equals(422));
      });

      test('isRetryable returns false', () {
        const exception = ValidationException(
          message: 'test',
          statusCode: 400,
        );

        expect(exception.isRetryable, isFalse);
      });

      test('typeName returns ValidationException', () {
        const exception = ValidationException(
          message: 'test',
          statusCode: 400,
        );

        expect(exception.typeName, equals('ValidationException'));
      });
    });

    group('ServerException', () {
      test('creates with required fields', () {
        const exception = ServerException(
          message: 'Internal server error',
          statusCode: 500,
        );

        expect(exception.message, equals('Internal server error'));
        expect(exception.statusCode, equals(500));
      });

      test('creates with various 5xx status codes', () {
        const codes = [500, 502, 503, 504];

        for (final code in codes) {
          final exception = ServerException(
            message: 'Error',
            statusCode: code,
          );
          expect(exception.statusCode, equals(code));
        }
      });

      test('isRetryable returns true', () {
        const exception = ServerException(
          message: 'test',
          statusCode: 500,
        );

        expect(exception.isRetryable, isTrue);
      });

      test('typeName returns ServerException', () {
        const exception = ServerException(
          message: 'test',
          statusCode: 500,
        );

        expect(exception.typeName, equals('ServerException'));
      });
    });

    group('StreamException', () {
      test('creates with message', () {
        const exception = StreamException(
          message: 'SSE parsing error',
        );

        expect(exception.message, equals('SSE parsing error'));
        expect(exception.statusCode, isNull);
      });

      test('isRetryable returns false', () {
        const exception = StreamException(message: 'test');

        expect(exception.isRetryable, isFalse);
      });

      test('typeName returns StreamException', () {
        const exception = StreamException(message: 'test');

        expect(exception.typeName, equals('StreamException'));
      });
    });

    group('CircuitBreakerOpenException', () {
      test('creates with message only', () {
        const exception = CircuitBreakerOpenException(
          message: 'Circuit breaker is open',
        );

        expect(exception.message, equals('Circuit breaker is open'));
        expect(exception.statusCode, isNull);
        expect(exception.recoveryTime, isNull);
      });

      test('creates with recoveryTime', () {
        final recoveryTime = DateTime.now().add(const Duration(seconds: 30));
        final exception = CircuitBreakerOpenException(
          message: 'Circuit breaker is open',
          recoveryTime: recoveryTime,
        );

        expect(exception.recoveryTime, equals(recoveryTime));
      });

      test('isRetryable returns true', () {
        const exception = CircuitBreakerOpenException(message: 'test');

        expect(exception.isRetryable, isTrue);
      });

      test('typeName returns CircuitBreakerOpenException', () {
        const exception = CircuitBreakerOpenException(message: 'test');

        expect(exception.typeName, equals('CircuitBreakerOpenException'));
      });
    });
  });

  group('ExceptionFactory', () {
    group('fromHttpStatus', () {
      test('returns AuthenticationException for 401', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 401,
          body: 'Unauthorized',
          requestId: 'req-123',
        );

        expect(exception, isA<AuthenticationException>());
        expect(exception.statusCode, equals(401));
        expect(exception.requestId, equals('req-123'));
      });

      test('returns AuthenticationException for 403', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 403,
          body: 'Forbidden',
        );

        expect(exception, isA<AuthenticationException>());
        expect(exception.statusCode, equals(403));
      });

      test('returns RateLimitException for 429', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 429,
          body: 'Too many requests',
          retryAfter: const Duration(seconds: 60),
        );

        expect(exception, isA<RateLimitException>());
        final rateLimitException = exception as RateLimitException;
        expect(rateLimitException.retryAfter, equals(const Duration(seconds: 60)));
      });

      test('returns ValidationException for 400', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 400,
          body: 'Bad request',
        );

        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, equals(400));
      });

      test('returns ValidationException for 422', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 422,
          body: 'Unprocessable entity',
        );

        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, equals(422));
      });

      test('returns ServerException for 500', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 500,
          body: 'Internal server error',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, equals(500));
      });

      test('returns ServerException for 502', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 502,
          body: 'Bad gateway',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, equals(502));
      });

      test('returns ServerException for 503', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 503,
          body: 'Service unavailable',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, equals(503));
      });

      test('returns ServerException for 504', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 504,
          body: 'Gateway timeout',
        );

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, equals(504));
      });

      test('returns ValidationException for unknown status codes', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 418,
          body: "I'm a teapot",
        );

        expect(exception, isA<ValidationException>());
        expect(exception.statusCode, equals(418));
      });

      test('includes body in error message', () {
        final exception = ExceptionFactory.fromHttpStatus(
          statusCode: 500,
          body: 'Detailed error message',
        );

        expect(exception.message, contains('Detailed error message'));
      });
    });

    group('parseRetryAfter', () {
      test('returns null for null input', () {
        final result = ExceptionFactory.parseRetryAfter(null);

        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = ExceptionFactory.parseRetryAfter('');

        expect(result, isNull);
      });

      test('parses integer seconds', () {
        final result = ExceptionFactory.parseRetryAfter('30');

        expect(result, equals(const Duration(seconds: 30)));
      });

      test('parses large integer seconds', () {
        final result = ExceptionFactory.parseRetryAfter('3600');

        expect(result, equals(const Duration(hours: 1)));
      });

      test('parses ISO 8601 date format', () {
        final futureDate = DateTime.now().add(const Duration(minutes: 5));
        final result = ExceptionFactory.parseRetryAfter(futureDate.toIso8601String());

        expect(result, isNotNull);
        // Should be approximately 5 minutes (allow some tolerance)
        expect(result!.inMinutes, closeTo(5, 1));
      });

      test('returns zero duration for past date', () {
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final result = ExceptionFactory.parseRetryAfter(pastDate.toIso8601String());

        expect(result, equals(Duration.zero));
      });

      test('returns null for invalid format', () {
        final result = ExceptionFactory.parseRetryAfter('invalid-date');

        expect(result, isNull);
      });

      test('returns null for non-numeric non-date string', () {
        final result = ExceptionFactory.parseRetryAfter('abc');

        expect(result, isNull);
      });
    });
  });

  group('isRetryable categorization', () {
    test('network errors are retryable', () {
      const exception = NetworkException(message: 'test');
      expect(exception.isRetryable, isTrue);
    });

    test('timeout errors are retryable', () {
      const exception = TimeoutException(
        message: 'test',
        timeout: Duration(seconds: 30),
      );
      expect(exception.isRetryable, isTrue);
    });

    test('authentication errors are not retryable', () {
      const exception = AuthenticationException(
        message: 'test',
        statusCode: 401,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('rate limit errors are retryable', () {
      const exception = RateLimitException(message: 'test');
      expect(exception.isRetryable, isTrue);
    });

    test('validation errors are not retryable', () {
      const exception = ValidationException(
        message: 'test',
        statusCode: 400,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('server errors are retryable', () {
      const exception = ServerException(
        message: 'test',
        statusCode: 500,
      );
      expect(exception.isRetryable, isTrue);
    });

    test('stream errors are not retryable', () {
      const exception = StreamException(message: 'test');
      expect(exception.isRetryable, isFalse);
    });

    test('circuit breaker open errors are retryable', () {
      const exception = CircuitBreakerOpenException(message: 'test');
      expect(exception.isRetryable, isTrue);
    });
  });
}
