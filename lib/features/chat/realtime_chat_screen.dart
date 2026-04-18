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
    this.chatTitle = 'Chat',
  });

  final String channelId;
  final String chatTitle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ChatViewModel(channelId: channelId)..loadMessages(),
      child: _ChatView(chatTitle: chatTitle),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.chatTitle});

  final String chatTitle;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(chatTitle),
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
          ChatInputBar(
            onSend: (text) =>
                context.read<ChatViewModel>().sendMessage(text),
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
      itemBuilder: (_, i) => MessageBubble(message: widget.messages[i]),
    );
  }
}
