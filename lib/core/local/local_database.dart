// lib/core/local/local_database.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static Database? _db;

  /// Call this once from main() before any database access.
  static void initFfiIfNeeded() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'courtnow_cache.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE facilities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        image_url TEXT,
        open_hour INTEGER NOT NULL,
        close_hour INTEGER NOT NULL,
        price_per_slot REAL NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE courts (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (facility_id) REFERENCES facilities(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        court_id TEXT NOT NULL,
        facility_id TEXT NOT NULL,
        date TEXT NOT NULL,
        start_hour INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        status TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE facility_images (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        remote_url TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_bookings (
        local_id TEXT PRIMARY KEY,
        court_id TEXT NOT NULL,
        facility_id TEXT NOT NULL,
        date TEXT NOT NULL,
        start_hour INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data_json TEXT,
        is_read INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_transaction_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        points INTEGER NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_message_cache (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_bookings (
          local_id TEXT PRIMARY KEY,
          court_id TEXT NOT NULL,
          facility_id TEXT NOT NULL,
          date TEXT NOT NULL,
          start_hour INTEGER NOT NULL,
          end_hour INTEGER NOT NULL,
          amount REAL NOT NULL,
          method TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notification_cache (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          data_json TEXT,
          is_read INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reward_transaction_cache (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          points INTEGER NOT NULL,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_message_cache (
          id TEXT PRIMARY KEY,
          channel_id TEXT NOT NULL,
          sender_id TEXT NOT NULL,
          sender_name TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
