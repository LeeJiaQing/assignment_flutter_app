// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/repositories/auth_repository.dart';
import 'core/supabase/supabase_config.dart';
import 'features/home/main_navigation.dart';
import 'features/home/viewmodels/navigation_view_model.dart';

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
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: Color(0xFF3A4F3A),
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Color(0xFF3A4F3A)),
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}