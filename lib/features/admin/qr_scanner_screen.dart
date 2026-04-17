// lib/features/admin/qr_scanner_screen.dart
//
// Admin QR Scanner screen.
// Uses mobile_scanner for live camera scanning.
// Falls back to a manual-entry input if the package is unavailable.
//
// Add to pubspec.yaml:
//   mobile_scanner: ^5.2.3
//
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/qr_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final QrService _qrService = QrService();

  bool _isProcessing = false;
  _ScanResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final booking = await _qrService.validateBookingQr(code);
      if (!mounted) return;

      if (booking == null) {
        setState(() {
          _lastResult = _ScanResult.invalid(code);
          _isProcessing = false;
        });
        _showResultSheet(context, _lastResult!);
      } else {
        setState(() {
          _lastResult = _ScanResult.valid(booking, code);
          _isProcessing = false;
        });
        _showResultSheet(context, _lastResult!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastResult = _ScanResult.error(e.toString());
        _isProcessing = false;
      });
      _showResultSheet(context, _lastResult!);
    }
  }

  void _resumeScanning() {
    setState(() {
      _lastResult = null;
      _isProcessing = false;
    });
    _controller.start();
  }

  void _showResultSheet(BuildContext context, _ScanResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(
        result: result,
        qrService: _qrService,
        onDismiss: () {
          Navigator.pop(context);
          _resumeScanning();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'QR Scanner',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, value, __) => Icon(
                value.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: _controller.toggleTorch,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, value, __) => Icon(
                value.cameraDirection == CameraFacing.back
                    ? Icons.camera_front
                    : Icons.camera_rear,
                color: Colors.white,
              ),
            ),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scan frame
          _ScanOverlay(isProcessing: _isProcessing),

          // Bottom hint
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isProcessing
                        ? 'Validating booking…'
                        : 'Point camera at a booking QR code',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Manual entry fallback
                TextButton(
                  onPressed: () => _showManualEntry(context),
                  child: const Text(
                    'Enter Booking ID manually',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    _controller.stop();
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Booking ID'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Paste or type booking ID',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C894E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final id = ctrl.text.trim();
              if (id.isEmpty) {
                _resumeScanning();
                return;
              }
              await _onDetect(
                BarcodeCapture(
                  barcodes: [
                    Barcode(rawValue: id),
                  ],
                ),
              );
            },
            child: const Text('Validate'),
          ),
        ],
      ),
    );
  }
}

// ── Scan overlay ───────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.isProcessing});
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.transparent),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result sheet ───────────────────────────────────────────────────────────

class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.result,
    required this.qrService,
    required this.onDismiss,
  });
  final _ScanResult result;
  final QrService qrService;
  final VoidCallback onDismiss;

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  bool _checkingIn = false;
  bool _checkedIn = false;

  Future<void> _checkIn() async {
    if (widget.result.bookingId == null) return;
    setState(() => _checkingIn = true);
    try {
      await widget.qrService.checkInBooking(widget.result.bookingId!);
      setState(() {
        _checkingIn = false;
        _checkedIn = true;
      });
    } catch (e) {
      setState(() => _checkingIn = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Status icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 36),
          ),
          const SizedBox(height: 16),

          // Status title
          Text(
            _statusTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _statusColor,
            ),
          ),
          const SizedBox(height: 8),

          // Booking details (if valid)
          if (widget.result.isValid && widget.result.booking != null)
            ..._buildBookingDetails(widget.result.booking!),

          if (!widget.result.isValid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.result.errorMessage ??
                    'The scanned QR code is not a valid or active booking.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

          const SizedBox(height: 24),

          // Check-in button (valid bookings only)
          if (widget.result.isValid && !_checkedIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _checkingIn
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_checkingIn ? 'Checking in…' : 'Mark as Checked In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C894E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _checkingIn ? null : _checkIn,
              ),
            ),

          if (_checkedIn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F0E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Color(0xFF1C894E), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Successfully Checked In!',
                    style: TextStyle(
                        color: Color(0xFF1C894E),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onDismiss,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
              Text(_checkedIn ? 'Scan Next' : 'Scan Again'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookingDetails(Map<String, dynamic> booking) {
    final facilityName =
        (booking['facilities'] as Map?)?['name'] as String? ?? '—';
    final courtName =
        (booking['courts'] as Map?)?['name'] as String? ?? '—';
    final date = booking['date'] as String? ?? '—';
    final startHour = booking['start_hour'] as int? ?? 0;
    final endHour = booking['end_hour'] as int? ?? 0;
    final status = booking['status'] as String? ?? '—';

    String fmt(int h) {
      final s = h < 12 ? 'AM' : 'PM';
      final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$v:00 $s';
    }

    return [
      const SizedBox(height: 12),
      _DetailRow(label: 'Facility', value: facilityName),
      _DetailRow(label: 'Court', value: courtName),
      _DetailRow(label: 'Date', value: date),
      _DetailRow(label: 'Time', value: '${fmt(startHour)} – ${fmt(endHour)}'),
      _DetailRow(
        label: 'Status',
        value: status[0].toUpperCase() + status.substring(1),
        valueColor: status == 'confirmed'
            ? Colors.green
            : status == 'checked_in'
            ? Colors.blue
            : Colors.orange,
      ),
    ];
  }

  Color get _statusColor {
    if (widget.result.isError) return Colors.orange.shade700;
    return widget.result.isValid
        ? const Color(0xFF1C894E)
        : Colors.red.shade700;
  }

  IconData get _statusIcon {
    if (widget.result.isError) return Icons.error_outline;
    return widget.result.isValid
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;
  }

  String get _statusTitle {
    if (widget.result.isError) return 'Scan Error';
    return widget.result.isValid ? 'Valid Booking' : 'Invalid Booking';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label,
        required this.value,
        this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan result model ──────────────────────────────────────────────────────

class _ScanResult {
  final bool isValid;
  final bool isError;
  final Map<String, dynamic>? booking;
  final String? bookingId;
  final String? errorMessage;

  const _ScanResult._({
    required this.isValid,
    required this.isError,
    this.booking,
    this.bookingId,
    this.errorMessage,
  });

  factory _ScanResult.valid(Map<String, dynamic> booking, String id) =>
      _ScanResult._(
          isValid: true,
          isError: false,
          booking: booking,
          bookingId: id);

  factory _ScanResult.invalid(String id) =>
      _ScanResult._(isValid: false, isError: false, bookingId: id);

  factory _ScanResult.error(String message) => _ScanResult._(
      isValid: false, isError: true, errorMessage: message);
}