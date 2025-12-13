#!/usr/bin/env python3
"""
Skill Generator - Generate Claude skills from natural language descriptions

Usage:
    generate_skill.py "<description>"
    generate_skill.py "<description>" --type <skill-type>
    generate_skill.py "<description>" --path <output-directory>

By default, skills are created in .claude/skills/ directory of the current project.

Examples:
    generate_skill.py "Flutter widget testing toolkit"
    generate_skill.py "NDIS compliance checker" --type workflow
    generate_skill.py "REST API integration helper" --name api-toolkit
    generate_skill.py "Custom skill" --path /custom/output/path

Skill Types:
    - technical: Code-focused with scripts and examples
    - workflow: Process-focused with decision trees
    - reference: Knowledge-focused with documentation
    - integration: API-focused with authentication
    - creative: Design-focused with templates
    - auto (default): Infer from description
"""

import sys
import re
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional


# ============================================================================
# SKILL TYPE DETECTION
# ============================================================================

SKILL_TYPE_KEYWORDS = {
    'technical': [
        'code', 'script', 'programming', 'development', 'toolkit', 'library',
        'framework', 'debug', 'testing', 'build', 'compile', 'flutter', 'dart',
        'python', 'javascript', 'typescript', 'react', 'api', 'sdk'
    ],
    'workflow': [
        'workflow', 'process', 'procedure', 'steps', 'pipeline', 'automation',
        'management', 'coordination', 'orchestration', 'sequence', 'flow'
    ],
    'reference': [
        'guide', 'reference', 'documentation', 'knowledge', 'expertise',
        'standards', 'compliance', 'regulations', 'rules', 'policies'
    ],
    'integration': [
        'integration', 'api', 'service', 'endpoint', 'authentication',
        'oauth', 'webhook', 'external', 'third-party', 'connect'
    ],
    'creative': [
        'design', 'template', 'style', 'brand', 'visual', 'ui', 'ux',
        'creative', 'artistic', 'aesthetic', 'layout'
    ]
}


def detect_skill_type(description: str) -> str:
    """Detect the most appropriate skill type from description."""
    description_lower = description.lower()
    scores = {stype: 0 for stype in SKILL_TYPE_KEYWORDS}
    
    for skill_type, keywords in SKILL_TYPE_KEYWORDS.items():
        for keyword in keywords:
            if keyword in description_lower:
                scores[skill_type] += 1
    
    max_score = max(scores.values())
    if max_score == 0:
        return 'technical'  # Default
    
    return max(scores, key=scores.get)


# ============================================================================
# NAME GENERATION
# ============================================================================

def generate_skill_name(description: str) -> str:
    """Generate a hyphen-case skill name from description."""
    # Extract key nouns and verbs
    words = re.findall(r'\b[a-zA-Z]+\b', description.lower())
    
    # Remove common words
    stopwords = {
        'the', 'a', 'an', 'and', 'or', 'for', 'to', 'with', 'from', 'by',
        'this', 'that', 'which', 'when', 'where', 'how', 'what', 'why',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has',
        'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may',
        'can', 'use', 'using', 'used', 'create', 'creating', 'build', 'building'
    }
    
    meaningful_words = [w for w in words if w not in stopwords and len(w) > 2]
    
    # Take first 3-4 meaningful words
    name_parts = meaningful_words[:4]
    
    # Join with hyphens
    name = '-'.join(name_parts)
    
    # Ensure max length
    if len(name) > 40:
        name = name[:40].rsplit('-', 1)[0]
    
    return name or 'new-skill'


# ============================================================================
# DESCRIPTION GENERATION
# ============================================================================

def generate_description(name: str, raw_description: str, skill_type: str) -> str:
    """Generate an optimized skill description."""
    # Clean up raw description
    desc = raw_description.strip()
    
    # Ensure third-person and present tense
    if desc.startswith(('I ', 'We ', 'You ')):
        desc = desc.split(' ', 1)[1]
    
    # Add type-specific suffixes if not present
    type_triggers = {
        'technical': 'Use when writing code, debugging, or building applications.',
        'workflow': 'Use when managing processes, coordinating tasks, or following procedures.',
        'reference': 'Use when looking up standards, checking compliance, or referencing documentation.',
        'integration': 'Use when connecting to external services, making API calls, or handling authentication.',
        'creative': 'Use when designing interfaces, applying styles, or creating visual content.'
    }
    
    if 'use when' not in desc.lower():
        trigger = type_triggers.get(skill_type, 'Use when this capability is needed.')
        desc = f"{desc}. {trigger}"
    
    # Ensure under 200 chars (leaving room for potential expansion)
    if len(desc) > 200:
        desc = desc[:197] + '...'
    
    return desc


# ============================================================================
# TEMPLATE SELECTION
# ============================================================================

TEMPLATES = {
    'technical': '''---
name: {name}
description: {description}
---

# {title}

## Quick Start

```{language}
# Example usage
{quick_start_example}
```

## Core Operations

### Operation 1: [Name]

```{language}
[Code example]
```

### Operation 2: [Name]

```{language}
[Code example]
```

## Common Patterns

### Pattern: [Name]
[Description and example]

## Troubleshooting

| Problem | Solution |
|---------|----------|
| [Issue] | [Fix] |
| [Issue] | [Fix] |

## Resources

For advanced usage, see references/advanced.md
''',

    'workflow': '''---
name: {name}
description: {description}
---

# {title}

## Overview

{overview}

## Workflow Decision Tree

1. **Determine task type:**
   - [Condition A] → Follow "Path A" below
   - [Condition B] → Follow "Path B" below
   - [Condition C] → Follow "Path C" below

## Path A: [Workflow Name]

### Step 1: [Action]
[Instructions]

### Step 2: [Action]
[Instructions]

### Step 3: [Action]
[Instructions]

## Path B: [Workflow Name]

### Step 1: [Action]
[Instructions]

### Step 2: [Action]
[Instructions]

## Validation Checklist

- [ ] [Checkpoint 1]
- [ ] [Checkpoint 2]
- [ ] [Checkpoint 3]

## Error Recovery

| Failure | Recovery Action |
|---------|-----------------|
| [Issue] | [Steps to recover] |
''',

    'reference': '''---
name: {name}
description: {description}
---

# {title}

## Overview

{overview}

## Core Concepts

### [Concept 1]
[Explanation]

### [Concept 2]
[Explanation]

### [Concept 3]
[Explanation]

## Terminology

| Term | Definition |
|------|------------|
| [Term] | [Definition] |
| [Term] | [Definition] |
| [Term] | [Definition] |

## Guidelines

### Requirement 1: [Name]
[Details]

### Requirement 2: [Name]
[Details]

## Best Practices

1. **[Practice]**: [Why and how]
2. **[Practice]**: [Why and how]
3. **[Practice]**: [Why and how]

## Common Mistakes

- **[Mistake]**: [Why it's wrong] → [How to fix]
- **[Mistake]**: [Why it's wrong] → [How to fix]

## Resources

For detailed specifications, see references/specifications.md
''',

    'integration': '''---
name: {name}
description: {description}
---

# {title}

## Overview

{overview}

## Authentication

```python
import requests

# Setup
API_BASE = "https://api.example.com/v1"
headers = {{
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "application/json"
}}
```

## Core Endpoints

### Endpoint: [Resource Name]

**GET** `/resource`
```python
response = requests.get(f"{{API_BASE}}/resource", headers=headers)
data = response.json()
```

**POST** `/resource`
```python
payload = {{"field": "value"}}
response = requests.post(f"{{API_BASE}}/resource", json=payload, headers=headers)
```

### Endpoint: [Another Resource]

```python
# Example usage
```

## Error Handling

| Status Code | Meaning | Action |
|-------------|---------|--------|
| 400 | Bad Request | Check payload format |
| 401 | Unauthorized | Refresh authentication |
| 404 | Not Found | Verify resource exists |
| 429 | Rate Limited | Implement backoff |
| 500 | Server Error | Retry with exponential backoff |

## Rate Limits

- **Requests**: X per minute
- **Burst**: Y concurrent requests
- **Handling**: Implement exponential backoff

```python
import time

def api_call_with_retry(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except RateLimitError:
            wait = 2 ** attempt
            time.sleep(wait)
    raise Exception("Max retries exceeded")
```

## Resources

For complete API reference, see references/api_reference.md
''',

    'creative': '''---
name: {name}
description: {description}
---

# {title}

## Overview

{overview}

## Design Principles

1. **[Principle]**: [Explanation]
2. **[Principle]**: [Explanation]
3. **[Principle]**: [Explanation]

## Style Guide

### Typography
- **Primary Font**: [Font name] - Use for [context]
- **Secondary Font**: [Font name] - Use for [context]
- **Sizes**: Heading (24-32px), Body (16px), Caption (12-14px)

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Primary | #XXXXXX | Main actions, headers |
| Secondary | #XXXXXX | Supporting elements |
| Accent | #XXXXXX | Highlights, CTAs |
| Background | #XXXXXX | Page backgrounds |
| Text | #XXXXXX | Body text |

### Spacing
- **Base unit**: 8px
- **Tight**: 4px
- **Default**: 16px
- **Loose**: 24px
- **Section**: 48px

## Components

### Component: [Name]
[Description and usage]

```html
<!-- Example -->
```

### Component: [Name]
[Description and usage]

## Templates

Available in assets/:
- `template-a.html` - [Description]
- `template-b.html` - [Description]

## Anti-Patterns

- **Don't**: [Bad practice]
- **Don't**: [Bad practice]
- **Don't**: [Bad practice]
'''
}


def get_template(skill_type: str) -> str:
    """Get the appropriate template for skill type."""
    return TEMPLATES.get(skill_type, TEMPLATES['technical'])


# ============================================================================
# LANGUAGE DETECTION
# ============================================================================

def detect_language(description: str) -> str:
    """Detect the primary programming language from description."""
    language_keywords = {
        'dart': ['dart', 'flutter'],
        'python': ['python', 'django', 'flask', 'fastapi'],
        'javascript': ['javascript', 'js', 'node', 'nodejs'],
        'typescript': ['typescript', 'ts', 'angular', 'nest'],
        'java': ['java', 'spring', 'android'],
        'kotlin': ['kotlin'],
        'swift': ['swift', 'ios', 'swiftui'],
        'rust': ['rust', 'cargo'],
        'go': ['golang', ' go '],
        'bash': ['bash', 'shell', 'cli', 'command']
    }
    
    desc_lower = description.lower()
    for lang, keywords in language_keywords.items():
        for kw in keywords:
            if kw in desc_lower:
                return lang
    
    return 'python'  # Default


# ============================================================================
# SKILL GENERATION
# ============================================================================

def generate_skill(
    description: str,
    output_path: str,
    skill_type: Optional[str] = None,
    skill_name: Optional[str] = None
) -> Path:
    """Generate a complete skill from description."""
    
    # Auto-detect type if not specified
    if skill_type is None or skill_type == 'auto':
        skill_type = detect_skill_type(description)
    
    # Generate name if not specified
    if skill_name is None:
        skill_name = generate_skill_name(description)
    
    # Create skill directory
    output_dir = Path(output_path).resolve()
    skill_dir = output_dir / skill_name
    
    if skill_dir.exists():
        print(f"⚠️  Directory exists: {skill_dir}")
        print("    Use --force to overwrite or choose a different name")
        return None
    
    skill_dir.mkdir(parents=True)
    print(f"✅ Created: {skill_dir}")
    
    # Generate title
    title = ' '.join(word.capitalize() for word in skill_name.split('-'))
    
    # Generate description
    opt_description = generate_description(skill_name, description, skill_type)
    
    # Detect language for code examples
    language = detect_language(description)
    
    # Get template and fill
    template = get_template(skill_type)
    
    # Create placeholders
    overview = f"This skill provides {skill_type} capabilities for {title.lower()}."
    quick_start = f"# Quick start example for {skill_name}\nprint('Hello from {skill_name}!')"
    
    content = template.format(
        name=skill_name,
        description=opt_description,
        title=title,
        overview=overview,
        language=language,
        quick_start_example=quick_start
    )
    
    # Write SKILL.md
    skill_md = skill_dir / 'SKILL.md'
    skill_md.write_text(content)
    print(f"✅ Created: SKILL.md ({skill_type} template)")
    
    # Create directories based on type
    if skill_type in ['technical', 'integration']:
        scripts_dir = skill_dir / 'scripts'
        scripts_dir.mkdir()
        
        # Create example script
        example_script = scripts_dir / 'example.py'
        example_script.write_text(f'''#!/usr/bin/env python3
"""
Example script for {skill_name}

Usage:
    python example.py [args]
"""

def main():
    print("Example script for {skill_name}")
    # TODO: Implement functionality

if __name__ == "__main__":
    main()
''')
        example_script.chmod(0o755)
        print(f"✅ Created: scripts/example.py")
    
    if skill_type in ['reference', 'technical', 'integration']:
        refs_dir = skill_dir / 'references'
        refs_dir.mkdir()
        
        ref_file = refs_dir / 'reference.md'
        ref_file.write_text(f'''# {title} Reference

## Detailed Documentation

[Add comprehensive reference documentation here]

## API Reference

[Add API details if applicable]

## Examples

[Add detailed examples]
''')
        print(f"✅ Created: references/reference.md")
    
    if skill_type == 'creative':
        assets_dir = skill_dir / 'assets'
        assets_dir.mkdir()
        
        # Create sample asset
        sample = assets_dir / 'sample_template.html'
        sample.write_text('''<!DOCTYPE html>
<html>
<head>
    <title>Sample Template</title>
    <style>
        /* Add styles here */
    </style>
</head>
<body>
    <!-- Template content -->
</body>
</html>
''')
        print(f"✅ Created: assets/sample_template.html")
    
    # Print summary
    print(f"\n✅ Skill '{skill_name}' generated successfully!")
    print(f"\n📋 Summary:")
    print(f"   Type: {skill_type}")
    print(f"   Language: {language}")
    print(f"   Location: {skill_dir}")
    print(f"\n📝 Next steps:")
    print("   1. Edit SKILL.md to customize the content")
    print("   2. Replace placeholder sections with real content")
    print("   3. Add any required scripts or references")
    print("   4. Validate with: validate_skill.py <skill-path>")
    print("   5. Package with: package_skill.py <skill-path>")
    
    return skill_dir


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate Claude skills from descriptions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    %(prog)s "Flutter widget testing"
    %(prog)s "NDIS compliance workflow" --type workflow
    %(prog)s "REST API helper" --name api-toolkit
    %(prog)s "Custom skill" --path /custom/path

Output:
    By default, skills are created in .claude/skills/ directory.
    This ensures Claude automatically discovers and uses them in the project.

Skill Types:
    technical   - Code-focused with scripts and examples
    workflow    - Process-focused with decision trees
    reference   - Knowledge-focused with documentation
    integration - API-focused with authentication
    creative    - Design-focused with templates
    auto        - Automatically detect from description (default)
        """
    )
    
    parser.add_argument(
        "description",
        help="Natural language description of the skill"
    )
    parser.add_argument(
        "--path", "-p",
        default=".claude/skills",
        help="Output directory for the skill (default: .claude/skills)"
    )
    parser.add_argument(
        "--type", "-t",
        choices=['technical', 'workflow', 'reference', 'integration', 'creative', 'auto'],
        default='auto',
        help="Skill type (default: auto-detect)"
    )
    parser.add_argument(
        "--name", "-n",
        help="Override generated skill name"
    )
    parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Overwrite existing skill directory"
    )
    
    args = parser.parse_args()
    
    print(f"\n🏭 Skills Factory - Generating Skill")
    print(f"{'='*50}")
    print(f"Description: {args.description}")
    print(f"Output path: {args.path}")
    print(f"Type: {args.type}")
    print(f"{'='*50}\n")
    
    result = generate_skill(
        args.description,
        args.path,
        args.type if args.type != 'auto' else None,
        args.name
    )
    
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
