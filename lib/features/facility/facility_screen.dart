import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import '../../core/widgets/offline_banner.dart';
import '../admin/viewmodels/admin_facility_view_model.dart';
import '../admin/widgets/admin_facility_tile.dart';
import 'viewmodels/facility_page_view_model.dart';
import 'viewmodels/facility_view_model.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_search_bar.dart';

class FacilityScreen extends StatelessWidget {
  const FacilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<AppDependencies>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FacilityViewModel(
            facilityRepository: dependencies.offlineFacilityRepository,
          )..loadFacilities(),
        ),
        ChangeNotifierProvider(
          create: (_) => FacilityPageViewModel(
            authRepository: dependencies.authRepository,
          )..loadRole(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminFacilityViewModel(
            facilityRepository: dependencies.facilityRepository,
          )..loadFacilities(),
        ),
      ],
      child: const _FacilityView(),
    );
  }
}

class _FacilityView extends StatelessWidget {
  const _FacilityView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();
    final pageVm = context.watch<FacilityPageViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: WithOfflineBanner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C3A2A),
                            height: 1.1)),
                    Text('Your Game',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C894E),
                            height: 1.1)),
                  ],
                ),
              ),
              FacilitySearchBar(
                onChanged: vm.updateQuery,
                onCleared: vm.clearQuery,
              ),
              Expanded(
                child: _FacilityListArea(
                  isAdmin: pageVm.isAdmin,
                  roleLoading: pageVm.isLoadingRole,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: pageVm.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, '/admin/facility/create');
                if (context.mounted) {
                  context.read<FacilityViewModel>().loadFacilities();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Facility'),
              backgroundColor: const Color(0xFF1C894E),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _FacilityListArea extends StatelessWidget {
  const _FacilityListArea({required this.isAdmin, required this.roleLoading});

  final bool isAdmin;
  final bool roleLoading;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();

    if (roleLoading ||
        vm.status == FacilityStatus.loading ||
        vm.status == FacilityStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.status == FacilityStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Failed to load facilities',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<FacilityViewModel>().loadFacilities(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final facilities = vm.filteredFacilities;

    if (facilities.isEmpty) {
      return const Center(
        child: Text('No facilities found.', style: TextStyle(color: Colors.grey)),
      );
    }

    if (isAdmin) {
      return _AdminList(facilityVm: vm);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<FacilityViewModel>().loadFacilities(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: facilities.length,
        itemBuilder: (_, i) => FacilityCard(facility: facilities[i]),
      ),
    );
  }
}

class _AdminList extends StatelessWidget {
  const _AdminList({required this.facilityVm});
  final FacilityViewModel facilityVm;

  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminFacilityViewModel>();
    final facilities = facilityVm.filteredFacilities;

    if (adminVm.status == AdminFacilityStatus.loading && facilities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await facilityVm.loadFacilities();
        await adminVm.loadFacilities();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: facilities.length,
        itemBuilder: (_, i) => AdminFacilityTile(
          facility: facilities[i],
          onDelete: () async {
            await adminVm.deleteFacility(facilities[i].id);
            if (context.mounted) {
              await facilityVm.loadFacilities();
            }
          },
        ),
      ),
    );
  }
}
