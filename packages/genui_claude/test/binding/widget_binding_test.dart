import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/widget_binding.dart';

void main() {
  group('WidgetBinding', () {
    late BindingDefinition definition;
    late ValueNotifier<dynamic> notifier;

    setUp(() {
      definition = BindingDefinition(
        property: 'value',
        path: BindingPath.fromDotNotation('form.email'),
      );
      notifier = ValueNotifier<dynamic>('initial@example.com');
    });

    tearDown(() {
      notifier.dispose();
    });

    group('constructor', () {
      test('creates with required fields', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.widgetId, equals('email-input'));
        expect(binding.surfaceId, equals('form-surface'));
        expect(binding.definition, equals(definition));
        expect(binding.subscription, equals(notifier));
      });
    });

    group('value', () {
      test('returns current subscription value', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.value, equals('initial@example.com'));
      });

      test('reflects updated subscription value', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        notifier.value = 'updated@example.com';

        expect(binding.value, equals('updated@example.com'));
      });
    });

    group('property', () {
      test('returns definition property', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.property, equals('value'));
      });
    });

    group('path', () {
      test('returns definition path', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.path, equals(definition.path));
      });
    });

    group('mode', () {
      test('returns definition mode', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.mode, equals(BindingMode.oneWay));
      });

      test('returns twoWay mode when defined', () {
        final twoWayDefinition = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
          mode: BindingMode.twoWay,
        );

        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: twoWayDefinition,
          subscription: notifier,
        );

        expect(binding.mode, equals(BindingMode.twoWay));
      });
    });

    group('isTwoWay', () {
      test('returns false for oneWay mode', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.isTwoWay, isFalse);
      });

      test('returns true for twoWay mode', () {
        final twoWayDefinition = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
          mode: BindingMode.twoWay,
        );

        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: twoWayDefinition,
          subscription: notifier,
        );

        expect(binding.isTwoWay, isTrue);
      });
    });

    group('isDisposed', () {
      test('returns false initially', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        expect(binding.isDisposed, isFalse);
      });

      test('returns true after dispose', () {
        final localNotifier = ValueNotifier<dynamic>('test');
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: localNotifier,
        );

        binding.dispose();

        expect(binding.isDisposed, isTrue);
      });
    });

    group('dispose', () {
      test('can be called multiple times safely', () {
        final localNotifier = ValueNotifier<dynamic>('test');
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: localNotifier,
        );

        // Should not throw
        binding.dispose();
        binding.dispose();

        expect(binding.isDisposed, isTrue);
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final binding = WidgetBinding(
          widgetId: 'email-input',
          surfaceId: 'form-surface',
          definition: definition,
          subscription: notifier,
        );

        final str = binding.toString();

        expect(str, contains('email-input'));
        expect(str, contains('value'));
        expect(str, contains('form.email'));
      });
    });
  });
}
