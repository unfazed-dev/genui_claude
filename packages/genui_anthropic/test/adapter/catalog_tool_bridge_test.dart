import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_anthropic/src/adapter/catalog_tool_bridge.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('CatalogToolBridge', () {
    group('fromItems', () {
      test('converts empty list to empty tool list', () {
        final tools = CatalogToolBridge.fromItems(<CatalogItem>[]);

        expect(tools, isEmpty);
      });

      test('converts single CatalogItem to A2uiToolSchema', () {
        final item = CatalogItem(
          name: 'test_widget',
          dataSchema: S.object(
            description: 'A test widget',
            properties: {
              'title': S.string(description: 'Widget title'),
            },
            required: ['title'],
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);

        expect(tools.length, 1);
        expect(tools.first.name, 'test_widget');
        expect(tools.first.description, contains('test widget'));
      });

      test('extracts inputSchema from CatalogItem dataSchema', () {
        final item = CatalogItem(
          name: 'card_widget',
          dataSchema: S.object(
            description: 'A card widget',
            properties: {
              'title': S.string(description: 'Card title'),
              'subtitle': S.string(description: 'Card subtitle'),
            },
            required: ['title'],
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;

        expect(schema['type'], 'object');
        expect(schema['properties'], isA<Map<String, dynamic>>());
        expect(
          (schema['properties'] as Map<String, dynamic>).containsKey('title'),
          isTrue,
        );
        expect(
          (schema['properties'] as Map<String, dynamic>).containsKey('subtitle'),
          isTrue,
        );
      });

      test('extracts required fields from schema', () {
        final item = CatalogItem(
          name: 'required_widget',
          dataSchema: S.object(
            description: 'Widget with required fields',
            properties: {
              'field1': S.string(),
              'field2': S.string(),
              'field3': S.string(),
            },
            required: ['field1', 'field2'],
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);

        expect(tools.first.requiredFields, containsAll(['field1', 'field2']));
        expect(tools.first.requiredFields, isNot(contains('field3')));
      });

      test('converts multiple CatalogItems', () {
        final items = [
          CatalogItem(
            name: 'widget_a',
            dataSchema: S.object(
              description: 'Widget A',
              properties: {'value': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
          CatalogItem(
            name: 'widget_b',
            dataSchema: S.object(
              description: 'Widget B',
              properties: {'count': S.integer()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ];

        final tools = CatalogToolBridge.fromItems(items);

        expect(tools.length, 2);
        expect(
          tools.map((A2uiToolSchema t) => t.name),
          containsAll(['widget_a', 'widget_b']),
        );
      });

      test('handles nested object schemas', () {
        final item = CatalogItem(
          name: 'nested_widget',
          dataSchema: S.object(
            description: 'Widget with nested schema',
            properties: {
              'config': S.object(
                properties: {
                  'option1': S.boolean(),
                  'option2': S.string(),
                },
              ),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;
        final configProp = props['config'] as Map<String, dynamic>;

        expect(configProp['type'], 'object');
        expect(configProp['properties'], isA<Map<String, dynamic>>());
      });

    });

    group('fromCatalog', () {
      test('extracts tools from Catalog', () {
        final catalog = Catalog([
          CatalogItem(
            name: 'catalog_widget',
            dataSchema: S.object(
              description: 'A catalog widget',
              properties: {'text': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ]);

        final tools = CatalogToolBridge.fromCatalog(catalog);

        expect(tools.length, 1);
        expect(tools.first.name, 'catalog_widget');
      });

      test('handles empty catalog', () {
        const catalog = Catalog(<CatalogItem>[]);

        final tools = CatalogToolBridge.fromCatalog(catalog);

        expect(tools, isEmpty);
      });
    });

    group('withA2uiTools', () {
      test('prepends A2UI control tools to widget tools', () {
        final widgetTools = CatalogToolBridge.fromItems([
          CatalogItem(
            name: 'custom_widget',
            dataSchema: S.object(
              description: 'Custom widget',
              properties: {'value': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ]);

        final allTools = CatalogToolBridge.withA2uiTools(widgetTools);

        // Should have A2UI control tools + custom widget tool
        expect(allTools.length, greaterThan(widgetTools.length));
        // First tools should be A2UI control tools
        expect(allTools.first.name, 'begin_rendering');
        // Last tool should be custom widget
        expect(allTools.last.name, 'custom_widget');
      });

      test('includes all A2UI control tools', () {
        final allTools =
            CatalogToolBridge.withA2uiTools(<A2uiToolSchema>[]);

        final toolNames =
            allTools.map((A2uiToolSchema t) => t.name).toList();
        expect(toolNames, contains('begin_rendering'));
        expect(toolNames, contains('surface_update'));
        expect(toolNames, contains('data_model_update'));
        expect(toolNames, contains('delete_surface'));
      });
    });
  });
}
