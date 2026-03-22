// lib/features/booking/widgets/slot_legend.dart
import 'package:flutter/material.dart';

class SlotLegend extends StatelessWidget {
  const SlotLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(
            bg: const Color(0xFFD6F0E0),
            fg: const Color(0xFF1C894E),
            label: 'Available',
          ),
          const SizedBox(width: 24),
          _LegendDot(
            bg: const Color(0xFFFFD6D6),
            fg: const Color(0xFFB00020),
            label: 'Unavailable',
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.bg,
    required this.fg,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: fg.withOpacity(0.4)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}