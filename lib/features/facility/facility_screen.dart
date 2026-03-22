// lib/features/facility/facility_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/facility_repository.dart';
import 'viewmodels/facility_view_model.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_search_bar.dart';

class FacilityScreen extends StatelessWidget {
  const FacilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      FacilityViewModel(facilityRepository: FacilityRepository())
        ..loadFacilities(),
      child: const _FacilityView(),
    );
  }
}

class _FacilityView extends StatelessWidget {
  const _FacilityView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            FacilitySearchBar(
              onChanged: (q) =>
                  context.read<FacilityViewModel>().updateQuery(q),
              onCleared: () =>
                  context.read<FacilityViewModel>().clearQuery(),
            ),
            const Expanded(child: _FacilityList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C3A2A),
            height: 1.1,
          ),
        ),
        Text(
          'Your Game',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C894E),
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

class _FacilityList extends StatelessWidget {
  const _FacilityList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();

    if (vm.status == FacilityStatus.loading ||
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
            Text(
              'Failed to load facilities',
              style: TextStyle(color: Colors.grey.shade600),
            ),
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
        child: Text('No facilities found.',
            style: TextStyle(color: Colors.grey)),
      );
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