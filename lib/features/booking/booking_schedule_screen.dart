// lib/features/booking/booking_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/services/booking_service.dart';
import '../../models/facility_model.dart';
import 'viewmodels/booking_schedule_view_model.dart';
import 'viewmodels/payment_view_model.dart';
import 'payment_screen.dart';
import 'widgets/checkout_bottom_bar.dart';
import 'widgets/court_slot_grid.dart';
import 'widgets/slot_legend.dart';
import 'widgets/week_calendar.dart';

class BookingScheduleScreen extends StatelessWidget {
  const BookingScheduleScreen({super.key, required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingScheduleViewModel(
        bookingService: BookingService(
          bookingRepository: BookingRepository(),
          facilityRepository: FacilityRepository(),
        ),
        facility: facility,
      )..loadBookedHoursForDate(DateTime.now()),
      child: const _BookingScheduleView(),
    );
  }
}

class _BookingScheduleView extends StatelessWidget {
  const _BookingScheduleView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingScheduleViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFC8DFC3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC8DFC3),
        elevation: 0,
        title: Text(
          vm.facility.name,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // bottomNavigationBar reserves its own space — the body will never
      // slide under it, unlike bottomSheet which floats on top.
      bottomNavigationBar: CheckoutBottomBar(
        selectedSlots: vm.selectedSlots,
        formattedDate: vm.formattedDate,
        grandTotal: vm.grandTotal,
        onCheckout: vm.hasSelection ? () => _goToPayment(context, vm) : null,
      ),
      body: Column(
        children: [
          WeekCalendar(
            weekDays: vm.weekDays,
            selectedDate: vm.selectedDate,
            monthLabel: vm.fmtMonth(vm.weekStart),
            onDayTap: vm.selectDate,
            onPreviousWeek: vm.previousWeek,
            onNextWeek: vm.nextWeek,
          ),
          const SlotLegend(),
          Expanded(
            child: ListView(
              // No extra bottom padding needed — the nav bar handles the gap.
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: vm.facility.courts
                  .map((court) => CourtSlotGrid(
                court: court,
                slots: vm.slotsForCourt(court.id),
                isLoading: vm.isCourtLoading(court.id),
                isSlotSelected: vm.isSlotSelected,
                onSlotTap: (court, slot) {
                  final error = vm.toggleSlot(court, slot);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPayment(BuildContext context, BookingScheduleViewModel vm) {
    final items = vm.selectedSlots.values
        .map((s) => PaymentItem(
      facilityName: vm.facility.name,
      facilityId: vm.facility.id,
      courtId: s.courtId,
      courtName: s.courtName,
      imageUrl: vm.facility.imageUrl,
      date: vm.selectedDate,
      formattedDate: vm.formattedDate,
      startHour: s.slot.startHour,
      endHour: s.slot.endHour,
      timeLabel: s.slot.label,
      pricePerSlot: vm.facility.pricePerSlot,
    ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          items: items,
          grandTotal: vm.grandTotal,
        ),
      ),
    );
  }
}