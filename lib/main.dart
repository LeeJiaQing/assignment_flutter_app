// lib/main.dart
import 'package:assignment/core/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'core/local/local_database.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/facility_repository.dart';
import 'core/repositories/offline_facility_repository.dart';
import 'core/repositories/offline_booking_repository.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/sync_service.dart';
import 'core/supabase/supabase_config.dart';
import 'features/admin/admin_announcement_screen.dart';
import 'features/admin/admin_terms_screen.dart';
import 'features/admin/create_facility_screen.dart';
import 'features/admin/edit_facility_screen.dart';
import 'features/admin/user_list_screen.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/booking/create_party_screen.dart';
import 'features/facility/facility_screen.dart';
import 'features/feedback/create_feedback_screen.dart';
import 'features/home/main_navigation.dart';
import 'features/notification/notification_screen.dart';
import 'features/party/myparty_screen_page.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/terms_conditions_screen.dart';
import 'features/profile/viewmodels/profile_view_model.dart';
import 'features/rewardPoints/rewardpoints_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();

  LocalDatabase.initFfiIfNeeded();
  await LocalDatabase.instance.database;

  ConnectivityService.instance.startMonitoring();

  SyncService.instance.init(
    bookingRepository: OfflineBookingRepository(),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies(
      authRepository: AuthRepository(),
      facilityRepository: FacilityRepository(),
      offlineFacilityRepository: OfflineFacilityRepository(),
    );

    return Provider.value(
      value: dependencies,
      child: MaterialApp(
        navigatorKey: NavigationService.instance.navigatorKey,
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
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainNavigation(),
        '/facility': (_) => const FacilityScreen(),
        '/bookings': (_) => const BookingScreen(),
        '/rewards': (_) => const RewardPointsScreen(),
        '/feedback': (_) => const CreateFeedbackScreen(),
        '/terms': (_) => const TermsConditionsScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/profile/edit': (_) => ChangeNotifierProvider(
          create: (_) =>
          ProfileViewModel(
            authRepository: dependencies.authRepository,
          )..loadProfile(),
          child: const EditProfileScreen(),
        ),
        '/party/create': (_) => const CreatePartyScreen(),
        '/party/my': (_) => const MyPartyScreenPage(),
        '/admin/facility/create': (_) =>
        const CreateFacilityScreen(),
        '/admin/announcement': (_) =>
        const AdminAnnouncementScreen(),
        '/admin/users': (_) => const UserListScreen(),
        '/admin/terms/edit': (_) => const AdminTermsScreen(),
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
