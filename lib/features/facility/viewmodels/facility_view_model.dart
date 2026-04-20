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
  Set<String> _selectedSportTypes = {};
  RangeValues _priceRange = const RangeValues(0, 100);
  RangeValues _availableHourRange = const RangeValues(0, 24);
  double _minimumRating = 0;
  double? _selectedDistanceRadiusKm;
  String? _errorMessage;

  List<Facility> get facilities => List.unmodifiable(_facilities);
  FacilityStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  Set<String> get selectedSportTypes => Set.unmodifiable(_selectedSportTypes);
  RangeValues get priceRange => _priceRange;
  RangeValues get availableHourRange => _availableHourRange;
  double get minimumRating => _minimumRating;
  double? get selectedDistanceRadiusKm => _selectedDistanceRadiusKm;

  List<String> get categories => _facilities
      .map((f) => f.category)
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  double get maxFacilityPrice {
    if (_facilities.isEmpty) return 100;
    return _facilities
        .map((f) => f.pricePerSlot)
        .reduce((a, b) => a > b ? a : b)
        .clamp(10, 500)
        .toDouble();
  }

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

      final sportMatches = _selectedSportTypes.isEmpty ||
          _selectedSportTypes
              .map((e) => e.toLowerCase())
              .contains(f.category.toLowerCase());

      final priceMatches =
          f.pricePerSlot >= _priceRange.start && f.pricePerSlot <= _priceRange.end;

      final hourMatches = f.openHour <= _availableHourRange.start.round() &&
          f.closeHour >= _availableHourRange.end.round();

      final ratingMatches = f.averageRating >= _minimumRating;

      return textMatches &&
          categoryMatches &&
          sportMatches &&
          priceMatches &&
          hourMatches &&
          ratingMatches;
    }).toList();
  }

  Future<void> loadFacilities() async {
    _status = FacilityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _facilities = await _repo.fetchFacilities();
      _status = FacilityStatus.loaded;
      final dynamicMax = maxFacilityPrice;
      _priceRange = RangeValues(0, dynamicMax);
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

  void toggleSportType(String category) {
    final found = _selectedSportTypes
        .firstWhere((s) => s.toLowerCase() == category.toLowerCase(), orElse: () => '');
    if (found.isNotEmpty) {
      _selectedSportTypes.remove(found);
    } else {
      _selectedSportTypes.add(category);
    }
    notifyListeners();
  }

  void setPriceRange(RangeValues values) {
    _priceRange = values;
    notifyListeners();
  }

  void setAvailableHourRange(RangeValues values) {
    _availableHourRange = values;
    notifyListeners();
  }

  void setMinimumRating(double rating) {
    _minimumRating = rating;
    notifyListeners();
  }

  void setDistanceRadius(double? radiusKm) {
    _selectedDistanceRadiusKm = radiusKm;
    notifyListeners();
  }

  void clearAdvancedFilters() {
    _selectedSportTypes.clear();
    _selectedDistanceRadiusKm = null;
    _minimumRating = 0;
    _availableHourRange = const RangeValues(0, 24);
    _priceRange = RangeValues(0, maxFacilityPrice);
    notifyListeners();
  }
}
