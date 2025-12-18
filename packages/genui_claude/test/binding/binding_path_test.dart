import 'package:flutter_test/flutter_test.dart';
import 'package:genui_claude/src/binding/binding_path.dart';

void main() {
  group('BindingPath', () {
    group('fromDotNotation', () {
      test('parses simple path', () {
        final path = BindingPath.fromDotNotation('email');

        expect(path.segments, equals(['email']));
        expect(path.isAbsolute, isTrue);
      });

      test('parses nested path', () {
        final path = BindingPath.fromDotNotation('form.email');

        expect(path.segments, equals(['form', 'email']));
      });

      test('parses deeply nested path', () {
        final path = BindingPath.fromDotNotation('user.profile.name');

        expect(path.segments, equals(['user', 'profile', 'name']));
      });

      test('parses array index notation', () {
        final path = BindingPath.fromDotNotation('items[0]');

        expect(path.segments, equals(['items', '0']));
      });

      test('parses array index with property', () {
        final path = BindingPath.fromDotNotation('items[0].name');

        expect(path.segments, equals(['items', '0', 'name']));
      });

      test('parses complex mixed path', () {
        final path = BindingPath.fromDotNotation('form.addresses[2].city');

        expect(path.segments, equals(['form', 'addresses', '2', 'city']));
      });

      test('parses multiple array indices', () {
        final path = BindingPath.fromDotNotation('matrix[0][1]');

        expect(path.segments, equals(['matrix', '0', '1']));
      });

      test('handles empty string', () {
        final path = BindingPath.fromDotNotation('');

        expect(path.segments, isEmpty);
      });

      test('handles whitespace by trimming', () {
        final path = BindingPath.fromDotNotation('  form.email  ');

        expect(path.segments, equals(['form', 'email']));
      });
    });

    group('fromSlashNotation', () {
      test('parses absolute path', () {
        final path = BindingPath.fromSlashNotation('/form/email');

        expect(path.segments, equals(['form', 'email']));
        expect(path.isAbsolute, isTrue);
      });

      test('parses relative path', () {
        final path = BindingPath.fromSlashNotation('form/email');

        expect(path.segments, equals(['form', 'email']));
        expect(path.isAbsolute, isFalse);
      });

      test('parses path with numeric segments', () {
        final path = BindingPath.fromSlashNotation('/items/0/name');

        expect(path.segments, equals(['items', '0', 'name']));
      });

      test('handles empty path', () {
        final path = BindingPath.fromSlashNotation('');

        expect(path.segments, isEmpty);
      });

      test('handles root only', () {
        final path = BindingPath.fromSlashNotation('/');

        expect(path.segments, isEmpty);
        expect(path.isAbsolute, isTrue);
      });
    });

    group('toDotNotation', () {
      test('converts simple path', () {
        final path = BindingPath.fromDotNotation('email');

        expect(path.toDotNotation(), equals('email'));
      });

      test('converts nested path', () {
        final path = BindingPath.fromDotNotation('form.email');

        expect(path.toDotNotation(), equals('form.email'));
      });

      test('converts array index path', () {
        final path = BindingPath.fromDotNotation('items[0].name');

        expect(path.toDotNotation(), equals('items[0].name'));
      });

      test('converts multiple array indices', () {
        final path = BindingPath.fromDotNotation('matrix[0][1]');

        expect(path.toDotNotation(), equals('matrix[0][1]'));
      });

      test('handles empty path', () {
        final path = BindingPath.fromDotNotation('');

        expect(path.toDotNotation(), equals(''));
      });
    });

    group('toSlashNotation', () {
      test('converts to absolute slash path', () {
        final path = BindingPath.fromDotNotation('form.email');

        expect(path.toSlashNotation(), equals('/form/email'));
      });

      test('converts array indices', () {
        final path = BindingPath.fromDotNotation('items[0].name');

        expect(path.toSlashNotation(), equals('/items/0/name'));
      });

      test('handles empty path', () {
        final path = BindingPath.fromDotNotation('');

        expect(path.toSlashNotation(), equals('/'));
      });

      test('relative path omits leading slash', () {
        final path = BindingPath.fromSlashNotation('form/email');

        expect(path.toSlashNotation(), equals('form/email'));
      });
    });

    group('parent', () {
      test('returns parent for nested path', () {
        final path = BindingPath.fromDotNotation('form.email');
        final parent = path.parent;

        expect(parent, isNotNull);
        expect(parent!.segments, equals(['form']));
      });

      test('returns null for single segment path', () {
        final path = BindingPath.fromDotNotation('email');

        expect(path.parent, isNull);
      });

      test('returns null for empty path', () {
        final path = BindingPath.fromDotNotation('');

        expect(path.parent, isNull);
      });

      test('returns parent for array path', () {
        final path = BindingPath.fromDotNotation('items[0].name');
        final parent = path.parent;

        expect(parent!.segments, equals(['items', '0']));
      });
    });

    group('leaf', () {
      test('returns last segment for nested path', () {
        final path = BindingPath.fromDotNotation('form.email');

        expect(path.leaf, equals('email'));
      });

      test('returns segment for single segment path', () {
        final path = BindingPath.fromDotNotation('email');

        expect(path.leaf, equals('email'));
      });

      test('returns empty string for empty path', () {
        final path = BindingPath.fromDotNotation('');

        expect(path.leaf, equals(''));
      });

      test('returns index for array path', () {
        final path = BindingPath.fromDotNotation('items[0]');

        expect(path.leaf, equals('0'));
      });
    });

    group('join', () {
      test('joins two paths', () {
        final base = BindingPath.fromDotNotation('form');
        final child = BindingPath.fromSlashNotation('email');

        final joined = base.join(child);

        expect(joined.segments, equals(['form', 'email']));
      });

      test('joins with multi-segment path', () {
        final base = BindingPath.fromDotNotation('user');
        final child = BindingPath.fromDotNotation('profile.name');

        final joined = base.join(child);

        expect(joined.segments, equals(['user', 'profile', 'name']));
      });

      test('joining empty path returns original', () {
        final base = BindingPath.fromDotNotation('form.email');
        final empty = BindingPath.fromDotNotation('');

        final joined = base.join(empty);

        expect(joined.segments, equals(['form', 'email']));
      });
    });

    group('startsWith', () {
      test('returns true when path starts with prefix', () {
        final path = BindingPath.fromDotNotation('form.email');
        final prefix = BindingPath.fromDotNotation('form');

        expect(path.startsWith(prefix), isTrue);
      });

      test('returns true for exact match', () {
        final path = BindingPath.fromDotNotation('form.email');
        final prefix = BindingPath.fromDotNotation('form.email');

        expect(path.startsWith(prefix), isTrue);
      });

      test('returns false when path does not start with prefix', () {
        final path = BindingPath.fromDotNotation('form.email');
        final prefix = BindingPath.fromDotNotation('user');

        expect(path.startsWith(prefix), isFalse);
      });

      test('returns false when prefix is longer', () {
        final path = BindingPath.fromDotNotation('form');
        final prefix = BindingPath.fromDotNotation('form.email');

        expect(path.startsWith(prefix), isFalse);
      });

      test('empty prefix matches any path', () {
        final path = BindingPath.fromDotNotation('form.email');
        final prefix = BindingPath.fromDotNotation('');

        expect(path.startsWith(prefix), isTrue);
      });
    });

    group('equality', () {
      test('equal paths are equal', () {
        final path1 = BindingPath.fromDotNotation('form.email');
        final path2 = BindingPath.fromDotNotation('form.email');

        expect(path1, equals(path2));
        expect(path1.hashCode, equals(path2.hashCode));
      });

      test('paths from different notations are equal', () {
        final dotPath = BindingPath.fromDotNotation('items[0].name');
        final slashPath = BindingPath.fromSlashNotation('/items/0/name');

        expect(dotPath, equals(slashPath));
      });

      test('different paths are not equal', () {
        final path1 = BindingPath.fromDotNotation('form.email');
        final path2 = BindingPath.fromDotNotation('form.name');

        expect(path1, isNot(equals(path2)));
      });
    });

    group('toString', () {
      test('returns dot notation for debugging', () {
        final path = BindingPath.fromDotNotation('form.items[0].name');

        expect(path.toString(), contains('form.items[0].name'));
      });
    });
  });
}
