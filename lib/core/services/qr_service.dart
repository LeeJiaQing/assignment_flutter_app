// lib/core/services/qr_service.dart
import '../supabase/supabase_config.dart';

/// UUID v4 regex — only queries Supabase if the scanned value looks like a UUID.
final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

enum QrValidationStatus {
  valid,        // confirmed booking — can check in
  alreadyIn,   // already checked_in — show info, no action
  invalid,     // cancelled, not found, or not a UUID
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

      final bookingDate = DateTime.parse(response['date']);
      final now = DateTime.now();

      if (bookingDate.year != now.year ||
          bookingDate.month != now.month ||
          bookingDate.day != now.day) {
        return const QrValidationResult(status: QrValidationStatus.invalid);
      }

      if (response == null) {
        return const QrValidationResult(status: QrValidationStatus.invalid);
      }

      final bookingStatus = response['status'] as String? ?? '';

      if (bookingStatus == 'cancelled') {
        return const QrValidationResult(status: QrValidationStatus.invalid);
      }

      if (bookingStatus == 'confirmed') {
        return QrValidationResult(
          status: QrValidationStatus.valid,
          booking: response as Map<String, dynamic>,
        );
      }

      if (bookingStatus == 'checked_in') {
        return QrValidationResult(
          status: QrValidationStatus.alreadyIn,
          booking: response as Map<String, dynamic>,
        );
      }

      // everything else is invalid
      return const QrValidationResult(status: QrValidationStatus.invalid);

    } catch (_) {
      return const QrValidationResult(status: QrValidationStatus.invalid);
    }
  }

  /// Marks a booking as checked-in.
  Future<void> checkInBooking(String bookingId) async {
    final response = await supabase
        .from('bookings')
        .select('status')
        .eq('id', bookingId)
        .maybeSingle();
    if (response == null) return;
    final status = response['status'];
    if (status == 'checked_in') {
      return;
    }
    if (status != 'confirmed') {
      return;
    }
    await supabase
        .from('bookings')
        .update({'status': 'checked_in'})
        .eq('id', bookingId);
  }
}