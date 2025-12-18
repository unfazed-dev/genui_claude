import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/search/indexed_catalog_item.dart';
import 'package:genui_claude/src/search/tool_catalog_index.dart';

const _emptySchema = <String, dynamic>{
  'type': 'object',
  'properties': <String, dynamic>{},
};

void main() {
  group('IndexedCatalogItem', () {
    test('creates from tool schema with extracted keywords', () {
      const schema = A2uiToolSchema(
        name: 'date_picker',
        description: 'A calendar widget for selecting dates',
        inputSchema: {
          'type': 'object',
          'properties': {
            'selectedDate': {'type': 'string'},
          },
        },
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.name, equals('date_picker'));
      expect(item.schema, equals(schema));
      expect(item.keywords, containsAll(['date', 'picker', 'calendar']));
    });

    test('keywords are sorted and unique', () {
      const schema = A2uiToolSchema(
        name: 'date_selector',
        description: 'Select a date',
        inputSchema: {
          'type': 'object',
          'properties': {
            'date': {'type': 'string'},
          },
        },
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      // Should not have duplicates
      final sorted = List<String>.from(item.keywords)..sort();
      expect(item.keywords, equals(sorted));
    });

    test('handles schema with no description', () {
      const schema = A2uiToolSchema(
        name: 'simple_button',
        description: '',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.keywords, containsAll(['simple', 'button']));
    });

    test('handles minimal inputSchema', () {
      const schema = A2uiToolSchema(
        name: 'basic_text',
        description: 'Display text content',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(
        item.keywords,
        containsAll(['basic', 'text', 'display', 'content']),
      );
    });

    test('matchesQuery returns true for matching keyword', () {
      const schema = A2uiToolSchema(
        name: 'data_table',
        description: 'Display tabular data',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.matchesQuery('table'), isTrue);
      expect(item.matchesQuery('tabular'), isTrue);
      expect(item.matchesQuery('data'), isTrue);
    });

    test('matchesQuery returns false for non-matching keyword', () {
      const schema = A2uiToolSchema(
        name: 'button',
        description: 'A clickable button',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.matchesQuery('calendar'), isFalse);
      expect(item.matchesQuery('date'), isFalse);
    });

    test('matchesQuery is case insensitive', () {
      const schema = A2uiToolSchema(
        name: 'DataTable',
        description: 'Display data',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.matchesQuery('TABLE'), isTrue);
      expect(item.matchesQuery('Data'), isTrue);
    });

    test('matchesQuery handles partial matches', () {
      const schema = A2uiToolSchema(
        name: 'calendar_picker',
        description: 'Pick dates from calendar',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      // Should match partial keyword
      expect(item.matchesQuery('cal'), isTrue);
      expect(item.matchesQuery('pick'), isTrue);
    });

    test('relevanceScore calculates based on keyword matches', () {
      const schema = A2uiToolSchema(
        name: 'date_picker',
        description: 'Calendar widget for date selection',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      // More matching keywords = higher score
      final scoreSingle = item.relevanceScore(['date']);
      final scoreDouble = item.relevanceScore(['date', 'calendar']);
      final scoreTriple = item.relevanceScore(['date', 'calendar', 'picker']);

      expect(scoreDouble, greaterThan(scoreSingle));
      expect(scoreTriple, greaterThan(scoreDouble));
    });

    test('relevanceScore returns 0 for no matches', () {
      const schema = A2uiToolSchema(
        name: 'button',
        description: 'A button widget',
        inputSchema: _emptySchema,
      );

      final item = IndexedCatalogItem.fromSchema(schema);

      expect(item.relevanceScore(['calendar', 'date']), equals(0));
    });
  });

  group('ToolCatalogIndex', () {
    late ToolCatalogIndex index;

    setUp(() {
      index = ToolCatalogIndex();
    });

    group('addSchema', () {
      test('adds schema to index', () {
        const schema = A2uiToolSchema(
          name: 'test_widget',
          description: 'A test widget',
          inputSchema: _emptySchema,
        );

        index.addSchema(schema);

        expect(index.size, equals(1));
      });

      test('indexes schema by keywords', () {
        const schema = A2uiToolSchema(
          name: 'date_picker',
          description: 'Calendar for dates',
          inputSchema: _emptySchema,
        );

        index.addSchema(schema);

        final results = index.search('calendar');
        expect(results, hasLength(1));
        expect(results.first.name, equals('date_picker'));
      });

      test('handles duplicate adds gracefully', () {
        const schema = A2uiToolSchema(
          name: 'test_widget',
          description: 'Test',
          inputSchema: _emptySchema,
        );

        index.addSchema(schema);
        index.addSchema(schema);

        expect(index.size, equals(1));
      });
    });

    group('addSchemas', () {
      test('adds multiple schemas at once', () {
        final schemas = [
          const A2uiToolSchema(
            name: 'widget1',
            description: 'First',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget2',
            description: 'Second',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget3',
            description: 'Third',
            inputSchema: _emptySchema,
          ),
        ];

        index.addSchemas(schemas);

        expect(index.size, equals(3));
      });
    });

    group('search', () {
      setUp(() {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'date_picker',
            description: 'Calendar widget for selecting dates',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'data_table',
            description: 'Display tabular data with sorting',
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

      test('finds matching widgets by single keyword', () {
        final results = index.search('date');

        expect(
          results.map((A2uiToolSchema r) => r.name),
          containsAll(['date_picker', 'date_range_picker']),
        );
      });

      test('finds matching widgets by multiple keywords', () {
        final results = index.search('data table');

        expect(results, hasLength(1));
        expect(results.first.name, equals('data_table'));
      });

      test('ranks results by relevance', () {
        // 'date' appears in multiple widgets
        final results = index.search('date picker calendar');

        // date_picker should rank highest (matches all three)
        expect(results.first.name, equals('date_picker'));
      });

      test('returns empty for no matches', () {
        final results = index.search('nonexistent foo xyz');

        expect(results, isEmpty);
      });

      test('is case insensitive', () {
        final results = index.search('DATE PICKER');

        expect(
          results.map((A2uiToolSchema r) => r.name),
          contains('date_picker'),
        );
      });

      test('respects maxResults parameter', () {
        final results = index.search('date', maxResults: 1);

        expect(results, hasLength(1));
      });

      test('handles empty query', () {
        final results = index.search('');

        expect(results, isEmpty);
      });

      test('handles query with only stop words', () {
        final results = index.search('a the and');

        expect(results, isEmpty);
      });
    });

    group('getSchemaByName', () {
      setUp(() {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'widget1',
            description: 'First',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget2',
            description: 'Second',
            inputSchema: _emptySchema,
          ),
        ]);
      });

      test('returns schema by exact name', () {
        final schema = index.getSchemaByName('widget1');

        expect(schema, isNotNull);
        expect(schema!.name, equals('widget1'));
      });

      test('returns null for non-existent name', () {
        final schema = index.getSchemaByName('nonexistent');

        expect(schema, isNull);
      });
    });

    group('getSchemasByNames', () {
      setUp(() {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'widget1',
            description: 'First',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget2',
            description: 'Second',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget3',
            description: 'Third',
            inputSchema: _emptySchema,
          ),
        ]);
      });

      test('returns schemas for multiple names', () {
        final schemas = index.getSchemasByNames(['widget1', 'widget3']);

        expect(schemas, hasLength(2));
        expect(
          schemas.map((A2uiToolSchema s) => s.name),
          containsAll(['widget1', 'widget3']),
        );
      });

      test('skips non-existent names', () {
        final schemas = index.getSchemasByNames(['widget1', 'nonexistent']);

        expect(schemas, hasLength(1));
        expect(schemas.first.name, equals('widget1'));
      });

      test('returns empty list for all non-existent names', () {
        final schemas = index.getSchemasByNames(['foo', 'bar']);

        expect(schemas, isEmpty);
      });
    });

    group('allNames', () {
      test('returns all indexed tool names', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'alpha',
            description: 'A',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'beta',
            description: 'B',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'gamma',
            description: 'C',
            inputSchema: _emptySchema,
          ),
        ]);

        final names = index.allNames;

        expect(names, containsAll(['alpha', 'beta', 'gamma']));
      });

      test('returns empty list for empty index', () {
        expect(index.allNames, isEmpty);
      });
    });

    group('clear', () {
      test('removes all indexed items', () {
        index.addSchemas([
          const A2uiToolSchema(
            name: 'widget1',
            description: 'First',
            inputSchema: _emptySchema,
          ),
          const A2uiToolSchema(
            name: 'widget2',
            description: 'Second',
            inputSchema: _emptySchema,
          ),
        ]);

        expect(index.size, equals(2));

        index.clear();

        expect(index.size, equals(0));
        expect(index.search('widget'), isEmpty);
      });
    });
  });
}
