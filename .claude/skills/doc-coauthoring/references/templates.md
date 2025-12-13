# Documentation Templates

## README Templates

### Minimal README

```markdown
# project-name

Brief description of what this project does.

## Installation

\`\`\`bash
[install command]
\`\`\`

## Usage

\`\`\`[language]
[minimal example]
\`\`\`

## License

[License type]
```

### Library README

```markdown
# Library Name

[![pub package](https://img.shields.io/pub/v/package_name.svg)](https://pub.dev/packages/package_name)
[![build](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)](https://github.com/user/repo/actions)

Brief, compelling description of what the library does and why someone would use it.

## Features

- **Feature 1** - Brief description
- **Feature 2** - Brief description
- **Feature 3** - Brief description

## Getting Started

### Installation

Add to your `pubspec.yaml`:

\`\`\`yaml
dependencies:
  package_name: ^1.0.0
\`\`\`

### Quick Start

\`\`\`dart
import 'package:package_name/package_name.dart';

void main() {
  // Minimal working example
  final result = doSomething();
  print(result);
}
\`\`\`

## Usage

### Basic Usage

\`\`\`dart
// Example with explanation
\`\`\`

### Advanced Usage

\`\`\`dart
// More complex example
\`\`\`

## API Reference

See the [API documentation](https://pub.dev/documentation/package_name/latest/).

## Examples

Check out the [example](example/) directory for complete examples.

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

### Application README

```markdown
# App Name

Brief description of the application.

## Screenshots

| Home | Details | Settings |
|------|---------|----------|
| ![Home](docs/screenshots/home.png) | ![Details](docs/screenshots/details.png) | ![Settings](docs/screenshots/settings.png) |

## Features

- Feature 1
- Feature 2
- Feature 3

## Requirements

- Requirement 1 (version X.X+)
- Requirement 2

## Installation

### From Release

Download the latest release from [Releases](https://github.com/user/repo/releases).

### From Source

\`\`\`bash
git clone https://github.com/user/repo.git
cd repo
[build commands]
\`\`\`

## Configuration

Create a `.env` file or set environment variables:

\`\`\`bash
API_KEY=your_api_key
DEBUG=false
\`\`\`

## Usage

\`\`\`bash
[run command]
\`\`\`

## Development

### Setup

\`\`\`bash
[setup commands]
\`\`\`

### Running Tests

\`\`\`bash
[test command]
\`\`\`

## Architecture

Brief description of architecture or link to documentation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[License type] - see [LICENSE](LICENSE).

## Acknowledgments

- Acknowledgment 1
- Acknowledgment 2
```

### CLI Tool README

```markdown
# tool-name

A command-line tool for [purpose].

## Installation

\`\`\`bash
# Using pub
dart pub global activate tool_name

# Or download binary
curl -L https://github.com/user/repo/releases/latest/download/tool-name > /usr/local/bin/tool-name
chmod +x /usr/local/bin/tool-name
\`\`\`

## Usage

\`\`\`bash
tool-name [command] [options]
\`\`\`

### Commands

| Command | Description |
|---------|-------------|
| `init` | Initialize a new project |
| `build` | Build the project |
| `run` | Run the application |

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help |
| `--version` | `-v` | Show version |
| `--verbose` | | Enable verbose output |

### Examples

\`\`\`bash
# Initialize a new project
tool-name init my-project

# Build with options
tool-name build --release --output ./dist

# Run in development mode
tool-name run --dev
\`\`\`

## Configuration

Create `tool-name.yaml` in your project root:

\`\`\`yaml
option1: value1
option2: value2
\`\`\`

## License

[License type]
```

## API Documentation Templates

### Class Documentation

```markdown
## ClassName

Brief description of the class purpose.

### Overview

Detailed explanation of what this class does, when to use it,
and any important concepts.

### Inheritance

\`\`\`
Object
  └── ParentClass
        └── ClassName
\`\`\`

### Constructors

#### ClassName()

Creates a new instance with default values.

\`\`\`dart
ClassName()
\`\`\`

#### ClassName.named()

Creates a new instance with custom configuration.

\`\`\`dart
ClassName.named({
  required Type param1,
  Type param2 = defaultValue,
})
\`\`\`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| param1 | `Type` | Yes | - | Description |
| param2 | `Type` | No | `defaultValue` | Description |

### Properties

#### property1

\`\`\`dart
final Type property1
\`\`\`

Description of the property.

#### property2

\`\`\`dart
Type get property2
set property2(Type value)
\`\`\`

Description of the getter/setter.

### Methods

#### method1()

\`\`\`dart
ReturnType method1()
\`\`\`

Description of what the method does.

**Returns:** Description of return value.

**Example:**

\`\`\`dart
final instance = ClassName();
final result = instance.method1();
\`\`\`

#### method2()

\`\`\`dart
Future<ReturnType> method2(
  Type param1, {
  Type? param2,
})
\`\`\`

Description of the async method.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | `Type` | Yes | Description |
| param2 | `Type?` | No | Description |

**Returns:** `Future<ReturnType>` - Description.

**Throws:**

| Exception | Condition |
|-----------|-----------|
| `ExceptionType` | When condition occurs |

**Example:**

\`\`\`dart
try {
  final result = await instance.method2(value);
  print(result);
} on ExceptionType catch (e) {
  print('Error: $e');
}
\`\`\`

### Static Methods

#### staticMethod()

\`\`\`dart
static ReturnType staticMethod(Type param)
\`\`\`

Description.

### Operators

#### operator ==

\`\`\`dart
bool operator ==(Object other)
\`\`\`

Equality comparison based on [specific fields].

### See Also

- [RelatedClass] - For related functionality
- [OtherClass.method] - Alternative approach
```

### Function Documentation

```markdown
## functionName

\`\`\`dart
ReturnType functionName<T>(
  Type param1,
  Type param2, {
  Type? optionalParam,
})
\`\`\`

Brief description of what the function does.

### Type Parameters

| Parameter | Constraint | Description |
|-----------|------------|-------------|
| T | `extends Base` | Description |

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | `Type` | Yes | Description |
| param2 | `Type` | Yes | Description |
| optionalParam | `Type?` | No | Description |

### Returns

`ReturnType` - Description of the return value.

### Throws

| Exception | Condition |
|-----------|-----------|
| `ArgumentError` | When param1 is invalid |
| `StateError` | When called in wrong state |

### Example

\`\`\`dart
final result = functionName<String>(
  value1,
  value2,
  optionalParam: value3,
);
\`\`\`

### Notes

- Important note 1
- Important note 2
```

## CONTRIBUTING Template

```markdown
# Contributing to [Project Name]

First off, thank you for considering contributing to [Project Name]! It's people like you that make [Project Name] such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Style Guidelines](#style-guidelines)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- [Prerequisite 1] (version X.X or higher)
- [Prerequisite 2]

### Local Development

1. Fork the repository
2. Clone your fork:
   \`\`\`bash
   git clone https://github.com/YOUR_USERNAME/[repo].git
   cd [repo]
   \`\`\`
3. Install dependencies:
   \`\`\`bash
   [install command]
   \`\`\`
4. Create a branch:
   \`\`\`bash
   git checkout -b feature/your-feature-name
   \`\`\`

### Running Tests

\`\`\`bash
[test command]
\`\`\`

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check [existing issues](link) to avoid duplicates.

When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs what actually happened
- **Environment details** (OS, version, etc.)
- **Screenshots** if applicable
- **Code samples** that reproduce the issue

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title** describing the suggestion
- **Detailed description** of the proposed functionality
- **Use case** explaining why this would be useful
- **Possible implementation** if you have ideas

### Pull Requests

1. **Follow the style guidelines** below
2. **Include tests** for new functionality
3. **Update documentation** as needed
4. **Write clear commit messages** following our conventions
5. **Link related issues** in the PR description

#### PR Checklist

- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Commit messages follow conventions
- [ ] PR description explains changes

## Style Guidelines

### Code Style

[Language-specific style guide or reference to config file]

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

\`\`\`
type(scope): subject

body

footer
\`\`\`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

**Examples:**
\`\`\`
feat(auth): add OAuth2 support

Implements OAuth2 authentication flow with support for
Google and GitHub providers.

Closes #123
\`\`\`

### Documentation

- Use clear, concise language
- Include code examples where helpful
- Keep API documentation in sync with code

## Community

- [Discord/Slack channel]
- [Discussion forum]
- [Twitter/Social media]

## Recognition

Contributors are recognized in [CONTRIBUTORS.md](CONTRIBUTORS.md) and release notes.

Thank you for contributing!
```

## CHANGELOG Entry Templates

### Feature Entry
```markdown
### Added
- Add [feature name] for [use case] (#PR)
  - Sub-feature 1
  - Sub-feature 2
```

### Bug Fix Entry
```markdown
### Fixed
- Fix [issue description] when [condition] (#PR)
```

### Breaking Change Entry
```markdown
### Changed
- **BREAKING**: Rename `oldMethod` to `newMethod` (#PR)
  - Migration: Replace all calls to `oldMethod()` with `newMethod()`
```

### Deprecation Entry
```markdown
### Deprecated
- Deprecate `oldClass` in favor of `newClass` (#PR)
  - Will be removed in v3.0.0
  - Migration guide: [link]
```
