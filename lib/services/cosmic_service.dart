import 'package:cosmiq_guru/engines/numerology_engine.dart';
import 'package:cosmiq_guru/engines/astrology_engine.dart';
import 'package:cosmiq_guru/engines/chinese_zodiac_engine.dart';
import 'package:cosmiq_guru/engines/mahabote_engine.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';
import 'package:cosmiq_guru/engines/archetype_engine.dart';
import 'package:cosmiq_guru/engines/planetary_hours_engine.dart';
import 'package:cosmiq_guru/engines/decision_engine.dart';

class CosmicService {
  CosmicService._(); // Private constructor — static-only class

  // ─────────────────────────────────────────────
  // HELPERS — parse DOB string to DateTime, birth time to hour/minute
  // ─────────────────────────────────────────────

  static DateTime _parseDob(String dob) {
    try {
      return DateTime.parse(dob);
    } catch (_) {
      // Fallback: try slash/dash formats like "2000/02/21" or "2000-02-21"
      final parts = dob.split(RegExp(r'[/\-]'));
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 2000;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        return DateTime(y, m, d);
      }
      // Fallback: try human-readable format "February 21, 1985"
      const months = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4,
        'may': 5, 'june': 6, 'july': 7, 'august': 8,
        'september': 9, 'october': 10, 'november': 11, 'december': 12,
      };
      final cleaned = dob.replaceAll(',', '').trim();
      final words = cleaned.split(RegExp(r'\s+'));
      if (words.length == 3) {
        final m = months[words[0].toLowerCase()];
        final d = int.tryParse(words[1]);
        final y = int.tryParse(words[2]);
        if (m != null && d != null && y != null) {
          return DateTime(y, m, d);
        }
      }
      return DateTime(2000, 1, 1);
    }
  }

  static int _parseBirthHour(String birthTime) {
    try {
      final upper = birthTime.toUpperCase();
      final parts = birthTime.split(':');
      var hour = int.tryParse(parts[0]) ?? 12;
      // Handle 12-hour AM/PM format (e.g. "2:00 PM")
      if (upper.contains('PM') && hour < 12) hour += 12;
      if (upper.contains('AM') && hour == 12) hour = 0;
      return hour;
    } catch (_) {
      return 12;
    }
  }

  static int _parseBirthMinute(String birthTime) {
    try {
      final parts = birthTime.split(':');
      if (parts.length > 1) {
        // Strip AM/PM suffix: "00 PM" → "00"
        final minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(minuteStr) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // HOME SCREEN DAILY READINGS
  // ─────────────────────────────────────────────

  /// Composite luck score (0-100) from all 7 systems.
  /// Weights: astrology 0.18, chinese 0.13, burmese 0.17, numerology 0.18,
  ///          lunar 0.14, archetype 0.10, planetary 0.10
  static int getLuckScore({
    required String dob,
    required String birthTime,
    required String fullName,
    required int archetypeId,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);

    final astrologyScore = AstrologyEngine.dailyScore(dobDt);
    final chineseScore = ChineseZodiacEngine.dailyScore(dobDt.year);
    final mahaboteScore = MahaboteEngine.dailyScore(dobDt, birthHour);
    final numerologyScore = NumerologyEngine.dailyScore(dobDt, fullName);
    final lunarScore = LunarEngine.dailyScore();
    final archetypeScore = ArchetypeEngine.dailyScore(archetypeId);

    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final birthPlanet = MahaboteEngine.dayData[birthDayKey]?['planet'] as String?;
    final planetaryScore = PlanetaryHoursEngine.dailyScore(birthPlanet: birthPlanet);

    final composite = (astrologyScore * 0.18 +
            chineseScore * 0.13 +
            mahaboteScore * 0.17 +
            numerologyScore * 0.18 +
            lunarScore * 0.14 +
            archetypeScore * 0.10 +
            planetaryScore * 0.10)
        .round()
        .clamp(0, 100);

    return composite;
  }

  static int getRelationshipEnergy({
    required String dob,
    required String fullName,
  }) {
    final dobDt = _parseDob(dob);
    // Venus-influenced: astrology + archetype + lunar
    final astro = AstrologyEngine.dailyScore(dobDt);
    final lunar = LunarEngine.dailyScore();
    final soulUrge = NumerologyEngine.soulUrgeNumber(fullName);
    // Soul urge influence: higher soul urge numbers lean toward relationships
    final soulBonus = (soulUrge % 9) * 3;
    return ((astro * 0.4 + lunar * 0.35 + soulBonus + 15) * 0.9).round().clamp(0, 100);
  }

  static int getMoneyEnergy({
    required String dob,
    required String fullName,
  }) {
    final dobDt = _parseDob(dob);
    // Jupiter-influenced: numerology + chinese + planetary
    final numScore = NumerologyEngine.dailyScore(dobDt, fullName);
    final chineseScore = ChineseZodiacEngine.dailyScore(dobDt.year);
    final expressionNum = NumerologyEngine.expressionNumber(fullName);
    final expressionBonus = (expressionNum % 9) * 2;
    return ((numScore * 0.4 + chineseScore * 0.35 + expressionBonus + 15) * 0.9)
        .round()
        .clamp(0, 100);
  }

  static int getCareerEnergy({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);
    // Mars/Saturn influenced: mahabote + numerology + planetary
    final mahaboteScore = MahaboteEngine.dailyScore(dobDt, birthHour);
    // Use personal day number as a proxy since fullName isn't available here
    final personalDay = NumerologyEngine.personalDayNumber(dobDt);
    final numScore = (personalDay * 11).clamp(0, 100); // scale 1-9 to ~11-99
    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final birthPlanet = MahaboteEngine.dayData[birthDayKey]?['planet'] as String?;
    final planetaryScore = PlanetaryHoursEngine.dailyScore(birthPlanet: birthPlanet);
    return ((mahaboteScore * 0.4 + numScore * 0.3 + planetaryScore * 0.3))
        .round()
        .clamp(0, 100);
  }

  static String getDecisionWindowText() {
    final current = PlanetaryHoursEngine.currentPlanetaryHour();
    final bestWindows = PlanetaryHoursEngine.bestWindows();
    if (bestWindows.isEmpty) {
      return 'No optimal windows remaining today';
    }

    // Find next benefic hour
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;
    Map<String, dynamic>? nextWindow;
    for (final w in bestWindows) {
      if ((w['startHour'] as double) > currentHour) {
        nextWindow = w;
        break;
      }
    }

    if (nextWindow == null) {
      // Currently in a benefic hour
      final planet = current['planet'] as String;
      final endStr = PlanetaryHoursEngine.formatHour(current['endHour'] as double);
      return 'Now until $endStr ($planet Hour)';
    }

    final start = PlanetaryHoursEngine.formatHour(nextWindow['startHour'] as double);
    final end = PlanetaryHoursEngine.formatHour(nextWindow['endHour'] as double);
    final planet = nextWindow['planet'] as String;
    return 'Best window: $start – $end ($planet Hour)';
  }

  static String getDailySummary({
    required String dob,
    required String birthTime,
    required String fullName,
    required int archetypeId,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);

    final sunSign = AstrologyEngine.sunSign(dobDt);
    final moonPhase = LunarEngine.phaseName();
    final personalDay = NumerologyEngine.personalDayNumber(dobDt);
    final archetype = ArchetypeEngine.getProfile(archetypeId);
    final archetypeName = archetype['name'] as String? ?? 'Seeker';
    final archetypeShortName = archetypeName.startsWith('The ') ? archetypeName.substring(4) : archetypeName;

    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final birthPlanet = MahaboteEngine.dayData[birthDayKey]?['planet'] as String? ?? 'Mercury';
    final currentPH = PlanetaryHoursEngine.currentPlanetaryHour();
    final currentPlanet = currentPH['planet'] as String;

    final dayRuler = PlanetaryHoursEngine.dayRulers[
        DateTime.now().weekday == 7 ? DateTime.sunday : DateTime.now().weekday]!;

    // Build a personalized narrative
    final buf = StringBuffer();

    buf.write('The cosmos align powerfully for you today, dear $sunSign. ');
    buf.write('The $moonPhase illuminates your path, ');

    if (personalDay <= 3) {
      buf.write('and your Personal Day $personalDay invites fresh creative energy. ');
    } else if (personalDay <= 6) {
      buf.write('and your Personal Day $personalDay calls for steady focus and nurturing. ');
    } else {
      buf.write('and your Personal Day $personalDay deepens your intuitive wisdom. ');
    }

    buf.write('Your inner $archetypeShortName archetype resonates strongly — ');
    buf.write('${archetype['affirmation'] ?? 'trust your inner knowing'}. ');

    if (currentPlanet == birthPlanet) {
      buf.write('The current $currentPlanet hour aligns perfectly with your birth planet — seize this moment! ');
    } else {
      buf.write('With $dayRuler ruling today, channel its energy wisely through your endeavors. ');
    }

    buf.write('Trust the synchronicities unfolding around you.');

    return buf.toString();
  }

  static String getLuckyColor({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);
    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final element = MahaboteEngine.dayData[birthDayKey]?['element'] as String? ?? 'Water';

    // Element-to-color mapping blended with day-of-week cycle
    const elementColors = {
      'Fire': ['Crimson', 'Ruby Red', 'Amber', 'Sunset Orange'],
      'Water': ['Sapphire Blue', 'Teal', 'Ocean Blue', 'Aquamarine'],
      'Earth': ['Emerald', 'Forest Green', 'Olive', 'Jade'],
      'Air': ['Violet', 'Lavender', 'Silver', 'Periwinkle'],
      'Metal': ['Gold', 'Silver', 'Platinum', 'Bronze'],
      'Wood': ['Jade', 'Forest Green', 'Moss', 'Sage'],
    };

    final colors = elementColors[element] ?? ['Violet', 'Gold', 'Silver', 'Emerald'];
    final dayIndex = DateTime.now().weekday % colors.length;
    return colors[dayIndex];
  }

  static String getLuckyDirection({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);
    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    // Use Mahabote birth direction
    return MahaboteEngine.dayData[birthDayKey]?['direction'] as String? ?? 'North-East';
  }

  static String getBestHourStart() {
    final bestWindows = PlanetaryHoursEngine.bestWindows();
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;

    for (final w in bestWindows) {
      if ((w['startHour'] as double) > currentHour) {
        return PlanetaryHoursEngine.formatHour(w['startHour'] as double);
      }
    }
    if (bestWindows.isNotEmpty) {
      return PlanetaryHoursEngine.formatHour(bestWindows.first['startHour'] as double);
    }
    return '14:00';
  }

  static String getBestHourEnd() {
    final bestWindows = PlanetaryHoursEngine.bestWindows();
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;

    for (final w in bestWindows) {
      if ((w['startHour'] as double) > currentHour) {
        return PlanetaryHoursEngine.formatHour(w['endHour'] as double);
      }
    }
    if (bestWindows.isNotEmpty) {
      return PlanetaryHoursEngine.formatHour(bestWindows.first['endHour'] as double);
    }
    return '16:00';
  }

  static String getBestHourPlanet() {
    final bestWindows = PlanetaryHoursEngine.bestWindows();
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;

    for (final w in bestWindows) {
      if ((w['startHour'] as double) > currentHour) {
        return w['planet'] as String;
      }
    }
    if (bestWindows.isNotEmpty) {
      return bestWindows.first['planet'] as String;
    }
    return 'Venus';
  }

  static String getAiNarrative({
    required String dob,
    required String fullName,
    required int archetypeId,
  }) {
    final dobDt = _parseDob(dob);
    final archetype = ArchetypeEngine.getProfile(archetypeId);
    final archetypeName = archetype['name'] as String? ?? 'Seeker';
    final archetypeShortName = archetypeName.startsWith('The ') ? archetypeName.substring(4) : archetypeName;
    final sunSign = AstrologyEngine.sunSign(dobDt);
    final moonPhase = LunarEngine.phaseName();
    final lifePath = NumerologyEngine.lifePathNumber(dobDt);

    return 'Your cosmic blueprint reveals a rare convergence of energies today. '
        'As a $sunSign with Life Path $lifePath, the inner $archetypeShortName within you is awakening '
        'under the $moonPhase. This is your moment to transform intention into reality. '
        '${archetype['affirmation'] ?? 'Speak your desires into existence'}.';
  }

  // ─────────────────────────────────────────────
  // SYSTEM BREAKDOWN — 7 DIVINATION SYSTEMS
  // ─────────────────────────────────────────────

  static List<Map<String, dynamic>> getSystemBreakdown({
    required String dob,
    required String birthTime,
    required String fullName,
    required int archetypeId,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);

    final sunSign = AstrologyEngine.sunSign(dobDt);
    final moonSign = AstrologyEngine.moonSign(dobDt);
    final astrologyScore = AstrologyEngine.dailyScore(dobDt);

    final lifePath = NumerologyEngine.lifePathNumber(dobDt);
    final personalDay = NumerologyEngine.personalDayNumber(dobDt);
    final numerologyScore = NumerologyEngine.dailyScore(dobDt, fullName);

    final chineseProfile = ChineseZodiacEngine.profile(dobDt.year, dobDt.month, birthHour);
    final animal = chineseProfile['animal'] as String;
    final element = chineseProfile['element'] as String;
    final chineseScore = ChineseZodiacEngine.dailyScore(dobDt.year);

    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final mahaboteData = MahaboteEngine.dayData[birthDayKey]!;
    final mahabotePlanet = mahaboteData['planet'] as String;
    final mahaboteScore = MahaboteEngine.dailyScore(dobDt, birthHour);

    final moonPhase = LunarEngine.phaseName();
    final moonSignLunar = LunarEngine.currentMoonSign();
    final lunarScore = LunarEngine.dailyScore();

    final archetype = ArchetypeEngine.getProfile(archetypeId);
    final archetypeName = archetype['name'] as String? ?? 'Seeker';
    final archetypeShortName = archetypeName.startsWith('The ') ? archetypeName.substring(4) : archetypeName;
    final archetypeScore = ArchetypeEngine.dailyScore(archetypeId);

    final birthPlanet = mahabotePlanet;
    final planetaryScore = PlanetaryHoursEngine.dailyScore(birthPlanet: birthPlanet);
    final currentPH = PlanetaryHoursEngine.currentPlanetaryHour();
    final currentPlanet = currentPH['planet'] as String;

    return [
      {
        'id': 'astrology',
        'name': 'Western Astrology',
        'emoji': '♈',
        'score': astrologyScore,
        'color': 0xFF7C3AED,
        'summary': 'Sun in $sunSign, Moon in $moonSign. Daily transits shape your cosmic weather.',
        'detail': 'Your $sunSign sun radiates its core qualities while your $moonSign moon deepens emotional nuance. Today\'s planetary alignments favor ${astrologyScore > 60 ? 'creative endeavors and heartfelt conversations' : 'introspection and careful planning'}.',
      },
      {
        'id': 'numerology',
        'name': 'Numerology',
        'emoji': '🔢',
        'score': numerologyScore,
        'color': 0xFFF59E0B,
        'summary': 'Life Path $lifePath. Personal Day $personalDay amplifies ${personalDay <= 3 ? 'creativity' : personalDay <= 6 ? 'stability' : 'wisdom'}.',
        'detail': getNumberInterpretation(lifePath, 'life_path').split('.').first + '. Today\'s Personal Day $personalDay energy: ${getNumberInterpretation(personalDay, 'personal_day')}',
      },
      {
        'id': 'chinese_zodiac',
        'name': 'Chinese Zodiac',
        'emoji': '🐉',
        'score': chineseScore,
        'color': 0xFFEF4444,
        'summary': 'Year of the $animal. $element element ${chineseScore > 60 ? 'strengthens' : 'tempers'} resolve.',
        'detail': 'The $animal\'s innate power is ${chineseScore > 60 ? 'amplified' : 'modulated'} by the $element element today. ${chineseScore > 70 ? 'Fortune favors bold moves and long-term planning.' : 'Patience and reflection will serve you better than action.'}',
      },
      {
        'id': 'mahabote',
        'name': 'Mahabote',
        'emoji': '🌐',
        'score': mahaboteScore,
        'color': 0xFF10B981,
        'summary': 'Born on ${mahaboteData['dayName'] ?? birthDayKey} — $mahabotePlanet governs.',
        'detail': '$mahabotePlanet\'s influence ${mahaboteScore > 60 ? 'sharpens your intellect and communication' : 'invites patience and strategic thinking'}. ${mahaboteScore > 70 ? 'Upward movement in professional matters is indicated.' : 'Focus on consolidating existing gains.'}',
      },
      {
        'id': 'lunar',
        'name': 'Lunar Phase',
        'emoji': '🌕',
        'score': lunarScore,
        'color': 0xFF3B82F6,
        'summary': '$moonPhase in $moonSignLunar. ${lunarScore > 60 ? 'Manifestation energy is strong.' : 'Introspection energy flows.'}',
        'detail': getMoonPhaseDescription(moonPhase),
      },
      {
        'id': 'archetype',
        'name': 'Jungian Archetype',
        'emoji': '🎭',
        'score': archetypeScore,
        'color': 0xFFEC4899,
        'summary': '$archetypeName is active. ${archetypeScore > 60 ? 'Transformation energy peaks.' : 'Reflection energy deepens.'}',
        'detail': 'Motto: "${archetype['motto']}"\n\nStrengths: ${(archetype['strengths'] as List).join(', ')}\n\nLife Lesson: ${archetype['lifeLesson']}\n\nShadow: ${archetype['shadowAspect']}\n\nAffirmation: ${archetype['dailyAffirmation']}',
      },
      {
        'id': 'planetary_hours',
        'name': 'Planetary Hours',
        'emoji': '⏰',
        'score': planetaryScore,
        'color': 0xFF8B5CF6,
        'summary': 'Current hour: $currentPlanet. ${planetaryScore > 60 ? 'Benefic alignment detected.' : 'Navigate with awareness.'}',
        'detail': 'The $currentPlanet hour ${planetaryScore > 60 ? 'brings favorable energy for your endeavors' : 'suggests mindful action'}. Your birth planet $birthPlanet ${currentPlanet == birthPlanet ? 'is in perfect resonance!' : 'awaits its optimal window.'}',
      },
    ];
  }

  // ─────────────────────────────────────────────
  // WESTERN ASTROLOGY
  // ─────────────────────────────────────────────

  static String getSunSign({required String dob}) {
    return AstrologyEngine.sunSign(_parseDob(dob));
  }

  static String getMoonSign({required String dob}) {
    return AstrologyEngine.moonSign(_parseDob(dob));
  }

  static String getRisingSign({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    return AstrologyEngine.risingSign(
      dobDt,
      _parseBirthHour(birthTime),
      _parseBirthMinute(birthTime),
    );
  }

  static const Map<String, String> _signSymbols = {
    'Aries': '♈', 'Taurus': '♉', 'Gemini': '♊', 'Cancer': '♋',
    'Leo': '♌', 'Virgo': '♍', 'Libra': '♎', 'Scorpio': '♏',
    'Sagittarius': '♐', 'Capricorn': '♑', 'Aquarius': '♒', 'Pisces': '♓',
  };

  static String getSunSignSymbol({required String dob}) {
    return _signSymbols[getSunSign(dob: dob)] ?? '✦';
  }

  static String getMoonSignSymbol({required String dob}) {
    return _signSymbols[getMoonSign(dob: dob)] ?? '✦';
  }

  static String getRisingSignSymbol({required String dob, required String birthTime}) {
    return _signSymbols[getRisingSign(dob: dob, birthTime: birthTime)] ?? '✦';
  }

  static String getDailyHoroscope({required String dob}) {
    final dobDt = _parseDob(dob);
    final sunSign = AstrologyEngine.sunSign(dobDt);
    final transits = AstrologyEngine.dailyTransits();

    final buf = StringBuffer();
    buf.write('Today the cosmos invite you, dear $sunSign, to step into your fullest self. ');

    // Find the most positive transit
    final positive = transits.where((t) => t['isPositive'] == true).toList();
    final negative = transits.where((t) => t['isPositive'] != true).toList();

    if (positive.isNotEmpty) {
      final best = positive.first;
      buf.write('${best['planet']} ${best['transit']} — ${best['influence']} ');
    }

    if (negative.isNotEmpty) {
      final challenge = negative.first;
      buf.write('Be mindful: ${challenge['planet']} ${challenge['transit']}. ${challenge['influence']} ');
    }

    buf.write('Trust the synchronicities unfolding around you. Your creative energy is at a peak; channel it into something that will outlast the day.');

    return buf.toString();
  }

  static List<Map<String, dynamic>> getPlanetaryTransits({required String dob}) {
    return AstrologyEngine.dailyTransits();
  }

  // ─────────────────────────────────────────────
  // NUMEROLOGY
  // ─────────────────────────────────────────────

  static int getLifePathNumber({required String dob}) {
    return NumerologyEngine.lifePathNumber(_parseDob(dob));
  }

  static int getExpressionNumber({required String fullName}) {
    return NumerologyEngine.expressionNumber(fullName);
  }

  static int getSoulUrgeNumber({required String fullName}) {
    return NumerologyEngine.soulUrgeNumber(fullName);
  }

  static int getPersonalityNumber({required String fullName}) {
    return NumerologyEngine.personalityNumber(fullName);
  }

  static int getPersonalDayNumber({required String dob}) {
    return NumerologyEngine.personalDayNumber(_parseDob(dob));
  }

  static int getPersonalMonthNumber({required String dob}) {
    return NumerologyEngine.personalMonthNumber(_parseDob(dob));
  }

  static int getPersonalYearNumber({required String dob}) {
    return NumerologyEngine.personalYearNumber(_parseDob(dob));
  }

  static bool isMasterNumber(int number) {
    return number == 11 || number == 22 || number == 33;
  }

  static String getNumberInterpretation(int number, String type) {
    final Map<String, Map<int, String>> interpretations = {
      'life_path': {
        1: 'The Leader — Independent, pioneering, and driven. You are here to forge your own path and inspire others through courageous action.',
        2: 'The Diplomat — Cooperative, sensitive, and intuitive. Your gift is creating harmony and building bridges between opposing forces.',
        3: 'The Creator — Expressive, joyful, and imaginative. You are here to inspire through art, words, and the celebration of life.',
        4: 'The Builder — Practical, disciplined, and reliable. Your purpose is to create lasting foundations through hard work and integrity.',
        5: 'The Freedom Seeker — Adventurous, versatile, and magnetic. You are here to experience life fully and inspire freedom in others.',
        6: 'The Nurturer — Compassionate, responsible, and loving. Your path involves caring for others and creating beauty in the world.',
        7: 'The Seeker — Analytical, spiritual, and introspective. You are here to uncover hidden truths and bridge the material and mystical.',
        8: 'The Powerhouse — Ambitious, authoritative, and capable. Your path involves mastering the material world and achieving lasting success.',
        9: 'The Humanitarian — Wise, compassionate, and visionary. You are here to serve humanity and embody universal love.',
        11: 'The Illuminator — Highly intuitive, spiritually gifted master number. You are here to inspire and uplift through spiritual insight.',
        22: 'The Master Builder — The most powerful master number. You are here to manifest grand visions that benefit all of humanity.',
        33: 'The Master Teacher — The highest master number. You are here to teach, heal, and embody unconditional love.',
      },
      'expression': {
        1: 'Natural leadership and original thinking define your expression. You communicate with authority and inspire confidence.',
        2: 'Diplomacy and cooperation color your expression. You excel at listening deeply and finding common ground.',
        3: 'Creative self-expression is your gift. Words, art, and humor flow naturally, drawing others to your vibrant energy.',
        4: 'Practical and methodical expression. You communicate with precision and build trust through reliability.',
        5: 'Dynamic and versatile expression. Your adaptability and curiosity make you a compelling communicator.',
        6: 'Nurturing and responsible expression. You naturally take on the role of advisor, counselor, and caregiver.',
        7: 'Analytical and philosophical expression. Your depth of thought and wisdom make you a sought-after guide.',
        8: 'Powerful and authoritative expression. You project confidence and competence in all you do.',
        9: 'Broad and compassionate expression. You speak to the universal human experience and inspire collective healing.',
        11: 'Visionary and inspirational master expression. You channel higher wisdom and illuminate paths for others.',
        22: 'Masterful and transformative expression. You have the rare ability to turn the most ambitious visions into reality.',
        33: 'Healing and enlightening master expression. Your words carry the vibration of unconditional love and truth.',
      },
      'soul_urge': {
        1: 'Deep within, you crave independence, recognition, and the freedom to lead. Your soul yearns to be first and original.',
        2: 'Your soul craves peace, partnership, and belonging. Deep harmony and meaningful connection are your innermost desires.',
        3: 'Joy, creativity, and self-expression fuel your soul. You deeply desire to create, perform, and bring happiness to others.',
        4: 'Security, order, and solid foundations are what your soul truly craves. Stability gives you the deepest sense of peace.',
        5: 'Freedom, adventure, and sensory experience are your soul\'s deepest desires. You yearn to explore and experience everything.',
        6: 'Love, family, and service are your soul\'s core desires. You yearn to nurture, protect, and create a harmonious home.',
        7: 'Truth, wisdom, and spiritual understanding are your soul\'s deepest cravings. Solitude and contemplation nourish you.',
        8: 'Power, achievement, and material mastery are what your soul truly seeks. Success and recognition fulfill you deeply.',
        9: 'Your soul craves universal love, wisdom, and the opportunity to serve a cause greater than yourself.',
        11: 'Spiritual illumination and the ability to inspire others are your soul\'s deepest desires.',
        22: 'Your soul craves the opportunity to build something monumental that will outlast your lifetime.',
        33: 'Unconditional love and the ability to heal and teach are the deepest desires of your master soul.',
      },
      'personality': {
        1: 'You project confidence, independence, and leadership. Others see you as a trailblazer and natural authority.',
        2: 'You project gentleness, diplomacy, and sensitivity. Others see you as a peacemaker and trusted confidant.',
        3: 'You project charm, creativity, and joy. Others see you as entertaining, expressive, and socially magnetic.',
        4: 'You project reliability, practicality, and trustworthiness. Others see you as dependable and grounded.',
        5: 'You project dynamism, versatility, and excitement. Others see you as adventurous and full of life.',
        6: 'You project warmth, responsibility, and care. Others see you as nurturing, balanced, and deeply trustworthy.',
        7: 'You project mystery, depth, and wisdom. Others see you as enigmatic, intellectual, and spiritually aware.',
        8: 'You project power, authority, and ambition. Others see you as a force to be reckoned with — capable and commanding.',
        9: 'You project wisdom, compassion, and universal understanding. Others see you as old-souled and deeply humanitarian.',
        11: 'You project an ethereal, inspirational quality. Others sense your spiritual depth and visionary nature immediately.',
        22: 'You project mastery and capability. Others sense your ability to achieve the extraordinary.',
        33: 'You project unconditional love and healing wisdom. Others feel uplifted simply by being in your presence.',
      },
      'personal_day': {
        1: 'A powerful day for new beginnings and bold actions. Plant seeds and take initiative.',
        2: 'A day for cooperation, patience, and nurturing relationships. Listen more than you speak.',
        3: 'A joyful, creative day. Express yourself, socialize, and let your imagination run free.',
        4: 'A day for practical work, organization, and building foundations. Focus and discipline pay off.',
        5: 'A dynamic day full of change and unexpected opportunities. Stay flexible and embrace the new.',
        6: 'A day for love, family, and responsibility. Nurture those around you and beautify your space.',
        7: 'A day for introspection, research, and spiritual reflection. Solitude brings insight.',
        8: 'A powerful day for business, finances, and manifesting material goals. Think big.',
        9: 'A day for completion, release, and compassionate giving. Let go of what no longer serves you.',
      },
    };

    final typeMap = interpretations[type];
    if (typeMap == null) {
      return 'This number carries unique vibrations that are still being decoded by the cosmic engine.';
    }
    return typeMap[number] ??
        'Number $number in the $type position carries powerful vibrations that transcend standard interpretation. Your path is uniquely your own.';
  }

  // ─────────────────────────────────────────────
  // CHINESE ZODIAC
  // ─────────────────────────────────────────────

  static Map<String, dynamic> getChineseZodiacProfile({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);
    final profile = ChineseZodiacEngine.profile(dobDt.year, dobDt.month, birthHour);

    final animal = profile['animal'] as String;
    final element = profile['element'] as String;
    final yinYang = profile['yinYang'] as String;
    final innerAnimal = profile['innerAnimal'] as String;
    final secretAnimal = profile['secretAnimal'] as String;
    final trineGroup = profile['trineGroupName'] as String;

    // Animal emoji mapping
    const animalEmojis = {
      'Rat': '🐀', 'Ox': '🐂', 'Tiger': '🐯', 'Rabbit': '🐰',
      'Dragon': '🐉', 'Snake': '🐍', 'Horse': '🐴', 'Goat': '🐐',
      'Monkey': '🐵', 'Rooster': '🐓', 'Dog': '🐕', 'Pig': '🐷',
    };

    // Element color mapping
    const elementColors = {
      'Wood': 0xFF10B981, 'Fire': 0xFFEF4444, 'Earth': 0xFFF59E0B,
      'Metal': 0xFFC0C0C0, 'Water': 0xFF3B82F6,
    };

    // Compatible animals by trine
    final compatible = profile['secretFriend'] != null
        ? [profile['secretFriend'] as String, ...(profile['trineAnimals'] as List).cast<String>()]
        : (profile['trineAnimals'] as List).cast<String>();

    // Incompatible = clash animal
    final incompatible = profile['clashAnimal'] != null
        ? [profile['clashAnimal'] as String]
        : <String>[];

    // Lucky numbers based on element
    const elementLucky = {
      'Wood': [3, 8], 'Fire': [2, 7], 'Earth': [5, 10],
      'Metal': [4, 9], 'Water': [1, 6],
    };

    const elementDirections = {
      'Wood': 'East', 'Fire': 'South', 'Earth': 'Center',
      'Metal': 'West', 'Water': 'North',
    };

    const elementLuckyColors = {
      'Wood': 'Green', 'Fire': 'Red', 'Earth': 'Yellow',
      'Metal': 'Gold', 'Water': 'Blue',
    };

    final score = ChineseZodiacEngine.dailyScore(dobDt.year);

    return {
      'animal': animal,
      'emoji': animalEmojis[animal] ?? '🐉',
      'element': element,
      'yinYang': yinYang,
      'innerAnimal': innerAnimal,
      'innerAnimalEmoji': animalEmojis[innerAnimal] ?? '🐰',
      'secretAnimal': secretAnimal,
      'secretAnimalEmoji': animalEmojis[secretAnimal] ?? '🐓',
      'trineGroup': trineGroup,
      'trineAnimals': (profile['trineAnimals'] as List).cast<String>(),
      'luckyColor': elementLuckyColors[element] ?? 'Gold',
      'luckyColorHex': elementColors[element] ?? 0xFFF59E0B,
      'luckyDirection': elementDirections[element] ?? 'East',
      'luckyNumbers': elementLucky[element] ?? [1, 6, 7],
      'compatibleAnimals': compatible,
      'incompatibleAnimals': incompatible,
      'yearDescription': '$element $animal (${dobDt.year})',
      'elementDescription': '$element brings ${element == 'Fire' ? 'passion and dynamism' : element == 'Water' ? 'wisdom and adaptability' : element == 'Wood' ? 'growth and creativity' : element == 'Metal' ? 'determination and persistence' : 'stability and grounding'} to the $animal\'s natural power and charisma.',
      'personalityTraits': _getAnimalTraits(animal),
      'overallFortune': score > 70
          ? 'Exceptional fortune awaits the $element $animal this cycle. Your natural magnetism attracts powerful allies and abundant opportunities.'
          : score > 50
              ? 'Steady fortune guides the $element $animal. Patient cultivation of relationships and projects yields lasting rewards.'
              : 'The $element $animal is called to inner work this cycle. Reflection and careful planning lay the groundwork for future breakthroughs.',
      'loveFortune': score > 60
          ? 'Deep romantic connections are highlighted. Your charm and authenticity draw meaningful relationships.'
          : 'Love requires patience this cycle. Focus on self-love and existing bonds will deepen naturally.',
      'careerFortune': score > 60
          ? 'Leadership opportunities emerge. Your innovative ideas gain recognition from influential figures.'
          : 'Career growth is gradual but steady. Focus on skill-building and strategic networking.',
      'healthFortune': 'Vitality is ${score > 60 ? 'strong' : 'moderate'}. ${score > 60 ? 'Channel your energy wisely' : 'Guard against overexertion'}. Incorporate mindful practices to balance your drive with necessary rest.',
    };
  }

  static List<String> _getAnimalTraits(String animal) {
    const traits = {
      'Rat': ['Resourceful', 'Quick-witted', 'Versatile', 'Charming', 'Alert'],
      'Ox': ['Diligent', 'Dependable', 'Strong', 'Determined', 'Patient'],
      'Tiger': ['Brave', 'Competitive', 'Confident', 'Charismatic', 'Ambitious'],
      'Rabbit': ['Gentle', 'Elegant', 'Alert', 'Quick', 'Compassionate'],
      'Dragon': ['Confident', 'Ambitious', 'Charismatic', 'Visionary', 'Passionate'],
      'Snake': ['Intuitive', 'Wise', 'Decisive', 'Elegant', 'Discreet'],
      'Horse': ['Energetic', 'Independent', 'Warm-hearted', 'Enthusiastic', 'Adventurous'],
      'Goat': ['Calm', 'Gentle', 'Creative', 'Thoughtful', 'Persevering'],
      'Monkey': ['Clever', 'Curious', 'Mischievous', 'Witty', 'Versatile'],
      'Rooster': ['Observant', 'Hardworking', 'Courageous', 'Talented', 'Confident'],
      'Dog': ['Loyal', 'Honest', 'Amiable', 'Kind', 'Prudent'],
      'Pig': ['Compassionate', 'Generous', 'Diligent', 'Calm', 'Optimistic'],
    };
    return traits[animal] ?? ['Unique', 'Powerful', 'Cosmic', 'Aligned', 'Blessed'];
  }

  // ─────────────────────────────────────────────
  // MAHABOTE (BURMESE ASTROLOGY)
  // ─────────────────────────────────────────────

  static Map<String, dynamic> getMahaboteProfile({
    required String dob,
    required String birthTime,
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);

    final birthDayKey = MahaboteEngine.birthDayKey(dobDt, birthHour);
    final data = MahaboteEngine.dayData[birthDayKey]!;
    final chart = MahaboteEngine.birthChart(dobDt, birthHour);
    final dasa = MahaboteEngine.currentDasa(dobDt, birthHour);

    final animal = data['animal'] as String;
    final planet = data['planet'] as String;
    final direction = data['direction'] as String;

    // Day name for display
    const dayNames = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday AM', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday', 8: 'Wednesday PM',
    };
    // Map weekday to Burmese day name
    String birthDay;
    if (birthDayKey == 'wednesday_am') {
      birthDay = 'Wednesday (Morning)';
    } else if (birthDayKey == 'wednesday_pm') {
      birthDay = 'Wednesday (Afternoon)';
    } else {
      const weekdayNames = {
        'monday': 'Monday', 'tuesday': 'Tuesday', 'thursday': 'Thursday',
        'friday': 'Friday', 'saturday': 'Saturday', 'sunday': 'Sunday',
      };
      birthDay = weekdayNames[birthDayKey] ?? birthDayKey;
    }

    // Animal emoji mapping
    const animalEmojis = {
      'Tiger': '🐯', 'Lion': '🦁', 'Tusked Elephant': '🐘',
      'Tuskless Elephant': '🐘', 'Mouse': '🐭', 'Guinea Pig': '🐹',
      'Naga': '🐍', 'Garuda': '🦅',
    };

    // Planet symbols
    const planetSymbols = {
      'Moon': '☽', 'Mars': '♂', 'Mercury': '☿', 'Jupiter': '♃',
      'Venus': '♀', 'Saturn': '♄', 'Sun': '☉', 'Rahu': '☊',
    };

    final dasaPlanet = dasa['planet'] as String;
    final dasaYearsRemaining = dasa['yearsRemaining'] as int;

    // Build octagon houses from chart
    final octagonHouses = <Map<String, dynamic>>[];
    const houseNames = [
      'House of Birth', 'House of Wealth', 'House of Advancement',
      'House of Fortune', 'House of Children', 'House of Enemies',
      'House of Partnership', 'House of Transformation',
    ];
    const housePlanets = ['Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Rahu'];

    for (int i = 0; i < 8; i++) {
      octagonHouses.add({
        'house': i + 1,
        'name': houseNames[i],
        'planet': housePlanets[i],
        'symbol': planetSymbols[housePlanets[i]] ?? '✦',
        'description': _getHouseDescription(i + 1),
      });
    }

    final score = MahaboteEngine.dailyScore(dobDt, birthHour);

    return {
      'birthDay': birthDay,
      'animal': animal,
      'animalEmoji': animalEmojis[animal] ?? '🐘',
      'planet': planet,
      'planetSymbol': planetSymbols[planet] ?? '✦',
      'direction': direction,
      'directionEmoji': '🧭',
      'house': _getHouseForPlanet(planet),
      'houseNumber': _getHouseNumberForPlanet(planet),
      'dasaPeriod': '$dasaPlanet Dasa',
      'dasaYearsRemaining': dasaYearsRemaining,
      'dasaDescription': 'The $dasaPlanet Dasa period ${_getDasaDescription(dasaPlanet)}. ${dasaYearsRemaining > 5 ? 'You have significant time to harness this energy.' : 'A transition approaches — prepare for new planetary influences.'}',
      'houseInterpretation': 'The ${_getHouseForPlanet(planet)} indicates ${score > 60 ? 'upward movement' : 'steady consolidation'} in ${_getHouseTheme(planet)}.',
      'planetInfluence': '$planet governs your ${_getPlanetDomain(planet)}. ${score > 60 ? 'Your mind is sharp and your words carry weight.' : 'Patience strengthens your innate gifts.'}',
      'directionInfluence': '$direction is your power direction. Facing $direction during important activities amplifies your natural $planet energy.',
      'octagonHouses': octagonHouses,
    };
  }

  static String _getHouseForPlanet(String planet) {
    const mapping = {
      'Sun': 'House of Birth', 'Moon': 'House of Wealth',
      'Mercury': 'House of Advancement', 'Venus': 'House of Fortune',
      'Mars': 'House of Children', 'Jupiter': 'House of Enemies',
      'Saturn': 'House of Partnership', 'Rahu': 'House of Transformation',
    };
    return mapping[planet] ?? 'House of Advancement';
  }

  static int _getHouseNumberForPlanet(String planet) {
    const mapping = {
      'Sun': 1, 'Moon': 2, 'Mercury': 3, 'Venus': 4,
      'Mars': 5, 'Jupiter': 6, 'Saturn': 7, 'Rahu': 8,
    };
    return mapping[planet] ?? 3;
  }

  static String _getHouseDescription(int house) {
    const descriptions = {
      1: 'Origins, identity, and life force',
      2: 'Material resources and emotional security',
      3: 'Progress, siblings, and short journeys',
      4: 'Happiness, home, and hidden treasures',
      5: 'Creativity, offspring, and speculation',
      6: 'Obstacles, health, and service',
      7: 'Marriage, contracts, and alliances',
      8: 'Death, rebirth, and hidden matters',
    };
    return descriptions[house] ?? 'Cosmic influence';
  }

  static String _getHouseTheme(String planet) {
    const themes = {
      'Sun': 'identity and leadership',
      'Moon': 'wealth and emotional security',
      'Mercury': 'career and intellectual pursuits',
      'Venus': 'fortune and domestic harmony',
      'Mars': 'creativity and action',
      'Jupiter': 'wisdom and overcoming obstacles',
      'Saturn': 'partnerships and commitments',
      'Rahu': 'transformation and hidden knowledge',
    };
    return themes[planet] ?? 'life matters';
  }

  static String _getDasaDescription(String planet) {
    const descriptions = {
      'Sun': 'enhances leadership, vitality, and recognition',
      'Moon': 'amplifies intuition, emotional wisdom, and public influence',
      'Mars': 'fuels courage, action, and competitive drive',
      'Mercury': 'enhances intellect, communication, and business acumen',
      'Jupiter': 'expands wisdom, spiritual growth, and good fortune',
      'Venus': 'heightens creativity, romance, and material comfort',
      'Saturn': 'builds discipline, patience, and lasting structures',
      'Rahu': 'drives transformation, ambition, and unconventional paths',
    };
    return descriptions[planet] ?? 'influences your cosmic journey';
  }

  static String _getPlanetDomain(String planet) {
    const domains = {
      'Sun': 'vitality, leadership, and sense of self',
      'Moon': 'emotions, intuition, and public life',
      'Mars': 'energy, courage, and physical strength',
      'Mercury': 'intellectual faculties, communication, and commercial instincts',
      'Jupiter': 'wisdom, expansion, and good fortune',
      'Venus': 'love, beauty, and creative expression',
      'Saturn': 'discipline, responsibility, and karmic lessons',
      'Rahu': 'destiny, obsession, and worldly ambition',
    };
    return domains[planet] ?? 'cosmic influence';
  }

  // ─────────────────────────────────────────────
  // LUNAR PHASE
  // ─────────────────────────────────────────────

  static String getMoonPhase() {
    return LunarEngine.phaseName();
  }

  static String getMoonPhaseEmoji() {
    const phaseEmojis = {
      'New Moon': '🌑', 'Waxing Crescent': '🌒', 'First Quarter': '🌓',
      'Waxing Gibbous': '🌔', 'Full Moon': '🌕', 'Waning Gibbous': '🌖',
      'Last Quarter': '🌗', 'Waning Crescent': '🌘',
    };
    return phaseEmojis[LunarEngine.phaseName()] ?? '🌕';
  }

  static bool isVoidOfCourse() {
    return LunarEngine.isVoidOfCourse();
  }

  static int getDaysUntilFullMoon() {
    return LunarEngine.daysUntilFullMoon();
  }

  static int getDaysUntilNewMoon() {
    return LunarEngine.daysUntilNewMoon();
  }

  static List<Map<String, dynamic>> getMonthlyMoonPhases() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> allPhases = [];

    for (int monthOffset = -1; monthOffset <= 2; monthOffset++) {
      final targetYear = now.year;
      final targetMonth = now.month + monthOffset;
      final adjustedDate = DateTime(targetYear, targetMonth, 1);
      final phases = LunarEngine.monthlyPhases(adjustedDate.year, adjustedDate.month);
      allPhases.addAll(phases);
    }

    // Deduplicate by date+type
    final seen = <String>{};
    allPhases.removeWhere((phase) {
      final date = phase['date'] as DateTime;
      final key = '${date.year}-${date.month}-${date.day}-${phase['type']}';
      return !seen.add(key);
    });

    return allPhases;
  }

  static String getMoonPhaseDescription(String phaseName) {
    const descriptions = {
      'New Moon': 'The New Moon marks a time of new beginnings. Plant seeds of intention, start fresh projects, and set powerful goals. The darkness invites introspection and inner renewal.',
      'Waxing Crescent': 'The Waxing Crescent phase supports taking action on your intentions. Momentum builds as the moon grows. Focus your energy on growth and forward movement.',
      'First Quarter': 'The First Quarter moon brings challenges that test your resolve. Decision-making energy is strong. Push through obstacles with determination and clarity.',
      'Waxing Gibbous': 'The Waxing Gibbous phase amplifies manifestation energy. Refine your plans and persist with dedication. The full moon\'s power is nearly at its peak.',
      'Full Moon': 'The Full Moon illuminates what was hidden and brings matters to culmination. Emotions run high, intuition peaks, and manifestations come to fruition. Release what no longer serves you.',
      'Waning Gibbous': 'The Waning Gibbous phase invites gratitude and sharing. Distribute your wisdom and resources. The energy of completion and generosity flows strongly.',
      'Last Quarter': 'The Last Quarter moon supports release and forgiveness. Let go of old patterns, habits, and relationships that have run their course. Make space for the new.',
      'Waning Crescent': 'The Waning Crescent phase is a time of rest, reflection, and surrender. Honor your need for solitude and quiet. Prepare your spirit for the next cycle of renewal.',
    };
    return descriptions[phaseName] ??
        'This lunar phase carries unique cosmic energy that influences your emotions, intuition, and manifestation power. Tune into the moon\'s wisdom and let it guide your inner journey.';
  }

  // ─────────────────────────────────────────────
  // COMPATIBILITY
  // ─────────────────────────────────────────────

  static Map<String, dynamic> getCompatibilityScores(
    String partnerName,
    String partnerDob,
    String partnerBirthTime, {
    required String userDob,
    required String userBirthTime,
    required String userFullName,
  }) {
    final userDobDt = _parseDob(userDob);
    final partnerDobDt = _parseDob(partnerDob);
    final userBirthH = _parseBirthHour(userBirthTime);
    final partnerBirthH = _parseBirthHour(partnerBirthTime);

    // Astrology compatibility: element harmony
    final userSun = AstrologyEngine.sunSign(userDobDt);
    final partnerSun = AstrologyEngine.sunSign(partnerDobDt);
    final astroCompat = _elementCompatibility(userSun, partnerSun);

    // Numerology: life path compatibility
    final userLP = NumerologyEngine.lifePathNumber(userDobDt);
    final partnerLP = NumerologyEngine.lifePathNumber(partnerDobDt);
    final numCompat = _lifePathCompatibility(userLP, partnerLP);

    // Chinese: animal compatibility
    final userAnimal = ChineseZodiacEngine.profile(userDobDt.year, userDobDt.month, userBirthH)['animal'] as String;
    final partnerAnimal = ChineseZodiacEngine.profile(partnerDobDt.year, partnerDobDt.month, partnerBirthH)['animal'] as String;
    // Chinese compatibility based on trine groups and compatible animals
    final userCompatible = ChineseZodiacEngine.compatibleAnimals(userAnimal);
    final chineseCompat = userCompatible.contains(partnerAnimal) ? 85 :
        ChineseZodiacEngine.incompatibleAnimals(userAnimal).contains(partnerAnimal) ? 40 : 65;

    // Mahabote: planet compatibility
    final userDayKey = MahaboteEngine.birthDayKey(userDobDt, userBirthH);
    final partnerDayKey = MahaboteEngine.birthDayKey(partnerDobDt, partnerBirthH);
    final userPlanet = MahaboteEngine.dayData[userDayKey]?['planet'] as String? ?? 'Mercury';
    final partnerPlanet = MahaboteEngine.dayData[partnerDayKey]?['planet'] as String? ?? 'Venus';
    final mahaboteCompat = MahaboteEngine.compatibility(userDayKey, partnerDayKey);

    // Lunar: moon phase birth compatibility
    final lunarCompat = _lunarCompatibility(userDobDt, partnerDobDt);

    final overall = (astroCompat * 0.25 + numCompat * 0.20 + chineseCompat * 0.20 +
            mahaboteCompat * 0.20 + lunarCompat * 0.15)
        .round()
        .clamp(0, 100);

    return {
      'overallScore': overall,
      'narrativeSummary': _buildCompatNarrative(partnerName, overall, userSun, partnerSun, userLP, partnerLP, userAnimal, partnerAnimal),
      'scores': {
        'astrology': astroCompat,
        'numerology': numCompat,
        'chinese': chineseCompat,
        'mahabote': mahaboteCompat,
        'lunar': lunarCompat,
      },
      'systemDetails': {
        'astrology': 'Your $userSun sun and their $partnerSun sun ${astroCompat > 70 ? 'create a powerful harmony' : astroCompat > 50 ? 'share complementary qualities' : 'present growth opportunities'} in the zodiac.',
        'numerology': 'Your Life Path $userLP and their Life Path $partnerLP ${numCompat > 70 ? 'create a dynamic synergy' : numCompat > 50 ? 'complement each other beautifully' : 'challenge each other to grow'}. Together your numbers reduce to ${(userLP + partnerLP) % 9 + 1}.',
        'chinese': '$userAnimal and $partnerAnimal ${chineseCompat > 70 ? 'share deep compatibility' : chineseCompat > 50 ? 'find balance through contrast' : 'learn from their differences'} in Chinese astrology.',
        'mahabote': 'Your $userPlanet day and their $partnerPlanet day ${mahaboteCompat > 70 ? 'create harmonious energy' : 'bring complementary perspectives'}.',
        'lunar': 'Your moon phases at birth ${lunarCompat > 70 ? 'are in harmonious alignment' : 'create an intriguing dynamic'}, indicating ${lunarCompat > 60 ? 'natural empathy' : 'growth through understanding'}.',
      },
    };
  }

  static int _elementCompatibility(String sign1, String sign2) {
    const signElements = {
      'Aries': 'Fire', 'Leo': 'Fire', 'Sagittarius': 'Fire',
      'Taurus': 'Earth', 'Virgo': 'Earth', 'Capricorn': 'Earth',
      'Gemini': 'Air', 'Libra': 'Air', 'Aquarius': 'Air',
      'Cancer': 'Water', 'Scorpio': 'Water', 'Pisces': 'Water',
    };
    final e1 = signElements[sign1] ?? 'Fire';
    final e2 = signElements[sign2] ?? 'Fire';

    if (e1 == e2) return 85;
    // Fire-Air and Earth-Water are compatible
    if ((e1 == 'Fire' && e2 == 'Air') || (e1 == 'Air' && e2 == 'Fire')) return 78;
    if ((e1 == 'Earth' && e2 == 'Water') || (e1 == 'Water' && e2 == 'Earth')) return 78;
    // Adjacent elements
    return 55;
  }

  static int _lifePathCompatibility(int lp1, int lp2) {
    // Reduce master numbers for comparison
    final r1 = lp1 > 9 ? (lp1 == 11 ? 2 : lp1 == 22 ? 4 : 6) : lp1;
    final r2 = lp2 > 9 ? (lp2 == 11 ? 2 : lp2 == 22 ? 4 : 6) : lp2;

    if (r1 == r2) return 80;
    final sum = r1 + r2;
    if (sum <= 5) return 75;
    if (sum <= 9) return 70;
    if (sum <= 13) return 65;
    return 55;
  }

  static int _lunarCompatibility(DateTime dob1, DateTime dob2) {
    final age1 = LunarEngine.moonAge(date: dob1);
    final age2 = LunarEngine.moonAge(date: dob2);
    final diff = (age1 - age2).abs();
    // Phases in harmony when 0, ~7.4 (quarter), ~14.8 (opposition can be dynamic)
    if (diff < 3.7) return 85; // Same phase
    if (diff < 7.4) return 70; // Adjacent phases
    if ((diff - 14.77).abs() < 3.7) return 65; // Opposition — dynamic
    return 60;
  }

  static String _buildCompatNarrative(String partnerName, int score, String userSun,
      String partnerSun, int userLP, int partnerLP, String userAnimal, String partnerAnimal) {
    final buf = StringBuffer();
    buf.write('Your cosmic connection with $partnerName reveals ');
    if (score > 75) {
      buf.write('a powerful soul-level bond. The stars align in your favor, suggesting a relationship of depth, passion, and mutual growth. ');
    } else if (score > 60) {
      buf.write('a complementary partnership rich with potential. Your combined energies create balance — ');
    } else {
      buf.write('an intriguing dynamic of contrast and growth. Your differences are your greatest teachers — ');
    }
    buf.write('Your $userSun-$partnerSun axis and $userAnimal-$partnerAnimal pairing ');
    buf.write(score > 65
        ? 'form a harmonious cosmic blueprint.'
        : 'invite mutual evolution and understanding.');
    return buf.toString();
  }

  // ─────────────────────────────────────────────
  // ARCHETYPE
  // ─────────────────────────────────────────────

  static Map<String, dynamic> getArchetypeProfile({required int archetypeId}) {
    final profile = ArchetypeEngine.getProfile(archetypeId);

    // Map archetype name to emoji
    const archetypeEmojis = {
      'The Ruler': '👑', 'The Creator': '🎨', 'The Magician': '🎩',
      'The Hero': '⚔️', 'The Rebel': '🔥', 'The Lover': '❤️',
      'The Caregiver': '🤲', 'The Jester': '🃏', 'The Sage': '📚',
      'The Innocent': '🕊️', 'The Explorer': '🧭', 'The Everyperson': '🤝',
    };

    final name = profile['name'] as String? ?? 'The Seeker';

    return {
      'archetypeId': archetypeId,
      'name': name,
      'emoji': archetypeEmojis[name] ?? '✨',
      'description': profile['description'] ?? 'You embody a unique cosmic archetype.',
      'strengths': (profile['strengths'] as List?)?.cast<String>() ?? ['Wisdom', 'Intuition'],
      'challenges': (profile['challenges'] as List?)?.cast<String>() ?? ['Balance'],
      'lifeLesson': profile['shadow'] ?? 'To use your gifts in service of the highest good.',
      'compatibleArchetypes': (profile['compatible'] as List?)?.cast<String>() ?? [],
      'shadowAspect': profile['shadow'] ?? 'Balance between light and shadow.',
      'dailyAffirmation': profile['affirmation'] ?? 'I am aligned with my highest purpose.',
    };
  }

  // ─────────────────────────────────────────────
  // DECISION ENGINE
  // ─────────────────────────────────────────────

  /// Runs the Lucky Decision Engine for a given question/category/target date.
  /// Parses user profile strings and delegates to DecisionEngine.calculate().
  // ─────────────────────────────────────────────
  // BUSINESS COMPATIBILITY
  // ─────────────────────────────────────────────

  /// Business compatibility scoring with different weights per partnership type.
  /// [partnershipType]: 'cofounder', 'employee', 'partner', 'investor'
  static Map<String, dynamic> getBusinessCompatibility(
    String partnerName,
    String partnerDob,
    String partnerBirthTime, {
    required String userDob,
    required String userBirthTime,
    required String userFullName,
    required int userArchetypeId,
    required String partnershipType,
  }) {
    final userDobDt = _parseDob(userDob);
    final partnerDobDt = _parseDob(partnerDob);
    final userBirthH = _parseBirthHour(userBirthTime);
    final partnerBirthH = _parseBirthHour(partnerBirthTime);

    // Numerology: expression number compatibility (business-focused)
    final userExpr = NumerologyEngine.expressionNumber(userFullName);
    final partnerExpr = NumerologyEngine.expressionNumber(partnerName);
    final userLP = NumerologyEngine.lifePathNumber(userDobDt);
    final partnerLP = NumerologyEngine.lifePathNumber(partnerDobDt);

    // Expression number compatibility — key for business
    int exprCompat = 50;
    if (userExpr == partnerExpr) exprCompat = 85;
    else if ((userExpr + partnerExpr) % 9 == 0 || (userExpr + partnerExpr) % 9 == 8) exprCompat = 80;
    else if (_isComplementary(userExpr, partnerExpr)) exprCompat = 75;
    else exprCompat = 60;

    // Life path business compatibility
    int lpCompat = 50;
    if (userLP == partnerLP) lpCompat = 75;
    else if (userLP + partnerLP == 9 || (userLP * partnerLP) % 8 == 0) lpCompat = 80;
    else if (_isComplementary(userLP, partnerLP)) lpCompat = 70;
    else lpCompat = 55;

    // Chinese zodiac element harmony
    final userAnimal = ChineseZodiacEngine.profile(userDobDt.year, userDobDt.month, userBirthH)['animal'] as String;
    final partnerAnimal = ChineseZodiacEngine.profile(partnerDobDt.year, partnerDobDt.month, partnerBirthH)['animal'] as String;
    final userCompatible = ChineseZodiacEngine.compatibleAnimals(userAnimal);
    final chineseCompat = userCompatible.contains(partnerAnimal) ? 82 :
        ChineseZodiacEngine.incompatibleAnimals(userAnimal).contains(partnerAnimal) ? 38 : 62;

    // Mahabote work direction compatibility
    final userDayKey = MahaboteEngine.birthDayKey(userDobDt, userBirthH);
    final partnerDayKey = MahaboteEngine.birthDayKey(partnerDobDt, partnerBirthH);
    final mahaboteCompat = MahaboteEngine.compatibility(userDayKey, partnerDayKey);

    // Archetype complementarity for business
    final archetypeProfile = ArchetypeEngine.getProfile(userArchetypeId);
    final compatArchetypes = (archetypeProfile['compatibleArchetypes'] as List?)?.cast<String>() ?? [];
    // Estimate partner archetype from name+DOB for basic scoring
    final partnerArchIdx = (partnerLP + partnerExpr) % 12;
    final partnerArchName = ArchetypeEngine.archetypes[partnerArchIdx]['name'] as String;
    final archetypeCompat = compatArchetypes.contains(partnerArchName) ? 82 : 58;

    // Partnership-type weights
    final weights = _businessWeights(partnershipType);
    final overall = (
      exprCompat * weights['expression']! +
      lpCompat * weights['lifePath']! +
      chineseCompat * weights['chinese']! +
      mahaboteCompat * weights['mahabote']! +
      archetypeCompat * weights['archetype']!
    ).round().clamp(0, 100);

    final partnershipLabel = _partnershipLabel(partnershipType);

    return {
      'overallScore': overall,
      'partnershipType': partnershipType,
      'narrativeSummary': _buildBusinessNarrative(partnerName, overall, partnershipLabel, userExpr, partnerExpr, userAnimal, partnerAnimal),
      'scores': {
        'expression': exprCompat,
        'lifePath': lpCompat,
        'chinese': chineseCompat,
        'mahabote': mahaboteCompat,
        'archetype': archetypeCompat,
      },
      'systemDetails': {
        'expression': 'Your expression $userExpr and their expression $partnerExpr ${exprCompat > 70 ? 'create powerful business synergy' : 'offer complementary skill sets'}. Combined vibration: ${(userExpr + partnerExpr) % 9 + 1}.',
        'lifePath': 'Life paths $userLP and $partnerLP ${lpCompat > 70 ? 'share aligned ambitions and drive' : 'bring diverse perspectives to the table'}.',
        'chinese': '$userAnimal and $partnerAnimal ${chineseCompat > 70 ? 'form a strong professional alliance' : 'balance each other\'s working styles'} in Chinese astrology.',
        'mahabote': 'Your work directions ${mahaboteCompat > 70 ? 'create harmonious workflow' : 'bring complementary approaches'} in Burmese astrology.',
        'archetype': 'Your archetype and their $partnerArchName energy ${archetypeCompat > 70 ? 'create a powerful leadership dynamic' : 'offer diverse strengths to the partnership'}.',
      },
    };
  }

  static bool _isComplementary(int a, int b) {
    const pairs = [{1, 8}, {2, 7}, {3, 6}, {4, 5}, {1, 5}, {3, 9}, {8, 9}];
    final set = {a > 9 ? a % 9 + 1 : a, b > 9 ? b % 9 + 1 : b};
    return pairs.any((p) => p.containsAll(set));
  }

  static Map<String, double> _businessWeights(String type) {
    switch (type) {
      case 'cofounder':
        return {'expression': 0.30, 'lifePath': 0.20, 'chinese': 0.15, 'mahabote': 0.10, 'archetype': 0.25};
      case 'employee':
        return {'expression': 0.20, 'lifePath': 0.15, 'chinese': 0.15, 'mahabote': 0.25, 'archetype': 0.25};
      case 'investor':
        return {'expression': 0.35, 'lifePath': 0.25, 'chinese': 0.15, 'mahabote': 0.10, 'archetype': 0.15};
      case 'partner':
      default:
        return {'expression': 0.25, 'lifePath': 0.25, 'chinese': 0.20, 'mahabote': 0.15, 'archetype': 0.15};
    }
  }

  static String _partnershipLabel(String type) {
    switch (type) {
      case 'cofounder': return 'Co-Founder';
      case 'employee': return 'Employee';
      case 'investor': return 'Investor';
      case 'partner': return 'Business Partner';
      default: return 'Business Partner';
    }
  }

  static String _buildBusinessNarrative(String name, int score, String type,
      int userExpr, int partnerExpr, String userAnimal, String partnerAnimal) {
    final buf = StringBuffer();
    buf.write('Your $type compatibility with $name reveals ');
    if (score > 75) {
      buf.write('exceptional professional synergy. Your combined numerological energies suggest a partnership built for success. ');
    } else if (score > 60) {
      buf.write('solid business potential with complementary strengths. ');
    } else {
      buf.write('areas that require careful alignment. Different working styles can become strengths with conscious effort. ');
    }
    buf.write('Expression numbers $userExpr and $partnerExpr ');
    buf.write(score > 65
        ? 'create a balanced professional vibration.'
        : 'benefit from clear role definition.');
    return buf.toString();
  }

  // ─────────────────────────────────────────────
  // DECISION ENGINE
  // ─────────────────────────────────────────────

  static Map<String, dynamic> getDecisionReading({
    required String category,
    required DateTime targetDate,
    required String dob,
    required String fullName,
    required String birthTime,
    required int archetypeId,
    String questionText = '',
  }) {
    final dobDt = _parseDob(dob);
    final birthHour = _parseBirthHour(birthTime);

    return DecisionEngine.calculate(
      category: category,
      targetDate: targetDate,
      dob: dobDt,
      fullName: fullName,
      birthHour: birthHour,
      archetypeId: archetypeId,
      questionText: questionText,
    );
  }
}
