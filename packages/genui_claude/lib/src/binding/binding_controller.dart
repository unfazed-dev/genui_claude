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

/// Bundles a transformed notifier with its source and listener for cleanup.
///
/// Used internally by [BindingController] to ensure listeners are properly
/// removed from source notifiers when cached transforms are evicted.
class _CachedTransform {
  _CachedTransform({
    required this.notifier,
    required this.source,
    required this.listener,
  });

  final ValueNotifier<dynamic> notifier;
  final ValueNotifier<dynamic> source;
  final VoidCallback listener;

  void dispose() {
    source.removeListener(listener);
    notifier.dispose();
  }
}

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
  /// - [maxCacheSize]: Maximum number of transformed notifiers to cache (default: 100)
  BindingController({
    required BindingRegistry registry,
    required DataModelSubscribe subscribe,
    required DataModelUpdate update,
    int maxCacheSize = 100,
  })  : _registry = registry,
        _subscribe = subscribe,
        _update = update,
        _maxCacheSize = maxCacheSize;

  final BindingRegistry _registry;
  final DataModelSubscribe _subscribe;
  final DataModelUpdate _update;
  final int _maxCacheSize;

  /// Tracks the last value set for each binding to prevent update loops.
  final Map<String, dynamic> _lastWidgetValues = {};

  /// Cache of transformed notifiers for toWidget transformers.
  final Map<String, _CachedTransform> _transformedNotifiers = {};

  /// Tracks access order for LRU eviction of transformed notifiers.
  final List<String> _cacheAccessOrder = [];

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
  /// If the binding has a [BindingDefinition.toWidget] transformer, returns
  /// a transformed notifier that applies the transform to values from the
  /// data model.
  ///
  /// Returns `null` if no binding exists for the given widget and property.
  ValueNotifier<dynamic>? getValueNotifier({
    required String widgetId,
    required String property,
  }) {
    if (_isDisposed) return null;

    final binding = _registry.getBindingForWidgetProperty(widgetId, property);
    if (binding == null) return null;

    final toWidget = binding.definition.toWidget;

    // No transformer - return raw subscription
    if (toWidget == null) {
      return binding.subscription;
    }

    // Check cache for existing transformed notifier
    final cacheKey = '$widgetId:$property';
    final cached = _transformedNotifiers[cacheKey];
    if (cached != null) {
      // Update LRU access order
      _trackCacheAccess(cacheKey);
      return cached.notifier;
    }

    // Create transformed notifier that applies toWidget transform
    final source = binding.subscription;
    final transformed = ValueNotifier<dynamic>(toWidget(source.value));

    // Listen to source and propagate transformed values
    void listener() {
      if (!_isDisposed) {
        transformed.value = toWidget(source.value);
      }
    }

    source.addListener(listener);

    // Evict oldest entries if cache is full before adding new entry
    _evictIfNeeded();

    // Cache for reuse and cleanup (with listener reference for proper disposal)
    _transformedNotifiers[cacheKey] = _CachedTransform(
      notifier: transformed,
      source: source,
      listener: listener,
    );
    _cacheAccessOrder.add(cacheKey);

    return transformed;
  }

  /// Updates LRU access order for a cache key.
  void _trackCacheAccess(String cacheKey) {
    _cacheAccessOrder.remove(cacheKey);
    _cacheAccessOrder.add(cacheKey);
  }

  /// Evicts oldest cache entries when over the max cache size.
  void _evictIfNeeded() {
    while (_transformedNotifiers.length >= _maxCacheSize &&
        _cacheAccessOrder.isNotEmpty) {
      final oldest = _cacheAccessOrder.removeAt(0);
      final cached = _transformedNotifiers.remove(oldest);
      cached?.dispose(); // Removes listener from source before disposing notifier
      _lastWidgetValues.remove(oldest);
    }
  }

  /// Updates the data model from a widget change (two-way binding).
  ///
  /// This method should be called when a widget's value changes and
  /// needs to propagate back to the data model.
  ///
  /// If the binding has a [BindingDefinition.toModel] transformer, it will
  /// be applied to the value before updating the data model.
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

    // Apply toModel transformer if present
    final toModel = binding.definition.toModel;
    final transformedValue = toModel != null ? toModel(value) : value;

    // Prevent update loops by checking if value actually changed
    final key = '$widgetId:$property';
    if (_lastWidgetValues[key] == transformedValue) return;
    _lastWidgetValues[key] = transformedValue;

    _update(binding.path, transformedValue);
  }

  /// Unregisters all bindings for a specific widget.
  void unregisterWidget(String widgetId) {
    if (_isDisposed) return;

    final bindings = _registry.getBindingsForWidget(widgetId);
    for (final binding in bindings) {
      final key = '${binding.widgetId}:${binding.property}';

      // Dispose cached transform (removes listener from source)
      final cached = _transformedNotifiers.remove(key);
      cached?.dispose();
      _cacheAccessOrder.remove(key);

      binding.dispose();
      _lastWidgetValues.remove(key);
    }
    _registry.unregisterWidget(widgetId);
  }

  /// Unregisters all bindings for a specific surface.
  void unregisterSurface(String surfaceId) {
    if (_isDisposed) return;

    final bindings = _registry.getBindingsForSurface(surfaceId);
    for (final binding in bindings) {
      final key = '${binding.widgetId}:${binding.property}';

      // Dispose cached transform (removes listener from source)
      final cached = _transformedNotifiers.remove(key);
      cached?.dispose();
      _cacheAccessOrder.remove(key);

      binding.dispose();
      _lastWidgetValues.remove(key);
    }
    _registry.unregisterSurface(surfaceId);
  }

  /// Disposes the controller and clears all bindings.
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    // Dispose all cached transforms (removes listeners from sources)
    for (final cached in _transformedNotifiers.values) {
      cached.dispose();
    }
    _transformedNotifiers.clear();
    _cacheAccessOrder.clear();

    // Registry.clear() handles disposing all bindings
    _registry.clear();
    _lastWidgetValues.clear();
  }
}
