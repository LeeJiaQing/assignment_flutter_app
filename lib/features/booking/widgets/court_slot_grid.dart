// lib/features/booking/widgets/court_slot_grid.dart
import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../models/facility_model.dart';

const _kAvailableChip = Color(0xFFD6F0E0);
const _kAvailableText = Color(0xFF1C894E);
const _kSelectedChip = Color(0xFF1C894E);
const _kUnavailableChip = Color(0xFFFFD6D6);
const _kUnavailableText = Color(0xFFB00020);
const _kExpiredChip = Color(0xFFE0E0E0);
const _kExpiredText = Color(0xFF9E9E9E);

class CourtSlotGrid extends StatelessWidget {
  const CourtSlotGrid({
    super.key,
    required this.court,
    required this.slots,
    required this.isLoading,
    required this.isSlotSelected,
    required this.onSlotTap,
  });

  final Court court;
  final List<TimeSlot> slots;
  final bool isLoading;
  final bool Function(String slotId) isSlotSelected;
  final void Function(Court court, TimeSlot slot) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map((s) => _SlotChip(
                slot: s,
                isSelected: isSlotSelected(s.id),
                onTap: () => onSlotTap(court, s),
              ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effective = slot.effectiveStatus(DateTime.now());

    Color chipColor;
    Color textColor;
    bool tappable = false;

    if (isSelected) {
      chipColor = _kSelectedChip;
      textColor = Colors.white;
      tappable = true;
    } else {
      switch (effective) {
        case SlotStatus.available:
          chipColor = _kAvailableChip;
          textColor = _kAvailableText;
          tappable = true;
          break;
        case SlotStatus.booked:
          chipColor = _kUnavailableChip;
          textColor = _kUnavailableText;
          break;
        case SlotStatus.expired:
          chipColor = _kExpiredChip;
          textColor = _kExpiredText;
          break;
      }
    }

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          slot.label,
          style: TextStyle(
            color: textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}