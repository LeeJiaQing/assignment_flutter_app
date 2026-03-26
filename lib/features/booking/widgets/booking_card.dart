// lib/features/booking/widgets/booking_card.dart
import 'package:flutter/material.dart';

import '../../../core/services/booking_service.dart';
import '../../../models/booking_model.dart';
import 'facility_thumb.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.item});

  final BookingWithFacility item;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;

    final formattedDate =
        '${booking.date.day.toString().padLeft(2, '0')}/'
        '${booking.date.month.toString().padLeft(2, '0')}/'
        '${booking.date.year}';

    final formattedTime =
        '${_fmt(booking.startHour)} – ${_fmt(booking.endHour)}';

    final statusColor = _statusColor(booking.status);
    final statusLabel =
        booking.status[0].toUpperCase() + booking.status.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left thumbnail image
          SizedBox(
            width: 100,
            height: 100,
            child: FacilityThumb(imageUrl: item.imageUrl, height: 100),
          ),
          // Right content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.facilityName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C3A2A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Date: $formattedDate'),
                  const SizedBox(height: 3),
                  _InfoRow(
                      icon: Icons.access_time_outlined,
                      text: 'Time: $formattedTime'),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(
                          label: 'Status: $statusLabel',
                          color: statusColor),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}