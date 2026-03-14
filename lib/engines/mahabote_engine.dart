/// Burmese Mahabote Astrology Calculation Engine
/// Implements: day-of-week animal system (8 animals, Wednesday split),
/// 8-house birth chart, Dasa planetary periods, and compatibility.
class MahaboteEngine {
  MahaboteEngine._();

  // ─────────────────────────────────────────────
  // 8 DAY-ANIMAL-PLANET SYSTEM
  // Wednesday is split: AM = Tusked Elephant (Mercury), PM = Tuskless Elephant (Rahu)
  // ─────────────────────────────────────────────

  static const dayData = {
    'Sunday':       {'animal': 'Garuda',              'emoji': '🦅', 'planet': 'Sun',     'planetSymbol': '☉', 'direction': 'North-East', 'element': 'Fire',  'consonants': 'Ah, Aw'},
    'Monday':       {'animal': 'Tiger',               'emoji': '🐅', 'planet': 'Moon',    'planetSymbol': '☽', 'direction': 'East',       'element': 'Earth', 'consonants': 'Ka, Kha, Ga, Gha, Nga'},
    'Tuesday':      {'animal': 'Lion',                'emoji': '🦁', 'planet': 'Mars',    'planetSymbol': '♂', 'direction': 'South-East', 'element': 'Fire',  'consonants': 'Sa, Hsa, Za, Nya'},
    'Wednesday AM': {'animal': 'Elephant (Tusked)',    'emoji': '🐘', 'planet': 'Mercury', 'planetSymbol': '☿', 'direction': 'South',      'element': 'Water', 'consonants': 'Ya, Ra, La, Wa'},
    'Wednesday PM': {'animal': 'Elephant (Tuskless)',  'emoji': '🐘', 'planet': 'Rahu',    'planetSymbol': '☊', 'direction': 'North-West', 'element': 'Water', 'consonants': 'Ya, Ra, La, Wa'},
    'Thursday':     {'animal': 'Rat',                 'emoji': '🐀', 'planet': 'Jupiter', 'planetSymbol': '♃', 'direction': 'West',       'element': 'Earth', 'consonants': 'Pa, Hpa, Ba, Ma'},
    'Friday':       {'animal': 'Guinea Pig',          'emoji': '🐹', 'planet': 'Venus',   'planetSymbol': '♀', 'direction': 'North',      'element': 'Metal', 'consonants': 'Tha, Ha'},
    'Saturday':     {'animal': 'Naga (Dragon)',       'emoji': '🐲', 'planet': 'Saturn',  'planetSymbol': '♄', 'direction': 'South-West', 'element': 'Fire',  'consonants': 'Ta, Hta, Da, Na'},
  };

  // Dasa periods (years per ruling planet)
  static const dasaPeriods = {
    'Sun': 6, 'Moon': 15, 'Mars': 8, 'Mercury': 17, 'Jupiter': 19,
    'Venus': 21, 'Saturn': 10, 'Rahu': 12,
  };

  // Dasa cycle order (Burmese traditional)
  static const dasaCycleOrder = [
    'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu',
  ];

  // Total Dasa cycle length
  static int get totalDasaCycle =>
      dasaPeriods.values.fold(0, (sum, v) => sum + v); // 108 years

  // 8 Houses of Mahabote (traditional names)
  static const houseNames = [
    'Beda',    // 1 - Self/Birth
    'Keitta',  // 2 - Wealth
    'Byattsa', // 3 - Status/Position
    'Hpongyi', // 4 - Elders/Spiritual
    'Thokda',  // 5 - Marriage/Partner
    'Ahtun',   // 6 - Enemies/Obstacles
    'Yaza',    // 7 - Leadership/Authority
    'Marana',  // 8 - Death/Danger
  ];

  static const houseDescriptions = {
    'Beda':    'House of Self — identity, personality, physical body, and life force',
    'Keitta':  'House of Wealth — material resources, income, and financial fortune',
    'Byattsa': 'House of Status — social position, reputation, and career standing',
    'Hpongyi': 'House of Elders — spiritual teachers, mentors, and religious life',
    'Thokda':  'House of Marriage — partnerships, spouse, and romantic relationships',
    'Ahtun':   'House of Enemies — obstacles, rivals, disputes, and health challenges',
    'Yaza':    'House of Leadership — authority, power, governance, and ambition',
    'Marana':  'House of Transformation — endings, danger, hidden matters, and rebirth',
  };

  static const housePlanets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu'];
  static const houseSymbols = ['☉', '☽', '♂', '☿', '♃', '♀', '♄', '☊'];

  // ─────────────────────────────────────────────
  // CORE CALCULATIONS
  // ─────────────────────────────────────────────

  /// Get the Burmese day key from a date and birth time.
  /// Wednesday is split at noon: before noon = Wednesday AM, after = Wednesday PM.
  static String birthDayKey(DateTime dob, int birthHour) {
    final weekday = dob.weekday; // 1=Monday, 7=Sunday
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[weekday - 1];

    if (dayName == 'Wednesday') {
      return birthHour < 12 ? 'Wednesday AM' : 'Wednesday PM';
    }
    return dayName;
  }

  /// Get the simple day name (without AM/PM) for display.
  static String dayOfWeek(DateTime dob) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[dob.weekday - 1];
  }

  /// Get full day data (animal, planet, direction, element, etc.).
  static Map<String, dynamic> getDayProfile(DateTime dob, int birthHour) {
    final key = birthDayKey(dob, birthHour);
    return Map<String, dynamic>.from(dayData[key] ?? dayData['Sunday']!)
      ..['dayKey'] = key
      ..['dayName'] = dayOfWeek(dob);
  }

  /// Calculate the 8-house birth chart positions.
  /// In Mahabote, the birth day planet occupies the Beda (self) house,
  /// and other planets are placed counting from there.
  static List<Map<String, dynamic>> birthChart(DateTime dob, int birthHour) {
    final dayKey = birthDayKey(dob, birthHour);
    final dayInfo = dayData[dayKey]!;
    final birthPlanet = dayInfo['planet'] as String;
    final birthPlanetIndex = dasaCycleOrder.indexOf(birthPlanet);

    final chart = <Map<String, dynamic>>[];
    for (int i = 0; i < 8; i++) {
      final planetIndex = (birthPlanetIndex + i) % 8;
      final planet = dasaCycleOrder[planetIndex];
      final isBirthPlanet = (i == 0);
      final isMarana = (i == 7); // 8th house = Marana (danger)

      chart.add({
        'houseIndex': i,
        'houseName': houseNames[i],
        'houseDescription': houseDescriptions[houseNames[i]],
        'planet': planet,
        'planetSymbol': houseSymbols[dasaCycleOrder.indexOf(planet)],
        'isBirthPlanet': isBirthPlanet,
        'isMarana': isMarana,
        'strength': _houseStrength(i, isBirthPlanet),
      });
    }
    return chart;
  }

  /// House strength score (simplified).
  static int _houseStrength(int houseIndex, bool isBirthPlanet) {
    if (isBirthPlanet) return 90; // Birth planet in Beda = strong
    // Houses 1-4 are generally stronger, 5-7 mixed, 8 (Marana) is challenging
    const baseStrength = [90, 75, 70, 65, 60, 40, 70, 30];
    return baseStrength[houseIndex];
  }

  /// Calculate current Dasa period based on age and birth day planet.
  /// Returns the current Dasa planet, years remaining, and description.
  static Map<String, dynamic> currentDasa(DateTime dob, int birthHour, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final dayKey = birthDayKey(dob, birthHour);
    final dayInfo = dayData[dayKey]!;
    final birthPlanet = dayInfo['planet'] as String;
    final startIndex = dasaCycleOrder.indexOf(birthPlanet);

    // Age in years
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    // Walk through Dasa periods from birth planet
    int cumulative = 0;
    int cycleAge = age % totalDasaCycle; // wrap for ages > 108

    for (int i = 0; i < 8; i++) {
      final planetIndex = (startIndex + i) % 8;
      final planet = dasaCycleOrder[planetIndex];
      final years = dasaPeriods[planet]!;
      cumulative += years;

      if (cycleAge < cumulative) {
        final yearsInto = cycleAge - (cumulative - years);
        final yearsRemaining = years - yearsInto;
        return {
          'planet': planet,
          'planetSymbol': houseSymbols[planetIndex],
          'totalYears': years,
          'yearsInto': yearsInto,
          'yearsRemaining': yearsRemaining,
          'description': _dasaDescription(planet),
          'startAge': cumulative - years,
          'endAge': cumulative,
        };
      }
    }

    // Fallback (shouldn't reach here)
    return {
      'planet': birthPlanet,
      'planetSymbol': dayInfo['planetSymbol'],
      'totalYears': dasaPeriods[birthPlanet],
      'yearsInto': 0,
      'yearsRemaining': dasaPeriods[birthPlanet],
      'description': _dasaDescription(birthPlanet),
      'startAge': 0,
      'endAge': dasaPeriods[birthPlanet],
    };
  }

  static String _dasaDescription(String planet) {
    const descriptions = {
      'Sun': 'Sun Dasa (6 years) — leadership, authority, vitality, and recognition. A time for taking charge and stepping into the spotlight.',
      'Moon': 'Moon Dasa (15 years) — emotions, intuition, nurturing, and domestic life. A long period of inner growth and family focus.',
      'Mars': 'Mars Dasa (8 years) — action, courage, energy, and competition. A time for bold moves and physical vitality.',
      'Mercury': 'Mercury Dasa (17 years) — intellect, communication, commerce, and education. The longest productive period for learning and business.',
      'Jupiter': 'Jupiter Dasa (19 years) — wisdom, expansion, spiritual growth, and fortune. The most auspicious Dasa period for overall prosperity.',
      'Venus': 'Venus Dasa (21 years) — love, beauty, comfort, and creative arts. The longest Dasa, bringing material pleasures and relationships.',
      'Saturn': 'Saturn Dasa (10 years) — discipline, hard work, karmic lessons, and endurance. A challenging but transformative period.',
      'Rahu': 'Rahu Dasa (12 years) — ambition, unconventional paths, and sudden changes. A period of intense desire and worldly pursuits.',
    };
    return descriptions[planet] ?? '$planet Dasa — a significant planetary period.';
  }

  // ─────────────────────────────────────────────
  // COMPATIBILITY
  // ─────────────────────────────────────────────

  /// Compatibility between two birth days (0-100).
  static int compatibility(String dayKey1, String dayKey2) {
    final planet1 = dayData[dayKey1]?['planet'] as String? ?? 'Sun';
    final planet2 = dayData[dayKey2]?['planet'] as String? ?? 'Sun';

    // Same planet = strong bond
    if (planet1 == planet2) return 85;

    // Natural friends in Burmese astrology
    const friends = {
      'Sun': ['Moon', 'Mars'],
      'Moon': ['Sun', 'Mercury'],
      'Mars': ['Sun', 'Jupiter'],
      'Mercury': ['Moon', 'Venus'],
      'Jupiter': ['Mars', 'Sun'],
      'Venus': ['Mercury', 'Saturn'],
      'Saturn': ['Venus', 'Mercury'],
      'Rahu': ['Saturn', 'Venus'],
    };

    if (friends[planet1]?.contains(planet2) == true) return 78;
    if (friends[planet2]?.contains(planet1) == true) return 72;

    // Natural enemies
    const enemies = {
      'Sun': ['Saturn', 'Rahu'],
      'Moon': ['Rahu'],
      'Mars': ['Mercury'],
      'Mercury': ['Mars'],
      'Jupiter': ['Rahu'],
      'Venus': ['Sun'],
      'Saturn': ['Sun', 'Mars'],
      'Rahu': ['Sun', 'Moon'],
    };

    if (enemies[planet1]?.contains(planet2) == true) return 35;
    if (enemies[planet2]?.contains(planet1) == true) return 40;

    // Neutral
    return 55;
  }

  /// Daily Mahabote score based on current day's ruling planet interaction with birth planet.
  static int dailyScore(DateTime dob, int birthHour, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final birthKey = birthDayKey(dob, birthHour);
    final birthPlanet = dayData[birthKey]?['planet'] as String? ?? 'Sun';

    // Today's ruling planet (based on day of week)
    final todayHour = today.hour;
    final todayKey = birthDayKey(today, todayHour);
    final todayPlanet = dayData[todayKey]?['planet'] as String? ?? 'Sun';

    int score = 50;

    // Same planet as birth = very auspicious day
    if (todayPlanet == birthPlanet) score += 25;

    // Friendly planet
    const friends = {
      'Sun': ['Moon', 'Mars'],
      'Moon': ['Sun', 'Mercury'],
      'Mars': ['Sun', 'Jupiter'],
      'Mercury': ['Moon', 'Venus'],
      'Jupiter': ['Mars', 'Sun'],
      'Venus': ['Mercury', 'Saturn'],
      'Saturn': ['Venus', 'Mercury'],
      'Rahu': ['Saturn', 'Venus'],
    };
    if (friends[birthPlanet]?.contains(todayPlanet) == true) score += 15;

    // Enemy planet
    const enemies = {
      'Sun': ['Saturn', 'Rahu'],
      'Moon': ['Rahu'],
      'Mars': ['Mercury'],
      'Jupiter': ['Rahu'],
      'Saturn': ['Sun', 'Mars'],
      'Rahu': ['Sun', 'Moon'],
    };
    if (enemies[birthPlanet]?.contains(todayPlanet) == true) score -= 15;

    // Dasa period influence
    final dasa = currentDasa(dob, birthHour, now: today);
    final dasaPlanet = dasa['planet'] as String;
    if (dasaPlanet == 'Jupiter' || dasaPlanet == 'Venus') score += 5; // auspicious Dasa
    if (dasaPlanet == 'Saturn' || dasaPlanet == 'Rahu') score -= 5; // challenging Dasa

    return score.clamp(0, 100);
  }
}
