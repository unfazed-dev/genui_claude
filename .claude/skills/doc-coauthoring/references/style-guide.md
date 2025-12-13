# Documentation Style Guide

## Writing Principles

### Clarity Over Cleverness

```markdown
<!-- Bad -->
Leverage our cutting-edge paradigm to synergize your workflow.

<!-- Good -->
Use this tool to automate your daily tasks.
```

### Active Voice

```markdown
<!-- Bad -->
The configuration file should be created in the root directory.

<!-- Good -->
Create the configuration file in the root directory.
```

### Second Person (You)

```markdown
<!-- Bad -->
Users can configure the settings by...
The developer should first install...

<!-- Good -->
You can configure the settings by...
First, install the dependencies...
```

### Present Tense

```markdown
<!-- Bad -->
This method will return a list of users.
The function returned an error.

<!-- Good -->
This method returns a list of users.
The function returns an error.
```

## Formatting Standards

### Headings

```markdown
# Document Title (H1) - One per document

## Major Sections (H2)

### Subsections (H3)

#### Minor sections (H4) - Use sparingly
```

- Use sentence case for headings: "Getting started" not "Getting Started"
- Keep headings short and descriptive
- Don't skip heading levels (H1 → H3)

### Code Blocks

Always specify the language:

````markdown
```dart
void main() {
  print('Hello, World!');
}
```

```yaml
dependencies:
  flutter:
    sdk: flutter
```

```bash
flutter pub get
```
````

### Inline Code

Use backticks for:
- File names: `pubspec.yaml`
- Class names: `MyWidget`
- Method names: `setState()`
- Property names: `fontSize`
- Command names: `flutter run`
- Values: `true`, `null`, `42`

```markdown
Call the `initialize()` method before using `MyService`.
```

### Lists

Use unordered lists for items without sequence:

```markdown
Features:
- Fast compilation
- Hot reload
- Cross-platform
```

Use ordered lists for steps or ranked items:

```markdown
Installation:
1. Clone the repository
2. Install dependencies
3. Run the application
```

### Tables

Use tables for structured comparisons:

```markdown
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | `String` | Yes | Unique identifier |
| name | `String` | No | Display name |
```

### Links

Use descriptive link text:

```markdown
<!-- Bad -->
Click [here](url) for more information.
See [this link](url).

<!-- Good -->
See the [installation guide](url) for details.
Read the [API reference](url).
```

### Emphasis

- **Bold** for important terms, UI elements, warnings
- *Italics* for introducing terms, book titles, emphasis
- `Code` for technical terms, values, commands

```markdown
**Important:** Always backup your data before upgrading.

The *repository pattern* separates data access logic.

Set `debug` to `true` to enable logging.
```

## Content Patterns

### Introduction Sections

```markdown
# Project Name

Brief one-sentence description of what this does.

## Overview

2-3 paragraphs explaining:
- What problem this solves
- Who should use it
- Key benefits
```

### Installation Sections

```markdown
## Installation

### Prerequisites

- Dart SDK 3.0+
- Flutter 3.16+

### Quick Install

\`\`\`bash
flutter pub add package_name
\`\`\`

### Manual Install

Add to your `pubspec.yaml`:

\`\`\`yaml
dependencies:
  package_name: ^1.0.0
\`\`\`
```

### Usage Sections

Start with the simplest example:

```markdown
## Usage

### Basic Usage

\`\`\`dart
import 'package:example/example.dart';

void main() {
  final result = doSomething();
  print(result);
}
\`\`\`

### Advanced Usage

\`\`\`dart
// More complex example with configuration
\`\`\`
```

### API Documentation

```markdown
## methodName

\`\`\`dart
ReturnType methodName(Type param1, {Type? param2})
\`\`\`

Brief description of what this method does.

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | `Type` | Yes | What this parameter controls |
| param2 | `Type?` | No | Optional configuration |

### Returns

`ReturnType` - Description of the return value.

### Example

\`\`\`dart
final result = methodName('value');
\`\`\`

### Throws

- `ArgumentError` - When param1 is empty
- `StateError` - When called before initialization
```

### Warning and Note Callouts

```markdown
> **Note:** This feature requires version 2.0 or higher.

> **Warning:** This operation cannot be undone.

> **Tip:** Use keyboard shortcuts for faster navigation.
```

## Grammar and Punctuation

### Oxford Comma

Use the Oxford comma in lists:

```markdown
<!-- Bad -->
Supports iOS, Android and Web.

<!-- Good -->
Supports iOS, Android, and Web.
```

### Contractions

Use contractions for friendlier tone:

```markdown
<!-- Formal -->
You cannot use this method before initialization.
It does not support null values.

<!-- Friendly -->
You can't use this method before initialization.
It doesn't support null values.
```

### Technical Terms

- Define acronyms on first use: "Command Line Interface (CLI)"
- Use consistent terminology throughout
- Prefer common terms over jargon

## Code Examples

### Complete Examples

Examples should be copy-paste ready:

```dart
// Good - Complete, runnable example
import 'package:example/example.dart';

void main() async {
  final client = ApiClient(baseUrl: 'https://api.example.com');
  final users = await client.getUsers();
  print('Found ${users.length} users');
}

// Bad - Incomplete, won't compile
final users = await getUsers(); // Where does getUsers come from?
```

### Progressive Complexity

Start simple, then add complexity:

```markdown
### Basic Example

\`\`\`dart
// Minimal working example
final widget = MyWidget();
\`\`\`

### With Configuration

\`\`\`dart
// Adding common options
final widget = MyWidget(
  color: Colors.blue,
  size: 24,
);
\`\`\`

### Full Example

\`\`\`dart
// Complete real-world usage
final widget = MyWidget(
  color: theme.primaryColor,
  size: 24,
  onTap: () => handleTap(),
  child: Text('Click me'),
);
\`\`\`
```

### Comments in Code

```dart
// Good - Explains why, not what
// Cache the result to avoid repeated API calls
final cachedUsers = await _cache.getOrFetch('users', fetchUsers);

// Bad - States the obvious
// Get users from cache
final cachedUsers = await _cache.getOrFetch('users', fetchUsers);
```

## File Organization

### README Structure

```
README.md
├── Title + badges
├── Brief description
├── Table of contents (for long READMEs)
├── Features
├── Installation
├── Quick start
├── Usage examples
├── API reference (or link)
├── Configuration
├── Contributing
├── License
└── Acknowledgments
```

### Documentation Folder

```
docs/
├── getting-started.md
├── guides/
│   ├── configuration.md
│   ├── authentication.md
│   └── deployment.md
├── api/
│   ├── client.md
│   └── models.md
├── examples/
│   ├── basic.md
│   └── advanced.md
└── troubleshooting.md
```

## Version-Specific Documentation

### Marking Version Requirements

```markdown
## New Feature

> Available since version 2.0

Description of the feature...
```

### Deprecation Notices

```markdown
## oldMethod() (Deprecated)

> **Deprecated:** Use `newMethod()` instead. Will be removed in v3.0.

\`\`\`dart
// Deprecated
oldMethod();

// Use instead
newMethod();
\`\`\`
```

## Accessibility

### Alt Text for Images

```markdown
![Screenshot of the settings panel showing theme options](images/settings.png)
```

### Descriptive Link Text

```markdown
<!-- Bad -->
[Click here](url) for the API docs.

<!-- Good -->
Read the [API documentation](url) for method details.
```

### Semantic Structure

Use proper heading hierarchy for screen readers:

```markdown
# Main Title

## Section 1

### Subsection 1.1

## Section 2
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Click here" links | Use descriptive link text |
| Passive voice | Use active voice |
| Future tense for behavior | Use present tense |
| Unexplained jargon | Define terms or use simpler words |
| Incomplete code examples | Provide runnable examples |
| Missing language in code blocks | Always specify the language |
| Inconsistent formatting | Follow style guide consistently |
| Walls of text | Break into sections with headings |
| No table of contents | Add for documents > 3 sections |
| Outdated examples | Review and update regularly |
