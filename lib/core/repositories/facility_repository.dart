// lib/core/repositories/facility_repository.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/facility_model.dart';
import '../supabase/supabase_config.dart';

class FacilityRepository {
  static const _bucket = 'facilities';

  List<String>? _extractCourtNames(Map<String, dynamic> data) {
    if (!data.containsKey('court_names')) return null;
    final raw = data.remove('court_names');
    if (raw is! List) return const [];
    return raw
        .map((court) => court.toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> _replaceCourts({
    required String facilityId,
    required List<String> courtNames,
  }) async {
    await supabase.from('courts').delete().eq('facility_id', facilityId);

    if (courtNames.isEmpty) return;

    final rows = courtNames
        .map((name) => {'facility_id': facilityId, 'name': name})
        .toList();
    await supabase.from('courts').insert(rows);
  }

  /// Converts a stored path (e.g. "court1.jpg") into a public URL.
  /// If the value is already a full URL (legacy rows), it is returned as-is.
  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  /// Converts a raw JSON map into a [Facility], resolving the image path.
  Facility _fromJson(Map<String, dynamic> json) {
    final raw = Facility.fromJson(json);
    return Facility(
      id: raw.id,
      name: raw.name,
      address: raw.address,
      imageUrl: _resolveImageUrl(raw.imageUrl),
      openHour: raw.openHour,
      closeHour: raw.closeHour,
      pricePerSlot: raw.pricePerSlot,
      category: raw.category,
      courts: raw.courts,
      averageRating: raw.averageRating,
    );
  }

  /// Fetch a single facility row (without courts) and return it.
  /// Used internally after write operations to avoid RLS issues with joins.
  Future<Facility> _fetchById(String id) async {
    // First fetch the facility row itself
    final facilityRow = await supabase
        .from('facilities')
        .select('id, name, address, image_url, open_hour, close_hour, price_per_slot, category, average_rating')
        .eq('id', id)
        .maybeSingle();

    if (facilityRow == null) {
      // Row not found or RLS blocked read — return a minimal stub so callers
      // don't crash. The local AdminFacilityViewModel already has the data.
      throw Exception('Facility not found after save (id=$id). '
          'Check Supabase RLS policies allow admin SELECT on facilities.');
    }

    // Fetch courts separately — avoids the nested join that sometimes
    // triggers PGRST116 when RLS policies differ between tables.
    List<Court> courts = [];
    try {
      final courtRows = await supabase
          .from('courts')
          .select('id, facility_id, name')
          .eq('facility_id', id);
      courts = (courtRows as List<dynamic>)
          .map((c) => Court.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Courts are non-critical for the admin edit flow; ignore errors.
    }

    final json = {
      ...(facilityRow as Map<String, dynamic>),
      'courts': courts.map((c) => {'id': c.id, 'facility_id': c.facilityId, 'name': c.name}).toList(),
    };
    return _fromJson(json);
  }

  /// Fetch all facilities with their nested courts.
  Future<List<Facility>> fetchFacilities() async {
    final response = await supabase
        .from('facilities')
        .select('*, courts(*)')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => _fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single facility by id.
  Future<Facility> fetchFacility(String id) async {
    return _fetchById(id);
  }

  /// Fetch multiple facilities by a list of ids.
  Future<List<Facility>> fetchFacilitiesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await supabase
        .from('facilities')
        .select('id, name, address, image_url, open_hour, close_hour, price_per_slot, category, average_rating')
        .inFilter('id', ids);

    return (response as List<dynamic>)
        .map((json) => _fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new facility.
  /// Uses upsert-style insert and re-fetches separately to avoid RLS join issues.
  Future<Facility> createFacility(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final courtNames = _extractCourtNames(payload);

    // Insert without requesting a join — just get back the id.
    final response = await supabase
        .from('facilities')
        .insert(payload)
        .select('id')
        .single();

    final id = (response as Map<String, dynamic>)['id'] as String;
    if (courtNames != null) {
      await _replaceCourts(facilityId: id, courtNames: courtNames);
    }
    return _fetchById(id);
  }

  /// Update an existing facility.
  /// Re-fetches the row separately after update to avoid PGRST116.
  Future<Facility> updateFacility(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final courtNames = _extractCourtNames(payload);

    await supabase
        .from('facilities')
        .update(payload)
        .eq('id', id);

    if (courtNames != null) {
      await _replaceCourts(facilityId: id, courtNames: courtNames);
    }
    return _fetchById(id);
  }

  /// Delete a facility.
  Future<void> deleteFacility(String id) async {
    await supabase.from('facilities').delete().eq('id', id);
  }

  /// Uploads a facility image and returns the stored object path.
  Future<String> uploadFacilityImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return path;
  }
}
