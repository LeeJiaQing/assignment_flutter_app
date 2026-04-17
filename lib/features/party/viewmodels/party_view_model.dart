// lib/features/party/viewmodels/party_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';

enum PartyStatus { initial, loading, loaded, error }

class PartySession {
  final String id;
  final String facilityId;
  final String facilityName;
  final String hostId;
  final String hostName;
  final DateTime date;
  final int startHour;
  final int endHour;
  final int maxPlayers;
  final int currentPlayers;
  final String sport;
  final String? notes;

  const PartySession({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.hostId,
    required this.hostName,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.sport,
    this.notes,
  });

  bool get isFull => currentPlayers >= maxPlayers;
  int get spotsLeft => maxPlayers - currentPlayers;

  factory PartySession.fromJson(Map<String, dynamic> json) => PartySession(
    id: json['id'] as String,
    facilityId: json['facility_id'] as String,
    facilityName: (json['facilities'] as Map?)?['name'] as String? ??
        'Unknown Facility',
    hostId: json['host_id'] as String,
    hostName: (json['profiles'] as Map?)?['full_name'] as String? ??
        'Unknown Host',
    date: DateTime.parse(json['date'] as String),
    startHour: json['start_hour'] as int,
    endHour: json['end_hour'] as int,
    maxPlayers: json['max_players'] as int,
    currentPlayers: json['current_players'] as int,
    sport: json['sport'] as String,
    notes: json['notes'] as String?,
  );
}

class PartyViewModel extends ChangeNotifier {
  PartyStatus _status = PartyStatus.initial;
  List<PartySession> _sessions = [];
  String? _errorMessage;

  PartyStatus get status => _status;
  List<PartySession> get sessions => _sessions;
  String? get errorMessage => _errorMessage;

  /// Returns the currently signed-in user's ID (null if not signed in).
  String? get currentUserId => supabase.auth.currentUser?.id;

  /// All sessions that the current user is NOT hosting.
  /// Used on the public party list so a host doesn't see their own session.
  List<PartySession> get sessionsExcludingOwn {
    final uid = currentUserId;
    if (uid == null) return _sessions;
    return _sessions.where((s) => s.hostId != uid).toList();
  }

  /// Sessions the current user is either hosting or has joined.
  /// Used on the "My Sessions" page.
  List<PartySession> get mySessions {
    final uid = currentUserId;
    if (uid == null) return [];
    return _sessions.where((s) => s.hostId == uid).toList();
  }

  Future<void> loadSessions() async {
    _status = PartyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use explicit FK hints so Supabase knows which relationship to use
      // for both `facilities` and `profiles`, avoiding the 406 ambiguity error.
      final response = await supabase
          .from('party_sessions')
          .select(
        '*, '
            'facilities!party_sessions_facility_id_fkey(name), '
            'profiles!party_sessions_host_id_fkey(full_name)',
      )
          .order('date', ascending: true);

      _sessions = (response as List<dynamic>)
          .map((json) =>
          PartySession.fromJson(json as Map<String, dynamic>))
          .toList();
      _status = PartyStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = PartyStatus.error;
    }

    notifyListeners();
  }

  /// Joins a session. Returns true on success, false otherwise.
  Future<bool> joinSession(String sessionId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'You must be signed in to join a session.';
        notifyListeners();
        return false;
      }

      // Check if already a member to avoid duplicate-key error.
      final existing = await supabase
          .from('party_members')
          .select('id')
          .eq('session_id', sessionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        _errorMessage = 'You have already joined this session.';
        notifyListeners();
        return false;
      }

      // Insert member row first.
      await supabase.from('party_members').insert({
        'session_id': sessionId,
        'user_id': userId,
      });

      // Increment current_players using a raw SQL expression so we don't
      // rely on the stale in-memory value (avoids race conditions too).
      await supabase.rpc('increment_party_players', params: {
        'session_id_input': sessionId,
      });

      await loadSessions();
      return true;
    } catch (e) {
      // If the RPC doesn't exist yet, fall back to a manual increment.
      if (e.toString().contains('increment_party_players') ||
          e.toString().contains('PGRST202') ||
          e.toString().contains('404')) {
        try {
          final session =
          _sessions.firstWhere((s) => s.id == sessionId);
          await supabase.from('party_sessions').update({
            'current_players': session.currentPlayers + 1,
          }).eq('id', sessionId);
          await loadSessions();
          return true;
        } catch (inner) {
          _errorMessage = inner.toString();
          notifyListeners();
          return false;
        }
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}