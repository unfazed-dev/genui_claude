import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:genui_claude/src/search/catalog_search_tool.dart';
import 'package:genui_claude/src/search/tool_catalog_index.dart';
import 'package:meta/meta.dart';

/// Handles search_catalog and load_tools tool requests.
///
/// This handler processes search queries against a [ToolCatalogIndex]
/// and manages the set of loaded tools for a session.
class ToolSearchHandler {
  /// Creates a tool search handler.
  ToolSearchHandler({required this.index});

  /// The catalog index to search.
  final ToolCatalogIndex index;

  /// The set of tool names that have been loaded in this session.
  final Set<String> _loadedToolNames = {};

  /// Returns the set of currently loaded tool names.
  Set<String> get loadedToolNames => Set.unmodifiable(_loadedToolNames);

  /// Handles a search_catalog tool request.
  ///
  /// Searches the index for tools matching the query and returns
  /// results with relevance scores.
  SearchCatalogOutput handleSearchCatalog(SearchCatalogInput input) {
    final results = index.search(input.query, maxResults: input.maxResults);

    final searchResults = results.map((schema) {
      // Calculate a simple relevance score based on the number of matching terms
      final queryTerms = _extractQueryTerms(input.query);
      final score = _calculateRelevance(schema, queryTerms);

      return SearchResult(
        name: schema.name,
        description: schema.description,
        relevance: score,
      );
    }).toList();

    return SearchCatalogOutput(
      results: searchResults,
      totalAvailable: index.size,
    );
  }

  /// Handles a load_tools tool request.
  ///
  /// Loads the requested tools from the index and adds them to the
  /// loaded tools set for this session.
  LoadToolsResult handleLoadTools(LoadToolsInput input) {
    // Remove duplicates
    final uniqueNames = input.toolNames.toSet();

    final loaded = <String>[];
    final notFound = <String>[];
    final schemas = <A2uiToolSchema>[];

    for (final name in uniqueNames) {
      final schema = index.getSchemaByName(name);
      if (schema != null) {
        loaded.add(name);
        schemas.add(schema);
        _loadedToolNames.add(name);
      } else {
        notFound.add(name);
      }
    }

    return LoadToolsResult(
      output: LoadToolsOutput(loaded: loaded, notFound: notFound),
      schemas: schemas,
    );
  }

  /// Clears all loaded tools.
  void clearLoadedTools() {
    _loadedToolNames.clear();
  }

  /// Returns the schemas for all currently loaded tools.
  List<A2uiToolSchema> getLoadedSchemas() {
    return index.getSchemasByNames(_loadedToolNames);
  }

  /// Extracts normalized query terms from a search query.
  List<String> _extractQueryTerms(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.length >= 2)
        .toList();
  }

  /// Calculates a relevance score for a schema based on query terms.
  double _calculateRelevance(A2uiToolSchema schema, List<String> queryTerms) {
    if (queryTerms.isEmpty) return 0;

    var matches = 0;
    final nameLower = schema.name.toLowerCase();
    final descLower = schema.description.toLowerCase();

    for (final term in queryTerms) {
      if (nameLower.contains(term) || descLower.contains(term)) {
        matches++;
      }
    }

    return matches / queryTerms.length;
  }
}

/// Result of a load_tools operation.
@immutable
class LoadToolsResult {
  /// Creates a load tools result.
  const LoadToolsResult({
    required this.output,
    required this.schemas,
  });

  /// The output to return to the caller.
  final LoadToolsOutput output;

  /// The schemas that were loaded.
  final List<A2uiToolSchema> schemas;
}
