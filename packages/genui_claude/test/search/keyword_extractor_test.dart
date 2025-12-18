import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/search/keyword_extractor.dart';

void main() {
  group('KeywordExtractor', () {
    late KeywordExtractor extractor;

    setUp(() {
      extractor = KeywordExtractor();
    });

    group('extractFromName', () {
      test('extracts words from camelCase', () {
        final keywords = extractor.extractFromName('dateTimePicker');

        expect(keywords, containsAll(['date', 'time', 'picker']));
      });

      test('extracts words from snake_case', () {
        final keywords = extractor.extractFromName('date_time_picker');

        expect(keywords, containsAll(['date', 'time', 'picker']));
      });

      test('extracts words from kebab-case', () {
        final keywords = extractor.extractFromName('date-time-picker');

        expect(keywords, containsAll(['date', 'time', 'picker']));
      });

      test('extracts words from PascalCase', () {
        final keywords = extractor.extractFromName('DateTimePicker');

        expect(keywords, containsAll(['date', 'time', 'picker']));
      });

      test('handles single word', () {
        final keywords = extractor.extractFromName('button');

        expect(keywords, contains('button'));
      });

      test('lowercases all keywords', () {
        final keywords = extractor.extractFromName('DataTable');

        expect(keywords, containsAll(['data', 'table']));
        expect(keywords.every((k) => k == k.toLowerCase()), isTrue);
      });

      test('returns empty set for empty string', () {
        final keywords = extractor.extractFromName('');

        expect(keywords, isEmpty);
      });

      test('filters out short words (< 2 chars)', () {
        final keywords = extractor.extractFromName('a_b_table');

        expect(keywords, contains('table'));
        expect(keywords, isNot(contains('a')));
        expect(keywords, isNot(contains('b')));
      });
    });

    group('extractFromDescription', () {
      test('extracts meaningful words from description', () {
        final keywords = extractor.extractFromDescription(
          'A calendar widget for selecting dates',
        );

        expect(keywords, containsAll(['calendar', 'widget', 'selecting', 'dates']));
      });

      test('filters out common stop words', () {
        final keywords = extractor.extractFromDescription(
          'A widget for the display of data in a table',
        );

        expect(keywords, isNot(contains('a')));
        expect(keywords, isNot(contains('for')));
        expect(keywords, isNot(contains('the')));
        expect(keywords, isNot(contains('of')));
        expect(keywords, isNot(contains('in')));
        expect(keywords, containsAll(['widget', 'display', 'data', 'table']));
      });

      test('lowercases all keywords', () {
        final keywords = extractor.extractFromDescription(
          'Displays a Calendar for Date Selection',
        );

        expect(keywords.every((k) => k == k.toLowerCase()), isTrue);
      });

      test('returns empty set for empty description', () {
        final keywords = extractor.extractFromDescription('');

        expect(keywords, isEmpty);
      });

      test('returns empty set for null description', () {
        final keywords = extractor.extractFromDescription(null);

        expect(keywords, isEmpty);
      });

      test('handles punctuation', () {
        final keywords = extractor.extractFromDescription(
          'Shows data, charts, and graphs.',
        );

        expect(keywords, containsAll(['shows', 'data', 'charts', 'graphs']));
      });
    });

    group('extractFromSchema', () {
      test('extracts property names', () {
        final schema = {
          'type': 'object',
          'properties': {
            'selectedDate': {'type': 'string'},
            'minDate': {'type': 'string'},
            'maxDate': {'type': 'string'},
          },
        };

        final keywords = extractor.extractFromSchema(schema);

        expect(keywords, containsAll(['selected', 'date', 'min', 'max']));
      });

      test('extracts words from property descriptions', () {
        final schema = {
          'type': 'object',
          'properties': {
            'value': {
              'type': 'string',
              'description': 'The currently selected item',
            },
          },
        };

        final keywords = extractor.extractFromSchema(schema);

        expect(keywords, containsAll(['currently', 'selected', 'item']));
      });

      test('extracts enum values', () {
        final schema = {
          'type': 'object',
          'properties': {
            'size': {
              'type': 'string',
              'enum': ['small', 'medium', 'large'],
            },
          },
        };

        final keywords = extractor.extractFromSchema(schema);

        expect(keywords, containsAll(['small', 'medium', 'large']));
      });

      test('extracts nested property names', () {
        final schema = {
          'type': 'object',
          'properties': {
            'header': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string'},
                'subtitle': {'type': 'string'},
              },
            },
          },
        };

        final keywords = extractor.extractFromSchema(schema);

        expect(keywords, containsAll(['header', 'title', 'subtitle']));
      });

      test('extracts from array items schema', () {
        final schema = {
          'type': 'object',
          'properties': {
            'items': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                  'icon': {'type': 'string'},
                },
              },
            },
          },
        };

        final keywords = extractor.extractFromSchema(schema);

        expect(keywords, containsAll(['items', 'label', 'icon']));
      });

      test('returns empty set for null schema', () {
        final keywords = extractor.extractFromSchema(null);

        expect(keywords, isEmpty);
      });

      test('returns empty set for empty schema', () {
        final keywords = extractor.extractFromSchema({});

        expect(keywords, isEmpty);
      });
    });

    group('extractAll', () {
      test('combines keywords from name, description, and schema', () {
        final keywords = extractor.extractAll(
          name: 'datePicker',
          description: 'A calendar widget for selecting dates',
          schema: {
            'type': 'object',
            'properties': {
              'selectedDate': {'type': 'string'},
            },
          },
        );

        // From name
        expect(keywords, containsAll(['date', 'picker']));
        // From description
        expect(keywords, containsAll(['calendar', 'widget']));
        // From schema
        expect(keywords, contains('selected'));
      });

      test('removes duplicates', () {
        final keywords = extractor.extractAll(
          name: 'dateSelector',
          description: 'Select a date',
          schema: {
            'type': 'object',
            'properties': {
              'date': {'type': 'string'},
            },
          },
        );

        // 'date' appears in all three sources but should only appear once
        expect(keywords.where((k) => k == 'date').length, equals(1));
      });

      test('returns sorted list', () {
        final keywords = extractor.extractAll(
          name: 'zebra_button',
          description: 'An apple widget',
        );

        final sorted = List<String>.from(keywords)..sort();
        expect(keywords, equals(sorted));
      });
    });

    group('stop words', () {
      test('has common English stop words', () {
        expect(KeywordExtractor.stopWords, containsAll([
          'a', 'an', 'the', 'is', 'are', 'was', 'were',
          'be', 'been', 'being', 'have', 'has', 'had',
          'do', 'does', 'did', 'will', 'would', 'could',
          'should', 'may', 'might', 'must', 'shall',
          'for', 'and', 'nor', 'but', 'or', 'yet', 'so',
          'in', 'on', 'at', 'to', 'by', 'of', 'with',
          'this', 'that', 'these', 'those',
          'it', 'its',
        ]),);
      });

      test('has UI-specific words to filter', () {
        expect(KeywordExtractor.stopWords, containsAll([
          'optional', 'required', 'default', 'value',
        ]),);
      });
    });

    group('edge cases', () {
      test('handles numbers in names', () {
        final keywords = extractor.extractFromName('form2Input');

        // Numbers attached to words stay with the word
        expect(keywords, containsAll(['form2', 'input']));
      });

      test('handles all-caps abbreviations', () {
        final keywords = extractor.extractFromName('HTTPClient');

        expect(keywords, contains('http'));
        expect(keywords, contains('client'));
      });

      test('handles mixed notation', () {
        // Note: 'my' is a stop word and gets filtered
        final keywords = extractor.extractFromName('custom_camelCase_widget');

        expect(keywords, containsAll(['custom', 'camel', 'case', 'widget']));
      });

      test('filters stop words from names', () {
        // 'my' is a pronoun stop word
        final keywords = extractor.extractFromName('my_widget');

        expect(keywords, contains('widget'));
        expect(keywords, isNot(contains('my')));
      });
    });
  });
}
