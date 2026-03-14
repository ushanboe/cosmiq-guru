// Step 1: Inventory
// This file DEFINES:
//   - PlanetaryHoursEngine — static methods for Chaldean planetary hours
//
// This file USES from other files: NOTHING — pure math, no dependencies
//
// Step 2: Connections
// - CosmicService calls PlanetaryHoursEngine.currentPlanetaryHour() for "Best Decision Window"
// - CosmicService calls PlanetaryHoursEngine.dailyScore() for composite luck score
// - HomeScreen shows current planetary hour and best windows
//
// Step 3: User Journey Trace
// - Engine approximates sunrise/sunset from day-of-year and rough latitude
// - Divides daytime into 12 equal "planetary hours", nighttime into 12 equal hours
// - Chaldean order: Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon (repeating)
// - Day ruler = planet of the first hour after sunrise (Sun=Sunday, Moon=Monday, etc.)
// - dailyScore() checks if current planetary hour's planet is benefic or matches user's birth planet
//
// Step 4: Layout Sanity
// - No UI in this file — pure computation
// - All methods are static, no state
// - Sunrise/sunset approximation uses simplified equation of time

import 'dart:math';

class PlanetaryHoursEngine {
  // Chaldean order (descending orbital speed as understood by ancients)
  static const List<String> chaldeanOrder = [
    'Saturn',
    'Jupiter',
    'Mars',
    'Sun',
    'Venus',
    'Mercury',
    'Moon',
  ];

  // Day rulers: the planet that rules the first hour of each weekday
  // Sunday=0 in our mapping (DateTime.weekday: Monday=1..Sunday=7)
  static const Map<int, String> dayRulers = {
    DateTime.sunday: 'Sun',
    DateTime.monday: 'Moon',
    DateTime.tuesday: 'Mars',
    DateTime.wednesday: 'Mercury',
    DateTime.thursday: 'Jupiter',
    DateTime.friday: 'Venus',
    DateTime.saturday: 'Saturn',
  };

  // Planet properties for interpretation
  static const Map<String, Map<String, dynamic>> planetProperties = {
    'Sun': {
      'keywords': ['vitality', 'leadership', 'success', 'visibility'],
      'bestFor': 'Authority matters, career moves, asking for favors from superiors',
      'avoid': 'Secrecy, hiding, working behind the scenes',
      'energy': 'masculine',
      'benefic': true,
    },
    'Moon': {
      'keywords': ['intuition', 'emotions', 'travel', 'dreams'],
      'bestFor': 'Short trips, public dealings, imagination, nurturing',
      'avoid': 'Starting long-term projects, surgery',
      'energy': 'feminine',
      'benefic': true,
    },
    'Mars': {
      'keywords': ['action', 'courage', 'conflict', 'energy'],
      'bestFor': 'Physical activity, competition, confrontation, surgery',
      'avoid': 'Negotiations, peace talks, starting relationships',
      'energy': 'masculine',
      'benefic': false,
    },
    'Mercury': {
      'keywords': ['communication', 'commerce', 'learning', 'travel'],
      'bestFor': 'Writing, studying, business deals, sending messages',
      'avoid': 'Long-term commitments, emotional conversations',
      'energy': 'neutral',
      'benefic': true,
    },
    'Jupiter': {
      'keywords': ['expansion', 'luck', 'wisdom', 'abundance'],
      'bestFor': 'Financial matters, legal issues, spiritual growth, education',
      'avoid': 'Nothing major — Jupiter hours are broadly fortunate',
      'energy': 'masculine',
      'benefic': true,
    },
    'Venus': {
      'keywords': ['love', 'beauty', 'harmony', 'pleasure'],
      'bestFor': 'Romance, art, socializing, beautification, reconciliation',
      'avoid': 'Confrontation, aggressive action',
      'energy': 'feminine',
      'benefic': true,
    },
    'Saturn': {
      'keywords': ['discipline', 'restriction', 'endings', 'structure'],
      'bestFor': 'Binding agreements, property matters, meditation, endings',
      'avoid': 'Starting new ventures, asking favors, celebrations',
      'energy': 'masculine',
      'benefic': false,
    },
  };

  /// Approximate sunrise hour (decimal) for a given day of year.
  /// Uses a simplified model assuming ~35° latitude (mid-range for most users).
  /// Returns hour in 24h format (e.g., 6.5 = 6:30 AM).
  static double _approxSunrise(int dayOfYear) {
    // Simplified: sunrise varies roughly ±1.5 hours around 6:00 AM
    // Earliest around summer solstice (day ~172), latest around winter solstice (day ~355)
    final angle = 2 * pi * (dayOfYear - 172) / 365.25;
    return 6.0 + 1.5 * cos(angle);
  }

  /// Approximate sunset hour (decimal) for a given day of year.
  static double _approxSunset(int dayOfYear) {
    final angle = 2 * pi * (dayOfYear - 172) / 365.25;
    return 18.0 - 1.5 * cos(angle);
  }

  /// Get the day of year for a DateTime.
  static int _dayOfYear(DateTime dt) {
    return dt.difference(DateTime(dt.year, 1, 1)).inDays + 1;
  }

  /// Get the Chaldean order index for the day ruler of a given weekday.
  static int _dayRulerIndex(int weekday) {
    final ruler = dayRulers[weekday]!;
    return chaldeanOrder.indexOf(ruler);
  }

  /// Calculate all 24 planetary hours for a given date.
  /// Returns list of maps with 'planet', 'startHour', 'endHour', 'isDaytime'.
  static List<Map<String, dynamic>> planetaryHours(DateTime date) {
    final doy = _dayOfYear(date);
    final sunrise = _approxSunrise(doy);
    final sunset = _approxSunset(doy);

    final dayLength = sunset - sunrise;
    final nightLength = 24.0 - dayLength;
    final dayHourLength = dayLength / 12;
    final nightHourLength = nightLength / 12;

    // First daytime hour is ruled by the day's planet
    final startIndex = _dayRulerIndex(date.weekday == 7 ? DateTime.sunday : date.weekday);

    final List<Map<String, dynamic>> hours = [];

    // 12 daytime hours
    for (int i = 0; i < 12; i++) {
      final planetIndex = (startIndex + i) % 7;
      hours.add({
        'planet': chaldeanOrder[planetIndex],
        'startHour': sunrise + i * dayHourLength,
        'endHour': sunrise + (i + 1) * dayHourLength,
        'isDaytime': true,
        'hourNumber': i + 1,
      });
    }

    // 12 nighttime hours
    for (int i = 0; i < 12; i++) {
      final planetIndex = (startIndex + 12 + i) % 7;
      final startH = sunset + i * nightHourLength;
      hours.add({
        'planet': chaldeanOrder[planetIndex],
        'startHour': startH >= 24 ? startH - 24 : startH,
        'endHour': startH + nightHourLength >= 24
            ? startH + nightHourLength - 24
            : startH + nightHourLength,
        'isDaytime': false,
        'hourNumber': i + 1,
      });
    }

    return hours;
  }

  /// Get the current planetary hour info.
  /// Returns map with 'planet', 'startHour', 'endHour', 'isDaytime', 'hourNumber',
  /// plus 'properties' from planetProperties.
  static Map<String, dynamic> currentPlanetaryHour({DateTime? now}) {
    now ??= DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;
    final hours = planetaryHours(now);

    final doy = _dayOfYear(now);
    final sunrise = _approxSunrise(doy);
    final sunset = _approxSunset(doy);

    Map<String, dynamic>? current;

    if (currentHour >= sunrise && currentHour < sunset) {
      // Daytime — search daytime hours (first 12)
      for (final h in hours.sublist(0, 12)) {
        if (currentHour >= (h['startHour'] as double) &&
            currentHour < (h['endHour'] as double)) {
          current = h;
          break;
        }
      }
    } else {
      // Nighttime — search nighttime hours (last 12)
      for (final h in hours.sublist(12)) {
        final start = h['startHour'] as double;
        final end = h['endHour'] as double;

        if (end < start) {
          // Wraps past midnight
          if (currentHour >= start || currentHour < end) {
            current = h;
            break;
          }
        } else {
          if (currentHour >= start && currentHour < end) {
            current = h;
            break;
          }
        }
      }
    }

    // Fallback to first hour if not found (shouldn't happen)
    current ??= hours.first;

    final planet = current['planet'] as String;
    return {
      ...current,
      'properties': planetProperties[planet],
      'dayRuler': dayRulers[now.weekday == 7 ? DateTime.sunday : now.weekday],
    };
  }

  /// Find the next occurrence of a specific planet's hour.
  /// Useful for "best time for X" features.
  static Map<String, dynamic> nextHourOf(String planet, {DateTime? from}) {
    from ??= DateTime.now();
    final currentHour = from.hour + from.minute / 60.0;

    // Check today's remaining hours
    final todayHours = planetaryHours(from);
    for (final h in todayHours) {
      if (h['planet'] == planet) {
        final start = h['startHour'] as double;
        if (start > currentHour) {
          return {
            ...h,
            'date': from,
            'properties': planetProperties[planet],
          };
        }
      }
    }

    // Check tomorrow
    final tomorrow = from.add(const Duration(days: 1));
    final tomorrowHours = planetaryHours(tomorrow);
    for (final h in tomorrowHours) {
      if (h['planet'] == planet) {
        return {
          ...h,
          'date': tomorrow,
          'properties': planetProperties[planet],
        };
      }
    }

    // Should never reach here — every planet appears multiple times per day
    return {'planet': planet, 'error': 'not found'};
  }

  /// Get best decision windows for today — hours ruled by benefic planets.
  /// Returns list of hours sorted by start time, filtered to benefics.
  static List<Map<String, dynamic>> bestWindows({DateTime? date}) {
    date ??= DateTime.now();
    final hours = planetaryHours(date);

    return hours.where((h) {
      final planet = h['planet'] as String;
      final props = planetProperties[planet]!;
      return props['benefic'] == true;
    }).toList();
  }

  /// Format a decimal hour to "HH:MM" string.
  static String formatHour(double decimalHour) {
    if (decimalHour < 0) decimalHour += 24;
    if (decimalHour >= 24) decimalHour -= 24;
    final h = decimalHour.floor();
    final m = ((decimalHour - h) * 60).round();
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  /// Daily score (0-100) for the composite luck score.
  /// Higher when current planetary hour is benefic, day ruler is benefic,
  /// and aligns with the user's birth planet (if provided).
  static int dailyScore({String? birthPlanet, DateTime? now}) {
    now ??= DateTime.now();
    int score = 50; // baseline

    // Day ruler influence (+/- 15)
    final ruler = dayRulers[now.weekday == 7 ? DateTime.sunday : now.weekday]!;
    final rulerProps = planetProperties[ruler]!;
    if (rulerProps['benefic'] == true) {
      score += 15;
    } else {
      score -= 10;
    }

    // Current planetary hour influence (+/- 10)
    final current = currentPlanetaryHour(now: now);
    final currentPlanet = current['planet'] as String;
    final currentProps = planetProperties[currentPlanet]!;
    if (currentProps['benefic'] == true) {
      score += 10;
    } else {
      score -= 5;
    }

    // Birth planet alignment (+/- 15)
    if (birthPlanet != null) {
      if (currentPlanet == birthPlanet) {
        score += 15; // Your planet's hour — very favorable
      } else if (ruler == birthPlanet) {
        score += 10; // Your planet rules the day
      }

      // Planet friendship (simplified)
      final beneficPlanets = ['Sun', 'Moon', 'Venus', 'Jupiter', 'Mercury'];
      if (beneficPlanets.contains(birthPlanet) &&
          beneficPlanets.contains(currentPlanet)) {
        score += 5;
      }
    }

    // Day-of-week cycle variation (subtle ±5)
    final dayVariance = (sin(now.weekday * pi / 3.5) * 5).round();
    score += dayVariance;

    return score.clamp(0, 100);
  }
}
