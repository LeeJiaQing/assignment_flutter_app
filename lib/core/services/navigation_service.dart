// lib/core/services/navigation_service.dart
//
// A singleton that holds a GlobalKey<NavigatorState> so any widget
// can navigate or access the NavigationViewModel without a BuildContext.
import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  NavigatorState? get navigator => navigatorKey.currentState;

  /// Convenience: pop all routes back to the first (home) screen.
  void popToRoot() {
    navigator?.popUntil((route) => route.isFirst);
  }
}