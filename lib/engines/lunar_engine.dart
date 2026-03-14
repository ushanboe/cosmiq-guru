/// Lunar Phase Calculation Engine
/// Uses Julian Day Number and the synodic month to determine moon phase.
import 'dart:math';

class LunarEngine {
  LunarEngine._();

  /// Synodic month (new moon to new moon) in days.
  static const synodicMonth = 29.530588853;

  /// Reference new moon: January 6, 2000 at 18:14 UTC (Julian Day 2451550.26)
  static const _refNewMoonJD = 2451550.26;

  /// Moon signs (sidereal, ~2.3 days each)
  static const moonSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  /// Convert a DateTime to Julian Day Number.
  static double julianDay(DateTime dt) {
    int y = dt.year;
    int m = dt.month;
    final d = dt.day + dt.hour / 24.0 + dt.minute / 1440.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Get the moon's age in days (0 = new moon, ~14.77 = full moon).
  static double moonAge({DateTime? date}) {
    final dt = date ?? DateTime.now();
    final jd = julianDay(dt);
    final daysSinceRef = jd - _refNewMoonJD;
    final age = daysSinceRef % synodicMonth;
    return age < 0 ? age + synodicMonth : age;
  }

  /// Get the current moon phase name (8 phases).
  static String phaseName({DateTime? date}) {
    final age = moonAge(date: date);
    final fraction = age / synodicMonth;

    if (fraction < 0.0625) return 'New Moon';
    if (fraction < 0.1875) return 'Waxing Crescent';
    if (fraction < 0.3125) return 'First Quarter';
    if (fraction < 0.4375) return 'Waxing Gibbous';
    if (fraction < 0.5625) return 'Full Moon';
    if (fraction < 0.6875) return 'Waning Gibbous';
    if (fraction < 0.8125) return 'Last Quarter';
    if (fraction < 0.9375) return 'Waning Crescent';
    return 'New Moon';
  }

  /// Get the moon phase emoji.
  static String phaseEmoji({DateTime? date}) {
    final phase = phaseName(date: date);
    const emojis = {
      'New Moon': '🌑',
      'Waxing Crescent': '🌒',
      'First Quarter': '🌓',
      'Waxing Gibbous': '🌔',
      'Full Moon': '🌕',
      'Waning Gibbous': '🌖',
      'Last Quarter': '🌗',
      'Waning Crescent': '🌘',
    };
    return emojis[phase] ?? '🌙';
  }

  /// Get illumination percentage (0.0 to 1.0).
  static double illumination({DateTime? date}) {
    final age = moonAge(date: date);
    // Illumination follows a cosine curve
    return (1 - cos(2 * pi * age / synodicMonth)) / 2;
  }

  /// Approximate moon sign based on moon's position in the sidereal zodiac.
  /// The moon moves through all 12 signs in ~27.32 days (sidereal month).
  static String currentMoonSign({DateTime? date}) {
    final dt = date ?? DateTime.now();
    final jd = julianDay(dt);
    // Moon's sidereal period = 27.321661 days
    // Reference: Moon was at 0° Aries on Jan 1, 2000
    final daysSinceRef = jd - 2451544.5; // J2000.0
    final siderealPosition = (daysSinceRef / 27.321661) * 360.0;
    final signIndex = ((siderealPosition % 360) / 30).floor() % 12;
    return moonSigns[signIndex];
  }

  /// Days until next full moon.
  static int daysUntilFullMoon({DateTime? date}) {
    final age = moonAge(date: date);
    final fullMoonAge = synodicMonth / 2; // ~14.77 days
    if (age < fullMoonAge) {
      return (fullMoonAge - age).ceil();
    }
    return (synodicMonth - age + fullMoonAge).ceil();
  }

  /// Days until next new moon.
  static int daysUntilNewMoon({DateTime? date}) {
    final age = moonAge(date: date);
    return (synodicMonth - age).ceil();
  }

  /// Check if moon is approximately void-of-course.
  /// Simplified: last ~2 hours before moon changes sign.
  static bool isVoidOfCourse({DateTime? date}) {
    final dt = date ?? DateTime.now();
    final jd = julianDay(dt);
    final daysSinceRef = jd - 2451544.5;
    // Moon spends ~2.28 days in each sign
    final positionInSign = (daysSinceRef / 2.2768) % 1.0;
    // Void-of-course when in last ~8% of a sign (~4.4 hours)
    return positionInSign > 0.92;
  }

  /// Generate moon phase events for a given month.
  static List<Map<String, dynamic>> monthlyPhases(int year, int month) {
    final phases = <Map<String, dynamic>>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final age = moonAge(date: date);
      final nextAge = moonAge(date: date.add(const Duration(days: 1)));

      // Detect phase transitions
      final fraction = age / synodicMonth;
      final nextFraction = nextAge / synodicMonth;

      // New Moon (fraction crosses 0)
      if (fraction > 0.9 && nextFraction < 0.1) {
        phases.add({'date': date, 'type': 'new_moon', 'name': 'New Moon', 'emoji': '🌑'});
      }
      // First Quarter (fraction crosses 0.25)
      if (fraction < 0.25 && nextFraction >= 0.25) {
        phases.add({'date': date, 'type': 'first_quarter', 'name': 'First Quarter', 'emoji': '🌓'});
      }
      // Full Moon (fraction crosses 0.5)
      if (fraction < 0.5 && nextFraction >= 0.5) {
        phases.add({'date': date, 'type': 'full_moon', 'name': 'Full Moon', 'emoji': '🌕'});
      }
      // Last Quarter (fraction crosses 0.75)
      if (fraction < 0.75 && nextFraction >= 0.75) {
        phases.add({'date': date, 'type': 'last_quarter', 'name': 'Last Quarter', 'emoji': '🌗'});
      }
    }
    return phases;
  }

  /// Daily lunar score based on phase energy.
  static int dailyScore({DateTime? date}) {
    final dt = date ?? DateTime.now();
    final age = moonAge(date: dt);
    final fraction = age / synodicMonth;
    final phase = phaseName(date: dt);

    int score = 50;

    // Full moon = peak energy
    if (phase == 'Full Moon') score += 25;
    if (phase == 'Waxing Gibbous') score += 15;
    if (phase == 'New Moon') score += 10; // new beginnings energy

    // Waxing phases are generally more auspicious for action
    if (fraction < 0.5) score += 5;

    // Void-of-course penalty
    if (isVoidOfCourse(date: dt)) score -= 10;

    // Moon sign bonus (water signs = intuitive, fire = energetic)
    final sign = currentMoonSign(date: dt);
    if (sign == 'Cancer' || sign == 'Pisces' || sign == 'Scorpio') score += 5;
    if (sign == 'Aries' || sign == 'Leo' || sign == 'Sagittarius') score += 3;

    return score.clamp(0, 100);
  }
}
