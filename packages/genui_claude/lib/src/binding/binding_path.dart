import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Represents a parsed binding path with support for both dot notation
/// (A2UI format: "form.email", "items[0].name") and slash notation
/// (GenUI format: "/form/email", "/items/0/name").
///
/// This class handles path parsing, conversion between notations, and
/// path manipulation operations needed for the data binding engine.
@immutable
class BindingPath {
  /// Creates a BindingPath from segments.
  const BindingPath._(this.segments, {this.isAbsolute = true});

  /// Parses A2UI dot notation: "form.email", "items[0].name"
  ///
  /// Supports:
  /// - Simple paths: "email" → ["email"]
  /// - Nested paths: "form.email" → ["form", "email"]
  /// - Array indices: "items[0]" → ["items", "0"]
  /// - Mixed paths: "form.items[0].name" → ["form", "items", "0", "name"]
  factory BindingPath.fromDotNotation(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return const BindingPath._([]);
    }

    final segments = <String>[];

    // Parse the path character by character to handle both dots and brackets
    final buffer = StringBuffer();

    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (char == '.') {
        // End current segment on dot
        if (buffer.isNotEmpty) {
          segments.add(buffer.toString());
          buffer.clear();
        }
      } else if (char == '[') {
        // End current segment before bracket
        if (buffer.isNotEmpty) {
          segments.add(buffer.toString());
          buffer.clear();
        }
        // Find the closing bracket
        final closeIndex = trimmed.indexOf(']', i);
        if (closeIndex > i + 1) {
          segments.add(trimmed.substring(i + 1, closeIndex));
          i = closeIndex; // Skip past the closing bracket
        }
      } else if (char == ']') {
        // Skip closing brackets (handled above)
        continue;
      } else {
        buffer.write(char);
      }
    }

    // Add any remaining content
    if (buffer.isNotEmpty) {
      segments.add(buffer.toString());
    }

    return BindingPath._(segments);
  }

  /// Parses GenUI slash notation: "/form/email", "/items/0/name"
  ///
  /// Supports:
  /// - Absolute paths (starting with /): "/form/email"
  /// - Relative paths: "form/email"
  factory BindingPath.fromSlashNotation(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return const BindingPath._([], isAbsolute: false);
    }

    final isAbsolute = trimmed.startsWith('/');
    final pathToSplit = isAbsolute ? trimmed.substring(1) : trimmed;

    if (pathToSplit.isEmpty) {
      return BindingPath._(const [], isAbsolute: isAbsolute);
    }

    final segments =
        pathToSplit.split('/').where((s) => s.isNotEmpty).toList();

    return BindingPath._(segments, isAbsolute: isAbsolute);
  }

  /// The path segments (e.g., ['form', 'email'] or ['items', '0', 'name'])
  final List<String> segments;

  /// Whether this is an absolute path (starts from root)
  final bool isAbsolute;

  /// Converts to A2UI dot notation string.
  ///
  /// Array indices are formatted with brackets: "items[0].name"
  String toDotNotation() {
    if (segments.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isNumeric = int.tryParse(segment) != null;

      if (isNumeric) {
        // Format as array index
        buffer.write('[$segment]');
      } else {
        // Add dot separator for non-first segments (after both array indices and properties)
        if (i > 0) {
          buffer.write('.');
        }
        buffer.write(segment);
      }
    }

    return buffer.toString();
  }

  /// Converts to GenUI slash notation string.
  ///
  /// Absolute paths start with /: "/form/email"
  /// Relative paths omit leading /: "form/email"
  String toSlashNotation() {
    if (segments.isEmpty) {
      return isAbsolute ? '/' : '';
    }

    final path = segments.join('/');
    return isAbsolute ? '/$path' : path;
  }

  /// Returns parent path (e.g., "items[0].name" → "items[0]")
  ///
  /// Returns null if this is a single segment or empty path.
  BindingPath? get parent {
    if (segments.length <= 1) {
      return null;
    }

    return BindingPath._(
      segments.sublist(0, segments.length - 1),
      isAbsolute: isAbsolute,
    );
  }

  /// Returns the last segment (property name or index).
  ///
  /// Returns empty string for empty paths.
  String get leaf {
    if (segments.isEmpty) {
      return '';
    }
    return segments.last;
  }

  /// Joins with another path.
  ///
  /// The child path's segments are appended to this path's segments.
  BindingPath join(BindingPath other) {
    return BindingPath._(
      [...segments, ...other.segments],
      isAbsolute: isAbsolute,
    );
  }

  /// Checks if this path starts with another path.
  ///
  /// Returns true if all segments of [other] match the beginning
  /// of this path's segments.
  bool startsWith(BindingPath other) {
    if (other.segments.length > segments.length) {
      return false;
    }

    for (var i = 0; i < other.segments.length; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BindingPath) return false;

    // Use deep equality for list comparison
    const listEquals = ListEquality<String>();
    return isAbsolute == other.isAbsolute &&
        listEquals.equals(segments, other.segments);
  }

  @override
  int get hashCode => Object.hash(
        isAbsolute,
        const ListEquality<String>().hash(segments),
      );

  @override
  String toString() => 'BindingPath(${toDotNotation()}, absolute: $isAbsolute)';
}
