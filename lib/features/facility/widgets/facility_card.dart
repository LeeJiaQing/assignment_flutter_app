// lib/features/facility/widgets/facility_card.dart
import 'package:flutter/material.dart';

import '../../../models/facility_model.dart';
import '../../booking/booking_schedule_screen.dart';

class FacilityCard extends StatelessWidget {
  const FacilityCard({super.key, required this.facility});

  final Facility facility;

  String get _hours {
    String fmt(int h) {
      final s = h < 12 ? 'AM' : 'PM';
      final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$v:00 $s';
    }
    return '${fmt(facility.openHour)} – ${fmt(facility.closeHour)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                FacilityImage(imageUrl: facility.imageUrl),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _PriceBadge(price: facility.pricePerSlot),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C3A2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: facility.address,
                    flexible: true,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoRow(icon: Icons.access_time_outlined, text: _hours),
                      const SizedBox(width: 10),
                      _InfoRow(
                        icon: Icons.star_rounded,
                        text: facility.averageRating > 0
                            ? facility.averageRating.toStringAsFixed(1)
                            : 'New',
                      ),
                      const SizedBox(width: 10),
                      _InfoRow(
                        icon: Icons.sports_tennis,
                        text: '${facility.courts.length} court${facility.courts.length != 1 ? 's' : ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookNowButton(facility: facility),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C894E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'RM ${price.toStringAsFixed(0)}/hr',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.flexible = false,
  });

  final IconData icon;
  final String text;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        flexible
            ? Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        )
            : Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
    return flexible ? Row(children: [Expanded(child: content)]) : content;
  }
}

class _BookNowButton extends StatelessWidget {
  const _BookNowButton({required this.facility});
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6DCC98),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScheduleScreen(facility: facility),
          ),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

class FacilityImage extends StatelessWidget {
  const FacilityImage({super.key, this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    height: 160,
    color: const Color(0xFFD6F0E0),
    child: const Center(
      child: Icon(Icons.sports_tennis, size: 48, color: Color(0xFF1C894E)),
    ),
  );
}