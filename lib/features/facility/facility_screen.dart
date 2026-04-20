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
  static const List<double> _radiusOptions = [1, 5, 10];
  double? _selectedRadius;
  double _customRadius = 15;

  @override
  void initState() {
    super.initState();
    final vm = context.read<FacilityViewModel>();
    _selectedRadius = vm.selectedDistanceRadiusKm;
    if (_selectedRadius != null && !_radiusOptions.contains(_selectedRadius)) {
      _customRadius = _selectedRadius!;
    }
  }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Facilities',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.clearAdvancedFilters,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _FilterTitle('1. Sport Type'),
              ...vm.categories.map(
                (category) => CheckboxListTile(
                  value: vm.selectedSportTypes
                      .map((e) => e.toLowerCase())
                      .contains(category.toLowerCase()),
                  title: Text('• $category'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (_) => vm.toggleSportType(category),
                ),
              ),
              const SizedBox(height: 10),
              const _FilterTitle('2. Distance Radius (km)'),
              Wrap(
                spacing: 8,
                children: _radiusOptions
                    .map(
                      (radius) => ChoiceChip(
                        label: Text('Within ${radius.toInt()}km'),
                        selected: _selectedRadius == radius,
                        onSelected: (_) {
                          setState(() => _selectedRadius = radius);
                          vm.setDistanceRadius(radius);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('Custom: ${_customRadius.round()}km'),
              Slider(
                min: 1,
                max: 50,
                divisions: 49,
                value: _customRadius,
                label: '${_customRadius.round()}km',
                onChanged: (value) {
                  setState(() {
                    _customRadius = value;
                    _selectedRadius = value;
                  });
                  vm.setDistanceRadius(value);
                },
              ),
              const Text(
                'Note: distance filter UI is ready, but exact KM filtering depends on facility coordinate data.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              const _FilterTitle('3. Price Range (RM / hr)'),
              Text(
                'RM ${vm.priceRange.start.round()} - RM ${vm.priceRange.end.round()}',
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
                onChanged: vm.setPriceRange,
              ),
              const SizedBox(height: 10),
              const _FilterTitle('4. Available Time'),
              Text(
                'Open time: ${_formatHour(vm.availableHourRange.start)} • Close time: ${_formatHour(vm.availableHourRange.end)}',
              ),
              RangeSlider(
                min: 0,
                max: 24,
                divisions: 24,
                values: vm.availableHourRange,
                onChanged: vm.setAvailableHourRange,
              ),
              const SizedBox(height: 10),
              const _FilterTitle('5. Rating of Facility'),
              Text('Minimum ${vm.minimumRating.toStringAsFixed(1)} star'),
              Slider(
                min: 0,
                max: 5,
                divisions: 10,
                value: vm.minimumRating,
                label: vm.minimumRating.toStringAsFixed(1),
                onChanged: vm.setMinimumRating,
              ),
              const SizedBox(height: 12),
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
