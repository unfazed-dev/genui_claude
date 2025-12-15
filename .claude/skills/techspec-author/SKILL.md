---
name: techspec-author
description: Technical specification author for Flutter/Dart packages. Creates AI-optimized specs with requirements, acceptance criteria, and implementation contracts. Use when planning new packages, documenting features, or preparing specs for AI code generation.
---

# Technical Specification Author

## Overview

Generate comprehensive technical specifications for Flutter/Dart packages, optimized for AI agents to implement effectively. Follows spec-driven development (SDD) principles where specs define the WHAT and WHY before the HOW.

**Output**: `docs/specs/SPEC-{package-name}.md`

## Workflow Decision Tree

1. **What type of spec is needed?**
   - New package → Full Spec (all phases)
   - New feature → Feature Spec (specify + plan)
   - API design → API Contract Spec
   - Bug fix → Skip (use issue tracker)

2. **What package complexity?**
   - Simple (utilities, models, single-purpose) → Quick Spec Template
   - Standard (widgets, services, multi-file) → Standard Spec Template
   - Complex (plugins, platform channels, monorepo) → Full Spec Template

3. **Auto-detect project constraints**
   - Read `pubspec.yaml` for SDK, dependencies, platforms
   - Read `analysis_options.yaml` for lint rules
   - Check for existing patterns in `lib/` structure

## Auto-Detection Workflow

Before writing specs, extract constraints from existing project:

```dart
// From pubspec.yaml
- name: package_name
- sdk: ^3.0.0
- flutter: ">=3.10.0"  // if Flutter package
- platforms: [android, ios, web, ...]  // if plugin
- dependencies: [list with versions]

// From analysis_options.yaml
- strict-casts: true/false
- strict-inference: true/false
- linter rules in use

// From lib/ structure
- Package type: Pure Dart / Flutter / Plugin
- Export pattern: barrel file / direct exports
- Architecture: flat / layered / feature-based
```

Include auto-detected constraints in spec under "Technical Constraints" section.

## Spec-Driven Development Phases

### Phase 1: Discovery

Gather requirements through questions:

```markdown
## Discovery Questions

### Problem Space
- What problem does this package solve?
- Who are the target users (app developers, package authors, end users)?
- What existing solutions exist? Why create a new one?

### Scope
- What are the must-have features (MVP)?
- What features are explicitly out of scope?
- What are the non-functional requirements (performance, size, compatibility)?

### Constraints
- Minimum SDK versions?
- Required dependencies?
- Platform support requirements?
```

Mark unknowns with `[NEEDS CLARIFICATION: specific question]`.

### Phase 2: Specify (Functional Spec)

Define WHAT the package does, not HOW:

```markdown
## Package Overview

**Name**: package_name
**Description**: One-sentence description of what it does.
**Problem Statement**: The specific problem this solves.
**Target Users**: Who will use this package.

## Requirements

### REQ-001: [Requirement Name]

**User Story**:
As a [user type]
I want [capability]
So that [benefit]

**Acceptance Criteria**:
- GIVEN [initial context]
  WHEN [action performed]
  THEN [expected outcome]

- GIVEN [another context]
  WHEN [different action]
  THEN [different outcome]

**Priority**: Must Have | Should Have | Nice to Have
```

### Phase 3: Plan (Technical Spec)

Define HOW requirements will be implemented:

```markdown
## Public API Contract

### Classes

#### ClassName

```dart
/// Brief description.
class ClassName {
  /// Constructor documentation.
  const ClassName({
    required Type param1,
    Type? param2,
  });

  /// Property documentation.
  final Type property;

  /// Method documentation.
  ///
  /// Returns [ReturnType] when successful.
  /// Throws [ExceptionType] when [condition].
  ReturnType methodName(ParamType param);
}
```

**Input/Output Contract**:
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| param1 | Type | Yes | What it represents |
| param2 | Type | No | Default: value |

**Error Handling**:
| Error | Condition | Recovery |
|-------|-----------|----------|
| ExceptionType | When condition | Suggested handling |

### Dependencies

| Package | Version | Rationale |
|---------|---------|-----------|
| dep_name | ^1.0.0 | Why needed |

### Architecture

[Diagram or description of component relationships]
```

### Phase 4: Tasks (Implementation Breakdown)

Break spec into implementable tasks:

```markdown
## Implementation Tasks

### Task 1: [Task Name] [P]
**Files**: `lib/src/file.dart`
**Implements**: REQ-001
**Complexity**: Low | Medium | High

**Deliverables**:
- [ ] Create class skeleton
- [ ] Implement core logic
- [ ] Add unit tests
- [ ] Add documentation

### Task 2: [Task Name]
**Depends On**: Task 1
**Files**: `lib/src/other.dart`
**Implements**: REQ-002
...

[P] = Parallelizable (no dependencies)
```

## AI Optimization Guidelines

Write specs that AI agents can implement without clarification:

### Do

1. **Self-Contained Sections**: Each section understandable independently
2. **Complete Examples**: Include imports, no partial snippets
3. **Explicit Contracts**: Input types, output types, error conditions
4. **Given/When/Then**: Unambiguous acceptance criteria
5. **Consistent Terminology**: Same term = same concept throughout
6. **Structured Data**: Tables, JSON schemas over prose
7. **Measurable Success**: Testable criteria, not vague goals

### Don't

1. **No Implementation Details in Requirements**: Save for Phase 3
2. **No Ambiguous Language**: Avoid "should", "might", "could"
3. **No Implicit Knowledge**: Assume AI has no project context
4. **No Circular References**: Each section stands alone
5. **No Unresolved Questions**: Mark with `[NEEDS CLARIFICATION]`

### Writing Patterns

**Good Requirement**:
```markdown
### REQ-001: Parse JSON Configuration

As a package user
I want to load configuration from a JSON file
So that I can configure the package without code changes

Acceptance Criteria:
- GIVEN a valid JSON file at path "config.json"
  WHEN ConfigLoader.fromFile("config.json") is called
  THEN returns Config object with parsed values

- GIVEN a JSON file with missing required field "apiKey"
  WHEN ConfigLoader.fromFile is called
  THEN throws ConfigException with message containing "apiKey"
```

**Bad Requirement**:
```markdown
### Configuration
The package should be able to read configuration from files.
It should handle errors appropriately.
```

## Spec Validation Checklist

Before finalizing spec:

- [ ] All `[NEEDS CLARIFICATION]` markers resolved
- [ ] Every requirement has acceptance criteria
- [ ] Acceptance criteria use Given/When/Then format
- [ ] SDK constraints specified
- [ ] Dependencies listed with rationale
- [ ] Test scenarios defined for each requirement
- [ ] No implementation details in requirements section
- [ ] All code examples are complete and runnable
- [ ] Error conditions documented with recovery guidance
- [ ] Task breakdown covers all requirements

## Quick Reference

### Spec File Location
```
project/
└── docs/
    └── specs/
        └── SPEC-{package-name}.md
```

### Spec Document Structure
```markdown
# SPEC: Package Name

## Metadata
- Version: 0.1.0
- Status: Draft | Review | Approved
- Author: [name]
- Date: YYYY-MM-DD

## Package Overview
[Problem, users, type]

## Requirements
[User stories with acceptance criteria]

## Technical Constraints
[Auto-detected + explicit constraints]

## Public API Contract
[Classes, methods, types]

## Testing Requirements
[Test scenarios by type]

## Implementation Tasks
[Ordered task list]

## Open Questions
[Any remaining clarifications needed]
```

### Package Type Indicators

| Indicator | Package Type |
|-----------|--------------|
| `flutter: sdk` dependency | Flutter Package |
| `pluginClass` in pubspec | Flutter Plugin |
| `ffiPlugin` in pubspec | FFI Plugin |
| No Flutter dependencies | Pure Dart Package |

## Resources

- **Templates**: See [references/spec-templates.md](references/spec-templates.md)
- **Flutter/Dart Specifics**: See [references/flutter-package-specs.md](references/flutter-package-specs.md)
- **AI Optimization**: See [references/ai-optimization.md](references/ai-optimization.md)
- **Validation Script**: Run `dart run .claude/skills/techspec-author/scripts/validate_spec.dart docs/specs/SPEC-name.md`
