# Spec Templates

Copy and adapt these templates for different specification needs.

## Full Spec Template (Complex Packages)

Use for: Flutter plugins, multi-module packages, packages with platform channels.

```markdown
# SPEC: {Package Name}

## Metadata

| Field | Value |
|-------|-------|
| Version | 0.1.0 |
| Status | Draft |
| Author | {name} |
| Created | YYYY-MM-DD |
| Updated | YYYY-MM-DD |

---

## Package Overview

### Problem Statement

{Describe the specific problem this package solves. Be concrete.}

### Target Users

| User Type | Use Case |
|-----------|----------|
| {type} | {how they use it} |

### Package Type

- [ ] Pure Dart Package
- [ ] Flutter Package
- [ ] Flutter Plugin
- [ ] FFI Plugin

### Scope

**In Scope**:
- {feature 1}
- {feature 2}

**Out of Scope**:
- {explicitly excluded feature}

---

## Requirements

### REQ-001: {Requirement Name}

**Priority**: Must Have

**User Story**:
As a {user type}
I want {capability}
So that {benefit}

**Acceptance Criteria**:

| ID | Given | When | Then |
|----|-------|------|------|
| AC-001-1 | {context} | {action} | {result} |
| AC-001-2 | {context} | {action} | {result} |

**Notes**: {any clarifications}

---

### REQ-002: {Requirement Name}

**Priority**: Should Have

**User Story**:
As a {user type}
I want {capability}
So that {benefit}

**Acceptance Criteria**:

| ID | Given | When | Then |
|----|-------|------|------|
| AC-002-1 | {context} | {action} | {result} |

---

## Technical Constraints

### SDK & Dependencies

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Dart SDK | ^3.0.0 | {why} |
| Flutter SDK | >=3.10.0 | {why} |
| {dependency} | ^{version} | {why needed} |

### Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android | Yes/No | Min SDK: {version} |
| iOS | Yes/No | Min iOS: {version} |
| Web | Yes/No | {limitations} |
| macOS | Yes/No | |
| Windows | Yes/No | |
| Linux | Yes/No | |

### Code Quality

| Rule | Value |
|------|-------|
| strict-casts | true |
| strict-inference | true |
| Test coverage target | {percentage}% |

---

## Public API Contract

### Core Classes

#### {ClassName}

```dart
/// {Brief description}
///
/// {@example}
/// final instance = ClassName(param: value);
/// final result = instance.method();
/// {@end-example}
class ClassName {
  /// Creates a [ClassName] with the given [param].
  const ClassName({
    required this.param,
    this.optional,
  });

  /// {Property description}
  final Type param;

  /// {Property description}. Defaults to {value}.
  final Type? optional;

  /// {Method description}
  ///
  /// Returns {what} when {condition}.
  /// Throws [ExceptionType] when {error condition}.
  ReturnType methodName(ParamType input);
}
```

**Constructor Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| param | Type | Yes | - | {description} |
| optional | Type? | No | null | {description} |

**Methods**:

| Method | Returns | Throws | Description |
|--------|---------|--------|-------------|
| methodName | ReturnType | ExceptionType | {description} |

---

### Exceptions

#### {ExceptionName}

```dart
/// Thrown when {condition}.
class ExceptionName implements Exception {
  const ExceptionName(this.message, {this.code});

  final String message;
  final int? code;
}
```

| Property | Type | Description |
|----------|------|-------------|
| message | String | {what it contains} |
| code | int? | {error code meaning} |

---

### Enums

#### {EnumName}

```dart
/// {Description of what this enum represents}
enum EnumName {
  /// {value1 description}
  value1,

  /// {value2 description}
  value2,
}
```

| Value | Description | Use When |
|-------|-------------|----------|
| value1 | {description} | {condition} |
| value2 | {description} | {condition} |

---

## Testing Requirements

### Unit Tests

| Requirement | Test Scenarios |
|-------------|----------------|
| REQ-001 | - Happy path: {scenario}<br>- Error case: {scenario}<br>- Edge case: {scenario} |
| REQ-002 | - {scenarios} |

### Integration Tests

| Scenario | Components | Expected Behavior |
|----------|------------|-------------------|
| {name} | {components} | {behavior} |

### Widget Tests (if Flutter)

| Widget | Test Scenarios |
|--------|----------------|
| {WidgetName} | - Renders correctly<br>- Responds to interaction<br>- Handles error state |

---

## Implementation Tasks

### Phase 1: Core Foundation

#### Task 1.1: Project Setup [P]
**Implements**: Infrastructure
**Files**: `pubspec.yaml`, `analysis_options.yaml`, `lib/{name}.dart`
**Complexity**: Low

- [ ] Create package structure
- [ ] Configure pubspec.yaml with dependencies
- [ ] Set up analysis_options.yaml
- [ ] Create main export file

#### Task 1.2: Core Models [P]
**Implements**: REQ-001
**Files**: `lib/src/models/`
**Complexity**: Medium

- [ ] Create model classes
- [ ] Add JSON serialization (if needed)
- [ ] Write unit tests
- [ ] Add documentation

### Phase 2: Main Features

#### Task 2.1: {Feature Name}
**Depends On**: Task 1.1, Task 1.2
**Implements**: REQ-001, REQ-002
**Files**: `lib/src/{feature}/`
**Complexity**: High

- [ ] Implement core logic
- [ ] Add error handling
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Add documentation

### Phase 3: Polish

#### Task 3.1: Documentation
**Depends On**: All previous tasks
**Files**: `README.md`, `CHANGELOG.md`, `example/`
**Complexity**: Low

- [ ] Write README with examples
- [ ] Add CHANGELOG entry
- [ ] Create example app/script
- [ ] Generate API docs

---

## Open Questions

| ID | Question | Status | Resolution |
|----|----------|--------|------------|
| Q-001 | {question} | Open/Resolved | {answer if resolved} |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | YYYY-MM-DD | {name} | Initial draft |
```

---

## Quick Spec Template (Simple Packages)

Use for: Utilities, single-purpose packages, small libraries.

```markdown
# SPEC: {Package Name}

**Status**: Draft | **Version**: 0.1.0 | **Date**: YYYY-MM-DD

## Overview

**Problem**: {one sentence}
**Solution**: {one sentence}
**Users**: {target audience}

## Requirements

### REQ-001: {Core Feature}

As a developer, I want {capability} so that {benefit}.

**Acceptance**:
- GIVEN {context} WHEN {action} THEN {result}
- GIVEN {context} WHEN {action} THEN {result}

## API Contract

```dart
/// {Description}
class PackageName {
  /// {Method description}
  ReturnType method(ParamType param);
}
```

## Constraints

- Dart SDK: ^3.0.0
- Dependencies: {list or "none"}
- Platforms: {all | specific list}

## Tasks

1. [ ] Create package structure [P]
2. [ ] Implement core class [P]
3. [ ] Write unit tests
4. [ ] Add documentation
5. [ ] Create example
```

---

## Feature Addition Template

Use for: Adding features to existing packages.

```markdown
# SPEC: {Feature Name} for {Package Name}

**Status**: Draft | **Version**: {package version + 1} | **Date**: YYYY-MM-DD

## Context

**Package**: {package name}
**Current Version**: {version}
**Feature Request**: {link to issue or description}

## Feature Overview

**Problem**: {what users can't do now}
**Solution**: {what this feature enables}
**Impact**: {what existing code is affected}

## Requirements

### REQ-F01: {Feature Requirement}

As a {user type}, I want {capability} so that {benefit}.

**Acceptance**:
- GIVEN {context} WHEN {action} THEN {result}

## API Changes

### New APIs

```dart
/// {New class or method}
extension NewFeature on ExistingClass {
  ReturnType newMethod(ParamType param);
}
```

### Modified APIs

| Current | Proposed | Breaking? |
|---------|----------|-----------|
| `method()` | `method({Type? newParam})` | No |

### Deprecated APIs

| API | Replacement | Remove In |
|-----|-------------|-----------|
| `oldMethod()` | `newMethod()` | v{next major} |

## Migration Guide

```dart
// Before
final result = instance.oldMethod();

// After
final result = instance.newMethod();
```

## Tasks

1. [ ] Add new API surface
2. [ ] Update existing implementation
3. [ ] Add migration deprecation warnings
4. [ ] Write tests for new feature
5. [ ] Update tests for modified behavior
6. [ ] Update documentation
7. [ ] Add CHANGELOG entry
```

---

## API Contract Template

Use for: Documenting public API surface only.

```markdown
# API Contract: {Package Name}

**Version**: {version} | **Date**: YYYY-MM-DD

## Public Exports

```dart
// lib/{package_name}.dart
export 'src/class_a.dart';
export 'src/class_b.dart' show ClassB, TypedefB;
export 'src/exceptions.dart';
```

## Classes

### {ClassName}

**Purpose**: {one sentence}

```dart
class ClassName {
  const ClassName({required Type param});

  final Type param;

  ReturnType method(ParamType input);
}
```

| Member | Type | Description |
|--------|------|-------------|
| `param` | `Type` | {description} |
| `method()` | `ReturnType Function(ParamType)` | {description} |

**Throws**: `ExceptionType` when {condition}

---

## Type Definitions

```dart
typedef CallbackType = void Function(ParamType param);
typedef ResultType = Either<ErrorType, SuccessType>;
```

## Constants

```dart
const defaultTimeout = Duration(seconds: 30);
const maxRetries = 3;
```

## Exceptions

| Exception | Thrown When | Contains |
|-----------|-------------|----------|
| `PackageException` | {condition} | `message`, `code` |

## Extension Methods

```dart
extension StringX on String {
  /// {description}
  String transform();
}
```
```
