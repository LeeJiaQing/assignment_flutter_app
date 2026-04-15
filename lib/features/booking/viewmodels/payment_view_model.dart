// lib/features/booking/viewmodels/payment_view_model.dart
// Booking reminders are now handled server-side via pg_cron +
// create_upcoming_booking_reminders() — no client-side scheduling needed.
import 'package:flutter/material.dart';

import '../../../core/services/booking_service.dart';
import '../../rewardPoints/viewmodels/reward_points_view_model.dart';

enum PayMethod { tng, card, banking }

extension PayMethodExt on PayMethod {
  String get dbValue => name;

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
        _originalTotal = grandTotal {
    _loadAvailablePoints();
  }

  final BookingService _service;
  final List<PaymentItem> items;
  final double _originalTotal;

  PayMethod _selectedMethod = PayMethod.tng;
  PaymentStatus _status = PaymentStatus.idle;
  String? _errorMessage;

  int _availablePoints = 0;
  bool _useRewardPoints = false;
  int _pointsToRedeem = 0;
  String? _tngPhone;
  String? _cardNumber;
  String? _selectedBank;

  PayMethod get selectedMethod => _selectedMethod;
  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _status == PaymentStatus.processing;

  int get availablePoints => _availablePoints;
  bool get useRewardPoints => _useRewardPoints;
  int get pointsToRedeem => _pointsToRedeem;
  String? get tngPhone => _tngPhone;
  String? get cardNumber => _cardNumber;
  String? get selectedBank => _selectedBank;

  double get rewardDiscount =>
      _useRewardPoints ? (_pointsToRedeem / 100.0) : 0.0;
  double get grandTotal =>
      (_originalTotal - rewardDiscount).clamp(0, double.infinity);

  Future<void> _loadAvailablePoints() async {
    _availablePoints = await RewardPointsViewModel.getAvailablePoints();
    final maxByOrder = (_originalTotal * 0.5 * 100).floor();
    _pointsToRedeem = _availablePoints < maxByOrder
        ? _availablePoints
        : maxByOrder;
    notifyListeners();
  }

  void toggleRewardPoints(bool use) {
    _useRewardPoints = use;
    notifyListeners();
  }

  void selectMethod(PayMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  void saveTngPhone(String phone) {
    _tngPhone = phone.trim();
    notifyListeners();
  }

  void saveCardNumber(String cardNo) {
    final digitsOnly = cardNo.replaceAll(RegExp(r'\s+'), '');
    _cardNumber = digitsOnly;
    notifyListeners();
  }

  void saveBank(String bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  bool get isSelectedMethodConfigured {
    switch (_selectedMethod) {
      case PayMethod.tng:
        return (_tngPhone ?? '').isNotEmpty;
      case PayMethod.card:
        return (_cardNumber ?? '').length >= 12;
      case PayMethod.banking:
        return (_selectedBank ?? '').isNotEmpty;
    }
  }

  String get selectedMethodSetupLabel {
    switch (_selectedMethod) {
      case PayMethod.tng:
        if ((_tngPhone ?? '').isEmpty) return 'Not set up yet';
        return 'Phone: $_tngPhone';
      case PayMethod.card:
        final card = _cardNumber ?? '';
        if (card.isEmpty) return 'Not set up yet';
        final suffix =
            card.length >= 4 ? card.substring(card.length - 4) : card;
        return 'Card ending •••• $suffix';
      case PayMethod.banking:
        if ((_selectedBank ?? '').isEmpty) return 'Not set up yet';
        return 'Bank: $_selectedBank';
    }
  }

  Future<void> processPayment() async {
    if (!isSelectedMethodConfigured) {
      _errorMessage =
          'Please set up ${_selectedMethod.label} details before paying.';
      _status = PaymentStatus.error;
      notifyListeners();
      return;
    }

    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useRewardPoints && _pointsToRedeem > 0) {
        await RewardPointsViewModel.redeemPoints(
          points: _pointsToRedeem,
          description: 'Redeemed for booking discount',
        );
      }

      for (final item in items) {
        final booking = await _service.createBooking(
          courtId: item.courtId,
          facilityId: item.facilityId,
          date: item.date,
          startHour: item.startHour,
          endHour: item.endHour,
        );

        final double slotAmount =
            (item.pricePerSlot - (rewardDiscount / items.length))
                .clamp(0, double.infinity);

        await _service.createPayment(
          bookingId: booking.id,
          amount: slotAmount,
          method: _selectedMethod.dbValue,
        );
        // Note: 10-minute booking reminders are fired server-side
        // by the pg_cron job calling create_upcoming_booking_reminders().
        // No client-side scheduling is needed here.
      }

      await RewardPointsViewModel.earnPoints(
        amount: grandTotal,
        description: 'Earned from booking at '
            '${items.isNotEmpty ? items.first.facilityName : "facility"}',
      );

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
