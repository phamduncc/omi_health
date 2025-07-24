import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
  
  ValueNotifier<int> get currentTabIndex => _currentTabIndex;

  void navigateToTab(int index) {
    _currentTabIndex.value = index;
  }

  void navigateToGoals() {
    navigateToTab(2); // Goals tab is at index 2
  }

  void navigateToHome() {
    navigateToTab(1); // Home tab is at index 1
  }

  void navigateToDashboard() {
    navigateToTab(0); // Dashboard tab is at index 0
  }

  void navigateToTips() {
    navigateToTab(3); // Tips tab is at index 3
  }

  void navigateToProfile() {
    navigateToTab(4); // Profile tab is at index 4
  }

  void dispose() {
    _currentTabIndex.dispose();
  }
}
