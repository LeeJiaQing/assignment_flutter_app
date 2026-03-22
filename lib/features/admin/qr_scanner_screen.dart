// lib/features/admin/qr_scanner_screen.dart
import 'package:flutter/material.dart';

/// Placeholder for the QR scanner screen.
/// Wire a real scanner package (e.g. mobile_scanner) here when ready.
/// All validation logic lives in QrService — this screen only triggers it.
class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF1C894E)),
            SizedBox(height: 16),
            Text(
              'QR Scanner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Camera scanner widget goes here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}