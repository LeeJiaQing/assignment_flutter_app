// lib/features/auth/auth_gate.dart
import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../auth/login_screen.dart';
import '../home/main_navigation.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/local/local_database.dart';
import '../../core/repositories/offline_booking_repository.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500)); // splash feel
    if (!mounted) return;
    setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const _SplashScreen();
    }

    final isSignedIn = supabase.auth.currentUser != null;
    if (isSignedIn) {
      return const MainNavigationWrapper();
    }
    return const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C894E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'CourtNow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book your court, play your game',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper that provides NavigationViewModel
class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}
