import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../models/user_model.dart';

enum AnnouncementStatus { idle, loading, success, error }

class AnnouncementViewModel extends ChangeNotifier {
  AnnouncementStatus _status = AnnouncementStatus.idle;
  List<UserProfile> _allUsers = [];
  final List<UserProfile> _selectedUsers = [];
  String? _errorMessage;
  bool _loadingUsers = false;

  AnnouncementStatus get status => _status;
  List<UserProfile> get allUsers => _allUsers;
  List<UserProfile> get selectedUsers => List.unmodifiable(_selectedUsers);
  bool get loadingUsers => _loadingUsers;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _status == AnnouncementStatus.loading;

  Future<void> loadUsers() async {
    _loadingUsers = true;
    notifyListeners();
    try {
      final myId = supabase.auth.currentUser?.id;
      final response = await supabase.from('profiles').select().order('full_name');
      _allUsers = (response as List<dynamic>)
          .map((j) => UserProfile.fromJson({
        ...j as Map<String, dynamic>,
        'email': (j as Map)['email'] ?? '',
      }))
          .where((u) => u.id != myId)
          .toList();
    } catch (e) {
      debugPrint('loadUsers: $e');
    }
    _loadingUsers = false;
    notifyListeners();
  }

  void setSelectedUsers(List<String> ids) {
    _selectedUsers.clear();
    _selectedUsers.addAll(_allUsers.where((u) => ids.contains(u.id)));
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
      final result = await supabase
          .from('announcements')
          .insert({
        'title': title.trim(),
        'body': body.trim(),
        'target_type': broadcastAll ? 'all' : 'selected',
        'target_user_ids':
        broadcastAll ? null : _selectedUsers.map((u) => u.id).toList(),
        'created_by': createdBy,
        'notification_sent': false,
      })
          .select('id')
          .single();

      await supabase
          .rpc('notify_announcement_targets', params: {'announcement_id': result['id']});

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

  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required bool broadcastAll,
  }) async {
    _status = AnnouncementStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await supabase.from('announcements').update({
        'title': title.trim(),
        'body': body.trim(),
        'target_type': broadcastAll ? 'all' : 'selected',
        'target_user_ids':
        broadcastAll ? null : _selectedUsers.map((u) => u.id).toList(),
        'notification_sent': false,
      }).eq('id', id);

      // Mark all existing notifications for this announcement as unread
      // so members see it as new again.
      // The data column stores the announcement_id as a JSON field.
      try {
        await supabase
            .from('user_notifications')
            .update({'is_read': false, 'title': title.trim(), 'body': body.trim()})
            .filter('data->>announcement_id', 'eq', id);
      } catch (_) {
        // If the data column filter syntax differs in your Supabase version,
        // fall back to re-running the notify RPC which will upsert notifications.
      }

      // Re-run notify RPC so any newly-targeted users also receive it
      try {
        await supabase.rpc('notify_announcement_targets',
            params: {'announcement_id': id});
      } catch (_) {
        // Non-fatal: RPC may not support upsert mode. The update above handles
        // existing recipients.
      }

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

  Future<bool> deleteAnnouncement(String id) async {
    try {
      // Delete linked notifications first so members stop seeing it
      await supabase
          .from('user_notifications')
          .delete()
          .filter('data->>announcement_id', 'eq', id);
    } catch (_) {
      // Non-fatal — proceed to delete the announcement itself
    }

    try {
      await supabase.from('announcements').delete().eq('id', id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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