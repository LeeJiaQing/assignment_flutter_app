// lib/features/admin/admin_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/announcement_view_model.dart';

class AdminAnnouncementScreen extends StatelessWidget {
  const AdminAnnouncementScreen({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnnouncementViewModel()..loadUsers(),
      child: _Body(existing: existing),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late bool _broadcastAll;
  String _searchQuery = '';
  bool _vmInitialized = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl =
        TextEditingController(text: e?['title'] as String? ?? '');
    _bodyCtrl =
        TextEditingController(text: e?['body'] as String? ?? '');
    _broadcastAll =
        (e?['target_type'] as String? ?? 'all') == 'all';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _maybeInitVm(AnnouncementViewModel vm) {
    if (_vmInitialized || vm.loadingUsers || vm.allUsers.isEmpty)
      return;
    final e = widget.existing;
    if (e != null && e['target_type'] == 'selected') {
      final ids = (e['target_user_ids'] as List<dynamic>?)
          ?.map((v) => v.toString())
          .toList() ??
          [];
      vm.setSelectedUsers(ids);
    }
    _vmInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();
    _maybeInitVm(vm);

    if (vm.status == AnnouncementStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'Updated — recipients will see it as unread.'
              : 'Announcement sent!'),
          backgroundColor: const Color(0xFF1C894E),
        ));
        Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(
            _isEdit ? 'Edit Announcement' : 'New Announcement'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit)
              _InfoBanner(
                icon: Icons.edit_notifications_outlined,
                color: Colors.orange.shade700,
                message:
                'Saving changes will mark this announcement as unread for all recipients.',
              ),

            _FieldLabel(icon: Icons.title, text: 'Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration:
              _deco('e.g. Court Maintenance on Saturday'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            _FieldLabel(
                icon: Icons.message_outlined, text: 'Message'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: _deco('Write your announcement here…',
                  alignHint: true),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            _FieldLabel(
                icon: Icons.people_outline, text: 'Send To'),
            const SizedBox(height: 10),
            _TargetToggle(
              broadcastAll: _broadcastAll,
              onChanged: (v) => setState(() => _broadcastAll = v),
            ),

            if (!_broadcastAll) ...[
              const SizedBox(height: 12),
              _UserPicker(
                vm: vm,
                searchQuery: _searchQuery,
                onSearchChanged: (q) =>
                    setState(() => _searchQuery = q),
              ),
            ],

            const SizedBox(height: 20),

            if (vm.errorMessage != null)
              _InfoBanner(
                icon: Icons.error_outline,
                color: Colors.red.shade700,
                message: vm.errorMessage!,
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: vm.isSubmitting
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Icon(_isEdit
                    ? Icons.save_outlined
                    : Icons.send_outlined),
                label: Text(vm.isSubmitting
                    ? (_isEdit ? 'Saving…' : 'Sending…')
                    : _isEdit
                    ? 'Save Changes'
                    : _broadcastAll
                    ? 'Send to All Users'
                    : vm.selectedUsers.isEmpty
                    ? 'Select users first'
                    : 'Send to ${vm.selectedUsers.length} user${vm.selectedUsers.length != 1 ? 's' : ''}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C894E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                  const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: vm.isSubmitting ||
                    (!_broadcastAll &&
                        vm.selectedUsers.isEmpty &&
                        !_isEdit)
                    ? null
                    : () => _submit(context, vm),
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
    if (_isEdit) {
      await vm.updateAnnouncement(
        id: widget.existing!['id'] as String,
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        broadcastAll: _broadcastAll,
      );
    } else {
      await vm.createAnnouncement(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        broadcastAll: _broadcastAll,
      );
    }
  }

  InputDecoration _deco(String hint, {bool alignHint = false}) =>
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
        alignLabelWithHint: alignHint,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      );
}

// ── Target Toggle ──────────────────────────────────────────────────────────

class _TargetToggle extends StatelessWidget {
  const _TargetToggle(
      {required this.broadcastAll, required this.onChanged});
  final bool broadcastAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ToggleChip(
          label: 'All Users',
          icon: Icons.public,
          selected: broadcastAll,
          onTap: () => onChanged(true)),
      const SizedBox(width: 10),
      _ToggleChip(
          label: 'Selected Users',
          icon: Icons.person_search_outlined,
          selected: !broadcastAll,
          onTap: () => onChanged(false)),
    ],
  );
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
  Widget build(BuildContext context) => GestureDetector(
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
              color:
              selected ? Colors.white : Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    ),
  );
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
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search users…',
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 13),
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
            contentPadding:
            const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        if (vm.selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${vm.selectedUsers.length} selected',
                style: const TextStyle(
                    color: Color(0xFF1C894E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
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
            separatorBuilder: (_, __) => Divider(
                height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final u = filtered[i];
              final sel = vm.isSelected(u);
              return ListTile(
                onTap: () => vm.toggleUser(u),
                contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: sel
                      ? const Color(0xFF1C894E)
                      : const Color(0xFFD6F0E0),
                  child: Text(
                    u.fullName.isNotEmpty
                        ? u.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: sel
                          ? Colors.white
                          : const Color(0xFF1C894E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(u.fullName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                subtitle: Text(u.email,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                trailing: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1C894E)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF1C894E)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: sel
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(
      {required this.icon,
        required this.color,
        required this.message});
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  fontSize: 12, color: Colors.black87)),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF1C894E)),
      const SizedBox(width: 6),
      Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1C3A2A))),
    ],
  );
}