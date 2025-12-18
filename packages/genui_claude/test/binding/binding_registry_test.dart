import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/binding_registry.dart';
import 'package:genui_claude/src/binding/widget_binding.dart';

void main() {
  group('BindingRegistry', () {
    late BindingRegistry registry;

    WidgetBinding createBinding({
      required String widgetId,
      required String surfaceId,
      required String property,
      required String path,
      BindingMode mode = BindingMode.oneWay,
    }) {
      return WidgetBinding(
        widgetId: widgetId,
        surfaceId: surfaceId,
        definition: BindingDefinition(
          property: property,
          path: BindingPath.fromDotNotation(path),
          mode: mode,
        ),
        subscription: ValueNotifier<dynamic>(null),
      );
    }

    setUp(() {
      registry = BindingRegistry();
    });

    group('register', () {
      test('registers a binding', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        expect(registry.getBindingsForWidget('widget-1'), contains(binding));
      });

      test('registers multiple bindings for same widget', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'label',
          path: 'form.emailLabel',
        );

        registry.register(binding1);
        registry.register(binding2);

        final bindings = registry.getBindingsForWidget('widget-1');
        expect(bindings, hasLength(2));
        expect(bindings, contains(binding1));
        expect(bindings, contains(binding2));
      });
    });

    group('unregisterWidget', () {
      test('removes all bindings for widget', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'label',
          path: 'form.emailLabel',
        );

        registry.register(binding1);
        registry.register(binding2);
        registry.unregisterWidget('widget-1');

        expect(registry.getBindingsForWidget('widget-1'), isEmpty);
      });

      test('does not affect other widgets', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-2',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.name',
        );

        registry.register(binding1);
        registry.register(binding2);
        registry.unregisterWidget('widget-1');

        expect(registry.getBindingsForWidget('widget-2'), contains(binding2));
      });

      test('handles non-existent widget gracefully', () {
        // Should not throw
        registry.unregisterWidget('non-existent');
        expect(registry.getBindingsForWidget('non-existent'), isEmpty);
      });
    });

    group('unregisterSurface', () {
      test('removes all bindings for surface', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-2',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.name',
        );

        registry.register(binding1);
        registry.register(binding2);
        registry.unregisterSurface('surface-1');

        expect(registry.getBindingsForSurface('surface-1'), isEmpty);
      });

      test('does not affect other surfaces', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-2',
          surfaceId: 'surface-2',
          property: 'value',
          path: 'form.name',
        );

        registry.register(binding1);
        registry.register(binding2);
        registry.unregisterSurface('surface-1');

        expect(registry.getBindingsForSurface('surface-2'), contains(binding2));
      });
    });

    group('getBindingsForWidget', () {
      test('returns empty list for unknown widget', () {
        expect(registry.getBindingsForWidget('unknown'), isEmpty);
      });

      test('returns all bindings for widget', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        expect(registry.getBindingsForWidget('widget-1'), equals([binding]));
      });
    });

    group('getBindingsForSurface', () {
      test('returns empty list for unknown surface', () {
        expect(registry.getBindingsForSurface('unknown'), isEmpty);
      });

      test('returns all bindings for surface', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-2',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.name',
        );

        registry.register(binding1);
        registry.register(binding2);

        final bindings = registry.getBindingsForSurface('surface-1');
        expect(bindings, hasLength(2));
      });
    });

    group('getBindingsForPath', () {
      test('returns empty list for unknown path', () {
        final path = BindingPath.fromDotNotation('unknown.path');
        expect(registry.getBindingsForPath(path), isEmpty);
      });

      test('returns bindings matching exact path', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        final path = BindingPath.fromDotNotation('form.email');
        expect(registry.getBindingsForPath(path), contains(binding));
      });

      test('does not return bindings for different path', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        final path = BindingPath.fromDotNotation('form.name');
        expect(registry.getBindingsForPath(path), isEmpty);
      });
    });

    group('clear', () {
      test('removes all bindings', () {
        final binding1 = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );
        final binding2 = createBinding(
          widgetId: 'widget-2',
          surfaceId: 'surface-2',
          property: 'value',
          path: 'form.name',
        );

        registry.register(binding1);
        registry.register(binding2);
        registry.clear();

        expect(registry.getBindingsForWidget('widget-1'), isEmpty);
        expect(registry.getBindingsForWidget('widget-2'), isEmpty);
        expect(registry.getBindingsForSurface('surface-1'), isEmpty);
        expect(registry.getBindingsForSurface('surface-2'), isEmpty);
      });
    });

    group('getBindingForWidgetProperty', () {
      test('returns binding for specific property', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        expect(
          registry.getBindingForWidgetProperty('widget-1', 'value'),
          equals(binding),
        );
      });

      test('returns null for unknown property', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        expect(
          registry.getBindingForWidgetProperty('widget-1', 'label'),
          isNull,
        );
      });

      test('returns null for unknown widget', () {
        expect(
          registry.getBindingForWidgetProperty('unknown', 'value'),
          isNull,
        );
      });
    });

    group('hasBindings', () {
      test('returns false when empty', () {
        expect(registry.hasBindings, isFalse);
      });

      test('returns true when has bindings', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);

        expect(registry.hasBindings, isTrue);
      });

      test('returns false after clear', () {
        final binding = createBinding(
          widgetId: 'widget-1',
          surfaceId: 'surface-1',
          property: 'value',
          path: 'form.email',
        );

        registry.register(binding);
        registry.clear();

        expect(registry.hasBindings, isFalse);
      });
    });
  });
}
