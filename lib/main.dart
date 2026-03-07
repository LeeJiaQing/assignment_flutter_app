import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/repositories/auth_repository.dart';
import 'core/repositories/supabase_auth_repository.dart';
import 'features/booking/booking_provider.dart';
import 'features/home/main_navigation.dart';
import 'features/home/viewmodels/navigation_view_model.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BookingProvider(),
        ),
        // ChangeNotifierProvider(
        //   create: (context) => BookingProvider(),
        // ),
        ChangeNotifierProvider(
          create: (context) => NavigationViewModel(
            authRepository: SupabaseAuthRepository(
              // Replace with real Supabase role lookup after auth integration.
              fallbackRole: UserRole.admin,
            ),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: Color(0xFF3A4F3A),
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(
              color: Color(0xFF3A4F3A),
            ),
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}
