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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentViewModel>();

    if (vm.status == PaymentStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showSuccessDialog(context, vm.grandTotal);
      });
    }

    if (vm.status == PaymentStatus.error && vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
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
          const SizedBox(height: 16),

          // ── Reward Points Section ─────────────────────────────────────
          if (vm.availablePoints > 0) ...[
            _RewardPointsCard(vm: vm),
            const SizedBox(height: 16),
          ],

          // ── Order Summary ─────────────────────────────────────────────
          _OrderSummaryCard(vm: vm),
          const SizedBox(height: 20),

          // ── Payment Method ────────────────────────────────────────────
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking has been confirmed!\n'
              'Total paid: RM ${total.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.stars, color: Color(0xFFFFC107), size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reward points have been added to your account!',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF1C894E)),
                  ),
                ),
              ],
            ),
          ],
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

class _RewardPointsCard extends StatelessWidget {
  const _RewardPointsCard({required this.vm});
  final PaymentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final discount = vm.rewardDiscount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vm.useRewardPoints
              ? const Color(0xFF1C894E)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFC107), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Reward Points',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Switch(
                value: vm.useRewardPoints,
                onChanged: context.read<PaymentViewModel>().toggleRewardPoints,
                activeColor: const Color(0xFF1C894E),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You have ${vm.availablePoints} pts available',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (vm.useRewardPoints) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '− ${vm.pointsToRedeem} pts = − RM ${discount.toStringAsFixed(2)} discount',
                style: const TextStyle(
                  color: Color(0xFF1C894E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.vm});
  final PaymentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final discount = vm.rewardDiscount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1C3A2A))),
          const SizedBox(height: 12),
          _SummaryRow(
              label: 'Subtotal',
              value:
                  'RM ${vm.items.fold(0.0, (s, i) => s + i.pricePerSlot).toStringAsFixed(2)}'),
          if (discount > 0)
            _SummaryRow(
              label: 'Reward Discount',
              value: '− RM ${discount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF1C894E),
            ),
          const Divider(),
          _SummaryRow(
            label: 'Total',
            value: 'RM ${vm.grandTotal.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold ? Colors.black87 : Colors.grey,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ??
                      (bold ? Colors.black87 : Colors.black87))),
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
