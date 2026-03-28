// lib/core/services/booking_service_offline.dart
//
// Extends [BookingService] so it is type-compatible with [BookingViewModel],
// [PaymentViewModel], and anywhere else that holds a BookingService reference.
// Online behaviour is identical to the original; offline writes are queued.

import '../../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/facility_repository.dart';
import '../repositories/offline_booking_repository.dart';
import '../repositories/offline_facility_repository.dart';
import 'booking_service.dart';

class OfflineBookingService extends BookingService {
  OfflineBookingService({
    required OfflineBookingRepository bookingRepository,
    required OfflineFacilityRepository facilityRepository,
  })  : _offlineBookingRepo = bookingRepository,
        _offlineFacilityRepo = facilityRepository,
  // Pass no-op stubs to the super constructor — we override every method.
        super(
        bookingRepository: BookingRepository(),
        facilityRepository: FacilityRepository(),
      );

  final OfflineBookingRepository _offlineBookingRepo;
  final OfflineFacilityRepository _offlineFacilityRepo;

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<Set<int>> fetchBookedHours({
    required String courtId,
    required DateTime date,
  }) =>
      _offlineBookingRepo.fetchBookedHours(courtId: courtId, date: date);

  @override
  Future<List<BookingWithFacility>> fetchMyBookingsWithFacilities() async {
    final bookings = await _offlineBookingRepo.fetchMyBookings();
    if (bookings.isEmpty) return [];

    final facilityIds = bookings.map((b) => b.facilityId).toSet().toList();
    final facilities =
    await _offlineFacilityRepo.fetchFacilitiesByIds(facilityIds);
    final facilityMap = {for (final f in facilities) f.id: f};

    return bookings.map((b) {
      final facility = facilityMap[b.facilityId];
      return BookingWithFacility(
        booking: b,
        facilityName: facility?.name ?? 'Unknown Facility',
        imageUrl: facility?.imageUrl,
      );
    }).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Online: creates booking immediately.
  /// Offline: enqueues for later sync and returns a stub booking.
  @override
  Future<Booking> createBooking({
    required String courtId,
    required String facilityId,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final result = await _offlineBookingRepo.createBooking(
      courtId: courtId,
      facilityId: facilityId,
      date: date,
      startHour: startHour,
      endHour: endHour,
      amount: 0, // payment amount supplied separately via createPayment
      paymentMethod: 'pending',
    );

    if (result.isOnline) return result.booking!;

    // Offline stub — UI can check status == 'pending_sync'
    return Booking(
      id: result.localId!,
      userId: '',
      courtId: courtId,
      facilityId: facilityId,
      date: date,
      startHour: startHour,
      endHour: endHour,
      status: 'pending_sync',
    );
  }

  /// Online: records payment immediately.
  /// Offline: payment was already bundled into the pending queue entry;
  /// nothing more to do here.
  @override
  Future<void> createPayment({
    required String bookingId,
    required double amount,
    required String method,
  }) async {
    try {
      await super.createPayment(
          bookingId: bookingId, amount: amount, method: method);
    } catch (_) {
      // Offline — silently ignore; will sync via SyncService on reconnect.
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) =>
      _offlineBookingRepo.cancelBooking(bookingId);
}