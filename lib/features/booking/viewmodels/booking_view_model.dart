// lib/features/booking/viewmodels/booking_view_model.dart
import 'package:flutter/material.dart';

import '../../../core/services/booking_service.dart';

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
      _bookings = await _service.fetchMyBookingsWithFacilities();
      _status = BookingListStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = BookingListStatus.error;
    }

    notifyListeners();
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
