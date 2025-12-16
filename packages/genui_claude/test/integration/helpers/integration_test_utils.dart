import 'dart:async';

import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

/// Default timeout for Claude API responses.
const claudeResponseTimeout = Duration(seconds: 60);

/// Extended timeout for complex multi-turn conversations.
const extendedTimeout = Duration(seconds: 90);

/// Creates an [ClaudeContentGenerator] configured for integration testing.
///
/// Uses smaller token limits for faster responses.
ClaudeContentGenerator createIntegrationGenerator({
  required String apiKey,
  String? systemInstruction,
  String model = 'claude-sonnet-4-20250514',
  int maxTokens = 1024,
}) {
  return ClaudeContentGenerator(
    apiKey: apiKey,
    model: model,
    systemInstruction: systemInstruction,
    config: ClaudeConfig(
      maxTokens: maxTokens,
    ),
  );
}

/// Result of an integration test request.
class IntegrationTestResult {
  const IntegrationTestResult({
    required this.a2uiMessages,
    required this.textChunks,
    required this.errors,
    this.timedOut = false,
  });

  /// A2UI messages received from the stream.
  final List<A2uiMessage> a2uiMessages;

  /// Text chunks received from the stream.
  final List<String> textChunks;

  /// Errors received from the stream.
  final List<ContentGeneratorError> errors;

  /// Whether the request timed out.
  final bool timedOut;

  /// Full text response concatenated from chunks.
  String get fullText => textChunks.join();

  /// Whether any errors were received.
  bool get hasErrors => errors.isNotEmpty;

  /// Whether any A2UI messages were received.
  bool get hasA2uiMessages => a2uiMessages.isNotEmpty;

  /// Whether any text response was received.
  bool get hasTextResponse => textChunks.isNotEmpty;
}

/// Sends a request and waits for the response with timeout.
///
/// Collects all stream events (A2UI messages, text chunks, errors)
/// and returns them in an [IntegrationTestResult].
Future<IntegrationTestResult> waitForResponse(
  ClaudeContentGenerator generator,
  ChatMessage message, {
  Iterable<ChatMessage>? history,
  Duration timeout = claudeResponseTimeout,
}) async {
  final a2uiMessages = <A2uiMessage>[];
  final textChunks = <String>[];
  final errors = <ContentGeneratorError>[];

  final completer = Completer<IntegrationTestResult>();

  // Subscribe to all streams
  final subs = <StreamSubscription<dynamic>>[
    generator.a2uiMessageStream.listen(a2uiMessages.add),
    generator.textResponseStream.listen(textChunks.add),
    generator.errorStream.listen(errors.add),
  ];

  // Listen for processing completion
  void onProcessingChanged() {
    if (!generator.isProcessing.value && !completer.isCompleted) {
      completer.complete(
        IntegrationTestResult(
          a2uiMessages: a2uiMessages,
          textChunks: textChunks,
          errors: errors,
        ),
      );
    }
  }

  generator.isProcessing.addListener(onProcessingChanged);

  // Start the request
  await generator.sendRequest(message, history: history);

  // Wait with timeout
  try {
    return await completer.future.timeout(timeout);
  } on TimeoutException {
    return IntegrationTestResult(
      a2uiMessages: a2uiMessages,
      textChunks: textChunks,
      errors: errors,
      timedOut: true,
    );
  } finally {
    generator.isProcessing.removeListener(onProcessingChanged);
    for (final sub in subs) {
      await sub.cancel();
    }
  }
}

/// Waits for the generator to finish processing.
///
/// Use this when you've already called sendRequest and want to wait
/// for completion without re-sending.
Future<void> waitForProcessingComplete(
  ClaudeContentGenerator generator, {
  Duration timeout = claudeResponseTimeout,
}) async {
  if (!generator.isProcessing.value) return;

  final completer = Completer<void>();

  void onChanged() {
    if (!generator.isProcessing.value && !completer.isCompleted) {
      completer.complete();
    }
  }

  generator.isProcessing.addListener(onChanged);

  try {
    await completer.future.timeout(timeout);
  } finally {
    generator.isProcessing.removeListener(onChanged);
  }
}
