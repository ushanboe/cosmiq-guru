// Step 1: Inventory
// This file DEFINES:
//   - CosmiqApp (StatelessWidget) — MaterialApp with dark theme, Google Fonts, home: SplashScreen()
//   - AppTheme class with static constants for colors, text styles, card decoration, button style
//   - ThemeData using ColorScheme.dark() factory with all spec colors
//
// This file USES from other files:
//   - SplashScreen from package:cosmiq_guru/screens/splash_screen.dart — confirmed in manifest, already generated
//
// Imports needed:
//   - package:flutter/material.dart
//   - package:google_fonts/google_fonts.dart
//   - package:cosmiq_guru/screens/splash_screen.dart
//
// Step 2: Connections
// - main.dart calls runApp(CosmiqApp()) — this is the root widget
// - main.dart wraps with ChangeNotifierProvider before CosmiqApp, so CosmiqApp itself is just MaterialApp
// - home: SplashScreen() — confirmed from wiring manifest
// - No navigation logic here — just theme and root setup
//
// Step 3: User Journey Trace
// - main.dart calls runApp(ChangeNotifierProvider(child: CosmiqApp()))
// - CosmiqApp.build() returns MaterialApp with dark theme and home: SplashScreen()
// - SplashScreen handles all routing from there
// - AppTheme constants are used by all other screens via AppTheme.xxx references
//
// Step 4: Layout Sanity
// - No layout in this file — pure MaterialApp configuration
// - ColorScheme.dark() factory used per spec — NEVER raw ColorScheme()
// - No background/onBackground — use surface/onSurface per spec
// - Google Fonts: Cinzel for headings, Raleway for body
// - google_fonts package applies fonts via textTheme override
// - All theme constants match spec exactly: #0F0A1A scaffold, #1A1025 card, #241538 surface, #7C3AED primary, #F59E0B secondary
// - CardThemeData (not CardTheme) per Flutter API rules
// - ElevatedButton.styleFrom with backgroundColor (not primary) per Flutter API rules
// - withValues(alpha:) not withOpacity() per Flutter API rules

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cosmiq_guru/screens/splash_screen.dart';

class AppTheme {
  // Colors
  static const Color scaffoldBackground = Color(0xFF0F0A1A);
  static const Color cardBackground = Color(0xFF1A1025);
  static const Color surfaceColor = Color(0xFF241538);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color secondaryGold = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color relationshipPink = Color(0xFFEC4899);
  static const Color moneyGreen = Color(0xFF10B981);
  static const Color careerBlue = Color(0xFF3B82F6);
  static const Color gaugeRed = Color(0xFFEF4444);
  static const Color gaugeYellow = Color(0xFFF59E0B);
  static const Color gaugeGreen = Color(0xFF10B981);

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryPurple.withValues(alpha: 0.3),
      width: 1,
    ),
  );

  // Elevated card with stronger glow
  static BoxDecoration glowCardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryPurple.withValues(alpha: 0.6),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryPurple.withValues(alpha: 0.15),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  );

  // Button style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryPurple,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 0,
  );

  // Text styles
  static TextStyle headingLarge = GoogleFonts.cinzel(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  static TextStyle headingMedium = GoogleFonts.cinzel(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 1.5,
  );

  static TextStyle headingSmall = GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 1,
  );

  static TextStyle bodyLarge = GoogleFonts.raleway(
    fontSize: 16,
    color: Colors.white70,
  );

  static TextStyle bodyMedium = GoogleFonts.raleway(
    fontSize: 14,
    color: Colors.white70,
  );

  static TextStyle bodySmall = GoogleFonts.raleway(
    fontSize: 12,
    color: Colors.white54,
  );

  static TextStyle goldLabel = GoogleFonts.cinzel(
    fontSize: 14,
    color: secondaryGold,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  // Full ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: secondaryGold,
        surface: surfaceColor,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      textTheme: GoogleFonts.ralewayTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white54),
          labelLarge: TextStyle(color: Colors.white70),
          labelMedium: TextStyle(color: Colors.white54),
          labelSmall: TextStyle(color: Colors.white54),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.white38,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryPurple,
            width: 1.5,
          ),
        ),
        labelStyle: GoogleFonts.raleway(color: Colors.white54),
        hintStyle: GoogleFonts.raleway(color: Colors.white38),
      ),
      dividerTheme: DividerThemeData(
        color: primaryPurple.withValues(alpha: 0.2),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPurple,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.raleway(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: GoogleFonts.raleway(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: cardBackground,
        collapsedBackgroundColor: cardBackground,
        iconColor: primaryPurple,
        collapsedIconColor: Colors.white54,
        textColor: Colors.white,
        collapsedTextColor: Colors.white70,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryPurple;
          return Colors.white38;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryPurple.withValues(alpha: 0.4);
          }
          return Colors.white12;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: primaryPurple.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class CosmiqApp extends StatelessWidget {
  const CosmiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cosmiq.guru',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}