import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/adapter/a2ui_control_tools.dart';

void main() {
  group('A2uiControlTools', () {
    group('all', () {
      test('returns list of 4 control tools', () {
        final tools = A2uiControlTools.all;

        expect(tools.length, 4);
      });

      test('includes begin_rendering tool', () {
        final tools = A2uiControlTools.all;
        final tool =
            tools.firstWhere((A2uiToolSchema t) => t.name == 'begin_rendering');

        expect(tool.name, 'begin_rendering');
        expect(tool.description, isNotEmpty);
        expect(tool.inputSchema, isNotNull);
      });

      test('includes surface_update tool', () {
        final tools = A2uiControlTools.all;
        final tool =
            tools.firstWhere((A2uiToolSchema t) => t.name == 'surface_update');

        expect(tool.name, 'surface_update');
        expect(tool.description, isNotEmpty);
        expect(tool.inputSchema, isNotNull);
      });

      test('includes data_model_update tool', () {
        final tools = A2uiControlTools.all;
        final tool = tools
            .firstWhere((A2uiToolSchema t) => t.name == 'data_model_update');

        expect(tool.name, 'data_model_update');
        expect(tool.description, isNotEmpty);
        expect(tool.inputSchema, isNotNull);
      });

      test('includes delete_surface tool', () {
        final tools = A2uiControlTools.all;
        final tool =
            tools.firstWhere((A2uiToolSchema t) => t.name == 'delete_surface');

        expect(tool.name, 'delete_surface');
        expect(tool.description, isNotEmpty);
        expect(tool.inputSchema, isNotNull);
      });
    });

    group('beginRendering', () {
      test('has correct name', () {
        expect(A2uiControlTools.beginRendering.name, 'begin_rendering');
      });

      test('has surfaceId as required field', () {
        const tool = A2uiControlTools.beginRendering;

        expect(tool.requiredFields, contains('surfaceId'));
      });

      test('has correct input schema structure', () {
        final schema = A2uiControlTools.beginRendering.inputSchema;

        expect(schema['type'], 'object');
        expect(schema['properties'], isA<Map<String, dynamic>>());
        expect(
          (schema['properties'] as Map<String, dynamic>)
              .containsKey('surfaceId'),
          isTrue,
        );
      });
    });

    group('surfaceUpdate', () {
      test('has correct name', () {
        expect(A2uiControlTools.surfaceUpdate.name, 'surface_update');
      });

      test('has surfaceId and widgets as required fields', () {
        const tool = A2uiControlTools.surfaceUpdate;

        expect(tool.requiredFields, containsAll(['surfaceId', 'widgets']));
      });

      test('has correct input schema with widgets array', () {
        final schema = A2uiControlTools.surfaceUpdate.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('surfaceId'), isTrue);
        expect(props.containsKey('widgets'), isTrue);
        expect(props.containsKey('append'), isTrue);
      });
    });

    group('dataModelUpdate', () {
      test('has correct name', () {
        expect(A2uiControlTools.dataModelUpdate.name, 'data_model_update');
      });

      test('has updates as required field', () {
        const tool = A2uiControlTools.dataModelUpdate;

        expect(tool.requiredFields, contains('updates'));
      });

      test('has correct input schema with updates and scope', () {
        final schema = A2uiControlTools.dataModelUpdate.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('updates'), isTrue);
        expect(props.containsKey('scope'), isTrue);
      });
    });

    group('deleteSurface', () {
      test('has correct name', () {
        expect(A2uiControlTools.deleteSurface.name, 'delete_surface');
      });

      test('has surfaceId as required field', () {
        const tool = A2uiControlTools.deleteSurface;

        expect(tool.requiredFields, contains('surfaceId'));
      });

      test('has correct input schema with cascade option', () {
        final schema = A2uiControlTools.deleteSurface.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('surfaceId'), isTrue);
        expect(props.containsKey('cascade'), isTrue);
      });
    });
  });
}
