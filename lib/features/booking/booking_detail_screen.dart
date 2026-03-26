// lib/features/booking/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import '../../models/booking_model.dart';
import 'viewmodels/booking_view_model.dart';
import 'widgets/facility_thumb.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingWithFacility});

  final BookingWithFacility bookingWithFacility;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final booking = bookingWithFacility.booking;

    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(
        bookingService: BookingService(
          bookingRepository: BookingRepository(),
          facilityRepository: FacilityRepository(),
        ),
      ),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4FAF6),
          appBar: AppBar(
            title: const Text('Booking Details'),
            backgroundColor: const Color(0xFFF4FAF6),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── QR Code Section ──────────────────────────────────────────
              _QrSection(bookingId: booking.id),
              const SizedBox(height: 16),

              // ── Facility Image ────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FacilityThumb(
                  imageUrl: bookingWithFacility.imageUrl,
                  height: 160,
                ),
              ),
              const SizedBox(height: 16),

              // ── Booking Details Card ──────────────────────────────────────
              _SectionCard(
                title: 'Booking Details',
                icon: Icons.receipt_long_outlined,
                children: [
                  _DetailRow(
                    icon: Icons.stadium_outlined,
                    label: 'Facility',
                    value: bookingWithFacility.facilityName,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value:
                    '${booking.date.day.toString().padLeft(2, '0')}/${booking.date.month.toString().padLeft(2, '0')}/${booking.date.year}',
                  ),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value:
                    '${_fmt(booking.startHour)} – ${_fmt(booking.endHour)}',
                  ),
                  _StatusRow(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),

              // ── Payment Details Card ──────────────────────────────────────
              _SectionCard(
                title: 'Payment Details',
                icon: Icons.payment_outlined,
                children: [
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payment Type',
                    value: 'Digital Wallet',
                  ),
                  _DetailRow(
                    icon: Icons.credit_card_outlined,
                    label: 'Payment Method',
                    value: 'TNG eWallet',
                  ),
                  _DetailRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Payment Date',
                    value:
                    '${booking.date.day.toString().padLeft(2, '0')}/${booking.date.month.toString().padLeft(2, '0')}/${booking.date.year}',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cancel Button (only for confirmed/pending) ────────────────
              if (booking.status == 'confirmed' ||
                  booking.status == 'pending')
                _CancelButton(
                  onCancel: () => _handleCancel(context, booking.id),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _handleCancel(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<BookingViewModel>().cancelBooking(bookingId);

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled.')),
    );
  }
}

// ── QR Code Placeholder ────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scan to check in',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C3A2A),
            ),
          ),
          const SizedBox(height: 16),
          // QR Placeholder — replace with a real QR package later
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF1C894E).withOpacity(0.3),
                  width: 2),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF4FAF6),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Corner decorators to mimic a QR border
                ..._qrCorners(),
                // Center icon
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 64, color: Color(0xFF1C894E)),
                    const SizedBox(height: 6),
                    Text(
                      bookingId.length > 8
                          ? bookingId.substring(0, 8).toUpperCase()
                          : bookingId.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Show this QR code at the facility entrance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _qrCorners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = Color(0xFF1C894E);

    Widget corner({
      required AlignmentGeometry alignment,
      required BorderRadius radius,
      required Border border,
    }) =>
        Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: border,
                borderRadius: radius,
              ),
            ),
          ),
        );

    return [
      corner(
        alignment: Alignment.topLeft,
        radius: const BorderRadius.only(topLeft: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.topRight,
        radius: const BorderRadius.only(topRight: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.bottomLeft,
        radius: const BorderRadius.only(bottomLeft: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.bottomRight,
        radius: const BorderRadius.only(bottomRight: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
    ];
  }
}

// ── Section Card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1C894E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C3A2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1C894E)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Row ─────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final String status;

  Color get _color {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String get _label =>
      status[0].toUpperCase() + status.substring(1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: const Color(0xFF1C894E)),
          const SizedBox(width: 10),
          const SizedBox(
            width: 110,
            child: Text(
              'Status',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _label,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancel Button ──────────────────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel Booking'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onCancel,
      ),
    );
  }
}