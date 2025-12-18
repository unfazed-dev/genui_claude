import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/search/tool_catalog_index.dart';
import 'package:genui_claude/src/search/tool_search_handler.dart';
import 'package:genui_claude/src/search/tool_use_interceptor.dart';

const _emptySchema = <String, dynamic>{
  'type': 'object',
  'properties': <String, dynamic>{},
};

void main() {
  group('ToolUseInterceptor', () {
    late ToolUseInterceptor interceptor;
    late ToolSearchHandler handler;
    late ToolCatalogIndex index;
    late List<A2uiToolSchema> loadedSchemas;

    setUp(() {
      index = ToolCatalogIndex();
      handler = ToolSearchHandler(index: index);
      loadedSchemas = [];

      interceptor = ToolUseInterceptor(
        handler: handler,
        onToolsLoaded: (schemas) {
          loadedSchemas.addAll(schemas);
        },
      );

      // Add some test schemas
      index.addSchemas([
        const A2uiToolSchema(
          name: 'button',
          description: 'A clickable button',
          inputSchema: _emptySchema,
        ),
        const A2uiToolSchema(
          name: 'text_field',
          description: 'Text input field',
          inputSchema: _emptySchema,
        ),
        const A2uiToolSchema(
          name: 'date_picker',
          description: 'Calendar for dates',
          inputSchema: _emptySchema,
        ),
      ]);
    });

    group('shouldIntercept', () {
      test('returns true for search_catalog', () {
        expect(interceptor.shouldIntercept('search_catalog'), isTrue);
      });

      test('returns true for load_tools', () {
        expect(interceptor.shouldIntercept('load_tools'), isTrue);
      });

      test('returns false for widget tools', () {
        expect(interceptor.shouldIntercept('button'), isFalse);
        expect(interceptor.shouldIntercept('text_field'), isFalse);
      });

      test('returns false for unknown tools', () {
        expect(interceptor.shouldIntercept('unknown_tool'), isFalse);
      });
    });

    group('intercept', () {
      group('search_catalog', () {
        test('processes search request and returns result', () {
          final result = interceptor.intercept(
            toolName: 'search_catalog',
            input: {'query': 'button'},
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['results'], isNotEmpty);
          expect(result['total_available'], equals(3));
        });

        test('returns matching results', () {
          final result = interceptor.intercept(
            toolName: 'search_catalog',
            input: {'query': 'date'},
          );

          final results = result['results'] as List<dynamic>;
          expect(
            results.any(
              (dynamic r) =>
                  (r as Map<String, dynamic>)['name'] == 'date_picker',
            ),
            isTrue,
          );
        });

        test('respects max_results parameter', () {
          final result = interceptor.intercept(
            toolName: 'search_catalog',
            input: {'query': 'button', 'max_results': 1},
          );

          final results = result['results'] as List;
          expect(results.length, equals(1));
        });
      });

      group('load_tools', () {
        test('processes load request and returns result', () {
          final result = interceptor.intercept(
            toolName: 'load_tools',
            input: {
              'tool_names': ['button', 'text_field'],
            },
          );

          expect(result['loaded'], equals(['button', 'text_field']));
          expect(result['not_found'], isEmpty);
        });

        test('invokes onToolsLoaded callback', () {
          interceptor.intercept(
            toolName: 'load_tools',
            input: {
              'tool_names': ['button'],
            },
          );

          expect(loadedSchemas, hasLength(1));
          expect(loadedSchemas.first.name, equals('button'));
        });

        test('reports not found tools', () {
          final result = interceptor.intercept(
            toolName: 'load_tools',
            input: {
              'tool_names': ['button', 'nonexistent'],
            },
          );

          expect(result['loaded'], equals(['button']));
          expect(result['not_found'], equals(['nonexistent']));
        });
      });

      test('throws for unknown tool', () {
        expect(
          () => interceptor.intercept(
            toolName: 'unknown',
            input: {},
          ),
          throwsArgumentError,
        );
      });
    });

    group('createToolResult', () {
      test('creates successful tool result for search', () {
        final result = interceptor.createToolResult(
          toolUseId: 'test-id',
          toolName: 'search_catalog',
          input: {'query': 'button'},
        );

        expect(result.toolUseId, equals('test-id'));
        expect(result.isError, isFalse);
        expect(result.content, contains('results'));
      });

      test('creates successful tool result for load', () {
        final result = interceptor.createToolResult(
          toolUseId: 'test-id',
          toolName: 'load_tools',
          input: {
            'tool_names': ['button'],
          },
        );

        expect(result.toolUseId, equals('test-id'));
        expect(result.isError, isFalse);
        expect(result.content, contains('loaded'));
      });

      test('creates error result for unknown tool', () {
        final result = interceptor.createToolResult(
          toolUseId: 'test-id',
          toolName: 'unknown',
          input: {},
        );

        expect(result.toolUseId, equals('test-id'));
        expect(result.isError, isTrue);
        expect(result.content, contains('unknown'));
      });
    });

    group('integration', () {
      test('full search and load workflow', () {
        // Step 1: Search for date-related widgets
        final searchResult = interceptor.intercept(
          toolName: 'search_catalog',
          input: {'query': 'date'},
        );

        expect(searchResult['results'], isNotEmpty);

        // Step 2: Load the date_picker widget
        final loadResult = interceptor.intercept(
          toolName: 'load_tools',
          input: {
            'tool_names': ['date_picker'],
          },
        );

        expect(loadResult['loaded'], contains('date_picker'));
        expect(loadedSchemas.any((s) => s.name == 'date_picker'), isTrue);

        // Verify the handler tracks loaded tools
        expect(handler.loadedToolNames, contains('date_picker'));
      });
    });
  });
}
