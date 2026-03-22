// lib/features/booking/widgets/checkout_bottom_bar.dart
import 'package:flutter/material.dart';

import '../viewmodels/booking_schedule_view_model.dart';

class CheckoutBottomBar extends StatelessWidget {
  const CheckoutBottomBar({
    super.key,
    required this.selectedSlots,
    required this.formattedDate,
    required this.grandTotal,
    required this.onCheckout,
  });

  final Map<String, SelectedSlot> selectedSlots;
  final String formattedDate;
  final double grandTotal;
  final VoidCallback? onCheckout;

  static const _kGreenLight = Color(0xFF6DCC98);
  static const _kExpiredChip = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final slots = selectedSlots.values.toList();
    final hasSelection = slots.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection) ...[
            Text(
              'Facility: ${slots.first.courtName}',
              style: const TextStyle(fontSize: 13),
            ),
            Text('Date: $formattedDate',
                style: const TextStyle(fontSize: 13)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Time: ${slots.map((s) => s.slot.label).join(', ')}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Total: RM ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreenLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: _kExpiredChip,
              ),
              onPressed: hasSelection ? onCheckout : null,
              child: const Text(
                'Checkout',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}