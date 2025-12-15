# Anthropic GenUI

A Flutter monorepo workspace for Anthropic GenUI packages, managed with [Melos](https://melos.invertase.dev/).

## Project Structure

```
anthropic_genui/
├── melos.yaml                 # Melos configuration
├── pubspec.yaml               # Root pubspec (workspace)
├── analysis_options.yaml      # Shared linting rules
├── packages/
│   ├── anthropic_a2ui/        # Core UI components package
│   └── genui_anthropic/       # GenUI package (depends on anthropic_a2ui)
└── README.md
```

## Packages

| Package | Description |
|---------|-------------|
| [`anthropic_a2ui`](packages/anthropic_a2ui) | Pure Dart package for converting between Claude API responses and A2UI protocol messages. No Flutter dependency - works in apps, CLI tools, servers, and edge functions. |
| [`genui_anthropic`](packages/genui_anthropic) | Flutter `ContentGenerator` implementation for Claude-powered GenUI. Features dual-mode architecture (direct/proxy), streaming, circuit breaker, metrics, and comprehensive error handling. |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Melos CLI

### Install Melos

```bash
dart pub global activate melos
```

### Bootstrap the Project

```bash
melos bootstrap
```

This will install all dependencies and link local packages.

## Available Scripts

| Script | Description |
|--------|-------------|
| `melos bootstrap` | Install dependencies and link packages |
| `melos clean` | Clean all packages |
| `melos run analyze` | Run dart analyze in all packages |
| `melos run format` | Check formatting in all packages |
| `melos run format:fix` | Apply dart format in all packages |
| `melos run test` | Run tests in all packages |
| `melos run test:coverage` | Run tests with coverage |
| `melos run build:runner` | Run build_runner in all packages |
| `melos run get` | Get dependencies for all packages |
| `melos run upgrade` | Upgrade dependencies for all packages |
| `melos run outdated` | Check outdated dependencies |

## Development

### Adding a New Package

1. Create a new directory under `packages/`
2. Add the package configuration to `melos.yaml` if needed
3. Add the package to the workspace in root `pubspec.yaml`
4. Run `melos bootstrap`

### Cross-Package Dependencies

Packages can reference each other using path dependencies:

```yaml
dependencies:
  anthropic_a2ui:
    path: ../anthropic_a2ui
```

Melos will automatically manage these dependencies during bootstrap.

### Running Commands in Specific Packages

```bash
melos exec --scope="anthropic_a2ui" -- flutter test
```

## IDE Configuration

Melos automatically generates IDE configuration files for:
- IntelliJ IDEA / Android Studio
- Visual Studio Code

These are regenerated on each `melos bootstrap`.
