#!/usr/bin/env python3
"""
Skill Packager - Package Claude skills for distribution

Usage:
    package_skill.py <skill-path> [output-directory]

Examples:
    package_skill.py ./my-skill
    package_skill.py ./my-skill ./dist
    package_skill.py ./my-skill --validate-only
"""

import sys
import zipfile
import argparse
from pathlib import Path
from datetime import datetime
import subprocess


def validate_skill(skill_path: Path) -> bool:
    """Run validation on skill before packaging."""
    validate_script = Path(__file__).parent / 'validate_skill.py'
    
    if validate_script.exists():
        result = subprocess.run(
            [sys.executable, str(validate_script), str(skill_path)],
            capture_output=True,
            text=True
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return result.returncode == 0
    else:
        print("⚠️  Validator not found, skipping validation")
        return True


def package_skill(skill_path: Path, output_dir: Path) -> Path:
    """Package skill into a .skill file."""
    skill_name = skill_path.name
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Create .skill file (zip with .skill extension)
    output_file = output_dir / f"{skill_name}.skill"
    
    print(f"\n📦 Packaging: {skill_name}")
    print(f"   Output: {output_file}")
    
    # Files to exclude
    exclude_patterns = {
        '__pycache__', '.pytest_cache', '.git', '.gitignore',
        '.DS_Store', 'Thumbs.db', '*.pyc', '*.pyo', '.env'
    }
    
    def should_exclude(path: Path) -> bool:
        """Check if file should be excluded."""
        for pattern in exclude_patterns:
            if pattern.startswith('*'):
                if path.name.endswith(pattern[1:]):
                    return True
            elif pattern in str(path):
                return True
        return False
    
    # Create zip
    file_count = 0
    with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        for file_path in skill_path.rglob('*'):
            if file_path.is_file() and not should_exclude(file_path):
                # Store with path relative to skill directory
                arcname = str(file_path.relative_to(skill_path.parent))
                zf.write(file_path, arcname)
                file_count += 1
                print(f"   + {arcname}")
    
    # Get file size
    size_kb = output_file.stat().st_size / 1024
    
    print(f"\n✅ Package created: {output_file}")
    print(f"   Files: {file_count}")
    print(f"   Size: {size_kb:.1f} KB")
    
    return output_file


def main():
    parser = argparse.ArgumentParser(
        description="Package Claude skills for distribution",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    %(prog)s ./my-skill
    %(prog)s ./my-skill ./dist
    %(prog)s ./my-skill --validate-only
        """
    )
    
    parser.add_argument(
        "skill_path",
        help="Path to the skill directory"
    )
    parser.add_argument(
        "output_dir",
        nargs='?',
        default='.',
        help="Output directory for the .skill file (default: current directory)"
    )
    parser.add_argument(
        "--validate-only", "-v",
        action="store_true",
        help="Only validate, don't package"
    )
    parser.add_argument(
        "--skip-validation", "-s",
        action="store_true",
        help="Skip validation step"
    )
    
    args = parser.parse_args()
    
    skill_path = Path(args.skill_path).resolve()
    output_dir = Path(args.output_dir).resolve()
    
    # Validate skill path
    if not skill_path.exists():
        print(f"❌ Skill path not found: {skill_path}")
        sys.exit(1)
    
    if not (skill_path / 'SKILL.md').exists():
        print(f"❌ Not a valid skill directory (SKILL.md not found): {skill_path}")
        sys.exit(1)
    
    # Validate
    if not args.skip_validation:
        print("🔍 Running validation...")
        if not validate_skill(skill_path):
            print("\n❌ Validation failed. Fix errors before packaging.")
            sys.exit(1)
    
    if args.validate_only:
        print("\n✅ Validation complete (--validate-only mode)")
        sys.exit(0)
    
    # Package
    try:
        output_file = package_skill(skill_path, output_dir)
        print(f"\n🎉 Success! Skill packaged to: {output_file}")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Packaging failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
