#!/usr/bin/env python3
"""
Skill Validator - Validate Claude skills against best practices

Usage:
    validate_skill.py <skill-path>
    validate_skill.py <skill-path> --verbose
    validate_skill.py <skill-path> --strict

Examples:
    validate_skill.py ./my-skill
    validate_skill.py ./my-skill --verbose
"""

import sys
import re
import yaml
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import Optional


@dataclass
class ValidationResult:
    """Result of a validation check."""
    passed: bool
    message: str
    severity: str = 'error'  # error, warning, info


class SkillValidator:
    """Validates Claude skills against best practices."""
    
    # Allowed frontmatter fields
    ALLOWED_FIELDS = {'name', 'description', 'license', 'allowed-tools', 'metadata'}
    
    # Forbidden files (should not exist in skill)
    FORBIDDEN_FILES = {
        'README.md', 'readme.md', 'README.txt',
        'CHANGELOG.md', 'changelog.md', 'CHANGELOG.txt',
        'INSTALLATION.md', 'INSTALL.md', 'install.md',
        'INSTALLATION_GUIDE.md', 'QUICK_REFERENCE.md',
        '.gitignore', '.git', '__pycache__', '.pytest_cache'
    }
    
    def __init__(self, skill_path: Path, strict: bool = False):
        self.skill_path = skill_path
        self.strict = strict
        self.results: list[ValidationResult] = []
    
    def add_result(self, passed: bool, message: str, severity: str = 'error'):
        """Add a validation result."""
        self.results.append(ValidationResult(passed, message, severity))
    
    def validate_structure(self) -> bool:
        """Validate skill directory structure."""
        # Check skill directory exists
        if not self.skill_path.exists():
            self.add_result(False, f"Skill directory not found: {self.skill_path}")
            return False
        
        if not self.skill_path.is_dir():
            self.add_result(False, f"Path is not a directory: {self.skill_path}")
            return False
        
        # Check SKILL.md exists
        skill_md = self.skill_path / 'SKILL.md'
        if not skill_md.exists():
            # Check for case variations
            for variant in ['skill.md', 'Skill.md']:
                if (self.skill_path / variant).exists():
                    self.add_result(False, f"SKILL.md must be uppercase (found: {variant})")
                    return False
            self.add_result(False, "SKILL.md not found (required)")
            return False
        
        self.add_result(True, "SKILL.md found")
        
        # Check for forbidden files
        for item in self.skill_path.iterdir():
            if item.name in self.FORBIDDEN_FILES:
                self.add_result(False, f"Forbidden file found: {item.name}", 'warning')
        
        # Check standard directories (optional but recommended)
        for dir_name in ['scripts', 'references', 'assets']:
            dir_path = self.skill_path / dir_name
            if dir_path.exists() and not dir_path.is_dir():
                self.add_result(False, f"{dir_name} should be a directory, not a file")
        
        return True
    
    def validate_frontmatter(self) -> Optional[dict]:
        """Validate YAML frontmatter."""
        skill_md = self.skill_path / 'SKILL.md'
        content = skill_md.read_text()
        
        # Check frontmatter exists and is properly delimited
        if not content.startswith('---'):
            self.add_result(False, "SKILL.md must start with '---' (YAML frontmatter delimiter)")
            return None
        
        # Extract frontmatter
        parts = content.split('---', 2)
        if len(parts) < 3:
            self.add_result(False, "Invalid frontmatter: missing closing '---'")
            return None
        
        frontmatter_text = parts[1].strip()
        
        # Parse YAML
        try:
            frontmatter = yaml.safe_load(frontmatter_text)
            if not isinstance(frontmatter, dict):
                self.add_result(False, "Frontmatter must be a YAML dictionary")
                return None
        except yaml.YAMLError as e:
            self.add_result(False, f"Invalid YAML in frontmatter: {e}")
            return None
        
        self.add_result(True, "Valid YAML frontmatter")
        
        # Check required fields
        if 'name' not in frontmatter:
            self.add_result(False, "Missing required field: 'name'")
        else:
            self.validate_name(frontmatter['name'])
        
        if 'description' not in frontmatter:
            self.add_result(False, "Missing required field: 'description'")
        else:
            self.validate_description(frontmatter['description'])
        
        # Check for unexpected fields
        for key in frontmatter:
            if key not in self.ALLOWED_FIELDS:
                self.add_result(
                    False,
                    f"Unexpected frontmatter field: '{key}' (allowed: {', '.join(self.ALLOWED_FIELDS)})",
                    'error'
                )
        
        return frontmatter
    
    def validate_name(self, name: str):
        """Validate skill name field."""
        # Check type
        if not isinstance(name, str):
            self.add_result(False, f"'name' must be a string, got: {type(name).__name__}")
            return
        
        # Check length
        if len(name) > 40:
            self.add_result(False, f"'name' exceeds 40 characters: {len(name)}")
        
        # Check format (hyphen-case)
        if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
            self.add_result(False, f"'name' must be hyphen-case (lowercase, hyphens): {name}")
        
        # Check matches directory name
        if name != self.skill_path.name:
            self.add_result(
                False,
                f"'name' ({name}) must match directory name ({self.skill_path.name})",
                'warning'
            )
        
        self.add_result(True, f"Valid name: {name}")
    
    def validate_description(self, description: str):
        """Validate skill description field."""
        # Check type
        if not isinstance(description, str):
            self.add_result(False, f"'description' must be a string, got: {type(description).__name__}")
            return
        
        # Check length
        if len(description) > 1024:
            self.add_result(False, f"'description' exceeds 1024 characters: {len(description)}")
        
        if len(description) < 20:
            self.add_result(False, f"'description' too short (<20 chars): {len(description)}", 'warning')
        
        # Check for first-person (should be third-person)
        first_person = ['I ', 'We ', 'You ', ' I ', ' we ', ' you ']
        for fp in first_person:
            if fp in description:
                self.add_result(
                    False,
                    f"'description' should use third-person voice (found: '{fp.strip()}')",
                    'warning'
                )
                break
        
        # Check for trigger information
        trigger_keywords = ['use when', 'use for', 'when', 'for']
        has_trigger = any(kw in description.lower() for kw in trigger_keywords)
        if not has_trigger:
            self.add_result(
                False,
                "'description' should include when to use the skill (e.g., 'Use when...')",
                'warning'
            )
        
        self.add_result(True, f"Valid description ({len(description)} chars)")
    
    def validate_body(self) -> bool:
        """Validate SKILL.md body content."""
        skill_md = self.skill_path / 'SKILL.md'
        content = skill_md.read_text()
        
        # Extract body (after frontmatter)
        parts = content.split('---', 2)
        if len(parts) < 3:
            return False
        
        body = parts[2].strip()
        
        if not body:
            self.add_result(False, "SKILL.md body is empty")
            return False
        
        # Check line count
        lines = body.split('\n')
        line_count = len(lines)
        
        if line_count > 500:
            self.add_result(
                False,
                f"SKILL.md body exceeds 500 lines ({line_count}). Consider splitting to references/",
                'warning'
            )
        
        # Check for TODO placeholders
        if '[TODO' in body or 'TODO:' in body:
            self.add_result(False, "SKILL.md contains TODO placeholders", 'warning')
        
        # Check for headers
        if '# ' not in body:
            self.add_result(False, "SKILL.md should have at least one header", 'warning')
        
        # Check for broken file references
        ref_pattern = r'\[([^\]]+)\]\(([^)]+\.md)\)'
        for match in re.finditer(ref_pattern, body):
            ref_path = match.group(2)
            if not ref_path.startswith('http'):
                full_path = self.skill_path / ref_path
                if not full_path.exists():
                    self.add_result(
                        False,
                        f"Broken reference: {ref_path} (file not found)",
                        'warning'
                    )
        
        self.add_result(True, f"Valid body ({line_count} lines)")
        return True
    
    def validate_scripts(self):
        """Validate scripts directory if it exists."""
        scripts_dir = self.skill_path / 'scripts'
        if not scripts_dir.exists():
            return
        
        for script in scripts_dir.glob('*.py'):
            # Check shebang
            content = script.read_text()
            if not content.startswith('#!'):
                self.add_result(
                    False,
                    f"Script missing shebang: {script.name}",
                    'warning'
                )
            
            # Check docstring
            if '"""' not in content[:500] and "'''" not in content[:500]:
                self.add_result(
                    False,
                    f"Script missing docstring: {script.name}",
                    'warning'
                )
            
            # Check syntax (basic)
            try:
                compile(content, script, 'exec')
                self.add_result(True, f"Valid Python syntax: {script.name}")
            except SyntaxError as e:
                self.add_result(False, f"Syntax error in {script.name}: {e}")
    
    def validate_references(self):
        """Validate references directory if it exists."""
        refs_dir = self.skill_path / 'references'
        if not refs_dir.exists():
            return
        
        for ref in refs_dir.glob('*.md'):
            content = ref.read_text()
            
            # Check not empty
            if len(content.strip()) < 50:
                self.add_result(
                    False,
                    f"Reference file nearly empty: {ref.name}",
                    'warning'
                )
            
            # Check has content (not just headers)
            non_header_content = re.sub(r'^#+.*$', '', content, flags=re.MULTILINE)
            if len(non_header_content.strip()) < 50:
                self.add_result(
                    False,
                    f"Reference file has headers but little content: {ref.name}",
                    'warning'
                )
    
    def validate(self) -> bool:
        """Run all validations and return overall result."""
        print(f"\n🔍 Validating skill: {self.skill_path.name}")
        print("=" * 50)
        
        # Structure validation
        if not self.validate_structure():
            return self._print_results()
        
        # Frontmatter validation
        frontmatter = self.validate_frontmatter()
        
        # Body validation
        self.validate_body()
        
        # Scripts validation
        self.validate_scripts()
        
        # References validation
        self.validate_references()
        
        return self._print_results()
    
    def _print_results(self) -> bool:
        """Print results and return True if all critical checks passed."""
        errors = []
        warnings = []
        passed = []
        
        for result in self.results:
            if result.severity == 'error' and not result.passed:
                errors.append(result)
            elif result.severity == 'warning' and not result.passed:
                warnings.append(result)
            elif result.passed:
                passed.append(result)
        
        # Print passed checks
        if passed:
            print("\n✅ Passed:")
            for r in passed:
                print(f"   • {r.message}")
        
        # Print warnings
        if warnings:
            print("\n⚠️  Warnings:")
            for r in warnings:
                print(f"   • {r.message}")
        
        # Print errors
        if errors:
            print("\n❌ Errors:")
            for r in errors:
                print(f"   • {r.message}")
        
        # Summary
        print("\n" + "=" * 50)
        total = len(self.results)
        error_count = len(errors)
        warning_count = len(warnings)
        
        if error_count == 0:
            if warning_count == 0:
                print("✅ All checks passed!")
            else:
                print(f"✅ Passed with {warning_count} warning(s)")
            return True
        else:
            print(f"❌ Failed: {error_count} error(s), {warning_count} warning(s)")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Validate Claude skills",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "skill_path",
        help="Path to the skill directory"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show all validation details"
    )
    parser.add_argument(
        "--strict", "-s",
        action="store_true",
        help="Treat warnings as errors"
    )
    
    args = parser.parse_args()
    
    skill_path = Path(args.skill_path).resolve()
    validator = SkillValidator(skill_path, strict=args.strict)
    
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
