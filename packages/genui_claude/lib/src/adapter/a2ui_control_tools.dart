import 'package:a2ui_claude/a2ui_claude.dart';

/// A2UI control tool definitions for Claude API.
///
/// These tools allow Claude to generate dynamic UI by sending A2UI protocol
/// messages. They are the core tools that enable generative UI functionality.
class A2uiControlTools {
  A2uiControlTools._(); // coverage:ignore-line

  /// Tool for signaling the start of UI generation for a surface.
  static const beginRendering = A2uiToolSchema(
    name: 'begin_rendering',
    description: 'Signal the start of UI generation for a surface. '
        'Call this before sending surface updates to initialize the rendering context.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'Unique identifier for the UI surface being rendered.',
        },
        'parentSurfaceId': {
          'type': 'string',
          'description':
              'Optional parent surface ID for nested UI hierarchies.',
        },
        'root': {
          'type': 'string',
          'description':
              'Optional root element ID for hierarchical rendering. Defaults to "root".',
        },
      },
      'required': ['surfaceId'],
    },
    requiredFields: ['surfaceId'],
  );

  /// Tool for updating the widget tree of a surface.
  static const surfaceUpdate = A2uiToolSchema(
    name: 'surface_update',
    description: 'Update the widget tree of a UI surface. '
        'Use this to add, modify, or replace widgets in the rendered UI.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'The surface ID to update.',
        },
        'widgets': {
          'type': 'array',
          'description': 'Array of widget definitions to render.',
          'items': {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'string',
                'description':
                    'Optional unique instance ID. Auto-generated if not provided.',
              },
              'type': {
                'type': 'string',
                'description': 'Widget type name (e.g., "text", "button").',
              },
              'properties': {
                'type': 'object',
                'description': 'Widget configuration properties.',
              },
              'children': {
                'type': 'array',
                'description': 'Child widgets for container types.',
              },
              'dataBinding': {
                'type': 'string',
                'description': 'Optional data binding path.',
              },
            },
            'required': ['type'],
          },
        },
        'append': {
          'type': 'boolean',
          'description':
              'If true, append widgets to existing content. If false, replace.',
        },
      },
      'required': ['surfaceId', 'widgets'],
    },
    requiredFields: ['surfaceId', 'widgets'],
  );

  /// Tool for updating the data model bound to UI components.
  static const dataModelUpdate = A2uiToolSchema(
    name: 'data_model_update',
    description: 'Update the data model that UI components are bound to. '
        'Use this to update dynamic content without rebuilding the widget tree.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'updates': {
          'type': 'object',
          'description': 'Key-value pairs of data updates to apply.',
        },
        'scope': {
          'type': 'string',
          'description': 'Optional scope/surface ID for the data update.',
        },
      },
      'required': ['updates'],
    },
    requiredFields: ['updates'],
  );

  /// Tool for deleting a UI surface.
  static const deleteSurface = A2uiToolSchema(
    name: 'delete_surface',
    description: 'Delete a UI surface and optionally its child surfaces. '
        'Use this to clean up UI elements that are no longer needed.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'surfaceId': {
          'type': 'string',
          'description': 'The surface ID to delete.',
        },
        'cascade': {
          'type': 'boolean',
          'description': 'If true, also delete all child surfaces.',
        },
      },
      'required': ['surfaceId'],
    },
    requiredFields: ['surfaceId'],
  );

  /// All A2UI control tools.
  static List<A2uiToolSchema> get all => [
        beginRendering,
        surfaceUpdate,
        dataModelUpdate,
        deleteSurface,
      ];
}
