// lib/features/facility/facility_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/facility_repository.dart';
import '../../core/repositories/offline_facility_repository.dart';
import '../../core/widgets/offline_banner.dart';
import '../admin/viewmodels/admin_facility_view_model.dart';
import '../admin/widgets/admin_facility_tile.dart';
import 'viewmodels/facility_view_model.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_search_bar.dart';

class FacilityScreen extends StatelessWidget {
  const FacilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacilityViewModel(
          facilityRepository: OfflineFacilityRepository())
        ..loadFacilities(),
      child: const _FacilityView(),
    );
  }
}

class _FacilityView extends StatefulWidget {
  const _FacilityView();

  @override
  State<_FacilityView> createState() => _FacilityViewState();
}

class _FacilityViewState extends State<_FacilityView> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await AuthRepository().getCurrentUserRole();
    if (mounted) setState(() => _isAdmin = role == UserRole.admin);
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: (q) =>
                    context.read<FacilityViewModel>().updateQuery(q),
                onCleared: () =>
                    context.read<FacilityViewModel>().clearQuery(),
              ),
              const Expanded(child: _FacilityListArea()),
            ],
          ),
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(
              context, '/admin/facility/create');
          if (context.mounted) {
            context
                .read<FacilityViewModel>()
                .loadFacilities();
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

// ── List area — decides regular vs admin view ──────────────────────────────

class _FacilityListArea extends StatefulWidget {
  const _FacilityListArea();

  @override
  State<_FacilityListArea> createState() => _FacilityListAreaState();
}

class _FacilityListAreaState extends State<_FacilityListArea> {
  bool _isAdmin = false;
  bool _roleChecked = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await AuthRepository().getCurrentUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = role == UserRole.admin;
        _roleChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();

    if (!_roleChecked ||
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
              onPressed: () =>
                  context.read<FacilityViewModel>().loadFacilities(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final facilities = vm.filteredFacilities;

    if (facilities.isEmpty) {
      return const Center(
        child: Text('No facilities found.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    if (_isAdmin) {
      // Admin: wrap with a second provider using the correct type
      return ChangeNotifierProvider(
        create: (_) => AdminFacilityViewModel(
          // FacilityRepository (not Offline) — admin always needs live data
            facilityRepository: FacilityRepository())
          ..loadFacilities(),
        child: _AdminList(facilityVm: vm),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<FacilityViewModel>().loadFacilities(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: facilities.length,
        itemBuilder: (_, i) =>
            FacilityCard(facility: facilities[i]),
      ),
    );
  }
}

// ── Admin tile list ────────────────────────────────────────────────────────

class _AdminList extends StatelessWidget {
  const _AdminList({required this.facilityVm});
  final FacilityViewModel facilityVm;

  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminFacilityViewModel>();
    final facilities = facilityVm.filteredFacilities;

    if (adminVm.status == AdminFacilityStatus.loading &&
        facilities.isEmpty) {
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