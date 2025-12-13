---
name: doc-coauthoring
description: Documentation workflow toolkit for README, API docs, CHANGELOG, and contributing guidelines. Use when creating project documentation, writing API references, maintaining changelogs, or onboarding contributors.
---

# Documentation Co-authoring

## Workflow Decision Tree

1. **What documentation is needed?**
   - New project → Start with README.md
   - Library/API → Create API documentation
   - Releasing version → Update CHANGELOG.md
   - Open source → Add CONTRIBUTING.md
   - Code samples → Write example documentation

2. **What's the audience?**
   - End users → Focus on usage, examples
   - Developers → Include API details, architecture
   - Contributors → Add setup, guidelines, processes

## README.md

### Structure

```markdown
# Project Name

Brief compelling description (1-2 sentences).

## Features

- Key feature 1
- Key feature 2
- Key feature 3

## Installation

[Installation instructions]

## Quick Start

[Minimal working example]

## Usage

[Common usage patterns]

## Documentation

[Links to detailed docs]

## Contributing

[Link to CONTRIBUTING.md or brief guidelines]

## License

[License info]
```

### Writing Guidelines

1. **Title**: Project name, optionally with tagline
2. **Badges**: Build status, version, license (top, after title)
3. **Description**: What it does, why it exists, who it's for
4. **Installation**: Copy-paste ready commands
5. **Quick Start**: Working example in <30 seconds
6. **Usage**: Progressive complexity, common scenarios first

### README Checklist

- [ ] Can someone understand what this does in 10 seconds?
- [ ] Is installation copy-paste ready?
- [ ] Does quick start actually work?
- [ ] Are code examples tested and current?
- [ ] Is there a clear path to more documentation?

## API Documentation

### Structure for Libraries

```markdown
# API Reference

## Installation

## Quick Start

## Core Classes

### ClassName

Brief description of the class.

#### Constructor

\`\`\`dart
ClassName({required Type param1, Type? param2})
\`\`\`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| param1 | Type | Yes | Description |
| param2 | Type | No | Description (default: value) |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| property1 | Type | Description |

#### Methods

##### methodName

\`\`\`dart
ReturnType methodName(Type param)
\`\`\`

Description of what the method does.

**Parameters:**
- `param` - Description

**Returns:** Description of return value

**Throws:**
- `ExceptionType` - When condition

**Example:**
\`\`\`dart
final result = instance.methodName(value);
\`\`\`

## Enums

### EnumName

| Value | Description |
|-------|-------------|
| value1 | Description |
| value2 | Description |

## Type Definitions

### TypedefName

\`\`\`dart
typedef TypedefName = ReturnType Function(ParamType);
\`\`\`

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| ErrorType | When it occurs | How to fix |
```

### Documentation Comments (DartDoc)

```dart
/// A brief one-line description.
///
/// A longer description that explains the purpose,
/// behavior, and any important details.
///
/// ## Example
///
/// ```dart
/// final widget = MyWidget(
///   title: 'Hello',
///   onTap: () => print('tapped'),
/// );
/// ```
///
/// ## See Also
///
/// - [RelatedClass] for related functionality
/// - [otherMethod] for alternative approach
class MyWidget extends StatelessWidget {
  /// Creates a widget with the given [title].
  ///
  /// The [onTap] callback is invoked when the widget is tapped.
  /// If null, the widget is not interactive.
  const MyWidget({
    required this.title,
    this.onTap,
  });

  /// The text displayed in the widget.
  final String title;

  /// Called when the widget is tapped.
  ///
  /// If null, tap interactions are disabled.
  final VoidCallback? onTap;
}
```

## CHANGELOG.md

### Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New feature description

### Changed
- Change description

### Deprecated
- Deprecation notice

### Removed
- Removal description

### Fixed
- Bug fix description

### Security
- Security fix description

## [1.2.0] - 2024-01-15

### Added
- User authentication with OAuth 2.0 (#123)
- Dark mode support (#145)

### Changed
- Improved error messages for validation failures
- Updated minimum SDK version to 3.0.0

### Fixed
- Memory leak in image processing (#156)
- Incorrect date parsing for ISO 8601 strings (#162)

## [1.1.0] - 2024-01-01

### Added
- Initial public release

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/releases/tag/v1.1.0
```

### Changelog Guidelines

| Category | Use For |
|----------|---------|
| Added | New features |
| Changed | Changes in existing functionality |
| Deprecated | Soon-to-be removed features |
| Removed | Removed features |
| Fixed | Bug fixes |
| Security | Vulnerability fixes |

### Writing Entries

**Good:**
```markdown
- Add user authentication with OAuth 2.0 support (#123)
- Fix memory leak when processing large images (#156)
```

**Bad:**
```markdown
- Updated stuff
- Fixed bug
- Various improvements
```

## CONTRIBUTING.md

### Structure

```markdown
# Contributing to Project Name

Thank you for your interest in contributing!

## Code of Conduct

[Link to CODE_OF_CONDUCT.md or brief statement]

## Getting Started

### Prerequisites

- Requirement 1
- Requirement 2

### Development Setup

\`\`\`bash
# Clone the repository
git clone https://github.com/user/repo.git
cd repo

# Install dependencies
[install command]

# Run tests
[test command]
\`\`\`

## How to Contribute

### Reporting Bugs

1. Check existing issues
2. Create a new issue with:
   - Clear title
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details

### Suggesting Features

1. Check existing issues/discussions
2. Create a feature request with:
   - Problem description
   - Proposed solution
   - Alternatives considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`[test command]`)
5. Commit with clear message
6. Push to your fork
7. Open a Pull Request

## Development Guidelines

### Code Style

[Style guide or linter configuration]

### Commit Messages

Format: `type(scope): description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

### Testing

- All new features must have tests
- Maintain or improve code coverage
- Run full test suite before submitting

## Review Process

1. Automated checks must pass
2. At least one maintainer approval
3. All conversations resolved
4. Squash and merge

## Questions?

- Open a discussion
- Join [community channel]
```

## Example Documentation

### Structure

```markdown
# Examples

## Basic Usage

### Example 1: Simple Case

Description of what this example demonstrates.

\`\`\`dart
// Complete, runnable example
import 'package:my_package/my_package.dart';

void main() {
  final instance = MyClass();
  final result = instance.doSomething();
  print(result); // Output: expected output
}
\`\`\`

**Key Points:**
- Point 1
- Point 2

### Example 2: With Configuration

\`\`\`dart
final instance = MyClass(
  option1: value1,
  option2: value2,
);
\`\`\`

## Advanced Usage

### Example 3: Complex Scenario

[Progressive complexity examples]

## Common Patterns

### Pattern: Error Handling

\`\`\`dart
try {
  await riskyOperation();
} on SpecificException catch (e) {
  // Handle specific error
} catch (e) {
  // Handle general error
}
\`\`\`

## Troubleshooting

### Issue: Common Problem

**Symptom:** Description of what user sees

**Cause:** Why this happens

**Solution:**
\`\`\`dart
// Fixed code
\`\`\`
```

### Example Guidelines

1. **Complete**: Examples should be copy-paste runnable
2. **Focused**: One concept per example
3. **Progressive**: Simple → Complex ordering
4. **Annotated**: Comments explain the "why"
5. **Tested**: All examples verified to work

## Quality Checklist

### Before Publishing

- [ ] Spell check completed
- [ ] All links work
- [ ] Code examples tested
- [ ] Consistent formatting
- [ ] No placeholder text
- [ ] Images have alt text
- [ ] Version numbers current

### Maintenance

- [ ] Review quarterly for accuracy
- [ ] Update with each release
- [ ] Address user feedback
- [ ] Remove deprecated content

## Resources

- **Templates**: See [references/templates.md](references/templates.md)
- **Style Guide**: See [references/style-guide.md](references/style-guide.md)
