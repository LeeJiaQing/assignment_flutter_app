// lib/features/booking/viewmodels/payment_view_model.dart
import 'package:flutter/material.dart';

import '../../../../../core/services/booking_service.dart';

enum PayMethod { tng, card, banking }

extension PayMethodExt on PayMethod {
  String get dbValue => name; // 'tng' | 'card' | 'banking'

  String get label {
    switch (this) {
      case PayMethod.tng:
        return "Touch 'n Go eWallet";
      case PayMethod.card:
        return 'Credit/Debit Card';
      case PayMethod.banking:
        return 'Online Banking';
    }
  }
}

enum PaymentStatus { idle, processing, success, error }

class PaymentItem {
  final String facilityName;
  final String facilityId;
  final String courtId;
  final String courtName;
  final String? imageUrl;
  final DateTime date;
  final String formattedDate;
  final int startHour;
  final int endHour;
  final String timeLabel;
  final double pricePerSlot;

  const PaymentItem({
    required this.facilityName,
    required this.facilityId,
    required this.courtId,
    required this.courtName,
    this.imageUrl,
    required this.date,
    required this.formattedDate,
    required this.startHour,
    required this.endHour,
    required this.timeLabel,
    required this.pricePerSlot,
  });
}

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required BookingService bookingService,
    required List<PaymentItem> items,
    required double grandTotal,
  })  : _service = bookingService,
        items = items,
        grandTotal = grandTotal;

  final BookingService _service;

  final List<PaymentItem> items;
  final double grandTotal;

  PayMethod _selectedMethod = PayMethod.tng;
  PaymentStatus _status = PaymentStatus.idle;
  String? _errorMessage;

  PayMethod get selectedMethod => _selectedMethod;
  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _status == PaymentStatus.processing;

  void selectMethod(PayMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<void> processPayment() async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final item in items) {
        final booking = await _service.createBooking(
          courtId: item.courtId,
          facilityId: item.facilityId,
          date: item.date,
          startHour: item.startHour,
          endHour: item.endHour,
        );

        await _service.createPayment(
          bookingId: booking.id,
          amount: item.pricePerSlot,
          method: _selectedMethod.dbValue,
        );
      }
      _status = PaymentStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = PaymentStatus.error;
    }

    notifyListeners();
  }

  void resetError() {
    if (_status == PaymentStatus.error) {
      _status = PaymentStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }
}