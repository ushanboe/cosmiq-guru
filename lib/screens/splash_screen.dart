// Step 1: Inventory
// This file DEFINES:
//   - SplashScreen (StatefulWidget) — no constructor params
//   - _SplashScreenState — initState checks SharedPreferences, navigates after 1 second
//   - No state variables per spec (navigation happens via timer, no visible state changes)
//
// This file USES from other files:
//   - StarBackground from package:cosmiq_guru/widgets/star_background.dart — confirmed in manifest
//   - MainShell from package:cosmiq_guru/screens/main_shell.dart — confirmed in manifest
//   - OnboardingNameScreen from package:cosmiq_guru/screens/onboarding_name_screen.dart — confirmed in manifest
//   - SharedPreferences from shared_preferences package
//
// Step 2: Connections
// - main.dart sets home: SplashScreen() — this is the entry point
// - SplashScreen → MainShell: Navigator.pushReplacement if onboarding_complete == true
// - SplashScreen → OnboardingNameScreen: Navigator.pushReplacement if onboarding_complete != true
// - No back navigation (pushReplacement removes splash from stack)
//
// Step 3: User Journey Trace
// - App launches → SplashScreen renders
// - User sees dark background with star field, "cosmiq.guru" in gold Cinzel, subtitle in white54
// - initState: Timer(1 second) fires → await SharedPreferences.getInstance()
// - Read 'onboarding_complete' bool
// - If true → Navigator.pushReplacement to MainShell
// - If false/null/exception → Navigator.pushReplacement to OnboardingNameScreen
// - Error handling: try/catch around SharedPreferences read, default to onboarding on error
//
// Step 4: Layout Sanity
// - Scaffold > Stack([StarBackground, SafeArea > Center > Column])
// - Column with mainAxisAlignment.center — no unbounded height issues (Center handles it)
// - No scrollable inside non-scrollable
// - No AppBar on splash screen — correct
// - Timer uses Future.delayed pattern or dart:async Timer
// - Must check mounted before calling Navigator after async gap
// - StarBackground fills entire screen as first child in Stack — correct
// - Text widgets are simple, no dynamic data needed
// - backgroundColor: Color(0xFF0F0A1A) per spec

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/screens/main_shell.dart';
import 'package:cosmiq_guru/screens/onboarding_name_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    bool onboardingComplete = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {
      onboardingComplete = false;
    }

    if (!mounted) return;

    if (onboardingComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingNameScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(
        children: [
          const StarBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'cosmiq.guru',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 36,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'your cosmic operating system',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}