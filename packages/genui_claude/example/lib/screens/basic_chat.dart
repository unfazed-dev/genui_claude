import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import 'package:genui_claude_example/catalog/demo_catalog.dart';

/// Basic chat screen demonstrating direct API mode.
///
/// This is suitable for development and prototyping but should NOT
/// be used in production as it exposes the API key in the app.
class BasicChatScreen extends StatefulWidget {
  const BasicChatScreen({super.key});

  @override
  State<BasicChatScreen> createState() => _BasicChatScreenState();
}

class _BasicChatScreenState extends State<BasicChatScreen> {
  late final ClaudeContentGenerator _contentGenerator;
  late final GenUiManager _genUiManager;
  late final GenUiConversation _conversation;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatEntry>[];

  // API key should be provided via compile-time environment variable
  // ignore: do_not_use_environment
  static const _apiKey = String.fromEnvironment('CLAUDE_API_KEY');

  @override
  void initState() {
    super.initState();

    // Create the GenUI manager with the catalog
    _genUiManager = GenUiManager(catalog: DemoCatalog());

    // Create the content generator with direct API access
    _contentGenerator = ClaudeContentGenerator(
      apiKey: _apiKey,
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
      contentGenerator: _contentGenerator,
      genUiManager: _genUiManager,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _handleTextResponse,
      onError: _handleError,
    );
  }

  void _handleSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _messages.add(_ChatEntry.surface(update.surfaceId));
    });
    _scrollToBottom();
  }

  void _handleTextResponse(String text) {
    setState(() {
      // Add or append to existing AI text message
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
    _conversation.dispose();
    _contentGenerator.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatEntry.user(text));
    });
    _conversation.sendRequest(UserMessage.text(text));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = _apiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _contentGenerator.isProcessing,
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
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me to create some UI components!',
            style: TextStyle(color: Colors.grey),
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
          genUiManager: _genUiManager,
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
                  hintText: 'Ask me to create some UI...',
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
            ValueListenableBuilder<bool>(
              valueListenable: _contentGenerator.isProcessing,
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
