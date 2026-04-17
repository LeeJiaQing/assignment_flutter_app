// lib/features/booking/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import '../../core/supabase/supabase_config.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // ── QR Code Section ─────────────────────────────────────
              if (booking.status == 'confirmed') ...[
                const SizedBox(height: 16),
                _QrSection(bookingId: booking.id),
              ],

              // ── Status Banner for non-active bookings ────────────────
              if (booking.status != 'confirmed') ...[
                const SizedBox(height: 16),
                _StatusBanner(status: booking.status),
              ],

              const SizedBox(height: 16),

              // ── Facility Image ────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FacilityThumb(
                  imageUrl: bookingWithFacility.imageUrl,
                  height: 160,
                ),
              ),
              const SizedBox(height: 16),

              // ── Booking Details Card ──────────────────────────────────
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
                    '${booking.date.day.toString().padLeft(2, '0')}/'
                        '${booking.date.month.toString().padLeft(2, '0')}/'
                        '${booking.date.year}',
                  ),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value:
                    '${_fmt(booking.startHour)} \u2013 ${_fmt(booking.endHour)}',
                  ),
                  _StatusRow(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),

              // ── Payment Details Card ──────────────────────────────────
              _SectionCard(
                title: 'Payment Details',
                icon: Icons.payment_outlined,
                children: [
                  _PaymentDetailsRows(
                      bookingId: booking.id, booking: booking),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cancel Button ─────────────────────────────────────────
              if (BookingViewModel.canCancel(bookingWithFacility))
                _CancelButton(
                  onCancel: () => _handleCancel(context, booking.id),
                ),

              if (booking.status == 'confirmed' &&
                  !BookingViewModel.canCancel(bookingWithFacility))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This booking cannot be cancelled as the session time has already passed.',
                          style:
                          TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
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

// ── QR Code Section ────────────────────────────────────────────────────────

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
            'Show this QR code at the facility to check in',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C3A2A),
            ),
          ),
          const SizedBox(height: 16),
          // Real QR code generated from the booking UUID.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1C894E).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: bookingId,
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1C894E),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1C3A2A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Short booking ID reference below the QR.
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD6F0E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1C894E),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Banner ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String message;

    switch (status) {
      case 'completed':
        bg = const Color(0xFFD6F0E0);
        fg = const Color(0xFF1C894E);
        icon = Icons.check_circle_outline;
        message = 'This session has been completed.';
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        message = 'This booking was cancelled.';
        break;
      case 'pending_sync':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        icon = Icons.cloud_upload_outlined;
        message = 'Booking saved offline — will sync when online.';
        break;
      case 'checked_in':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.how_to_reg_outlined;
        message = 'You have checked in. Enjoy your session!';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.info_outline;
        message = 'Booking status: $status';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Details ────────────────────────────────────────────────────────

class _PaymentDetailsRows extends StatelessWidget {
  const _PaymentDetailsRows({
    required this.bookingId,
    required this.booking,
  });

  final String bookingId;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadPaymentRow(),
      builder: (context, snapshot) {
        final methodCode =
            (snapshot.data?['method'] as String?) ?? '';
        final labels = _paymentLabels(methodCode);

        return Column(
          children: [
            _DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment Type',
              value: labels.type,
            ),
            _DetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Payment Method',
              value: labels.method,
            ),
            _DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Payment Date',
              value:
              '${booking.date.day.toString().padLeft(2, '0')}/'
                  '${booking.date.month.toString().padLeft(2, '0')}/'
                  '${booking.date.year}',
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadPaymentRow() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final rows = await supabase
          .from('payments')
          .select('method')
          .eq('booking_id', bookingId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List<dynamic>).isEmpty) return null;
      return rows.first as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  _PaymentLabels _paymentLabels(String methodCode) {
    switch (methodCode) {
      case 'tng':
        return const _PaymentLabels(
          type: 'Digital Wallet',
          method: "Touch 'n Go eWallet",
        );
      case 'card':
        return const _PaymentLabels(
          type: 'Card Payment',
          method: 'Credit/Debit Card',
        );
      case 'banking':
        return const _PaymentLabels(
          type: 'Online Banking',
          method: 'FPX / Online Banking',
        );
      default:
        return const _PaymentLabels(type: 'N/A', method: 'N/A');
    }
  }
}

class _PaymentLabels {
  final String type;
  final String method;
  const _PaymentLabels({required this.type, required this.method});
}

// ── Section Card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title,
        required this.icon,
        required this.children});

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
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C3A2A))),
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
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
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
            child: Text(label,
                style:
                const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
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
      case 'completed':
        return Colors.purple;
      case 'checked_in':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  String get _label =>
      status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: Color(0xFF1C894E)),
          const SizedBox(width: 10),
          const SizedBox(
              width: 110,
              child: Text('Status',
                  style:
                  TextStyle(fontSize: 13, color: Colors.grey))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_label,
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
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
      ),
    );
  }
}