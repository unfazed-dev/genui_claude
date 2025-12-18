import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_controller.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/binding_registry.dart';

/// Mock DataModel for testing.
///
/// Simulates GenUI's DataModel behavior with subscribe/update methods.
class MockDataModel {
  MockDataModel([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  final Map<String, dynamic> _data = {};
  final Map<String, ValueNotifier<dynamic>> _notifiers = {};

  /// Whether update was called (for verification).
  int updateCallCount = 0;

  /// Last path that was updated.
  BindingPath? lastUpdatedPath;

  /// Last value that was set.
  dynamic lastUpdatedValue;

  /// Get value at path.
  dynamic getValue(BindingPath path) {
    dynamic current = _data;
    for (final segment in path.segments) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else if (current is List && int.tryParse(segment) != null) {
        final index = int.parse(segment);
        if (index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  /// Subscribe to path, returns ValueNotifier.
  ValueNotifier<dynamic> subscribe(BindingPath path) {
    final key = path.toSlashNotation();
    if (!_notifiers.containsKey(key)) {
      _notifiers[key] = ValueNotifier<dynamic>(getValue(path));
    }
    return _notifiers[key]!;
  }

  /// Update value at path.
  void update(BindingPath path, dynamic value) {
    updateCallCount++;
    lastUpdatedPath = path;
    lastUpdatedValue = value;

    // Actually update the data
    _setValueAtPath(path, value);

    // Notify subscribers
    final key = path.toSlashNotation();
    if (_notifiers.containsKey(key)) {
      _notifiers[key]!.value = value;
    }
  }

  void _setValueAtPath(BindingPath path, dynamic value) {
    if (path.segments.isEmpty) return;

    if (path.segments.length == 1) {
      _data[path.segments.first] = value;
      return;
    }

    dynamic current = _data;
    for (var i = 0; i < path.segments.length - 1; i++) {
      final segment = path.segments[i];
      if (current is Map<String, dynamic>) {
        current[segment] ??= <String, dynamic>{};
        current = current[segment];
      }
    }

    if (current is Map<String, dynamic>) {
      current[path.segments.last] = value;
    }
  }

  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
  }
}

void main() {
  group('BindingController', () {
    late MockDataModel mockDataModel;
    late BindingRegistry registry;
    late BindingController controller;

    setUp(() {
      mockDataModel = MockDataModel({'form': {'email': 'test@example.com'}});
      registry = BindingRegistry();
      controller = BindingController(
        registry: registry,
        subscribe: mockDataModel.subscribe,
        update: mockDataModel.update,
      );
    });

    tearDown(() {
      controller.dispose();
      mockDataModel.dispose();
    });

    group('constructor', () {
      test('creates controller with required dependencies', () {
        expect(controller, isNotNull);
      });

      test('starts with no active bindings', () {
        expect(registry.hasBindings, isFalse);
      });
    });

    group('processWidgetBindings', () {
      test('creates binding for widget with single binding', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        expect(registry.hasBindings, isTrue);
        final bindings = registry.getBindingsForWidget('email-input');
        expect(bindings, hasLength(1));
        expect(bindings.first.path.toDotNotation(), equals('form.email'));
      });

      test('creates binding for widget with object binding format', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {'value': 'form.email'},
        );

        expect(registry.hasBindings, isTrue);
        final bindings = registry.getBindingsForWidget('email-input');
        expect(bindings, hasLength(1));
        expect(bindings.first.property, equals('value'));
        expect(bindings.first.path.toDotNotation(), equals('form.email'));
      });

      test('creates multiple bindings from object format', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'date-picker',
          dataBinding: {
            'selectedDate': 'form.startDate',
            'minDate': 'form.minDate',
          },
        );

        final bindings = registry.getBindingsForWidget('date-picker');
        expect(bindings, hasLength(2));

        final properties = bindings.map((b) => b.property).toSet();
        expect(properties, containsAll(['selectedDate', 'minDate']));
      });

      test('creates two-way binding when mode specified', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {
            'value': {'path': 'form.email', 'mode': 'twoWay'},
          },
        );

        final bindings = registry.getBindingsForWidget('email-input');
        expect(bindings.first.isTwoWay, isTrue);
      });

      test('subscribes to data model for each binding', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        final bindings = registry.getBindingsForWidget('email-input');
        expect(bindings.first.subscription, isNotNull);
        expect(bindings.first.value, equals('test@example.com'));
      });

      test('ignores null dataBinding', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'button',
          dataBinding: null,
        );

        expect(registry.hasBindings, isFalse);
      });

      test('handles array path in binding', () {
        mockDataModel.update(
          BindingPath.fromDotNotation('items'),
          [
            {'name': 'First'},
            {'name': 'Second'},
          ],
        );

        controller.processWidgetBindings(
          surfaceId: 'list-surface',
          widgetId: 'item-0',
          dataBinding: 'items[0].name',
        );

        final bindings = registry.getBindingsForWidget('item-0');
        expect(bindings, hasLength(1));
        expect(bindings.first.value, equals('First'));
      });
    });

    group('getValueNotifier', () {
      test('returns ValueNotifier for bound widget property', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {'value': 'form.email'},
        );

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        );

        expect(notifier, isNotNull);
        expect(notifier!.value, equals('test@example.com'));
      });

      test('returns null for unbound widget', () {
        final notifier = controller.getValueNotifier(
          widgetId: 'unknown-widget',
          property: 'value',
        );

        expect(notifier, isNull);
      });

      test('returns null for unbound property', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {'value': 'form.email'},
        );

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'label', // Not bound
        );

        expect(notifier, isNull);
      });
    });

    group('updateFromWidget (two-way binding)', () {
      test('updates data model for two-way binding', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {
            'value': {'path': 'form.email', 'mode': 'twoWay'},
          },
        );

        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'new@example.com',
        );

        expect(mockDataModel.updateCallCount, equals(1));
        expect(
          mockDataModel.lastUpdatedPath?.toDotNotation(),
          equals('form.email'),
        );
        expect(mockDataModel.lastUpdatedValue, equals('new@example.com'));
      });

      test('does nothing for one-way binding', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email', // Default one-way
        );

        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'new@example.com',
        );

        // Should not call update (beyond initial subscription setup)
        expect(mockDataModel.updateCallCount, equals(0));
      });

      test('does nothing for unbound widget', () {
        controller.updateFromWidget(
          widgetId: 'unknown-widget',
          property: 'value',
          value: 'test',
        );

        expect(mockDataModel.updateCallCount, equals(0));
      });

      test('prevents update loops', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {
            'value': {'path': 'form.email', 'mode': 'twoWay'},
          },
        );

        // First update should go through
        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'new@example.com',
        );

        // Same value should not trigger another update
        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'new@example.com',
        );

        expect(mockDataModel.updateCallCount, equals(1));
      });
    });

    group('unregisterWidget', () {
      test('removes all bindings for widget', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: {
            'value': 'form.email',
            'label': 'form.emailLabel',
          },
        );

        expect(registry.getBindingsForWidget('email-input'), hasLength(2));

        controller.unregisterWidget('email-input');

        expect(registry.getBindingsForWidget('email-input'), isEmpty);
      });

      test('disposes bindings on unregister', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        final binding = registry.getBindingsForWidget('email-input').first;

        controller.unregisterWidget('email-input');

        expect(binding.isDisposed, isTrue);
      });
    });

    group('unregisterSurface', () {
      test('removes all bindings for surface', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'name-input',
          dataBinding: 'form.name',
        );
        controller.processWidgetBindings(
          surfaceId: 'other-surface',
          widgetId: 'other-input',
          dataBinding: 'other.value',
        );

        expect(registry.getBindingsForSurface('form-surface'), hasLength(2));

        controller.unregisterSurface('form-surface');

        expect(registry.getBindingsForSurface('form-surface'), isEmpty);
        expect(registry.getBindingsForSurface('other-surface'), hasLength(1));
      });
    });

    group('dispose', () {
      test('clears all bindings', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        controller.dispose();

        expect(registry.hasBindings, isFalse);
      });

      test('can be called multiple times safely', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        // Should not throw
        controller.dispose();
        controller.dispose();
      });
    });

    group('binding definition parsing delegation', () {
      test('handles string binding format', () {
        controller.processWidgetBindings(
          surfaceId: 'surface',
          widgetId: 'widget',
          dataBinding: 'path.to.value',
        );

        final bindings = registry.getBindingsForWidget('widget');
        expect(bindings, hasLength(1));
        expect(bindings.first.property, equals('value'));
        expect(bindings.first.path.toDotNotation(), equals('path.to.value'));
      });

      test('handles object binding with simple paths', () {
        controller.processWidgetBindings(
          surfaceId: 'surface',
          widgetId: 'widget',
          dataBinding: {
            'prop1': 'path1',
            'prop2': 'path2',
          },
        );

        final bindings = registry.getBindingsForWidget('widget');
        expect(bindings, hasLength(2));
      });

      test('handles object binding with mode specification', () {
        controller.processWidgetBindings(
          surfaceId: 'surface',
          widgetId: 'widget',
          dataBinding: {
            'value': {
              'path': 'form.field',
              'mode': 'twoWay',
            },
          },
        );

        final bindings = registry.getBindingsForWidget('widget');
        expect(bindings, hasLength(1));
        expect(bindings.first.mode, equals(BindingMode.twoWay));
      });
    });

    group('data model integration', () {
      test('reflects data model changes in bound value', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;

        expect(notifier.value, equals('test@example.com'));

        // Simulate external data model update
        mockDataModel.update(
          BindingPath.fromDotNotation('form.email'),
          'updated@example.com',
        );

        expect(notifier.value, equals('updated@example.com'));
      });

      test('notifies listeners when data model updates', () {
        controller.processWidgetBindings(
          surfaceId: 'form-surface',
          widgetId: 'email-input',
          dataBinding: 'form.email',
        );

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;

        var notificationCount = 0;
        notifier.addListener(() => notificationCount++);

        mockDataModel.update(
          BindingPath.fromDotNotation('form.email'),
          'changed@example.com',
        );

        expect(notificationCount, equals(1));
      });
    });
  });
}
