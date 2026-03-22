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
  const BookingDetailScreen({super.key, required this.booking});

  final Booking booking;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final v = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$v:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(
        bookingService: BookingService(
          bookingRepository: BookingRepository(),
          facilityRepository: FacilityRepository(),
        ),
      ),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Booking Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FacilityThumb(imageUrl: null),
              const SizedBox(height: 16),
              _DetailCard(booking: booking, fmt: _fmt),
              const SizedBox(height: 16),
              if (booking.status == 'confirmed')
                _CancelButton(
                  onCancel: () => _handleCancel(context),
                ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
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

    await context.read<BookingViewModel>().cancelBooking(booking.id);

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled.')),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.booking, required this.fmt});
  final Booking booking;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${booking.date.day.toString().padLeft(2, '0')}/'
        '${booking.date.month.toString().padLeft(2, '0')}/'
        '${booking.date.year}';

    final statusColor = switch (booking.status) {
      'confirmed' => Colors.green,
      'pending' => Colors.orange,
      _ => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(label: 'Booking ID', value: booking.id),
          _Row(label: 'Date', value: formattedDate),
          _Row(
            label: 'Time',
            value:
            '${fmt(booking.startHour)} – ${fmt(booking.endHour)}',
          ),
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text('Status',
                    style:
                    TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status[0].toUpperCase() +
                      booking.status.substring(1),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

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