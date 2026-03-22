// lib/core/services/qr_service.dart
import '../supabase/supabase_config.dart';

/// Handles QR code validation logic.
/// The actual scanning widget lives in the features layer.
class QrService {
  /// Validates a scanned QR payload against the bookings table.
  /// Returns the booking row if valid, null if not found or cancelled.
  Future<Map<String, dynamic>?> validateBookingQr(String bookingId) async {
    final response = await supabase
        .from('bookings')
        .select('*, facilities(name), courts(name)')
        .eq('id', bookingId)
        .maybeSingle();

    if (response == null) return null;
    if (response['status'] == 'cancelled') return null;

    return response as Map<String, dynamic>;
  }

  /// Marks a booking as checked-in (or updates status as needed).
  Future<void> checkInBooking(String bookingId) async {
    await supabase
        .from('bookings')
        .update({'status': 'checked_in'}).eq('id', bookingId);
  }
}