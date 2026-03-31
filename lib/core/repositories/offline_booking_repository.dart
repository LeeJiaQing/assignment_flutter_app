// lib/core/repositories/offline_booking_repository.dart
import '../../models/booking_model.dart';
import '../local/local_booking_cache.dart';
import '../services/connectivity_service.dart';
import 'booking_repository.dart';

/// Wraps [BookingRepository] with SQLite caching and offline-queue support.
///
/// Strategy:
///   - Online reads  → Supabase, cache result.
///   - Offline reads → SQLite (ignore TTL).
///   - Online writes → Supabase directly.
///   - Offline writes → enqueue in pending_bookings table; sync on reconnect.
class OfflineBookingRepository {
  OfflineBookingRepository({
    BookingRepository? remote,
    LocalBookingCache? cache,
    ConnectivityService? connectivity,
  })  : _remote = remote ?? BookingRepository(),
        _cache = cache ?? LocalBookingCache(),
        _connectivity = connectivity ?? ConnectivityService.instance;

  final BookingRepository _remote;
  final LocalBookingCache _cache;
  final ConnectivityService _connectivity;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Set<int>> fetchBookedHours({
    required String courtId,
    required DateTime date,
  }) async {
    if (_connectivity.isOnline) {
      return _remote.fetchBookedHours(courtId: courtId, date: date);
    }
    // Offline: return empty set — the UI will show all slots as "available"
    // (conservative; prevents blocking users from at least seeing the schedule)
    return {};
  }

  Future<List<Booking>> fetchMyBookings() async {
    if (_connectivity.isOnline) {
      try {
        final bookings = await _remote.fetchMyBookings();
        await _cache.saveBookings(bookings);
        return bookings;
      } catch (_) {
        // fall through
      }
    }
    return _cache.getMyBookings(ignoreExpiry: true);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a booking immediately (online) or queues it (offline).
  /// Returns a [BookingResult] indicating whether the booking was created
  /// remotely or queued for later sync.
  Future<BookingResult> createBooking({
    required String courtId,
    required String facilityId,
    required DateTime date,
    required int startHour,
    required int endHour,
    required double amount,
    required String paymentMethod,
  }) async {
    if (_connectivity.isOnline) {
      try {
        final booking = await _remote.createBooking(
          courtId: courtId,
          facilityId: facilityId,
          date: date,
          startHour: startHour,
          endHour: endHour,
        );
        await _remote.createPayment(
          bookingId: booking.id,
          amount: amount,
          method: paymentMethod,
        );
        await _cache.saveBookings([booking]);
        return BookingResult.online(booking);
      } catch (e) {
        rethrow;
      }
    }

    // Offline → enqueue
    final localId = await _cache.enqueuePendingBooking(
      courtId: courtId,
      facilityId: facilityId,
      date: date,
      startHour: startHour,
      endHour: endHour,
      amount: amount,
      method: paymentMethod,
    );
    return BookingResult.queued(localId);
  }

  Future<void> cancelBooking(String bookingId) =>
      _remote.cancelBooking(bookingId);

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Call when connectivity is restored to push pending bookings to Supabase.
  Future<SyncResult> syncPendingBookings() async {
    if (!_connectivity.isOnline) return SyncResult(synced: 0, failed: 0);

    final pending = await _cache.getPendingBookings();
    int synced = 0;
    int failed = 0;

    for (final p in pending) {
      try {
        final booking = await _remote.createBooking(
          courtId: p.courtId,
          facilityId: p.facilityId,
          date: p.date,
          startHour: p.startHour,
          endHour: p.endHour,
        );
        await _remote.createPayment(
          bookingId: booking.id,
          amount: p.amount,
          method: p.method,
        );
        await _cache.markSynced(p.localId);
        synced++;
      } catch (_) {
        failed++;
      }
    }

    if (synced > 0) await _cache.deleteSynced();
    return SyncResult(synced: synced, failed: failed);
  }

  Future<int> pendingCount() async {
    final pending = await _cache.getPendingBookings();
    return pending.length;
  }
}

// ── Result types ───────────────────────────────────────────────────────────

enum BookingResultType { online, queued }

class BookingResult {
  final BookingResultType type;
  final Booking? booking;   // set when online
  final String? localId;   // set when queued

  const BookingResult._({required this.type, this.booking, this.localId});

  factory BookingResult.online(Booking b) =>
      BookingResult._(type: BookingResultType.online, booking: b);

  factory BookingResult.queued(String id) =>
      BookingResult._(type: BookingResultType.queued, localId: id);

  bool get isOnline => type == BookingResultType.online;
  bool get isQueued => type == BookingResultType.queued;
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}