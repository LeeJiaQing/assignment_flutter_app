// lib/core/repositories/facility_repository.dart
import '../../models/facility_model.dart';
import '../supabase/supabase_config.dart';

class FacilityRepository {
  /// Fetch all facilities with their nested courts.
  Future<List<Facility>> fetchFacilities() async {
    final response = await supabase
        .from('facilities')
        .select('*, courts(*)')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => Facility.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single facility by id.
  Future<Facility> fetchFacility(String id) async {
    final response = await supabase
        .from('facilities')
        .select('*, courts(*)')
        .eq('id', id)
        .single();

    return Facility.fromJson(response);
  }

  /// Fetch multiple facilities by a list of ids.
  Future<List<Facility>> fetchFacilitiesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await supabase
        .from('facilities')
        .select(
        'id, name, address, image_url, open_hour, close_hour, price_per_slot')
        .inFilter('id', ids);

    return (response as List<dynamic>)
        .map((json) => Facility.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new facility.
  Future<Facility> createFacility(Map<String, dynamic> data) async {
    final response = await supabase
        .from('facilities')
        .insert(data)
        .select('*, courts(*)')
        .single();

    return Facility.fromJson(response);
  }

  /// Update an existing facility.
  Future<Facility> updateFacility(String id, Map<String, dynamic> data) async {
    final response = await supabase
        .from('facilities')
        .update(data)
        .eq('id', id)
        .select('*, courts(*)')
        .single();

    return Facility.fromJson(response);
  }

  /// Delete a facility.
  Future<void> deleteFacility(String id) async {
    await supabase.from('facilities').delete().eq('id', id);
  }
}