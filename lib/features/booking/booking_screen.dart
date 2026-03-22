// lib/features/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import 'viewmodels/booking_view_model.dart';
import 'widgets/booking_card.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(
        bookingService: BookingService(
          bookingRepository: BookingRepository(),
          facilityRepository: FacilityRepository(),
        ),
      )..loadBookings(),
      child: const _BookingView(),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C894E),
            ),
          ),
          const SizedBox(height: 10),
          const Expanded(child: _BookingList()),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFC8DFC3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: switch (vm.status) {
        BookingListStatus.initial ||
        BookingListStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        BookingListStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Failed to load bookings',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<BookingViewModel>().loadBookings(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        BookingListStatus.loaded => vm.bookings.isEmpty
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No bookings yet',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () =>
              context.read<BookingViewModel>().loadBookings(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.bookings.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BookingCard(item: vm.bookings[i]),
            ),
          ),
        ),
      },
    );
  }
}