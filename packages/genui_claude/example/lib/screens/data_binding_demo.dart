import 'package:flutter/material.dart';
import 'package:genui_claude/genui_claude.dart';

/// Data binding demo screen demonstrating the binding engine.
///
/// This example shows how to use the data binding engine:
/// - BindingController for orchestrating bindings
/// - BindingRegistry for tracking active bindings
/// - Two-way binding between widgets and data model
/// - Value transformers (toWidget, toModel)
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

  // Example data paths
  static const _emailPath = 'form.email';
  static const _namePath = 'form.name';
  static const _agePath = 'form.age';
  static const _subscribedPath = 'form.subscribed';

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
  }

  void _initializeBindings() {
    _registry = BindingRegistry();
    _controller = BindingController(
      registry: _registry,
      subscribe: _subscribe,
      update: _update,
    );

    // Register bindings for each "widget"
    // Email: two-way binding
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'email-input',
      dataBinding: {
        'value': {'path': _emailPath, 'mode': 'twoWay'},
      },
    );

    // Name: two-way binding
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'name-input',
      dataBinding: {
        'value': {'path': _namePath, 'mode': 'twoWay'},
      },
    );

    // Age: two-way binding (will show transformer)
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'age-input',
      dataBinding: {
        'value': {'path': _agePath, 'mode': 'twoWay'},
      },
    );

    // Subscribed: two-way binding
    _controller.processWidgetBindings(
      surfaceId: 'demo-surface',
      widgetId: 'subscribe-toggle',
      dataBinding: {
        'value': {'path': _subscribedPath, 'mode': 'twoWay'},
      },
    );
  }

  /// Subscribe to a data model path - returns ValueNotifier for that path
  ValueNotifier<dynamic> _subscribe(BindingPath path) {
    final key = path.toDotNotation();
    return _dataModel[key] ??= ValueNotifier<dynamic>(null);
  }

  /// Update a data model path
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
            _buildFormSection(),
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
                Icon(Icons.sync_alt, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Two-Way Data Binding',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This demo shows how the BindingController connects widgets to a data model. '
              'Edit the form fields and watch the data model update in real-time. '
              'Click "Update from Model" to see changes flow from model to widgets.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bound Form Widgets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Email field
            _BoundTextField(
              widgetId: 'email-input',
              label: 'Email',
              controller: _controller,
              icon: Icons.email,
            ),
            const SizedBox(height: 12),
            // Name field
            _BoundTextField(
              widgetId: 'name-input',
              label: 'Name',
              controller: _controller,
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            // Age field
            _BoundTextField(
              widgetId: 'age-input',
              label: 'Age',
              controller: _controller,
              icon: Icons.cake,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Subscribe toggle
            _BoundSwitch(
              widgetId: 'subscribe-toggle',
              label: 'Subscribe to newsletter',
              controller: _controller,
            ),
          ],
        ),
      ),
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

  void _updateFromModel() {
    // Simulate external update to data model
    _dataModel[_emailPath]?.value = 'updated@example.com';
    _dataModel[_namePath]?.value = 'Jane Smith';
    _dataModel[_agePath]?.value = 30;
    _dataModel[_subscribedPath]?.value = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data model updated! Watch widgets refresh.')),
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
                  'Usage Example',
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
// Create binding controller
final controller = BindingController(
  registry: BindingRegistry(),
  subscribe: dataModel.subscribe,
  update: dataModel.update,
);

// Register widget bindings
controller.processWidgetBindings(
  surfaceId: 'form-surface',
  widgetId: 'email-input',
  dataBinding: {
    'value': {'path': 'form.email', 'mode': 'twoWay'}
  },
);

// Get reactive value for widget
final notifier = controller.getValueNotifier(
  widgetId: 'email-input',
  property: 'value',
);

// Update from widget (two-way)
controller.updateFromWidget(
  widgetId: 'email-input',
  property: 'value',
  value: 'new@example.com',
);''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
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

/// A text field that's bound to the data model via BindingController.
class _BoundTextField extends StatefulWidget {
  const _BoundTextField({
    required this.widgetId,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
  });

  final String widgetId;
  final String label;
  final BindingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;

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
      value: widget.keyboardType == TextInputType.number
          ? int.tryParse(value) ?? value
          : value,
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
      keyboardType: widget.keyboardType,
      onChanged: _onWidgetChanged,
    );
  }
}

/// A switch widget that's bound to the data model via BindingController.
class _BoundSwitch extends StatefulWidget {
  const _BoundSwitch({
    required this.widgetId,
    required this.label,
    required this.controller,
  });

  final String widgetId;
  final String label;
  final BindingController controller;

  @override
  State<_BoundSwitch> createState() => _BoundSwitchState();
}

class _BoundSwitchState extends State<_BoundSwitch> {
  ValueNotifier<dynamic>? _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = widget.controller.getValueNotifier(
      widgetId: widget.widgetId,
      property: 'value',
    );
  }

  void _onChanged(bool value) {
    widget.controller.updateFromWidget(
      widgetId: widget.widgetId,
      property: 'value',
      value: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: _valueNotifier ?? ValueNotifier<dynamic>(false),
      builder: (context, value, _) {
        return SwitchListTile(
          title: Text(widget.label),
          value: value == true,
          onChanged: _onChanged,
          secondary: Tooltip(
            message: 'Widget ID: ${widget.widgetId}',
            child: Icon(
              Icons.link,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
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
                    fontSize: 12,
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
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
