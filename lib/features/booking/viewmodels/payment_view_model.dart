// lib/features/booking/viewmodels/payment_view_model.dart
// Booking reminders are now handled server-side via pg_cron +
// create_upcoming_booking_reminders() — no client-side scheduling needed.
import 'package:flutter/material.dart';

import '../../../core/local/local_booking_cache.dart';
import '../../../core/local/local_notification_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/booking_model.dart';
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
    _loadPaymentSetup();
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
    _persistPaymentSetup();
  }

  void saveCardNumber(String cardNo) {
    final digitsOnly = cardNo.replaceAll(RegExp(r'\s+'), '');
    _cardNumber = digitsOnly;
    notifyListeners();
    _persistPaymentSetup();
  }

  void saveBank(String bank) {
    _selectedBank = bank;
    notifyListeners();
    _persistPaymentSetup();
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
    return methodDetailLabel(_selectedMethod);
  }

  String methodDetailLabel(PayMethod method) {
    String maskPhone(String raw) {
      if (raw.length < 4) return raw;
      final end = raw.substring(raw.length - 4);
      return '${'*' * (raw.length - 4)}$end';
    }

    switch (method) {
      case PayMethod.tng:
        if ((_tngPhone ?? '').isEmpty) return 'Not set up yet';
        return maskPhone(_tngPhone!);
      case PayMethod.card:
        final card = _cardNumber ?? '';
        if (card.isEmpty) return 'Not set up yet';
        final suffix =
            card.length >= 4 ? card.substring(card.length - 4) : card;
        return '•••• •••• •••• $suffix';
      case PayMethod.banking:
        if ((_selectedBank ?? '').isEmpty) return 'Not set up yet';
        return 'Bank: $_selectedBank';
    }
  }

  Future<void> _loadPaymentSetup() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await supabase
          .from('user_payment_methods')
          .select('tng_phone, card_number, bank_name')
          .eq('user_id', userId)
          .limit(1);

      if ((rows as List<dynamic>).isEmpty) return;
      final data = rows.first as Map<String, dynamic>;
      _tngPhone = data['tng_phone'] as String?;
      _cardNumber = data['card_number'] as String?;
      _selectedBank = data['bank_name'] as String?;
      notifyListeners();
    } catch (_) {
      // Table may not exist yet in Supabase; keep local-only fallback.
    }
  }

  Future<void> _persistPaymentSetup() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('user_payment_methods').upsert({
        'user_id': userId,
        'tng_phone': _tngPhone,
        'card_number': _cardNumber,
        'bank_name': _selectedBank,
      });
    } catch (_) {
      // Keep flow working even when persistence layer isn't ready yet.
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
      final createdBookings = <Booking>[];

      // Retry persisting latest payment setup at checkout time.
      // This ensures edits made while offline are saved once connection returns.
      await _persistPaymentSetup();

      if (_useRewardPoints && _pointsToRedeem > 0) {
        await RewardPointsViewModel.redeemPoints(
          points: _pointsToRedeem,
          description: 'Redeemed for booking discount',
        );
      }

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final booking = await _service.createBooking(
          courtId: item.courtId,
          facilityId: item.facilityId,
          date: item.date,
          startHour: item.startHour,
          endHour: item.endHour,
        );
        createdBookings.add(booking);

        final double slotAmount =
        (item.pricePerSlot - (rewardDiscount / items.length))
            .clamp(0, double.infinity);

        await _service.createPayment(
          bookingId: booking.id,
          amount: slotAmount,
          method: _selectedMethod.dbValue,
        );

        // Schedule local notification reminder (30 min before)
        final slotStart = DateTime(
          item.date.year,
          item.date.month,
          item.date.day,
          item.startHour,
        );
        try {
          await LocalNotificationService.instance.scheduleBookingReminder(
            id: booking.id.hashCode.abs() % 100000,
            facilityName: item.facilityName,
            courtName: item.courtName,
            slotStart: slotStart,
          );
        } catch (_) {

        }
      }

      await RewardPointsViewModel.earnPoints(
        amount: grandTotal,
        description: 'Earned from booking at '
            '${items.isNotEmpty ? items.first.facilityName : "facility"}',
      );
      await _cacheCreatedBookings(createdBookings);
      await RewardPointsViewModel.refreshLocalCache();

      _status = PaymentStatus.success;
    } catch (e) {
      _errorMessage = _parsePaymentError(e);
      _status = PaymentStatus.error;
    }

    notifyListeners();
  }

  Future<void> _cacheCreatedBookings(List<Booking> bookings) async {
    if (bookings.isEmpty) return;
    try {
      await LocalBookingCache().saveBookings(bookings);
    } catch (_) {
      // Cache failure should not block successful payment.
    }
  }

  void resetError() {
    if (_status == PaymentStatus.error) {
      _status = PaymentStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _parsePaymentError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();
    final isNetworkIssue = normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network') ||
        normalized.contains('connection') ||
        normalized.contains('timed out');

    if (isNetworkIssue) {
      return 'No internet connection. Unable to complete payment.';
    }

    return 'Unable to complete payment. Please try again.';
  }
}
