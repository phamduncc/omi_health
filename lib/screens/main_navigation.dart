import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'tips_screen.dart';
import 'profile_screen.dart';
import 'utilities_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final NavigationService _navigationService = NavigationService();
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HomeScreen(),
    const GoalsScreen(),
    const UtilitiesScreen(),
    const TipsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Tổng quan',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.calculate_outlined),
      activeIcon: Icon(Icons.calculate),
      label: 'Tính toán',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.flag_outlined),
      activeIcon: Icon(Icons.flag),
      label: 'Mục tiêu',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.build_outlined),
      activeIcon: Icon(Icons.build),
      label: 'Tiện ích',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb_outlined),
      activeIcon: Icon(Icons.lightbulb),
      label: 'Lời khuyên',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Cá nhân',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to navigation service changes
    _navigationService.currentTabIndex.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _navigationService.currentTabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = _navigationService.currentTabIndex.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Update navigation service
            _navigationService.currentTabIndex.value = index;
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3498DB),
          unselectedItemColor: const Color(0xFF7F8C8D),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: _navItems,
        ),
      ),
    );
  }
}
