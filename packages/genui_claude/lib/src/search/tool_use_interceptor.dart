import 'dart:convert';

import 'package:a2ui_claude/a2ui_claude.dart';

import 'package:genui_claude/src/search/catalog_search_tool.dart';
import 'package:genui_claude/src/search/tool_search_handler.dart';

/// Callback invoked when tools are loaded.
typedef OnToolsLoadedCallback = void Function(List<A2uiToolSchema> schemas);

/// Intercepts search_catalog and load_tools tool calls locally.
///
/// This interceptor handles search tool calls before they reach the API,
/// processing them against a local [ToolSearchHandler] and returning
/// results immediately.
class ToolUseInterceptor {
  /// Creates a tool use interceptor.
  ToolUseInterceptor({
    required this.handler,
    this.onToolsLoaded,
  });

  /// The handler for search and load operations.
  final ToolSearchHandler handler;

  /// Optional callback invoked when tools are loaded.
  final OnToolsLoadedCallback? onToolsLoaded;

  /// Returns whether this interceptor should handle the given tool.
  bool shouldIntercept(String toolName) {
    return CatalogSearchTool.isSearchTool(toolName);
  }

  /// Intercepts and processes a tool call locally.
  ///
  /// Returns the result as a JSON-serializable map.
  ///
  /// Throws [ArgumentError] if the tool is not a search tool.
  Map<String, dynamic> intercept({
    required String toolName,
    required Map<String, dynamic> input,
  }) {
    switch (toolName) {
      case CatalogSearchTool.searchCatalogName:
        return _handleSearch(input);
      case CatalogSearchTool.loadToolsName:
        return _handleLoad(input);
      default:
        throw ArgumentError('Unknown search tool: $toolName');
    }
  }

  /// Creates a complete tool result for a tool call.
  ///
  /// Returns an [InterceptedToolResult] with the result content
  /// or an error if the tool is unknown.
  InterceptedToolResult createToolResult({
    required String toolUseId,
    required String toolName,
    required Map<String, dynamic> input,
  }) {
    try {
      final result = intercept(toolName: toolName, input: input);
      return InterceptedToolResult(
        toolUseId: toolUseId,
        content: jsonEncode(result),
        isError: false,
      );
    } on Object catch (e) {
      return InterceptedToolResult(
        toolUseId: toolUseId,
        content: 'Error processing $toolName: $e',
        isError: true,
      );
    }
  }

  Map<String, dynamic> _handleSearch(Map<String, dynamic> input) {
    final searchInput = SearchCatalogInput.fromJson(input);
    final output = handler.handleSearchCatalog(searchInput);
    return output.toJson();
  }

  Map<String, dynamic> _handleLoad(Map<String, dynamic> input) {
    final loadInput = LoadToolsInput.fromJson(input);
    final result = handler.handleLoadTools(loadInput);

    // Notify callback of loaded schemas
    if (result.schemas.isNotEmpty && onToolsLoaded != null) {
      onToolsLoaded!(result.schemas);
    }

    return result.output.toJson();
  }
}

/// Result of an intercepted tool call.
class InterceptedToolResult {
  /// Creates an intercepted tool result.
  const InterceptedToolResult({
    required this.toolUseId,
    required this.content,
    required this.isError,
  });

  /// The tool use ID this result corresponds to.
  final String toolUseId;

  /// The result content (JSON string or error message).
  final String content;

  /// Whether this result represents an error.
  final bool isError;
}
