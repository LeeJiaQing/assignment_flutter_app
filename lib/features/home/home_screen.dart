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

class _HomeViewState extends State<_HomeView> {
  static const String _currentLocationLabel = 'Current location';
  static const String _preferredLocationLabel = 'PV9 Residence, Setapak';

  String _selectedLocation = _preferredLocationLabel;
  bool _useCurrentLocation = false;
  bool _isResolvingCurrentLocation = false;

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
              if (vm.status == FacilityStatus.loaded &&
                  facilitiesByLocation.isNotEmpty)
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
                  onTap: () => _showLocationPicker(context),
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
      child: Row(
        children: [
          Expanded(
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
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF1C894E), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 13, horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C894E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
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
                onPressed: () {},
                child: const Text('See all',
                    style: TextStyle(color: Color(0xFF1C894E))),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: facilities.length > 3 ? 3 : facilities.length,
          itemBuilder: (_, i) =>
              _NearbyCard(facility: facilities[i]),
        ),
      ],
    );
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
    if (_useCurrentLocation) {
      return facilities;
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

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Choose location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
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
                    : () => _selectCurrentLocation(context),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Other location'),
                subtitle: Text(_selectedLocation),
                trailing: !_useCurrentLocation
                    ? const Icon(Icons.check, color: Color(0xFF1C894E))
                    : null,
                onTap: () => _showOtherLocationPicker(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showOtherLocationPicker(BuildContext context) {
    final facilities = context.read<FacilityViewModel>().filteredFacilities;
    final quickPickLocations = <String>{
      _preferredLocationLabel,
      ...facilities.map((facility) => facility.address.trim()),
    }.where((location) => location.isNotEmpty).take(4).toList();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Other location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...quickPickLocations.map(
                (location) => ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(location),
                  onTap: () {
                    _selectFixedLocation(location);
                    Navigator.pop(sheetContext);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_location_alt_outlined),
                title: const Text('Enter address details'),
                subtitle: const Text('Address + postcode'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _showManualLocationDialog(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _selectFixedLocation(String location) {
    setState(() {
      _useCurrentLocation = false;
      _selectedLocation = location;
    });
  }

  Future<void> _showManualLocationDialog(BuildContext context) async {
    final addressController = TextEditingController();
    final postcodeController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Address details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Street, city',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: postcodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final address = addressController.text.trim();
                final postcode = postcodeController.text.trim();
                Navigator.pop(dialogContext, '$address|$postcode');
              },
              child: const Text('Validate'),
            ),
          ],
        );
      },
    );

    addressController.dispose();
    postcodeController.dispose();

    if (result == null || !mounted) {
      return;
    }

    final split = result.split('|');
    if (split.length != 2) {
      _showLocationError('Please provide a valid address and postcode.');
      return;
    }

    final address = split.first.trim();
    final postcode = split.last.trim();
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
      _selectedLocation = '$address, $postcode';
    });
    if (mounted) {
      Navigator.pop(context);
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

  Future<void> _selectCurrentLocation(BuildContext context) async {
    setState(() => _isResolvingCurrentLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
        _selectedLocation = detectedLabel.isNotEmpty
            ? detectedLabel
            : _currentLocationLabel;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      _showLocationError(
        'Unable to detect current location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResolvingCurrentLocation = false);
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
