#!/usr/bin/env dart
/// Proxy Endpoint Tester for GenUI Anthropic
///
/// Tests deployed Supabase edge functions or other backend proxies
/// to verify they're correctly configured for GenUI Anthropic.
///
/// Usage:
///   dart run .claude/skills/genui-anthropic/scripts/test_proxy_endpoint.dart <endpoint_url>
///
/// Options:
///   --auth=<token>     Authorization token (Bearer token)
///   --timeout=<ms>     Request timeout in milliseconds (default: 30000)
///   --verbose          Show detailed request/response info

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Test result status
enum TestStatus { pass, fail, skip, warning }

/// Individual test result
class TestResult {
  final String name;
  final TestStatus status;
  final String? message;
  final Duration? duration;

  TestResult({
    required this.name,
    required this.status,
    this.message,
    this.duration,
  });

  String get statusIcon {
    switch (status) {
      case TestStatus.pass:
        return '✓';
      case TestStatus.fail:
        return '✗';
      case TestStatus.skip:
        return '○';
      case TestStatus.warning:
        return '⚠';
    }
  }
}

/// Proxy endpoint tester
class ProxyTester {
  final Uri endpoint;
  final String? authToken;
  final Duration timeout;
  final bool verbose;
  final HttpClient _client = HttpClient();

  ProxyTester({
    required this.endpoint,
    this.authToken,
    this.timeout = const Duration(seconds: 30),
    this.verbose = false,
  });

  /// Run all tests
  Future<List<TestResult>> runAllTests() async {
    final results = <TestResult>[];

    results.add(await testConnection());
    results.add(await testCorsPrelight());
    results.add(await testAuthRequired());
    results.add(await testValidRequest());
    results.add(await testInvalidRequest());

    return results;
  }

  /// Test basic connectivity
  Future<TestResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.headUrl(endpoint).timeout(timeout);
      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      if (response.statusCode < 500) {
        return TestResult(
          name: 'Connection',
          status: TestStatus.pass,
          message: 'Endpoint reachable (${response.statusCode})',
          duration: stopwatch.elapsed,
        );
      } else {
        return TestResult(
          name: 'Connection',
          status: TestStatus.fail,
          message: 'Server error: ${response.statusCode}',
          duration: stopwatch.elapsed,
        );
      }
    } on TimeoutException {
      return TestResult(
        name: 'Connection',
        status: TestStatus.fail,
        message: 'Connection timeout after ${timeout.inSeconds}s',
      );
    } catch (e) {
      return TestResult(
        name: 'Connection',
        status: TestStatus.fail,
        message: 'Connection failed: $e',
      );
    }
  }

  /// Test CORS preflight
  Future<TestResult> testCorsPrelight() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.openUrl('OPTIONS', endpoint).timeout(timeout);
      request.headers.set('Origin', 'https://example.com');
      request.headers.set('Access-Control-Request-Method', 'POST');
      request.headers.set('Access-Control-Request-Headers', 'authorization, content-type');

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      final allowOrigin = response.headers.value('Access-Control-Allow-Origin');
      final allowHeaders = response.headers.value('Access-Control-Allow-Headers');

      if (verbose) {
        print('  CORS headers:');
        print('    Allow-Origin: $allowOrigin');
        print('    Allow-Headers: $allowHeaders');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (allowOrigin != null) {
          return TestResult(
            name: 'CORS Preflight',
            status: TestStatus.pass,
            message: 'CORS configured correctly',
            duration: stopwatch.elapsed,
          );
        } else {
          return TestResult(
            name: 'CORS Preflight',
            status: TestStatus.warning,
            message: 'Missing Access-Control-Allow-Origin header',
            duration: stopwatch.elapsed,
          );
        }
      } else {
        return TestResult(
          name: 'CORS Preflight',
          status: TestStatus.fail,
          message: 'Unexpected status: ${response.statusCode}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      return TestResult(
        name: 'CORS Preflight',
        status: TestStatus.fail,
        message: 'CORS test failed: $e',
      );
    }
  }

  /// Test that auth is required
  Future<TestResult> testAuthRequired() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.postUrl(endpoint).timeout(timeout);
      request.headers.set('Content-Type', 'application/json');
      // Intentionally no auth header

      request.write(jsonEncode({
        'messages': [
          {'role': 'user', 'content': 'test'}
        ],
        'tools': [],
        'systemPrompt': 'test',
      }));

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      if (response.statusCode == 401) {
        return TestResult(
          name: 'Auth Required',
          status: TestStatus.pass,
          message: 'Correctly requires authentication',
          duration: stopwatch.elapsed,
        );
      } else if (response.statusCode == 200) {
        return TestResult(
          name: 'Auth Required',
          status: TestStatus.warning,
          message: 'Endpoint accepts unauthenticated requests',
          duration: stopwatch.elapsed,
        );
      } else {
        return TestResult(
          name: 'Auth Required',
          status: TestStatus.warning,
          message: 'Unexpected status without auth: ${response.statusCode}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      return TestResult(
        name: 'Auth Required',
        status: TestStatus.fail,
        message: 'Auth test failed: $e',
      );
    }
  }

  /// Test valid request processing
  Future<TestResult> testValidRequest() async {
    if (authToken == null) {
      return TestResult(
        name: 'Valid Request',
        status: TestStatus.skip,
        message: 'Skipped (no auth token provided)',
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.postUrl(endpoint).timeout(timeout);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $authToken');

      final body = {
        'messages': [
          {'role': 'user', 'content': 'Say "test successful" and nothing else.'}
        ],
        'tools': [],
        'systemPrompt': 'You are a test assistant. Respond with exactly what is asked.',
        'maxTokens': 50,
      };

      if (verbose) {
        print('  Request body:');
        print('    ${jsonEncode(body)}');
      }

      request.write(jsonEncode(body));

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      if (verbose) {
        print('  Response status: ${response.statusCode}');
        print('  Content-Type: ${response.headers.contentType}');
      }

      if (response.statusCode == 200) {
        // Check if it's streaming
        final contentType = response.headers.contentType?.toString() ?? '';
        final isStreaming = contentType.contains('event-stream') ||
            contentType.contains('text/plain') ||
            contentType.contains('application/json');

        if (isStreaming) {
          // Try to read first event
          final firstChunk = await response.transform(utf8.decoder).first.timeout(
                Duration(seconds: 10),
                onTimeout: () => '',
              );

          if (verbose) {
            print('  First chunk: ${firstChunk.substring(0, firstChunk.length.clamp(0, 200))}...');
          }

          if (firstChunk.isNotEmpty) {
            return TestResult(
              name: 'Valid Request',
              status: TestStatus.pass,
              message: 'Streaming response received',
              duration: stopwatch.elapsed,
            );
          } else {
            return TestResult(
              name: 'Valid Request',
              status: TestStatus.warning,
              message: 'Empty response received',
              duration: stopwatch.elapsed,
            );
          }
        } else {
          return TestResult(
            name: 'Valid Request',
            status: TestStatus.warning,
            message: 'Response not streaming: $contentType',
            duration: stopwatch.elapsed,
          );
        }
      } else {
        final body = await response.transform(utf8.decoder).join();
        return TestResult(
          name: 'Valid Request',
          status: TestStatus.fail,
          message: 'Request failed: ${response.statusCode} - ${body.substring(0, body.length.clamp(0, 100))}',
          duration: stopwatch.elapsed,
        );
      }
    } on TimeoutException {
      return TestResult(
        name: 'Valid Request',
        status: TestStatus.fail,
        message: 'Request timeout',
      );
    } catch (e) {
      return TestResult(
        name: 'Valid Request',
        status: TestStatus.fail,
        message: 'Request failed: $e',
      );
    }
  }

  /// Test invalid request handling
  Future<TestResult> testInvalidRequest() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.postUrl(endpoint).timeout(timeout);
      request.headers.set('Content-Type', 'application/json');
      if (authToken != null) {
        request.headers.set('Authorization', 'Bearer $authToken');
      }

      // Send invalid request (missing required fields)
      request.write(jsonEncode({'invalid': 'data'}));

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      if (response.statusCode == 400) {
        return TestResult(
          name: 'Invalid Request',
          status: TestStatus.pass,
          message: 'Correctly rejects invalid requests',
          duration: stopwatch.elapsed,
        );
      } else if (response.statusCode == 401) {
        return TestResult(
          name: 'Invalid Request',
          status: TestStatus.pass,
          message: 'Auth checked before validation (OK)',
          duration: stopwatch.elapsed,
        );
      } else {
        return TestResult(
          name: 'Invalid Request',
          status: TestStatus.warning,
          message: 'Unexpected status for invalid request: ${response.statusCode}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      return TestResult(
        name: 'Invalid Request',
        status: TestStatus.fail,
        message: 'Invalid request test failed: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Print test results summary
void printResults(List<TestResult> results) {
  print('');
  print('Test Results');
  print('============');
  print('');

  int passed = 0;
  int failed = 0;
  int warnings = 0;
  int skipped = 0;

  for (final result in results) {
    final duration = result.duration != null ? ' (${result.duration!.inMilliseconds}ms)' : '';
    print('${result.statusIcon} ${result.name}$duration');
    if (result.message != null) {
      print('  ${result.message}');
    }
    print('');

    switch (result.status) {
      case TestStatus.pass:
        passed++;
        break;
      case TestStatus.fail:
        failed++;
        break;
      case TestStatus.warning:
        warnings++;
        break;
      case TestStatus.skip:
        skipped++;
        break;
    }
  }

  print('Summary: $passed passed, $failed failed, $warnings warnings, $skipped skipped');
}

void main(List<String> args) async {
  print('GenUI Anthropic Proxy Endpoint Tester');
  print('=====================================');
  print('');

  // Parse arguments
  String? endpointUrl;
  String? authToken;
  int timeoutMs = 30000;
  bool verbose = false;

  for (final arg in args) {
    if (arg.startsWith('--auth=')) {
      authToken = arg.substring('--auth='.length);
    } else if (arg.startsWith('--timeout=')) {
      timeoutMs = int.tryParse(arg.substring('--timeout='.length)) ?? 30000;
    } else if (arg == '--verbose' || arg == '-v') {
      verbose = true;
    } else if (!arg.startsWith('--')) {
      endpointUrl = arg;
    }
  }

  if (endpointUrl == null) {
    print('Usage: dart run test_proxy_endpoint.dart <endpoint_url> [options]');
    print('');
    print('Options:');
    print('  --auth=<token>    Authorization token');
    print('  --timeout=<ms>    Request timeout (default: 30000)');
    print('  --verbose, -v     Show detailed output');
    print('');
    print('Example:');
    print('  dart run test_proxy_endpoint.dart https://project.supabase.co/functions/v1/claude-genui --auth=your_jwt_token');
    exit(1);
  }

  final uri = Uri.tryParse(endpointUrl);
  if (uri == null || !uri.hasScheme) {
    print('Error: Invalid URL: $endpointUrl');
    exit(1);
  }

  print('Endpoint: $endpointUrl');
  print('Auth: ${authToken != null ? "Provided" : "Not provided"}');
  print('Timeout: ${timeoutMs}ms');
  print('');

  final tester = ProxyTester(
    endpoint: uri,
    authToken: authToken,
    timeout: Duration(milliseconds: timeoutMs),
    verbose: verbose,
  );

  try {
    final results = await tester.runAllTests();
    printResults(results);

    final hasFailures = results.any((r) => r.status == TestStatus.fail);
    exit(hasFailures ? 1 : 0);
  } finally {
    tester.dispose();
  }
}
