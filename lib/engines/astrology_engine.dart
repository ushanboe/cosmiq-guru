/// Western Astrology Calculation Engine
/// Sun sign from exact date ranges. Moon and rising signs use simplified approximations.
import 'dart:math';

class AstrologyEngine {
  AstrologyEngine._();

  static const signs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  static const symbols = [
    '♈', '♉', '♊', '♋', '♌', '♍',
    '♎', '♏', '♐', '♑', '♒', '♓',
  ];

  static const rulers = [
    'Mars', 'Venus', 'Mercury', 'Moon', 'Sun', 'Mercury',
    'Venus', 'Pluto', 'Jupiter', 'Saturn', 'Uranus', 'Neptune',
  ];

  static const elements = {
    'Aries': 'Fire', 'Leo': 'Fire', 'Sagittarius': 'Fire',
    'Taurus': 'Earth', 'Virgo': 'Earth', 'Capricorn': 'Earth',
    'Gemini': 'Air', 'Libra': 'Air', 'Aquarius': 'Air',
    'Cancer': 'Water', 'Scorpio': 'Water', 'Pisces': 'Water',
  };

  static const modalities = {
    'Aries': 'Cardinal', 'Cancer': 'Cardinal', 'Libra': 'Cardinal', 'Capricorn': 'Cardinal',
    'Taurus': 'Fixed', 'Leo': 'Fixed', 'Scorpio': 'Fixed', 'Aquarius': 'Fixed',
    'Gemini': 'Mutable', 'Virgo': 'Mutable', 'Sagittarius': 'Mutable', 'Pisces': 'Mutable',
  };

  // Sun sign date boundaries (month, day) — start of each sign
  static const _signStarts = [
    [3, 21],  // Aries
    [4, 20],  // Taurus
    [5, 21],  // Gemini
    [6, 21],  // Cancer
    [7, 23],  // Leo
    [8, 23],  // Virgo
    [9, 23],  // Libra
    [10, 23], // Scorpio
    [11, 22], // Sagittarius
    [12, 22], // Capricorn
    [1, 20],  // Aquarius
    [2, 19],  // Pisces
  ];

  /// Get sun sign from date of birth.
  static String sunSign(DateTime dob) {
    final m = dob.month;
    final d = dob.day;

    // Check each sign's date range
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Aries';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Taurus';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Gemini';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Leo';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Virgo';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Libra';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Scorpio';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Sagittarius';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'Capricorn';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Aquarius';
    return 'Pisces'; // Feb 19 - Mar 20
  }

  /// Approximate moon sign using simplified lunar ephemeris.
  /// The moon traverses all 12 signs in ~27.3 days (~2.3 days per sign).
  /// This uses a reference date and the moon's average daily motion.
  static String moonSign(DateTime dob) {
    // Reference: Jan 1, 2000, Moon was approximately in Aries (0°)
    final ref = DateTime(2000, 1, 1);
    final daysSinceRef = dob.difference(ref).inDays.toDouble();

    // Moon's sidereal period = 27.321661 days
    // One sign = 27.321661 / 12 = 2.2768 days
    final moonPosition = (daysSinceRef / 27.321661) * 360.0;
    final signIndex = ((moonPosition % 360) / 30).floor() % 12;
    return signs[signIndex];
  }

  /// Approximate rising sign (ascendant) from birth time and date.
  /// The ascendant changes approximately every 2 hours through the zodiac.
  /// Simplified: sun sign position + offset based on birth hour.
  static String risingSign(DateTime dob, int birthHour, int birthMinute) {
    // Start from sun sign
    final sun = sunSign(dob);
    final sunIndex = signs.indexOf(sun);

    // Each 2 hours advances the ascendant by approximately 1 sign
    // At sunrise (~6am), ascendant = sun sign
    // Offset from 6am in hours, each 2 hours = 1 sign
    final hoursFromSunrise = (birthHour + birthMinute / 60.0) - 6.0;
    final signOffset = (hoursFromSunrise / 2.0).round();

    final risingIndex = (sunIndex + signOffset) % 12;
    return signs[risingIndex < 0 ? risingIndex + 12 : risingIndex];
  }

  /// Get the symbol for a zodiac sign.
  static String symbol(String sign) {
    final idx = signs.indexOf(sign);
    return idx >= 0 ? symbols[idx] : '?';
  }

  /// Get the ruling planet for a sign.
  static String ruler(String sign) {
    final idx = signs.indexOf(sign);
    return idx >= 0 ? rulers[idx] : 'Unknown';
  }

  /// Get the element for a sign.
  static String signElement(String sign) => elements[sign] ?? 'Unknown';

  /// Get the modality for a sign.
  static String modality(String sign) => modalities[sign] ?? 'Unknown';

  /// Check element compatibility between two signs.
  static String elementCompatibility(String sign1, String sign2) {
    final e1 = elements[sign1] ?? '';
    final e2 = elements[sign2] ?? '';

    if (e1 == e2) return 'Harmonious — same element';
    if ((e1 == 'Fire' && e2 == 'Air') || (e1 == 'Air' && e2 == 'Fire')) {
      return 'Energizing — fire and air fuel each other';
    }
    if ((e1 == 'Earth' && e2 == 'Water') || (e1 == 'Water' && e2 == 'Earth')) {
      return 'Nurturing — earth and water nourish each other';
    }
    if ((e1 == 'Fire' && e2 == 'Water') || (e1 == 'Water' && e2 == 'Fire')) {
      return 'Challenging — fire and water create steam';
    }
    return 'Mixed — different elemental energies';
  }

  /// Simplified planetary transit descriptions for today.
  /// Uses approximate planetary positions based on orbital periods.
  static List<Map<String, dynamic>> dailyTransits({DateTime? now}) {
    final today = now ?? DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    // Approximate sign positions based on orbital periods
    // Sun: moves 1 sign/month (handled by sunSign)
    // Mercury: ~88 day orbit, roughly tracks the sun ±1 sign
    // Venus: ~225 day orbit
    // Mars: ~687 day orbit (~1.88 years)
    // Jupiter: ~4333 day orbit (~11.86 years)
    // Saturn: ~10759 day orbit (~29.46 years)

    final mercurySign = signs[((dayOfYear / 30.4 + 0.5) % 12).floor()];
    final venusSign = signs[((dayOfYear / 30.4 + 1.2) % 12).floor()];
    final marsSign = signs[((today.year * 12 + today.month - 2000 * 12) ~/ 2 % 12)];
    final jupiterSign = signs[((today.year - 2000) % 12)];
    final saturnSign = signs[((today.year - 2000) ~/ 2.5 % 12).floor()];

    return [
      {
        'planet': 'Mercury',
        'symbol': '☿',
        'sign': mercurySign,
        'transit': 'Mercury in $mercurySign',
        'influence': _mercuryInfluence(mercurySign),
        'isPositive': true,
      },
      {
        'planet': 'Venus',
        'symbol': '♀',
        'sign': venusSign,
        'transit': 'Venus in $venusSign',
        'influence': _venusInfluence(venusSign),
        'isPositive': true,
      },
      {
        'planet': 'Mars',
        'symbol': '♂',
        'sign': marsSign,
        'transit': 'Mars in $marsSign',
        'influence': _marsInfluence(marsSign),
        'isPositive': elements[marsSign] == 'Fire' || elements[marsSign] == 'Air',
      },
      {
        'planet': 'Jupiter',
        'symbol': '♃',
        'sign': jupiterSign,
        'transit': 'Jupiter in $jupiterSign',
        'influence': 'Expansion and growth energy flows through ${signElement(jupiterSign).toLowerCase()} matters.',
        'isPositive': true,
      },
      {
        'planet': 'Saturn',
        'symbol': '♄',
        'sign': saturnSign,
        'transit': 'Saturn in $saturnSign',
        'influence': 'Discipline and structure in ${signElement(saturnSign).toLowerCase()} areas of life.',
        'isPositive': false,
      },
    ];
  }

  static String _mercuryInfluence(String sign) {
    final elem = signElement(sign);
    switch (elem) {
      case 'Fire': return 'Communication is bold and direct. Speak your truth with confidence.';
      case 'Earth': return 'Practical thinking dominates. Focus on concrete plans and details.';
      case 'Air': return 'Mental clarity is sharp. Ideal for learning, writing, and social connection.';
      case 'Water': return 'Intuitive communication. Trust your gut feelings in conversations.';
      default: return 'Mercury influences your mental faculties.';
    }
  }

  static String _venusInfluence(String sign) {
    final elem = signElement(sign);
    switch (elem) {
      case 'Fire': return 'Passion and romance burn bright. Bold expressions of love are favored.';
      case 'Earth': return 'Sensual, grounded love. Appreciate beauty in simple, tangible things.';
      case 'Air': return 'Intellectual connections deepen. Love through conversation and shared ideas.';
      case 'Water': return 'Deep emotional bonds strengthen. Vulnerability leads to intimacy.';
      default: return 'Venus brings harmony to your relationships.';
    }
  }

  static String _marsInfluence(String sign) {
    final elem = signElement(sign);
    switch (elem) {
      case 'Fire': return 'Energy is high and action-oriented. Channel drive into productive pursuits.';
      case 'Earth': return 'Steady, persistent effort pays off. Build something lasting today.';
      case 'Air': return 'Mental energy is restless. Direct it into strategic planning and debate.';
      case 'Water': return 'Emotional intensity may surface. Use this power for creative transformation.';
      default: return 'Mars drives your ambition and action.';
    }
  }

  /// Daily astrology score based on sun sign interaction with current transits.
  static int dailyScore(DateTime dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final sun = sunSign(dob);
    final sunElement = signElement(sun);
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    int score = 55;

    // Sun in own sign period = peak
    if (sunSign(today) == sun) score += 20;

    // Same element as current sun sign = harmonious
    if (signElement(sunSign(today)) == sunElement) score += 10;

    // Complementary elements
    if ((sunElement == 'Fire' && signElement(sunSign(today)) == 'Air') ||
        (sunElement == 'Air' && signElement(sunSign(today)) == 'Fire') ||
        (sunElement == 'Earth' && signElement(sunSign(today)) == 'Water') ||
        (sunElement == 'Water' && signElement(sunSign(today)) == 'Earth')) {
      score += 8;
    }

    // Lunar day bonus (cycles every ~2.5 days)
    final lunarPhase = (dayOfYear % 30) / 30.0;
    if (lunarPhase > 0.4 && lunarPhase < 0.6) score += 5; // near full moon

    // Seasonal alignment (sun in own element's season)
    score += ((sin(dayOfYear * 2 * pi / 365.25) * 5).round());

    return score.clamp(0, 100);
  }
}
