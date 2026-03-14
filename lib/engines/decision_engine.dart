// Lucky Decision Engine
// Meta-engine that composes all 7 divination engines to answer:
// "Is today (or a specific date) good for X?"
// Returns a cosmic verdict with score, best window, lucky number, risk level, and advice.
import 'package:cosmiq_guru/engines/astrology_engine.dart';
import 'package:cosmiq_guru/engines/numerology_engine.dart';
import 'package:cosmiq_guru/engines/chinese_zodiac_engine.dart';
import 'package:cosmiq_guru/engines/mahabote_engine.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';
import 'package:cosmiq_guru/engines/archetype_engine.dart';
import 'package:cosmiq_guru/engines/planetary_hours_engine.dart';

class DecisionEngine {
  DecisionEngine._();

  // ─────────────────────────────────────────────
  // CATEGORIES & WEIGHTS
  // ─────────────────────────────────────────────

  static const categories = [
    {'id': 'business', 'label': 'Business & Career', 'emoji': '💼'},
    {'id': 'investment', 'label': 'Money & Investment', 'emoji': '💰'},
    {'id': 'love', 'label': 'Love & Relationships', 'emoji': '❤️'},
    {'id': 'travel', 'label': 'Travel', 'emoji': '✈️'},
    {'id': 'health', 'label': 'Health & Wellness', 'emoji': '🏥'},
    {'id': 'education', 'label': 'Education', 'emoji': '📚'},
    {'id': 'property', 'label': 'Property & Real Estate', 'emoji': '🏠'},
    {'id': 'general', 'label': 'General', 'emoji': '🌟'},
  ];

  static const Map<String, Map<String, double>> _categoryWeights = {
    'business': {
      'astrology': 0.20, 'numerology': 0.25, 'chinese': 0.15,
      'mahabote': 0.15, 'lunar': 0.10, 'archetype': 0.05, 'planetary': 0.10,
    },
    'investment': {
      'astrology': 0.15, 'numerology': 0.30, 'chinese': 0.15,
      'mahabote': 0.10, 'lunar': 0.10, 'archetype': 0.05, 'planetary': 0.15,
    },
    'love': {
      'astrology': 0.30, 'numerology': 0.15, 'chinese': 0.15,
      'mahabote': 0.10, 'lunar': 0.15, 'archetype': 0.10, 'planetary': 0.05,
    },
    'travel': {
      'astrology': 0.15, 'numerology': 0.10, 'chinese': 0.15,
      'mahabote': 0.25, 'lunar': 0.15, 'archetype': 0.05, 'planetary': 0.15,
    },
    'health': {
      'astrology': 0.20, 'numerology': 0.10, 'chinese': 0.10,
      'mahabote': 0.15, 'lunar': 0.25, 'archetype': 0.10, 'planetary': 0.10,
    },
    'education': {
      'astrology': 0.15, 'numerology': 0.20, 'chinese': 0.10,
      'mahabote': 0.15, 'lunar': 0.10, 'archetype': 0.20, 'planetary': 0.10,
    },
    'property': {
      'astrology': 0.15, 'numerology': 0.25, 'chinese': 0.20,
      'mahabote': 0.15, 'lunar': 0.10, 'archetype': 0.05, 'planetary': 0.10,
    },
    'general': {
      'astrology': 0.18, 'numerology': 0.18, 'chinese': 0.13,
      'mahabote': 0.17, 'lunar': 0.14, 'archetype': 0.10, 'planetary': 0.10,
    },
  };

  // Category-specific numerology affinities (personal day numbers that boost score)
  static const Map<String, List<int>> _categoryDayAffinities = {
    'business': [1, 8],
    'investment': [8, 1],
    'love': [6, 2],
    'travel': [5, 3],
    'health': [6, 9],
    'education': [7, 3],
    'property': [4, 8],
    'general': [1, 5],
  };

  // Category-specific best planets for planetary hour window
  static const Map<String, List<String>> _categoryBestPlanets = {
    'business': ['Jupiter', 'Sun', 'Mercury'],
    'investment': ['Jupiter', 'Venus'],
    'love': ['Venus', 'Moon'],
    'travel': ['Mercury', 'Moon'],
    'health': ['Sun', 'Moon'],
    'education': ['Mercury', 'Jupiter'],
    'property': ['Saturn', 'Jupiter'],
    'general': ['Jupiter', 'Venus', 'Sun'],
  };

  // Category-specific colors
  static const Map<String, List<String>> _categoryColors = {
    'business': ['Gold', 'Navy Blue', 'Forest Green', 'Silver', 'Charcoal'],
    'investment': ['Gold', 'Green', 'Silver', 'Royal Purple', 'Copper'],
    'love': ['Rose Pink', 'Crimson Red', 'Soft Lavender', 'Pearl White', 'Blush'],
    'travel': ['Sky Blue', 'Emerald Green', 'Sunset Orange', 'Turquoise', 'Sand'],
    'health': ['Healing Green', 'Sky Blue', 'White', 'Soft Yellow', 'Lavender'],
    'education': ['Royal Blue', 'Deep Purple', 'Gold', 'Teal', 'Indigo'],
    'property': ['Earth Brown', 'Forest Green', 'Terra Cotta', 'Cream', 'Slate'],
    'general': ['Royal Purple', 'Gold', 'Silver', 'Sky Blue', 'Emerald'],
  };

  // Archetype category resonance bonuses
  static const Map<String, List<int>> _archetypeCategoryBoost = {
    'business': [0, 7, 4],     // Hero, Ruler, Magician
    'investment': [7, 1, 4],   // Ruler, Sage, Magician
    'love': [9, 8, 5],         // Lover, Caregiver, Innocent
    'travel': [2, 3, 10],      // Explorer, Outlaw, Jester
    'health': [8, 5, 9],       // Caregiver, Innocent, Lover
    'education': [1, 6, 4],    // Sage, Creator, Magician
    'property': [7, 11, 8],    // Ruler, Everyman, Caregiver
    'general': [4, 0, 1],      // Magician, Hero, Sage
  };

  // ─────────────────────────────────────────────
  // MAIN CALCULATION
  // ─────────────────────────────────────────────

  static Map<String, dynamic> calculate({
    required String category,
    required DateTime targetDate,
    required DateTime dob,
    required String fullName,
    required int birthHour,
    required int archetypeId,
    String questionText = '',
  }) {
    // Hash the question text into a stable seed for variation
    final qSeed = _questionSeed(questionText);
    final weights = _categoryWeights[category] ?? _categoryWeights['general']!;

    // Question-derived modifiers: each engine gets a different offset (-12 to +12)
    // so the same person on the same day gets different scores per question
    final qMods = _questionModifiers(qSeed);

    // 1. Astrology score (with category modifier + question modifier)
    int astrologyScore = AstrologyEngine.dailyScore(dob, now: targetDate) + qMods[0];
    final transits = AstrologyEngine.dailyTransits(now: targetDate);
    if (category == 'love') {
      final venusSign = transits.firstWhere((t) => t['planet'] == 'Venus', orElse: () => {})['sign'] as String?;
      if (venusSign != null) {
        final venusElem = AstrologyEngine.signElement(venusSign);
        if (venusElem == 'Water' || venusElem == 'Fire') astrologyScore += 8;
      }
    } else if (category == 'business' || category == 'investment') {
      final jupiterSign = transits.firstWhere((t) => t['planet'] == 'Jupiter', orElse: () => {})['sign'] as String?;
      if (jupiterSign != null) {
        final jupElem = AstrologyEngine.signElement(jupiterSign);
        if (jupElem == 'Earth' || jupElem == 'Fire') astrologyScore += 8;
      }
    }
    astrologyScore = astrologyScore.clamp(0, 100);

    // 2. Numerology score (with personal day affinity + question modifier)
    int numerologyScore = NumerologyEngine.dailyScore(dob, fullName, now: targetDate) + qMods[1];
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: targetDate);
    final affinities = _categoryDayAffinities[category] ?? [1, 5];
    if (affinities.contains(personalDay)) numerologyScore += 15;
    numerologyScore = numerologyScore.clamp(0, 100);

    // 3. Chinese Zodiac score (+ question modifier)
    int chineseScore = ChineseZodiacEngine.dailyScore(dob.year, now: targetDate) + qMods[2];
    if ((category == 'investment' || category == 'property')) {
      final yearElement = ChineseZodiacEngine.element(targetDate.year);
      if (yearElement == 'Earth' || yearElement == 'Metal') chineseScore += 10;
    }
    chineseScore = chineseScore.clamp(0, 100);

    // 4. Mahabote score (+ question modifier)
    int mahaboteScore = MahaboteEngine.dailyScore(dob, birthHour, now: targetDate) + qMods[3];
    if (category == 'travel') {
      final birthProfile = MahaboteEngine.getDayProfile(dob, birthHour);
      final targetProfile = MahaboteEngine.getDayProfile(targetDate, 12);
      if (birthProfile['direction'] == targetProfile['direction']) mahaboteScore += 10;
    }
    final dasa = MahaboteEngine.currentDasa(dob, birthHour, now: targetDate);
    final dasaPlanet = dasa['planet'] as String;
    if (category == 'business' && (dasaPlanet == 'Jupiter' || dasaPlanet == 'Venus')) {
      mahaboteScore += 8;
    }
    mahaboteScore = mahaboteScore.clamp(0, 100);

    // 5. Lunar score (with moon phase category modifier + question modifier)
    int lunarScore = LunarEngine.dailyScore(date: targetDate) + qMods[4];
    final moonPhase = LunarEngine.phaseName(date: targetDate);
    lunarScore += _moonPhaseBonus(category, moonPhase);
    lunarScore = lunarScore.clamp(0, 100);

    // 6. Archetype score (with category resonance + question modifier)
    int archetypeScore = ArchetypeEngine.dailyScore(archetypeId, now: targetDate) + qMods[5];
    final boostedArchetypes = _archetypeCategoryBoost[category] ?? [];
    if (boostedArchetypes.contains(archetypeId)) archetypeScore += 12;
    archetypeScore = archetypeScore.clamp(0, 100);

    // 7. Planetary Hours score + best window (+ question modifier)
    final birthDayKey = MahaboteEngine.birthDayKey(dob, birthHour);
    final birthPlanet = MahaboteEngine.dayData[birthDayKey]?['planet']?.toString() ?? 'Sun';
    int planetaryScore = PlanetaryHoursEngine.dailyScore(birthPlanet: birthPlanet, now: targetDate) + qMods[6];
    planetaryScore = planetaryScore.clamp(0, 100);

    // Find best window for category
    final bestWindow = _findBestWindow(targetDate, category);

    // ─── Compose weighted score ───
    final weightedScore = (
      astrologyScore * weights['astrology']! +
      numerologyScore * weights['numerology']! +
      chineseScore * weights['chinese']! +
      mahaboteScore * weights['mahabote']! +
      lunarScore * weights['lunar']! +
      archetypeScore * weights['archetype']! +
      planetaryScore * weights['planetary']!
    ).round().clamp(0, 100);

    // Lucky number (question-aware)
    final luckyNumber = _computeLuckyNumber(dob, fullName, targetDate, category, qSeed);

    // Lucky color (question shifts the selection)
    final colors = _categoryColors[category] ?? _categoryColors['general']!;
    final colorIndex = (targetDate.day + targetDate.month + personalDay + qSeed) % colors.length;
    final luckyColor = colors[colorIndex];

    // Lucky direction (question can shift it)
    const directions = ['North', 'Northeast', 'East', 'Southeast', 'South', 'Southwest', 'West', 'Northwest'];
    final birthAnimal = ChineseZodiacEngine.animal(dob.year);
    final baseDirection = ChineseZodiacEngine.luckyDirections[birthAnimal] ??
        (MahaboteEngine.dayData[birthDayKey]?['direction']?.toString() ?? 'North');
    // If question seed is odd, shift direction by seed-derived offset
    final luckyDirection = qSeed % 3 == 0
        ? baseDirection
        : directions[(directions.indexOf(baseDirection).clamp(0, 7) + (qSeed % 3)) % directions.length];

    // Risk level
    final riskLevel = weightedScore >= 75
        ? 'Low'
        : weightedScore >= 55
            ? 'Medium'
            : weightedScore >= 35
                ? 'High'
                : 'Extreme';

    // Advice narrative
    final advice = _generateAdvice(
      category: category,
      score: weightedScore,
      moonPhase: moonPhase,
      personalDay: personalDay,
      dasaPlanet: dasaPlanet,
      archetypeId: archetypeId,
      targetDate: targetDate,
    );

    return {
      'score': weightedScore,
      'riskLevel': riskLevel,
      'bestWindowStart': bestWindow['start'] as String,
      'bestWindowEnd': bestWindow['end'] as String,
      'bestWindowPlanet': bestWindow['planet'] as String,
      'luckyNumber': luckyNumber,
      'luckyColor': luckyColor,
      'luckyDirection': luckyDirection,
      'moonPhase': moonPhase,
      'systemScores': {
        'Astrology': astrologyScore,
        'Numerology': numerologyScore,
        'Chinese Zodiac': chineseScore,
        'Lunar': lunarScore,
        'Mahabote': mahaboteScore,
        'Archetype': archetypeScore,
        'Planetary Hours': planetaryScore,
      },
      'advice': advice,
    };
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static int _moonPhaseBonus(String category, String phase) {
    switch (category) {
      case 'business':
      case 'education':
        // Starting things favors waxing phases
        if (phase == 'Waxing Crescent' || phase == 'First Quarter') return 12;
        if (phase == 'New Moon') return 8;
        if (phase == 'Waning Gibbous' || phase == 'Last Quarter') return -5;
        return 0;
      case 'love':
        if (phase == 'Full Moon' || phase == 'Waxing Gibbous') return 12;
        if (phase == 'New Moon') return -5;
        return 0;
      case 'health':
        // Ending/quitting favors waning phases
        if (phase == 'Waning Gibbous' || phase == 'Last Quarter') return 12;
        if (phase == 'New Moon') return 8; // detox/cleanse
        return 0;
      case 'investment':
      case 'property':
        if (phase.startsWith('Waxing')) return 8;
        if (phase == 'New Moon') return 6; // new beginnings
        return 0;
      case 'travel':
        if (phase == 'Full Moon') return 10;
        if (phase == 'Waxing Gibbous') return 5;
        return 0;
      default:
        return 0;
    }
  }

  static Map<String, String> _findBestWindow(DateTime date, String category) {
    final hours = PlanetaryHoursEngine.planetaryHours(date);
    final bestPlanets = _categoryBestPlanets[category] ?? ['Jupiter', 'Venus'];

    // Find first matching planet hour
    for (final planet in bestPlanets) {
      for (final h in hours) {
        if (h['planet'] == planet && h['isDaytime'] == true) {
          return {
            'start': PlanetaryHoursEngine.formatHour(h['startHour'] as double),
            'end': PlanetaryHoursEngine.formatHour(h['endHour'] as double),
            'planet': planet,
          };
        }
      }
    }

    // Fallback: first benefic daytime hour
    for (final h in hours) {
      if (h['isDaytime'] == true) {
        final props = PlanetaryHoursEngine.planetProperties[h['planet'] as String];
        if (props?['benefic'] == true) {
          return {
            'start': PlanetaryHoursEngine.formatHour(h['startHour'] as double),
            'end': PlanetaryHoursEngine.formatHour(h['endHour'] as double),
            'planet': h['planet'] as String,
          };
        }
      }
    }

    return {'start': '9:00 AM', 'end': '10:00 AM', 'planet': 'Sun'};
  }

  static int _computeLuckyNumber(DateTime dob, String fullName, DateTime targetDate, String category, int qSeed) {
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: targetDate);
    final lifePath = NumerologyEngine.lifePathNumber(dob);

    // Category modifier
    const categoryNums = {
      'business': 8, 'investment': 8, 'love': 6, 'travel': 5,
      'health': 9, 'education': 7, 'property': 4, 'general': 1,
    };
    final catNum = categoryNums[category] ?? 1;

    // Combine and reduce to single digit (question seed adds variation)
    int combined = personalDay + catNum + lifePath + (qSeed % 9);
    while (combined > 9) {
      int sum = 0;
      while (combined > 0) {
        sum += combined % 10;
        combined ~/= 10;
      }
      combined = sum;
    }
    return combined == 0 ? 1 : combined;
  }

  static String _generateAdvice({
    required String category,
    required int score,
    required String moonPhase,
    required int personalDay,
    required String dasaPlanet,
    required int archetypeId,
    required DateTime targetDate,
  }) {
    final archetype = ArchetypeEngine.archetypes[archetypeId.clamp(0, 11)];
    final archetypeName = archetype['name'] as String;
    final shortName = archetypeName.startsWith('The ') ? archetypeName.substring(4) : archetypeName;

    // Strength descriptor
    final strength = score >= 80
        ? 'The stars strongly favor'
        : score >= 65
            ? 'Cosmic energies support'
            : score >= 50
                ? 'The cosmos offers moderate support for'
                : score >= 35
                    ? 'Exercise caution with'
                    : 'The cosmos advises against';

    // Moon phase context
    final moonContext = moonPhase == 'Full Moon'
        ? 'The full moon amplifies your intentions and visibility.'
        : moonPhase == 'New Moon'
            ? 'The new moon favors planting seeds for the future.'
            : moonPhase.startsWith('Waxing')
                ? 'The waxing moon builds momentum and growth energy.'
                : moonPhase.startsWith('Waning')
                    ? 'The waning moon supports releasing and completing.'
                    : '';

    // Personal day context
    final dayMeaning = _personalDayMeaning(personalDay);

    // Category-specific framing
    String catFrame;
    switch (category) {
      case 'business':
        catFrame = 'bold professional moves today';
        break;
      case 'investment':
        catFrame = 'financial decisions at this time';
        break;
      case 'love':
        catFrame = 'matters of the heart right now';
        break;
      case 'travel':
        catFrame = 'journeys and exploration now';
        break;
      case 'health':
        catFrame = 'health and wellness changes';
        break;
      case 'education':
        catFrame = 'learning and intellectual pursuits';
        break;
      case 'property':
        catFrame = 'property and real estate decisions';
        break;
      default:
        catFrame = 'this decision';
    }

    return '$strength $catFrame. $moonContext Your personal day number $personalDay brings $dayMeaning energy, and your inner $shortName resonates with the current $dasaPlanet Dasa period.';
  }

  // Hash question text into a stable integer seed (0-9999)
  // Same question always produces the same seed, different questions differ
  static int _questionSeed(String text) {
    if (text.isEmpty) return 0;
    final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    int hash = 5381;
    for (int i = 0; i < normalized.length; i++) {
      hash = ((hash << 5) + hash + normalized.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash % 10000;
  }

  // Generate 7 score modifiers from the seed, each between -12 and +12
  // Uses a simple LCG to spread seed across 7 independent values
  static List<int> _questionModifiers(int seed) {
    if (seed == 0) return List.filled(7, 0);
    final mods = <int>[];
    int s = seed;
    for (int i = 0; i < 7; i++) {
      s = (s * 1103515245 + 12345) & 0x7FFFFFFF;
      mods.add((s % 25) - 12); // range: -12 to +12
    }
    return mods;
  }

  static String _personalDayMeaning(int num) {
    const meanings = {
      1: 'initiating and leadership',
      2: 'cooperative and diplomatic',
      3: 'creative and expressive',
      4: 'structured and disciplined',
      5: 'adventurous and changeable',
      6: 'nurturing and harmonious',
      7: 'reflective and analytical',
      8: 'ambitious and prosperous',
      9: 'completion and humanitarian',
      11: 'inspired and visionary',
      22: 'masterful and transformative',
      33: 'compassionate and healing',
    };
    return meanings[num] ?? 'balanced';
  }
}
