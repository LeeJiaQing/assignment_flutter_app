// lib/features/facility/viewmodels/facility_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/repositories/offline_facility_repository.dart';
import '../../../models/facility_model.dart';

enum FacilityStatus { initial, loading, loaded, error }

class FacilityViewModel extends ChangeNotifier {
  FacilityViewModel({required OfflineFacilityRepository facilityRepository})
      : _repo = facilityRepository;

  final OfflineFacilityRepository _repo;

  FacilityStatus _status = FacilityStatus.initial;
  List<Facility> _facilities = [];
  String _query = '';
  String? _selectedCategory;
  String? _errorMessage;
  List<Facility> get facilities => List.unmodifiable(_facilities);

  FacilityStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  List<String> get categories => _facilities
      .map((f) => f.category)
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<Facility> get filteredFacilities {
    final q = _query.toLowerCase();
    final selectedCategory = _selectedCategory?.trim().toLowerCase();
    return _facilities.where((f) {
      final textMatches = q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          f.address.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q);
      final categoryMatches = selectedCategory == null ||
          f.category.trim().toLowerCase() == selectedCategory;
      return textMatches && categoryMatches;
    }).toList();
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

  void toggleCategory(String category) {
    if (_selectedCategory?.toLowerCase() == category.toLowerCase()) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    final normalized = category?.trim();
    _selectedCategory = (normalized == null || normalized.isEmpty)
        ? null
        : normalized;
    notifyListeners();
  }
}
