#!/usr/bin/env python3
"""
Skill Suite Generator - Generate interconnected skill suites for complex domains

Usage:
    generate_suite.py "<domain>"
    generate_suite.py "<domain>" --skills <count>
    generate_suite.py "<domain>" --path <output-directory>

By default, suites are created in .claude/skills/ directory of the current project.

Examples:
    generate_suite.py "NDIS service management"
    generate_suite.py "Flutter application development" --skills 5
    generate_suite.py "E-commerce platform" --detailed
    generate_suite.py "Custom domain" --path /custom/path
"""

import sys
import argparse
from pathlib import Path
from typing import Optional
import subprocess


# ============================================================================
# DOMAIN ANALYSIS
# ============================================================================

DOMAIN_PATTERNS = {
    'healthcare': {
        'keywords': ['health', 'medical', 'patient', 'ndis', 'clinical', 'therapy', 'care'],
        'suggested_skills': [
            ('core', 'Core terminology, compliance requirements, and shared utilities'),
            ('participant-management', 'Managing participant records, plans, and preferences'),
            ('provider-coordination', 'Coordinating service providers, schedules, and billing'),
            ('compliance-reporting', 'Generating compliance reports and audit documentation'),
            ('assessment-workflows', 'Conducting assessments and generating recommendations')
        ]
    },
    'development': {
        'keywords': ['flutter', 'dart', 'react', 'coding', 'development', 'programming', 'api'],
        'suggested_skills': [
            ('core', 'Core patterns, architecture decisions, and shared utilities'),
            ('component-builder', 'Building and testing UI components'),
            ('api-integration', 'Integrating with APIs and managing data'),
            ('testing-toolkit', 'Testing strategies, mocking, and quality assurance'),
            ('deployment-workflows', 'Build, deployment, and release management')
        ]
    },
    'business': {
        'keywords': ['business', 'enterprise', 'crm', 'sales', 'marketing', 'operations'],
        'suggested_skills': [
            ('core', 'Core business logic, terminology, and shared utilities'),
            ('customer-management', 'Managing customer records and interactions'),
            ('reporting-analytics', 'Generating reports and analyzing data'),
            ('workflow-automation', 'Automating business processes'),
            ('communication-templates', 'Templates for business communications')
        ]
    },
    'creative': {
        'keywords': ['design', 'creative', 'brand', 'visual', 'content', 'media'],
        'suggested_skills': [
            ('core', 'Core design principles and brand guidelines'),
            ('visual-design', 'Creating visual assets and layouts'),
            ('content-creation', 'Writing and editing content'),
            ('template-library', 'Reusable templates and components'),
            ('asset-management', 'Managing and organizing assets')
        ]
    },
    'data': {
        'keywords': ['data', 'analytics', 'database', 'sql', 'etl', 'pipeline'],
        'suggested_skills': [
            ('core', 'Core schemas, connections, and shared utilities'),
            ('query-builder', 'Building and optimizing queries'),
            ('data-transformation', 'ETL and data transformation workflows'),
            ('reporting-dashboard', 'Creating reports and dashboards'),
            ('data-quality', 'Data validation and quality checks')
        ]
    }
}


def detect_domain(description: str) -> tuple[str, dict]:
    """Detect the domain and return suggested skill structure."""
    description_lower = description.lower()
    
    scores = {}
    for domain, config in DOMAIN_PATTERNS.items():
        score = sum(1 for kw in config['keywords'] if kw in description_lower)
        scores[domain] = score
    
    best_domain = max(scores, key=scores.get)
    
    if scores[best_domain] == 0:
        # No match, use generic
        return 'generic', {
            'suggested_skills': [
                ('core', f'Core functionality and shared utilities for {description}'),
                ('workflows', 'Main workflows and processes'),
                ('integrations', 'External integrations and APIs'),
                ('templates', 'Templates and assets')
            ]
        }
    
    return best_domain, DOMAIN_PATTERNS[best_domain]


def generate_suite_name(description: str) -> str:
    """Generate a suite name from description."""
    import re
    words = re.findall(r'\b[a-zA-Z]+\b', description.lower())
    
    stopwords = {'the', 'a', 'an', 'and', 'or', 'for', 'to', 'with', 'from', 'by'}
    meaningful = [w for w in words if w not in stopwords and len(w) > 2][:3]
    
    return '-'.join(meaningful) + '-suite' if meaningful else 'skill-suite'


# ============================================================================
# SUITE GENERATION
# ============================================================================

def generate_suite(
    description: str,
    output_path: str,
    num_skills: int = 5,
    detailed: bool = False
) -> Path:
    """Generate a complete skill suite for a domain."""
    
    # Detect domain
    domain, config = detect_domain(description)
    print(f"🔍 Detected domain: {domain}")
    
    # Generate suite name
    suite_name = generate_suite_name(description)
    
    # Create suite directory structure
    output_dir = Path(output_path).resolve()
    suite_dir = output_dir / suite_name
    
    if suite_dir.exists():
        print(f"⚠️  Suite directory exists: {suite_dir}")
        return None
    
    suite_dir.mkdir(parents=True)
    print(f"\n📁 Created suite: {suite_dir}")
    
    # Get suggested skills (limit to num_skills)
    suggested = config['suggested_skills'][:num_skills]
    
    # Create each skill in the suite
    generator_script = Path(__file__).parent / 'generate_skill.py'
    
    created_skills = []
    for skill_suffix, skill_desc in suggested:
        skill_name = f"{suite_name.replace('-suite', '')}-{skill_suffix}"
        full_description = f"{skill_desc} for {description}"
        
        print(f"\n🛠️  Generating: {skill_name}")
        
        # Use generate_skill.py if available
        if generator_script.exists():
            result = subprocess.run(
                [
                    sys.executable,
                    str(generator_script),
                    full_description,
                    '--path', str(suite_dir),
                    '--name', skill_name
                ],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                created_skills.append(skill_name)
                print(f"   ✅ Created")
            else:
                print(f"   ❌ Failed: {result.stderr}")
        else:
            # Fallback: create minimal structure
            skill_dir = suite_dir / skill_name
            skill_dir.mkdir(parents=True)
            
            skill_md = skill_dir / 'SKILL.md'
            skill_md.write_text(f'''---
name: {skill_name}
description: {full_description[:200]}
---

# {skill_name.replace("-", " ").title()}

## Overview

[TODO: Add overview for this skill]

## Core Functionality

[TODO: Add core functionality]

## Integration with Suite

This skill is part of the {suite_name} suite and integrates with:
- [List related skills]

## Resources

[TODO: Add resources if needed]
''')
            created_skills.append(skill_name)
            print(f"   ✅ Created (minimal)")
    
    # Create suite index file
    index_file = suite_dir / 'INDEX.md'
    index_file.write_text(f'''# {suite_name.replace("-", " ").title()}

> Generated skill suite for: {description}

## Skills in this Suite

{chr(10).join(f"- **{s}**: See {s}/SKILL.md" for s in created_skills)}

## Usage

Each skill in this suite can be used independently or combined for complex workflows.

### Recommended Order

1. Start with the `*-core` skill for foundational capabilities
2. Add specific workflow skills as needed
3. Use integration skills for external connections

## Suite Architecture

```
{suite_name}/
{chr(10).join(f"├── {s}/" for s in created_skills)}
└── INDEX.md (this file)
```

---
Generated by Skills Factory on {Path(__file__).stem}
''')
    
    print(f"\n✅ Suite '{suite_name}' generated successfully!")
    print(f"\n📋 Summary:")
    print(f"   Domain: {domain}")
    print(f"   Skills created: {len(created_skills)}")
    print(f"   Location: {suite_dir}")
    print(f"\n📝 Next steps:")
    print("   1. Review each skill's SKILL.md")
    print("   2. Customize content for your specific needs")
    print("   3. Add references and scripts as needed")
    print("   4. Test skills individually")
    print("   5. Package skills for distribution")
    
    return suite_dir


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate Claude skill suites for complex domains",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    %(prog)s "NDIS service management"
    %(prog)s "Flutter app development" --skills 5
    %(prog)s "E-commerce platform" --detailed
    %(prog)s "Custom domain" --path /custom/path

Output:
    By default, suites are created in .claude/skills/ directory.
    This ensures Claude automatically discovers and uses them in the project.

Domains detected:
    - healthcare (NDIS, medical, patient management)
    - development (Flutter, React, API development)
    - business (CRM, sales, marketing)
    - creative (design, brand, content)
    - data (analytics, database, ETL)
        """
    )
    
    parser.add_argument(
        "description",
        help="Natural language description of the domain"
    )
    parser.add_argument(
        "--path", "-p",
        default=".claude/skills",
        help="Output directory for the skill suite (default: .claude/skills)"
    )
    parser.add_argument(
        "--skills", "-n",
        type=int,
        default=5,
        help="Number of skills to generate (default: 5)"
    )
    parser.add_argument(
        "--detailed", "-d",
        action="store_true",
        help="Generate more detailed skill content"
    )
    
    args = parser.parse_args()
    
    print(f"\n🏭 Skills Factory - Generating Suite")
    print(f"{'='*50}")
    print(f"Domain: {args.description}")
    print(f"Output: {args.path}")
    print(f"Skills: {args.skills}")
    print(f"{'='*50}")
    
    result = generate_suite(
        args.description,
        args.path,
        args.skills,
        args.detailed
    )
    
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
