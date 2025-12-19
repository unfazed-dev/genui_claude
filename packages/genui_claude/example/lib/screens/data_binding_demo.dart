import 'package:flutter/material.dart';
import 'package:genui_claude/genui_claude.dart';

/// Data binding demo screen demonstrating ALL binding engine features.
///
/// This example shows comprehensive data binding capabilities:
/// - BindingPath: dot notation, slash notation, array indices, path operations
/// - BindingMode: oneWay, twoWay, oneWayToSource
/// - BindingDefinition: all parse formats, value transformers
/// - BindingRegistry: multi-index lookup, unregistration, path queries
/// - BindingController: widget binding, value notifiers, lifecycle management
class DataBindingDemoScreen extends StatefulWidget {
  const DataBindingDemoScreen({super.key});

  @override
  State<DataBindingDemoScreen> createState() => _DataBindingDemoScreenState();
}

class _DataBindingDemoScreenState extends State<DataBindingDemoScreen> {
  // Simulated data model using ValueNotifiers
  final _dataModel = <String, ValueNotifier<dynamic>>{};

  // Binding infrastructure
  late final BindingRegistry _registry;
  late final BindingController _controller;

  // Example data paths - demonstrating various path formats
  static const _emailPath = 'form.email';
  static const _namePath = 'form.name';
  static const _agePath = 'form.age';
  static const _subscribedPath = 'form.subscribed';
  static const _itemsPath = 'items[0].name'; // Array index notation
  static const _nestedPath = 'user.profile.settings.theme'; // Deep nesting
  static const _labelPath = 'ui.labels.submit'; // One-way source

  // Transformer demonstration
  String _lastTransformedValue = '';

  @override
  void initState() {
    super.initState();
    _initializeDataModel();
    _initializeBindings();
  }

  void _initializeDataModel() {
    // Initialize with default values
    _dataModel[_emailPath] = ValueNotifier<dynamic>('user@example.com');
    _dataModel[_namePath] = ValueNotifier<dynamic>('John Doe');
    _dataModel[_agePath] = ValueNotifier<dynamic>(25);
    _dataModel[_subscribedPath] = ValueNotifier<dynamic>(false);
    _dataModel[_itemsPath] = ValueNotifier<dynamic>('First Item');
    _dataModel[_nestedPath] = ValueNotifier<dynamic>('dark');
    _dataModel[_labelPath] = ValueNotifier<dynamic>('Submit');
  }

  void _initializeBindings() {
    _registry = BindingRegistry();
    _controller = BindingController(
      registry: _registry,
      subscribe: _subscribe,
      update: _update,
    );

    // === Binding Mode Demonstrations ===

    // TWO-WAY BINDING: model ↔ widget (bidirectional)
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'email-input',
      dataBinding: {
        'value': {'path': _emailPath, 'mode': 'twoWay'},
      },
    );

    // TWO-WAY BINDING with string shorthand
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'name-input',
      dataBinding: {
        'value': {'path': _namePath, 'mode': 'twoWay'},
      },
    );

    // ONE-WAY BINDING: model → widget only (default)
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'age-display',
      dataBinding: {
        'value': {'path': _agePath, 'mode': 'oneWay'},
      },
    );

    // ONE-WAY-TO-SOURCE BINDING: widget → model only
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'label-source',
      dataBinding: {
        'value': {'path': _labelPath, 'mode': 'oneWayToSource'},
      },
    );

    // === Parse Format Demonstrations ===

    // Simple string format (shorthand)
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'subscribed-toggle',
      dataBinding: _subscribedPath, // Just the path string
    );

    // Map with string values format
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'item-display',
      dataBinding: {'value': _itemsPath}, // Property → path
    );

    // Full config format
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'theme-selector',
      dataBinding: {
        'value': {'path': _nestedPath, 'mode': 'twoWay'},
      },
    );

    // === Secondary Surface for Lifecycle Demo ===
    _controller.processWidgetBindings(
      surfaceId: 'secondary-surface',
      widgetId: 'secondary-email',
      dataBinding: {
        'value': {'path': _emailPath, 'mode': 'oneWay'},
      },
    );
  }

  /// Subscribe to a data model path - returns ValueNotifier for that path.
  ValueNotifier<dynamic> _subscribe(BindingPath path) {
    final key = path.toDotNotation();
    return _dataModel[key] ??= ValueNotifier<dynamic>(null);
  }

  /// Update a data model path.
  void _update(BindingPath path, dynamic value) {
    final key = path.toDotNotation();
    _dataModel[key]?.value = value;
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final notifier in _dataModel.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Binding Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildBindingModesSection(),
            const SizedBox(height: 24),
            _buildPathNotationsSection(),
            const SizedBox(height: 24),
            _buildTransformersSection(),
            const SizedBox(height: 24),
            _buildRegistrySection(),
            const SizedBox(height: 24),
            _buildLifecycleSection(),
            const SizedBox(height: 24),
            _buildDataModelViewer(),
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
                Icon(Icons.sync_alt,
                    color: Theme.of(context).colorScheme.primary,),
                const SizedBox(width: 8),
                Text(
                  'Data Binding Engine',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This demo showcases ALL features of the data binding engine:\n'
              '• Binding Modes (oneWay, twoWay, oneWayToSource)\n'
              '• Path Notations (dot, slash, array indices)\n'
              '• Value Transformers (toWidget, toModel)\n'
              '• Registry Lookups (by widget, surface, path)\n'
              '• Lifecycle Management (unregister, dispose)',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: 'Bindings',
                  value: _registry.hasBindings ? 'Active' : 'None',
                  icon: Icons.link,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Paths',
                  value: _dataModel.length.toString(),
                  icon: Icons.account_tree,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBindingModesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.primary,),
                const SizedBox(width: 8),
                Text(
                  'Binding Modes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TWO-WAY: Email
            _buildModeLabel('TWO-WAY', 'model ↔ widget', Colors.green),
            const SizedBox(height: 8),
            _BoundTextField(
              widgetId: 'email-input',
              label: 'Email (twoWay)',
              controller: _controller,
              icon: Icons.email,
            ),
            const SizedBox(height: 16),

            // ONE-WAY: Age display
            _buildModeLabel('ONE-WAY', 'model → widget', Colors.blue),
            const SizedBox(height: 8),
            _OneWayDisplay(
              widgetId: 'age-display',
              label: 'Age (oneWay - read only)',
              controller: _controller,
              icon: Icons.cake,
            ),
            const SizedBox(height: 8),
            // Button to update model directly
            FilledButton.tonalIcon(
              onPressed: () {
                final current = _dataModel[_agePath]?.value as int? ?? 25;
                _dataModel[_agePath]?.value = current + 1;
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('Increment Age (updates model)'),
            ),
            const SizedBox(height: 16),

            // ONE-WAY-TO-SOURCE: Label input
            _buildModeLabel(
                'ONE-WAY-TO-SOURCE', 'widget → model', Colors.orange,),
            const SizedBox(height: 8),
            _OneWayToSourceField(
              widgetId: 'label-source',
              label: 'Button Label (oneWayToSource)',
              controller: _controller,
              icon: Icons.label,
              initialValue: _dataModel[_labelPath]?.value?.toString() ?? '',
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<dynamic>(
              valueListenable: _dataModel[_labelPath]!,
              builder: (context, value, _) {
                return Text(
                  'Model receives: "$value"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeLabel(String mode, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: Text(
            mode,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(description, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPathNotationsSection() {
    // Demonstrate path parsing and conversion
    final dotPath = BindingPath.fromDotNotation('form.items[0].name');
    final slashPath = BindingPath.fromSlashNotation('/user/profile/settings');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Path Notations & Operations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dot notation demo
            _buildPathDemo(
              'Dot Notation',
              'form.items[0].name',
              dotPath,
            ),
            const SizedBox(height: 12),

            // Slash notation demo
            _buildPathDemo(
              'Slash Notation',
              '/user/profile/settings',
              slashPath,
            ),
            const SizedBox(height: 16),

            // Path operations
            Text(
              'Path Operations:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildOperationResult(
                'parent', dotPath.parent?.toDotNotation() ?? 'null',),
            _buildOperationResult('leaf', dotPath.leaf),
            _buildOperationResult(
                'isAbsolute', slashPath.isAbsolute.toString(),),
            _buildOperationResult(
              'join(other)',
              BindingPath.fromDotNotation('form')
                  .join(BindingPath.fromDotNotation('email'))
                  .toDotNotation(),
            ),
            _buildOperationResult(
              'startsWith(form)',
              dotPath
                  .startsWith(BindingPath.fromDotNotation('form'))
                  .toString(),
            ),
            const SizedBox(height: 12),

            // Array index widget
            _BoundTextField(
              widgetId: 'item-display',
              label: 'Array Item (items[0].name)',
              controller: _controller,
              icon: Icons.list,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathDemo(String title, String input, BindingPath path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Input: "$input"',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),),
          Text('Segments: ${path.segments}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),),
          Text('→ Dot: ${path.toDotNotation()}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),),
          Text('→ Slash: ${path.toSlashNotation()}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),),
        ],
      ),
    );
  }

  Widget _buildOperationResult(String operation, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '.$operation',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const Text(' → '),
          Text(
            result,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.transform,
                    color: Theme.of(context).colorScheme.primary,),
                const SizedBox(width: 8),
                Text(
                  'Value Transformers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Transformers convert values between model and widget formats:\n'
              '• toWidget: model → widget (e.g., int → formatted string)\n'
              '• toModel: widget → model (e.g., string → int)',
            ),
            const SizedBox(height: 16),

            // Create a binding with transformers programmatically
            _TransformerDemo(
              dataModel: _dataModel,
              onTransformed: (value) {
                setState(() {
                  _lastTransformedValue = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Last transformed: $_lastTransformedValue',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrySection() {
    final widgetBindings = _registry.getBindingsForWidget('email-input');
    final surfaceBindings = _registry.getBindingsForSurface('demo-surface');
    final pathBindings = _registry.getBindingsForPath(
      BindingPath.fromDotNotation(_emailPath),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage,
                    color: Theme.of(context).colorScheme.primary,),
                const SizedBox(width: 8),
                Text(
                  'Registry Lookups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLookupResult(
              'getBindingsForWidget("email-input")',
              '${widgetBindings.length} binding(s)',
            ),
            _buildLookupResult(
              'getBindingsForSurface("demo-surface")',
              '${surfaceBindings.length} binding(s)',
            ),
            _buildLookupResult(
              'getBindingsForPath("$_emailPath")',
              '${pathBindings.length} binding(s)',
            ),
            _buildLookupResult(
              'hasBindings',
              _registry.hasBindings.toString(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Surface Bindings:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...surfaceBindings.take(5).map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${b.widgetId}.${b.property} → ${b.path.toDotNotation()} (${b.mode.name})',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11,),
                    ),
                  ),
                ),
            if (surfaceBindings.length > 5)
              Text(
                '  ... and ${surfaceBindings.length - 5} more',
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookupResult(String method, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chevron_right, size: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: method,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                  const TextSpan(text: ' → '),
                  TextSpan(
                    text: result,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleSection() {
    final secondaryBindings =
        _registry.getBindingsForSurface('secondary-surface');

    return Card(
      color:
          Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delete_sweep,
                    color: Theme.of(context).colorScheme.error,),
                const SizedBox(width: 8),
                Text(
                  'Lifecycle Management',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Demonstrate binding cleanup methods:\n'
              '• unregisterWidget(widgetId) - removes single widget\n'
              '• unregisterSurface(surfaceId) - removes all in surface\n'
              '• dispose() - clears all bindings',
            ),
            const SizedBox(height: 16),
            Text(
              'Secondary Surface Bindings: ${secondaryBindings.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...secondaryBindings.map(
              (b) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${b.widgetId} → ${b.path.toDotNotation()}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: secondaryBindings.isEmpty
                      ? null
                      : () {
                          _controller.unregisterSurface('secondary-surface');
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Secondary surface unregistered!'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.delete),
                  label: const Text('Unregister Surface'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: secondaryBindings.isNotEmpty
                      ? null
                      : () {
                          // Re-register the secondary surface binding
                          _controller.processWidgetBindings(
                            surfaceId: 'secondary-surface',
                            widgetId: 'secondary-email',
                            dataBinding: {
                              'value': {'path': _emailPath, 'mode': 'oneWay'},
                            },
                          );
                          setState(() {});
                        },
                  child: const Text('Re-register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateFromModel() {
    // Simulate external update to data model
    _dataModel[_emailPath]?.value = 'updated@example.com';
    _dataModel[_namePath]?.value = 'Jane Smith';
    _dataModel[_agePath]?.value = 30;
    _dataModel[_subscribedPath]?.value = true;
    _dataModel[_itemsPath]?.value = 'Updated Item';
    _dataModel[_nestedPath]?.value = 'light';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data model updated! Watch widgets refresh.'),),
    );
  }

  Widget _buildDataModelViewer() {
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
                  'Data Model (Live)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.tonalIcon(
                  onPressed: _updateFromModel,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Update from Model'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Live data model display
            ..._dataModel.entries.map(
              (entry) => _DataModelEntry(
                path: entry.key,
                notifier: entry.value,
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
// === Path Notations ===
final dotPath = BindingPath.fromDotNotation('form.items[0].name');
final slashPath = BindingPath.fromSlashNotation('/user/profile');

// Path operations
dotPath.toDotNotation();    // form.items[0].name
dotPath.toSlashNotation();  // /form/items/0/name
dotPath.parent;             // form.items[0]
dotPath.leaf;               // name
dotPath.join(otherPath);    // Concatenate paths
dotPath.startsWith(prefix); // Check prefix

// === Binding Modes ===
// BindingMode.oneWay       - model → widget (default)
// BindingMode.twoWay       - model ↔ widget
// BindingMode.oneWayToSource - widget → model

// === Parse Formats ===
// String: "form.email" (shorthand, binds to 'value')
// Map<String>: {'value': 'form.email'}
// Config: {'value': {'path': 'form.email', 'mode': 'twoWay'}}

// === Controller API ===
final controller = BindingController(
  registry: BindingRegistry(),
  subscribe: dataModel.subscribe,
  update: dataModel.update,
);

// Register bindings
controller.processWidgetBindings(
  surfaceId: 'form-surface',
  widgetId: 'email-input',
  dataBinding: {'value': {'path': 'form.email', 'mode': 'twoWay'}},
);

// Get reactive value (applies toWidget transformer)
final notifier = controller.getValueNotifier(
  widgetId: 'email-input',
  property: 'value',
);

// Update from widget (applies toModel transformer)
controller.updateFromWidget(
  widgetId: 'email-input',
  property: 'value',
  value: 'new@example.com',
);

// === Lifecycle ===
controller.unregisterWidget('email-input');  // Remove widget
controller.unregisterSurface('form-surface'); // Remove surface
controller.dispose();  // Cleanup all

// === Registry Lookups ===
registry.getBindingsForWidget('email-input');
registry.getBindingsForSurface('form-surface');
registry.getBindingsForPath(path);
registry.getBindingForWidgetProperty('email-input', 'value');
registry.hasBindings;
registry.clear();''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
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

/// Stat chip widget.
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

/// A text field that's bound to the data model via BindingController.
class _BoundTextField extends StatefulWidget {
  const _BoundTextField({
    required this.widgetId,
    required this.label,
    required this.controller,
    this.icon,
  });

  final String widgetId;
  final String label;
  final BindingController controller;
  final IconData? icon;

  @override
  State<_BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<_BoundTextField> {
  late final TextEditingController _textController;
  ValueNotifier<dynamic>? _valueNotifier;
  bool _isUpdatingFromModel = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // Get the bound value notifier
    _valueNotifier = widget.controller.getValueNotifier(
      widgetId: widget.widgetId,
      property: 'value',
    );

    // Initialize text from model
    if (_valueNotifier != null) {
      _textController.text = _valueNotifier!.value?.toString() ?? '';
      _valueNotifier!.addListener(_onModelChanged);
    }
  }

  void _onModelChanged() {
    if (_isUpdatingFromModel) return;
    _isUpdatingFromModel = true;

    final newValue = _valueNotifier?.value?.toString() ?? '';
    if (_textController.text != newValue) {
      _textController.text = newValue;
    }

    _isUpdatingFromModel = false;
  }

  void _onWidgetChanged(String value) {
    if (_isUpdatingFromModel) return;

    // Update the model through the controller
    widget.controller.updateFromWidget(
      widgetId: widget.widgetId,
      property: 'value',
      value: value,
    );
  }

  @override
  void dispose() {
    _valueNotifier?.removeListener(_onModelChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        border: const OutlineInputBorder(),
        suffixIcon: Tooltip(
          message: 'Widget ID: ${widget.widgetId}',
          child: Icon(
            Icons.link,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      onChanged: _onWidgetChanged,
    );
  }
}

/// Display widget for ONE-WAY binding (read-only from model).
class _OneWayDisplay extends StatelessWidget {
  const _OneWayDisplay({
    required this.widgetId,
    required this.label,
    required this.controller,
    this.icon,
  });

  final String widgetId;
  final String label;
  final BindingController controller;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final notifier = controller.getValueNotifier(
      widgetId: widgetId,
      property: 'value',
    );

    return ValueListenableBuilder<dynamic>(
      valueListenable: notifier ?? ValueNotifier<dynamic>(''),
      builder: (context, value, _) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            suffixIcon: Tooltip(
              message: 'ONE-WAY: Cannot edit',
              child: Icon(
                Icons.lock,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Text(
            value?.toString() ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }
}

/// Input widget for ONE-WAY-TO-SOURCE binding (widget to model only).
class _OneWayToSourceField extends StatefulWidget {
  const _OneWayToSourceField({
    required this.widgetId,
    required this.label,
    required this.controller,
    required this.initialValue,
    this.icon,
  });

  final String widgetId;
  final String label;
  final BindingController controller;
  final String initialValue;
  final IconData? icon;

  @override
  State<_OneWayToSourceField> createState() => _OneWayToSourceFieldState();
}

class _OneWayToSourceFieldState extends State<_OneWayToSourceField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // ONE-WAY-TO-SOURCE: Widget updates model
    widget.controller.updateFromWidget(
      widgetId: widget.widgetId,
      property: 'value',
      value: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        border: const OutlineInputBorder(),
        suffixIcon: const Tooltip(
          message: 'ONE-WAY-TO-SOURCE: Updates model only',
          child: Icon(
            Icons.upload,
            size: 16,
            color: Colors.orange,
          ),
        ),
      ),
      onChanged: _onChanged,
    );
  }
}

/// Demonstrates value transformers.
class _TransformerDemo extends StatefulWidget {
  const _TransformerDemo({
    required this.dataModel,
    required this.onTransformed,
  });

  final Map<String, ValueNotifier<dynamic>> dataModel;
  final void Function(String value) onTransformed;

  @override
  State<_TransformerDemo> createState() => _TransformerDemoState();
}

class _TransformerDemoState extends State<_TransformerDemo> {
  late final BindingRegistry _registry;
  late final BindingController _controller;
  late final TextEditingController _textController;
  ValueNotifier<dynamic>? _notifier;

  // Transformer: multiply by 100 (model value 0.5 → widget shows 50)
  dynamic _toWidget(dynamic value) {
    if (value is num) {
      final result = (value * 100).round();
      widget.onTransformed('toWidget: $value × 100 = $result');
      return result;
    }
    return value;
  }

  // Transformer: divide by 100 (widget value 50 → model gets 0.5)
  dynamic _toModel(dynamic value) {
    if (value is num) {
      final result = value / 100;
      widget.onTransformed('toModel: $value ÷ 100 = $result');
      return result;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        final result = parsed / 100;
        widget.onTransformed('toModel: $value ÷ 100 = $result');
        return result;
      }
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // Create a separate controller for transformer demo
    _registry = BindingRegistry();
    _controller = BindingController(
      registry: _registry,
      subscribe: (path) {
        final key = path.toDotNotation();
        // Use a dedicated path for transformer demo
        widget.dataModel['transformer.percentage'] ??=
            ValueNotifier<dynamic>(0.75);
        return widget.dataModel[key] ??
            widget.dataModel['transformer.percentage']!;
      },
      update: (path, value) {
        final key = path.toDotNotation();
        widget.dataModel[key]?.value = value;
      },
    );

    // Create binding definition with transformers
    final definition = BindingDefinition(
      property: 'value',
      path: BindingPath.fromDotNotation('transformer.percentage'),
      mode: BindingMode.twoWay,
      toWidget: _toWidget,
      toModel: _toModel,
    );

    // Register with transformers
    final subscription = widget.dataModel['transformer.percentage'] ??=
        ValueNotifier<dynamic>(0.75);
    final binding = WidgetBinding(
      widgetId: 'transformer-input',
      surfaceId: 'transformer-surface',
      definition: definition,
      subscription: subscription,
    );
    _registry.register(binding);

    // Get the transformed notifier
    _notifier = _controller.getValueNotifier(
      widgetId: 'transformer-input',
      property: 'value',
    );

    // Initialize from transformed value
    if (_notifier != null) {
      _textController.text = _notifier!.value?.toString() ?? '';
      _notifier!.addListener(_onModelChanged);
    }
  }

  void _onModelChanged() {
    final newValue = _notifier?.value?.toString() ?? '';
    if (_textController.text != newValue) {
      _textController.text = newValue;
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onModelChanged);
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Percentage Transformer Example:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '• Model stores: 0.0 - 1.0 (decimal)\n'
                '• Widget shows: 0 - 100 (percentage)\n'
                '• toWidget: value × 100\n'
                '• toModel: value ÷ 100',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Percentage (0-100)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _controller.updateFromWidget(
                    widgetId: 'transformer-input',
                    property: 'value',
                    value: value,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<dynamic>(
              valueListenable: widget.dataModel['transformer.percentage']!,
              builder: (context, value, _) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Model:', style: TextStyle(fontSize: 10)),
                      Text(
                        value?.toString() ?? 'null',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Displays a single data model entry with live updates.
class _DataModelEntry extends StatelessWidget {
  const _DataModelEntry({
    required this.path,
    required this.notifier,
  });

  final String path;
  final ValueNotifier<dynamic> notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  path,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${value.runtimeType}: $value',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
