// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import 'admin_announcement_screen.dart';
import 'user_list_screen.dart';

// ── Analytics model ────────────────────────────────────────────────────────

class _Analytics {
  final int totalUsers;
  final int activeBookings;
  final int completedBookings;
  final int bookingsToday;
  final double revenueToday;
  final double revenueThisMonth;
  final int totalFacilities;
  final int activeSessions;
  final int totalAnnouncements;

  const _Analytics({
    required this.totalUsers,
    required this.activeBookings,
    required this.completedBookings,
    required this.bookingsToday,
    required this.revenueToday,
    required this.revenueThisMonth,
    required this.totalFacilities,
    required this.activeSessions,
    required this.totalAnnouncements,
  });

  factory _Analytics.fromJson(Map<String, dynamic> j) => _Analytics(
    totalUsers: (j['total_users'] as num?)?.toInt() ?? 0,
    activeBookings: (j['active_bookings'] as num?)?.toInt() ?? 0,
    completedBookings:
    (j['completed_bookings'] as num?)?.toInt() ?? 0,
    bookingsToday: (j['bookings_today'] as num?)?.toInt() ?? 0,
    revenueToday:
    (j['revenue_today'] as num?)?.toDouble() ?? 0.0,
    revenueThisMonth:
    (j['revenue_this_month'] as num?)?.toDouble() ?? 0.0,
    totalFacilities:
    (j['total_facilities'] as num?)?.toInt() ?? 0,
    activeSessions:
    (j['active_sessions'] as num?)?.toInt() ?? 0,
    totalAnnouncements:
    (j['total_announcements'] as num?)?.toInt() ?? 0,
  );
}

// ── Dashboard Screen ───────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Analytics? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
      await supabase.from('admin_analytics').select().single();
      setState(() {
        _analytics =
            _Analytics.fromJson(response as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(context),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline,
            size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(_error!,
            style: const TextStyle(color: Colors.grey)),
        TextButton(
            onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    final a = _analytics!;
    final now = DateTime.now();
    final monthName = _monthNames[now.month - 1];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header banner ──────────────────────────────────────────
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Admin Overview',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$monthName ${now.year}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.analytics_outlined,
                    color: Colors.white38, size: 44),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick actions ──────────────────────────────────────────
          const _SectionLabel('Quick Actions'),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionTile(
                icon: Icons.campaign_outlined,
                label: 'New\nAnnouncement',
                color: const Color(0xFF1C894E),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const AdminAnnouncementScreen()));
                  _load();
                },
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.history_edu_outlined,
                label: 'All\nAnnouncements',
                color: Colors.purple.shade600,
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const AdminAnnouncementListScreen()));
                  _load();
                },
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.people_outline,
                label: 'Manage\nUsers',
                color: Colors.blue.shade600,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserListScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Today ─────────────────────────────────────────────────
          const _SectionLabel("Today"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Bookings',
                  value: '${a.bookingsToday}',
                  color: const Color(0xFF1C894E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money,
                  label: 'Revenue',
                  value:
                  'RM ${a.revenueToday.toStringAsFixed(0)}',
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Monthly revenue highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up,
                      color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${a.revenueThisMonth.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C3A2A)),
                    ),
                    Text('Revenue in $monthName',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Platform stats grid ────────────────────────────────────
          const _SectionLabel('Platform Stats'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              _MiniStat(
                  icon: Icons.people,
                  label: 'Users',
                  value: '${a.totalUsers}',
                  color: Colors.blue),
              _MiniStat(
                  icon: Icons.stadium_outlined,
                  label: 'Facilities',
                  value: '${a.totalFacilities}',
                  color: const Color(0xFF1C894E)),
              _MiniStat(
                  icon: Icons.check_circle_outline,
                  label: 'Confirmed',
                  value: '${a.activeBookings}',
                  color: Colors.green),
              _MiniStat(
                  icon: Icons.task_alt,
                  label: 'Completed',
                  value: '${a.completedBookings}',
                  color: Colors.teal),
              _MiniStat(
                  icon: Icons.sports_soccer,
                  label: 'Sessions',
                  value: '${a.activeSessions}',
                  color: Colors.orange),
              _MiniStat(
                  icon: Icons.campaign_outlined,
                  label: 'Sent',
                  value: '${a.totalAnnouncements}',
                  color: Colors.purple),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
}

// ── Facility management moves to FacilityScreen (admin sees extra controls)
// Nothing facility-related lives in admin dashboard anymore.

// ── Announcement list (admin edit view) ────────────────────────────────────

class AdminAnnouncementListScreen extends StatefulWidget {
  const AdminAnnouncementListScreen({super.key});

  @override
  State<AdminAnnouncementListScreen> createState() =>
      _AdminAnnouncementListScreenState();
}

class _AdminAnnouncementListScreenState
    extends State<AdminAnnouncementListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _items = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      backgroundColor: const Color(0xFFF4FAF6),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
          child: Text('No announcements yet.',
              style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (_, i) => _AnnouncementTile(
            data: _items[i],
            onEdit: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAnnouncementScreen(
                      existing: _items[i]),
                ),
              );
              _load();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AdminAnnouncementScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New'),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile(
      {required this.data, required this.onEdit});
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final editCount = (data['edit_count'] as int?) ?? 0;
    final target = (data['target_type'] as String?) ?? 'all';
    final createdAt =
    DateTime.tryParse(data['created_at'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        title: Text(data['title'] as String? ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              data['body'] as String? ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SmallChip(
                  label:
                  target == 'all' ? 'All Users' : 'Selected',
                  color: const Color(0xFF1C894E),
                ),
                if (editCount > 0) ...[
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: 'Edited $editCount×',
                    color: Colors.orange.shade700,
                  ),
                ],
                const Spacer(),
                if (createdAt != null)
                  Text(
                    '${createdAt.day.toString().padLeft(2, '0')}/'
                        '${createdAt.month.toString().padLeft(2, '0')}/'
                        '${createdAt.year}',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined,
              color: Color(0xFF1C894E)),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF1C3A2A)),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C3A2A))),
            Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 10)),
      ],
    ),
  );
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold)),
  );
}