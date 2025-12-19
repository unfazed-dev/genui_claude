import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../mocks/mock_generators.dart';

void main() {
  group('Chat Flow Widget Integration', () {
    late MockClaudeContentGenerator mockGenerator;

    setUp(() {
      mockGenerator = MockClaudeContentGenerator();
    });

    tearDown(() {
      mockGenerator.dispose();
    });

    group('full chat flow', () {
      testWidgets('displays user message and AI response', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Initial state - no messages
        expect(find.text('No messages'), findsOneWidget);

        // Simulate user sending message
        await tester.enterText(find.byType(TextField), 'Hello Claude');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Should show user message
        expect(find.text('Hello Claude'), findsOneWidget);

        // Simulate processing
        mockGenerator.setProcessing(true);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Simulate AI response
        mockGenerator.emitText('Hello! How can I help you?');
        mockGenerator.setProcessing(false);
        await tester.pump();

        expect(find.text('Hello! How can I help you?'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('handles multiple message exchanges', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // First exchange
        await tester.enterText(find.byType(TextField), 'Message 1');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();
        mockGenerator.setProcessing(true);
        await tester.pump();
        mockGenerator.emitText('Response 1');
        await tester.pump();
        mockGenerator.setProcessing(false);
        await tester.pump(); // Process listener callback
        await tester.pump(); // Process setState from _completeResponse

        // Second exchange
        await tester.enterText(find.byType(TextField), 'Message 2');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();
        mockGenerator.setProcessing(true);
        await tester.pump();
        mockGenerator.emitText('Response 2');
        await tester.pump();
        mockGenerator.setProcessing(false);
        await tester.pump();
        await tester.pump();

        // Third exchange
        await tester.enterText(find.byType(TextField), 'Message 3');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();
        mockGenerator.setProcessing(true);
        await tester.pump();
        mockGenerator.emitText('Response 3');
        await tester.pump();
        mockGenerator.setProcessing(false);
        await tester.pump();
        await tester.pump();

        // All messages should be visible
        expect(find.text('Message 1'), findsOneWidget);
        expect(find.text('Response 1'), findsOneWidget);
        expect(find.text('Message 2'), findsOneWidget);
        expect(find.text('Response 2'), findsOneWidget);
        expect(find.text('Message 3'), findsOneWidget);
        expect(find.text('Response 3'), findsOneWidget);
      });
    });

    group('error state transitions', () {
      testWidgets('shows error and allows retry', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Send message
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Processing
        mockGenerator.setProcessing(true);
        await tester.pump();

        // Error occurs
        mockGenerator.emitError(
          ContentGeneratorError('Network error', StackTrace.current),
        );
        mockGenerator.setProcessing(false);
        await tester.pump();

        // Error should be displayed
        expect(find.text('Network error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should be processing again
        mockGenerator.setProcessing(true);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('clears error when new message sent', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Trigger error
        mockGenerator.emitError(
          ContentGeneratorError('Error 1', StackTrace.current),
        );
        await tester.pump();
        expect(find.text('Error 1'), findsOneWidget);

        // Send new message
        await tester.enterText(find.byType(TextField), 'New message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Error should be cleared
        expect(find.text('Error 1'), findsNothing);
      });
    });

    group('loading state management', () {
      testWidgets('disables send button while processing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'Test');

        // Not processing - button enabled
        find.byIcon(Icons.send);
        expect(
          tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
          isNotNull,
        );

        // Start processing
        mockGenerator.setProcessing(true);
        await tester.pump();

        // Button should be disabled (shows loading indicator)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('clears input field after successful send', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Enter text
        await tester.enterText(find.byType(TextField), 'Test message');
        expect(find.text('Test message'), findsOneWidget);

        // Send
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Text field should be cleared
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });
    });

    group('streaming text updates', () {
      testWidgets('shows streaming text progressively', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Send message
        await tester.enterText(find.byType(TextField), 'Tell me a story');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Start streaming response
        mockGenerator.setProcessing(true);
        await tester.pump();

        // Stream text chunks - use different text from user message
        mockGenerator.emitText('Once');
        await tester.pump();
        expect(find.text('Once'), findsOneWidget);

        mockGenerator.emitText(' upon');
        await tester.pump();
        expect(find.text('Once upon'), findsOneWidget);

        mockGenerator.emitText(' a time');
        await tester.pump();
        expect(find.text('Once upon a time'), findsOneWidget);

        mockGenerator.setProcessing(false);
        await tester.pump();
      });
    });

    group('A2UI message handling', () {
      testWidgets('displays A2UI rendering surfaces', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Emit A2UI begin rendering
        const beginRendering = BeginRendering(
          surfaceId: 'test-surface',
          root: 'TestWidget',
        );
        mockGenerator.emitA2uiMessage(beginRendering);
        await tester.pump();

        // Should indicate A2UI content is being rendered
        expect(find.text('Rendering: test-surface'), findsOneWidget);
      });

      testWidgets('handles surface updates', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: mockGenerator),
            ),
          ),
        );

        // Begin rendering
        const beginRendering = BeginRendering(
          surfaceId: 'surface-1',
          root: 'Widget',
        );
        mockGenerator.emitA2uiMessage(beginRendering);
        await tester.pump();

        // Surface update
        const surfaceUpdate = SurfaceUpdate(
          surfaceId: 'surface-1',
          components: [],
        );
        mockGenerator.emitA2uiMessage(surfaceUpdate);
        await tester.pump();

        // Widget should handle update without error
        expect(find.text('Rendering: surface-1'), findsOneWidget);
      });
    });

    group('dispose behavior', () {
      testWidgets('cancels subscriptions on dispose', (tester) async {
        final generator = MockClaudeContentGenerator();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ChatFlowWidget(generator: generator),
            ),
          ),
        );

        // Navigate away to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Other')),
          ),
        );

        // Should not throw when emitting after dispose
        expect(
          () => generator.emitText('After dispose'),
          returnsNormally,
        );

        generator.dispose();
      });
    });
  });
}

/// A comprehensive chat widget for integration testing.
class _ChatFlowWidget extends StatefulWidget {
  const _ChatFlowWidget({required this.generator});

  final ContentGenerator generator;

  @override
  State<_ChatFlowWidget> createState() => _ChatFlowWidgetState();
}

class _ChatFlowWidgetState extends State<_ChatFlowWidget> {
  final _textController = TextEditingController();
  final _messages = <_ChatMessage>[];
  String _currentResponse = '';
  String? _error;
  String? _renderingSurface;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  bool _wasProcessing = false;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      widget.generator.textResponseStream.listen(_onTextResponse),
      widget.generator.a2uiMessageStream.listen(_onA2uiMessage),
      widget.generator.errorStream.listen(_onError),
    ];
    // Listen to processing state changes
    widget.generator.isProcessing.addListener(_onProcessingChanged);
  }

  void _onProcessingChanged() {
    final isProcessing = widget.generator.isProcessing.value;
    // Complete response when processing transitions from true to false
    if (_wasProcessing && !isProcessing && _currentResponse.isNotEmpty) {
      _completeResponse();
    }
    _wasProcessing = isProcessing;
  }

  @override
  void dispose() {
    widget.generator.isProcessing.removeListener(_onProcessingChanged);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _textController.dispose();
    super.dispose();
  }

  void _onTextResponse(String text) {
    setState(() {
      _currentResponse += text;
    });
  }

  void _onA2uiMessage(A2uiMessage message) {
    if (message is BeginRendering) {
      setState(() {
        _renderingSurface = message.surfaceId;
      });
    }
  }

  void _onError(ContentGeneratorError error) {
    setState(() {
      _error = error.error.toString();
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _currentResponse = '';
      _error = null;
    });

    _textController.clear();
  }

  void _completeResponse() {
    if (_currentResponse.isNotEmpty) {
      setState(() {
        _messages.add(_ChatMessage(text: _currentResponse, isUser: false));
        _currentResponse = '';
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty && _renderingSurface == null
              ? const Center(child: Text('No messages'))
              : ListView(
                  children: [
                    ..._messages.map(
                      (m) => ListTile(
                        title: Text(m.text),
                        leading:
                            Icon(m.isUser ? Icons.person : Icons.smart_toy),
                      ),
                    ),
                    if (_currentResponse.isNotEmpty)
                      ListTile(
                        title: Text(_currentResponse),
                        leading: const Icon(Icons.smart_toy),
                      ),
                    if (_renderingSurface != null)
                      ListTile(
                        title: Text('Rendering: $_renderingSurface'),
                        leading: const Icon(Icons.widgets),
                      ),
                  ],
                ),
        ),
        if (_error != null)
          MaterialBanner(
            content: Text(_error!),
            actions: [
              TextButton(onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.generator.isProcessing,
          builder: (_, isProcessing, __) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !isProcessing,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                    ),
                  ),
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}
