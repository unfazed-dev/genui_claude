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

    # Patterns to remove
    patterns_to_remove = [
        r'\n*🤖 Generated with \[Claude Code\]\(https://claude\.com/claude-code\)\n*',
        r'\n*Co-Authored-By: Claude[^\n]*\n*',
        r'\n*Co-Authored-By: Claude Opus[^\n]*\n*',
    ]

    modified_command = command
    for pattern in patterns_to_remove:
        modified_command = re.sub(pattern, '', modified_command)

    # Clean up any trailing/leading whitespace in the message
    # Handle HEREDOC format
    modified_command = re.sub(r'\n+EOF', '\nEOF', modified_command)

    if modified_command != command:
        result = {
            "decision": "continue",
            "updatedInput": {
                "command": modified_command
            }
        }
        print(json.dumps(result))

    sys.exit(0)

if __name__ == "__main__":
    main()
