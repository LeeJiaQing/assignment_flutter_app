// lib/features/booking/widgets/payment_summary_card.dart
import 'package:flutter/material.dart';

import '../viewmodels/payment_view_model.dart';
import 'facility_thumb.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key, required this.item});

  final PaymentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 100,          // ← add explicit width
              height: 100,
              child: FacilityThumb(imageUrl: item.imageUrl, height: 100),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.facilityName} – ${item.courtName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1C3A2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Row(label: 'Date', value: item.formattedDate),
                  _Row(label: 'Time', value: item.timeLabel),
                  _Row(
                    label: 'Total',
                    value: 'RM ${item.pricePerSlot.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style:
          const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}