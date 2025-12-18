import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import 'package:genui_claude_example/catalog/demo_catalog.dart';

/// Advanced configuration chat screen demonstrating model parameters.
///
/// This example shows how to use advanced Claude model parameters:
/// - topP: Nucleus sampling for response diversity
/// - topK: Top-k sampling for token selection
/// - stopSequences: Stop generation on specific strings
class AdvancedConfigChatScreen extends StatefulWidget {
  const AdvancedConfigChatScreen({super.key});

  @override
  State<AdvancedConfigChatScreen> createState() =>
      _AdvancedConfigChatScreenState();
}

class _AdvancedConfigChatScreenState extends State<AdvancedConfigChatScreen> {
  late ClaudeContentGenerator? _contentGenerator;
  late GenUiManager? _genUiManager;
  late GenUiConversation? _conversation;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatEntry>[];

  // Configuration state
  double _topP = 0.9;
  int _topK = 40;
  bool _useTopP = true; // Toggle between topP and topK
  final List<String> _stopSequences = [];
  final _stopSequenceController = TextEditingController();

  // ignore: do_not_use_environment
  static const _apiKey = String.fromEnvironment('CLAUDE_API_KEY');

  @override
  void initState() {
    super.initState();
    _initializeGenerator();
  }

  void _initializeGenerator() {
    // Dispose existing resources
    _conversation?.dispose();
    _contentGenerator?.dispose();

    // Create the GenUI manager with the catalog
    _genUiManager = GenUiManager(catalog: DemoCatalog());

    // Create configuration with advanced parameters
    final config = ClaudeConfig(
      topP: _useTopP ? _topP : null,
      topK: !_useTopP ? _topK : null,
      stopSequences: _stopSequences.isNotEmpty ? _stopSequences : null,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.error}'),
        backgroundColor: Colors.red,
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
    _messageController.dispose();
    _scrollController.dispose();
    _stopSequenceController.dispose();
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Model Parameters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Sampling method toggle
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
                const SizedBox(height: 8),
                // Top-P slider
                if (_useTopP) ...[
                  Text('Top-P: ${_topP.toStringAsFixed(2)}'),
                  Slider(
                    value: _topP,
                    min: 0.1,
                    divisions: 18,
                    label: _topP.toStringAsFixed(2),
                    onChanged: (value) {
                      setModalState(() => _topP = value);
                      setState(() {});
                    },
                  ),
                  const Text(
                    'Lower values = more focused, higher = more diverse',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                // Top-K slider
                if (!_useTopP) ...[
                  Text('Top-K: $_topK'),
                  Slider(
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
                  const Text(
                    'Lower values = more focused, higher = more variety',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                // Stop sequences
                Text(
                  'Stop Sequences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stopSequenceController,
                        decoration: const InputDecoration(
                          hintText: 'Add stop sequence...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _stopSequences.length < 4
                          ? () {
                              final seq = _stopSequenceController.text.trim();
                              if (seq.isNotEmpty && seq.length <= 100) {
                                setModalState(() {
                                  _stopSequences.add(seq);
                                  _stopSequenceController.clear();
                                });
                                setState(() {});
                              }
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                if (_stopSequences.isEmpty)
                  const Text(
                    'No stop sequences (max 4)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _messages.clear();
                      _initializeGenerator();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuration applied. New conversation started.'),
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
          child: Row(
            children: [
              Icon(
                Icons.settings,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _useTopP ? 'topP: ${_topP.toStringAsFixed(2)}' : 'topK: $_topK',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_stopSequences.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  'stops: ${_stopSequences.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tune,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced Configuration Demo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the tune icon to adjust model parameters\n'
            '(topP, topK, stop sequences)',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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

// Chat entry model (shared with basic_chat.dart pattern)
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

// UI Components (matching basic_chat.dart style)

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
