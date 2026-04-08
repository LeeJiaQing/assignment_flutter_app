// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/facility_repository.dart';
import 'admin_announcement_screen.dart';
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
        actions: [
          // ── Announcement button ──────────────────────────────────────
          Tooltip(
            message: 'Create Announcement',
            child: IconButton(
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AdminAnnouncementScreen(),
                ),
              ),
            ),
          ),
        ],
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
                onPressed: () => context
                    .read<AdminFacilityViewModel>()
                    .loadFacilities(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        AdminFacilityStatus.loaded => Column(
          children: [
            // ── Quick action strip ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _QuickAction(
                    icon: Icons.campaign_outlined,
                    label: 'Announcements',
                    color: const Color(0xFF1C894E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const AdminAnnouncementScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.people_outline,
                    label: 'Users',
                    color: Colors.blue.shade600,
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/users'),
                  ),
                ],
              ),
            ),

            const Padding(
              padding:
              EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Facilities',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1C3A2A),
                  ),
                ),
              ),
            ),

            Expanded(
              child: vm.facilities.isEmpty
                  ? const Center(
                  child: Text('No facilities yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 80),
                itemCount: vm.facilities.length,
                itemBuilder: (_, i) => AdminFacilityTile(
                  facility: vm.facilities[i],
                  onDelete: () => context
                      .read<AdminFacilityViewModel>()
                      .deleteFacility(
                      vm.facilities[i].id),
                ),
              ),
            ),
          ],
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/admin/facility/create'),
        label: const Text('Add Facility'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}