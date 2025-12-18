import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/src/adapter/catalog_tool_bridge.dart';
import 'package:genui_claude/src/search/catalog_search_tool.dart';
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

      test('handles object schema with string property', () {
        final item = CatalogItem(
          name: 'string_widget',
          dataSchema: S.object(
            description: 'Widget with string property',
            properties: {
              'text': S.string(description: 'The text content'),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('text'), isTrue);
        expect(props['text'], isA<Map<String, dynamic>>());
      });

      test('handles object schema with integer property', () {
        final item = CatalogItem(
          name: 'integer_widget',
          dataSchema: S.object(
            description: 'Widget with integer property',
            properties: {
              'count': S.integer(description: 'The count value'),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('count'), isTrue);
        expect(props['count'], isA<Map<String, dynamic>>());
      });

      test('handles object schema with number property', () {
        final item = CatalogItem(
          name: 'number_widget',
          dataSchema: S.object(
            description: 'Widget with number property',
            properties: {
              'value': S.number(description: 'A decimal value'),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('value'), isTrue);
      });

      test('handles object schema with boolean property', () {
        final item = CatalogItem(
          name: 'boolean_widget',
          dataSchema: S.object(
            description: 'Widget with boolean property',
            properties: {
              'isEnabled': S.boolean(description: 'Whether enabled'),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('isEnabled'), isTrue);
      });

      test('handles object schema with list property', () {
        final item = CatalogItem(
          name: 'list_widget',
          dataSchema: S.object(
            description: 'Widget with list property',
            properties: {
              'items': S.list(
                description: 'List of items',
                items: S.string(),
              ),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;
        final props = schema['properties'] as Map<String, dynamic>;

        expect(props.containsKey('items'), isTrue);
      });

      test('handles object with nested object properties', () {
        final item = CatalogItem(
          name: 'nested_props_widget',
          dataSchema: S.object(
            description: 'Widget with nested object',
            properties: {
              'config': S.object(
                description: 'Configuration object',
                properties: {
                  'enabled': S.boolean(),
                  'name': S.string(),
                },
                required: ['enabled'],
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
        expect(configProp['description'], 'Configuration object');
        expect(configProp['properties'], isA<Map<String, dynamic>>());
        expect(configProp['required'], contains('enabled'));
      });

      test('generates default description when schema has no description', () {
        final item = CatalogItem(
          name: 'no_desc_widget',
          dataSchema: S.object(
            properties: {
              'value': S.string(),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);

        expect(tools.first.description, 'Render a no_desc_widget widget');
      });

      test('handles schema with no required fields', () {
        final item = CatalogItem(
          name: 'optional_widget',
          dataSchema: S.object(
            description: 'All optional fields',
            properties: {
              'field1': S.string(),
              'field2': S.integer(),
            },
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);

        expect(tools.first.requiredFields, isNull);
      });

      test('handles schema with empty required list', () {
        final item = CatalogItem(
          name: 'empty_required_widget',
          dataSchema: S.object(
            description: 'Empty required list',
            properties: {
              'field1': S.string(),
            },
            required: [],
          ),
          widgetBuilder: (_) => const SizedBox(),
        );

        final tools = CatalogToolBridge.fromItems([item]);
        final schema = tools.first.inputSchema;

        // Empty required list should not be included in schema
        expect(schema.containsKey('required'), isFalse);
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

    group('createIndex', () {
      test('creates index from tool schemas', () {
        final tools = CatalogToolBridge.fromItems([
          CatalogItem(
            name: 'date_picker',
            dataSchema: S.object(
              description: 'Calendar widget for selecting dates',
              properties: {'date': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
          CatalogItem(
            name: 'button',
            dataSchema: S.object(
              description: 'A clickable button',
              properties: {'label': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ]);

        final index = CatalogToolBridge.createIndex(tools);

        expect(index.size, equals(2));
        expect(index.allNames, containsAll(['date_picker', 'button']));
      });

      test('creates searchable index', () {
        final tools = CatalogToolBridge.fromItems([
          CatalogItem(
            name: 'date_picker',
            dataSchema: S.object(
              description: 'Calendar widget for selecting dates',
              properties: {'date': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ]);

        final index = CatalogToolBridge.createIndex(tools);
        final results = index.search('calendar');

        expect(results, hasLength(1));
        expect(results.first.name, equals('date_picker'));
      });

      test('creates empty index for empty tools', () {
        final index = CatalogToolBridge.createIndex([]);

        expect(index.size, equals(0));
      });
    });

    group('createIndexFromCatalog', () {
      test('creates index directly from catalog', () {
        final catalog = Catalog([
          CatalogItem(
            name: 'test_widget',
            dataSchema: S.object(
              description: 'A test widget',
              properties: {'value': S.string()},
            ),
            widgetBuilder: (_) => const SizedBox(),
          ),
        ]);

        final index = CatalogToolBridge.createIndexFromCatalog(catalog);

        expect(index.size, equals(1));
        expect(index.allNames, contains('test_widget'));
      });
    });

    group('searchModeTools', () {
      test('returns search and load tools', () {
        final tools = CatalogToolBridge.searchModeTools();

        expect(tools, hasLength(2));
        expect(
          tools.map((t) => t.name),
          containsAll([
            CatalogSearchTool.searchCatalogName,
            CatalogSearchTool.loadToolsName,
          ]),
        );
      });

      test('returns same tools as CatalogSearchTool.allTools', () {
        final bridgeTools = CatalogToolBridge.searchModeTools();
        final searchTools = CatalogSearchTool.allTools;

        expect(bridgeTools, equals(searchTools));
      });
    });

    group('withSearchTools', () {
      test('adds search tools to A2UI control tools', () {
        final tools = CatalogToolBridge.withSearchTools();

        final toolNames = tools.map((t) => t.name).toList();

        // Should have A2UI control tools
        expect(toolNames, contains('begin_rendering'));
        expect(toolNames, contains('surface_update'));

        // Should have search tools
        expect(toolNames, contains('search_catalog'));
        expect(toolNames, contains('load_tools'));
      });

      test('does not include widget tools', () {
        final tools = CatalogToolBridge.withSearchTools();

        // Only control tools + search tools
        expect(tools.length, greaterThanOrEqualTo(6));
      });
    });
  });
}
