// lib/features/booking/viewmodels/booking_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/supabase/supabase_config.dart';

enum BookingListStatus { initial, loading, loaded, error }

class BookingViewModel extends ChangeNotifier {
  BookingViewModel({required BookingService bookingService})
      : _service = bookingService;

  final BookingService _service;

  BookingListStatus _status = BookingListStatus.initial;
  List<BookingWithFacility> _bookings = [];
  String? _errorMessage;

  BookingListStatus get status => _status;
  List<BookingWithFacility> get bookings => _bookings;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookings() async {
    _status = BookingListStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Auto-complete past confirmed bookings before loading
      await _autoCompletePastBookings();

      _bookings = await _service.fetchMyBookingsWithFacilities();
      _status = BookingListStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = BookingListStatus.error;
    }

    notifyListeners();
  }

  /// Marks confirmed bookings as 'completed' if their end time has passed.
  Future<void> _autoCompletePastBookings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch confirmed bookings for this user
      final response = await supabase
          .from('bookings')
          .select('id, date, end_hour')
          .eq('user_id', userId)
          .eq('status', 'confirmed');

      final now = DateTime.now();
      final toComplete = <String>[];

      for (final row in response as List<dynamic>) {
        final date = DateTime.parse(row['date'] as String);
        final endHour = row['end_hour'] as int;
        final slotEnd = DateTime(
          date.year, date.month, date.day, endHour,
        );
        if (slotEnd.isBefore(now)) {
          toComplete.add(row['id'] as String);
        }
      }

      if (toComplete.isNotEmpty) {
        await supabase
            .from('bookings')
            .update({'status': 'completed'})
            .inFilter('id', toComplete);
      }
    } catch (_) {
      // Silently ignore — don't block the load
    }
  }

  /// Returns true if the booking can still be cancelled.
  /// Rules: must be confirmed/pending AND start time must be in the future.
  static bool canCancel(BookingWithFacility bwf) {
    final b = bwf.booking;
    if (b.status != 'confirmed' && b.status != 'pending') return false;
    final slotStart = DateTime(
      b.date.year, b.date.month, b.date.day, b.startHour,
    );
    return slotStart.isAfter(DateTime.now());
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _service.cancelBooking(bookingId);
      await loadBookings();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}