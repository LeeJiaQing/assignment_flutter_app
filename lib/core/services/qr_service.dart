// lib/core/services/qr_service.dart
import '../supabase/supabase_config.dart';

/// UUID v4 regex — only queries Supabase if the scanned value looks like a UUID.
final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Handles QR code validation logic.
class QrService {
  /// Validates a scanned QR payload against the bookings table.
  ///
  /// Returns null (invalid) if:
  ///   • The payload is not a valid UUID — avoids the Supabase 400 crash.
  ///   • No matching booking exists in the DB.
  ///   • The booking is cancelled.
  Future<Map<String, dynamic>?> validateBookingQr(String payload) async {
    final trimmed = payload.trim();

    // Guard: only query Supabase if the value is a valid UUID.
    // Non-UUID QR codes (URLs, plain text, etc.) would cause a 400 error.
    if (!_uuidRegex.hasMatch(trimmed)) return null;

    try {
      final response = await supabase
          .from('bookings')
          .select('*, facilities(name), courts(name)')
          .eq('id', trimmed)
          .maybeSingle();

      if (response == null) return null;
      if (response['status'] == 'cancelled') return null;

      return response as Map<String, dynamic>;
    } catch (_) {
      // Any DB error (network, permissions, etc.) → treat as invalid.
      return null;
    }
  }

  /// Marks a booking as checked-in.
  Future<void> checkInBooking(String bookingId) async {
    await supabase
        .from('bookings')
        .update({'status': 'checked_in'}).eq('id', bookingId);
  }
}