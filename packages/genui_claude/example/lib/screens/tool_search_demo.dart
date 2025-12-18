import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter/material.dart';
import 'package:genui_claude/genui_claude.dart';

/// Tool search demo screen demonstrating ALL tool search features.
///
/// This example shows comprehensive tool search capabilities:
/// - ToolCatalogIndex: indexing, searching, batch lookups, index management
/// - KeywordExtractor: stop words, extraction methods, schema parsing
/// - ToolSearchHandler: search/load handling, session management
/// - ToolUseInterceptor: tool interception, callback handling
/// - CatalogSearchTool: tool schemas, input/output models
/// - IndexedCatalogItem: keywords, relevance scoring
class ToolSearchDemoScreen extends StatefulWidget {
  const ToolSearchDemoScreen({super.key});

  @override
  State<ToolSearchDemoScreen> createState() => _ToolSearchDemoScreenState();
}

class _ToolSearchDemoScreenState extends State<ToolSearchDemoScreen> {
  final _searchController = TextEditingController();
  late final ToolCatalogIndex _index;
  late final ToolSearchHandler _handler;
  late final ToolUseInterceptor _interceptor;
  final KeywordExtractor _extractor = KeywordExtractor();

  List<A2uiToolSchema> _searchResults = [];
  final List<String> _eventLog = [];
  int _maxResults = 10;

  @override
  void initState() {
    super.initState();
    _initializeIndex();
  }

  void _initializeIndex() {
    // Create index with custom extractor
    _index = ToolCatalogIndex(_extractor);

    // Add a large set of example tools to demonstrate search
    final tools = _generateLargeCatalog();
    _index.addSchemas(tools);

    // Create handler with index
    _handler = ToolSearchHandler(index: _index);

    // Create interceptor with callback
    _interceptor = ToolUseInterceptor(
      handler: _handler,
      onToolsLoaded: (schemas) {
        _addEvent('Tools loaded via interceptor: ${schemas.map((s) => s.name).join(", ")}');
      },
    );
  }

  /// Generates a large catalog of example tools for demonstration.
  List<A2uiToolSchema> _generateLargeCatalog() {
    return [
      // Form controls
      _tool('text_input', 'Text input field for single-line text entry'),
      _tool('text_area', 'Multi-line text area for longer content'),
      _tool('number_input', 'Numeric input with validation'),
      _tool('email_input', 'Email input with format validation'),
      _tool('password_input', 'Secure password entry field'),
      _tool('phone_input', 'Phone number input with formatting'),
      _tool('date_picker', 'Calendar-based date selection'),
      _tool('time_picker', 'Time selection with hour and minute'),
      _tool('datetime_picker', 'Combined date and time selection'),
      _tool('dropdown', 'Dropdown select menu with options'),
      _tool('checkbox', 'Single checkbox for boolean values'),
      _tool('checkbox_group', 'Group of checkboxes for multiple selection'),
      _tool('radio_group', 'Radio buttons for single selection'),
      _tool('toggle_switch', 'On/off toggle switch'),
      _tool('slider', 'Range slider for numeric values'),
      _tool('range_slider', 'Dual-handle range selection'),
      _tool('file_upload', 'File upload with drag and drop'),
      _tool('image_upload', 'Image upload with preview'),
      _tool('color_picker', 'Color selection widget'),
      _tool('rating', 'Star rating input'),

      // Display components
      _tool('text_display', 'Simple text display'),
      _tool('heading', 'Section heading with levels'),
      _tool('paragraph', 'Body text paragraph'),
      _tool('label', 'Form field label'),
      _tool('badge', 'Status badge or tag'),
      _tool('chip', 'Interactive chip component'),
      _tool('avatar', 'User avatar image'),
      _tool('icon', 'Material icon display'),
      _tool('image', 'Image display with fallback'),
      _tool('video_player', 'Video playback component'),
      _tool('audio_player', 'Audio playback component'),

      // Layout components
      _tool('container', 'Generic container with padding'),
      _tool('card', 'Material card with elevation'),
      _tool('list_tile', 'List item with leading/trailing'),
      _tool('expansion_tile', 'Expandable list item'),
      _tool('divider', 'Horizontal divider line'),
      _tool('spacer', 'Flexible spacing element'),
      _tool('row', 'Horizontal layout container'),
      _tool('column', 'Vertical layout container'),
      _tool('grid', 'Grid layout for items'),
      _tool('wrap', 'Wrap layout for flowing content'),

      // Navigation
      _tool('button', 'Primary action button'),
      _tool('text_button', 'Flat text button'),
      _tool('icon_button', 'Icon-only button'),
      _tool('floating_action_button', 'FAB floating action'),
      _tool('link', 'Hyperlink navigation'),
      _tool('tab_bar', 'Tab navigation bar'),
      _tool('bottom_navigation', 'Bottom navigation bar'),
      _tool('drawer', 'Side navigation drawer'),
      _tool('breadcrumb', 'Breadcrumb navigation'),

      // Data display
      _tool('data_table', 'Tabular data display with sorting'),
      _tool('list_view', 'Scrollable list of items'),
      _tool('grid_view', 'Grid of items'),
      _tool('carousel', 'Horizontal scrolling carousel'),
      _tool('timeline', 'Vertical timeline display'),
      _tool('tree_view', 'Hierarchical tree structure'),
      _tool('chart_bar', 'Bar chart visualization'),
      _tool('chart_line', 'Line chart visualization'),
      _tool('chart_pie', 'Pie chart visualization'),
      _tool('progress_bar', 'Linear progress indicator'),
      _tool('progress_circular', 'Circular progress indicator'),
      _tool('skeleton', 'Loading skeleton placeholder'),

      // Feedback
      _tool('alert', 'Alert message box'),
      _tool('snackbar', 'Brief notification message'),
      _tool('toast', 'Temporary toast notification'),
      _tool('dialog', 'Modal dialog box'),
      _tool('bottom_sheet', 'Bottom sheet overlay'),
      _tool('tooltip', 'Hover tooltip'),
      _tool('popover', 'Popover menu'),
    ];
  }

  A2uiToolSchema _tool(String name, String description) {
    return A2uiToolSchema(
      name: name,
      description: description,
      inputSchema: {
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'description': 'The value to display'},
        },
      },
    );
  }

  void _addEvent(String event) {
    setState(() {
      _eventLog.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $event');
      if (_eventLog.length > 20) {
        _eventLog.removeLast();
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _index.search(query, maxResults: _maxResults);
    });
    _addEvent('Search "$query" → ${_searchResults.length} results');
  }

  void _loadTool(String name) {
    // Use handler to load tools
    final result = _handler.handleLoadTools(LoadToolsInput(toolNames: [name]));
    setState(() {});

    if (result.output.loaded.isNotEmpty) {
      _addEvent('Loaded: ${result.output.loaded.join(", ")}');
    }
    if (result.output.notFound.isNotEmpty) {
      _addEvent('Not found: ${result.output.notFound.join(", ")}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded tool: $name')),
    );
  }

  void _loadMultipleTools(List<String> names) {
    // Demonstrate batch loading
    final result = _handler.handleLoadTools(LoadToolsInput(toolNames: names));
    setState(() {});

    _addEvent('Batch load: ${result.output.loaded.length} loaded, ${result.output.notFound.length} not found');
  }

  void _clearLoadedTools() {
    _handler.clearLoadedTools();
    _addEvent('Cleared all loaded tools');
    setState(() {});
  }

  void _simulateInterception() {
    // Simulate tool use interception
    const toolName = 'search_catalog';
    final input = {'query': 'chart', 'max_results': 5};

    if (_interceptor.shouldIntercept(toolName)) {
      final result = _interceptor.createToolResult(
        toolUseId: 'test-${DateTime.now().millisecondsSinceEpoch}',
        toolName: toolName,
        input: input,
      );
      _addEvent('Intercepted $toolName: isError=${result.isError}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Search Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildIndexStatsSection(),
            const SizedBox(height: 24),
            _buildSearchSection(),
            const SizedBox(height: 24),
            _buildKeywordExtractorSection(),
            const SizedBox(height: 24),
            _buildInterceptorSection(),
            const SizedBox(height: 24),
            _buildLoadedToolsSection(),
            const SizedBox(height: 24),
            _buildEventLogSection(),
            const SizedBox(height: 24),
            _buildCodeSnippet(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Dynamic Tool Discovery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This demo showcases ALL features of the tool search engine:\n'
              '• ToolCatalogIndex: inverted keyword index, search, batch lookup\n'
              '• KeywordExtractor: stop words, name/desc/schema extraction\n'
              '• ToolSearchHandler: search, load, session management\n'
              '• ToolUseInterceptor: local tool interception\n'
              '• CatalogSearchTool: search_catalog & load_tools schemas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ToolCatalogIndex Stats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: 'size',
                  value: _index.size.toString(),
                  icon: Icons.widgets,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'allNames',
                  value: '${_index.allNames.length} items',
                  icon: Icons.list,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Index Methods:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMethodRow('addSchema(schema)', 'Add single tool'),
            _buildMethodRow('addSchemas(list)', 'Add multiple tools'),
            _buildMethodRow('search(query, maxResults)', 'Keyword search'),
            _buildMethodRow('getSchemaByName(name)', 'Exact lookup'),
            _buildMethodRow('getSchemasByNames(names)', 'Batch lookup'),
            _buildMethodRow('clear()', 'Clear all indexed'),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    // Demonstrate batch lookup
                    final schemas = _index.getSchemasByNames(['button', 'slider', 'chart_bar']);
                    _addEvent('Batch lookup: found ${schemas.length} schemas');
                  },
                  icon: const Icon(Icons.batch_prediction),
                  label: const Text('Batch Lookup'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Demonstrate single lookup
                    final schema = _index.getSchemaByName('date_picker');
                    _addEvent('Single lookup: ${schema != null ? "found" : "not found"}');
                  },
                  child: const Text('Single Lookup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodRow(String method, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              method,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          Text(
            '→ $description',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Catalog',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try: "input", "chart", "form", "navigation", "date", "picker"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for tools...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Results:', style: TextStyle(fontSize: 10)),
                    DropdownButton<int>(
                      value: _maxResults,
                      items: [5, 10, 20, 50].map((v) {
                        return DropdownMenuItem(value: v, child: Text('$v'));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _maxResults = v ?? 10;
                        });
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_searchResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Results (${_searchResults.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      _loadMultipleTools(_searchResults.map((s) => s.name).toList());
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Load All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._searchResults.map(
                (tool) => _SearchResultTile(
                  tool: tool,
                  isLoaded: _handler.loadedToolNames.contains(tool.name),
                  onLoad: () => _loadTool(tool.name),
                ),
              ),
            ],
            if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No matching tools found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordExtractorSection() {
    // Demonstrate keyword extraction
    const exampleName = 'date_time_picker';
    const exampleDesc = 'A calendar-based date and time selection widget';
    final nameKeywords = _extractor.extractFromName(exampleName);
    final descKeywords = _extractor.extractFromDescription(exampleDesc);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'KeywordExtractor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildExtractionDemo('extractFromName("$exampleName")', nameKeywords),
            const SizedBox(height: 12),
            _buildExtractionDemo('extractFromDescription("...")', descKeywords),
            const SizedBox(height: 16),

            // Stop words demo
            ExpansionTile(
              title: const Text('Stop Words (filtered out)'),
              subtitle: Text('${KeywordExtractor.stopWords.length} words'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: KeywordExtractor.stopWords.take(30).map((word) {
                      return Chip(
                        label: Text(word, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    '... and more',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              'Min word length: ${KeywordExtractor.minWordLength}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionDemo(String method, Set<String> keywords) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            method,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: keywords.map((kw) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(kw, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterceptorSection() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'ToolUseInterceptor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Intercepts search_catalog and load_tools calls locally, '
              'without sending to the API.',
            ),
            const SizedBox(height: 16),

            // Show which tools are interceptable
            _buildInterceptRow('search_catalog', CatalogSearchTool.isSearchTool('search_catalog')),
            _buildInterceptRow('load_tools', CatalogSearchTool.isSearchTool('load_tools')),
            _buildInterceptRow('custom_widget', CatalogSearchTool.isSearchTool('custom_widget')),

            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _simulateInterception,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Simulate Interception'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterceptRow(String toolName, bool isIntercepted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isIntercepted ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isIntercepted ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            'shouldIntercept("$toolName")',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          const Text(' → '),
          Text(
            isIntercepted.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIntercepted ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedToolsSection() {
    final loadedTools = _handler.loadedToolNames;
    final loadedSchemas = _handler.getLoadedSchemas();

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_done, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ToolSearchHandler Session',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (loadedTools.isNotEmpty)
                  TextButton(
                    onPressed: _clearLoadedTools,
                    child: const Text('clearLoadedTools()'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: 'loadedToolNames',
                  value: loadedTools.length.toString(),
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'getLoadedSchemas()',
                  value: loadedSchemas.length.toString(),
                  icon: Icons.schema,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loadedTools.isEmpty)
              const Text(
                'No tools loaded yet. Search and load tools above.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: loadedTools.map((name) {
                  return Chip(
                    label: Text(name),
                    avatar: const Icon(Icons.check, size: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Event Log',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(_eventLog.clear);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _eventLog.isEmpty
                  ? const Center(
                      child: Text(
                        'Events will appear here...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _eventLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _eventLog[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSnippet() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Complete API Reference',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                '''
// === ToolCatalogIndex ===
final index = ToolCatalogIndex();
index.addSchema(schema);           // Add single
index.addSchemas(schemas);         // Add multiple
index.search(query, maxResults: 10); // Search
index.getSchemaByName('button');   // Exact lookup
index.getSchemasByNames(['a','b']); // Batch lookup
index.size;                        // Count
index.allNames;                    // All names
index.clear();                     // Clear all

// === KeywordExtractor ===
final extractor = KeywordExtractor();
extractor.extractFromName('date_picker');
extractor.extractFromDescription('Calendar...');
extractor.extractFromSchema(inputSchema);
extractor.extractAll(name: n, description: d, schema: s);
KeywordExtractor.stopWords;        // Filtered words
KeywordExtractor.minWordLength;    // Min length (2)

// === ToolSearchHandler ===
final handler = ToolSearchHandler(index: index);
handler.handleSearchCatalog(SearchCatalogInput(...));
handler.handleLoadTools(LoadToolsInput(...));
handler.loadedToolNames;           // Set<String>
handler.getLoadedSchemas();        // List<Schema>
handler.clearLoadedTools();        // Clear session

// === ToolUseInterceptor ===
final interceptor = ToolUseInterceptor(
  handler: handler,
  onToolsLoaded: (schemas) => print('Loaded!'),
);
interceptor.shouldIntercept('search_catalog'); // true
interceptor.intercept(toolName: n, input: {...});
interceptor.createToolResult(toolUseId: id, ...);

// === CatalogSearchTool ===
CatalogSearchTool.searchCatalogTool;  // Schema
CatalogSearchTool.loadToolsTool;      // Schema
CatalogSearchTool.allTools;           // Both
CatalogSearchTool.isSearchTool(name); // Check

// === Input/Output Models ===
SearchCatalogInput(query: q, maxResults: 10);
SearchCatalogOutput(results: [...], totalAvailable: n);
LoadToolsInput(toolNames: ['a', 'b']);
LoadToolsOutput(loaded: [...], notFound: [...]);
SearchResult(name: n, description: d, relevance: 0.8);''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.tool,
    required this.isLoaded,
    required this.onLoad,
  });

  final A2uiToolSchema tool;
  final bool isLoaded;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        leading: Icon(
          isLoaded ? Icons.check_circle : Icons.extension,
          color: isLoaded
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          tool.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          tool.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isLoaded
            ? const Text('Loaded', style: TextStyle(color: Colors.green))
            : FilledButton.tonal(
                onPressed: onLoad,
                child: const Text('Load'),
              ),
      ),
    );
  }
}
