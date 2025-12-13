import 'package:anthropic_a2ui/anthropic_a2ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_anthropic/genui_anthropic.dart';

void main() {
  group('GenUIAnthropic', () {
    test('packageName returns correct value', () {
      const genui = GenUIAnthropic();
      expect(genui.packageName, equals('genui_anthropic'));
    });

    test('version returns correct value', () {
      const genui = GenUIAnthropic();
      expect(genui.version, equals('0.1.0'));
    });

    test('a2ui returns AnthropicA2UI instance', () {
      const genui = GenUIAnthropic();
      expect(genui.a2ui, isA<AnthropicA2UI>());
      expect(genui.a2ui.packageName, equals('anthropic_a2ui'));
    });
  });
}
