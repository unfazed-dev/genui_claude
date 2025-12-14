import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

// =============================================================================
// Custom Matchers for A2uiMessage Types
// =============================================================================

/// Matches a [BeginRendering] message with optional surfaceId check.
Matcher isBeginRendering({String? surfaceId}) {
  return _IsBeginRendering(surfaceId: surfaceId);
}

class _IsBeginRendering extends Matcher {
  _IsBeginRendering({this.surfaceId});

  final String? surfaceId;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! BeginRendering) return false;
    if (surfaceId != null && item.surfaceId != surfaceId) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('is BeginRendering');
    if (surfaceId != null) {
      description.add(' with surfaceId "$surfaceId"');
    }
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! BeginRendering) {
      return mismatchDescription.add('is ${item.runtimeType}');
    }
    if (surfaceId != null && item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    return mismatchDescription;
  }
}

/// Matches a [SurfaceUpdate] message with optional checks.
Matcher isSurfaceUpdate({String? surfaceId, int? componentCount}) {
  return _IsSurfaceUpdate(surfaceId: surfaceId, componentCount: componentCount);
}

class _IsSurfaceUpdate extends Matcher {
  _IsSurfaceUpdate({this.surfaceId, this.componentCount});

  final String? surfaceId;
  final int? componentCount;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! SurfaceUpdate) return false;
    if (surfaceId != null && item.surfaceId != surfaceId) return false;
    if (componentCount != null && item.components.length != componentCount) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('is SurfaceUpdate');
    if (surfaceId != null) {
      description.add(' with surfaceId "$surfaceId"');
    }
    if (componentCount != null) {
      description.add(' with $componentCount components');
    }
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! SurfaceUpdate) {
      return mismatchDescription.add('is ${item.runtimeType}');
    }
    if (surfaceId != null && item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    if (componentCount != null && item.components.length != componentCount) {
      return mismatchDescription.add(
        'has ${item.components.length} components instead of $componentCount',
      );
    }
    return mismatchDescription;
  }
}

/// Matches a [DataModelUpdate] message with optional checks.
Matcher isDataModelUpdate({String? surfaceId}) {
  return _IsDataModelUpdate(surfaceId: surfaceId);
}

class _IsDataModelUpdate extends Matcher {
  _IsDataModelUpdate({this.surfaceId});

  final String? surfaceId;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! DataModelUpdate) return false;
    if (surfaceId != null && item.surfaceId != surfaceId) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('is DataModelUpdate');
    if (surfaceId != null) {
      description.add(' with surfaceId "$surfaceId"');
    }
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! DataModelUpdate) {
      return mismatchDescription.add('is ${item.runtimeType}');
    }
    if (surfaceId != null && item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    return mismatchDescription;
  }
}

/// Matches a [SurfaceDeletion] message with optional surfaceId check.
Matcher isSurfaceDeletion({String? surfaceId}) {
  return _IsSurfaceDeletion(surfaceId: surfaceId);
}

class _IsSurfaceDeletion extends Matcher {
  _IsSurfaceDeletion({this.surfaceId});

  final String? surfaceId;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! SurfaceDeletion) return false;
    if (surfaceId != null && item.surfaceId != surfaceId) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('is SurfaceDeletion');
    if (surfaceId != null) {
      description.add(' with surfaceId "$surfaceId"');
    }
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! SurfaceDeletion) {
      return mismatchDescription.add('is ${item.runtimeType}');
    }
    if (surfaceId != null && item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    return mismatchDescription;
  }
}

// =============================================================================
// Stream Test Helpers
// =============================================================================

/// Collects all items from a stream into a list with timeout.
///
/// ```dart
/// final messages = await collectStream(
///   generator.a2uiMessageStream,
///   timeout: Duration(seconds: 5),
/// );
/// expect(messages, hasLength(3));
/// ```
Future<List<T>> collectStream<T>(
  Stream<T> stream, {
  Duration timeout = const Duration(seconds: 5),
  int? maxItems,
}) async {
  final items = <T>[];
  final completer = Completer<List<T>>();

  late StreamSubscription<T> subscription;
  Timer? timeoutTimer;

  subscription = stream.listen(
    (item) {
      items.add(item);
      if (maxItems != null && items.length >= maxItems) {
        timeoutTimer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(items);
        }
      }
    },
    onDone: () {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        completer.complete(items);
      }
    },
    onError: (Object error) {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
  );

  timeoutTimer = Timer(timeout, () {
    subscription.cancel();
    if (!completer.isCompleted) {
      completer.complete(items);
    }
  });

  return completer.future;
}

/// Waits for a specific number of items from a stream.
///
/// ```dart
/// final messages = await waitForItems(
///   generator.a2uiMessageStream,
///   count: 2,
/// );
/// ```
Future<List<T>> waitForItems<T>(
  Stream<T> stream, {
  required int count,
  Duration timeout = const Duration(seconds: 5),
}) {
  return collectStream(stream, timeout: timeout, maxItems: count);
}

/// Waits for the first item from a stream.
Future<T> waitForFirst<T>(
  Stream<T> stream, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final items = await waitForItems(stream, count: 1, timeout: timeout);
  if (items.isEmpty) {
    throw TimeoutException('No items received within timeout', timeout);
  }
  return items.first;
}

// =============================================================================
// Conversation Builder
// =============================================================================

/// Helper to build conversation histories for testing.
///
/// ```dart
/// final history = ConversationBuilder()
///   ..user('Hello')
///   ..assistant('Hi there!')
///   ..user('How are you?');
/// final messages = history.build();
/// ```
class ConversationBuilder {
  final List<ChatMessage> _messages = [];

  /// Adds a user message with text content.
  void user(String text) {
    _messages.add(UserMessage.text(text));
  }

  /// Adds a user message with multiple text parts.
  void userMulti(List<String> texts) {
    _messages.add(UserMessage(texts.map(TextPart.new).toList()));
  }

  /// Adds an AI text message.
  void assistant(String text) {
    _messages.add(AiTextMessage.text(text));
  }

  /// Adds an AI message with tool calls.
  void assistantWithTools(List<ToolCallPart> toolCalls) {
    _messages.add(AiTextMessage(toolCalls));
  }

  /// Adds a tool response message.
  void toolResponse(String callId, String result) {
    _messages.add(
      ToolResponseMessage([
        ToolResultPart(callId: callId, result: result),
      ]),
    );
  }

  /// Adds an internal context message.
  void internal(String context) {
    _messages.add(InternalMessage(context));
  }

  /// Builds the conversation history.
  List<ChatMessage> build() => List.unmodifiable(_messages);

  /// Returns the last message added.
  ChatMessage? get last => _messages.isEmpty ? null : _messages.last;

  /// Returns the number of messages.
  int get length => _messages.length;

  /// Clears all messages.
  void clear() => _messages.clear();
}

// =============================================================================
// Test Data Generators
// =============================================================================

/// Generates a sequence of surface IDs for testing.
Iterable<String> generateSurfaceIds({
  String prefix = 'surface',
  int count = 10,
}) sync* {
  for (var i = 0; i < count; i++) {
    yield '$prefix-$i';
  }
}

/// Creates a simple component for testing.
Component testComponent({
  String id = 'test-component',
  String type = 'text',
  Map<String, dynamic>? properties,
}) {
  return Component(
    id: id,
    componentProperties: properties ?? {'text': 'Test content'},
  );
}

/// Creates a list of test components.
List<Component> testComponents({
  int count = 3,
  String idPrefix = 'component',
}) {
  return List.generate(
    count,
    (i) => Component(
      id: '$idPrefix-$i',
      componentProperties: {'text': 'Content $i'},
    ),
  );
}

// =============================================================================
// Assertion Helpers
// =============================================================================

/// Asserts that a stream emits items matching the given matchers in order.
Future<void> expectStreamEmits<T>(
  Stream<T> stream,
  List<Matcher> matchers, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final items = await collectStream(
    stream,
    timeout: timeout,
    maxItems: matchers.length,
  );

  expect(
    items.length,
    equals(matchers.length),
    reason: 'Expected ${matchers.length} items but got ${items.length}',
  );

  for (var i = 0; i < matchers.length; i++) {
    expect(items[i], matchers[i], reason: 'Item at index $i did not match');
  }
}

/// Asserts that a stream emits at least one item matching the matcher.
Future<void> expectStreamContains<T>(
  Stream<T> stream,
  Matcher matcher, {
  Duration timeout = const Duration(seconds: 5),
  int maxItems = 100,
}) async {
  final items = await collectStream(
    stream,
    timeout: timeout,
    maxItems: maxItems,
  );

  expect(items, contains(matcher));
}
