import 'package:a2ui_claude/a2ui_claude.dart';
import 'package:flutter/material.dart';
import 'package:genui_claude/genui_claude.dart';

/// Tool search demo screen demonstrating large catalog support.
///
/// This example shows how to use the tool search feature:
/// - ToolCatalogIndex for searchable tool indexing
/// - KeywordExtractor for automatic metadata generation
/// - search_catalog and load_tools tool schemas
/// - ToolUseInterceptor for local search handling
class ToolSearchDemoScreen extends StatefulWidget {
  const ToolSearchDemoScreen({super.key});

  @override
  State<ToolSearchDemoScreen> createState() => _ToolSearchDemoScreenState();
}

class _ToolSearchDemoScreenState extends State<ToolSearchDemoScreen> {
  final _searchController = TextEditingController();
  late final ToolCatalogIndex _index;
  List<A2uiToolSchema> _searchResults = [];
  final Set<String> _loadedTools = {};

  @override
  void initState() {
    super.initState();
    _initializeIndex();
  }

  void _initializeIndex() {
    _index = ToolCatalogIndex();

    // Add a large set of example tools to demonstrate search
    final tools = _generateLargeCatalog();
    _index.addSchemas(tools);
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _index.search(query);
    });
  }

  void _loadTool(String name) {
    setState(() {
      _loadedTools.add(name);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded tool: $name')),
    );
  }

  void _clearLoadedTools() {
    _loadedTools.clear();
    setState(() {});
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
            _buildSearchSection(),
            const SizedBox(height: 24),
            _buildLoadedToolsSection(),
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
              'For large widget catalogs (100+ items), loading all tools upfront '
              "bloats Claude's context window. Tool search enables Claude to "
              'discover and load only the tools it needs.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: 'Indexed Tools',
                  value: _index.size.toString(),
                  icon: Icons.inventory_2,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Loaded',
                  value: _loadedTools.length.toString(),
                  icon: Icons.download_done,
                ),
              ],
            ),
          ],
        ),
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
              'Try searching for: "input", "chart", "form", "navigation", "date"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
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
            const SizedBox(height: 16),
            if (_searchResults.isNotEmpty) ...[
              Text(
                'Results (${_searchResults.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._searchResults.map(
                (tool) => _SearchResultTile(
                  tool: tool,
                  isLoaded: _loadedTools.contains(tool.name),
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

  Widget _buildLoadedToolsSection() {
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
                Text(
                  'Loaded Tools (Session)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_loadedTools.isNotEmpty)
                  TextButton(
                    onPressed: _clearLoadedTools,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadedTools.isEmpty)
              const Text(
                'No tools loaded yet. Search and load tools above.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _loadedTools.map((name) {
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
                  'Integration Example',
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
// Create searchable index from large catalog
final index = CatalogToolBridge.createIndexFromCatalog(
  largeCatalog,  // 100+ widgets
);

// Create search handler
final searchHandler = ToolSearchHandler(index: index);

// Create interceptor for local search handling
final interceptor = ToolUseInterceptor(
  searchHandler: searchHandler,
  onToolsLoaded: (tools) {
    // Callback when Claude loads new tools
    print('Loaded tools: ' + tools.length.toString());
  },
);

// Configure generator with search mode
final generator = ClaudeContentGenerator(
  apiKey: apiKey,
  config: ClaudeConfig(
    enableToolSearch: true,
    maxLoadedToolsPerSession: 50,
  ),
  // Only search tools initially (not all widgets)
  tools: CatalogToolBridge.withSearchTools(),
  toolInterceptor: interceptor,
);

// Claude can now search and load tools dynamically!''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
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
