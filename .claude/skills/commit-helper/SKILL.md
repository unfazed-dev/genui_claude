---
name: commit-helper
description: Semantic commit message generator using Conventional Commits standard. Use when committing changes, staging files, saving work to git, or when user says "commit", "save changes", or "push my work".
---

# Semantic Commit Helper

Generate well-formatted conventional commit messages automatically.

## Activation Triggers

Activate when user:
- Mentions committing, staging, or saving to git
- Says "commit", "save changes", "push my work"
- Asks to create a commit message
- Finishes a task and needs to commit

## Commit Message Format

### Standard Format

```
<type>(<scope>): <description>
```

### With Breaking Change

```
<type>(<scope>)!: <description>
```

### Examples

```
feat: add email OTP authentication flow
fix(auth): resolve null pointer in profile service
refactor(ui): extract validation logic to separate service
feat(api)!: change response format for user endpoints
chore: update dependencies to latest versions
```

---

## Types Reference

| Type | Use When | Example |
|------|----------|---------|
| `feat` | New functionality, user-facing capabilities | `feat: add dark mode toggle` |
| `fix` | Bug fixes, error handling, crash fixes | `fix: resolve crash on empty list` |
| `refactor` | Code restructuring without behavior change | `refactor: extract auth logic to service` |
| `perf` | Performance improvements | `perf: optimize image loading` |
| `test` | Adding/updating tests only | `test: add unit tests for cart service` |
| `docs` | Documentation, README, comments only | `docs: update API documentation` |
| `style` | Formatting, whitespace, lint fixes | `style: fix linting errors` |
| `chore` | Dependencies, config, maintenance | `chore: update flutter to 3.24` |
| `ci` | CI/CD pipeline changes | `ci: add github actions workflow` |
| `build` | Build system, tooling changes | `build: configure release signing` |

### Type Precedence

When changes span multiple types, pick by primary intent:

| Combined Changes | Use | Reason |
|------------------|-----|--------|
| Feature + tests | `feat` | Tests support the feature |
| Bug fix + refactor | `fix` | Fix is the goal |
| Config + docs | `chore` | Unless docs are main deliverable |
| Multiple features | `feat` | Summarize or split commits |

---

## Scope (Optional)

Scopes indicate the area of change. Use lowercase, no spaces.

### Common Scopes

| Scope | Area |
|-------|------|
| `auth` | Authentication, login, sessions |
| `api` | API endpoints, networking |
| `ui` | User interface, widgets |
| `db` | Database, migrations, queries |
| `config` | Configuration, settings |
| `deps` | Dependencies |
| `core` | Core business logic |
| `test` | Test infrastructure |

### When to Use Scope

- **Use scope** when change is localized to one area
- **Omit scope** for broad changes or when area is obvious from description

```
feat(auth): add biometric login        # Scoped - specific area
feat: add user onboarding flow         # No scope - spans multiple areas
```

---

## Breaking Changes

Add an exclamation mark after type/scope to indicate breaking changes:

```
feat!: remove deprecated user API
feat(api)!: change authentication response format
refactor(db)!: rename user table columns
```

Breaking changes should be rare and intentional.

---

## Rules

1. **Single line** - No body, no footer, no attribution
2. **Lowercase after colon** - `feat: add button` not `feat: Add button`
3. **50-72 characters** - Concise but specific
4. **Present tense imperative** - "add" not "added" or "adds"
5. **What + context, not how** - Focus on outcome
6. **No trailing period** - `feat: add login` not `feat: add login.`

### Never Include

- "Generated with Claude"
- "Co-Authored-By"
- Any attribution or footer
- Emojis (unless project convention)

---

## Workflow

### Step 1: Analyze Changes

Run in parallel:

```bash
git status
git diff --staged --stat
git diff --stat
git log -3 --oneline
```

### Step 2: Auto-Stage if Needed

If nothing is staged but changes exist:

```bash
git add -A
```

**Exception:** If user specifies files, only stage those.

### Step 3: Present Summary

```markdown
## Staged Changes

**Files (N):**
- path/to/file.dart (modified)
- path/to/new_file.dart (added)

**Summary:**
- Added new authentication service
- Fixed null check in profile handler

---

**Suggested commit:**
`feat(auth): add email OTP authentication flow`

Reply **"ok"** to commit, or provide your own message.
```

### Step 4: Validate & Commit

**If user says "ok", "yes", "y", "commit":**
- Use suggested message

**If user provides custom message:**
- Validate format: `^(feat|fix|chore|docs|test|refactor|style|perf|ci|build)(\(.+\))?!?: .+$`
- If invalid, show correct format and ask again

**Execute:**

```bash
git commit -m "type(scope): description"
```

**Never use HEREDOC.** Single `-m` flag only.

### Step 5: Confirm

```
Committed: abc1234
Message: feat(auth): add email OTP authentication flow
Files: 3 changed
```

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| No changes | "Nothing to commit. Working tree clean." |
| Nothing staged | Auto-stage with `git add -A`, or ask user |
| Merge conflict | "Resolve conflicts first, then commit." |
| Pre-commit hook fails | Show error, retry. Only suggest `--no-verify` if user confirms |
| Mixed unrelated changes | Suggest splitting into multiple commits |
| Very large changeset | Summarize main changes, suggest splitting if >10 files |

---

## Quick Reference

### Format

```
type(scope): description       # Standard
type(scope)!: description      # Breaking change
type: description              # No scope
```

### Valid Types

`feat` `fix` `refactor` `perf` `test` `docs` `style` `chore` `ci` `build`

### Validation Regex

```regex
^(feat|fix|chore|docs|test|refactor|style|perf|ci|build)(\([a-z0-9-]+\))?!?: .{1,72}$
```
