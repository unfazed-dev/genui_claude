import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:genui_claude/src/search/indexed_catalog_item.dart';
import 'package:genui_claude/src/search/keyword_extractor.dart';

/// A searchable index of tool schemas.
///
/// Provides efficient keyword-based search over a catalog of tools,
/// ranking results by relevance.
class ToolCatalogIndex {
  /// Creates an empty tool catalog index.
  ToolCatalogIndex([KeywordExtractor? extractor])
      : _extractor = extractor ?? KeywordExtractor();

  final KeywordExtractor _extractor;

  /// Items indexed by name for O(1) lookup.
  final Map<String, IndexedCatalogItem> _itemsByName = {};

  /// Inverted index: keyword → list of item names.
  final Map<String, Set<String>> _keywordIndex = {};

  /// Returns the number of indexed tools.
  int get size => _itemsByName.length;

  /// Returns all indexed tool names.
  List<String> get allNames => _itemsByName.keys.toList();

  /// Adds a single schema to the index.
  void addSchema(A2uiToolSchema schema) {
    // Skip if already indexed
    if (_itemsByName.containsKey(schema.name)) return;

    final item = IndexedCatalogItem.fromSchema(schema, _extractor);
    _itemsByName[schema.name] = item;

    // Update inverted index
    for (final keyword in item.keywords) {
      _keywordIndex.putIfAbsent(keyword, () => {}).add(item.name);
    }
  }

  /// Adds multiple schemas to the index.
  void addSchemas(Iterable<A2uiToolSchema> schemas) {
    for (final schema in schemas) {
      addSchema(schema);
    }
  }

  /// Searches for tools matching the given query.
  ///
  /// The query is tokenized into keywords, and tools are ranked
  /// by how many keywords they match.
  ///
  /// [query] - The search query (can be multiple words).
  /// [maxResults] - Maximum number of results to return (default: 10).
  ///
  /// Returns a list of matching schemas, ordered by relevance.
  List<A2uiToolSchema> search(String query, {int maxResults = 10}) {
    if (query.isEmpty) return [];

    // Tokenize query
    final queryTerms = _extractor.extractFromDescription(query).toList();
    if (queryTerms.isEmpty) return [];

    // Find candidate items using inverted index
    final candidateNames = <String>{};
    for (final term in queryTerms) {
      // Look for exact keyword matches
      if (_keywordIndex.containsKey(term)) {
        candidateNames.addAll(_keywordIndex[term]!);
      }

      // Also look for prefix matches
      for (final keyword in _keywordIndex.keys) {
        if (keyword.startsWith(term)) {
          candidateNames.addAll(_keywordIndex[keyword]!);
        }
      }
    }

    if (candidateNames.isEmpty) return [];

    // Score candidates
    final scoredItems = <_ScoredItem>[];
    for (final name in candidateNames) {
      final item = _itemsByName[name]!;
      final score = item.relevanceScore(queryTerms);
      if (score > 0) {
        scoredItems.add(_ScoredItem(item: item, score: score));
      }
    }

    // Sort by score descending
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    // Return top results
    return scoredItems.take(maxResults).map((s) => s.item.schema).toList();
  }

  /// Gets a schema by exact name.
  ///
  /// Returns null if not found.
  A2uiToolSchema? getSchemaByName(String name) {
    return _itemsByName[name]?.schema;
  }

  /// Gets multiple schemas by their names.
  ///
  /// Skips names that don't exist in the index.
  List<A2uiToolSchema> getSchemasByNames(Iterable<String> names) {
    return names
        .map((name) => _itemsByName[name]?.schema)
        .whereType<A2uiToolSchema>()
        .toList();
  }

  /// Clears all indexed items.
  void clear() {
    _itemsByName.clear();
    _keywordIndex.clear();
  }
}

/// Internal class for scoring search results.
class _ScoredItem {
  _ScoredItem({required this.item, required this.score});

  final IndexedCatalogItem item;
  final int score;
}
