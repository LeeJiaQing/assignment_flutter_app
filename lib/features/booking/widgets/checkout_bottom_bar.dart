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

    // Group slots by courtId so each court gets its own row
    final Map<String, List<SelectedSlot>> byCourt = {};
    for (final s in slots) {
      byCourt.putIfAbsent(s.courtId, () => []).add(s);
    }

    return Container(
      color: Colors.white,
      // Cap height so the bar never swallows more than ~40% of the screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.40,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection) ...[
            // Scrollable summary area
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: $formattedDate',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    // One row per court
                    ...byCourt.entries.map((entry) {
                      final courtSlots = entry.value;
                      final courtName = courtSlots.first.courtName;
                      final timeLabels =
                      courtSlots.map((s) => s.slot.label).join(', ');
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                '$courtName: $timeLabels',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: RM ${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}