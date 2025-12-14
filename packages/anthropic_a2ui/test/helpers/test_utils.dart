/// Test utilities and custom matchers for anthropic_a2ui tests.
library;

import 'dart:async';

import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:test/test.dart';

// ============================================================================
// Custom Matchers for A2UI Messages
// ============================================================================

/// Matches a [BeginRenderingData] with the expected [surfaceId].
Matcher isBeginRenderingData({
  required String surfaceId,
  String? parentSurfaceId,
}) =>
    _BeginRenderingDataMatcher(
      surfaceId: surfaceId,
      parentSurfaceId: parentSurfaceId,
    );

class _BeginRenderingDataMatcher extends Matcher {
  _BeginRenderingDataMatcher({
    required this.surfaceId,
    this.parentSurfaceId,
  });

  final String surfaceId;
  final String? parentSurfaceId;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! BeginRenderingData) return false;
    if (item.surfaceId != surfaceId) return false;
    if (parentSurfaceId != null && item.parentSurfaceId != parentSurfaceId) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('BeginRenderingData with surfaceId: $surfaceId');
    if (parentSurfaceId != null) {
      description.add(', parentSurfaceId: $parentSurfaceId');
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
    if (item is! BeginRenderingData) {
      return mismatchDescription.add('is not a BeginRenderingData');
    }
    if (item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    if (parentSurfaceId != null && item.parentSurfaceId != parentSurfaceId) {
      return mismatchDescription.add(
        'has parentSurfaceId "${item.parentSurfaceId}" '
        'instead of "$parentSurfaceId"',
      );
    }
    return mismatchDescription;
  }
}

/// Matches a [SurfaceUpdateData] with the expected [surfaceId] and widget count.
Matcher isSurfaceUpdateData({
  required String surfaceId,
  int? widgetCount,
}) =>
    _SurfaceUpdateDataMatcher(surfaceId: surfaceId, widgetCount: widgetCount);

class _SurfaceUpdateDataMatcher extends Matcher {
  _SurfaceUpdateDataMatcher({required this.surfaceId, this.widgetCount});

  final String surfaceId;
  final int? widgetCount;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! SurfaceUpdateData) return false;
    if (item.surfaceId != surfaceId) return false;
    if (widgetCount != null && item.widgets.length != widgetCount) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('SurfaceUpdateData with surfaceId: $surfaceId');
    if (widgetCount != null) description.add(', widgetCount: $widgetCount');
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! SurfaceUpdateData) {
      return mismatchDescription.add('is not a SurfaceUpdateData');
    }
    if (item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    if (widgetCount != null && item.widgets.length != widgetCount) {
      return mismatchDescription.add(
        'has ${item.widgets.length} widgets instead of $widgetCount',
      );
    }
    return mismatchDescription;
  }
}

/// Matches a [DataModelUpdateData] with the expected [scope].
Matcher isDataModelUpdateData({String? scope}) =>
    _DataModelUpdateDataMatcher(scope: scope);

class _DataModelUpdateDataMatcher extends Matcher {
  _DataModelUpdateDataMatcher({this.scope});

  final String? scope;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! DataModelUpdateData) return false;
    if (scope != null && item.scope != scope) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('DataModelUpdateData');
    if (scope != null) description.add(' with scope: $scope');
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! DataModelUpdateData) {
      return mismatchDescription.add('is not a DataModelUpdateData');
    }
    if (scope != null && item.scope != scope) {
      return mismatchDescription
          .add('has scope "${item.scope}" instead of "$scope"');
    }
    return mismatchDescription;
  }
}

/// Matches a [DeleteSurfaceData] with the expected [surfaceId].
Matcher isDeleteSurfaceData({
  required String surfaceId,
  bool? cascade,
}) =>
    _DeleteSurfaceDataMatcher(surfaceId: surfaceId, cascade: cascade);

class _DeleteSurfaceDataMatcher extends Matcher {
  _DeleteSurfaceDataMatcher({required this.surfaceId, this.cascade});

  final String surfaceId;
  final bool? cascade;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! DeleteSurfaceData) return false;
    if (item.surfaceId != surfaceId) return false;
    if (cascade != null && item.cascade != cascade) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('DeleteSurfaceData with surfaceId: $surfaceId');
    if (cascade != null) description.add(', cascade: $cascade');
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! DeleteSurfaceData) {
      return mismatchDescription.add('is not a DeleteSurfaceData');
    }
    if (item.surfaceId != surfaceId) {
      return mismatchDescription
          .add('has surfaceId "${item.surfaceId}" instead of "$surfaceId"');
    }
    if (cascade != null && item.cascade != cascade) {
      return mismatchDescription
          .add('has cascade "${item.cascade}" instead of "$cascade"');
    }
    return mismatchDescription;
  }
}

// ============================================================================
// Custom Matchers for Stream Events
// ============================================================================

/// Matches a [TextDeltaEvent] with the expected [text].
Matcher isTextDeltaEvent([String? text]) => _TextDeltaEventMatcher(text);

class _TextDeltaEventMatcher extends Matcher {
  _TextDeltaEventMatcher(this.expectedText);

  final String? expectedText;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! TextDeltaEvent) return false;
    if (expectedText != null && item.text != expectedText) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('TextDeltaEvent');
    if (expectedText != null) description.add(' with text: "$expectedText"');
    return description;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! TextDeltaEvent) {
      return mismatchDescription.add('is not a TextDeltaEvent');
    }
    if (expectedText != null && item.text != expectedText) {
      return mismatchDescription
          .add('has text "${item.text}" instead of "$expectedText"');
    }
    return mismatchDescription;
  }
}

/// Matches a [CompleteEvent].
const Matcher isCompleteEvent = TypeMatcher<CompleteEvent>();

/// Matches an [ErrorEvent] with optional message check.
Matcher isErrorEvent([String? message]) => _ErrorEventMatcher(message);

class _ErrorEventMatcher extends Matcher {
  _ErrorEventMatcher(this.expectedMessage);

  final String? expectedMessage;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! ErrorEvent) return false;
    if (expectedMessage != null && item.error.message != expectedMessage) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('ErrorEvent');
    if (expectedMessage != null) {
      description.add(' with message: "$expectedMessage"');
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
    if (item is! ErrorEvent) {
      return mismatchDescription.add('is not an ErrorEvent');
    }
    if (expectedMessage != null && item.error.message != expectedMessage) {
      return mismatchDescription.add(
        'has message "${item.error.message}" instead of "$expectedMessage"',
      );
    }
    return mismatchDescription;
  }
}

/// Matches an [A2uiMessageEvent] containing the specified message type.
Matcher isA2uiMessageEvent<T extends A2uiMessageData>() =>
    _A2uiMessageEventMatcher<T>();

class _A2uiMessageEventMatcher<T extends A2uiMessageData> extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! A2uiMessageEvent) return false;
    return item.message is T;
  }

  @override
  Description describe(Description description) {
    return description.add('A2uiMessageEvent containing $T');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! A2uiMessageEvent) {
      return mismatchDescription.add('is not an A2uiMessageEvent');
    }
    return mismatchDescription
        .add('contains ${item.message.runtimeType} instead of $T');
  }
}

// ============================================================================
// JSON Comparison Helpers
// ============================================================================

/// Deep compares two JSON-like maps for equality.
bool jsonEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final valueA = a[key];
    final valueB = b[key];
    if (valueA is Map<String, dynamic> && valueB is Map<String, dynamic>) {
      if (!jsonEquals(valueA, valueB)) return false;
    } else if (valueA is List && valueB is List) {
      if (!_listEquals(valueA, valueB)) return false;
    } else if (valueA != valueB) {
      return false;
    }
  }
  return true;
}

bool _listEquals(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final itemA = a[i];
    final itemB = b[i];
    if (itemA is Map<String, dynamic> && itemB is Map<String, dynamic>) {
      if (!jsonEquals(itemA, itemB)) return false;
    } else if (itemA is List && itemB is List) {
      if (!_listEquals(itemA, itemB)) return false;
    } else if (itemA != itemB) {
      return false;
    }
  }
  return true;
}

/// Matcher for deep JSON equality.
Matcher jsonEqualTo(Map<String, dynamic> expected) =>
    _JsonEqualsMatcher(expected);

class _JsonEqualsMatcher extends Matcher {
  _JsonEqualsMatcher(this.expected);

  final Map<String, dynamic> expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Map<String, dynamic>) return false;
    return jsonEquals(item, expected);
  }

  @override
  Description describe(Description description) {
    return description.add('equals JSON $expected');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Map<String, dynamic>) {
      return mismatchDescription.add('is not a Map<String, dynamic>');
    }
    return mismatchDescription.add('differs from expected JSON');
  }
}

// ============================================================================
// Async Test Helpers
// ============================================================================

/// Collects all events from a stream into a list.
Future<List<T>> collectStream<T>(Stream<T> stream) async {
  final results = <T>[];
  await for (final event in stream) {
    results.add(event);
  }
  return results;
}

/// Collects events from a stream with a timeout.
Future<List<T>> collectStreamWithTimeout<T>(
  Stream<T> stream, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final results = <T>[];
  await for (final event in stream.timeout(timeout)) {
    results.add(event);
  }
  return results;
}

/// Expects a stream to emit a specific sequence of events.
Future<void> expectStreamEmits<T>(
  Stream<T> stream,
  List<Matcher> matchers,
) async {
  final events = await collectStream(stream);
  expect(
    events.length,
    equals(matchers.length),
    reason: 'Expected ${matchers.length} events but got ${events.length}',
  );
  for (var i = 0; i < matchers.length; i++) {
    expect(events[i], matchers[i], reason: 'Event at index $i did not match');
  }
}

/// Creates a stream from a list of events with optional delays.
Stream<T> streamFromEvents<T>(
  List<T> events, {
  Duration delay = Duration.zero,
}) async* {
  for (final event in events) {
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    yield event;
  }
}

/// Creates a stream that emits events then throws an error.
Stream<T> streamWithError<T>(
  List<T> events,
  Exception error, {
  Duration delay = Duration.zero,
}) async* {
  for (final event in events) {
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    yield event;
  }
  throw error;
}

// ============================================================================
// Widget Node Helpers
// ============================================================================

/// Creates a simple text widget node.
WidgetNode textWidget({
  required String content,
  String? dataBinding,
}) =>
    WidgetNode(
      type: 'text',
      properties: {'content': content},
      dataBinding: dataBinding,
    );

/// Creates a button widget node.
WidgetNode buttonWidget({
  required String label,
  String? action,
  String? dataBinding,
}) =>
    WidgetNode(
      type: 'button',
      properties: {
        'label': label,
        if (action != null) 'action': action,
      },
      dataBinding: dataBinding,
    );

/// Creates a container widget node with children.
WidgetNode containerWidget({
  required String type,
  List<WidgetNode> children = const [],
  Map<String, dynamic> properties = const {},
  String? dataBinding,
}) =>
    WidgetNode(
      type: type,
      properties: properties,
      children: children,
      dataBinding: dataBinding,
    );
