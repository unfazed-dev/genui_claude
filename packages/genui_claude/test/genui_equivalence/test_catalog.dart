/// Shared test catalog for GenUI equivalence tests.
///
/// Provides a minimal widget catalog for testing A2UI message handling
/// and GenUiConversation integration.
library;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// A minimal test catalog with basic widgets for testing.
class TestCatalog extends Catalog {
  TestCatalog() : super(_catalogItems);

  static final List<CatalogItem> _catalogItems = [
    // Text widget
    CatalogItem(
      name: 'Text',
      dataSchema: S.object(
        description: 'A simple text display widget',
        properties: {
          'text': S.string(description: 'The text to display'),
          'style': S.string(
            description: 'Text style: normal, bold, italic',
            enumValues: ['normal', 'bold', 'italic'],
          ),
        },
        required: ['text'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        final text = props['text'] as String? ?? '';
        final style = props['style'] as String? ?? 'normal';

        return Text(
          text,
          style: TextStyle(
            fontWeight: style == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontStyle: style == 'italic' ? FontStyle.italic : FontStyle.normal,
          ),
        );
      },
    ),

    // Button widget
    CatalogItem(
      name: 'Button',
      dataSchema: S.object(
        description: 'A clickable button widget',
        properties: {
          'label': S.string(description: 'Button label text'),
          'action':
              S.string(description: 'Action identifier for click handler'),
        },
        required: ['label'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        final label = props['label'] as String? ?? 'Button';
        return ElevatedButton(
          onPressed: () {},
          child: Text(label),
        );
      },
    ),

    // Container widget
    CatalogItem(
      name: 'Container',
      dataSchema: S.object(
        description: 'A container with optional background color',
        properties: {
          'color': S.string(description: 'Background color as hex string'),
          'padding': S.number(description: 'Padding in logical pixels'),
        },
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        final colorHex = props['color'] as String?;
        final padding = (props['padding'] as num?)?.toDouble() ?? 8.0;

        Color? color;
        if (colorHex != null && colorHex.startsWith('#')) {
          final hex = colorHex.substring(1);
          if (hex.length == 6) {
            color = Color(int.parse('FF$hex', radix: 16));
          }
        }

        return Container(
          color: color,
          padding: EdgeInsets.all(padding),
          child: const SizedBox.shrink(),
        );
      },
    ),
  ];

  /// Get catalog items for external use.
  static List<CatalogItem> get catalogItems => _catalogItems;
}

/// Widget definitions for use in mock responses.
class TestWidgets {
  TestWidgets._();

  /// Simple text widget definition.
  static Map<String, dynamic> text(String content) => {
        'type': 'Text',
        'properties': {'text': content},
      };

  /// Button widget definition.
  static Map<String, dynamic> button(String label, {String? action}) => {
        'type': 'Button',
        'properties': {
          'label': label,
          if (action != null) 'action': action,
        },
      };

  /// Container widget definition.
  static Map<String, dynamic> container({String? color, double? padding}) => {
        'type': 'Container',
        'properties': {
          if (color != null) 'color': color,
          if (padding != null) 'padding': padding,
        },
      };
}
