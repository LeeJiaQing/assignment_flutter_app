// lib/core/services/sync_service.dart
import 'dart:async';

import 'connectivity_service.dart';
import '../repositories/offline_booking_repository.dart';

/// Listens for connectivity-restored events and syncs pending bookings.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  StreamSubscription<bool>? _sub;
  OfflineBookingRepository? _bookingRepo;

  final _syncResultController =
  StreamController<SyncResult>.broadcast();

  Stream<SyncResult> get onSyncComplete => _syncResultController.stream;

  void init({required OfflineBookingRepository bookingRepository}) {
    _bookingRepo = bookingRepository;

    _sub = ConnectivityService.instance.onConnectivityChanged.listen(
          (isOnline) async {
        if (isOnline) {
          await _sync();
        }
      },
    );
  }

  Future<SyncResult> forcSync() => _sync();

  Future<SyncResult> _sync() async {
    final repo = _bookingRepo;
    if (repo == null) return SyncResult(synced: 0, failed: 0);

    final result = await repo.syncPendingBookings();
    _syncResultController.add(result);
    return result;
  }

  void dispose() {
    _sub?.cancel();
    _syncResultController.close();
  }
}