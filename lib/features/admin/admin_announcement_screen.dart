// lib/features/admin/admin_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_config.dart';
import '../../models/user_model.dart';

// ── View Model ─────────────────────────────────────────────────────────────

enum AnnouncementStatus { idle, loading, success, error }

class AnnouncementViewModel extends ChangeNotifier {
  AnnouncementStatus _status = AnnouncementStatus.idle;
  List<UserProfile> _allUsers = [];
  List<UserProfile> _selectedUsers = [];
  String? _errorMessage;
  bool _loadingUsers = false;

  AnnouncementStatus get status => _status;
  List<UserProfile> get allUsers => _allUsers;
  List<UserProfile> get selectedUsers => _selectedUsers;
  bool get loadingUsers => _loadingUsers;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _status == AnnouncementStatus.loading;

  Future<void> loadUsers() async {
    _loadingUsers = true;
    notifyListeners();
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('full_name');
      _allUsers = (response as List<dynamic>)
          .map((j) => UserProfile.fromJson({
        ...j as Map<String, dynamic>,
        'email': (j as Map)['email'] ?? '',
      }))
          .toList();
    } catch (e) {
      debugPrint('AnnouncementViewModel.loadUsers: $e');
    }
    _loadingUsers = false;
    notifyListeners();
  }

  void toggleUser(UserProfile user) {
    if (_selectedUsers.any((u) => u.id == user.id)) {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  bool isSelected(UserProfile user) =>
      _selectedUsers.any((u) => u.id == user.id);

  Future<bool> createAnnouncement({
    required String title,
    required String body,
    required bool broadcastAll,
  }) async {
    _status = AnnouncementStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdBy = supabase.auth.currentUser?.id;

      // 1. Insert announcement
      final result = await supabase
          .from('announcements')
          .insert({
        'title': title.trim(),
        'body': body.trim(),
        'target_type': broadcastAll ? 'all' : 'selected',
        'target_user_ids': broadcastAll
            ? null
            : _selectedUsers.map((u) => u.id).toList(),
        'created_by': createdBy,
        'notification_sent': false,
      })
          .select('id')
          .single();

      final announcementId = result['id'] as String;

      // 2. Create per-user notification rows via DB function
      await supabase.rpc(
        'notify_announcement_targets',
        params: {'announcement_id': announcementId},
      );

      _status = AnnouncementStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AnnouncementStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = AnnouncementStatus.idle;
    _errorMessage = null;
    _selectedUsers.clear();
    notifyListeners();
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class AdminAnnouncementScreen extends StatelessWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnnouncementViewModel()..loadUsers(),
      child: const _AnnouncementView(),
    );
  }
}

class _AnnouncementView extends StatefulWidget {
  const _AnnouncementView();

  @override
  State<_AnnouncementView> createState() => _AnnouncementViewState();
}

class _AnnouncementViewState extends State<_AnnouncementView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _broadcastAll = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();

    // Auto-pop on success
    if (vm.status == AnnouncementStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent!'),
            backgroundColor: Color(0xFF1C894E),
          ),
        );
        Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(title: const Text('Create Announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Title ────────────────────────────────────────────────────
            _SectionHeader(
                icon: Icons.title, label: 'Announcement Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDeco(
                  hint: 'e.g. Court Maintenance on Saturday'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────────
            _SectionHeader(icon: Icons.message_outlined, label: 'Message'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: _inputDeco(
                hint: 'Write your announcement here…',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Target ───────────────────────────────────────────────────
            _SectionHeader(
                icon: Icons.people_outline, label: 'Send To'),
            const SizedBox(height: 8),
            _TargetToggle(
              broadcastAll: _broadcastAll,
              onChanged: (val) => setState(() => _broadcastAll = val),
            ),

            // ── User picker (shown only for 'selected') ───────────────────
            if (!_broadcastAll) ...[
              const SizedBox(height: 12),
              _UserPicker(
                vm: vm,
                searchQuery: _searchQuery,
                onSearchChanged: (q) =>
                    setState(() => _searchQuery = q),
              ),
            ],

            const SizedBox(height: 24),

            // ── Error ─────────────────────────────────────────────────────
            if (vm.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(vm.errorMessage!,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13)),
              ),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: vm.isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  vm.isSubmitting
                      ? 'Sending…'
                      : _broadcastAll
                      ? 'Send to All Users'
                      : 'Send to ${vm.selectedUsers.length} user${vm.selectedUsers.length != 1 ? 's' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C894E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: vm.isSubmitting
                    ? null
                    : (!_broadcastAll && vm.selectedUsers.isEmpty)
                    ? null
                    : () => _submit(context, vm),
              ),
            ),

            if (!_broadcastAll && vm.selectedUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Select at least one user to send to.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
      BuildContext context, AnnouncementViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    await vm.createAnnouncement(
      title: _titleController.text,
      body: _bodyController.text,
      broadcastAll: _broadcastAll,
    );
  }

  InputDecoration _inputDeco(
      {required String hint,
        bool alignLabelWithHint = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C894E)),
        ),
        alignLabelWithHint: alignLabelWithHint,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Target Toggle ──────────────────────────────────────────────────────────

class _TargetToggle extends StatelessWidget {
  const _TargetToggle(
      {required this.broadcastAll, required this.onChanged});
  final bool broadcastAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleChip(
          label: 'All Users',
          icon: Icons.public,
          selected: broadcastAll,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 10),
        _ToggleChip(
          label: 'Selected Users',
          icon: Icons.person_search_outlined,
          selected: !broadcastAll,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1C894E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF1C894E)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User Picker ────────────────────────────────────────────────────────────

class _UserPicker extends StatelessWidget {
  const _UserPicker({
    required this.vm,
    required this.searchQuery,
    required this.onSearchChanged,
  });
  final AnnouncementViewModel vm;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    if (vm.loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = vm.allUsers.where((u) {
      final q = searchQuery.toLowerCase();
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search users…',
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFF1C894E), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),

        const SizedBox(height: 8),

        // Selected count
        if (vm.selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${vm.selectedUsers.length} selected',
              style: const TextStyle(
                  color: Color(0xFF1C894E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),

        // User list
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: filtered.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('No users found.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final user = filtered[i];
              final selected = vm.isSelected(user);
              return ListTile(
                onTap: () => vm.toggleUser(user),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: selected
                      ? const Color(0xFF1C894E)
                      : const Color(0xFFD6F0E0),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF1C894E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                subtitle: Text(user.email,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                trailing: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1C894E)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1C894E)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1C894E)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1C3A2A),
          ),
        ),
      ],
    );
  }
}