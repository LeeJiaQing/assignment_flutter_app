// lib/core/repositories/booking_repository.dart
import '../../models/booking_model.dart';
import '../supabase/supabase_config.dart';

class BookingRepository {
  /// Returns all booked start_hours for a given court on a given date.
  Future<Set<int>> fetchBookedHours({
    required String courtId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await supabase
        .from('bookings')
        .select('start_hour')
        .eq('court_id', courtId)
        .eq('date', dateStr)
        .inFilter('status', ['pending', 'confirmed']);

    return (response as List<dynamic>)
        .map((row) => row['start_hour'] as int)
        .toSet();
  }

  /// Fetch all bookings belonging to the currently signed-in user.
  Future<List<Booking>> fetchMyBookings() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List<dynamic>)
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Insert one booking row and return the created [Booking].
  Future<Booking> createBooking({
    required String courtId,
    required String facilityId,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('bookings')
        .insert({
      'user_id': userId,
      'court_id': courtId,
      'facility_id': facilityId,
      'date': date.toIso8601String().substring(0, 10),
      'start_hour': startHour,
      'end_hour': endHour,
      'status': 'confirmed',
    })
        .select()
        .single();

    return Booking.fromJson(response);
  }

  /// Insert a payment row linked to a booking.
  Future<void> createPayment({
    required String bookingId,
    required double amount,
    required String method,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('payments').insert({
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'status': 'paid',
    });
  }

  /// Cancel a booking owned by the current user.
  Future<void> cancelBooking(String bookingId) async {
    await supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId)
        .eq('user_id', supabase.auth.currentUser!.id);
  }
}