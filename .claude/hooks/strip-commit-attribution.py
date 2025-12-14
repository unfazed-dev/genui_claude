#!/usr/bin/env python3
"""
Hook to strip Claude Code attribution from git commit messages.
Runs as PreToolUse hook on Bash commands.
"""
import json
import sys
import re

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    # Only process git commit commands
    if tool_name != "Bash" or "git commit" not in command:
        sys.exit(0)

    # Patterns to remove (stop before closing quote or newline)
    patterns_to_remove = [
        r'\n*🤖 Generated with \[Claude Code\]\(https://claude\.com/claude-code\)\n*',
        r'\n*Co-Authored-By: Claude[^\n"]*(?:\n|(?="))',
    ]

    modified_command = command
    for pattern in patterns_to_remove:
        modified_command = re.sub(pattern, '', modified_command)

    # Clean up HEREDOC format - ensure exactly one newline before closing EOF
    # Only match EOF at start of line (the heredoc delimiter), not <<'EOF'
    # First normalize: ensure at least one newline before EOF at start of line
    modified_command = re.sub(r'([^\n])\nEOF\n', r'\1\nEOF\n', modified_command)
    # Handle case where EOF has no newline before it (due to pattern removal)
    modified_command = re.sub(r'([^\n\'])EOF(\n|\))', r'\1\nEOF\2', modified_command)
    # Clean up multiple newlines before EOF delimiter
    modified_command = re.sub(r'\n{2,}EOF(\n|\))', r'\nEOF\1', modified_command)

    if modified_command != command:
        result = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "updatedInput": {
                    "command": modified_command
                }
            }
        }
        print(json.dumps(result))

    sys.exit(0)

if __name__ == "__main__":
    main()
