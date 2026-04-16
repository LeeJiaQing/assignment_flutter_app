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
      }).eq('id', id);

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
