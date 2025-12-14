import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

import '../mocks/mock_generators.dart';

void main() {
  group('Error Handling Widget Tests', () {
    late MockAnthropicContentGenerator mockGenerator;

    setUp(() {
      mockGenerator = MockAnthropicContentGenerator();
    });

    tearDown(() {
      mockGenerator.dispose();
    });

    group('Error Type Display', () {
      testWidgets('displays network error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(
              message: 'Connection failed',
              requestId: 'req-123',
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Network Error'), findsOneWidget);
        expect(find.text('Connection failed'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget); // Retryable
      });

      testWidgets('displays timeout error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const TimeoutException(
              message: 'Request timed out after 60s',
              timeout: Duration(seconds: 60),
              requestId: 'req-456',
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Timeout Error'), findsOneWidget);
        expect(find.text('Request timed out after 60s'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget); // Retryable
      });

      testWidgets('displays authentication error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const AuthenticationException(
              message: 'Invalid API key',
              statusCode: 401,
              requestId: 'req-789',
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Authentication Error'), findsOneWidget);
        expect(find.text('Invalid API key'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsNothing); // Not retryable
        expect(find.byIcon(Icons.login), findsOneWidget); // Login action
      });

      testWidgets('displays rate limit error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const RateLimitException(
              message: 'Rate limit exceeded',
              requestId: 'req-101',
              retryAfter: Duration(seconds: 30),
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Rate Limit'), findsOneWidget);
        expect(find.text('Rate limit exceeded'), findsOneWidget);
        expect(find.text('Retry in 30 seconds'), findsOneWidget);
      });

      testWidgets('displays circuit breaker error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            CircuitBreakerOpenException(
              message: 'Circuit breaker is open',
              recoveryTime: DateTime.now().add(const Duration(seconds: 30)),
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Service Unavailable'), findsOneWidget);
        expect(find.text('Circuit breaker is open'), findsOneWidget);
      });

      testWidgets('displays validation error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const ValidationException(
              message: 'Invalid request format',
              statusCode: 400,
              requestId: 'req-102',
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Validation Error'), findsOneWidget);
        expect(find.text('Invalid request format'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsNothing); // Not retryable
      });

      testWidgets('displays server error correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const ServerException(
              message: 'Internal server error',
              statusCode: 500,
              requestId: 'req-103',
            ),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Server Error'), findsOneWidget);
        expect(find.text('Internal server error'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget); // Retryable
      });
    });

    group('Retry Functionality', () {
      testWidgets('retry button triggers callback', (tester) async {
        var retryCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _RetryWidget(
                generator: mockGenerator,
                onRetry: () => retryCalled = true,
              ),
            ),
          ),
        );

        // Emit retryable error
        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(message: 'Connection failed'),
            StackTrace.current,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(retryCalled, isTrue);
      });

      testWidgets('retry clears error state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _RetryWidget(
                generator: mockGenerator,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Emit error
        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(message: 'Connection failed'),
            StackTrace.current,
          ),
        );
        await tester.pump();

        expect(find.text('Connection failed'), findsOneWidget);

        // Tap retry
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(find.text('Connection failed'), findsNothing);
      });
    });

    group('Error During Processing', () {
      testWidgets('shows error and stops processing indicator', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ProcessingErrorWidget(generator: mockGenerator),
            ),
          ),
        );

        // Start processing
        mockGenerator.setProcessing(true);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Emit error
        mockGenerator
          ..emitError(
            ContentGeneratorError(
              const ServerException(message: 'Server error', statusCode: 500),
              StackTrace.current,
            ),
          )
          ..setProcessing(false);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Server error'), findsOneWidget);
      });
    });

    group('Multiple Errors', () {
      testWidgets('displays latest error only', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorTypeWidget(generator: mockGenerator),
            ),
          ),
        );

        // Emit first error
        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(message: 'First error'),
            StackTrace.current,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('First error'), findsOneWidget);

        // Emit second error
        mockGenerator.emitError(
          ContentGeneratorError(
            const TimeoutException(
              message: 'Second error',
              timeout: Duration(seconds: 60),
            ),
            StackTrace.current,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('First error'), findsNothing);
        expect(find.text('Second error'), findsOneWidget);
      });
    });

    group('Error Recovery', () {
      testWidgets('error clears after successful response', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorRecoveryWidget(generator: mockGenerator),
            ),
          ),
        );

        // Emit error
        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(message: 'Connection failed'),
            StackTrace.current,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Connection failed'), findsOneWidget);

        // Emit successful response
        mockGenerator.emitText('Success!');
        await tester.pumpAndSettle();

        expect(find.text('Connection failed'), findsNothing);
        expect(find.text('Success!'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('error message is accessible', (tester) async {
        final semanticsHandle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _AccessibleErrorWidget(generator: mockGenerator),
            ),
          ),
        );

        mockGenerator.emitError(
          ContentGeneratorError(
            const NetworkException(message: 'Connection failed'),
            StackTrace.current,
          ),
        );
        await tester.pumpAndSettle();

        // Find Semantics widget - look for the Semantics wrapper
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Error: Connection failed',
          ),
          findsOneWidget,
        );

        semanticsHandle.dispose();
      });
    });
  });
}

// Test Helper Widgets

class _ErrorTypeWidget extends StatefulWidget {
  const _ErrorTypeWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_ErrorTypeWidget> createState() => _ErrorTypeWidgetState();
}

class _ErrorTypeWidgetState extends State<_ErrorTypeWidget> {
  ContentGeneratorError? _error;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return const SizedBox();

    final exception = _error!.error;
    String title;
    IconData? actionIcon;

    if (exception is NetworkException) {
      title = 'Network Error';
      actionIcon = Icons.refresh;
    } else if (exception is TimeoutException) {
      title = 'Timeout Error';
      actionIcon = Icons.refresh;
    } else if (exception is AuthenticationException) {
      title = 'Authentication Error';
      actionIcon = Icons.login;
    } else if (exception is RateLimitException) {
      title = 'Rate Limit';
    } else if (exception is CircuitBreakerOpenException) {
      title = 'Service Unavailable';
    } else if (exception is ValidationException) {
      title = 'Validation Error';
    } else if (exception is ServerException) {
      title = 'Server Error';
      actionIcon = Icons.refresh;
    } else {
      title = 'Error';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(_getErrorMessage(exception)),
        if (exception is RateLimitException && exception.retryAfter != null)
          Text('Retry in ${exception.retryAfter!.inSeconds} seconds'),
        if (actionIcon != null) Icon(actionIcon),
      ],
    );
  }

  String _getErrorMessage(Object exception) {
    if (exception is AnthropicException) {
      return exception.message;
    }
    return exception.toString();
  }
}

class _RetryWidget extends StatefulWidget {
  const _RetryWidget({
    required this.generator,
    required this.onRetry,
  });

  final ContentGenerator generator;
  final VoidCallback onRetry;

  @override
  State<_RetryWidget> createState() => _RetryWidgetState();
}

class _RetryWidgetState extends State<_RetryWidget> {
  ContentGeneratorError? _error;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() => _error = error);
    });
  }

  void _handleRetry() {
    setState(() => _error = null);
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return const SizedBox();

    final exception = _error!.error;
    final isRetryable =
        exception is AnthropicException && exception.isRetryable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_getErrorMessage(exception)),
        if (isRetryable)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRetry,
          ),
      ],
    );
  }

  String _getErrorMessage(Object exception) {
    if (exception is AnthropicException) {
      return exception.message;
    }
    return exception.toString();
  }
}

class _ProcessingErrorWidget extends StatefulWidget {
  const _ProcessingErrorWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_ProcessingErrorWidget> createState() => _ProcessingErrorWidgetState();
}

class _ProcessingErrorWidgetState extends State<_ProcessingErrorWidget> {
  ContentGeneratorError? _error;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.generator.isProcessing,
      builder: (_, isProcessing, __) {
        if (isProcessing) {
          return const CircularProgressIndicator();
        }

        if (_error != null) {
          final exception = _error!.error;
          return Text(_getErrorMessage(exception));
        }

        return const SizedBox();
      },
    );
  }

  String _getErrorMessage(Object exception) {
    if (exception is AnthropicException) {
      return exception.message;
    }
    return exception.toString();
  }
}

class _ErrorRecoveryWidget extends StatefulWidget {
  const _ErrorRecoveryWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_ErrorRecoveryWidget> createState() => _ErrorRecoveryWidgetState();
}

class _ErrorRecoveryWidgetState extends State<_ErrorRecoveryWidget> {
  ContentGeneratorError? _error;
  String? _response;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() {
        _error = error;
        _response = null;
      });
    });
    widget.generator.textResponseStream.listen((text) {
      setState(() {
        _error = null;
        _response = text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final exception = _error!.error;
      return Text(_getErrorMessage(exception));
    }

    if (_response != null) {
      return Text(_response!);
    }

    return const SizedBox();
  }

  String _getErrorMessage(Object exception) {
    if (exception is AnthropicException) {
      return exception.message;
    }
    return exception.toString();
  }
}

class _AccessibleErrorWidget extends StatefulWidget {
  const _AccessibleErrorWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_AccessibleErrorWidget> createState() => _AccessibleErrorWidgetState();
}

class _AccessibleErrorWidgetState extends State<_AccessibleErrorWidget> {
  ContentGeneratorError? _error;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return const SizedBox();

    final exception = _error!.error;
    final message = _getErrorMessage(exception);

    return Semantics(
      label: 'Error: $message',
      child: Container(
        color: Colors.red.shade100,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object exception) {
    if (exception is AnthropicException) {
      return exception.message;
    }
    return exception.toString();
  }
}
