// lib/core/repositories/facility_repository.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/facility_model.dart';
import '../supabase/supabase_config.dart';

class FacilityRepository {
  static const _bucket = 'facilities';

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
    );
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
    final response = await supabase
        .from('facilities')
        .select('*, courts(*)')
        .eq('id', id)
        .single();

    return _fromJson(response);
  }

  /// Fetch multiple facilities by a list of ids.
  Future<List<Facility>> fetchFacilitiesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await supabase
        .from('facilities')
        .select('''
          id,
          name,
          address,
          image_url,
          open_hour,
          close_hour,
          price_per_slot,
          category
        ''')
        .inFilter('id', ids);

    return (response as List<dynamic>)
        .map((json) => _fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new facility.
  Future<Facility> createFacility(Map<String, dynamic> data) async {
    final response = await supabase
        .from('facilities')
        .insert(data)
        .select('*, courts(*)')
        .single();

    return _fromJson(response);
  }

  /// Update an existing facility.
  Future<Facility> updateFacility(String id, Map<String, dynamic> data) async {
    final response = await supabase
        .from('facilities')
        .update(data)
        .eq('id', id)
        .select('*, courts(*)')
        .single();

    return _fromJson(response);
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
