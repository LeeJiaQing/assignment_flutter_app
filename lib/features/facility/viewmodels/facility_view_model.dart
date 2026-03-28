// lib/features/facility/viewmodels/facility_view_model.dart
import 'package:flutter/material.dart';

import '../../../../../core/repositories/offline_facility_repository.dart';
import '../../../../../models/facility_model.dart';

enum FacilityStatus { initial, loading, loaded, error }

class FacilityViewModel extends ChangeNotifier {
  FacilityViewModel({required OfflineFacilityRepository facilityRepository})
      : _repo = facilityRepository;

  final OfflineFacilityRepository _repo;

  FacilityStatus _status = FacilityStatus.initial;
  List<Facility> _facilities = [];
  String _query = '';
  String? _errorMessage;

  FacilityStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;

  List<Facility> get filteredFacilities {
    if (_query.trim().isEmpty) return _facilities;
    final q = _query.toLowerCase();
    return _facilities
        .where((f) =>
    f.name.toLowerCase().contains(q) ||
        f.address.toLowerCase().contains(q))
        .toList();
  }

  Future<void> loadFacilities() async {
    _status = FacilityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _facilities = await _repo.fetchFacilities();
      _status = FacilityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = FacilityStatus.error;
    }

    notifyListeners();
  }

  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
  }
}