// lib/core/repositories/booking_repository.dart
import '../../models/booking_model.dart';
import '../local/local_notification_service.dart';
import '../supabase/supabase_config.dart';

class BookingRepository {
  /// Returns all booked start_hours for a given court on a given date.
  /// This intentionally fetches ALL users' bookings (not just the current
  /// user's) so the slot grid correctly shows unavailable slots.
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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not signed in');

    final dateStr = date.toIso8601String().substring(0, 10);

    // If this user has previously cancelled the exact same slot,
    // reactivate that record instead of inserting a brand-new row.
    // This supports re-booking a slot the user cancelled earlier,
    // even when DB-level uniqueness exists on slot columns.
    final cancelled = await supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .eq('court_id', courtId)
        .eq('facility_id', facilityId)
        .eq('date', dateStr)
        .eq('start_hour', startHour)
        .eq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1);

    if ((cancelled as List<dynamic>).isNotEmpty) {
      final bookingId =
          (cancelled.first as Map<String, dynamic>)['id'] as String;
      final reactivated = await supabase
          .from('bookings')
          .update({
            'end_hour': endHour,
            'status': 'confirmed',
          })
          .eq('id', bookingId)
          .eq('user_id', userId)
          .select()
          .single();

      return Booking.fromJson(reactivated);
    }

    final response = await supabase
        .from('bookings')
        .insert({
      'user_id': userId,
      'court_id': courtId,
      'facility_id': facilityId,
      'date': dateStr,
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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not signed in');

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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not signed in');

    final bookingRows = await supabase
        .from('bookings')
        .select('id, facility_id, status')
        .eq('id', bookingId)
        .eq('user_id', userId)
        .limit(1);

    if ((bookingRows as List<dynamic>).isEmpty) return;

    final booking = bookingRows.first as Map<String, dynamic>;
    final status = booking['status'] as String? ?? '';
    if (status == 'cancelled') return;

    await supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId)
        .eq('user_id', userId);

    try {
      final paymentRows = await supabase
          .from('payments')
          .select('amount')
          .eq('booking_id', bookingId)
          .eq('user_id', userId)
          .limit(1);

      if ((paymentRows as List<dynamic>).isEmpty) return;

      final amount =
          (paymentRows.first as Map<String, dynamic>)['amount'] as num;
      final paidAmount = amount.toDouble();
      final earnedPointsToReverse = paidAmount.floor();

      final facilityId = booking['facility_id'] as String?;
      if (facilityId == null) return;

      final facility = await supabase
          .from('facilities')
          .select('name, price_per_slot')
          .eq('id', facilityId)
          .single();

      final facilityName = (facility['name'] as String?) ?? 'facility';
      final fullPrice = (facility['price_per_slot'] as num).toDouble();
      final discount = (fullPrice - paidAmount).clamp(0, fullPrice);
      final pointsToRefund = (discount * 100).round();
      final deductedLabel =
          'Deducted from cancelled booking at $facilityName';
      final returnedLabel =
          'Returned from cancelled booking at $facilityName';

      if (pointsToRefund > 0) {
        await supabase.from('reward_transactions').insert({
          'user_id': userId,
          'points': pointsToRefund,
          'description': returnedLabel,
        });
      }

      if (earnedPointsToReverse > 0) {
        await supabase.from('reward_transactions').insert({
          'user_id': userId,
          'points': -earnedPointsToReverse,
          'description': deductedLabel,
        });
      }
      try {
        await LocalNotificationService.instance.cancelReminder(
          bookingId.hashCode.abs() % 100000,
        );
      } catch (_) {}
    } catch (_) {
      // Do not fail cancellation if rewards reconciliation fails.
    }
  }
}
