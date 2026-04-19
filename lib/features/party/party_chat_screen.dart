// lib/features/party/party_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/auth_repository.dart';
import '../../core/supabase/supabase_config.dart';
import 'edit_party_screen.dart';
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
            create: (_) => PartyViewModel()..loadSessions()),
        ChangeNotifierProvider(
          create: (_) =>
          ChatViewModel(channelId: 'party_${session.id}')
            ..loadMessages(),
        ),
      ],
      child: _PartyDetailChatView(session: session),
    );
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class _PartyDetailChatView extends StatefulWidget {
  const _PartyDetailChatView({required this.session});
  final PartySession session;

  @override
  State<_PartyDetailChatView> createState() => _PartyDetailChatViewState();
}

class _PartyDetailChatViewState extends State<_PartyDetailChatView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isAdmin = false;
  bool _roleChecked = false;

  // Live session data (updated after edit).
  late PartySession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _tabController = TabController(length: 2, vsync: this);
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await AuthRepository().getCurrentUserRole();
    if (mounted) setState(() {
      _isAdmin = role == UserRole.admin;
      _roleChecked = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isHost => supabase.auth.currentUser?.id == _session.hostId;

  String _fmt(int h) {
    final s = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $s';
  }

  String get _timeLabel =>
      '${_fmt(_session.startHour)} \u2013 ${_fmt(_session.endHour)}';

  String get _dateLabel {
    final d = _session.date;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPartyScreen(session: _session),
      ),
    );

    if (!mounted) return;

    if (result == 'deleted') {
      // Session was deleted — pop back to party list.
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session deleted.')),
      );
    } else if (result == true) {
      // Session was edited — reload sessions and show banner.
      context.read<PartyViewModel>().loadSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session updated. Participants will see the changes.'),
          backgroundColor: Color(0xFF1C894E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(_session.facilityName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Edit button — only for host
          if (_isHost)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit session',
              onPressed: _openEdit,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1C894E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1C894E),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DetailsTab(
            session: _session,
            isHost: _isHost,
            isAdmin: _isAdmin,
            roleChecked: _roleChecked,
            dateLabel: _dateLabel,
            timeLabel: _timeLabel,
            onSwitchToChat: () => _tabController.animateTo(1),
            onEdit: _openEdit,
          ),
          _ChatTab(
            channelId: 'party_${_session.id}',
            isAdmin: _isAdmin,
            roleChecked: _roleChecked,
          ),
        ],
      ),
    );
  }
}

// ── Details Tab ────────────────────────────────────────────────────────────

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({
    required this.session,
    required this.isHost,
    required this.isAdmin,
    required this.roleChecked,
    required this.dateLabel,
    required this.timeLabel,
    required this.onSwitchToChat,
    required this.onEdit,
  });

  final PartySession session;
  final bool isHost;
  final bool isAdmin;
  final bool roleChecked;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onSwitchToChat;
  final VoidCallback onEdit;

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  List<_Member> _members = [];
  bool _membersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      // Use explicit FK hint to avoid ambiguity when profiles has multiple
      // foreign key relationships (user_id -> profiles.id).
      final response = await supabase
          .from('party_members')
          .select('user_id, profiles!party_members_user_id_fkey(full_name)')
          .eq('session_id', widget.session.id);

      if (!mounted) return;
      setState(() {
        _members = (response as List<dynamic>).map((r) {
          final name =
              (r['profiles'] as Map?)?['full_name'] as String? ?? 'Unknown';
          return _Member(userId: r['user_id'] as String, name: name);
        }).toList();
        _membersLoaded = true;
      });
    } catch (e) {
      // Fallback: try without FK hint in case the FK name differs.
      try {
        final response = await supabase
            .from('party_members')
            .select('user_id, profiles(full_name)')
            .eq('session_id', widget.session.id);
        if (!mounted) return;
        setState(() {
          _members = (response as List<dynamic>).map((r) {
            final name =
                (r['profiles'] as Map?)?['full_name'] as String? ?? 'Unknown';
            return _Member(userId: r['user_id'] as String, name: name);
          }).toList();
          _membersLoaded = true;
        });
      } catch (_) {
        if (mounted) setState(() => _membersLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partyVm = context.watch<PartyViewModel>();
    final alreadyJoined = partyVm.isJoined(widget.session.id);

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
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
                    child: Text(widget.session.sport,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const Spacer(),
                  if (widget.isHost)
                    _HeaderBadge(label: "You're hosting"),
                  if (widget.session.isEdited) ...[
                    const SizedBox(width: 6),
                    _HeaderBadge(
                      label: 'Edited',
                      icon: Icons.edit_outlined,
                    ),
                  ],
                  if (widget.isAdmin && !widget.isHost)
                    _HeaderBadge(
                        label: 'Admin view',
                        icon: Icons.admin_panel_settings),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.session.facilityName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _WhiteInfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: widget.dateLabel),
              const SizedBox(height: 4),
              _WhiteInfoRow(
                  icon: Icons.access_time_outlined,
                  text: widget.timeLabel),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Players card with member list ──────────────────────────────
        _InfoCard(
          title: 'Players',
          icon: Icons.group_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Joined',
                      value: '${widget.session.currentPlayers}',
                      color: const Color(0xFF1C894E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                        label: 'Max',
                        value: '${widget.session.maxPlayers}',
                        color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Open',
                      value: '${widget.session.spotsLeft}',
                      color: widget.session.isFull
                          ? Colors.red
                          : const Color(0xFF6DCC98),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Participants',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1C3A2A))),
              const SizedBox(height: 8),
              // Host always first
              _ParticipantTile(
                  name: widget.session.hostName, badge: 'Host'),
              // Members loaded from DB
              if (!_membersLoaded)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else
                ..._members.map((m) => _ParticipantTile(name: m.name)),
              if (_membersLoaded && _members.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('No members yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
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
                  widget.session.hostName.isNotEmpty
                      ? widget.session.hostName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFF1C894E),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(widget.session.hostName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (widget.isHost) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6F0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('You',
                      style: TextStyle(
                          color: Color(0xFF1C894E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),

        if (widget.session.notes != null &&
            widget.session.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Notes',
            icon: Icons.notes_outlined,
            child: Text(widget.session.notes!,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.5)),
          ),
        ],
        const SizedBox(height: 16),

        // ── Action buttons ─────────────────────────────────────────────
        if (!widget.roleChecked)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (!widget.isAdmin) ...[
          if (!widget.isHost) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(alreadyJoined
                    ? Icons.check_circle_outline
                    : Icons.group_add_outlined),
                label: Text(alreadyJoined
                    ? 'Joined'
                    : widget.session.isFull
                    ? 'Session Full'
                    : 'Join This Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyJoined
                      ? Colors.blue.shade50
                      : widget.session.isFull
                      ? Colors.grey.shade300
                      : const Color(0xFF6DCC98),
                  foregroundColor: alreadyJoined
                      ? Colors.blue
                      : widget.session.isFull
                      ? Colors.grey.shade600
                      : Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: alreadyJoined
                      ? Colors.blue.shade50
                      : Colors.grey.shade300,
                  disabledForegroundColor: alreadyJoined
                      ? Colors.blue
                      : Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (alreadyJoined || widget.session.isFull)
                    ? null
                    : () => _handleJoin(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Host: edit button
          if (widget.isHost) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C894E),
                  side: const BorderSide(color: Color(0xFF1C894E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: widget.onEdit,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ] else ...[
          // Admin read-only banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD6F0E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Color(0xFF1C894E), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('You are viewing this session as an admin.',
                      style: TextStyle(
                          color: Color(0xFF1C894E), fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Open Chat button
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
            onPressed: widget.onSwitchToChat,
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoin(BuildContext context) async {
    final vm = context.read<PartyViewModel>();
    final success = await vm.joinSession(widget.session.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "You've joined the session!"
            : 'Failed to join. ${vm.errorMessage ?? ''}'),
        backgroundColor:
        success ? const Color(0xFF1C894E) : Colors.red.shade700,
      ),
    );

    // Reload members list after joining.
    if (success) await _loadMembers();
  }
}

// ── Participant Tile ───────────────────────────────────────────────────────

class _Member {
  final String userId;
  final String name;
  const _Member({required this.userId, required this.name});
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.name, this.badge});
  final String name;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFD6F0E0),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF1C894E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1C894E).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Color(0xFF1C894E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ── Chat Tab ───────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    required this.channelId,
    required this.isAdmin,
    required this.roleChecked,
  });
  final String channelId;
  final bool isAdmin;
  final bool roleChecked;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Column(
      children: [
        if (roleChecked && isAdmin)
          Container(
            color: const Color(0xFFD6F0E0),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.visibility_outlined,
                    color: Color(0xFF1C894E), size: 16),
                SizedBox(width: 8),
                Text('Admin view \u2014 read only',
                    style: TextStyle(
                        color: Color(0xFF1C894E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.messages.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: Colors.grey.shade300),
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
        if (roleChecked && !isAdmin)
          SafeArea(
            top: false,
            child: ChatInputBar(
              onSend: (text) =>
                  context.read<ChatViewModel>().sendMessage(text),
            ),
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
      itemBuilder: (_, i) => MessageBubble(message: widget.messages[i]),
    );
  }
}

// ── Reusable helper widgets ────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, this.icon = Icons.star});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

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
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.title, required this.icon, required this.child});
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1C894E)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1C3A2A))),
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
      {required this.label, required this.value, required this.color});
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
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}