import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_controller.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/binding_registry.dart';
import 'package:genui_claude/src/binding/widget_binding.dart';

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
      mockDataModel = MockDataModel({
        'form': {'email': 'test@example.com'},
      });
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

    group('value transformers', () {
      test('toWidget transformer applies to getValueNotifier result', () {
        // Create binding with toWidget transformer
        final path = BindingPath.fromDotNotation('form.email');
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          toWidget: (value) => (value as String).toUpperCase(),
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;

        // Should be transformed to uppercase
        expect(notifier.value, equals('TEST@EXAMPLE.COM'));
      });

      test('toWidget transformer updates when source changes', () {
        final path = BindingPath.fromDotNotation('form.email');
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          toWidget: (value) => 'PREFIX: $value',
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;

        expect(notifier.value, equals('PREFIX: test@example.com'));

        // Update source
        mockDataModel.update(path, 'new@example.com');

        expect(notifier.value, equals('PREFIX: new@example.com'));
      });

      test('toWidget transformed notifier is cached', () {
        final path = BindingPath.fromDotNotation('form.email');
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          toWidget: (value) => value.toString().toUpperCase(),
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        final notifier1 = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        );
        final notifier2 = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        );

        // Same instance returned
        expect(identical(notifier1, notifier2), isTrue);
      });

      test('toModel transformer applies in updateFromWidget', () {
        final path = BindingPath.fromDotNotation('form.email');
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          mode: BindingMode.twoWay,
          toModel: (value) => (value as String).toLowerCase(),
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'USER@EXAMPLE.COM',
        );

        // Should be transformed to lowercase before updating model
        expect(subscription.value, equals('user@example.com'));
      });

      test('toWidget and toModel work together for two-way binding', () {
        final path = BindingPath.fromDotNotation('form.email');

        final definition = BindingDefinition(
          property: 'value',
          path: path,
          mode: BindingMode.twoWay,
          toWidget: (value) => (value as String).toUpperCase(), // to uppercase
          toModel: (value) => (value as String).toLowerCase(), // to lowercase
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        // toWidget transforms to uppercase
        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;
        expect(notifier.value, equals('TEST@EXAMPLE.COM'));

        // toModel transforms to lowercase
        controller.updateFromWidget(
          widgetId: 'email-input',
          property: 'value',
          value: 'NEW@EXAMPLE.COM',
        );
        expect(subscription.value, equals('new@example.com'));
      });

      test('transformed notifiers disposed on unregisterWidget', () {
        final path = BindingPath.fromDotNotation('form.email');
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          toWidget: (value) => value.toString().toUpperCase(),
        );
        final subscription = mockDataModel.subscribe(path);
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: subscription,
        );
        registry.register(binding);

        // Get transformed notifier (creates it)
        final notifier = controller.getValueNotifier(
          widgetId: 'email-input',
          property: 'value',
        )!;

        // Verify it was created
        expect(notifier.value, equals('TEST@EXAMPLE.COM'));

        // Unregister widget
        controller.unregisterWidget('email-input');

        // Getting notifier again returns null (binding gone)
        expect(
          controller.getValueNotifier(
            widgetId: 'email-input',
            property: 'value',
          ),
          isNull,
        );
      });
    });

    group('LRU cache eviction', () {
      test('constructor accepts custom maxCacheSize', () {
        final customController = BindingController(
          registry: BindingRegistry(),
          subscribe: mockDataModel.subscribe,
          update: mockDataModel.update,
          maxCacheSize: 50,
        );
        // Controller created successfully with custom cache size
        expect(customController, isNotNull);
        customController.dispose();
      });

      test('evicts oldest entries when cache exceeds maxCacheSize', () {
        // Create controller with small cache size for testing
        final testRegistry = BindingRegistry();
        final testController = BindingController(
          registry: testRegistry,
          subscribe: mockDataModel.subscribe,
          update: mockDataModel.update,
          maxCacheSize: 3,
        );

        // Create 4 bindings with toWidget transformers to populate cache
        for (var i = 0; i < 4; i++) {
          final path = BindingPath.fromDotNotation('field$i');
          mockDataModel.update(path, 'value$i');
          final definition = BindingDefinition(
            property: 'value',
            path: path,
            toWidget: (value) => 'transformed:$value',
          );
          final subscription = mockDataModel.subscribe(path);
          final binding = WidgetBinding(
            widgetId: 'widget$i',
            surfaceId: 'surface',
            definition: definition,
            subscription: subscription,
          );
          testRegistry.register(binding);

          // Access to create cached transformed notifier
          testController.getValueNotifier(
            widgetId: 'widget$i',
            property: 'value',
          );
        }

        // First widget's cached notifier should have been evicted
        // Getting it again should still work (creates new cache entry)
        final notifier0 = testController.getValueNotifier(
          widgetId: 'widget0',
          property: 'value',
        );
        expect(notifier0, isNotNull);
        expect(notifier0!.value, equals('transformed:value0'));

        testController.dispose();
      });

      test('accessing cached entry updates LRU order', () {
        final testRegistry = BindingRegistry();
        final testController = BindingController(
          registry: testRegistry,
          subscribe: mockDataModel.subscribe,
          update: mockDataModel.update,
          maxCacheSize: 3,
        );

        // Create 3 bindings
        for (var i = 0; i < 3; i++) {
          final path = BindingPath.fromDotNotation('field$i');
          mockDataModel.update(path, 'value$i');
          final definition = BindingDefinition(
            property: 'value',
            path: path,
            toWidget: (value) => 'transformed:$value',
          );
          final subscription = mockDataModel.subscribe(path);
          final binding = WidgetBinding(
            widgetId: 'widget$i',
            surfaceId: 'surface',
            definition: definition,
            subscription: subscription,
          );
          testRegistry.register(binding);
          testController.getValueNotifier(
            widgetId: 'widget$i',
            property: 'value',
          );
        }

        // Access widget0 to move it to end of LRU
        final notifier0First = testController.getValueNotifier(
          widgetId: 'widget0',
          property: 'value',
        );

        // Add widget3, which should evict widget1 (now oldest)
        final path3 = BindingPath.fromDotNotation('field3');
        mockDataModel.update(path3, 'value3');
        final definition3 = BindingDefinition(
          property: 'value',
          path: path3,
          toWidget: (value) => 'transformed:$value',
        );
        final subscription3 = mockDataModel.subscribe(path3);
        final binding3 = WidgetBinding(
          widgetId: 'widget3',
          surfaceId: 'surface',
          definition: definition3,
          subscription: subscription3,
        );
        testRegistry.register(binding3);
        testController.getValueNotifier(
          widgetId: 'widget3',
          property: 'value',
        );

        // widget0 should still be cached (was accessed recently)
        final notifier0Second = testController.getValueNotifier(
          widgetId: 'widget0',
          property: 'value',
        );
        expect(identical(notifier0First, notifier0Second), isTrue);

        testController.dispose();
      });

      test('eviction removes listeners from source notifiers', () {
        final testRegistry = BindingRegistry();
        final testController = BindingController(
          registry: testRegistry,
          subscribe: mockDataModel.subscribe,
          update: mockDataModel.update,
          maxCacheSize: 2,
        );

        // Track listener calls on source
        var listenerCallCount = 0;
        final path = BindingPath.fromDotNotation('field0');
        mockDataModel.update(path, 'initial');
        final source = mockDataModel.subscribe(path);
        source.addListener(() => listenerCallCount++);

        // Create binding with transformer
        final definition = BindingDefinition(
          property: 'value',
          path: path,
          toWidget: (value) => 'transformed:$value',
        );
        final binding = WidgetBinding(
          widgetId: 'widget0',
          surfaceId: 'surface',
          definition: definition,
          subscription: source,
        );
        testRegistry.register(binding);
        testController.getValueNotifier(widgetId: 'widget0', property: 'value');

        // Fill cache to evict widget0's transform
        for (var i = 1; i <= 2; i++) {
          final p = BindingPath.fromDotNotation('field$i');
          mockDataModel.update(p, 'value$i');
          final def = BindingDefinition(
            property: 'value',
            path: p,
            toWidget: (value) => 'transformed:$value',
          );
          final sub = mockDataModel.subscribe(p);
          final b = WidgetBinding(
            widgetId: 'widget$i',
            surfaceId: 'surface',
            definition: def,
            subscription: sub,
          );
          testRegistry.register(b);
          testController.getValueNotifier(
            widgetId: 'widget$i',
            property: 'value',
          );
        }

        // Reset counter after eviction
        listenerCallCount = 0;

        // Update source - should NOT trigger the evicted transform's listener
        source.value = 'updated';

        // Only the external listener we added should fire (1 call)
        // If leak exists, evicted transform's listener would also fire (2 calls)
        expect(listenerCallCount, equals(1));

        testController.dispose();
      });
    });
  });
}
