// Step 1: Inventory
// This file DEFINES:
//   - StreakService (static class)
//   - checkAndUpdateStreak() -> Future<int>: reads last_open_date from SharedPreferences,
//     compares to today, increments/resets/preserves streak accordingly, saves back, returns current streak
//   - getCurrentStreak() -> Future<int>: reads current streak value from SharedPreferences and returns it
//
// SharedPreferences keys used:
//   - 'streak_current': int — current streak count
//   - 'streak_longest': int — longest streak ever
//   - 'streak_last_open_date': String — last date the app was opened (format: yyyy-MM-dd)
//
// This file USES from other files: NOTHING — only SharedPreferences package
// Imports needed: flutter/material.dart (for DateUtils), shared_preferences, intl or dart:core DateTime
//
// Step 2: Connections
// - HomeScreen calls StreakService.checkAndUpdateStreak() in initState
//   final streak = await StreakService.checkAndUpdateStreak();
//   setState(() => _streakCount = streak);
// - No navigation from this file
// - No services or models used
//
// Step 3: User Journey Trace
// checkAndUpdateStreak():
//   1. Get SharedPreferences instance
//   2. Read 'streak_last_open_date' string (may be null/empty)
//   3. Read 'streak_current' int (default 0)
//   4. Get today's date as yyyy-MM-dd string
//   5. If last_open_date is null/empty: first time opening — set streak to 1
//   6. If last_open_date == today: same day open — preserve streak (already counted today)
//   7. If last_open_date == yesterday: consecutive day — increment streak
//   8. If last_open_date < yesterday: streak broken — reset to 1
//   9. Save updated streak_current and streak_last_open_date to SharedPreferences
//   10. Update streak_longest if current > longest
//   11. Return the updated streak count
//
// getCurrentStreak():
//   1. Get SharedPreferences instance
//   2. Read 'streak_current' int (default 0)
//   3. Return it
//
// Step 4: Layout Sanity
// - Pure service class, no widgets, no layout concerns
// - Use DateTime arithmetic for yesterday comparison
// - Format dates as 'yyyy-MM-dd' for consistent string comparison
// - No dart:intl needed — can use DateTime directly with manual formatting

import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  StreakService._(); // Private constructor — static-only class

  static const String _keyCurrentStreak = 'streak_current';
  static const String _keyLongestStreak = 'streak_longest';
  static const String _keyLastOpenDate = 'streak_last_open_date';

  /// Formats a DateTime as 'yyyy-MM-dd' for consistent date comparison.
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Checks today's date against the last open date and updates the streak accordingly.
  /// Logic:
  ///   - No previous date recorded → first open, streak = 1
  ///   - Last open == today → same session, preserve streak
  ///   - Last open == yesterday → consecutive day, increment streak
  ///   - Last open < yesterday → streak broken, reset to 1
  /// Returns the updated current streak count.
  static Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayStr = _formatDate(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = _formatDate(yesterday);

    final lastOpenDate = prefs.getString(_keyLastOpenDate) ?? '';
    int currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    int longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;

    if (lastOpenDate.isEmpty) {
      // First time opening the app
      currentStreak = 1;
    } else if (lastOpenDate == todayStr) {
      // Already opened today — preserve the current streak, no change needed
      return currentStreak;
    } else if (lastOpenDate == yesterdayStr) {
      // Opened yesterday — consecutive day, increment streak
      currentStreak += 1;
    } else {
      // Missed one or more days — streak is broken, reset to 1
      currentStreak = 1;
    }

    // Update longest streak if current surpasses it
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      await prefs.setInt(_keyLongestStreak, longestStreak);
    }

    // Persist updated values
    await prefs.setInt(_keyCurrentStreak, currentStreak);
    await prefs.setString(_keyLastOpenDate, todayStr);

    return currentStreak;
  }

  /// Returns the current streak count from SharedPreferences without modifying it.
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  /// Returns the longest streak ever recorded.
  static Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLongestStreak) ?? 0;
  }

  /// Resets all streak data (used when clearing app data from Settings).
  static Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLongestStreak);
    await prefs.remove(_keyLastOpenDate);
  }
}