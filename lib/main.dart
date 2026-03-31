// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/local/local_database.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/offline_booking_repository.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/supabase/supabase_config.dart';
import 'features/admin/create_facility_screen.dart';
import 'features/admin/edit_facility_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/booking/create_party_screen.dart';
import 'features/feedback/create_feedback_screen.dart';
import 'features/home/main_navigation.dart';
import 'features/home/viewmodels/navigation_view_model.dart';
import 'features/notification/notification_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/terms_conditions_screen.dart';
import 'features/rewardPoints/rewardpoints_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase
  await SupabaseConfig.init();

  // 2. SQLite — initialise FFI on Windows/Linux, then warm up the connection
  LocalDatabase.initFfiIfNeeded();
  await LocalDatabase.instance.database;

  // 3. Connectivity monitoring
  ConnectivityService.instance.startMonitoring();

  // 4. Background sync service (syncs pending bookings on reconnect)
  SyncService.instance.init(
    bookingRepository: OfflineBookingRepository(),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NavigationViewModel(
            authRepository: AuthRepository(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1C894E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4FAF6),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Color(0xFF3A4F3A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            iconTheme: IconThemeData(color: Color(0xFF3A4F3A)),
          ),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
        routes: {
          '/bookings': (_) => const BookingScreen(),
          '/rewards': (_) => const RewardPointsScreen(),
          '/feedback': (_) => const CreateFeedbackScreen(),
          '/terms': (_) => const TermsConditionsScreen(),
          '/notifications': (_) => const NotificationScreen(),
          '/profile/edit': (_) => const EditProfileScreen(),
          '/party/create': (_) => const CreatePartyScreen(),
          '/admin/facility/create': (_) => const CreateFacilityScreen(),
          '/auth/login': (_) => const LoginScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/admin/facility/edit':
              final facility = settings.arguments;
              if (facility == null) return null;
              return MaterialPageRoute(
                builder: (_) => EditFacilityScreen(
                  facility: facility as dynamic,
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}