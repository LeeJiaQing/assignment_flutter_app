// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'dart:io';

/// Lightweight connectivity checker — no external package needed.
/// Tries to open a socket to a public DNS server.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Call once from main() after app starts.
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _check(); // immediate check
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _controller.close();
  }

  Future<bool> checkNow() async {
    await _check();
    return _isOnline;
  }

  Future<void> _check() async {
    final result = await _hasConnection();
    if (result != _isOnline) {
      _isOnline = result;
      _controller.add(_isOnline);
    }
  }

  Future<bool> _hasConnection() async {
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}