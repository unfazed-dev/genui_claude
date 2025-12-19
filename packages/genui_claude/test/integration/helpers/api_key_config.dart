import 'dart:io';

/// Handles API key configuration for integration tests.
///
/// API key can be provided via:
/// 1. Dart define: --dart-define=TEST_CLAUDE_API_KEY=...
/// 2. Environment variable: TEST_CLAUDE_API_KEY
class ApiKeyConfig {
  ApiKeyConfig._();

  /// Gets the API key, returns null if not available.
  static String? get apiKey {
    // Check dart-define first (compile-time constant)
    // ignore: do_not_use_environment
    const dartDefineKey = String.fromEnvironment('TEST_CLAUDE_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;

    // Check platform environment (runtime)
    final envKey = Platform.environment['TEST_CLAUDE_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;

    return null;
  }

  /// Whether integration tests should be skipped due to missing API key.
  static bool get shouldSkip => apiKey == null || apiKey!.isEmpty;

  /// Skip message for when API key is not available.
  static const skipMessage = 'Integration tests require TEST_CLAUDE_API_KEY. '
      'Run with: flutter test integration_test/ '
      '--dart-define=TEST_CLAUDE_API_KEY=your-key';
}
