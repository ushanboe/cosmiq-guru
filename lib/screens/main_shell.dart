// Step 1: Inventory
// This file DEFINES:
//   - MainShell (StatefulWidget) — the bottom navigation shell
//   - _MainShellState — holds _selectedIndex int
//   - BottomNavigationBar with 4 items: Home/auto_awesome, Explore/explore, Match/favorite, Settings/settings
//   - IndexedStack with 4 screens: HomeScreen, LuckBreakdownScreen, CompatibilityScreen, SettingsScreen
//
// State variables:
//   - _selectedIndex: int = 0
//
// This file USES from other files:
//   - HomeScreen from package:cosmiq_guru/screens/home_screen.dart
//   - LuckBreakdownScreen from package:cosmiq_guru/screens/luck_breakdown_screen.dart
//   - CompatibilityScreen from package:cosmiq_guru/screens/compatibility_screen.dart
//   - SettingsScreen from package:cosmiq_guru/screens/settings_screen.dart
//
// All 4 screen files exist in the project manifest — confirmed.
//
// Step 2: Connections
// - SplashScreen navigates TO MainShell (pushReplacement when onboarding_complete == true)
// - OnboardingLoadingScreen navigates TO MainShell (pushAndRemoveUntil)
// - MainShell renders HomeScreen at index 0
// - MainShell renders LuckBreakdownScreen at index 1
// - MainShell renders CompatibilityScreen at index 2
// - MainShell renders SettingsScreen at index 3
// - No navigation FROM MainShell — it IS the navigation container
//
// Step 3: User Journey Trace
// - User lands on MainShell (from SplashScreen or OnboardingLoadingScreen)
// - Default _selectedIndex = 0 → HomeScreen visible
// - User taps "Explore" tab → setState _selectedIndex = 1 → LuckBreakdownScreen visible
// - User taps "Match" tab → setState _selectedIndex = 2 → CompatibilityScreen visible
// - User taps "Settings" tab → setState _selectedIndex = 3 → SettingsScreen visible
// - User taps "Home" tab → setState _selectedIndex = 0 → HomeScreen visible
// - IndexedStack keeps all 4 screens in memory (no re-initialization on tab switch)
//
// Step 4: Layout Sanity
// - Scaffold(body: IndexedStack, bottomNavigationBar: Container > BottomNavigationBar)
// - Container wraps BottomNavigationBar to apply custom background color + top border
// - BottomNavigationBar: backgroundColor: Colors.transparent, elevation: 0
// - Container: color: Color(0xFF1A1025), border: Border(top: BorderSide(color: Color(0xFF7C3AED).withValues(alpha: 0.5), width: 1))
// - No AppBar on MainShell — each child screen manages its own AppBar
// - selectedItemColor: Color(0xFF7C3AED), unselectedItemColor: Colors.white38
// - type: BottomNavigationBarType.fixed (required for 4+ items to show labels)
// - Scaffold backgroundColor: Color(0xFF0F0A1A) per spec
// - No elevation on BottomNavigationBar
// - Font families: Raleway for labels per spec
// - Icons: Icons.auto_awesome, Icons.explore, Icons.favorite, Icons.settings
//
// All screen imports exist in manifest. Simple StatefulWidget with setState. No Riverpod needed.
// No assets, no Image.asset, no empty callbacks.
// The onTap callback does real work: setState(() => _selectedIndex = i)

import 'package:flutter/material.dart';
import 'package:cosmiq_guru/screens/home_screen.dart';
import 'package:cosmiq_guru/screens/luck_breakdown_screen.dart';
import 'package:cosmiq_guru/screens/compatibility_screen.dart';
import 'package:cosmiq_guru/screens/settings_screen.dart';
import 'package:cosmiq_guru/screens/decision_engine_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    DecisionEngineScreen(),
    LuckBreakdownScreen(),
    CompatibilityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_fix_high),
              label: 'Decide',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}