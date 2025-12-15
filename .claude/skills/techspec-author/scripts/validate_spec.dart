#!/usr/bin/env dart
/// Validates technical specification documents for completeness and AI-readability.
///
/// Usage:
///   dart run .claude/skills/techspec-author/scripts/validate_spec.dart <spec-file>
///
/// Examples:
///   dart run .claude/skills/techspec-author/scripts/validate_spec.dart docs/specs/SPEC-my-package.md
///
/// Exit codes:
///   0 - Validation passed
///   1 - Validation failed (errors found)
///   2 - File not found or invalid arguments

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: validate_spec.dart <spec-file.md>');
    print('');
    print('Example:');
    print('  dart run .claude/skills/techspec-author/scripts/validate_spec.dart docs/specs/SPEC-my-package.md');
    exit(2);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print('Error: File not found: $filePath');
    exit(2);
  }

  final content = file.readAsStringSync();
  final validator = SpecValidator(content, filePath);
  final results = validator.validate();

  _printResults(results);
  exit(results.hasErrors ? 1 : 0);
}

class SpecValidator {
  SpecValidator(this.content, this.filePath);

  final String content;
  final String filePath;

  ValidationResults validate() {
    final results = ValidationResults();

    _checkRequiredSections(results);
    _checkClarificationMarkers(results);
    _checkAcceptanceCriteria(results);
    _checkAmbiguousLanguage(results);
    _checkCodeExamples(results);

    return results;
  }

  void _checkRequiredSections(ValidationResults results) {
    final requiredSections = [
      'Package Overview',
      'Requirements',
      'Technical Constraints',
    ];

    final recommendedSections = [
      'Public API Contract',
      'Testing Requirements',
      'Implementation Tasks',
    ];

    for (final section in requiredSections) {
      if (!_hasSection(section)) {
        results.addError('Missing required section: "$section"');
      }
    }

    for (final section in recommendedSections) {
      if (!_hasSection(section)) {
        results.addWarning('Missing recommended section: "$section"');
      }
    }
  }

  void _checkClarificationMarkers(ValidationResults results) {
    final regex = RegExp(r'\[NEEDS CLARIFICATION:([^\]]+)\]');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final question = match.group(1)?.trim() ?? 'Unknown';
      results.addError('Unresolved clarification: "$question"');
    }
  }

  void _checkAcceptanceCriteria(ValidationResults results) {
    // Check for requirements without acceptance criteria
    final reqRegex = RegExp(r'###\s+REQ-\d+:', multiLine: true);
    final reqMatches = reqRegex.allMatches(content);

    for (final match in reqMatches) {
      final startIndex = match.end;
      final nextSection = content.indexOf(RegExp(r'\n###?\s'), startIndex);
      final endIndex = nextSection == -1 ? content.length : nextSection;
      final reqContent = content.substring(startIndex, endIndex);

      if (!reqContent.contains('GIVEN') || !reqContent.contains('THEN')) {
        final reqId = content.substring(match.start, match.end).trim();
        results.addWarning('$reqId may be missing Given/When/Then acceptance criteria');
      }
    }

    // Check for proper Given/When/Then format
    final givenCount = RegExp(r'GIVEN\s+').allMatches(content).length;
    final whenCount = RegExp(r'WHEN\s+').allMatches(content).length;
    final thenCount = RegExp(r'THEN\s+').allMatches(content).length;

    if (givenCount != thenCount || givenCount != whenCount) {
      results.addWarning(
        'Mismatched Given/When/Then count ($givenCount GIVEN, $whenCount WHEN, $thenCount THEN). '
        'Each acceptance criterion should have all three.',
      );
    }
  }

  void _checkAmbiguousLanguage(ValidationResults results) {
    final ambiguousPatterns = {
      r'\bshould\b': 'should',
      r'\bmight\b': 'might',
      r'\bcould\b': 'could',
      r'\bappropriate\b': 'appropriate',
      r'\bproperly\b': 'properly',
      r'\bcorrectly\b': 'correctly',
      r'\bas needed\b': 'as needed',
      r'\bif necessary\b': 'if necessary',
    };

    for (final entry in ambiguousPatterns.entries) {
      final regex = RegExp(entry.key, caseSensitive: false);
      final matches = regex.allMatches(content);

      if (matches.length > 3) {
        results.addWarning(
          'Potentially ambiguous language: "${entry.value}" appears ${matches.length} times. '
          'Consider using more precise language.',
        );
      }
    }
  }

  void _checkCodeExamples(ValidationResults results) {
    final codeBlockRegex = RegExp(r'```dart\n([\s\S]*?)```');
    final matches = codeBlockRegex.allMatches(content);

    var incompleteCount = 0;
    for (final match in matches) {
      final code = match.group(1) ?? '';

      // Check for partial examples (no import and uses package types)
      final hasPackageTypes = RegExp(r'\b[A-Z][a-zA-Z]+\(').hasMatch(code);
      final hasImport = code.contains('import ');
      final isShortSnippet = code.split('\n').length < 5;

      if (hasPackageTypes && !hasImport && !isShortSnippet) {
        incompleteCount++;
      }
    }

    if (incompleteCount > 0) {
      results.addWarning(
        '$incompleteCount code example(s) may be missing imports. '
        'Complete examples help AI agents implement correctly.',
      );
    }
  }

  bool _hasSection(String sectionName) {
    final regex = RegExp(
      '^##?\\s+.*${RegExp.escape(sectionName)}',
      multiLine: true,
      caseSensitive: false,
    );
    return regex.hasMatch(content);
  }
}

class ValidationResults {
  final List<String> errors = [];
  final List<String> warnings = [];

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => !hasErrors;

  void addError(String message) => errors.add(message);
  void addWarning(String message) => warnings.add(message);
}

void _printResults(ValidationResults results) {
  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║              SPEC VALIDATION RESULTS                        ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  if (results.errors.isNotEmpty) {
    print('ERRORS (${results.errors.length}):');
    for (final error in results.errors) {
      print('  ✗ $error');
    }
    print('');
  }

  if (results.warnings.isNotEmpty) {
    print('WARNINGS (${results.warnings.length}):');
    for (final warning in results.warnings) {
      print('  ⚠ $warning');
    }
    print('');
  }

  if (results.isValid && !results.hasWarnings) {
    print('✓ Spec validation passed with no issues!');
  } else if (results.isValid) {
    print('✓ Spec validation passed with ${results.warnings.length} warning(s).');
  } else {
    print('✗ Spec validation FAILED with ${results.errors.length} error(s).');
  }
  print('');
}
