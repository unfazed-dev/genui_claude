import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnthropicA2UI', () {
    test('packageName returns correct value', () {
      const a2ui = AnthropicA2UI();
      expect(a2ui.packageName, equals('anthropic_a2ui'));
    });

    test('version returns correct value', () {
      const a2ui = AnthropicA2UI();
      expect(a2ui.version, equals('0.1.0'));
    });
  });
}
