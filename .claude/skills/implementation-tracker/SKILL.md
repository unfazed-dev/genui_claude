---
name: implementation-tracker
description: Feature implementation tracker for Claude-assisted development. Creates and manages TRACKER.md files to track feature progress, task breakdowns, and implementation status. Use when planning features, tracking multi-step implementations, or resuming work on existing features.
---

# Implementation Tracker

Systematic feature tracking for AI-assisted development. Creates structured TRACKER.md files that Claude uses to understand context, track progress, and maintain implementation continuity across sessions.

## Quick Start

Create a tracker for a new feature:

```markdown
# TRACKER: [Feature Name]

## Status: IN_PROGRESS

## Overview
[1-2 sentence description of what's being implemented]

## Tasks
- [ ] Task 1
- [ ] Task 2
- [x] Completed task

## Files
- `path/to/file.dart` - Description of changes

## Notes
Implementation details and decisions
```

## Output Location

**All tracker files are created in `docs/trackers/` directory.**

Before creating a tracker:
1. Check if `docs/trackers/` exists
2. If not, create the directory: `mkdir -p docs/trackers`
3. Then create the tracker file in that location

### Single Tracker (Simple Features)

For simple features with a single tracker file:

```
project-root/
├── docs/
│   └── trackers/
│       ├── TRACKER-feature-a.md
│       ├── TRACKER-bug-fix-123.md
│       └── TRACKER-refactor-api.md
├── lib/
└── ...
```

### Multiple Trackers (Complex Features/Packages)

**When creating 2+ related tracker files, create a subfolder for organization:**

```
project-root/
├── docs/
│   └── trackers/
│       ├── package-name/                    # Subfolder for related trackers
│       │   ├── TRACKER-package-main.md      # Main/overview tracker
│       │   ├── TRACKER-data-models.md       # Component tracker
│       │   ├── TRACKER-core-apis.md         # Component tracker
│       │   └── TRACKER-testing.md           # Testing tracker
│       ├── another-feature/
│       │   ├── TRACKER-feature-main.md
│       │   └── TRACKER-feature-testing.md
│       └── TRACKER-simple-feature.md        # Single tracker stays at root
├── lib/
└── ...
```

**Subfolder naming:** Use kebab-case matching the feature/package name.

**When to use subfolders:**
- Package implementations with multiple components
- Large features spanning multiple phases
- Spec-driven implementations with separate concerns
- Any time you create 2+ related tracker files

## Workflow

### 1. Create Tracker

When starting a new feature:

1. Ensure `docs/trackers/` directory exists (create if missing)
2. Create `docs/trackers/TRACKER-[feature-name].md`
3. Fill in overview and initial task breakdown
4. Mark status as `PLANNING` or `IN_PROGRESS`

### 2. Update During Implementation

As work progresses:

1. Check off completed tasks with `[x]`
2. Add discovered subtasks
3. Update `## Files` section with modified paths
4. Add notes for important decisions

### 3. Complete and Archive

When feature is done:

1. Verify all tasks checked
2. Update status to `COMPLETE`
3. Add completion summary
4. Optionally move to `docs/trackers/completed/` or delete

## Tracker Format

### Status Values

```
PLANNING      - Defining requirements and tasks
IN_PROGRESS   - Active development
BLOCKED       - Waiting on dependency or decision
REVIEW        - Implementation complete, needs review
COMPLETE      - Feature finished and merged
```

### Standard Sections

| Section | Purpose | Required |
|---------|---------|----------|
| Status | Current state | Yes |
| Overview | Feature description | Yes |
| Tasks | Actionable items | Yes |
| Files | Affected paths | Recommended |
| Dependencies | Blockers/requirements | If applicable |
| Notes | Decisions, context | Recommended |
| History | Progress log | Optional |

### Task Syntax

```markdown
## Tasks

### Phase 1: Setup
- [x] Create data models
- [ ] Add repository layer
  - [ ] Subtask A
  - [ ] Subtask B

### Phase 2: Integration
- [ ] Connect to UI
- [ ] Add tests
```

## Commands

### Create New Tracker

When user says "track [feature]" or "create tracker for [feature]":

1. Check if `docs/trackers/` exists, create with `mkdir -p docs/trackers` if missing
2. Analyze feature requirements
3. Break into logical tasks (3-10 items)
4. Identify likely affected files
5. Generate `docs/trackers/TRACKER-[feature-name].md`

### Create Multiple Trackers (Package/Complex Feature)

When user says "create trackers for [package/spec]" or feature requires multiple tracker files:

1. Check if `docs/trackers/` exists, create if missing
2. Create subfolder: `mkdir -p docs/trackers/[feature-name]/`
3. Analyze requirements and identify logical groupings
4. Create main tracker: `docs/trackers/[feature-name]/TRACKER-[feature-name]-main.md`
5. Create component trackers for each major area:
   - Data models tracker
   - Core APIs/logic tracker
   - Testing tracker
   - Other domain-specific trackers
6. Cross-link related trackers in "Related Trackers" section

### Update Tracker

When user says "update tracker" or completes work:

1. Find tracker in `docs/trackers/TRACKER-[feature-name].md`
2. Mark completed tasks
3. Add any new discovered tasks
4. Update notes with decisions made

### Resume from Tracker

When user says "resume [feature]" or "continue work":

1. Read `docs/trackers/TRACKER-[feature-name].md`
2. Identify next unchecked task
3. Review notes for context
4. Continue implementation

## File Naming

All trackers live in `docs/trackers/`:

### Single Tracker Pattern
```
docs/trackers/TRACKER-user-auth.md       # Feature tracker
docs/trackers/TRACKER-fix-login-123.md   # Bug fix tracker
docs/trackers/TRACKER-refactor-api.md    # Refactoring tracker
```

Naming pattern: `TRACKER-[kebab-case-description].md`

### Multiple Tracker Pattern (Subfolders)
```
docs/trackers/a2ui-claude/                       # Package subfolder
├── TRACKER-a2ui-claude-package.md               # Main tracker
├── TRACKER-a2ui-data-models.md                  # Component
├── TRACKER-a2ui-core-apis.md                    # Component
└── TRACKER-a2ui-testing.md                      # Testing

docs/trackers/genui-claude/                      # Another package
├── TRACKER-genui-claude-package.md              # Main tracker
├── TRACKER-genui-content-generator.md           # Component
├── TRACKER-genui-adapters.md                    # Component
└── TRACKER-genui-claude-testing.md              # Testing
```

Subfolder naming: `[kebab-case-feature-name]/`
Main tracker: `TRACKER-[feature-name]-package.md` or `TRACKER-[feature-name]-main.md`
Component trackers: `TRACKER-[component-name].md`

## Best Practices

1. **One tracker per feature** - Don't combine unrelated work
2. **Task granularity** - Each task completable in one session
3. **Update frequently** - Check boxes immediately after completing
4. **Include file paths** - Helps Claude find relevant code
5. **Log decisions** - Notes section captures rationale
6. **Delete when done** - Trackers are temporary artifacts

## Integration with Git

Commit tracker updates with implementation:

```bash
git add docs/trackers/TRACKER-feature.md src/feature/
git commit -m "feat: implement user auth - update tracker"
```

Or exclude trackers from version control:

```bash
# Don't commit trackers (add to .gitignore)
echo "docs/trackers/" >> .gitignore
```

## Templates

See `references/templates.md` for:
- Feature implementation template
- Bug fix template
- Refactoring template
- Multi-phase project template

## Example

```markdown
# TRACKER: Add Dark Mode Toggle

## Status: IN_PROGRESS

## Overview
Add a dark mode toggle to the settings page that persists user preference and applies theme across the app.

## Tasks

### Phase 1: Theme Infrastructure
- [x] Create ThemeService
- [x] Add dark/light theme definitions
- [ ] Implement theme persistence (SharedPreferences)

### Phase 2: UI Integration
- [ ] Add toggle widget to SettingsView
- [ ] Connect toggle to ThemeService
- [ ] Apply theme to MaterialApp

### Phase 3: Polish
- [ ] Add transition animation
- [ ] Test on iOS and Android
- [ ] Update screenshots

## Files
- `lib/services/theme_service.dart` - New service
- `lib/ui/views/settings/settings_view.dart` - Add toggle
- `lib/app/app.dart` - Theme provider setup

## Dependencies
- SharedPreferences package (already installed)

## Notes
- Decision: Using ChangeNotifier pattern for theme state
- User preference key: 'app_theme_mode'
- Default to system theme on first launch
```
