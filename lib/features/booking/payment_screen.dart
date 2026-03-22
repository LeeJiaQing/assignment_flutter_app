// lib/features/booking/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import 'viewmodels/payment_view_model.dart';
import 'widgets/pay_method_card.dart';
import 'widgets/payment_summary_card.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.items,
    required this.grandTotal,
  });

  final List<PaymentItem> items;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentViewModel(
        bookingService: BookingService(
          bookingRepository: BookingRepository(),
          facilityRepository: FacilityRepository(),
        ),
        items: items,
        grandTotal: grandTotal,
      ),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView();

  static const _kBg = Color(0xFFF0F5F1);
  static const _kGreenLight = Color(0xFF6DCC98);
  static const _kExpiredChip = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentViewModel>();

    // React to success/error state changes
    if (vm.status == PaymentStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog(context, vm.grandTotal);
      });
    }

    if (vm.status == PaymentStatus.error && vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${vm.errorMessage}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        vm.resetError();
      });
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: const Text(
          'Payment Details',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          ...vm.items.map((i) => PaymentSummaryCard(item: i)),
          const SizedBox(height: 20),
          const Text(
            'Select Payment Method',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...PayMethod.values.map(
                (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PayMethodCard(
                method: m,
                selectedMethod: vm.selectedMethod,
                onChanged: vm.selectMethod,
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _PaymentBottomBar(
        grandTotal: vm.grandTotal,
        isProcessing: vm.isProcessing,
        onPay: vm.isProcessing
            ? null
            : () => context.read<PaymentViewModel>().processPayment(),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1C894E)),
            SizedBox(width: 8),
            Text('Booking Confirmed'),
          ],
        ),
        content: Text(
          'Your booking has been confirmed!\n'
              'Total paid: RM ${total.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Done',
                style: TextStyle(color: Color(0xFF1C894E))),
          ),
        ],
      ),
    );
  }
}

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.grandTotal,
    required this.isProcessing,
    required this.onPay,
  });

  final double grandTotal;
  final bool isProcessing;
  final VoidCallback? onPay;

  static const _kGreenLight = Color(0xFF6DCC98);
  static const _kExpiredChip = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreenLight,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: _kExpiredChip,
          ),
          onPressed: onPay,
          child: isProcessing
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.black54),
          )
              : Text(
            'Make Payment   RM ${grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}