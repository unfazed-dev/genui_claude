#!/usr/bin/env python3
"""
GenUI CatalogItem Generator
Generates CatalogItem definitions for Flutter GenUI SDK.

Usage:
    python generate_catalog.py ProductCard --props "title:string,price:number,imageUrl:string?" --required title,price
    python generate_catalog.py RatingStar --props "label:string?,maxStars:int,value:int?" --events rating_changed
    python generate_catalog.py BookingForm --props "checkIn:string,checkOut:string,guests:int" --bound
"""

import argparse
import os
import re
import sys
from pathlib import Path
from typing import NamedTuple

class Property(NamedTuple):
    name: str
    type: str
    optional: bool
    description: str

def to_snake_case(name: str) -> str:
    """Convert PascalCase to snake_case."""
    result = []
    for i, char in enumerate(name):
        if char.isupper() and i > 0:
            result.append('_')
        result.append(char.lower())
    return ''.join(result)

def to_pascal_case(name: str) -> str:
    """Convert snake_case to PascalCase."""
    return ''.join(word.capitalize() for word in name.split('_'))

def parse_properties(props_str: str) -> list[Property]:
    """Parse property string like 'name:string,price:number?'"""
    if not props_str:
        return []
    
    properties = []
    for prop in props_str.split(','):
        prop = prop.strip()
        if ':' not in prop:
            continue
        
        name, type_str = prop.split(':', 1)
        name = name.strip()
        type_str = type_str.strip()
        
        optional = type_str.endswith('?')
        if optional:
            type_str = type_str[:-1]
        
        # Map to schema types
        type_map = {
            'string': 'string',
            'str': 'string',
            'number': 'number',
            'num': 'number',
            'double': 'number',
            'float': 'number',
            'int': 'integer',
            'integer': 'integer',
            'bool': 'boolean',
            'boolean': 'boolean',
        }
        
        schema_type = type_map.get(type_str.lower(), 'string')
        description = f'{name.replace("_", " ").title()}'
        
        properties.append(Property(
            name=name,
            type=schema_type,
            optional=optional,
            description=description,
        ))
    
    return properties

def schema_type_to_dart(prop: Property) -> str:
    """Convert schema type to Dart extraction code."""
    type_map = {
        'string': ('String', "''"),
        'number': ('num', '0'),
        'integer': ('int', '0'),
        'boolean': ('bool', 'false'),
    }
    
    dart_type, default = type_map.get(prop.type, ('String', "''"))
    
    if prop.optional:
        return f"final {prop.name} = json['{prop.name}'] as {dart_type}?;"
    else:
        return f"final {prop.name} = json['{prop.name}'] as {dart_type}? ?? {default};"

def generate_schema(properties: list[Property], required: list[str]) -> str:
    """Generate schema definition."""
    if not properties:
        return "S.object(properties: {})"
    
    prop_lines = []
    for prop in properties:
        type_method = {
            'string': 'S.string',
            'number': 'S.number',
            'integer': 'S.integer',
            'boolean': 'S.boolean',
        }.get(prop.type, 'S.string')
        
        prop_lines.append(f"    '{prop.name}': {type_method}(description: '{prop.description}'),")
    
    required_str = ', '.join(f"'{r}'" for r in required) if required else ''
    
    return f"""S.object(
  properties: {{
{chr(10).join(prop_lines)}
  }},
  required: [{required_str}],
)"""

def generate_catalog_item(
    name: str,
    properties: list[Property],
    required: list[str],
    events: list[str],
    with_children: bool,
    data_bound: bool,
) -> str:
    """Generate complete CatalogItem code."""
    
    snake_name = to_snake_case(name)
    pascal_name = to_pascal_case(snake_name)
    
    # Schema
    schema = generate_schema(properties, required)
    
    # Property extraction
    extractions = []
    for prop in properties:
        extractions.append(f"    {schema_type_to_dart(prop)}")
    
    # Build widget content
    widget_content = _generate_widget_content(properties, events, with_children, data_bound)
    
    return f'''import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for {pascal_name}
final _{snake_name}Schema = {schema};

/// {pascal_name} CatalogItem for GenUI
final {snake_name} = CatalogItem(
  name: '{pascal_name}',
  dataSchema: _{snake_name}Schema,
  widgetBuilder: ({{
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }}) {{
    final json = data as Map<String, Object?>;
    
    // Extract properties
{chr(10).join(extractions)}
    
{widget_content}
  }},
);
'''

def _generate_widget_content(
    properties: list[Property],
    events: list[str],
    with_children: bool,
    data_bound: bool,
) -> str:
    """Generate the widget builder content."""
    
    lines = []
    lines.append("    return Card(")
    lines.append("      child: Padding(")
    lines.append("        padding: const EdgeInsets.all(16),")
    lines.append("        child: Column(")
    lines.append("          crossAxisAlignment: CrossAxisAlignment.start,")
    lines.append("          children: [")
    
    # Add property displays
    for prop in properties:
        if prop.type == 'string':
            if prop.optional:
                lines.append(f"            if ({prop.name} != null)")
                lines.append(f"              Text({prop.name}!, style: Theme.of(context).textTheme.bodyLarge),")
            else:
                lines.append(f"            Text({prop.name}, style: Theme.of(context).textTheme.bodyLarge),")
        elif prop.type in ('number', 'integer'):
            lines.append(f"            Text('{prop.name}: ${prop.name}'),")
        elif prop.type == 'boolean':
            lines.append(f"            if ({prop.name}) const Icon(Icons.check_circle, color: Colors.green),")
    
    # Add children placeholder
    if with_children:
        lines.append("            // Build child widgets")
        lines.append("            // buildChild(childData),")
    
    # Add event buttons
    for event in events:
        lines.append(f"            const SizedBox(height: 8),")
        lines.append(f"            ElevatedButton(")
        lines.append(f"              onPressed: () => dispatchEvent(GenUiEvent(")
        lines.append(f"                type: '{event}',")
        lines.append(f"                payload: {{}},")
        lines.append(f"              )),")
        lines.append(f"              child: const Text('{event.replace('_', ' ').title()}'),")
        lines.append(f"            ),")
    
    lines.append("          ],")
    lines.append("        ),")
    lines.append("      ),")
    lines.append("    );")
    
    return '\n'.join(lines)

def find_project_root() -> Path | None:
    """Find Flutter project root."""
    current = Path.cwd()
    while current != current.parent:
        if (current / 'pubspec.yaml').exists():
            return current
        current = current.parent
    return None

def write_file(path: Path, content: str, overwrite: bool = False):
    """Write content to file."""
    if path.exists() and not overwrite:
        print(f'  ⚠️  Skipped (exists): {path}')
        return False
    
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f'  ✓ Created: {path}')
    return True

def main():
    parser = argparse.ArgumentParser(
        description='Generate GenUI CatalogItem definitions',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s ProductCard --props "title:string,price:number,imageUrl:string?" --required title,price
  %(prog)s RatingStar --props "label:string?,maxStars:int,value:int?" --events rating_changed
  %(prog)s BookingForm --props "checkIn:string,checkOut:string" --bound --children
  
Property Types:
  string, str     -> S.string()
  number, num     -> S.number()
  int, integer    -> S.integer()
  bool, boolean   -> S.boolean()
  
Add ? suffix for optional: "name:string?"
        '''
    )
    
    parser.add_argument('name', help='CatalogItem name (e.g., ProductCard)')
    parser.add_argument('--props', help='Properties as "name:type,name:type?"')
    parser.add_argument('--required', help='Comma-separated required property names')
    parser.add_argument('--events', help='Comma-separated event names to dispatch')
    parser.add_argument('--children', action='store_true', help='Include child composition support')
    parser.add_argument('--bound', action='store_true', help='Include DataModel binding')
    parser.add_argument('--output', '-o', help='Output file path (default: lib/genui/catalog/<name>.dart)')
    
    args = parser.parse_args()
    
    # Parse inputs
    properties = parse_properties(args.props) if args.props else []
    required = [r.strip() for r in args.required.split(',')] if args.required else []
    events = [e.strip() for e in args.events.split(',')] if args.events else []
    
    # Generate content
    content = generate_catalog_item(
        name=args.name,
        properties=properties,
        required=required,
        events=events,
        with_children=args.children,
        data_bound=args.bound,
    )
    
    # Determine output path
    if args.output:
        output_path = Path(args.output)
    else:
        project_root = find_project_root()
        if project_root:
            snake_name = to_snake_case(args.name)
            output_path = project_root / 'lib' / 'genui' / 'catalog' / f'{snake_name}.dart'
        else:
            snake_name = to_snake_case(args.name)
            output_path = Path(f'{snake_name}.dart')
    
    # Write file
    print(f'Generating CatalogItem: {args.name}')
    print(f'  Properties: {len(properties)}')
    print(f'  Required: {required}')
    print(f'  Events: {events}')
    print()
    
    write_file(output_path, content)
    
    print()
    print('✅ Done!')
    print()
    print('Next steps:')
    print(f'  1. Import in your catalog: import "genui/catalog/{to_snake_case(args.name)}.dart";')
    print(f'  2. Add to GenUiManager: catalog: CoreCatalogItems.asCatalog().copyWith([{to_snake_case(args.name)}])')
    print(f'  3. Update system instruction to reference "{args.name}"')

if __name__ == '__main__':
    main()
