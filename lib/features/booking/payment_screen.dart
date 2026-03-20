// lib/features/booking/payment_screen.dart
//jq
import 'package:flutter/material.dart';

import '../../models/court_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class passed from BookingScheduleScreen
// ─────────────────────────────────────────────────────────────────────────────

class BookingInfo {
  final String facilityName;
  final String courtName;
  final String imagePath;
  final String date;       // formatted "dd/MM/yyyy"
  final String timeLabel;  // e.g. "10:00 AM - 11:00 AM"
  final double total;

  const BookingInfo({
    required this.facilityName,
    required this.courtName,
    required this.imagePath,
    required this.date,
    required this.timeLabel,
    required this.total,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment methods
// ─────────────────────────────────────────────────────────────────────────────

enum _PayMethod { tng, card, banking }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PaymentScreen extends StatefulWidget {
  final List<BookingInfo> bookings;
  final double grandTotal;

  const PaymentScreen({
    super.key,
    required this.bookings,
    required this.grandTotal,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _selected = _PayMethod.tng;

  static const _kBg = Color(0xFFF0F5F1);
  static const _kGreen = Color(0xFF1C894E);
  static const _kGreenLight = Color(0xFF6DCC98);
  static const _kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: const Text(
          'Payment Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── Booking summary cards ────────────────────────────────────────
          ...widget.bookings.map((b) => _BookingSummaryCard(booking: b)),

          const SizedBox(height: 20),

          // ── Payment method section ───────────────────────────────────────
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _PayMethodCard(
            value: _PayMethod.tng,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            icon: 'assets/images/payment/tng.png',
            iconFallback: Icons.account_balance_wallet_outlined,
            label: "Touch 'n Go eWallet",
            detail: '60*****1234',
          ),
          const SizedBox(height: 10),
          _PayMethodCard(
            value: _PayMethod.card,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            icon: 'assets/images/payment/visa.png',
            iconFallback: Icons.credit_card_outlined,
            label: 'Credit/Debit Card',
            detail: '4621 **** **** ****',
          ),
          const SizedBox(height: 10),
          _PayMethodCard(
            value: _PayMethod.banking,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            icon: 'assets/images/payment/maybank.png',
            iconFallback: Icons.account_balance_outlined,
            label: 'Online Banking',
            detail: 'Maybank',
          ),
        ],
      ),

      // ── Make Payment bottom bar ──────────────────────────────────────────
      bottomSheet: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreenLight,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _confirmPayment(context),
          child: Text(
            'Make Payment   RM ${widget.grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1C894E)),
            SizedBox(width: 8),
            Text('Payment Confirmed'),
          ],
        ),
        content: Text(
          'Your booking has been confirmed!\nTotal paid: RM ${widget.grandTotal.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).popUntil((r) => r.isFirst); // back to home
            },
            child: const Text('Done', style: TextStyle(color: Color(0xFF1C894E))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking summary card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final BookingInfo booking;
  const _BookingSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.asset(
              booking.imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: const Color(0xFFD6F0E0),
                child: const Icon(Icons.sports_tennis,
                    size: 36, color: Color(0xFF1C894E)),
              ),
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Facility: ${booking.facilityName} ${booking.courtName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1C3A2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoRow('Date', booking.date),
                  _infoRow('Time', booking.timeLabel),
                  _infoRow('Total', 'RM ${booking.total.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method card
// ─────────────────────────────────────────────────────────────────────────────

class _PayMethodCard extends StatelessWidget {
  final _PayMethod value;
  final _PayMethod groupValue;
  final ValueChanged<_PayMethod?> onChanged;
  final String icon;
  final IconData iconFallback;
  final String label;
  final String detail;

  const _PayMethodCard({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.iconFallback,
    required this.label,
    required this.detail,
  });

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isSelected
                ? const Color(0xFF1C894E)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon / logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    iconFallback,
                    color: const Color(0xFF1C894E),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label + detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Radio
            Radio<_PayMethod>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF1C894E),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}