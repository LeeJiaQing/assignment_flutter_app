// lib/features/chat/realtime_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/chat_view_model.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

class RealtimeChatScreen extends StatelessWidget {
  const RealtimeChatScreen({
    super.key,
    this.channelId = 'general',
    this.readOnly = false,
  });

  final String channelId;

  /// When true the input bar is hidden and a read-only banner is shown.
  /// Used for the admin navigation tab.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ChatViewModel(channelId: channelId)..loadMessages(),
      child: _ChatView(readOnly: readOnly),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.readOnly});
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ChatViewModel>().loadMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin read-only banner
          if (readOnly)
            Container(
              color: const Color(0xFFD6F0E0),
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      color: Color(0xFF1C894E), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Admin view — read only',
                    style: TextStyle(
                        color: Color(0xFF1C894E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.messages.isEmpty
                ? const Center(
              child: Text('No messages yet.',
                  style: TextStyle(color: Colors.grey)),
            )
                : _MessageList(messages: vm.messages),
          ),
          // Hide input bar for admins
          if (!readOnly)
            SafeArea(
              top: false,
              child: ChatInputBar(
                onSend: (text) =>
                    context.read<ChatViewModel>().sendMessage(text),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({required this.messages});
  final List<ChatMessage> messages;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: widget.messages.length,
      itemBuilder: (_, i) =>
          MessageBubble(message: widget.messages[i]),
    );
  }
}