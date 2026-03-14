// Step 1: Inventory
// This file DEFINES:
//   - OnboardingLoadingScreen (StatefulWidget) — accepts full profile data via constructor
//   - _OnboardingLoadingScreenState — holds _currentMessage, _messageIndex, two Timers
//   - _saveProfileAndNavigate() — saves to DB + SharedPreferences + UserProfileProvider, then navigates
//
// Constructor params needed (from OnboardingQuizScreen spec):
//   - name: String
//   - dob: String (date of birth)
//   - birthTime: String
//   - location: String (city)
//   - birthCountry: String
//   - timezone: String
//   - archetypeId: int
//   - archetypeAnswers: String (JSON)
//
// This file USES from other files:
//   - StarBackground (from lib/widgets/star_background.dart)
//   - DatabaseService, UserProfile, ZodiacProfile (from lib/services/database_service.dart)
//   - CosmicService (from lib/services/cosmic_service.dart) — for ZodiacProfile placeholder values
//   - UserProfileProvider (from lib/providers/user_profile_provider.dart)
//   - MainShell (from lib/screens/main_shell.dart)
//
// Step 2: Connections
// - OnboardingQuizScreen navigates TO this screen via Navigator.pushReplacement with all profile data
// - This screen navigates TO MainShell via Navigator.pushAndRemoveUntil after 3 seconds
// - _saveProfileAndNavigate() calls:
//   * DatabaseService.instance.saveUserProfile(profile)
//   * DatabaseService.instance.saveZodiacProfile(zodiac)
//   * SharedPreferences.setString('user_profile_json', jsonEncode(profile.toJson()))
//   * SharedPreferences.setBool('onboarding_complete', true)
//   * context.read<UserProfileProvider>().saveProfile(profile)
//
// Step 3: User Journey Trace
// - Screen appears → initState starts Timer.periodic(600ms) cycling messages
// - initState also starts Timer(3s) → _saveProfileAndNavigate()
// - User sees: logo "cosmiq.guru", "Mapping your cosmic blueprint...", cycling message, purple spinner
// - After 3s: profile saved, navigate to MainShell removing all previous routes
// - If DB save fails: still navigate (per edge case spec: "still navigate to MainShell")
//
// Step 4: Layout Sanity
// - Scaffold > Stack([StarBackground, SafeArea > Center > Column])
// - Column is centered vertically — no scroll needed, all content fits
// - AnimatedSwitcher wraps _currentMessage text with ValueKey for proper animation
// - Both timers must be cancelled in dispose()
// - UserProfile needs a UUID id — use uuid package? Check if it's in pubspec...
//   The spec mentions uuid package in database_service reasoning. Use uuid package.
//   Actually, looking at the project files, I'll generate a simple UUID using DateTime + hashCode
//   to avoid adding a new dependency. Or better: use the uuid package which is likely in pubspec.
//   The database_service.dart reasoning mentions "uuid package for generating UUIDs" — so it's available.
//   Use package:uuid/uuid.dart for generating profile ID.
// - Provider package is used (ChangeNotifierProvider in main.dart) so context.read<> is from provider package
// - Import: package:provider/provider.dart for context.read<UserProfileProvider>()
//
// ZodiacProfile construction from CosmicService:
//   - id: new UUID
//   - userId: profile.id
//   - sunSign: CosmicService.getSunSign()
//   - moonSign: CosmicService.getMoonSign()
//   - risingSign: CosmicService.getRisingSign()
//   - chineseAnimal: CosmicService.getChineseZodiacProfile()['animal']
//   - chineseElement: CosmicService.getChineseZodiacProfile()['element']
//   - chineseYinYang: CosmicService.getChineseZodiacProfile()['yinYang']
//   - chineseInnerAnimal: CosmicService.getChineseZodiacProfile()['innerAnimal']
//   - chineseSecretAnimal: CosmicService.getChineseZodiacProfile()['secretAnimal']
//   - burmeseDay: CosmicService.getMahaboteProfile()['birthDay']
//   - burmeseAnimal: CosmicService.getMahaboteProfile()['animal']
//   - burmesePlanet: CosmicService.getMahaboteProfile()['planet']
//   - burmeseDirection: CosmicService.getMahaboteProfile()['direction']
//   - lifePathNumber: CosmicService.getLifePathNumber()
//   - expressionNumber: CosmicService.getExpressionNumber()
//   - soulUrgeNumber: CosmicService.getSoulUrgeNumber()
//   - personalityNumber: CosmicService.getPersonalityNumber()
//   - isMasterLifePath: CosmicService.isMasterNumber(CosmicService.getLifePathNumber()) ? 1 : 0
//   - createdAt: DateTime.now().toIso8601String()

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/screens/main_shell.dart';

class OnboardingLoadingScreen extends StatefulWidget {
  final String name;
  final String dob;
  final String birthTime;
  final String location;
  final String birthCountry;
  final String timezone;
  final int archetypeId;
  final String archetypeAnswers;

  const OnboardingLoadingScreen({
    super.key,
    required this.name,
    required this.dob,
    required this.birthTime,
    required this.location,
    required this.birthCountry,
    required this.timezone,
    required this.archetypeId,
    required this.archetypeAnswers,
  });

  @override
  State<OnboardingLoadingScreen> createState() =>
      _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends State<OnboardingLoadingScreen> {
  static const List<String> _messages = [
    'Reading the stars...',
    'Calculating your numbers...',
    'Consulting the lunar cycle...',
    'Mapping your archetypes...',
    'Aligning your cosmic profile...',
  ];

  String _currentMessage = 'Reading the stars...';
  int _messageIndex = 0;

  Timer? _messageTimer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Cycle loading messages every 600ms
    _messageTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() {
        _messageIndex++;
        _currentMessage = _messages[_messageIndex % _messages.length];
      });
    });

    // After 3 seconds, save profile and navigate
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _saveProfileAndNavigate();
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveProfileAndNavigate() async {
    final now = DateTime.now().toIso8601String();
    const uuid = Uuid();
    final profileId = uuid.v4();

    final profile = UserProfile(
      id: profileId,
      fullName: widget.name,
      dateOfBirth: widget.dob,
      birthTime: widget.birthTime,
      birthCity: widget.location,
      birthCountry: widget.birthCountry,
      timezone: widget.timezone,
      archetypeId: widget.archetypeId,
      archetypeAnswers: widget.archetypeAnswers,
      createdAt: now,
      updatedAt: now,
    );

    // Build ZodiacProfile from real calculation engines
    final chineseProfile = CosmicService.getChineseZodiacProfile(
      dob: widget.dob,
      birthTime: widget.birthTime,
    );
    final mahaboteProfile = CosmicService.getMahaboteProfile(
      dob: widget.dob,
      birthTime: widget.birthTime,
    );
    final lifePathNumber = CosmicService.getLifePathNumber(dob: widget.dob);

    final zodiac = ZodiacProfile(
      id: uuid.v4(),
      userId: profileId,
      sunSign: CosmicService.getSunSign(dob: widget.dob),
      moonSign: CosmicService.getMoonSign(dob: widget.dob),
      risingSign: CosmicService.getRisingSign(
        dob: widget.dob,
        birthTime: widget.birthTime,
      ),
      chineseAnimal: chineseProfile['animal'] as String,
      chineseElement: chineseProfile['element'] as String,
      chineseYinYang: chineseProfile['yinYang'] as String,
      chineseInnerAnimal: chineseProfile['innerAnimal'] as String,
      chineseSecretAnimal: chineseProfile['secretAnimal'] as String,
      burmeseDay: mahaboteProfile['birthDay'] as String,
      burmeseAnimal: mahaboteProfile['animal'] as String,
      burmesePlanet: mahaboteProfile['planet'] as String,
      burmeseDirection: mahaboteProfile['direction'] as String,
      lifePathNumber: lifePathNumber,
      expressionNumber: CosmicService.getExpressionNumber(fullName: widget.name),
      soulUrgeNumber: CosmicService.getSoulUrgeNumber(fullName: widget.name),
      personalityNumber: CosmicService.getPersonalityNumber(fullName: widget.name),
      isMasterLifePath: CosmicService.isMasterNumber(lifePathNumber) ? 1 : 0,
      createdAt: now,
    );

    try {
      // Save to SQLite database
      await DatabaseService.instance.saveUserProfile(profile);
      await DatabaseService.instance.saveZodiacProfile(zodiac);
    } catch (e) {
      // DB save failure is non-fatal — continue with navigation
      debugPrint('OnboardingLoadingScreen: DB save error: $e');
    }

    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_profile_json', jsonEncode(profile.toJson()));
      await prefs.setBool('onboarding_complete', true);
    } catch (e) {
      debugPrint('OnboardingLoadingScreen: SharedPreferences save error: $e');
    }

    // Update UserProfileProvider in memory
    if (mounted) {
      context.read<UserProfileProvider>().saveProfile(profile);
    }

    // Navigate to MainShell, clearing the entire back stack
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
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
                  // App logo
                  Text(
                    'cosmiq.guru',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 28,
                      color: const Color(0xFFF59E0B),
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Main loading title
                  const Text(
                    'Mapping your cosmic blueprint...',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Cycling message with AnimatedSwitcher fade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _currentMessage,
                      key: ValueKey<String>(_currentMessage),
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Purple circular progress indicator
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                      strokeWidth: 2,
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