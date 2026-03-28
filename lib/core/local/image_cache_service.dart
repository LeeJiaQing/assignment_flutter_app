// lib/core/local/image_cache_service.dart
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'local_database.dart';

/// Caches remote facility images on disk so they load while offline.
class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService instance = ImageCacheService._();

  final _db = LocalDatabase.instance;
  final _uuid = const Uuid();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns local file path if cached, otherwise downloads then caches.
  /// Returns null if offline and no cached file exists.
  Future<String?> resolve(String facilityId, String remoteUrl) async {
    // 1. Check DB for existing cached path
    final cached = await _getCachedPath(remoteUrl);
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    // 2. Try downloading
    try {
      final filePath = await _download(facilityId, remoteUrl);
      await _saveRecord(facilityId, filePath, remoteUrl);
      return filePath;
    } catch (_) {
      // Offline or download failed — return whatever we have (may be stale)
      return cached;
    }
  }

  /// Prefetch a list of (facilityId, url) pairs in the background.
  Future<void> prefetch(List<MapEntry<String, String>> entries) async {
    for (final e in entries) {
      await resolve(e.key, e.value).catchError((_) => null);
    }
  }

  /// Delete cached file and DB record for a URL.
  Future<void> evict(String remoteUrl) async {
    final path = await _getCachedPath(remoteUrl);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();

      final db = await _db.database;
      await db.delete('facility_images',
          where: 'remote_url = ?', whereArgs: [remoteUrl]);
    }
  }

  /// Wipe all cached images older than [maxAge].
  Future<void> evictOlderThan(Duration maxAge) async {
    final db = await _db.database;
    final cutoff = DateTime.now()
        .subtract(maxAge)
        .millisecondsSinceEpoch;

    final rows = await db.query(
      'facility_images',
      where: 'cached_at < ?',
      whereArgs: [cutoff],
    );

    for (final r in rows) {
      final path = r['file_path'] as String;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    await db.delete('facility_images',
        where: 'cached_at < ?', whereArgs: [cutoff]);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String?> _getCachedPath(String remoteUrl) async {
    final db = await _db.database;
    final rows = await db.query(
      'facility_images',
      columns: ['file_path'],
      where: 'remote_url = ?',
      whereArgs: [remoteUrl],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['file_path'] as String;
  }

  Future<String> _download(String facilityId, String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dir = await _cacheDir();
    final ext = _extension(url);
    final fileName = '${facilityId}_${_uuid.v4()}$ext';
    final filePath = p.join(dir.path, fileName);

    await File(filePath).writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> _saveRecord(
      String facilityId, String filePath, String remoteUrl) async {
    final db = await _db.database;
    await db.insert(
      'facility_images',
      {
        'id': _uuid.v4(),
        'facility_id': facilityId,
        'file_path': filePath,
        'remote_url': remoteUrl,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Directory> _cacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'facility_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _extension(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.webp')) return '.webp';
    return '.jpg'; // default
  }
}