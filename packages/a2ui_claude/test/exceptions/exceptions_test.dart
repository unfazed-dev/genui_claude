import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiException hierarchy', () {
    group('ToolConversionException', () {
      test('creates with message and tool name', () {
        const exception = ToolConversionException(
          'Invalid schema',
          'my_tool',
        );

        expect(exception.message, 'Invalid schema');
        expect(exception.toolName, 'my_tool');
        expect(exception.invalidSchema, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('creates with invalid schema', () {
        const exception = ToolConversionException(
          'Invalid schema',
          'my_tool',
          {'invalid': 'data'},
        );

        expect(exception.invalidSchema, {'invalid': 'data'});
      });

      test('creates with stack trace', () {
        final trace = StackTrace.current;
        final exception = ToolConversionException(
          'Error',
          'tool',
          null,
          trace,
        );

        expect(exception.stackTrace, trace);
      });

      test('toString includes tool name', () {
        const exception = ToolConversionException(
          'Schema error',
          'widget_tool',
        );

        expect(
          exception.toString(),
          'ToolConversionException: Schema error (tool: widget_tool)',
        );
      });

      test('is A2uiException', () {
        const exception = ToolConversionException('msg', 'tool');
        expect(exception, isA<A2uiException>());
      });
    });

    group('MessageParseException', () {
      test('creates with message only', () {
        const exception = MessageParseException('Parse failed');

        expect(exception.message, 'Parse failed');
        expect(exception.rawContent, isNull);
        expect(exception.expectedFormat, isNull);
      });

      test('creates with raw content', () {
        const exception = MessageParseException(
          'Parse failed',
          '{"invalid": json}',
        );

        expect(exception.rawContent, '{"invalid": json}');
      });

      test('creates with expected format', () {
        const exception = MessageParseException(
          'Parse failed',
          'bad content',
          'JSON object',
        );

        expect(exception.expectedFormat, 'JSON object');
      });

      test('creates with stack trace', () {
        final trace = StackTrace.current;
        final exception = MessageParseException(
          'Error',
          null,
          null,
          trace,
        );

        expect(exception.stackTrace, trace);
      });

      test('toString shows message', () {
        const exception = MessageParseException('Invalid JSON');

        expect(exception.toString(), 'MessageParseException: Invalid JSON');
      });

      test('is A2uiException', () {
        const exception = MessageParseException('msg');
        expect(exception, isA<A2uiException>());
      });
    });

    group('StreamException', () {
      test('creates with message only', () {
        const exception = StreamException('Connection lost');

        expect(exception.message, 'Connection lost');
        expect(exception.httpStatusCode, isNull);
        expect(exception.isRetryable, isFalse);
      });

      test('creates with HTTP status code', () {
        const exception = StreamException(
          'Server error',
          httpStatusCode: 500,
        );

        expect(exception.httpStatusCode, 500);
      });

      test('creates with retryable flag', () {
        const exception = StreamException(
          'Timeout',
          isRetryable: true,
        );

        expect(exception.isRetryable, isTrue);
      });

      test('creates with all parameters', () {
        final trace = StackTrace.current;
        final exception = StreamException(
          'Rate limited',
          httpStatusCode: 429,
          isRetryable: true,
          stackTrace: trace,
        );

        expect(exception.httpStatusCode, 429);
        expect(exception.isRetryable, isTrue);
        expect(exception.stackTrace, trace);
      });

      test('toString includes HTTP status when present', () {
        const exception = StreamException(
          'Error',
          httpStatusCode: 503,
        );

        expect(exception.toString(), 'StreamException: Error (HTTP 503)');
      });

      test('toString without HTTP status', () {
        const exception = StreamException('Error');

        expect(exception.toString(), 'StreamException: Error');
      });

      test('is A2uiException', () {
        const exception = StreamException('msg');
        expect(exception, isA<A2uiException>());
      });
    });

    group('ValidationException', () {
      test('creates with message and errors', () {
        const errors = [
          ValidationError(
            field: 'name',
            message: 'Required',
            code: 'required',
          ),
        ];
        const exception = ValidationException('Validation failed', errors);

        expect(exception.message, 'Validation failed');
        expect(exception.errors, hasLength(1));
        expect(exception.errors.first.field, 'name');
      });

      test('creates with multiple errors', () {
        const errors = [
          ValidationError(field: 'name', message: 'Required', code: 'required'),
          ValidationError(field: 'email', message: 'Invalid', code: 'format'),
          ValidationError(field: 'age', message: 'Too low', code: 'min'),
        ];
        const exception = ValidationException('Invalid input', errors);

        expect(exception.errors, hasLength(3));
      });

      test('creates with stack trace', () {
        final trace = StackTrace.current;
        final exception = ValidationException(
          'Error',
          const [],
          trace,
        );

        expect(exception.stackTrace, trace);
      });

      test('toString shows error count', () {
        const errors = [
          ValidationError(field: 'a', message: 'm', code: 'c'),
          ValidationError(field: 'b', message: 'm', code: 'c'),
        ];
        const exception = ValidationException('Failed', errors);

        expect(
          exception.toString(),
          'ValidationException: Failed (2 errors)',
        );
      });

      test('is A2uiException', () {
        const exception = ValidationException('msg', []);
        expect(exception, isA<A2uiException>());
      });
    });

    group('ValidationError', () {
      test('creates with required fields', () {
        const error = ValidationError(
          field: 'email',
          message: 'Invalid email format',
          code: 'invalid_format',
        );

        expect(error.field, 'email');
        expect(error.message, 'Invalid email format');
        expect(error.code, 'invalid_format');
      });

      test('toString shows field and message', () {
        const error = ValidationError(
          field: 'password',
          message: 'Too short',
          code: 'min_length',
        );

        expect(error.toString(), 'password: Too short (min_length)');
      });
    });

    group('exhaustive pattern matching', () {
      test('can match all exception types', () {
        String describeException(A2uiException e) {
          return switch (e) {
            ToolConversionException(:final toolName) => 'tool: $toolName',
            MessageParseException(:final rawContent) =>
              'parse: ${rawContent ?? 'no content'}',
            StreamException(:final httpStatusCode) =>
              'stream: ${httpStatusCode ?? 'no code'}',
            ValidationException(:final errors) => 'validation: ${errors.length}',
          };
        }

        expect(
          describeException(const ToolConversionException('msg', 'my_tool')),
          'tool: my_tool',
        );
        expect(
          describeException(const MessageParseException('msg', 'raw')),
          'parse: raw',
        );
        expect(
          describeException(const StreamException('msg', httpStatusCode: 500)),
          'stream: 500',
        );
        expect(
          describeException(const ValidationException('msg', [])),
          'validation: 0',
        );
      });
    });
  });
}
