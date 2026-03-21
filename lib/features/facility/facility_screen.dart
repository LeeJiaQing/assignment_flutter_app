// lib/features/facility/facility_screen.dart
//yb
import 'package:flutter/material.dart';

import '../../core/repositories/facility_repository.dart';
import '../../models/facility_model.dart';
import '../booking/booking_schedule_screen.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  final _repo = FacilityRepository();
  final _searchController = TextEditingController();

  late Future<List<Facility>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchFacilities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Facility> _filter(List<Facility> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((f) =>
    f.name.toLowerCase().contains(q) ||
        f.address.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder<List<Facility>>(
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
                          Text('Failed to load facilities',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(
                                    () => _future = _repo.fetchFacilities()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = _filter(snapshot.data ?? []);
                  if (filtered.isEmpty) {
                    return const Center(
                        child: Text('No facilities found.',
                            style: TextStyle(color: Colors.grey)));
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        setState(() => _future = _repo.fetchFacilities()),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _FacilityCard(facility: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C3A2A),
                height: 1.1)),
        Text('Your Game',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C894E),
                height: 1.1)),
      ],
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Badminton, Pickleball…',
          hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: Color(0xFF1C894E), size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              })
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Facility card
// ─────────────────────────────────────────────────────────────────────────────

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

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
              offset: const Offset(0, 3))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _FacilityImage(imageUrl: facility.imageUrl),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C894E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RM ${facility.pricePerSlot.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facility.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C3A2A))),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(facility.address,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(_hours,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 10),
                      const Icon(Icons.sports_tennis,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${facility.courts.length} court${facility.courts.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DCC98),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingScheduleScreen(facility: facility),
                        ),
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityImage extends StatelessWidget {
  final String? imageUrl;
  const _FacilityImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(imageUrl!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    height: 160,
    color: const Color(0xFFD6F0E0),
    child: const Center(
        child: Icon(Icons.sports_tennis,
            size: 48, color: Color(0xFF1C894E))),
  );
}