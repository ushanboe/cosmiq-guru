// Step 1: Inventory
// This file DEFINES:
//   - UserProfileProvider (ChangeNotifier class)
//   - Fields: _profile (UserProfile?), _zodiacProfile (ZodiacProfile?), _isDarkMode (bool)
//   - Getters: profile, zodiacProfile, isDarkMode
//   - Methods: loadProfile(), saveProfile(UserProfile), setTheme(bool), clearProfile()
//
// This file USES from other files:
//   - UserProfile (from lib/services/database_service.dart) — model class with toJson/fromJson
//   - ZodiacProfile (from lib/services/database_service.dart) — model class
//   - DatabaseService (from lib/services/database_service.dart) — singleton with saveUserProfile()
//
// Imports needed:
//   - flutter/foundation.dart (ChangeNotifier)
//   - shared_preferences/shared_preferences.dart
//   - dart:convert (jsonEncode/jsonDecode)
//   - package:cosmiq_guru/services/database_service.dart (UserProfile, ZodiacProfile, DatabaseService)
//
// Step 2: Connections
// - main.dart wraps app with ChangeNotifierProvider<UserProfileProvider>(create: (_) => UserProfileProvider()..loadProfile())
// - OnboardingLoadingScreen calls context.read<UserProfileProvider>().saveProfile(profile)
// - SettingsScreen reads context.read<UserProfileProvider>().profile and calls saveProfile(updatedProfile)
// - HomeScreen reads context.read<UserProfileProvider>().profile?.fullName
// - setTheme() is called from SettingsScreen when theme toggle changes
// - clearProfile() is called from SettingsScreen after DatabaseService.clearAll()
//
// Step 3: User Journey Trace
// loadProfile():
//   1. Get SharedPreferences instance
//   2. Read 'user_profile_json' string
//   3. If not null/empty: jsonDecode -> UserProfile.fromJson -> set _profile
//   4. Read 'theme_dark' bool (default true) -> set _isDarkMode
//   5. notifyListeners()
//
// saveProfile(UserProfile profile):
//   1. Set _profile = profile
//   2. Save to SharedPreferences as JSON: prefs.setString('user_profile_json', jsonEncode(profile.toJson()))
//   3. Save to DatabaseService: await DatabaseService.instance.saveUserProfile(profile)
//   4. notifyListeners()
//
// setTheme(bool isDark):
//   1. Set _isDarkMode = isDark
//   2. Save to SharedPreferences: prefs.setBool('theme_dark', isDark)
//   3. notifyListeners()
//
// clearProfile():
//   1. Set _profile = null
//   2. Set _zodiacProfile = null
//   3. notifyListeners()
//
// Step 4: Layout Sanity
// - Pure ChangeNotifier — no widgets, no layout concerns
// - All async methods handle errors gracefully
// - _isDarkMode defaults to true (dark theme by default per spec)
// - SharedPreferences keys match what other files use: 'user_profile_json', 'theme_dark'

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmiq_guru/services/database_service.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  ZodiacProfile? _zodiacProfile;
  bool _isDarkMode = true;

  // ─────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────

  UserProfile? get profile => _profile;
  ZodiacProfile? get zodiacProfile => _zodiacProfile;
  bool get isDarkMode => _isDarkMode;

  // ─────────────────────────────────────────────
  // LOAD PROFILE
  // ─────────────────────────────────────────────

  /// Loads the user profile from SharedPreferences JSON string.
  /// Also loads the theme preference.
  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme preference (default: dark mode enabled)
      _isDarkMode = prefs.getBool('theme_dark') ?? true;

      // Load user profile from JSON string
      final profileJson = prefs.getString('user_profile_json');
      if (profileJson != null && profileJson.isNotEmpty) {
        final decoded = jsonDecode(profileJson) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(decoded);
      }

      // Attempt to load zodiac profile from database if we have a user profile
      if (_profile != null) {
        try {
          _zodiacProfile =
              await DatabaseService.instance.getZodiacProfile(_profile!.id);
        } catch (_) {
          // Zodiac profile may not exist yet — silently ignore
          _zodiacProfile = null;
        }
      }
    } catch (e) {
      // If loading fails, keep defaults (null profile, dark mode true)
      _profile = null;
      _zodiacProfile = null;
      _isDarkMode = true;
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SAVE PROFILE
  // ─────────────────────────────────────────────

  /// Saves the given [profile] to SharedPreferences (as JSON) and to DatabaseService.
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_profile_json', jsonEncode(profile.toJson()));
      await DatabaseService.instance.saveUserProfile(profile);
    } catch (e) {
      // Profile is already set in memory; persistence failure is non-fatal
      debugPrint('UserProfileProvider.saveProfile error: $e');
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SET ZODIAC PROFILE
  // ─────────────────────────────────────────────

  /// Updates the in-memory zodiac profile (called after onboarding loading saves it).
  void setZodiacProfile(ZodiacProfile zodiac) {
    _zodiacProfile = zodiac;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SET THEME
  // ─────────────────────────────────────────────

  /// Sets the dark/light mode preference, persists to SharedPreferences.
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_dark', isDark);
    } catch (e) {
      debugPrint('UserProfileProvider.setTheme error: $e');
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // CLEAR PROFILE
  // ─────────────────────────────────────────────

  /// Clears the in-memory profile and zodiac profile (called after data reset).
  void clearProfile() {
    _profile = null;
    _zodiacProfile = null;
    notifyListeners();
  }
}