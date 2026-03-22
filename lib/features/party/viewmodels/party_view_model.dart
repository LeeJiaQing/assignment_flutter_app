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

  Future<void> loadSessions() async {
    _status = PartyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('party_sessions')
          .select('*, facilities(name), profiles(full_name)')
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

  Future<bool> joinSession(String sessionId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('party_members').insert({
        'session_id': sessionId,
        'user_id': userId,
      });

      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}