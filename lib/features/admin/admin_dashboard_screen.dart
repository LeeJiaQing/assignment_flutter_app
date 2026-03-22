// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/facility_repository.dart';
import 'viewmodels/admin_facility_view_model.dart';
import 'widgets/admin_facility_tile.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      AdminFacilityViewModel(facilityRepository: FacilityRepository())
        ..loadFacilities(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFacilityViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: switch (vm.status) {
        AdminFacilityStatus.initial ||
        AdminFacilityStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        AdminFacilityStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(vm.errorMessage ?? 'Something went wrong'),
              TextButton(
                onPressed: () =>
                    context.read<AdminFacilityViewModel>().loadFacilities(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        AdminFacilityStatus.loaded => vm.facilities.isEmpty
            ? const Center(child: Text('No facilities yet.'))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.facilities.length,
          itemBuilder: (_, i) => AdminFacilityTile(
            facility: vm.facilities[i],
            onDelete: () => context
                .read<AdminFacilityViewModel>()
                .deleteFacility(vm.facilities[i].id),
          ),
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateFacility(context),
        label: const Text('Add Facility'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openCreateFacility(BuildContext context) {
    Navigator.pushNamed(context, '/admin/facility/create');
  }
}