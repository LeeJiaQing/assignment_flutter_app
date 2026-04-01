// lib/features/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/offline_booking_repository.dart';
import '../../core/repositories/offline_facility_repository.dart';
import '../../core/services/booking_service_offline.dart';
import '../../core/widgets/offline_banner.dart';
import 'booking_detail_screen.dart';
import 'viewmodels/booking_view_model.dart';
import 'widgets/booking_card.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(
        bookingService: OfflineBookingService(
          bookingRepository: OfflineBookingRepository(),
          facilityRepository: OfflineFacilityRepository(),
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
    // Check if we're embedded inside another scaffold (e.g., home screen)
    // or opened as a standalone screen
    final isStandalone =
        ModalRoute.of(context)?.settings.name == '/bookings' ||
        Navigator.of(context).canPop();

    if (isStandalone) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4FAF6),
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: const Color(0xFFF4FAF6),
        ),
        body: WithOfflineBanner(child: const _BookingList()),
      );
    }

    // Embedded — no AppBar, just the list
    return const WithOfflineBanner(child: _BookingList());
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    return switch (vm.status) {
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
                itemBuilder: (_, i) {
                  final item = vm.bookings[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(
                            bookingWithFacility: item,
                          ),
                        ),
                      ),
                      child: BookingCard(item: item),
                    ),
                  );
                },
              ),
            ),
    };
  }
}
