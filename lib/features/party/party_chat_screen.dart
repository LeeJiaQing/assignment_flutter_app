// lib/features/party/party_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_config.dart';
import 'viewmodels/party_view_model.dart';
import '../chat/viewmodels/chat_view_model.dart';
import '../chat/widgets/chat_input_bar.dart';
import '../chat/widgets/message_bubble.dart';

class PartyDetailChatScreen extends StatelessWidget {
  const PartyDetailChatScreen({super.key, required this.session});

  final PartySession session;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PartyViewModel()..loadSessions(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            channelId: 'party_${session.id}',
          )..loadMessages(),
        ),
      ],
      child: _PartyDetailChatView(session: session),
    );
  }
}

class _PartyDetailChatView extends StatefulWidget {
  const _PartyDetailChatView({required this.session});
  final PartySession session;

  @override
  State<_PartyDetailChatView> createState() =>
      _PartyDetailChatViewState();
}

class _PartyDetailChatViewState extends State<_PartyDetailChatView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isHost =>
      supabase.auth.currentUser?.id == widget.session.hostId;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  String get _timeLabel =>
      '${_fmt(widget.session.startHour)} – ${_fmt(widget.session.endHour)}';

  String get _dateLabel {
    final d = widget.session.date;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(
          widget.session.facilityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1C894E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1C894E),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(
                icon: Icon(Icons.chat_bubble_outline),
                text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DetailsTab(
            session: widget.session,
            isHost: _isHost,
            dateLabel: _dateLabel,
            timeLabel: _timeLabel,
          ),
          _ChatTab(channelId: 'party_${widget.session.id}'),
        ],
      ),
    );
  }
}

// ── Details Tab ────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.session,
    required this.isHost,
    required this.dateLabel,
    required this.timeLabel,
  });

  final PartySession session;
  final bool isHost;
  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C894E), Color(0xFF6DCC98)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.sport,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  if (isHost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('You\'re hosting',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                session.facilityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _WhiteInfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: dateLabel),
              const SizedBox(height: 4),
              _WhiteInfoRow(
                  icon: Icons.access_time_outlined, text: timeLabel),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Players card ───────────────────────────────────────────────
        _InfoCard(
          title: 'Players',
          icon: Icons.group_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Joined',
                      value: '${session.currentPlayers}',
                      color: const Color(0xFF1C894E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Max',
                      value: '${session.maxPlayers}',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Open Spots',
                      value: '${session.spotsLeft}',
                      color: session.isFull
                          ? Colors.red
                          : const Color(0xFF6DCC98),
                    ),
                  ),
                ],
              ),
              if (session.isFull) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('This session is full.',
                          style: TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Host card ──────────────────────────────────────────────────
        _InfoCard(
          title: 'Host',
          icon: Icons.person_outline,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD6F0E0),
                child: Text(
                  session.hostName.isNotEmpty
                      ? session.hostName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFF1C894E),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                session.hostName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (isHost) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6F0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                        color: Color(0xFF1C894E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (session.notes != null && session.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Notes',
            icon: Icons.notes_outlined,
            child: Text(
              session.notes!,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.5),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── Join button (non-hosts only, if not full) ──────────────────
        if (!isHost && !session.isFull)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join This Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6DCC98),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _handleJoin(context),
            ),
          ),

        if (!isHost && session.isFull)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Text('Session is full',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Chat shortcut button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Open Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1C894E),
              side: const BorderSide(color: Color(0xFF1C894E)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              // Switch to chat tab
              final tabController = context
                  .findAncestorStateOfType<_PartyDetailChatViewState>()
                  ?._tabController;
              tabController?.animateTo(1);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _handleJoin(BuildContext context) async {
    final vm = context.read<PartyViewModel>();
    final success = await vm.joinSession(session.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'You\'ve joined the session!'
            : 'Failed to join. ${vm.errorMessage ?? ''}'),
        backgroundColor:
        success ? const Color(0xFF1C894E) : Colors.red.shade700,
      ),
    );

    if (success) Navigator.pop(context);
  }
}

// ── Chat Tab ───────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  const _ChatTab({required this.channelId});
  final String channelId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Column(
      children: [
        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.messages.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No messages yet.\nSay hello to your session mates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : _MessageList(messages: vm.messages),
        ),
        ChatInputBar(
          onSend: (text) =>
              context.read<ChatViewModel>().sendMessage(text),
        ),
      ],
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
  void didUpdateWidget(_MessageList old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
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

// ── Reusable widgets ───────────────────────────────────────────────────────

class _WhiteInfoRow extends StatelessWidget {
  const _WhiteInfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text,
            style:
            const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.title,
        required this.icon,
        required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1C894E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1C3A2A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label,
        required this.value,
        required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}