// Step 1: Inventory
// This file DEFINES:
//   - OnboardingNameScreen (StatefulWidget) — no constructor params (entry point of onboarding)
//   - _OnboardingNameScreenState — holds _nameController, _isNextEnabled
//   - _buildProgressDot(int step, bool isActive) — builds progress indicator dot
//   - _onNext() — navigates to OnboardingBirthScreen with name
//   - initState/dispose — sets up and tears down controller + listener
//
// This file USES from other files:
//   - StarBackground (from lib/widgets/star_background.dart) — no constructor params, purely visual
//   - OnboardingBirthScreen (from lib/screens/onboarding_birth_screen.dart) — constructor: name (String)
//
// Step 2: Connections
// - SplashScreen navigates TO this screen via Navigator.pushReplacement if onboarding_complete != true
// - SettingsScreen navigates TO this screen via Navigator.push for profile reset
// - This screen navigates FORWARD to OnboardingBirthScreen(name: _nameController.text.trim())
// - No back navigation needed (first screen in onboarding flow)
//
// Step 3: User Journey Trace
// - User arrives at OnboardingNameScreen (from SplashScreen or SettingsScreen)
// - Sees star background, "cosmiq.guru" logo, welcome text, subtitle
// - TextField is empty → Continue button is disabled (30% opacity)
// - User types their name → _nameController listener fires → setState(_isNextEnabled = true)
// - Continue button becomes enabled (full purple)
// - User taps Continue → _onNext() called → Navigator.push(OnboardingBirthScreen(name: trimmed name))
// - Progress dots show dot 1 active, dots 2 and 3 inactive
//
// Step 4: Layout Sanity
// - Column inside SafeArea/Padding — no unbounded height issues
// - Spacer() between TextField and progress dots — pushes bottom content down
// - TextEditingController declared as class field — correct
// - _nameController disposed in dispose() — correct
// - onPressed: _nameController.text.trim().isEmpty ? null : _onNext — matches spec exactly
// - The spec says _isNextEnabled tracks state, but onPressed uses direct check on controller text
//   I'll use both: listener updates _isNextEnabled, onPressed uses _isNextEnabled for clean code
// - No scrollable inside non-scrollable — Column with Spacer is fine here
// - Scaffold has backgroundColor set, no AppBar (onboarding screens typically don't have one)

import 'package:flutter/material.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/screens/onboarding_birth_screen.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final isNonEmpty = _nameController.text.trim().isNotEmpty;
    if (isNonEmpty != _isNextEnabled) {
      setState(() {
        _isNextEnabled = isNonEmpty;
      });
    }
  }

  void _onNext() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingBirthScreen(name: name),
      ),
    );
  }

  Widget _buildProgressDot(int step, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF7C3AED)
            : const Color(0xFF7C3AED).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(
        children: [
          const StarBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'cosmiq.guru',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 24,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Welcome, cosmic traveler',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'What name do the stars know you by?',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Raleway',
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Your full name',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 2,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    cursorColor: const Color(0xFFF59E0B),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressDot(1, true),
                      const SizedBox(width: 8),
                      _buildProgressDot(2, false),
                      const SizedBox(width: 8),
                      _buildProgressDot(3, false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isNextEnabled ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue →',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}