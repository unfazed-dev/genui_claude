import 'package:a2ui_claude/src/converter/schema_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaMapper', () {
    group('convertProperties', () {
      test('returns empty map for null properties', () {
        final result = SchemaMapper.convertProperties({});
        expect(result, isEmpty);
      });

      test('converts string property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'name': {
              'type': 'string',
              'description': 'User name',
            },
          },
        });

        expect(result['name'], {
          'type': 'string',
          'description': 'User name',
        });
      });

      test('converts string property with enum', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'status': {
              'type': 'string',
              'description': 'Status',
              'enum': ['active', 'inactive'],
            },
          },
        });

        expect(result['status'], {
          'type': 'string',
          'description': 'Status',
          'enum': ['active', 'inactive'],
        });
      });

      test('converts number property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'age': {
              'type': 'number',
              'description': 'User age',
            },
          },
        });

        expect(result['age'], {
          'type': 'number',
          'description': 'User age',
        });
      });

      test('converts integer property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'count': {
              'type': 'integer',
              'description': 'Item count',
            },
          },
        });

        expect(result['count'], {
          'type': 'integer',
          'description': 'Item count',
        });
      });

      test('converts boolean property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'active': {
              'type': 'boolean',
              'description': 'Is active',
            },
          },
        });

        expect(result['active'], {
          'type': 'boolean',
          'description': 'Is active',
        });
      });

      test('converts array property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'tags': {
              'type': 'array',
              'description': 'Tag list',
              'items': {
                'type': 'string',
              },
            },
          },
        });

        expect(result['tags'], {
          'type': 'array',
          'description': 'Tag list',
          'items': {'type': 'string'},
        });
      });

      test('converts array property without items', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'items': {
              'type': 'array',
              'description': 'Generic items',
            },
          },
        });

        expect(result['items'], {
          'type': 'array',
          'description': 'Generic items',
        });
      });

      test('converts object property', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'address': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
                'city': {'type': 'string'},
              },
              'required': ['street'],
            },
          },
        });

        final address = result['address'] as Map<String, dynamic>;
        expect(address['type'], 'object');
        final props = address['properties'] as Map<String, dynamic>;
        expect(props['street'], {'type': 'string'});
        expect(address['required'], ['street']);
      });

      test('converts multiple properties', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'name': {'type': 'string', 'description': 'Name'},
            'age': {'type': 'number', 'description': 'Age'},
            'active': {'type': 'boolean'},
          },
        });

        expect(result.keys, containsAll(['name', 'age', 'active']));
        expect((result['name'] as Map<String, dynamic>)['type'], 'string');
        expect((result['age'] as Map<String, dynamic>)['type'], 'number');
        expect((result['active'] as Map<String, dynamic>)['type'], 'boolean');
      });

      test('handles unknown type by returning original', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'custom': {
              'type': 'custom_type',
              'foo': 'bar',
            },
          },
        });

        expect(result['custom'], {
          'type': 'custom_type',
          'foo': 'bar',
        });
      });

      test('omits description when not present', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'name': {'type': 'string'},
          },
        });

        expect(result['name'], {'type': 'string'});
        expect((result['name'] as Map<String, dynamic>).containsKey('description'), isFalse);
      });

      test('handles nested arrays with objects', () {
        final result = SchemaMapper.convertProperties({
          'properties': {
            'users': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                },
              },
            },
          },
        });

        final users = result['users'] as Map<String, dynamic>;
        expect(users['type'], 'array');
        final items = users['items'] as Map<String, dynamic>;
        expect(items['type'], 'object');
        final itemProps = items['properties'] as Map<String, dynamic>;
        expect(itemProps['id'], {'type': 'string'});
      });
    });
  });
}
