// lib/features/facility/facility_detail_screen.dart
import 'package:flutter/material.dart';

import '../../models/facility_model.dart';
import '../booking/booking_schedule_screen.dart';
import 'facility_review_screen.dart';
import 'widgets/facility_card.dart';

class FacilityDetailScreen extends StatelessWidget {
  const FacilityDetailScreen({super.key, required this.facility});

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoSection(),
                const SizedBox(height: 16),
                _buildCourtsSection(),
                const SizedBox(height: 16),
                _buildActionButtons(context),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          facility.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        background: FacilityImage(imageUrl: facility.imageUrl),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facility Info',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3A2A)),
          ),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.location_on_outlined, text: facility.address),
          const SizedBox(height: 6),
          _DetailRow(icon: Icons.access_time_outlined, text: _hours),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.attach_money,
            text:
            'RM ${facility.pricePerSlot.toStringAsFixed(2)} per slot',
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.sports_tennis,
            text:
            '${facility.courts.length} court${facility.courts.length != 1 ? 's' : ''} available',
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.star_rounded,
            text: facility.averageRating > 0
                ? '${facility.averageRating.toStringAsFixed(1)} / 5.0'
                : 'No rating yet',
          ),
        ],
      ),
    );
  }

  Widget _buildCourtsSection() {
    if (facility.courts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Courts',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3A2A)),
          ),
          const SizedBox(height: 10),
          ...facility.courts.map(
                (court) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF1C894E), size: 16),
                  const SizedBox(width: 8),
                  Text(court.name,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6DCC98),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookingScheduleScreen(facility: facility),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Reviews'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1C894E),
              side: const BorderSide(color: Color(0xFF1C894E)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacilityReviewScreen(
                  facilityId: facility.id,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1C894E)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
              const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }
}
