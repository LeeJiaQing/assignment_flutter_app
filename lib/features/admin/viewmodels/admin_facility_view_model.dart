// lib/features/admin/viewmodels/admin_facility_view_model.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/repositories/facility_repository.dart';
import '../../../models/facility_model.dart';

enum AdminFacilityStatus { initial, loading, loaded, error }

class AdminFacilityViewModel extends ChangeNotifier {
  AdminFacilityViewModel({required FacilityRepository facilityRepository})
      : _repo = facilityRepository;

  final FacilityRepository _repo;

  AdminFacilityStatus _status = AdminFacilityStatus.initial;
  List<Facility> _facilities = [];
  String? _errorMessage;

  AdminFacilityStatus get status => _status;
  List<Facility> get facilities => _facilities;
  String? get errorMessage => _errorMessage;

  Future<void> loadFacilities() async {
    _status = AdminFacilityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _facilities = await _repo.fetchFacilities();
      _status = AdminFacilityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AdminFacilityStatus.error;
    }

    notifyListeners();
  }

  Future<bool> createFacility(Map<String, dynamic> data) async {
    try {
      final facility = await _repo.createFacility(data);
      _facilities.add(facility);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadFacilityImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final path = await _repo.uploadFacilityImage(
        bytes: bytes,
        fileName: fileName,
      );
      return path;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateFacility(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repo.updateFacility(id, data);
      final index = _facilities.indexWhere((f) => f.id == id);
      if (index != -1) _facilities[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFacility(String id) async {
    try {
      await _repo.deleteFacility(id);
      _facilities.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
