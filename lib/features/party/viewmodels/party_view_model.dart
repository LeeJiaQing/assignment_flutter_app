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
  final bool isEdited;

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
    this.isEdited = false,
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
    // is_edited column: defaults false if column doesn't exist
    isEdited: (json['is_edited'] as bool?) ?? false,
  );
}

class PartyViewModel extends ChangeNotifier {
  PartyStatus _status = PartyStatus.initial;
  List<PartySession> _sessions = [];
  String? _errorMessage;

  final Set<String> _joinedSessionIds = {};
  bool _joinedLoaded = false;

  PartyStatus get status => _status;
  List<PartySession> get sessions => _sessions;
  String? get errorMessage => _errorMessage;
  bool get joinedLoaded => _joinedLoaded;

  String? get currentUserId => supabase.auth.currentUser?.id;

  bool isJoined(String sessionId) {
    final uid = currentUserId;
    if (uid == null) return false;
    final session = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session != null && session.hostId == uid) return true;
    return _joinedSessionIds.contains(sessionId);
  }

  List<PartySession> get allSessions => _sessions;

  List<PartySession> get mySessions {
    final uid = currentUserId;
    if (uid == null) return [];
    return _sessions
        .where((s) => s.hostId == uid || _joinedSessionIds.contains(s.id))
        .toList();
  }

  Future<void> loadSessions() async {
    _status = PartyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('party_sessions')
          .select(
        '*, '
            'facilities!party_sessions_facility_id_fkey(name), '
            'profiles!party_sessions_host_id_fkey(full_name)',
      )
          .order('date', ascending: true);

      _sessions = (response as List<dynamic>)
          .map((json) => PartySession.fromJson(json as Map<String, dynamic>))
          .toList();
      _status = PartyStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = PartyStatus.error;
    }

    notifyListeners();
    await _loadJoinedSessionIds();
  }

  Future<void> _loadJoinedSessionIds() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        _joinedLoaded = true;
        notifyListeners();
        return;
      }
      final response = await supabase
          .from('party_members')
          .select('session_id')
          .eq('user_id', userId);

      _joinedSessionIds
        ..clear()
        ..addAll((response as List<dynamic>)
            .map((r) => r['session_id'] as String));
      _joinedLoaded = true;
      notifyListeners();
    } catch (_) {
      _joinedLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> joinSession(String sessionId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        _errorMessage = 'You must be signed in to join a session.';
        notifyListeners();
        return false;
      }

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

      await supabase.from('party_members').insert({
        'session_id': sessionId,
        'user_id': userId,
      });

      try {
        await supabase.rpc('increment_party_players', params: {
          'session_id_input': sessionId,
        });
      } catch (_) {
        final session = _sessions.firstWhere((s) => s.id == sessionId);
        await supabase.from('party_sessions').update({
          'current_players': session.currentPlayers + 1,
        }).eq('id', sessionId);
      }

      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}