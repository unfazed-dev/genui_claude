# Tracker File Format Specification

Complete specification for TRACKER-*.md file format.

## File Location

All tracker files are stored in the `docs/trackers/` directory:

```
docs/trackers/TRACKER-[kebab-case-name].md
```

If `docs/trackers/` doesn't exist, create it before generating trackers.

### Naming Convention

| Pattern | Use Case | Example |
|---------|----------|---------|
| `TRACKER-[feature].md` | New feature | `docs/trackers/TRACKER-dark-mode.md` |
| `TRACKER-fix-[issue].md` | Bug fix | `docs/trackers/TRACKER-fix-login-crash.md` |
| `TRACKER-refactor-[area].md` | Refactoring | `docs/trackers/TRACKER-refactor-auth.md` |
| `TRACKER-[issue-id].md` | Issue-linked | `docs/trackers/TRACKER-GH-123.md` |

## Required Sections

### 1. Title Header

```markdown
# TRACKER: [Human-readable Feature Name]
```

The title should:
- Start with `# TRACKER:`
- Use title case
- Be descriptive but concise (5-10 words)

### 2. Status Section

```markdown
## Status: [STATUS_VALUE]
```

Valid status values:

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `PLANNING` | Requirements gathering | Initial creation, defining scope |
| `IN_PROGRESS` | Active development | While implementing |
| `BLOCKED` | Cannot proceed | Waiting on dependency/decision |
| `REVIEW` | Awaiting review | Implementation complete |
| `COMPLETE` | Finished | All tasks done, merged |
| `ABANDONED` | Not continuing | Decided not to implement |

### 3. Overview Section

```markdown
## Overview
[1-3 sentences describing the feature/task]
```

Should answer:
- What is being implemented?
- Why is it needed?
- What's the expected outcome?

### 4. Tasks Section

```markdown
## Tasks
- [ ] Uncompleted task
- [x] Completed task
  - [ ] Nested subtask
```

Task guidelines:
- Use GitHub-flavored markdown checkboxes
- Each task should be completable in one session
- Group related tasks under phase headers
- Indent subtasks with 2 spaces

## Recommended Sections

### Files Section

```markdown
## Files
- `path/to/file.ext` - Description of changes
- `path/to/new_file.ext` - New file (create)
- `path/to/deleted.ext` - To be removed (delete)
```

Use annotations:
- No annotation: File will be modified
- `(create)`: New file to create
- `(delete)`: File to remove
- `(move from X)`: File being renamed/moved

### Dependencies Section

```markdown
## Dependencies
- [x] Feature X must be complete
- [ ] Package Y needs to be installed
- [ ] Team decision on approach needed
```

Track:
- Feature dependencies
- Package requirements
- External blockers
- Required decisions

### Notes Section

```markdown
## Notes
- Decision: Using approach X because Y
- TODO: Remember to update docs
- Link: https://relevant-resource.com
```

Prefix patterns:
- `Decision:` - Architectural/design choices
- `TODO:` - Future considerations
- `Link:` - Relevant resources
- `Warning:` - Potential issues
- `Question:` - Unresolved questions

## Optional Sections

### Acceptance Criteria

```markdown
## Acceptance Criteria
- [ ] User can toggle dark mode
- [ ] Preference persists across sessions
- [ ] All screens respect theme
```

Use for:
- User-facing features
- QA verification
- Definition of "done"

### History Section

```markdown
## History
- 2025-01-15: Created tracker, defined initial scope
- 2025-01-16: Completed Phase 1, discovered edge case X
- 2025-01-17: Blocked on API decision
```

Use for:
- Long-running features
- Context for future sessions
- Team handoffs

### Architecture Section

```markdown
## Architecture

### Component Diagram
```
[ServiceA] --> [RepositoryB] --> [DataSourceC]
```

### Key Classes
- `FeatureService` - Business logic
- `FeatureRepository` - Data access
```

Use for:
- Complex implementations
- Multi-component features
- System design context

## Parsing Rules

For tooling that needs to parse trackers:

### Status Extraction
```regex
^## Status:\s*(PLANNING|IN_PROGRESS|BLOCKED|REVIEW|COMPLETE|ABANDONED)
```

### Task Progress
```regex
- \[([ x])\] (.+)$
```
- `[ ]` = incomplete
- `[x]` = complete

### File Paths
```regex
- `([^`]+)`
```

### Progress Calculation
```
progress = completed_tasks / total_tasks * 100
```

## Best Practices

### Do
- Update status immediately when it changes
- Check tasks as soon as they're done
- Add file paths when you modify them
- Log important decisions in Notes
- Keep task descriptions action-oriented

### Don't
- Combine unrelated features in one tracker
- Create tasks too granular (< 5 min) or too large (> 1 day)
- Forget to update when resuming work
- Leave trackers open after completion
- Duplicate information from other docs

## Example: Well-Structured Tracker

```markdown
# TRACKER: User Profile Image Upload

## Status: IN_PROGRESS

## Overview
Allow users to upload and crop profile images. Images stored in cloud storage with automatic resizing for thumbnails.

## Acceptance Criteria
- [ ] Users can select image from gallery or camera
- [ ] Image can be cropped to square
- [ ] Upload shows progress indicator
- [ ] Thumbnails generated automatically

## Tasks

### Phase 1: Infrastructure
- [x] Add image_picker dependency
- [x] Add image_cropper dependency
- [x] Create ImageUploadService
- [ ] Configure cloud storage bucket

### Phase 2: UI
- [ ] Create ProfileImagePicker widget
- [ ] Add crop screen
- [ ] Implement upload progress UI
- [ ] Add error states

### Phase 3: Backend Integration
- [ ] Create upload endpoint
- [ ] Implement thumbnail generation
- [ ] Update user profile API

### Phase 4: Polish
- [ ] Add loading skeletons
- [ ] Implement retry on failure
- [ ] Write tests
- [ ] Update API documentation

## Files
- `lib/services/image_upload_service.dart` - Upload logic (create)
- `lib/ui/widgets/profile_image_picker.dart` - Picker widget (create)
- `lib/ui/views/crop/crop_view.dart` - Crop screen (create)
- `lib/ui/views/profile/profile_view.dart` - Integration point

## Dependencies
- [x] image_picker: ^1.0.0
- [x] image_cropper: ^5.0.0
- [ ] Cloud storage bucket configured

## Notes
- Decision: Using image_cropper over custom solution for faster delivery
- Decision: Max image size 5MB, resize to 1024px before upload
- TODO: Consider adding compression options in v2
- Link: https://pub.dev/packages/image_picker

## History
- 2025-01-10: Created tracker, researched packages
- 2025-01-11: Phase 1 complete, starting UI work
```
