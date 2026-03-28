// lib/core/repositories/offline_facility_repository.dart
import '../../models/facility_model.dart';
import '../local/image_cache_service.dart';
import '../local/local_facility_cache.dart';
import '../services/connectivity_service.dart';
import 'facility_repository.dart';

/// Wraps [FacilityRepository] with SQLite caching.
///
/// Strategy:
///   - Online  → fetch from Supabase, persist to SQLite, prefetch images.
///   - Offline → serve from SQLite (ignores TTL).
class OfflineFacilityRepository {
  OfflineFacilityRepository({
    FacilityRepository? remote,
    LocalFacilityCache? cache,
    ImageCacheService? imageCacheService,
    ConnectivityService? connectivity,
  })  : _remote = remote ?? FacilityRepository(),
        _cache = cache ?? LocalFacilityCache(),
        _images = imageCacheService ?? ImageCacheService.instance,
        _connectivity = connectivity ?? ConnectivityService.instance;

  final FacilityRepository _remote;
  final LocalFacilityCache _cache;
  final ImageCacheService _images;
  final ConnectivityService _connectivity;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<List<Facility>> fetchFacilities() async {
    if (_connectivity.isOnline) {
      try {
        final facilities = await _remote.fetchFacilities();
        await _cache.saveFacilities(facilities);
        _prefetchImages(facilities);
        return facilities;
      } catch (_) {
        // Network error despite being "online" — fall through to cache
      }
    }

    // Offline or network error — serve stale cache (ignore TTL)
    return _cache.getFacilities(ignoreExpiry: true);
  }

  Future<Facility> fetchFacility(String id) async {
    if (_connectivity.isOnline) {
      try {
        final facility = await _remote.fetchFacility(id);
        await _cache.saveFacilities([facility]);
        if (facility.imageUrl != null) {
          _images.resolve(facility.id, facility.imageUrl!);
        }
        return facility;
      } catch (_) {
        // fall through
      }
    }

    final cached = await _cache.getFacility(id);
    if (cached != null) return cached;
    throw Exception('No cached data for facility $id and device is offline.');
  }

  Future<List<Facility>> fetchFacilitiesByIds(List<String> ids) async {
    if (_connectivity.isOnline) {
      try {
        final facilities = await _remote.fetchFacilitiesByIds(ids);
        await _cache.saveFacilities(facilities);
        return facilities;
      } catch (_) {
        // fall through
      }
    }

    final all = await _cache.getFacilities(ignoreExpiry: true);
    return all.where((f) => ids.contains(f.id)).toList();
  }

  Future<Facility> createFacility(Map<String, dynamic> data) =>
      _remote.createFacility(data);

  Future<Facility> updateFacility(String id, Map<String, dynamic> data) =>
      _remote.updateFacility(id, data);

  Future<void> deleteFacility(String id) => _remote.deleteFacility(id);

  /// Returns a local file path for an image if cached, otherwise the remote
  /// URL. Callers can pass either to Image.file / Image.network.
  Future<String?> resolveImagePath(String facilityId, String remoteUrl) =>
      _images.resolve(facilityId, remoteUrl);

  // ── Private ────────────────────────────────────────────────────────────────

  void _prefetchImages(List<Facility> facilities) {
    final entries = facilities
        .where((f) => f.imageUrl != null)
        .map((f) => MapEntry(f.id, f.imageUrl!))
        .toList();
    _images.prefetch(entries);
  }
}