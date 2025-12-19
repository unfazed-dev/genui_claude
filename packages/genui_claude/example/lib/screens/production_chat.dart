import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_claude/genui_claude.dart';

import 'package:genui_claude_example/catalog/demo_catalog.dart';

/// Production chat screen demonstrating proxy mode.
///
/// This pattern is recommended for production deployments where the
/// API key should not be exposed in the client application.
class ProductionChatScreen extends StatefulWidget {
  const ProductionChatScreen({super.key});

  @override
  State<ProductionChatScreen> createState() => _ProductionChatScreenState();
}

class _ProductionChatScreenState extends State<ProductionChatScreen> {
  late final ClaudeContentGenerator _contentGenerator;
  late final GenUiManager _genUiManager;
  late final GenUiConversation _conversation;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatEntry>[];

  // Proxy endpoint should be configured for your backend
  // ignore: do_not_use_environment
  static const _proxyEndpoint = String.fromEnvironment(
    'PROXY_ENDPOINT',
    defaultValue: 'https://your-project.supabase.co/functions/v1/claude-genui',
  );

  // Auth token from your authentication system
  // ignore: do_not_use_environment
  static const _authToken = String.fromEnvironment('AUTH_TOKEN');

  @override
  void initState() {
    super.initState();

    // Create the GenUI manager with the catalog
    _genUiManager = GenUiManager(catalog: DemoCatalog());

    // Create the content generator with proxy mode
    _contentGenerator = ClaudeContentGenerator.proxy(
      proxyEndpoint: Uri.parse(_proxyEndpoint),
      authToken: _authToken.isNotEmpty ? _authToken : null,
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
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
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
      body: Column(
        children: [
          _buildProxyInfo(context),
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
      ),
    );
  }

  Widget _buildProxyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(
            Icons.security,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Proxy Mode: API key secured on backend',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Production Mode'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This example demonstrates the recommended production pattern:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. API key is stored securely on the backend'),
              SizedBox(height: 4),
              Text('2. Client sends requests to your proxy endpoint'),
              SizedBox(height: 4),
              Text('3. Backend forwards requests to Claude API'),
              SizedBox(height: 4),
              Text('4. User authentication via auth token'),
              SizedBox(height: 16),
              Text(
                'Configure with environment variables:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('--dart-define=PROXY_ENDPOINT=https://...'),
              Text('--dart-define=AUTH_TOKEN=your-auth-token'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Production-Ready Chat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'API key is secured on your backend',
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

// Chat entry model (shared with basic_chat.dart in real app)
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

// UI Components (shared with basic_chat.dart in real app)

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
