// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/auth_repository.dart';
import 'viewmodels/profile_view_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ProfileViewModel(authRepository: AuthRepository())
        ..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
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
    final vm = context.watch<ProfileViewModel>();

    if (vm.status == ProfileStatus.initial ||
        vm.status == ProfileStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not signed in
    if (vm.profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Not signed in.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: ListView(
        children: [
          ProfileHeader(profile: vm.profile!),
          const SizedBox(height: 20),

          // ── Account section ─────────────────────────────────────────
          _MenuSection(
            title: 'Account',
            children: [
              ProfileMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () =>
                    Navigator.pushNamed(context, '/profile/edit'),
              ),
              ProfileMenuItem(
                icon: Icons.calendar_today_outlined,
                label: 'My Bookings',
                onTap: () =>
                    Navigator.pushNamed(context, '/bookings'),
              ),
              ProfileMenuItem(
                icon: Icons.star_outline,
                label: 'Reward Points',
                onTap: () =>
                    Navigator.pushNamed(context, '/rewards'),
              ),
              // My Sessions — member only
              if (!_isAdmin)
                ProfileMenuItem(
                  icon: Icons.sports_soccer,
                  label: 'My Party Sessions',
                  onTap: () =>
                      Navigator.pushNamed(context, '/party/my'),
                ),
            ],
          ),

          // ── Support section ─────────────────────────────────────────
          _MenuSection(
            title: 'Support',
            children: [
              ProfileMenuItem(
                icon: Icons.feedback_outlined,
                label: 'Send Feedback',
                onTap: () =>
                    Navigator.pushNamed(context, '/feedback'),
              ),
              ProfileMenuItem(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                // Admin navigates to the editable version;
                // members see the read-only version.
                onTap: () => Navigator.pushNamed(
                  context,
                  _isAdmin
                      ? '/admin/terms/edit'
                      : '/terms',
                ),
                trailing: _isAdmin
                    ? const Icon(Icons.edit_outlined,
                    color: Color(0xFF1C894E), size: 18)
                    : null,
              ),
            ],
          ),

          _MenuSection(
            children: [
              ProfileMenuItem(
                icon: Icons.logout,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () => _confirmSignOut(context, vm),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, ProfileViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vm.signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    }
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}