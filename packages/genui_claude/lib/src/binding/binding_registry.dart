import 'package:genui_claude/src/binding/binding_path.dart';
import 'package:genui_claude/src/binding/widget_binding.dart';

/// Central registry tracking all active bindings.
///
/// Enables efficient lookup by widget ID, surface ID, or data path.
/// This allows the binding system to quickly find affected bindings
/// when data updates or when widgets/surfaces are removed.
class BindingRegistry {
  /// Creates a new binding registry.
  BindingRegistry();

  /// All bindings indexed by widget ID.
  final Map<String, List<WidgetBinding>> _bindingsByWidget = {};

  /// All bindings indexed by surface ID.
  final Map<String, List<WidgetBinding>> _bindingsBySurface = {};

  /// All bindings indexed by path (for reverse lookup).
  final Map<String, List<WidgetBinding>> _bindingsByPath = {};

  /// Returns true if the registry has any bindings.
  bool get hasBindings => _bindingsByWidget.isNotEmpty;

  /// Registers a new binding.
  ///
  /// The binding will be indexed by widget ID, surface ID, and path
  /// for efficient lookup.
  void register(WidgetBinding binding) {
    // Index by widget ID
    _bindingsByWidget.putIfAbsent(binding.widgetId, () => []).add(binding);

    // Index by surface ID
    _bindingsBySurface.putIfAbsent(binding.surfaceId, () => []).add(binding);

    // Index by path
    final pathKey = binding.path.toSlashNotation();
    _bindingsByPath.putIfAbsent(pathKey, () => []).add(binding);
  }

  /// Unregisters all bindings for a widget.
  ///
  /// Also removes the bindings from surface and path indices.
  void unregisterWidget(String widgetId) {
    final bindings = _bindingsByWidget.remove(widgetId);
    if (bindings == null) return;

    for (final binding in bindings) {
      _removeFromSurfaceIndex(binding);
      _removeFromPathIndex(binding);
      binding.dispose();
    }
  }

  /// Unregisters all bindings for a surface.
  ///
  /// Also removes the bindings from widget and path indices.
  void unregisterSurface(String surfaceId) {
    final bindings = _bindingsBySurface.remove(surfaceId);
    if (bindings == null) return;

    for (final binding in bindings) {
      _removeFromWidgetIndex(binding);
      _removeFromPathIndex(binding);
      binding.dispose();
    }
  }

  /// Gets all bindings for a widget.
  ///
  /// Returns an empty list if no bindings exist for the widget.
  List<WidgetBinding> getBindingsForWidget(String widgetId) {
    return List.unmodifiable(_bindingsByWidget[widgetId] ?? []);
  }

  /// Gets all bindings for a surface.
  ///
  /// Returns an empty list if no bindings exist for the surface.
  List<WidgetBinding> getBindingsForSurface(String surfaceId) {
    return List.unmodifiable(_bindingsBySurface[surfaceId] ?? []);
  }

  /// Gets all widgets bound to a path.
  ///
  /// Returns an empty list if no bindings exist for the path.
  List<WidgetBinding> getBindingsForPath(BindingPath path) {
    final pathKey = path.toSlashNotation();
    return List.unmodifiable(_bindingsByPath[pathKey] ?? []);
  }

  /// Gets a specific binding for a widget property.
  ///
  /// Returns null if no binding exists for the widget/property combination.
  WidgetBinding? getBindingForWidgetProperty(String widgetId, String property) {
    final bindings = _bindingsByWidget[widgetId];
    if (bindings == null) return null;

    for (final binding in bindings) {
      if (binding.property == property) {
        return binding;
      }
    }
    return null;
  }

  /// Clears all bindings.
  void clear() {
    // Dispose all bindings
    for (final bindings in _bindingsByWidget.values) {
      for (final binding in bindings) {
        binding.dispose();
      }
    }

    _bindingsByWidget.clear();
    _bindingsBySurface.clear();
    _bindingsByPath.clear();
  }

  void _removeFromWidgetIndex(WidgetBinding binding) {
    final bindings = _bindingsByWidget[binding.widgetId];
    if (bindings != null) {
      bindings.remove(binding);
      if (bindings.isEmpty) {
        _bindingsByWidget.remove(binding.widgetId);
      }
    }
  }

  void _removeFromSurfaceIndex(WidgetBinding binding) {
    final bindings = _bindingsBySurface[binding.surfaceId];
    if (bindings != null) {
      bindings.remove(binding);
      if (bindings.isEmpty) {
        _bindingsBySurface.remove(binding.surfaceId);
      }
    }
  }

  void _removeFromPathIndex(WidgetBinding binding) {
    final pathKey = binding.path.toSlashNotation();
    final bindings = _bindingsByPath[pathKey];
    if (bindings != null) {
      bindings.remove(binding);
      if (bindings.isEmpty) {
        _bindingsByPath.remove(pathKey);
      }
    }
  }
}
