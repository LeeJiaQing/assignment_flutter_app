import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import '../../core/widgets/offline_banner.dart';
import '../admin/viewmodels/admin_facility_view_model.dart';
import '../admin/widgets/admin_facility_tile.dart';
import '../home/viewmodels/navigation_view_model.dart';
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

class _FacilityView extends StatefulWidget {
  const _FacilityView();

  @override
  State<_FacilityView> createState() => _FacilityViewState();
}

class _FacilityViewState extends State<_FacilityView> {
  int _lastAppliedRequestToken = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyPendingCategoryFilter();
  }

  void _applyPendingCategoryFilter() {
    final navVm = context.read<NavigationViewModel>();
    final token = navVm.facilityFilterRequestToken;
    if (token == _lastAppliedRequestToken) return;

    _lastAppliedRequestToken = token;
    final requested = navVm.requestedFacilityCategory;
    if (requested != null && requested.trim().isNotEmpty) {
      context.read<FacilityViewModel>().setCategoryFilter(requested);
      navVm.clearRequestedFacilityCategory();
    }
  }

  @override
  Widget build(BuildContext context) {
    _applyPendingCategoryFilter();
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
                onFilterPressed: () => _showFilterSheet(context),
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

  Future<void> _showFilterSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FacilityViewModel>(),
        child: const _FacilityFilterSheet(),
      ),
    );
  }
}

class _FacilityFilterSheet extends StatefulWidget {
  const _FacilityFilterSheet();

  @override
  State<_FacilityFilterSheet> createState() => _FacilityFilterSheetState();
}

class _FacilityFilterSheetState extends State<_FacilityFilterSheet> {
  String _formatHour(double value) {
    final hour = value.round();
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DFD9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Facilities',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: vm.clearAdvancedFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1C894E),
                    ),
                  ),
                ],
              ),
              const Text(
                'Adjust preferences to quickly find the right facility.',
                style: TextStyle(color: Color(0xFF6B7A72)),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Sport Type',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vm.categories
                      .map(
                        (category) => FilterChip(
                          label: Text(category),
                          selected: vm.selectedSportTypes
                              .map((e) => e.toLowerCase())
                              .contains(category.toLowerCase()),
                          onSelected: (_) => vm.toggleSportType(category),
                          selectedColor: const Color(0xFFE0F4E9),
                          checkmarkColor: const Color(0xFF1C894E),
                          side: BorderSide(
                            color: vm.selectedSportTypes
                                    .map((e) => e.toLowerCase())
                                    .contains(category.toLowerCase())
                                ? const Color(0xFF1C894E)
                                : const Color(0xFFD6DFD9),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Price Range (RM / hr)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${vm.priceRange.start.round()} - RM ${vm.priceRange.end.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      min: 0,
                      max: vm.maxFacilityPrice,
                      divisions: vm.maxFacilityPrice.round().clamp(1, 500),
                      values: vm.priceRange,
                      labels: RangeLabels(
                        vm.priceRange.start.round().toString(),
                        vm.priceRange.end.round().toString(),
                      ),
                      activeColor: const Color(0xFF1C894E),
                      onChanged: vm.setPriceRange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Available Time',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open from ${_formatHour(vm.availableHourRange.start)} to ${_formatHour(vm.availableHourRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      min: 0,
                      max: 24,
                      divisions: 24,
                      values: vm.availableHourRange,
                      activeColor: const Color(0xFF1C894E),
                      onChanged: vm.setAvailableHourRange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Minimum Rating',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.minimumRating.toStringAsFixed(1)} star & above',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      min: 0,
                      max: 5,
                      divisions: 10,
                      value: vm.minimumRating,
                      label: vm.minimumRating.toStringAsFixed(1),
                      activeColor: const Color(0xFF1C894E),
                      onChanged: vm.setMinimumRating,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C894E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filter'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterTitle(title),
          const SizedBox(height: 10),
          child,
        ],
      ),
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
