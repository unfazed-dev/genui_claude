// ignore_for_file: avoid_print
/// Server-side example for anthropic_a2ui package.
///
/// This example demonstrates using anthropic_a2ui in server-side contexts:
/// - Dart CLI applications
/// - Server-side Dart (shelf, dart_frog, etc.)
/// - Edge functions (Supabase, Cloudflare Workers)
///
/// The package is pure Dart with zero Flutter dependencies, making it
/// suitable for any Dart runtime environment.
library;

import 'dart:convert';

import 'package:anthropic_a2ui/anthropic_a2ui.dart';

void main() async {
  print('=== anthropic_a2ui Server-Side Example ===\n');

  // 1. Define tool catalog (typically loaded from config)
  print('1. Loading tool catalog...');
  final toolCatalog = _loadToolCatalog();
  print('   Loaded ${toolCatalog.length} tools\n');

  // 2. Generate Claude API request
  print('2. Preparing Claude API request...');
  final request = _prepareClaudeRequest(toolCatalog);
  print('   Request prepared with ${request['tools'].length} tools\n');

  // 3. Process mock response (simulating API call)
  print('3. Processing API response...');
  final response = _simulateClaudeResponse();
  final result = ClaudeA2uiParser.parseMessage(response);

  // 4. Convert to JSON for HTTP response
  print('4. Converting to JSON for HTTP response...');
  final jsonResponse = _convertToHttpResponse(result);
  print('   Response JSON:');
  print('   ${const JsonEncoder.withIndent('  ').convert(jsonResponse)}\n');

  // 5. Demonstrate error handling
  print('5. Demonstrating error handling...');
  _demonstrateErrorHandling(toolCatalog);

  // 6. Demonstrate rate limiting
  print('6. Demonstrating rate limiting...');
  await _demonstrateRateLimiting();

  print('\n=== Example Complete ===');
}

/// Load tool catalog (simulating config file or database load).
List<A2uiToolSchema> _loadToolCatalog() {
  // In production, this might come from:
  // - JSON config file
  // - Database
  // - Environment variables
  // - Remote config service
  return const [
    A2uiToolSchema(
      name: 'begin_rendering',
      description: 'Start a new UI surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string'},
          'parentSurfaceId': {'type': 'string'},
        },
      },
      requiredFields: ['surfaceId'],
    ),
    A2uiToolSchema(
      name: 'surface_update',
      description: 'Update widgets in a surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string'},
          'widgets': {'type': 'array'},
        },
      },
      requiredFields: ['surfaceId', 'widgets'],
    ),
    A2uiToolSchema(
      name: 'data_model_update',
      description: 'Update data bindings',
      inputSchema: {
        'type': 'object',
        'properties': {
          'updates': {'type': 'object'},
        },
      },
      requiredFields: ['updates'],
    ),
    A2uiToolSchema(
      name: 'delete_surface',
      description: 'Remove a UI surface',
      inputSchema: {
        'type': 'object',
        'properties': {
          'surfaceId': {'type': 'string'},
          'cascade': {'type': 'boolean'},
        },
      },
      requiredFields: ['surfaceId'],
    ),
  ];
}

/// Prepare a Claude API request with tools.
Map<String, dynamic> _prepareClaudeRequest(List<A2uiToolSchema> tools) {
  final claudeTools = A2uiToolConverter.toClaudeTools(tools);
  final instructions = A2uiToolConverter.generateToolInstructions(tools);

  return {
    'model': 'claude-sonnet-4-20250514',
    'max_tokens': 4096,
    'system': '''You are a UI generation assistant.
When asked to create UI, use the provided tools.

$instructions''',
    'messages': [
      {
        'role': 'user',
        'content': 'Create a simple login form',
      },
    ],
    'tools': claudeTools,
  };
}

/// Simulate Claude API response.
Map<String, dynamic> _simulateClaudeResponse() {
  return {
    'id': 'msg_server_001',
    'type': 'message',
    'role': 'assistant',
    'content': [
      {
        'type': 'tool_use',
        'id': 'toolu_001',
        'name': 'begin_rendering',
        'input': {
          'surfaceId': 'login-form',
        },
      },
      {
        'type': 'tool_use',
        'id': 'toolu_002',
        'name': 'surface_update',
        'input': {
          'surfaceId': 'login-form',
          'widgets': [
            {
              'type': 'Column',
              'props': {'spacing': 16},
              'children': [
                {
                  'type': 'TextField',
                  'props': {
                    'label': 'Email',
                    'keyboardType': 'email',
                    'binding': 'email',
                  },
                },
                {
                  'type': 'TextField',
                  'props': {
                    'label': 'Password',
                    'obscureText': true,
                    'binding': 'password',
                  },
                },
                {
                  'type': 'Button',
                  'props': {
                    'label': 'Sign In',
                    'onTap': 'submitLogin',
                    'variant': 'primary',
                  },
                },
              ],
            },
          ],
        },
      },
    ],
    'stop_reason': 'end_turn',
  };
}

/// Convert ParseResult to HTTP response format.
Map<String, dynamic> _convertToHttpResponse(ParseResult result) {
  return {
    'success': true,
    'hasToolUse': result.hasToolUse,
    'textContent': result.textContent,
    'messages': result.a2uiMessages.map((m) {
      return {
        'type': m.runtimeType.toString().replaceAll('Data', ''),
        'data': m.toJson(),
      };
    }).toList(),
  };
}

/// Demonstrate error handling patterns.
void _demonstrateErrorHandling(List<A2uiToolSchema> tools) {
  // Validate input before sending to Claude
  final validationResult = A2uiToolConverter.validateToolInput(
    'begin_rendering',
    <String, dynamic>{}, // Missing required surfaceId
    tools,
  );

  if (!validationResult.isValid) {
    print('   Validation failed:');
    for (final error in validationResult.errors) {
      print('   - [${error.code}] ${error.field}: ${error.message}');
    }
  }

  // Handle parse exceptions
  try {
    // Simulate malformed response
    ClaudeA2uiParser.parseMessage({
      'content': [
        {
          'type': 'tool_use',
          'name': 'surface_update',
          'input': {
            'surfaceId': 'test',
            'widgets': 'not-an-array', // Invalid type
          },
        },
      ],
    });
  } on Object catch (e) {
    print('   Parse error caught: $e');
  }
  print('');
}

/// Demonstrate rate limiting for API calls.
Future<void> _demonstrateRateLimiting() async {
  final rateLimiter = RateLimiter();

  // Simulate multiple requests
  for (var i = 0; i < 3; i++) {
    final result = await rateLimiter.execute(() async {
      // Simulated API call
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 'Response $i';
    });
    print('   Request $i: $result');
  }

  // Simulate rate limit response (429 with 2 second retry)
  final retryAfter = RateLimiter.parseRetryAfter('2');
  rateLimiter.recordRateLimit(
    statusCode: 429,
    retryAfter: retryAfter,
  );

  // Check if rate limited
  print('   Is rate limited: ${rateLimiter.isRateLimited}');

  // Clean up
  rateLimiter.dispose();
}
