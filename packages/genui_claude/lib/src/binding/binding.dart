/// Data binding engine for reactive widget-data model connections.
///
/// This library provides runtime data binding capabilities, enabling
/// widgets to automatically update when data model values change.
library;

// Hide DataModelUpdate to avoid conflict with genui package's DataModelUpdate
export 'binding_controller.dart' hide DataModelUpdate;
export 'binding_definition.dart';
export 'binding_path.dart';
export 'binding_registry.dart';
export 'widget_binding.dart';
