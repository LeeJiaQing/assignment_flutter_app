// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/repositories/auth_repository.dart';
import 'core/supabase/supabase_config.dart';
import 'features/admin/create_facility_screen.dart';
import 'features/admin/edit_facility_screen.dart';
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
  await SupabaseConfig.init();
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
        // Named routes for deep navigation from profile menu items,
        // admin dashboard etc. Screens that need arguments use
        // Navigator.push directly with MaterialPageRoute.
        routes: {
          '/bookings': (_) => const BookingScreen(),
          '/rewards': (_) => const RewardPointsScreen(),
          '/feedback': (_) => const CreateFeedbackScreen(),
          '/terms': (_) => const TermsConditionsScreen(),
          '/notifications': (_) => const NotificationScreen(),
          '/profile/edit': (_) => const EditProfileScreen(),
          '/party/create': (_) => const CreatePartyScreen(),
          '/admin/facility/create': (_) => const CreateFacilityScreen(),
        },
        // Routes that require arguments are handled with onGenerateRoute.
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