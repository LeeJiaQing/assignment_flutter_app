// lib/core/services/qr_service.dart
import '../supabase/supabase_config.dart';

/// UUID v4 regex — only queries Supabase if the scanned value looks like a UUID.
final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

enum QrValidationStatus {
  valid,      // confirmed booking — can check in
  alreadyIn,  // already checked_in — show info, no action
  invalid,    // cancelled, not found, or not a UUID
}

class QrValidationResult {
  final QrValidationStatus status;
  final Map<String, dynamic>? booking;

  const QrValidationResult({required this.status, this.booking});

  bool get isValid => status == QrValidationStatus.valid;
  bool get isAlreadyIn => status == QrValidationStatus.alreadyIn;
  bool get isInvalid => status == QrValidationStatus.invalid;
}

class QrService {
  /// Validates a scanned QR payload.
  ///
  /// Returns a [QrValidationResult] describing whether the booking is valid,
  /// already checked-in, or invalid (not a UUID, not found, cancelled).
  Future<QrValidationResult> validateBookingQr(String payload) async {
    final trimmed = payload.trim();

    // Guard: reject anything that's not a UUID — avoids Supabase 400 errors.
    if (!_uuidRegex.hasMatch(trimmed)) {
      return const QrValidationResult(status: QrValidationStatus.invalid);
    }

    try {
      final response = await supabase
          .from('bookings')
          .select('*, facilities(name), courts(name)')
          .eq('id', trimmed)
          .maybeSingle();

      if (response == null) {
        return const QrValidationResult(status: QrValidationStatus.invalid);
      }

      final bookingStatus = response['status'] as String? ?? '';

      if (bookingStatus == 'cancelled') {
        return const QrValidationResult(status: QrValidationStatus.invalid);
      }

      if (bookingStatus == 'checked_in') {
        return QrValidationResult(
          status: QrValidationStatus.alreadyIn,
          booking: response as Map<String, dynamic>,
        );
      }

      // confirmed / pending / completed → valid, can check in
      return QrValidationResult(
        status: QrValidationStatus.valid,
        booking: response as Map<String, dynamic>,
      );
    } catch (_) {
      return const QrValidationResult(status: QrValidationStatus.invalid);
    }
  }

  /// Marks a booking as checked-in and returns the updated booking.
  /// Throws an exception if the update fails or the booking is not found.
  Future<void> checkInBooking(String bookingId) async {
    // Verify the booking exists and is in a state that allows check-in.
    final booking = await supabase
        .from('bookings')
        .select('id, status')
        .eq('id', bookingId)
        .maybeSingle();

    if (booking == null) {
      throw Exception('Booking not found.');
    }

    final currentStatus = booking['status'] as String? ?? '';

    if (currentStatus == 'checked_in') {
      // Already checked in — no need to update, not an error.
      return;
    }

    if (currentStatus == 'cancelled') {
      throw Exception('Cannot check in a cancelled booking.');
    }

    // Perform the actual update.
    await supabase
        .from('bookings')
        .update({'status': 'checked_in'})
        .eq('id', bookingId);

    // Verify the update worked by re-reading the status.
    final updated = await supabase
        .from('bookings')
        .select('status')
        .eq('id', bookingId)
        .maybeSingle();

    final newStatus = updated?['status'] as String? ?? '';
    if (newStatus != 'checked_in') {
      throw Exception(
          'Check-in update did not persist. Check Supabase RLS policies — '
              'ensure the admin role can update the bookings table.');
    }
  }
}