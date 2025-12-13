# Tracker Templates

Ready-to-use templates for different implementation scenarios.

## Feature Implementation Template

```markdown
# TRACKER: [Feature Name]

## Status: PLANNING

## Overview
[Describe what this feature does and why it's needed]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Tasks

### Phase 1: Foundation
- [ ] [Setup task]
- [ ] [Data model task]
- [ ] [Service/logic task]

### Phase 2: Implementation
- [ ] [Core feature task]
- [ ] [Integration task]

### Phase 3: Testing & Polish
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Manual testing
- [ ] Code review

## Files
- `lib/models/` - Data models
- `lib/services/` - Business logic
- `lib/ui/views/` - UI components

## Dependencies
- [Package or feature dependency]

## Notes
[Design decisions, alternatives considered, relevant links]

## History
- [Date]: Created tracker
```

---

## Bug Fix Template

```markdown
# TRACKER: Fix [Bug Description]

## Status: IN_PROGRESS

## Issue
**Reported**: [Where reported - issue #, user feedback]
**Severity**: [Critical/High/Medium/Low]

## Problem
[Describe the bug behavior]

## Expected Behavior
[What should happen instead]

## Root Cause
[Analysis of why the bug occurs - fill after investigation]

## Tasks
- [ ] Reproduce the issue
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Add regression test
- [ ] Verify fix in dev
- [ ] Test edge cases

## Files
- `lib/path/to/affected_file.dart` - [What's wrong]

## Notes
[Steps to reproduce, related issues, stack traces]
```

---

## Refactoring Template

```markdown
# TRACKER: Refactor [Component/Area]

## Status: PLANNING

## Overview
[What's being refactored and why]

## Goals
- [ ] [Goal 1 - e.g., Improve testability]
- [ ] [Goal 2 - e.g., Reduce coupling]
- [ ] [Goal 3 - e.g., Better error handling]

## Constraints
- Maintain backward compatibility
- No API changes (or document if needed)
- Keep existing tests passing

## Tasks

### Analysis
- [ ] Document current architecture
- [ ] Identify pain points
- [ ] Design new structure

### Implementation
- [ ] [Refactor step 1]
- [ ] [Refactor step 2]
- [ ] [Refactor step 3]

### Validation
- [ ] All existing tests pass
- [ ] Add new tests for refactored code
- [ ] Performance benchmarks (if applicable)

## Before/After

### Before
```
[Current structure or approach]
```

### After
```
[Target structure or approach]
```

## Files
- [Files to modify]

## Notes
[Technical debt context, team discussions]
```

---

## Multi-Phase Project Template

```markdown
# TRACKER: [Project Name]

## Status: IN_PROGRESS

## Overview
[High-level project description]

## Milestones

### Milestone 1: [Name] - [Target]
Status: COMPLETE
- [x] Task 1
- [x] Task 2

### Milestone 2: [Name] - [Target]
Status: IN_PROGRESS
- [x] Task 1
- [ ] Task 2
- [ ] Task 3

### Milestone 3: [Name] - [Target]
Status: PLANNING
- [ ] Task 1
- [ ] Task 2

## Architecture Decisions

### ADR-001: [Decision Title]
**Context**: [Why decision was needed]
**Decision**: [What was decided]
**Consequences**: [Impact of decision]

## Files by Module

### Core
- `lib/core/` - [Description]

### Features
- `lib/features/feature_a/` - [Description]
- `lib/features/feature_b/` - [Description]

## Dependencies
- [External dependencies]
- [Internal module dependencies]

## Risks
| Risk | Mitigation | Status |
|------|------------|--------|
| [Risk 1] | [Plan] | Monitoring |

## History
- [Date]: Project started
- [Date]: Milestone 1 complete
```

---

## Quick Task Template

For smaller, focused work:

```markdown
# TRACKER: [Task Name]

## Status: IN_PROGRESS

## Goal
[Single sentence describing the objective]

## Tasks
- [ ] [Step 1]
- [ ] [Step 2]
- [ ] [Step 3]

## Files
- `path/to/file.dart`

## Done When
- [ ] [Completion criterion]
```

---

## API Integration Template

```markdown
# TRACKER: Integrate [API/Service Name]

## Status: PLANNING

## Overview
[What API is being integrated and why]

## API Details
- **Base URL**: `https://api.example.com/v1`
- **Auth**: [API key / OAuth / etc.]
- **Docs**: [Link to documentation]

## Endpoints to Implement

### GET /resource
- [ ] Create request model
- [ ] Create response model
- [ ] Implement API call
- [ ] Add error handling
- [ ] Write tests

### POST /resource
- [ ] Create request model
- [ ] Create response model
- [ ] Implement API call
- [ ] Add error handling
- [ ] Write tests

## Tasks

### Setup
- [ ] Add HTTP client dependency
- [ ] Create API service class
- [ ] Configure authentication
- [ ] Setup error handling

### Implementation
- [ ] [Endpoint 1]
- [ ] [Endpoint 2]

### Testing
- [ ] Mock API responses
- [ ] Write unit tests
- [ ] Integration tests with sandbox

## Files
- `lib/services/api/example_api_service.dart`
- `lib/models/api/example_models.dart`
- `test/services/example_api_service_test.dart`

## Environment Variables
```
EXAMPLE_API_KEY=
EXAMPLE_API_URL=
```

## Notes
[Rate limits, pagination details, known quirks]
```

---

## Migration Template

```markdown
# TRACKER: Migrate [From] to [To]

## Status: PLANNING

## Overview
[What's being migrated and why]

## Scope
- **Affected**: [Number of files/components]
- **Risk Level**: [Low/Medium/High]
- **Rollback Plan**: [How to revert if needed]

## Pre-Migration Checklist
- [ ] Backup current state
- [ ] Document current behavior
- [ ] Create feature branch
- [ ] Notify team

## Migration Steps
- [ ] [Step 1]
- [ ] [Step 2]
- [ ] [Step 3]

## Post-Migration Checklist
- [ ] All tests passing
- [ ] Manual smoke test
- [ ] Performance comparison
- [ ] Update documentation
- [ ] Remove deprecated code

## Affected Files
[List all files that need changes]

## Breaking Changes
[Document any breaking changes]

## Notes
[Migration gotchas, team coordination]
```
