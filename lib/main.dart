import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/booking/booking_provider.dart';
import 'features/home/main_navigation.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BookingProvider(),
      child: const MainApp(), // every child under MainApp class can use CartProvider
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}