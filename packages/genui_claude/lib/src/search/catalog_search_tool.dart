import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:meta/meta.dart';

/// Defines the search_catalog and load_tools tools for dynamic tool discovery.
///
/// These tools enable Claude to search and load relevant widgets from large
/// catalogs without bloating the context with all tool definitions.
class CatalogSearchTool {
  CatalogSearchTool._();

  /// Name of the search catalog tool.
  static const String searchCatalogName = 'search_catalog';

  /// Name of the load tools tool.
  static const String loadToolsName = 'load_tools';

  /// The search_catalog tool schema.
  ///
  /// Allows Claude to search the widget catalog by query string.
  static const A2uiToolSchema searchCatalogTool = A2uiToolSchema(
    name: searchCatalogName,
    description: 'Search the widget catalog to find relevant components. '
        'Use this to discover available widgets before building UI.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Search query describing the desired widget '
              '(e.g., "date picker", "data table", "chart")',
        },
        'categories': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Optional list of categories to filter by '
              '(e.g., ["input", "data-display", "navigation"])',
        },
        'max_results': {
          'type': 'integer',
          'description': 'Maximum number of results to return (default: 10)',
          'default': 10,
        },
      },
      'required': ['query'],
    },
  );

  /// The load_tools tool schema.
  ///
  /// Allows Claude to load specific tools by name for use in the session.
  static const A2uiToolSchema loadToolsTool = A2uiToolSchema(
    name: loadToolsName,
    description: 'Load specific widget tools by name to make them available '
        'for use. Call this after searching to load the widgets you need.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'tool_names': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'List of tool names to load '
              '(e.g., ["date_picker", "data_table"])',
        },
      },
      'required': ['tool_names'],
    },
  );

  /// All search-related tools.
  static List<A2uiToolSchema> get allTools => [searchCatalogTool, loadToolsTool];

  /// Names of all search-related tools.
  static Set<String> get toolNames => {searchCatalogName, loadToolsName};

  /// Check if a tool name is a search-related tool.
  static bool isSearchTool(String toolName) => toolNames.contains(toolName);
}

/// Input model for the search_catalog tool.
@immutable
class SearchCatalogInput {
  /// Creates a search catalog input.
  const SearchCatalogInput({
    required this.query,
    this.categories,
    this.maxResults = 10,
  });

  /// Creates from JSON input.
  factory SearchCatalogInput.fromJson(Map<String, dynamic> json) {
    return SearchCatalogInput(
      query: json['query'] as String,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>(),
      maxResults: json['max_results'] as int? ?? 10,
    );
  }

  /// The search query.
  final String query;

  /// Optional category filters.
  final List<String>? categories;

  /// Maximum number of results.
  final int maxResults;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'query': query,
        if (categories != null) 'categories': categories,
        'max_results': maxResults,
      };
}

/// Input model for the load_tools tool.
@immutable
class LoadToolsInput {
  /// Creates a load tools input.
  const LoadToolsInput({required this.toolNames});

  /// Creates from JSON input.
  factory LoadToolsInput.fromJson(Map<String, dynamic> json) {
    return LoadToolsInput(
      toolNames: (json['tool_names'] as List<dynamic>).cast<String>(),
    );
  }

  /// The tool names to load.
  final List<String> toolNames;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'tool_names': toolNames};
}

/// A single search result.
@immutable
class SearchResult {
  /// Creates a search result.
  const SearchResult({
    required this.name,
    required this.description,
    required this.relevance,
  });

  /// Creates a search result from a schema with a relevance score.
  factory SearchResult.fromSchemaWithScore({
    required String name,
    required String description,
    required int score,
    required int maxScore,
  }) {
    return SearchResult(
      name: name,
      description: description,
      relevance: maxScore > 0 ? score / maxScore : 0.0,
    );
  }

  /// The tool name.
  final String name;

  /// The tool description.
  final String description;

  /// Relevance score (0.0 to 1.0).
  final double relevance;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'relevance': relevance,
      };
}

/// Output model for the search_catalog tool.
@immutable
class SearchCatalogOutput {
  /// Creates a search catalog output.
  const SearchCatalogOutput({
    required this.results,
    required this.totalAvailable,
  });

  /// The search results.
  final List<SearchResult> results;

  /// Total number of tools available in the catalog.
  final int totalAvailable;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'results': results.map((r) => r.toJson()).toList(),
        'total_available': totalAvailable,
      };
}

/// Output model for the load_tools tool.
@immutable
class LoadToolsOutput {
  /// Creates a load tools output.
  const LoadToolsOutput({
    required this.loaded,
    required this.notFound,
  });

  /// The tools that were successfully loaded.
  final List<String> loaded;

  /// The tools that were not found.
  final List<String> notFound;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'loaded': loaded,
        'not_found': notFound,
      };
}
