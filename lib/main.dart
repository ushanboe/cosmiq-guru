// Step 1: Inventory
// This file DEFINES:
//   - main() async function — initializes services and calls runApp()
//   - No classes defined here — just the entry point
//
// This file USES from other files:
//   - DatabaseService.instance.init() from package:cosmiq_guru/services/database_service.dart
//   - NotificationService.instance.init() from package:cosmiq_guru/services/notification_service.dart
//   - UserProfileProvider from package:cosmiq_guru/providers/user_profile_provider.dart
//   - CosmiqApp from package:cosmiq_guru/app.dart
//
// All of these files exist in the manifest and have been generated already.
// DatabaseService has static instance + init() — confirmed.
// NotificationService has static instance + init() — confirmed.
// UserProfileProvider is a ChangeNotifier with loadProfile() — confirmed.
// CosmiqApp is a StatelessWidget in app.dart — confirmed.
//
// Step 2: Connections
// - main.dart → DatabaseService.init(): await DatabaseService.instance.init()
// - main.dart → NotificationService.init(): await NotificationService.instance.init()
// - main.dart → UserProfileProvider: ChangeNotifierProvider<UserProfileProvider>(create: (_) => UserProfileProvider()..loadProfile())
// - main.dart → CosmiqApp: runApp(ChangeNotifierProvider(child: CosmiqApp()))
// - CosmiqApp sets home: SplashScreen() which handles all routing
//
// Step 3: User Journey Trace
// 1. App launches → main() called
// 2. WidgetsFlutterBinding.ensureInitialized() called (required for async before runApp)
// 3. await DatabaseService.instance.init() — opens sqflite DB, creates tables
// 4. await NotificationService.instance.init() — initializes flutter_local_notifications
// 5. runApp(ChangeNotifierProvider<UserProfileProvider>(...child: CosmiqApp()))
// 6. CosmiqApp builds MaterialApp with dark theme, home: SplashScreen()
// 7. SplashScreen checks SharedPreferences and routes accordingly
//
// Step 4: Layout Sanity
// - No layout in this file — pure entry point
// - ChangeNotifierProvider wraps CosmiqApp (not just MaterialApp) so Provider is available everywhere
// - UserProfileProvider()..loadProfile() — cascade operator calls loadProfile() immediately after construction
// - WidgetsFlutterBinding.ensureInitialized() is REQUIRED before any async calls in main()
// - Import provider package for ChangeNotifierProvider
// - No GoRouter, no Riverpod — using Navigator + ChangeNotifier per spec

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/app.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/services/notification_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.init();
  await NotificationService.instance.init();

  runApp(
    ChangeNotifierProvider<UserProfileProvider>(
      create: (_) => UserProfileProvider()..loadProfile(),
      child: const CosmiqApp(),
    ),
  );
}