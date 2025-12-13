# Publishing Checklist

## Before First Publish

### Package Metadata

- [ ] `name` follows naming conventions (lowercase, underscores)
- [ ] `description` is 60-180 characters, compelling
- [ ] `version` starts at `0.1.0` or `1.0.0`
- [ ] `repository` points to public repo
- [ ] `homepage` or `documentation` URL set
- [ ] `issue_tracker` URL set
- [ ] `topics` list (1-5 relevant topics)
- [ ] `environment.sdk` constraint is appropriate

### Required Files

- [ ] `README.md` with usage examples
- [ ] `CHANGELOG.md` with initial entry
- [ ] `LICENSE` file (BSD-3, MIT, Apache 2.0)
- [ ] `example/example.dart` demonstrating usage
- [ ] `analysis_options.yaml` with strict lints

### Code Quality

- [ ] `dart format .` passes
- [ ] `dart analyze` has no errors/warnings
- [ ] `dart test` all tests pass
- [ ] `dart doc .` generates without warnings
- [ ] All public APIs have documentation

### Verification

```bash
# Run all checks
dart format --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test
dart doc .
dart pub publish --dry-run
```

## Before Each Release

### Version Update

- [ ] Bump version in `pubspec.yaml`
- [ ] Follow semver (MAJOR.MINOR.PATCH)
- [ ] Update `CHANGELOG.md` with all changes

### Testing

- [ ] All existing tests pass
- [ ] New features have tests
- [ ] Test coverage maintained/improved
- [ ] Manual testing of examples

### Documentation

- [ ] New APIs documented
- [ ] README updated if needed
- [ ] CHANGELOG entry is complete
- [ ] Breaking changes clearly documented

### Final Checks

```bash
# Full verification
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test --coverage=coverage
dart doc .
dart pub publish --dry-run

# Verify package contents
dart pub publish --dry-run 2>&1 | grep -A 100 "Package has"
```

## pub.dev Scoring Factors

### Follow Dart Conventions (30 points)

| Check | Points |
|-------|--------|
| Valid pubspec.yaml | Required |
| Proper package layout | Required |
| No platform-specific code in lib/ | +points |
| Follows Effective Dart | +points |

### Provide Documentation (20 points)

| Check | Points |
|-------|--------|
| README.md exists | +5 |
| README has getting started | +5 |
| API documentation (dartdoc) | +10 |
| Example file | +bonus |

### Support Multiple Platforms (20 points)

| Platform | Points |
|----------|--------|
| Each supported platform | +points |
| All platforms (pure Dart) | +20 |

### Pass Static Analysis (30 points)

| Check | Points |
|-------|--------|
| No errors | Required |
| No warnings | +points |
| No hints | +points |
| Uses latest lints | +bonus |

### Support Up-to-Date Dependencies (20 points)

| Check | Points |
|-------|--------|
| Dependencies up to date | +points |
| SDK constraint current | +points |
| No deprecated packages | +points |

## .pubignore

Exclude files from published package:

```
# Development files
.dart_tool/
.packages
.idea/
*.iml
.vscode/

# Build artifacts
build/
coverage/
doc/api/

# Test files (optional - may want to include)
# test/

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml
Makefile

# Other
*.log
*.tmp
.DS_Store
```

## Common Publishing Errors

### "Package validation failed"

```bash
# Check specific issues
dart pub publish --dry-run
```

Common fixes:
- Add missing `description` in pubspec.yaml
- Ensure `description` < 180 characters
- Add `LICENSE` file
- Create `example/example.dart`

### "Missing documentation"

```dart
// Add to all public classes/methods
/// Brief description.
///
/// More details if needed.
class MyClass {}
```

### "SDK constraint is not valid"

```yaml
# Use caret syntax
environment:
  sdk: ^3.0.0  # Not ">=3.0.0 <4.0.0"
```

### "Package is too large"

- Add files to `.pubignore`
- Remove build artifacts
- Compress/optimize assets
- Maximum size: 100MB (compressed)

### "Authentication error"

```bash
# Re-authenticate
dart pub logout
dart pub login
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/publish.yml
name: Publish to pub.dev

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: dart pub get

      - name: Verify
        run: |
          dart format --set-exit-if-changed .
          dart analyze --fatal-infos
          dart test
          dart pub publish --dry-run

      - name: Publish
        run: dart pub publish --force
        env:
          PUB_CREDENTIALS: ${{ secrets.PUB_CREDENTIALS }}
```

### Getting PUB_CREDENTIALS

```bash
# After `dart pub login`, credentials are stored at:
# Linux/Mac: ~/.config/dart/pub-credentials.json
# Windows: %APPDATA%\dart\pub-credentials.json

# Copy contents to GitHub secret named PUB_CREDENTIALS
cat ~/.config/dart/pub-credentials.json
```

## Post-Publish

- [ ] Verify package appears on pub.dev
- [ ] Check pub.dev score
- [ ] Create GitHub release with tag
- [ ] Announce release (if significant)
- [ ] Monitor issues for problems
