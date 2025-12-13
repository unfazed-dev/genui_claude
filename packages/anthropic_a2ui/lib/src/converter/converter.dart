/// Tool conversion utilities for A2UI to Claude API format.
///
/// This module exports:
/// - [A2uiToolConverter] - Main converter class
/// - Schema mapping utilities
library;

import 'package:anthropic_a2ui/anthropic_a2ui.dart' show A2uiToolConverter;
import 'package:anthropic_a2ui/src/converter/converter.dart' show A2uiToolConverter;
import 'package:anthropic_a2ui/src/converter/tool_converter.dart' show A2uiToolConverter;

export 'schema_mapper.dart';
export 'tool_converter.dart';
