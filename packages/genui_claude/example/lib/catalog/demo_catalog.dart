import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Demo catalog with example widgets for Claude to generate.
///
/// This catalog demonstrates various widget types that can be
/// rendered dynamically based on Claude's tool calls.
class DemoCatalog extends Catalog {
  DemoCatalog() : super(_catalogItems);

  static final List<CatalogItem> _catalogItems = [
    // Text display widget
    CatalogItem(
      name: 'text_display',
      dataSchema: S.object(
        description: 'Display text content with optional styling',
        properties: {
          'text': S.string(description: 'The text content to display'),
          'style': S.string(
            description: 'Text style: title, subtitle, body, caption',
            enumValues: ['title', 'subtitle', 'body', 'caption'],
          ),
          'align': S.string(
            description: 'Text alignment: left, center, right',
            enumValues: ['left', 'center', 'right'],
          ),
        },
        required: ['text'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _TextDisplayWidget(props: props);
      },
    ),

    // Info card widget
    CatalogItem(
      name: 'info_card',
      dataSchema: S.object(
        description: 'A card displaying information with title and content',
        properties: {
          'title': S.string(description: 'Card title'),
          'content': S.string(description: 'Card body content'),
          'icon': S.string(description: 'Icon name: info, warning, success, error'),
        },
        required: ['title', 'content'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _InfoCardWidget(props: props);
      },
    ),

    // Button widget
    CatalogItem(
      name: 'action_button',
      dataSchema: S.object(
        description: 'An interactive button',
        properties: {
          'label': S.string(description: 'Button label text'),
          'style': S.string(
            description: 'Button style: primary, secondary, outline',
            enumValues: ['primary', 'secondary', 'outline'],
          ),
          'enabled': S.boolean(description: 'Whether the button is enabled'),
        },
        required: ['label'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _ActionButtonWidget(props: props);
      },
    ),

    // List widget
    CatalogItem(
      name: 'item_list',
      dataSchema: S.object(
        description: 'A list of items',
        properties: {
          'title': S.string(description: 'List title'),
          'items': S.list(
            items: S.object(
              properties: {
                'title': S.string(),
                'subtitle': S.string(),
              },
            ),
            description: 'List items with title and optional subtitle',
          ),
        },
        required: ['items'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _ItemListWidget(props: props);
      },
    ),

    // Progress indicator
    CatalogItem(
      name: 'progress_indicator',
      dataSchema: S.object(
        description: 'Show progress or loading state',
        properties: {
          'value': S.number(description: 'Progress value from 0.0 to 1.0'),
          'label': S.string(description: 'Label text to show'),
          'type': S.string(
            description: 'Type: linear, circular',
            enumValues: ['linear', 'circular'],
          ),
        },
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _ProgressWidget(props: props);
      },
    ),

    // Input field
    CatalogItem(
      name: 'input_field',
      dataSchema: S.object(
        description: 'A text input field',
        properties: {
          'label': S.string(description: 'Field label'),
          'hint': S.string(description: 'Placeholder hint text'),
          'type': S.string(
            description: 'Input type: text, email, number, password',
            enumValues: ['text', 'email', 'number', 'password'],
          ),
          'required': S.boolean(description: 'Whether the field is required'),
        },
        required: ['label'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _InputFieldWidget(props: props);
      },
    ),

    // Image widget
    CatalogItem(
      name: 'image_display',
      dataSchema: S.object(
        description: 'Display an image from URL',
        properties: {
          'url': S.string(description: 'Image URL'),
          'alt': S.string(description: 'Alt text for accessibility'),
          'width': S.number(description: 'Width in logical pixels'),
          'height': S.number(description: 'Height in logical pixels'),
        },
        required: ['url'],
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _ImageDisplayWidget(props: props);
      },
    ),

    // Divider
    CatalogItem(
      name: 'divider',
      dataSchema: S.object(
        description: 'A horizontal divider line',
        properties: {
          'thickness': S.number(description: 'Line thickness'),
          'indent': S.number(description: 'Left indent'),
          'endIndent': S.number(description: 'Right indent'),
        },
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _DividerWidget(props: props);
      },
    ),

    // Spacer
    CatalogItem(
      name: 'spacer',
      dataSchema: S.object(
        description: 'Add vertical spacing',
        properties: {
          'height': S.number(description: 'Height in logical pixels'),
        },
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _SpacerWidget(props: props);
      },
    ),

    // Container/Box
    CatalogItem(
      name: 'container',
      dataSchema: S.object(
        description: 'A styled container box',
        properties: {
          'padding': S.number(description: 'Padding in logical pixels'),
          'color': S.string(description: 'Background color hex code'),
          'borderRadius': S.number(description: 'Border radius'),
        },
      ),
      widgetBuilder: (itemContext) {
        final props = itemContext.data as Map<String, dynamic>? ?? {};
        return _ContainerWidget(props: props);
      },
    ),
  ];

  /// Get the catalog items list.
  static List<CatalogItem> get catalogItems => _catalogItems;
}

// Widget implementations

class _TextDisplayWidget extends StatelessWidget {
  const _TextDisplayWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final text = props['text'] as String? ?? '';
    final style = props['style'] as String?;
    final align = props['align'] as String?;

    TextStyle textStyle;
    switch (style) {
      case 'title':
        textStyle = Theme.of(context).textTheme.headlineMedium!;
      case 'subtitle':
        textStyle = Theme.of(context).textTheme.titleMedium!;
      case 'caption':
        textStyle = Theme.of(context).textTheme.bodySmall!;
      default:
        textStyle = Theme.of(context).textTheme.bodyMedium!;
    }

    TextAlign textAlign;
    switch (align) {
      case 'center':
        textAlign = TextAlign.center;
      case 'right':
        textAlign = TextAlign.right;
      default:
        textAlign = TextAlign.left;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: textStyle, textAlign: textAlign),
    );
  }
}

class _InfoCardWidget extends StatelessWidget {
  const _InfoCardWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String? ?? '';
    final content = props['content'] as String? ?? '';
    final iconName = props['icon'] as String?;

    IconData icon;
    Color iconColor;
    switch (iconName) {
      case 'warning':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
      case 'success':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
      case 'error':
        icon = Icons.error_outline;
        iconColor = Colors.red;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonWidget extends StatelessWidget {
  const _ActionButtonWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final label = props['label'] as String? ?? 'Button';
    final style = props['style'] as String?;
    final enabled = props['enabled'] as bool? ?? true;

    final onPressed = enabled ? () {} : null;

    switch (style) {
      case 'secondary':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextButton(onPressed: onPressed, child: Text(label)),
        );
      case 'outline':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton(onPressed: onPressed, child: Text(label)),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ElevatedButton(onPressed: onPressed, child: Text(label)),
        );
    }
  }
}

class _ItemListWidget extends StatelessWidget {
  const _ItemListWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String?;
    final items = (props['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...items.map(
            (item) => ListTile(
              title: Text(item['title'] as String? ?? ''),
              subtitle: item['subtitle'] != null
                  ? Text(item['subtitle'] as String)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressWidget extends StatelessWidget {
  const _ProgressWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final value = (props['value'] as num?)?.toDouble();
    final label = props['label'] as String?;
    final type = props['type'] as String?;

    Widget indicator;
    if (type == 'circular') {
      indicator = value != null
          ? CircularProgressIndicator(value: value)
          : const CircularProgressIndicator();
    } else {
      indicator = value != null
          ? LinearProgressIndicator(value: value)
          : const LinearProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label),
            const SizedBox(height: 8),
          ],
          if (type == 'circular')
            Center(child: indicator)
          else
            indicator,
        ],
      ),
    );
  }
}

class _InputFieldWidget extends StatelessWidget {
  const _InputFieldWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final label = props['label'] as String? ?? '';
    final hint = props['hint'] as String?;
    final type = props['type'] as String?;
    final required = props['required'] as bool? ?? false;

    TextInputType keyboardType;
    var obscureText = false;

    switch (type) {
      case 'email':
        keyboardType = TextInputType.emailAddress;
      case 'number':
        keyboardType = TextInputType.number;
      case 'password':
        keyboardType = TextInputType.visiblePassword;
        obscureText = true;
      default:
        keyboardType = TextInputType.text;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
      ),
    );
  }
}

class _ImageDisplayWidget extends StatelessWidget {
  const _ImageDisplayWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final url = props['url'] as String?;
    final alt = props['alt'] as String?;
    final width = (props['width'] as num?)?.toDouble();
    final height = (props['height'] as num?)?.toDouble();

    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: alt,
        errorBuilder: (_, __, ___) => Container(
          width: width ?? 200,
          height: height ?? 150,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}

class _DividerWidget extends StatelessWidget {
  const _DividerWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final thickness = (props['thickness'] as num?)?.toDouble();
    final indent = (props['indent'] as num?)?.toDouble();
    final endIndent = (props['endIndent'] as num?)?.toDouble();

    return Divider(
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

class _SpacerWidget extends StatelessWidget {
  const _SpacerWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final height = (props['height'] as num?)?.toDouble() ?? 16;
    return SizedBox(height: height);
  }
}

class _ContainerWidget extends StatelessWidget {
  const _ContainerWidget({required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final padding = (props['padding'] as num?)?.toDouble() ?? 16;
    final colorHex = props['color'] as String?;
    final borderRadius = (props['borderRadius'] as num?)?.toDouble() ?? 8;

    Color? color;
    if (colorHex != null && colorHex.startsWith('#')) {
      try {
        color = Color(int.parse('FF${colorHex.substring(1)}', radix: 16));
      } on FormatException {
        color = null;
      }
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
