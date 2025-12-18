import 'package:flutter/foundation.dart';
import 'package:genui_claude/src/binding/binding_definition.dart';
import 'package:genui_claude/src/binding/binding_path.dart';

/// Represents an active binding between a widget and the data model.
///
/// A widget binding connects a widget property to a data model path,
/// enabling reactive updates when the data changes. For two-way bindings,
/// widget changes can also flow back to the data model.
class WidgetBinding {
  /// Creates a widget binding.
  WidgetBinding({
    required this.widgetId,
    required this.surfaceId,
    required this.definition,
    required this.subscription,
  });

  /// Unique identifier of the bound widget.
  final String widgetId;

  /// Surface containing the widget.
  final String surfaceId;

  /// The binding definition.
  final BindingDefinition definition;

  /// The ValueNotifier subscription from DataModel.
  final ValueNotifier<dynamic> subscription;

  /// Whether this binding has been disposed.
  bool _isDisposed = false;

  /// Current bound value.
  dynamic get value => subscription.value;

  /// The widget property being bound (convenience getter).
  String get property => definition.property;

  /// The data model path (convenience getter).
  BindingPath get path => definition.path;

  /// The binding mode (convenience getter).
  BindingMode get mode => definition.mode;

  /// Whether this is a two-way binding.
  bool get isTwoWay => definition.mode == BindingMode.twoWay;

  /// Whether this binding has been disposed.
  bool get isDisposed => _isDisposed;

  /// Disposes the binding.
  ///
  /// This does NOT dispose the underlying ValueNotifier, as that may be
  /// shared with other bindings or owned by the DataModel.
  /// Safe to call multiple times.
  void dispose() {
    _isDisposed = true;
  }

  @override
  String toString() =>
      'WidgetBinding(widgetId: $widgetId, property: $property, path: ${path.toDotNotation()})';
}
