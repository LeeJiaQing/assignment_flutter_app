// lib/core/services/navigation_service.dart
//
// Singleton holding a GlobalKey<NavigatorState> AND a direct reference to
// the NavigationViewModel so we can switch tabs from anywhere.
import 'package:flutter/material.dart';

import '../../features/home/viewmodels/navigation_view_model.dart';

class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get navigator => navigatorKey.currentState;

  /// Holds a direct reference to NavigationViewModel once MainNavigation builds.
  /// Set from MainNavigation so we can switch tabs from anywhere.
  NavigationViewModel? navigationViewModel;

  /// Pop all routes back to the first (home) screen.
  void popToRoot() {
    navigator?.popUntil((route) => route.isFirst);
  }

  /// Pop to root and switch to a given tab index.
  void popToRootAndSwitchTab(int tabIndex) {
    popToRoot();
    // Use a post-frame callback so the pop animation completes first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationViewModel?.setTab(tabIndex);
    });
  }
}