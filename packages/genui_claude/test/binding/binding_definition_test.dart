import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';

void main() {
  group('BindingMode', () {
    test('has oneWay mode', () {
      expect(BindingMode.oneWay, isNotNull);
    });

    test('has twoWay mode', () {
      expect(BindingMode.twoWay, isNotNull);
    });

    test('has oneWayToSource mode', () {
      expect(BindingMode.oneWayToSource, isNotNull);
    });
  });

  group('BindingDefinition', () {
    group('constructor', () {
      test('creates with required fields', () {
        final path = BindingPath.fromDotNotation('form.email');

        final definition = BindingDefinition(
          property: 'value',
          path: path,
        );

        expect(definition.property, equals('value'));
        expect(definition.path, equals(path));
        expect(definition.mode, equals(BindingMode.oneWay));
        expect(definition.toWidget, isNull);
        expect(definition.toModel, isNull);
      });

      test('creates with all fields', () {
        final path = BindingPath.fromDotNotation('form.email');
        String toWidgetTransform(dynamic v) => v.toString().toUpperCase();
        String toModelTransform(dynamic v) => v.toString().toLowerCase();

        final definition = BindingDefinition(
          property: 'value',
          path: path,
          mode: BindingMode.twoWay,
          toWidget: toWidgetTransform,
          toModel: toModelTransform,
        );

        expect(definition.property, equals('value'));
        expect(definition.path, equals(path));
        expect(definition.mode, equals(BindingMode.twoWay));
        expect(definition.toWidget, isNotNull);
        expect(definition.toModel, isNotNull);
      });
    });

    group('parse', () {
      group('string format', () {
        test('parses simple path string', () {
          final definitions = BindingDefinition.parse('form.email');

          expect(definitions, hasLength(1));
          expect(definitions.first.property, equals('value'));
          expect(
            definitions.first.path,
            equals(BindingPath.fromDotNotation('form.email')),
          );
          expect(definitions.first.mode, equals(BindingMode.oneWay));
        });

        test('parses array path string', () {
          final definitions = BindingDefinition.parse('items[0].name');

          expect(definitions, hasLength(1));
          expect(definitions.first.property, equals('value'));
          expect(
            definitions.first.path.segments,
            equals(['items', '0', 'name']),
          );
        });
      });

      group('object format', () {
        test('parses single property binding', () {
          final definitions = BindingDefinition.parse({
            'value': 'form.email',
          });

          expect(definitions, hasLength(1));
          expect(definitions.first.property, equals('value'));
          expect(
            definitions.first.path,
            equals(BindingPath.fromDotNotation('form.email')),
          );
        });

        test('parses multiple property bindings', () {
          final definitions = BindingDefinition.parse({
            'value': 'form.email',
            'label': 'form.emailLabel',
          });

          expect(definitions, hasLength(2));

          final valueBinding =
              definitions.firstWhere((d) => d.property == 'value');
          expect(
            valueBinding.path,
            equals(BindingPath.fromDotNotation('form.email')),
          );

          final labelBinding =
              definitions.firstWhere((d) => d.property == 'label');
          expect(
            labelBinding.path,
            equals(BindingPath.fromDotNotation('form.emailLabel')),
          );
        });

        test('parses binding with mode', () {
          final definitions = BindingDefinition.parse({
            'value': {
              'path': 'form.email',
              'mode': 'twoWay',
            },
          });

          expect(definitions, hasLength(1));
          expect(definitions.first.property, equals('value'));
          expect(
            definitions.first.path,
            equals(BindingPath.fromDotNotation('form.email')),
          );
          expect(definitions.first.mode, equals(BindingMode.twoWay));
        });

        test('parses binding with oneWayToSource mode', () {
          final definitions = BindingDefinition.parse({
            'value': {
              'path': 'form.email',
              'mode': 'oneWayToSource',
            },
          });

          expect(definitions.first.mode, equals(BindingMode.oneWayToSource));
        });
      });

      group('edge cases', () {
        test('returns empty list for null', () {
          final definitions = BindingDefinition.parse(null);

          expect(definitions, isEmpty);
        });

        test('returns empty list for empty string', () {
          final definitions = BindingDefinition.parse('');

          expect(definitions, isEmpty);
        });

        test('returns empty list for empty map', () {
          final definitions = BindingDefinition.parse(<String, dynamic>{});

          expect(definitions, isEmpty);
        });

        test('ignores non-string values in simple map', () {
          final definitions = BindingDefinition.parse({
            'value': 'form.email',
            'count': 42, // should be ignored
          });

          expect(definitions, hasLength(1));
          expect(definitions.first.property, equals('value'));
        });
      });
    });

    group('copyWith', () {
      test('creates copy with modified property', () {
        final original = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
        );

        final copy = original.copyWith(property: 'text');

        expect(copy.property, equals('text'));
        expect(copy.path, equals(original.path));
        expect(copy.mode, equals(original.mode));
      });

      test('creates copy with modified mode', () {
        final original = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
        );

        final copy = original.copyWith(mode: BindingMode.twoWay);

        expect(copy.property, equals(original.property));
        expect(copy.mode, equals(BindingMode.twoWay));
      });
    });

    group('equality', () {
      test('equal definitions are equal', () {
        final def1 = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
        );
        final def2 = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
        );

        expect(def1, equals(def2));
        expect(def1.hashCode, equals(def2.hashCode));
      });

      test('different definitions are not equal', () {
        final def1 = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
        );
        final def2 = BindingDefinition(
          property: 'text',
          path: BindingPath.fromDotNotation('form.email'),
        );

        expect(def1, isNot(equals(def2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final definition = BindingDefinition(
          property: 'value',
          path: BindingPath.fromDotNotation('form.email'),
          mode: BindingMode.twoWay,
        );

        expect(definition.toString(), contains('value'));
        expect(definition.toString(), contains('form.email'));
        expect(definition.toString(), contains('twoWay'));
      });
    });
  });
}
