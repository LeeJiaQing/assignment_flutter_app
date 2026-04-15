import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';

class HomeViewModel extends ChangeNotifier {
  String? _userName;
  bool _isLoading = false;

  String? get userName => _userName;
  bool get isLoading => _isLoading;

  Future<void> loadUserName() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      _userName = response?['full_name'] as String?;
    } catch (_) {
      _userName = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
