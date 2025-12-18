import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import 'package:genui_claude_example/catalog/demo_catalog.dart';

/// Advanced configuration chat screen demonstrating ALL model parameters.
///
/// This example shows comprehensive Claude configuration options:
/// - **Sampling**: topP (nucleus), topK, stopSequences
/// - **Retry**: RetryConfig with presets (defaults, aggressive, noRetry)
/// - **Circuit Breaker**: CircuitBreakerConfig with state monitoring
/// - **Metrics**: MetricsCollector with live event streaming
/// - **Custom Headers**: HTTP header injection
/// - **Timeouts**: Request timeout configuration
/// - **Tokens**: Max tokens configuration
/// - **Experimental**: Fine-grained streaming, interleaved thinking
class AdvancedConfigChatScreen extends StatefulWidget {
  const AdvancedConfigChatScreen({super.key});

  @override
  State<AdvancedConfigChatScreen> createState() =>
      _AdvancedConfigChatScreenState();
}

class _AdvancedConfigChatScreenState extends State<AdvancedConfigChatScreen> {
  ClaudeContentGenerator? _contentGenerator;
  late GenUiManager? _genUiManager;
  GenUiConversation? _conversation;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatEntry>[];

  // Sampling Configuration
  double _topP = 0.9;
  int _topK = 40;
  bool _useTopP = true;
  final List<String> _stopSequences = [];
  final _stopSequenceController = TextEditingController();

  // Request Configuration
  int _maxTokens = 4096;
  int _timeoutSeconds = 60;

  // Retry Configuration
  String _retryPreset = 'defaults'; // defaults, aggressive, noRetry
  int _retryMaxAttempts = 3;
  double _retryBackoffMultiplier = 2;

  // Circuit Breaker Configuration (for demonstration)
  String _circuitBreakerPreset = 'defaults'; // defaults, lenient, strict
  int _circuitBreakerThreshold = 5;
  int _circuitBreakerRecoverySeconds = 30;
  CircuitBreaker? _circuitBreaker;

  // Custom Headers
  final Map<String, String> _customHeaders = {};
  final _headerKeyController = TextEditingController();
  final _headerValueController = TextEditingController();

  // Experimental Features
  bool _enableFineGrainedStreaming = false;
  bool _enableInterleavedThinking = false;
  int _thinkingBudgetTokens = 1024;

  // Metrics Collection (standalone demonstration)
  bool _enableMetrics = true;
  MetricsCollector? _metricsCollector;
  StreamSubscription<MetricsEvent>? _metricsSubscription;
  final List<_MetricsLogEntry> _metricsLog = [];

  // ignore: do_not_use_environment
  static const _apiKey = String.fromEnvironment('CLAUDE_API_KEY');

  @override
  void initState() {
    super.initState();
    _initializeGenerator();
  }

  void _initializeGenerator() {
    // Dispose existing resources
    _metricsSubscription?.cancel();
    _conversation?.dispose();
    _contentGenerator?.dispose();

    // Create the GenUI manager with the catalog
    _genUiManager = GenUiManager(catalog: DemoCatalog());

    // Create metrics collector (standalone for demonstration)
    _metricsCollector = _enableMetrics ? MetricsCollector() : null;

    // Create circuit breaker (standalone for demonstration)
    final circuitBreakerConfig = switch (_circuitBreakerPreset) {
      'lenient' => CircuitBreakerConfig.lenient,
      'strict' => CircuitBreakerConfig.strict,
      _ => CircuitBreakerConfig(
          failureThreshold: _circuitBreakerThreshold,
          recoveryTimeout: Duration(seconds: _circuitBreakerRecoverySeconds),
        ),
    };
    _circuitBreaker = CircuitBreaker(
      config: circuitBreakerConfig,
      metricsCollector: _metricsCollector,
    );

    // Create retry config with selected preset (for documentation purposes)
    final retryConfig = switch (_retryPreset) {
      'aggressive' => RetryConfig.aggressive,
      'noRetry' => RetryConfig.noRetry,
      _ => RetryConfig(
          maxAttempts: _retryMaxAttempts,
          backoffMultiplier: _retryBackoffMultiplier,
        ),
    };

    // Create configuration with ALL advanced parameters
    final config = ClaudeConfig(
      // Sampling parameters
      topP: _useTopP ? _topP : null,
      topK: !_useTopP ? _topK : null,
      stopSequences: _stopSequences.isNotEmpty ? _stopSequences : null,
      // Request parameters
      maxTokens: _maxTokens,
      timeout: Duration(seconds: _timeoutSeconds),
      // Retry configuration
      retryAttempts: retryConfig.maxAttempts,
      // Custom headers
      headers: _customHeaders.isNotEmpty ? _customHeaders : null,
      // Experimental features (placeholders)
      enableFineGrainedStreaming: _enableFineGrainedStreaming,
      enableInterleavedThinking: _enableInterleavedThinking,
      thinkingBudgetTokens:
          _enableInterleavedThinking ? _thinkingBudgetTokens : null,
    );

    // Create the content generator with advanced config
    _contentGenerator = ClaudeContentGenerator(
      apiKey: _apiKey,
      config: config,
      systemInstruction: '''
You are a helpful assistant that generates interactive UI components.
When the user requests UI elements, use the available tools to create them.
Be creative and helpful in generating appropriate UI for the user's needs.

Available tools include: text_display, info_card, action_button, item_list,
progress_indicator, input_field, image_display, divider, spacer, container.
''',
    );

    // Subscribe to metrics events
    if (_metricsCollector != null) {
      _metricsSubscription = _metricsCollector!.eventStream.listen((event) {
        setState(() {
          _metricsLog.insert(0, _MetricsLogEntry(event));
          if (_metricsLog.length > 50) _metricsLog.removeLast();
        });
      });
    }

    // Create the GenUI conversation
    _conversation = GenUiConversation(
      contentGenerator: _contentGenerator!,
      genUiManager: _genUiManager!,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _handleTextResponse,
      onError: _handleError,
    );

    setState(() {});
  }

  void _handleSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _messages.add(_ChatEntry.surface(update.surfaceId));
    });
    _scrollToBottom();
  }

  void _handleTextResponse(String text) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isAiText) {
        _messages.last = _ChatEntry.aiText(_messages.last.text! + text);
      } else {
        _messages.add(_ChatEntry.aiText(text));
      }
    });
    _scrollToBottom();
  }

  void _handleError(ContentGeneratorError error) {
    if (!mounted) return;

    // Log error type for demonstration
    final errorType = error.error.runtimeType.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error [$errorType]: ${error.error}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _stopSequenceController.dispose();
    _headerKeyController.dispose();
    _headerValueController.dispose();
    _conversation?.dispose();
    _contentGenerator?.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatEntry.user(text));
    });
    _conversation?.sendRequest(UserMessage.text(text));
    _scrollToBottom();
  }

  void _showConfigDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Advanced Model Parameters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),

              // ============ SAMPLING SECTION ============
              _buildSectionHeader(context, 'Sampling Parameters', Icons.tune),
              SwitchListTile(
                title: Text(_useTopP ? 'Using Top-P (Nucleus)' : 'Using Top-K'),
                subtitle: Text(
                  _useTopP
                      ? 'Cumulative probability cutoff'
                      : 'Limit to k most likely tokens',
                ),
                value: _useTopP,
                onChanged: (value) {
                  setModalState(() => _useTopP = value);
                  setState(() {});
                },
              ),
              if (_useTopP) ...[
                ListTile(
                  title: Text('Top-P: ${_topP.toStringAsFixed(2)}'),
                  subtitle: Slider(
                    value: _topP,
                    min: 0.1,
                    divisions: 18,
                    label: _topP.toStringAsFixed(2),
                    onChanged: (value) {
                      setModalState(() => _topP = value);
                      setState(() {});
                    },
                  ),
                ),
              ],
              if (!_useTopP) ...[
                ListTile(
                  title: Text('Top-K: $_topK'),
                  subtitle: Slider(
                    value: _topK.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: _topK.toString(),
                    onChanged: (value) {
                      setModalState(() => _topK = value.toInt());
                      setState(() {});
                    },
                  ),
                ),
              ],
              // Stop Sequences
              ListTile(
                title: const Text('Stop Sequences'),
                subtitle: Text(
                  _stopSequences.isEmpty
                      ? 'None (max 4)'
                      : _stopSequences.join(', '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _stopSequences.length < 4
                      ? () => _showAddStopSequenceDialog(setModalState)
                      : null,
                ),
              ),
              if (_stopSequences.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _stopSequences
                      .map(
                        (seq) => Chip(
                          label: Text(seq),
                          onDeleted: () {
                            setModalState(() => _stopSequences.remove(seq));
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
              const Divider(),

              // ============ REQUEST SECTION ============
              _buildSectionHeader(
                context,
                'Request Configuration',
                Icons.settings,
              ),
              ListTile(
                title: Text('Max Tokens: $_maxTokens'),
                subtitle: Slider(
                  value: _maxTokens.toDouble(),
                  min: 256,
                  max: 8192,
                  divisions: 31,
                  label: _maxTokens.toString(),
                  onChanged: (value) {
                    setModalState(() => _maxTokens = value.toInt());
                    setState(() {});
                  },
                ),
              ),
              ListTile(
                title: Text('Timeout: ${_timeoutSeconds}s'),
                subtitle: Slider(
                  value: _timeoutSeconds.toDouble(),
                  min: 10,
                  max: 300,
                  divisions: 29,
                  label: '${_timeoutSeconds}s',
                  onChanged: (value) {
                    setModalState(() => _timeoutSeconds = value.toInt());
                    setState(() {});
                  },
                ),
              ),
              const Divider(),

              // ============ RETRY SECTION ============
              _buildSectionHeader(context, 'Retry Configuration', Icons.replay),
              ListTile(
                title: const Text('Retry Preset'),
                trailing: DropdownButton<String>(
                  value: _retryPreset,
                  items: const [
                    DropdownMenuItem(
                      value: 'defaults',
                      child: Text('Default'),
                    ),
                    DropdownMenuItem(
                      value: 'aggressive',
                      child: Text('Aggressive'),
                    ),
                    DropdownMenuItem(
                      value: 'noRetry',
                      child: Text('No Retry'),
                    ),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    setModalState(() => _retryPreset = value!);
                    setState(() {});
                  },
                ),
              ),
              if (_retryPreset == 'custom') ...[
                ListTile(
                  title: Text('Max Attempts: $_retryMaxAttempts'),
                  subtitle: Slider(
                    value: _retryMaxAttempts.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _retryMaxAttempts.toString(),
                    onChanged: (value) {
                      setModalState(() => _retryMaxAttempts = value.toInt());
                      setState(() {});
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    'Backoff Multiplier: '
                    '${_retryBackoffMultiplier.toStringAsFixed(1)}',
                  ),
                  subtitle: Slider(
                    value: _retryBackoffMultiplier,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _retryBackoffMultiplier.toStringAsFixed(1),
                    onChanged: (value) {
                      setModalState(() => _retryBackoffMultiplier = value);
                      setState(() {});
                    },
                  ),
                ),
              ],
              const Divider(),

              // ============ CIRCUIT BREAKER SECTION ============
              _buildSectionHeader(
                context,
                'Circuit Breaker',
                Icons.electric_bolt,
              ),
              ListTile(
                title: const Text('Circuit Breaker Preset'),
                trailing: DropdownButton<String>(
                  value: _circuitBreakerPreset,
                  items: const [
                    DropdownMenuItem(
                      value: 'defaults',
                      child: Text('Default'),
                    ),
                    DropdownMenuItem(value: 'lenient', child: Text('Lenient')),
                    DropdownMenuItem(value: 'strict', child: Text('Strict')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    setModalState(() => _circuitBreakerPreset = value!);
                    setState(() {});
                  },
                ),
              ),
              if (_circuitBreakerPreset == 'custom') ...[
                ListTile(
                  title: Text('Failure Threshold: $_circuitBreakerThreshold'),
                  subtitle: Slider(
                    value: _circuitBreakerThreshold.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _circuitBreakerThreshold.toString(),
                    onChanged: (value) {
                      setModalState(
                        () => _circuitBreakerThreshold = value.toInt(),
                      );
                      setState(() {});
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    'Recovery Timeout: ${_circuitBreakerRecoverySeconds}s',
                  ),
                  subtitle: Slider(
                    value: _circuitBreakerRecoverySeconds.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${_circuitBreakerRecoverySeconds}s',
                    onChanged: (value) {
                      setModalState(
                        () => _circuitBreakerRecoverySeconds = value.toInt(),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ],
              const Divider(),

              // ============ CUSTOM HEADERS SECTION ============
              _buildSectionHeader(
                context,
                'Custom HTTP Headers',
                Icons.http,
              ),
              ListTile(
                title: Text(
                  _customHeaders.isEmpty
                      ? 'No custom headers'
                      : '${_customHeaders.length} header(s)',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddHeaderDialog(setModalState),
                ),
              ),
              if (_customHeaders.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _customHeaders.entries
                      .map(
                        (e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
                          onDeleted: () {
                            setModalState(
                              () => _customHeaders.remove(e.key),
                            );
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
              const Divider(),

              // ============ EXPERIMENTAL SECTION ============
              _buildSectionHeader(
                context,
                'Experimental Features',
                Icons.science,
              ),
              SwitchListTile(
                title: const Text('Fine-Grained Streaming'),
                subtitle: const Text('Progressive JSON streaming (beta)'),
                value: _enableFineGrainedStreaming,
                onChanged: (value) {
                  setModalState(() => _enableFineGrainedStreaming = value);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Interleaved Thinking'),
                subtitle: const Text('Claude 4+ reasoning blocks'),
                value: _enableInterleavedThinking,
                onChanged: (value) {
                  setModalState(() => _enableInterleavedThinking = value);
                  setState(() {});
                },
              ),
              if (_enableInterleavedThinking)
                ListTile(
                  title: Text(
                    'Thinking Budget: $_thinkingBudgetTokens tokens',
                  ),
                  subtitle: Slider(
                    value: _thinkingBudgetTokens.toDouble(),
                    min: 256,
                    max: 4096,
                    divisions: 15,
                    label: _thinkingBudgetTokens.toString(),
                    onChanged: (value) {
                      setModalState(
                        () => _thinkingBudgetTokens = value.toInt(),
                      );
                      setState(() {});
                    },
                  ),
                ),
              const Divider(),

              // ============ METRICS SECTION ============
              _buildSectionHeader(
                context,
                'Metrics Collection',
                Icons.analytics,
              ),
              SwitchListTile(
                title: const Text('Enable Metrics'),
                subtitle: const Text('Collect performance & error metrics'),
                value: _enableMetrics,
                onChanged: (value) {
                  setModalState(() => _enableMetrics = value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // ============ APPLY BUTTON ============
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _messages.clear();
                    _metricsLog.clear();
                    _initializeGenerator();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Configuration applied. New conversation started.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Apply & Restart Conversation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showAddStopSequenceDialog(StateSetter setModalState) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stop Sequence'),
        content: TextField(
          controller: _stopSequenceController,
          decoration: const InputDecoration(
            hintText: 'Enter sequence (max 100 chars)',
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final seq = _stopSequenceController.text.trim();
              if (seq.isNotEmpty) {
                setModalState(() {
                  _stopSequences.add(seq);
                  _stopSequenceController.clear();
                });
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddHeaderDialog(StateSetter setModalState) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Header'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _headerKeyController,
              decoration: const InputDecoration(
                labelText: 'Header Name',
                hintText: 'X-Custom-Header',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _headerValueController,
              decoration: const InputDecoration(
                labelText: 'Header Value',
                hintText: 'value',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final key = _headerKeyController.text.trim();
              final value = _headerValueController.text.trim();
              if (key.isNotEmpty && value.isNotEmpty) {
                setModalState(() {
                  _customHeaders[key] = value;
                  _headerKeyController.clear();
                  _headerValueController.clear();
                });
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMetricsDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.analytics),
                  const SizedBox(width: 8),
                  const Text(
                    'Metrics Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_circuitBreaker != null)
                    _CircuitBreakerBadge(state: _circuitBreaker!.state),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_metricsCollector != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricCard(
                      label: 'Success Rate',
                      value:
                          '${_metricsCollector!.stats.successRate.toStringAsFixed(1)}%',
                    ),
                    _MetricCard(
                      label: 'Avg Latency',
                      value:
                          '${_metricsCollector!.stats.averageLatencyMs.toStringAsFixed(0)}ms',
                    ),
                    _MetricCard(
                      label: 'Total Requests',
                      value: '${_metricsCollector!.stats.totalRequests}',
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: _metricsLog.isEmpty
                  ? const Center(child: Text('No metrics yet'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _metricsLog.length,
                      itemBuilder: (_, index) {
                        final entry = _metricsLog[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            entry.icon,
                            size: 20,
                            color: entry.color,
                          ),
                          title: Text(entry.title),
                          subtitle: Text(entry.subtitle),
                          trailing: Text(
                            entry.time,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = _apiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Config'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_enableMetrics)
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'View Metrics',
              onPressed: _showMetricsDialog,
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Configure model parameters',
            onPressed: _showConfigDialog,
          ),
          if (_contentGenerator != null)
            ValueListenableBuilder<bool>(
              valueListenable: _contentGenerator!.isProcessing,
              builder: (_, isProcessing, __) {
                if (isProcessing) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: hasApiKey ? _buildChatBody() : _buildNoApiKeyMessage(),
    );
  }

  Widget _buildNoApiKeyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'API Key Required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please run the app with:\n'
              'flutter run --dart-define=CLAUDE_API_KEY=your-key',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    return Column(
      children: [
        // Current config indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _ConfigChip(
                icon: Icons.tune,
                label: _useTopP
                    ? 'topP: ${_topP.toStringAsFixed(2)}'
                    : 'topK: $_topK',
              ),
              _ConfigChip(
                icon: Icons.token,
                label: 'max: $_maxTokens',
              ),
              _ConfigChip(
                icon: Icons.replay,
                label: 'retry: $_retryPreset',
              ),
              _ConfigChip(
                icon: Icons.electric_bolt,
                label: 'cb: $_circuitBreakerPreset',
              ),
              if (_stopSequences.isNotEmpty)
                _ConfigChip(
                  icon: Icons.stop,
                  label: 'stops: ${_stopSequences.length}',
                ),
              if (_customHeaders.isNotEmpty)
                _ConfigChip(
                  icon: Icons.http,
                  label: 'headers: ${_customHeaders.length}',
                ),
              if (_enableFineGrainedStreaming)
                const _ConfigChip(
                  icon: Icons.stream,
                  label: 'fine-grained',
                ),
              if (_enableInterleavedThinking)
                const _ConfigChip(
                  icon: Icons.psychology,
                  label: 'thinking',
                ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(_messages[index]),
                ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Advanced Configuration Demo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the tune icon to adjust ALL parameters:',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(label: Text('topP/topK')),
                Chip(label: Text('stopSequences')),
                Chip(label: Text('maxTokens')),
                Chip(label: Text('timeout')),
                Chip(label: Text('retryConfig')),
                Chip(label: Text('circuitBreaker')),
                Chip(label: Text('customHeaders')),
                Chip(label: Text('metrics')),
                Chip(label: Text('thinking')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(_ChatEntry entry) {
    switch (entry.type) {
      case _ChatEntryType.user:
        return _UserMessageBubble(text: entry.text!);
      case _ChatEntryType.aiText:
        return _AiMessageBubble(text: entry.text!);
      case _ChatEntryType.surface:
        return _SurfaceContainer(
          surfaceId: entry.surfaceId!,
          genUiManager: _genUiManager!,
        );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Try different parameter settings...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            if (_contentGenerator != null)
              ValueListenableBuilder<bool>(
                valueListenable: _contentGenerator!.isProcessing,
                builder: (_, isProcessing, __) {
                  return IconButton.filled(
                    onPressed: isProcessing ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ============ HELPER CLASSES ============

class _ConfigChip extends StatelessWidget {
  const _ConfigChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CircuitBreakerBadge extends StatelessWidget {
  const _CircuitBreakerBadge({required this.state});

  final CircuitState state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      CircuitState.closed => (Colors.green, 'Closed'),
      CircuitState.open => (Colors.red, 'Open'),
      CircuitState.halfOpen => (Colors.orange, 'Half-Open'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.electric_bolt, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _MetricsLogEntry {
  _MetricsLogEntry(MetricsEvent event)
      : time = _formatTime(DateTime.now()),
        title = event.eventType,
        subtitle = _getSubtitle(event),
        icon = _getIcon(event),
        color = _getColor(event);

  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  static String _getSubtitle(MetricsEvent event) {
    return switch (event) {
      final CircuitBreakerStateChangeEvent e =>
        '${e.previousState.name} -> ${e.newState.name}',
      final RetryAttemptEvent e => 'Attempt ${e.attempt}: ${e.reason}',
      final RequestStartEvent e => 'Request ${e.requestId}',
      final RequestSuccessEvent e => '${e.durationMs}ms',
      final RequestFailureEvent e => e.errorMessage,
      final RateLimitEvent e => 'Retry after ${e.retryAfterMs ?? 0}ms',
      final StreamInactivityEvent e => 'Last activity: ${e.lastActivityMs}ms',
      final LatencyEvent e => '${e.operation}: ${e.durationMs}ms',
    };
  }

  static IconData _getIcon(MetricsEvent event) {
    return switch (event) {
      CircuitBreakerStateChangeEvent() => Icons.electric_bolt,
      RetryAttemptEvent() => Icons.replay,
      RequestStartEvent() => Icons.upload,
      RequestSuccessEvent() => Icons.check_circle,
      RequestFailureEvent() => Icons.error,
      RateLimitEvent() => Icons.speed,
      StreamInactivityEvent() => Icons.hourglass_empty,
      LatencyEvent() => Icons.timer,
    };
  }

  static Color _getColor(MetricsEvent event) {
    return switch (event) {
      RequestSuccessEvent() => Colors.green,
      RequestFailureEvent() => Colors.red,
      RateLimitEvent() => Colors.orange,
      CircuitBreakerStateChangeEvent() => Colors.purple,
      RetryAttemptEvent() => Colors.blue,
      _ => Colors.grey,
    };
  }
}

// Chat entry model
enum _ChatEntryType { user, aiText, surface }

class _ChatEntry {
  _ChatEntry.user(this.text)
      : type = _ChatEntryType.user,
        surfaceId = null;
  _ChatEntry.aiText(this.text)
      : type = _ChatEntryType.aiText,
        surfaceId = null;
  _ChatEntry.surface(this.surfaceId)
      : type = _ChatEntryType.surface,
        text = null;

  final _ChatEntryType type;
  final String? text;
  final String? surfaceId;

  bool get isAiText => type == _ChatEntryType.aiText;
}

// UI Components

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceContainer extends StatelessWidget {
  const _SurfaceContainer({
    required this.surfaceId,
    required this.genUiManager,
  });

  final String surfaceId;
  final GenUiManager genUiManager;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.widgets, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GenUiSurface(
                  host: genUiManager,
                  surfaceId: surfaceId,
                  defaultBuilder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
