// lib/core/supabase/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _url = 'https://gykqkerhbrtkwnsgliii.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5a3FrZXJoYnJ0a3duc2dsaWlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDQ4MTYsImV4cCI6MjA4OTYyMDgxNn0.hrEASpb72xuhDKfaczV3Bzukr2v3_cwM56-VJ3O-rOY';

  static Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
}

/// Convenience getter — use [supabase] anywhere instead of
/// Supabase.instance.client.
SupabaseClient get supabase => Supabase.instance.client;