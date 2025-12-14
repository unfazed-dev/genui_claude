import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../helpers/test_utils.dart';
import '../mocks/mock_generators.dart';

void main() {
  group('ContentGenerator Widget Integration', () {
    late MockAnthropicContentGenerator mockGenerator;

    setUp(() {
      mockGenerator = MockAnthropicContentGenerator();
    });

    tearDown(() {
      mockGenerator.dispose();
    });

    group('isProcessing ValueListenable', () {
      testWidgets('renders correctly when not processing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mockGenerator.isProcessing,
                builder: (_, isProcessing, __) {
                  return Text(isProcessing ? 'Processing...' : 'Ready');
                },
              ),
            ),
          ),
        );

        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('Processing...'), findsNothing);
      });

      testWidgets('updates when processing state changes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mockGenerator.isProcessing,
                builder: (_, isProcessing, __) {
                  return Text(isProcessing ? 'Processing...' : 'Ready');
                },
              ),
            ),
          ),
        );

        expect(find.text('Ready'), findsOneWidget);

        // Simulate processing
        mockGenerator.setProcessing(true);
        await tester.pump();

        expect(find.text('Processing...'), findsOneWidget);
        expect(find.text('Ready'), findsNothing);

        // Finish processing
        mockGenerator.setProcessing(false);
        await tester.pump();

        expect(find.text('Ready'), findsOneWidget);
      });

      testWidgets('shows loading indicator while processing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mockGenerator.isProcessing,
                builder: (_, isProcessing, __) {
                  if (isProcessing) {
                    return const CircularProgressIndicator();
                  }
                  return const Text('Ready');
                },
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNothing);

        mockGenerator.setProcessing(true);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Stream Listening', () {
      testWidgets('receives text responses from stream', (tester) async {
        final textResponses = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _StreamListenerWidget(
                generator: mockGenerator,
                onTextResponse: textResponses.add,
              ),
            ),
          ),
        );

        // Emit text responses
        mockGenerator.emitText('Hello');
        await tester.pump();
        mockGenerator.emitText(' World');
        await tester.pump();

        expect(textResponses, ['Hello', ' World']);
      });

      testWidgets('receives A2UI messages from stream', (tester) async {
        final a2uiMessages = <A2uiMessage>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _StreamListenerWidget(
                generator: mockGenerator,
                onA2uiMessage: a2uiMessages.add,
              ),
            ),
          ),
        );

        // Emit A2UI messages
        const beginRendering = BeginRendering(
          surfaceId: 'test-surface',
          root: 'root',
        );
        mockGenerator.emitA2uiMessage(beginRendering);
        await tester.pump();

        expect(a2uiMessages, hasLength(1));
        expect(a2uiMessages.first, isBeginRendering(surfaceId: 'test-surface'));
      });

      testWidgets('receives errors from stream', (tester) async {
        final errors = <ContentGeneratorError>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _StreamListenerWidget(
                generator: mockGenerator,
                onError: errors.add,
              ),
            ),
          ),
        );

        // Emit error
        mockGenerator.emitError(
          ContentGeneratorError('Test error', StackTrace.current),
        );
        await tester.pump();

        expect(errors, hasLength(1));
        expect(errors.first.error, 'Test error');
      });
    });

    group('sendRequest Integration', () {
      testWidgets('isProcessing lifecycle can be simulated', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mockGenerator.isProcessing,
                builder: (_, isProcessing, __) {
                  return Text(isProcessing ? 'Processing' : 'Idle');
                },
              ),
            ),
          ),
        );

        // Initial state
        expect(find.text('Idle'), findsOneWidget);

        // Simulate start of request
        mockGenerator.setProcessing(true);
        await tester.pump();
        expect(find.text('Processing'), findsOneWidget);

        // Simulate end of request
        mockGenerator.setProcessing(false);
        await tester.pump();
        expect(find.text('Idle'), findsOneWidget);
      });

      testWidgets('direct emit triggers stream listeners', (tester) async {
        final textResponses = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _StreamListenerWidget(
                generator: mockGenerator,
                onTextResponse: textResponses.add,
              ),
            ),
          ),
        );

        // Direct emit bypasses sendRequest async flow
        mockGenerator.emitText('Hello from Claude!');
        await tester.pump();

        expect(textResponses, ['Hello from Claude!']);
      });
    });

    group('Error Banner Integration', () {
      testWidgets('error banner appears on error event', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorBannerWidget(generator: mockGenerator),
            ),
          ),
        );

        expect(find.text('Error'), findsNothing);

        // Emit error
        mockGenerator.emitError(
          ContentGeneratorError('Network failed', StackTrace.current),
        );
        await tester.pump();

        expect(find.text('Error: Network failed'), findsOneWidget);
      });

      testWidgets('error banner can be dismissed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ErrorBannerWidget(generator: mockGenerator),
            ),
          ),
        );

        // Emit error
        mockGenerator.emitError(
          ContentGeneratorError('Test error', StackTrace.current),
        );
        await tester.pump();

        expect(find.text('Error: Test error'), findsOneWidget);

        // Dismiss
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(find.text('Error: Test error'), findsNothing);
      });
    });

    group('Dispose', () {
      testWidgets('generator can be disposed without error', (tester) async {
        final generator = MockAnthropicContentGenerator();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: generator.isProcessing,
                builder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        );

        // Dispose should not throw
        expect(generator.dispose, returnsNormally);
      });

      testWidgets('widget unmounts cleanly after dispose', (tester) async {
        final generator = MockAnthropicContentGenerator();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _DisposableWidget(generator: generator),
            ),
          ),
        );

        expect(find.text('Widget Active'), findsOneWidget);

        // Navigate away (unmount)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Other Page')),
          ),
        );

        expect(find.text('Other Page'), findsOneWidget);
        expect(find.text('Widget Active'), findsNothing);
      });
    });
  });
}

// Test Helper Widgets

class _StreamListenerWidget extends StatefulWidget {
  const _StreamListenerWidget({
    required this.generator,
    this.onTextResponse,
    this.onA2uiMessage,
    this.onError,
  });

  final ContentGenerator generator;
  final void Function(String)? onTextResponse;
  final void Function(A2uiMessage)? onA2uiMessage;
  final void Function(ContentGeneratorError)? onError;

  @override
  State<_StreamListenerWidget> createState() => _StreamListenerWidgetState();
}

class _StreamListenerWidgetState extends State<_StreamListenerWidget> {
  @override
  void initState() {
    super.initState();
    widget.generator.textResponseStream.listen(widget.onTextResponse);
    widget.generator.a2uiMessageStream.listen(widget.onA2uiMessage);
    widget.generator.errorStream.listen(widget.onError);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _ErrorBannerWidget extends StatefulWidget {
  const _ErrorBannerWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_ErrorBannerWidget> createState() => _ErrorBannerWidgetState();
}

class _ErrorBannerWidgetState extends State<_ErrorBannerWidget> {
  ContentGeneratorError? _error;

  @override
  void initState() {
    super.initState();
    widget.generator.errorStream.listen((error) {
      setState(() => _error = error);
    });
  }

  void _dismiss() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return const SizedBox();

    return MaterialBanner(
      content: Text('Error: ${_error!.error}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _dismiss,
        ),
      ],
    );
  }
}

class _DisposableWidget extends StatefulWidget {
  const _DisposableWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_DisposableWidget> createState() => _DisposableWidgetState();
}

class _DisposableWidgetState extends State<_DisposableWidget> {
  @override
  void dispose() {
    widget.generator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Widget Active');
}
