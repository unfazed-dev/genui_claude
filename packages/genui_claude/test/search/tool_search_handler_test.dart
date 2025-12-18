import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/search/catalog_search_tool.dart';
import 'package:genui_claude/src/search/tool_catalog_index.dart';
import 'package:genui_claude/src/search/tool_search_handler.dart';

const _emptySchema = <String, dynamic>{
  'type': 'object',
  'properties': <String, dynamic>{},
};

void main() {
  group('ToolSearchHandler', () {
    late ToolSearchHandler handler;
    late ToolCatalogIndex index;

    setUp(() {
      index = ToolCatalogIndex();
      handler = ToolSearchHandler(index: index);
    });

    group('constructor', () {
      test('creates handler with index', () {
        expect(handler, isNotNull);
        expect(handler.index, same(index));
      });
    });

    group('handleSearchCatalog', () {
      setUp(() {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'date_picker',
            description: 'Calendar widget for selecting dates',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'data_table',
            description: 'Display tabular data',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'button',
            description: 'Clickable button component',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'date_range_picker',
            description: 'Select a range of dates',
            inputSchema: _emptySchema,
          ),
        ]);
      });

      test('returns matching results for query', () {
        const input = SearchCatalogInput(query: 'date');
        final output = handler.handleSearchCatalog(input);

        expect(output.results.length, greaterThanOrEqualTo(2));
        expect(
          output.results.map((r) => r.name),
          containsAll(['date_picker', 'date_range_picker']),
        );
      });

      test('returns results with relevance scores', () {
        const input = SearchCatalogInput(query: 'date picker calendar');
        final output = handler.handleSearchCatalog(input);

        expect(output.results.first.name, equals('date_picker'));
        expect(output.results.first.relevance, greaterThan(0));
      });

      test('respects maxResults parameter', () {
        const input = SearchCatalogInput(query: 'date', maxResults: 1);
        final output = handler.handleSearchCatalog(input);

        expect(output.results.length, equals(1));
      });

      test('returns totalAvailable count', () {
        const input = SearchCatalogInput(query: 'date');
        final output = handler.handleSearchCatalog(input);

        expect(output.totalAvailable, equals(4));
      });

      test('returns empty results for no matches', () {
        const input = SearchCatalogInput(query: 'nonexistent xyz');
        final output = handler.handleSearchCatalog(input);

        expect(output.results, isEmpty);
      });

      test('includes description in results', () {
        const input = SearchCatalogInput(query: 'button');
        final output = handler.handleSearchCatalog(input);

        expect(output.results.first.description, contains('button'));
      });
    });

    group('handleLoadTools', () {
      setUp(() {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'button',
            description: 'A button',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'text_field',
            description: 'A text field',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'dropdown',
            description: 'A dropdown',
            inputSchema: _emptySchema,
          ),
        ]);
      });

      test('returns schemas for existing tools', () {
        const input = LoadToolsInput(toolNames: ['button', 'text_field']);
        final result = handler.handleLoadTools(input);

        expect(result.output.loaded, equals(['button', 'text_field']));
        expect(result.schemas, hasLength(2));
        expect(
          result.schemas.map((s) => s.name),
          containsAll(['button', 'text_field']),
        );
      });

      test('reports not found tools', () {
        const input = LoadToolsInput(toolNames: ['button', 'nonexistent']);
        final result = handler.handleLoadTools(input);

        expect(result.output.loaded, equals(['button']));
        expect(result.output.notFound, equals(['nonexistent']));
      });

      test('returns empty for all non-existent tools', () {
        const input = LoadToolsInput(toolNames: ['foo', 'bar']);
        final result = handler.handleLoadTools(input);

        expect(result.output.loaded, isEmpty);
        expect(result.output.notFound, equals(['foo', 'bar']));
        expect(result.schemas, isEmpty);
      });

      test('handles empty tool names list', () {
        const input = LoadToolsInput(toolNames: []);
        final result = handler.handleLoadTools(input);

        expect(result.output.loaded, isEmpty);
        expect(result.output.notFound, isEmpty);
        expect(result.schemas, isEmpty);
      });

      test('removes duplicates from request', () {
        const input = LoadToolsInput(
          toolNames: ['button', 'button', 'text_field'],
        );
        final result = handler.handleLoadTools(input);

        expect(result.output.loaded, equals(['button', 'text_field']));
        expect(result.schemas, hasLength(2));
      });
    });

    group('loadedToolNames', () {
      test('starts empty', () {
        expect(handler.loadedToolNames, isEmpty);
      });

      test('tracks loaded tools', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'button',
            description: 'A button',
            inputSchema: _emptySchema,
          ),
        ]);

        handler.handleLoadTools(const LoadToolsInput(toolNames: ['button']));

        expect(handler.loadedToolNames, contains('button'));
      });

      test('accumulates across multiple loads', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'button',
            description: 'A button',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'card',
            description: 'A card',
            inputSchema: _emptySchema,
          ),
        ]);

        handler.handleLoadTools(const LoadToolsInput(toolNames: ['button']));
        handler.handleLoadTools(const LoadToolsInput(toolNames: ['card']));

        expect(handler.loadedToolNames, containsAll(['button', 'card']));
      });
    });

    group('clearLoadedTools', () {
      test('clears all loaded tools', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'button',
            description: 'A button',
            inputSchema: _emptySchema,
          ),
        ]);

        handler.handleLoadTools(const LoadToolsInput(toolNames: ['button']));
        expect(handler.loadedToolNames, isNotEmpty);

        handler.clearLoadedTools();
        expect(handler.loadedToolNames, isEmpty);
      });
    });

    group('getLoadedSchemas', () {
      test('returns schemas for loaded tools', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'button',
            description: 'A button',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'card',
            description: 'A card',
            inputSchema: _emptySchema,
          ),
        ]);

        handler.handleLoadTools(const LoadToolsInput(toolNames: ['button']));

        final schemas = handler.getLoadedSchemas();
        expect(schemas, hasLength(1));
        expect(schemas.first.name, equals('button'));
      });

      test('returns empty when nothing loaded', () {
        expect(handler.getLoadedSchemas(), isEmpty);
      });
    });
  });

  group('LoadToolsResult', () {
    test('creates result with output and schemas', () {
      const result = LoadToolsResult(
        output: LoadToolsOutput(loaded: ['a'], notFound: ['b']),
        schemas: [
          A2uiToolSchema(
            name: 'a',
            description: 'A',
            inputSchema: _emptySchema,
          ),
        ],
      );

      expect(result.output.loaded, equals(['a']));
      expect(result.schemas, hasLength(1));
    });
  });
}
