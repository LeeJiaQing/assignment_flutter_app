// lib/features/booking/booking_screen.dart
//jq
import 'package:flutter/material.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../models/booking_model.dart';
import '../../models/facility_model.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingRepo = BookingRepository();
  final _facilityRepo = FacilityRepository();

  late Future<List<_BookingDisplay>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadBookings();
  }

  // Fetch bookings + facility names together
  Future<List<_BookingDisplay>> _loadBookings() async {
    final bookings = await _bookingRepo.fetchMyBookings();
    if (bookings.isEmpty) return [];

    // Fetch all unique facilities in one query
    final facilityIds = bookings.map((b) => b.facilityId).toSet().toList();
    final facilities = await _facilityRepo.fetchFacilitiesByIds(facilityIds);
    final facilityMap = {for (final f in facilities) f.id: f};

    return bookings.map((b) {
      final facility = facilityMap[b.facilityId];
      return _BookingDisplay(
        booking: b,
        facilityName: facility?.name ?? 'Unknown Facility',
        imageUrl: facility?.imageUrl,
      );
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C894E),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFC8DFC3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: FutureBuilder<List<_BookingDisplay>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('Failed to load bookings',
                              style:
                              TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No bookings yet',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BookingCard(display: items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display model — booking + resolved facility info
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDisplay {
  final Booking booking;
  final String facilityName;
  final String? imageUrl;

  const _BookingDisplay({
    required this.booking,
    required this.facilityName,
    this.imageUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────────────────────

class BookingCard extends StatelessWidget {
  final _BookingDisplay display;
  const BookingCard({super.key, required this.display});

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final booking = display.booking;

    final formattedDate =
        '${booking.date.day.toString().padLeft(2, '0')}/'
        '${booking.date.month.toString().padLeft(2, '0')}/'
        '${booking.date.year}';

    final formattedTime = '${_fmt(booking.startHour)} – ${_fmt(booking.endHour)}';

    Color statusColor;
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    final statusLabel =
        booking.status[0].toUpperCase() + booking.status.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Facility image ──────────────────────────────────────────────
          _FacilityThumb(imageUrl: display.imageUrl),

          // ── Details ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.facilityName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C3A2A),
                  ),
                ),
                const SizedBox(height: 6),
                _infoRow(Icons.calendar_today_outlined, formattedDate),
                const SizedBox(height: 4),
                _infoRow(Icons.access_time_outlined, formattedTime),
                const SizedBox(height: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Text(text,
          style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Facility thumbnail — network URL with placeholder fallback
// ─────────────────────────────────────────────────────────────────────────────

class _FacilityThumb extends StatelessWidget {
  final String? imageUrl;
  const _FacilityThumb({this.imageUrl});

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
      child: Icon(Icons.sports_tennis,
          size: 48, color: Color(0xFF1C894E)),
    ),
  );
}