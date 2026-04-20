// lib/features/home/home_screen.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import '../../models/facility_model.dart';
import '../booking/booking_screen.dart';
import '../facility/viewmodels/facility_view_model.dart';
import 'viewmodels/home_view_model.dart';
import '../facility/facility_detail_screen.dart';
import '../notification/notification_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<AppDependencies>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeViewModel()..loadUserName(),
        ),
        ChangeNotifierProvider(
          create: (_) => FacilityViewModel(
            facilityRepository: dependencies.offlineFacilityRepository,
          )..loadFacilities(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

enum _LocationPickerAction { current, other, enterAddress, previousAddress }

class _HomeViewState extends State<_HomeView> {
  static const String _currentLocationLabel = 'Current location';
  static const String _noLocationSelectedLabel = 'No location selected';

  String _selectedLocation = _noLocationSelectedLabel;
  String? _typedOtherLocation;
  bool _useCurrentLocation = false;
  bool _isResolvingCurrentLocation = false;
  Position? _currentPosition;
  final Map<String, double> _facilityDistancesInMeters = {};

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final facilitiesByLocation = _mapFacilitiesByLocation(vm.filteredFacilities);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context, homeVm.userName),

              // ── Search bar ──────────────────────────────────────────────
              _buildSearchBar(context, vm),

              // ── Pick Trendy chips ────────────────────────────────────────
              _buildTrendySection(context, vm),

              // ── Near By You ─────────────────────────────────────────────
              if (vm.status == FacilityStatus.loaded)
                _buildNearbySection(context, facilitiesByLocation),

              // ── Recent Activities ────────────────────────────────────────
              _buildRecentActivities(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C894E), Color(0xFF6DCC98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${userName ?? 'Customer'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showLocationPicker,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedLocation,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, FacilityViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: vm.updateQuery,
          decoration: InputDecoration(
            hintText: 'Volleyball',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF1C894E), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendySection(BuildContext context, FacilityViewModel vm) {
    final sports = [...vm.categories];
    sports.sort((a, b) {
      final aIsOther = a.trim().toLowerCase() == 'other';
      final bIsOther = b.trim().toLowerCase() == 'other';
      if (aIsOther == bIsOther) {
        return a.toLowerCase().compareTo(b.toLowerCase());
      }
      return aIsOther ? 1 : -1;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Pick Trendy',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3A2A)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: sports.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No facility categories available yet.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sports.map((sport) {
                      final isSelected =
                          vm.query.trim().toLowerCase() == sport.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            vm.updateQuery(isSelected ? '' : sport);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith((states) {
                              if (isSelected) return const Color(0xFF1C894E);
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0xFFEAF6EF);
                              }
                              return Colors.white;
                            }),
                            foregroundColor:
                                MaterialStateProperty.resolveWith((states) {
                              if (isSelected) return Colors.white;
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0xFF1C894E);
                              }
                              return Colors.black87;
                            }),
                            side: MaterialStateProperty.resolveWith((states) {
                              if (isSelected) {
                                return BorderSide.none;
                              }
                              if (states.contains(MaterialState.hovered)) {
                                return const BorderSide(
                                    color: Color(0xFF6DCC98));
                              }
                              return BorderSide(color: Colors.grey.shade300);
                            }),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            overlayColor: MaterialStateProperty.resolveWith(
                              (states) => isSelected
                                  ? Colors.white.withOpacity(0.14)
                                  : const Color(0xFF1C894E).withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            sport,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNearbySection(
      BuildContext context, List<Facility> facilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              const Text(
                'Near By You',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C3A2A)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _NearbyFacilitiesScreen(
                        facilities: facilities,
                        emptyMessage: _nearbyEmptyMessage(),
                        selectedLocation: _selectedLocation,
                      ),
                    ),
                  );
                },
                child: const Text('See all',
                    style: TextStyle(color: Color(0xFF1C894E))),
              ),
            ],
          ),
        ),
        if (facilities.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              _nearbyEmptyMessage(),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: facilities.length > 3 ? 3 : facilities.length,
            itemBuilder: (_, i) => _NearbyCard(facility: facilities[i]),
          ),
      ],
    );
  }

  String _nearbyEmptyMessage() {
    if (_selectedLocation == _noLocationSelectedLabel) {
      return 'No location selected.';
    }
    if (_isResolvingCurrentLocation) {
      return 'Detecting your current location...';
    }
    return 'No nearby facilities found for the selected location.';
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'Recent Activities',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3A2A)),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFD6F0E0),
                  child: Icon(Icons.sports_tennis,
                      color: Color(0xFF1C894E), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('View My Bookings',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('See your recent court bookings',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Facility> _mapFacilitiesByLocation(List<Facility> facilities) {
    if (_facilityDistancesInMeters.isNotEmpty) {
      final nearbyFacilities = facilities
          .where((facility) => _facilityDistancesInMeters.containsKey(facility.id))
          .toList()
        ..sort((a, b) => _facilityDistancesInMeters[a.id]!
            .compareTo(_facilityDistancesInMeters[b.id]!));
      return nearbyFacilities;
    }

    if (_selectedLocation == _noLocationSelectedLabel) {
      return const [];
    }

    return facilities
        .where(
          (facility) =>
              facility.address.toLowerCase().contains(
                    _selectedLocation.toLowerCase(),
                  ) ||
              _selectedLocation
                  .toLowerCase()
                  .contains(facility.address.toLowerCase()),
        )
        .toList();
  }

  Future<void> _showLocationPicker() async {
    final action = await showDialog<_LocationPickerAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose location'),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text(_currentLocationLabel),
                subtitle: _isResolvingCurrentLocation
                    ? const Text('Detecting your location...')
                    : null,
                trailing: _useCurrentLocation
                    ? const Icon(Icons.check, color: Color(0xFF1C894E))
                    : null,
                onTap: _isResolvingCurrentLocation
                    ? null
                    : () => Navigator.pop(
                        dialogContext,
                        _LocationPickerAction.current,
                      ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Other location'),
                subtitle: Text(_typedOtherLocation ?? 'Enter address detail'),
                trailing: !_useCurrentLocation && _typedOtherLocation != null
                    ? const Icon(Icons.check, color: Color(0xFF1C894E))
                    : null,
                onTap: () => Navigator.pop(
                  dialogContext,
                  _LocationPickerAction.other,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == _LocationPickerAction.current) {
      await _selectCurrentLocation();
      return;
    }
    await _showOtherLocationPicker();
  }

  Future<void> _showOtherLocationPicker() async {
    final action = await showDialog<_LocationPickerAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Other location'),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_typedOtherLocation != null)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(_typedOtherLocation!),
                  subtitle: const Text('Use previously entered location'),
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                      _LocationPickerAction.previousAddress,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_location_alt_outlined),
                title: const Text('Enter address details'),
                subtitle: const Text('Address + postcode'),
                onTap: () =>
                    Navigator.pop(dialogContext, _LocationPickerAction.enterAddress),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == _LocationPickerAction.previousAddress &&
        _typedOtherLocation != null) {
      await _selectFixedLocation(_typedOtherLocation!);
      return;
    }
    await _showManualLocationDialog();
  }

  Future<void> _selectFixedLocation(String location) async {
    setState(() {
      _useCurrentLocation = false;
      _currentPosition = null;
      _facilityDistancesInMeters.clear();
      _selectedLocation = location;
    });

    await _resolveFacilityDistancesFromQuery(location);
  }

  Future<void> _showManualLocationDialog() async {
    final formKey = GlobalKey<FormState>();
    String address = '';
    String postcode = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Form(
          key: formKey,
          child: AlertDialog(
            title: const Text('Address details'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      minLines: 2,
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Street, city',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => address = (value ?? '').trim(),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter your address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Postcode',
                        hintText: 'e.g. 53300',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => postcode = (value ?? '').trim(),
                      validator: (value) {
                        final trimmed = (value ?? '').trim();
                        final postcodePattern = RegExp(r'^[A-Za-z0-9 -]{4,10}$');
                        if (!postcodePattern.hasMatch(trimmed)) {
                          return 'Enter a valid postcode.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final state = formKey.currentState;
                  if (state == null || !state.validate()) return;
                  state.save();
                  Navigator.pop(dialogContext, '$address|$postcode');
                },
                child: const Text('Validate'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final split = result.split('|');
    if (split.length != 2) {
      _showLocationError('Please provide a valid address and postcode.');
      return;
    }

    final postcodePattern = RegExp(r'^[A-Za-z0-9 -]{4,10}$');
    if (address.isEmpty || !postcodePattern.hasMatch(postcode)) {
      _showLocationError('Invalid input. Add address and a valid postcode.');
      return;
    }

    final isValid = await _validateLocation(address: address, postcode: postcode);
    if (!isValid) {
      _showLocationError('Location is invalid. Please check address details.');
      return;
    }

    setState(() {
      _useCurrentLocation = false;
      _currentPosition = null;
      _facilityDistancesInMeters.clear();
      _typedOtherLocation = '$address, $postcode';
      _selectedLocation = _typedOtherLocation!;
    });
    await _resolveFacilityDistancesFromQuery(_typedOtherLocation!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully.')),
      );
    }
  }

  Future<bool> _validateLocation({
    required String address,
    required String postcode,
  }) async {
    try {
      final query = '$address, $postcode';
      final locations = await locationFromAddress(query);
      return locations.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _setNoLocationSelected() {
    setState(() {
      _useCurrentLocation = false;
      _currentPosition = null;
      _facilityDistancesInMeters.clear();
      _selectedLocation = _noLocationSelectedLabel;
    });
  }

  Future<void> _selectCurrentLocation() async {
    setState(() => _isResolvingCurrentLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setNoLocationSelected();
        _showLocationError(
          'Location service is turned off. Please enable GPS/location service.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setNoLocationSelected();
        _showLocationError(
          'Location permission was denied. Please allow location access.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final area = placemark?.subLocality ??
          placemark?.locality ??
          placemark?.administrativeArea;
      final country = placemark?.country;
      final detectedLabel = [area, country]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(', ')
          .trim();

      setState(() {
        _useCurrentLocation = true;
        _currentPosition = position;
        _selectedLocation = detectedLabel.isNotEmpty
            ? detectedLabel
            : _currentLocationLabel;
      });

      await _resolveFacilityDistancesFromCurrentLocation();
    } catch (_) {
      _setNoLocationSelected();
      _showLocationError(
        'Unable to detect current location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResolvingCurrentLocation = false);
      }
    }
  }

  Future<void> _resolveFacilityDistancesFromCurrentLocation() async {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    await _resolveFacilityDistancesFromCoordinates(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
    );
  }

  Future<void> _resolveFacilityDistancesFromQuery(String query) async {
    if (!mounted) return;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        if (!mounted) return;
        setState(() => _facilityDistancesInMeters.clear());
        return;
      }

      final selectedLocation = locations.first;
      await _resolveFacilityDistancesFromCoordinates(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _facilityDistancesInMeters.clear());
    }
  }

  Future<void> _resolveFacilityDistancesFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) return;

    final facilities = context.read<FacilityViewModel>().filteredFacilities;
    final Map<String, double> distances = {};

    for (final facility in facilities) {
      try {
        final locations = await locationFromAddress(facility.address);
        if (locations.isEmpty) continue;

        final facilityLocation = locations.first;
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          facilityLocation.latitude,
          facilityLocation.longitude,
        );
        distances[facility.id] = distance;
      } catch (_) {
        // Skip facilities with addresses that cannot be geocoded.
      }
    }

    if (!mounted) return;
    setState(() {
      _facilityDistancesInMeters
        ..clear()
        ..addAll(distances);
    });
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


class _NearbyFacilitiesScreen extends StatelessWidget {
  const _NearbyFacilitiesScreen({
    required this.facilities,
    required this.emptyMessage,
    required this.selectedLocation,
  });

  final List<Facility> facilities;
  final String emptyMessage;
  final String selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Nearby Facilities'),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                selectedLocation,
                style: const TextStyle(
                  color: Color(0xFF1C3A2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: facilities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: facilities.length,
                      itemBuilder: (_, i) => _NearbyCard(facility: facilities[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.facility});
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FacilityDetailScreen(facility: facility)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: facility.imageUrl != null
                  ? Image.network(
                      facility.imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    facility.address,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6DCC98),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FacilityDetailScreen(facility: facility)),
              ),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFD6F0E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.sports_tennis,
            color: Color(0xFF1C894E), size: 28),
      );
}
