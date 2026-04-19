import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../booking/booking_detail_screen.dart';
import '../booking/widgets/booking_card.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  late Future<List<BookingWithFacility>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUserBookings();
  }

  Future<List<BookingWithFacility>> _fetchUserBookings() async {
    final response = await supabase
        .from('bookings')
        .select('id, user_id, court_id, facility_id, date, start_hour, end_hour, status, facilities(name, image_url)')
        .eq('user_id', widget.user.id)
        .order('date', ascending: false);

    final rows = response as List<dynamic>;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final facility = map['facilities'] as Map<String, dynamic>?;
      return BookingWithFacility(
        booking: Booking.fromJson(map),
        facilityName: (facility?['name'] as String?) ?? 'Unknown Facility',
        imageUrl: facility?['image_url'] as String?,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text('${widget.user.fullName} Bookings'),
        backgroundColor: const Color(0xFFF4FAF6),
      ),
      body: FutureBuilder<List<BookingWithFacility>>(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString()),
                  TextButton(
                    onPressed: () => setState(() => _future = _fetchUserBookings()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetchUserBookings()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) {
                final item = bookings[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(
                          bookingWithFacility: item,
                          allowCancel: false,
                        ),
                      ),
                    ),
                    child: BookingCard(item: item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
