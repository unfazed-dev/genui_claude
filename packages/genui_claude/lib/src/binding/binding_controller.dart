import 'package:flutter/foundation.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/binding_registry.dart';
import 'package:genui_claude/src/binding/widget_binding.dart';

/// Function signature for subscribing to data model paths.
///
/// Takes a [BindingPath] and returns a [ValueNotifier] that tracks
/// changes at that path in the data model.
typedef DataModelSubscribe = ValueNotifier<dynamic> Function(BindingPath path);

/// Function signature for updating data model values.
///
/// Takes a [BindingPath] and the new value to set at that path.
typedef DataModelUpdate = void Function(BindingPath path, dynamic value);

/// Orchestrates data binding between widgets and the data model.
///
/// The controller manages the lifecycle of bindings, including:
/// - Creating bindings when widgets are rendered
/// - Providing reactive value access via [ValueNotifier]
/// - Handling two-way binding updates from widgets
/// - Cleaning up bindings when widgets/surfaces are removed
///
/// Example usage:
/// ```dart
/// final controller = BindingController(
///   registry: BindingRegistry(),
///   subscribe: dataModel.subscribe,
///   update: dataModel.update,
/// );
///
/// // Process widget bindings from SurfaceUpdate
/// controller.processWidgetBindings(
///   surfaceId: 'form-surface',
///   widgetId: 'email-input',
///   dataBinding: {'value': 'form.email'},
/// );
///
/// // Get reactive value for widget
/// final notifier = controller.getValueNotifier(
///   widgetId: 'email-input',
///   property: 'value',
/// );
/// ```
class BindingController {
  /// Creates a binding controller with the given dependencies.
  ///
  /// - [registry]: The binding registry for tracking active bindings
  /// - [subscribe]: Function to subscribe to data model paths
  /// - [update]: Function to update data model values
  BindingController({
    required BindingRegistry registry,
    required DataModelSubscribe subscribe,
    required DataModelUpdate update,
  })  : _registry = registry,
        _subscribe = subscribe,
        _update = update;

  final BindingRegistry _registry;
  final DataModelSubscribe _subscribe;
  final DataModelUpdate _update;

  /// Tracks the last value set for each binding to prevent update loops.
  final Map<String, dynamic> _lastWidgetValues = {};

  /// Whether this controller has been disposed.
  bool _isDisposed = false;

  /// Processes widget bindings from a dataBinding specification.
  ///
  /// The [dataBinding] can be:
  /// - A [String] path (e.g., 'form.email') - creates single one-way binding
  /// - A [Map] with property → path mappings (e.g., {'value': 'form.email'})
  /// - A [Map] with property → binding config (e.g., {'value': {'path': 'form.email', 'mode': 'twoWay'}})
  /// - `null` - no bindings created
  void processWidgetBindings({
    required String surfaceId,
    required String widgetId,
    required dynamic dataBinding,
  }) {
    if (_isDisposed || dataBinding == null) return;

    final definitions = BindingDefinition.parse(dataBinding);

    for (final definition in definitions) {
      final subscription = _subscribe(definition.path);
      final binding = WidgetBinding(
        widgetId: widgetId,
        surfaceId: surfaceId,
        definition: definition,
        subscription: subscription,
      );
      _registry.register(binding);
    }
  }

  /// Gets the [ValueNotifier] for a specific widget property binding.
  ///
  /// Returns `null` if no binding exists for the given widget and property.
  ValueNotifier<dynamic>? getValueNotifier({
    required String widgetId,
    required String property,
  }) {
    if (_isDisposed) return null;

    final binding = _registry.getBindingForWidgetProperty(widgetId, property);
    return binding?.subscription;
  }

  /// Updates the data model from a widget change (two-way binding).
  ///
  /// This method should be called when a widget's value changes and
  /// needs to propagate back to the data model.
  ///
  /// Only two-way bindings will actually update the data model.
  /// One-way bindings are ignored.
  void updateFromWidget({
    required String widgetId,
    required String property,
    required dynamic value,
  }) {
    if (_isDisposed) return;

    final binding = _registry.getBindingForWidgetProperty(widgetId, property);
    if (binding == null || !binding.isTwoWay) return;

    // Prevent update loops by checking if value actually changed
    final key = '$widgetId:$property';
    if (_lastWidgetValues[key] == value) return;
    _lastWidgetValues[key] = value;

    _update(binding.path, value);
  }

  /// Unregisters all bindings for a specific widget.
  void unregisterWidget(String widgetId) {
    if (_isDisposed) return;

    final bindings = _registry.getBindingsForWidget(widgetId);
    for (final binding in bindings) {
      binding.dispose();
      _lastWidgetValues.remove('${binding.widgetId}:${binding.property}');
    }
    _registry.unregisterWidget(widgetId);
  }

  /// Unregisters all bindings for a specific surface.
  void unregisterSurface(String surfaceId) {
    if (_isDisposed) return;

    final bindings = _registry.getBindingsForSurface(surfaceId);
    for (final binding in bindings) {
      binding.dispose();
      _lastWidgetValues.remove('${binding.widgetId}:${binding.property}');
    }
    _registry.unregisterSurface(surfaceId);
  }

  /// Disposes the controller and clears all bindings.
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    // Registry.clear() handles disposing all bindings
    _registry.clear();
    _lastWidgetValues.clear();
  }
}
