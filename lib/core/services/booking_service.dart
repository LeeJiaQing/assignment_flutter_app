// lib/core/services/booking_service.dart
import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/facility_repository.dart';

/// Combines [BookingRepository] and [FacilityRepository] to provide
/// richer booking data (e.g. bookings enriched with facility names).
class BookingService {
  BookingService({
    required BookingRepository bookingRepository,
    required FacilityRepository facilityRepository,
  })  : _bookingRepo = bookingRepository,
        _facilityRepo = facilityRepository;

  final BookingRepository _bookingRepo;
  final FacilityRepository _facilityRepo;

  Future<Set<int>> fetchBookedHours({
    required String courtId,
    required DateTime date,
  }) =>
      _bookingRepo.fetchBookedHours(courtId: courtId, date: date);

  /// Returns bookings enriched with facility information.
  Future<List<BookingWithFacility>> fetchMyBookingsWithFacilities() async {
    final bookings = await _bookingRepo.fetchMyBookings();
    if (bookings.isEmpty) return [];

    final facilityIds = bookings.map((b) => b.facilityId).toSet().toList();
    final facilities = await _facilityRepo.fetchFacilitiesByIds(facilityIds);
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

  Future<Booking> createBooking({
    required String courtId,
    required String facilityId,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) =>
      _bookingRepo.createBooking(
        courtId: courtId,
        facilityId: facilityId,
        date: date,
        startHour: startHour,
        endHour: endHour,
      );

  Future<void> createPayment({
    required String bookingId,
    required double amount,
    required String method,
  }) =>
      _bookingRepo.createPayment(
          bookingId: bookingId, amount: amount, method: method);

  Future<void> cancelBooking(String bookingId) =>
      _bookingRepo.cancelBooking(bookingId);
}

/// Booking enriched with resolved facility data — used only in the UI layer.
class BookingWithFacility {
  final Booking booking;
  final String facilityName;
  final String? imageUrl;

  const BookingWithFacility({
    required this.booking,
    required this.facilityName,
    this.imageUrl,
  });
}