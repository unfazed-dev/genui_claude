import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/search/catalog_search_tool.dart';

void main() {
  group('CatalogSearchTool', () {
    group('searchCatalogTool', () {
      test('has correct name', () {
        expect(CatalogSearchTool.searchCatalogTool.name, equals('search_catalog'));
      });

      test('has description', () {
        expect(
          CatalogSearchTool.searchCatalogTool.description,
          contains('Search'),
        );
      });

      test('has query parameter', () {
        final schema = CatalogSearchTool.searchCatalogTool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('query'), isTrue);
        final queryProp = properties['query'] as Map<String, dynamic>;
        expect(queryProp['type'], equals('string'));
      });

      test('query is required', () {
        final schema = CatalogSearchTool.searchCatalogTool.inputSchema;
        expect(schema['required'] as List, contains('query'));
      });

      test('has categories parameter', () {
        final schema = CatalogSearchTool.searchCatalogTool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('categories'), isTrue);
        final categoriesProp = properties['categories'] as Map<String, dynamic>;
        expect(categoriesProp['type'], equals('array'));
      });

      test('has max_results parameter', () {
        final schema = CatalogSearchTool.searchCatalogTool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('max_results'), isTrue);
        final maxResultsProp = properties['max_results'] as Map<String, dynamic>;
        expect(maxResultsProp['type'], equals('integer'));
      });
    });

    group('loadToolsTool', () {
      test('has correct name', () {
        expect(CatalogSearchTool.loadToolsTool.name, equals('load_tools'));
      });

      test('has description', () {
        expect(
          CatalogSearchTool.loadToolsTool.description,
          contains('Load'),
        );
      });

      test('has tool_names parameter', () {
        final schema = CatalogSearchTool.loadToolsTool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('tool_names'), isTrue);
        final toolNamesProp = properties['tool_names'] as Map<String, dynamic>;
        expect(toolNamesProp['type'], equals('array'));
      });

      test('tool_names is required', () {
        final schema = CatalogSearchTool.loadToolsTool.inputSchema;
        expect(schema['required'] as List, contains('tool_names'));
      });
    });

    group('allTools', () {
      test('returns both tools', () {
        final tools = CatalogSearchTool.allTools;
        expect(tools, hasLength(2));
        expect(
          tools.map((t) => t.name),
          containsAll(['search_catalog', 'load_tools']),
        );
      });
    });

    group('toolNames', () {
      test('returns both tool names', () {
        expect(
          CatalogSearchTool.toolNames,
          containsAll(['search_catalog', 'load_tools']),
        );
      });
    });

    group('isSearchTool', () {
      test('returns true for search_catalog', () {
        expect(CatalogSearchTool.isSearchTool('search_catalog'), isTrue);
      });

      test('returns true for load_tools', () {
        expect(CatalogSearchTool.isSearchTool('load_tools'), isTrue);
      });

      test('returns false for other tools', () {
        expect(CatalogSearchTool.isSearchTool('button'), isFalse);
        expect(CatalogSearchTool.isSearchTool('data_table'), isFalse);
      });
    });
  });

  group('SearchCatalogInput', () {
    test('creates from JSON with query only', () {
      final input = SearchCatalogInput.fromJson(const {
        'query': 'date picker',
      });

      expect(input.query, equals('date picker'));
      expect(input.categories, isNull);
      expect(input.maxResults, equals(10));
    });

    test('creates from JSON with all fields', () {
      final input = SearchCatalogInput.fromJson(const {
        'query': 'chart',
        'categories': ['data-display', 'visualization'],
        'max_results': 5,
      });

      expect(input.query, equals('chart'));
      expect(input.categories, equals(['data-display', 'visualization']));
      expect(input.maxResults, equals(5));
    });

    test('converts to JSON', () {
      const input = SearchCatalogInput(
        query: 'button',
        categories: ['input'],
        maxResults: 3,
      );

      final json = input.toJson();

      expect(json['query'], equals('button'));
      expect(json['categories'], equals(['input']));
      expect(json['max_results'], equals(3));
    });
  });

  group('LoadToolsInput', () {
    test('creates from JSON', () {
      final input = LoadToolsInput.fromJson(const {
        'tool_names': ['button', 'text_field', 'dropdown'],
      });

      expect(
        input.toolNames,
        equals(['button', 'text_field', 'dropdown']),
      );
    });

    test('converts to JSON', () {
      const input = LoadToolsInput(toolNames: ['card', 'list_tile']);

      final json = input.toJson();

      expect(json['tool_names'], equals(['card', 'list_tile']));
    });
  });

  group('SearchResult', () {
    test('creates search result', () {
      const result = SearchResult(
        name: 'date_picker',
        description: 'A calendar widget',
        relevance: 0.95,
      );

      expect(result.name, equals('date_picker'));
      expect(result.description, equals('A calendar widget'));
      expect(result.relevance, equals(0.95));
    });

    test('converts to JSON', () {
      const result = SearchResult(
        name: 'button',
        description: 'A clickable button',
        relevance: 0.8,
      );

      final json = result.toJson();

      expect(json['name'], equals('button'));
      expect(json['description'], equals('A clickable button'));
      expect(json['relevance'], equals(0.8));
    });

    test('creates from schema with score', () {
      final result = SearchResult.fromSchemaWithScore(
        name: 'data_table',
        description: 'Display tabular data',
        score: 3,
        maxScore: 4,
      );

      expect(result.name, equals('data_table'));
      expect(result.relevance, equals(0.75));
    });
  });

  group('SearchCatalogOutput', () {
    test('creates output with results', () {
      const output = SearchCatalogOutput(
        results: [
          SearchResult(name: 'a', description: 'A', relevance: 0.9),
          SearchResult(name: 'b', description: 'B', relevance: 0.8),
        ],
        totalAvailable: 100,
      );

      expect(output.results, hasLength(2));
      expect(output.totalAvailable, equals(100));
    });

    test('converts to JSON', () {
      const output = SearchCatalogOutput(
        results: [
          SearchResult(name: 'widget', description: 'A widget', relevance: 1),
        ],
        totalAvailable: 50,
      );

      final json = output.toJson();

      expect(json['results'], hasLength(1));
      expect(json['total_available'], equals(50));
    });
  });

  group('LoadToolsOutput', () {
    test('creates output with loaded tools', () {
      const output = LoadToolsOutput(
        loaded: ['button', 'text_field'],
        notFound: ['nonexistent'],
      );

      expect(output.loaded, equals(['button', 'text_field']));
      expect(output.notFound, equals(['nonexistent']));
    });

    test('converts to JSON', () {
      const output = LoadToolsOutput(
        loaded: ['card'],
        notFound: [],
      );

      final json = output.toJson();

      expect(json['loaded'], equals(['card']));
      expect(json['not_found'], equals([]));
    });
  });
}
