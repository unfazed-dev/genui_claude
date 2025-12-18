import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:genui_claude/src/search/keyword_extractor.dart';
import 'package:meta/meta.dart';

/// A catalog item enriched with searchable keywords.
///
/// Wraps an [A2uiToolSchema] with extracted keywords for efficient
/// full-text search capabilities.
@immutable
class IndexedCatalogItem {
  /// Creates an indexed catalog item.
  const IndexedCatalogItem._({
    required this.name,
    required this.schema,
    required this.keywords,
  });

  /// Creates an indexed item from a tool schema.
  ///
  /// Automatically extracts keywords from the schema's name,
  /// description, and input schema properties.
  factory IndexedCatalogItem.fromSchema(
    A2uiToolSchema schema, [
    KeywordExtractor? extractor,
  ]) {
    final keywordExtractor = extractor ?? KeywordExtractor();
    final keywords = keywordExtractor.extractAll(
      name: schema.name,
      description: schema.description,
      schema: schema.inputSchema,
    );

    return IndexedCatalogItem._(
      name: schema.name,
      schema: schema,
      keywords: keywords,
    );
  }

  /// The tool name (same as schema.name).
  final String name;

  /// The original tool schema.
  final A2uiToolSchema schema;

  /// Extracted searchable keywords, sorted alphabetically.
  final List<String> keywords;

  /// Checks if this item matches a search query.
  ///
  /// Returns true if any keyword starts with or equals the query.
  /// The match is case-insensitive.
  bool matchesQuery(String query) {
    if (query.isEmpty) return false;

    final normalizedQuery = query.toLowerCase();
    return keywords.any(
      (keyword) => keyword.startsWith(normalizedQuery),
    );
  }

  /// Calculates a relevance score for the given query terms.
  ///
  /// Higher scores indicate more relevant matches.
  /// Returns 0 if no terms match.
  int relevanceScore(List<String> queryTerms) {
    if (queryTerms.isEmpty) return 0;

    var score = 0;
    for (final term in queryTerms) {
      final normalizedTerm = term.toLowerCase();
      for (final keyword in keywords) {
        if (keyword == normalizedTerm) {
          // Exact match scores higher
          score += 3;
        } else if (keyword.startsWith(normalizedTerm)) {
          // Prefix match scores lower
          score += 1;
        }
      }
    }
    return score;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexedCatalogItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'IndexedCatalogItem(name: $name, keywords: ${keywords.length})';
}
