/// Wealth & Money Calculation Engine
/// Combines numerology, lunar, planetary, and Chinese zodiac data for
/// financial timing and lucky numbers.
import 'dart:math';
import 'package:cosmiq_guru/engines/numerology_engine.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';
import 'package:cosmiq_guru/engines/planetary_hours_engine.dart';
import 'package:cosmiq_guru/engines/chinese_zodiac_engine.dart';


class WealthEngine {
  WealthEngine._();

  /// Personal wealth cycle phases mapped from personal year number
  static const _cyclePhases = {
    1: {
      'phase': 'New Beginnings',
      'description': 'A fresh financial cycle begins. Plant seeds for future prosperity. Start new ventures, open accounts, explore opportunities.',
      'peakMonths': [1, 5, 9],
      'energy': 'expansion',
    },
    2: {
      'phase': 'Partnership',
      'description': 'Financial growth through collaboration. Joint ventures, partnerships, and shared investments are favored.',
      'peakMonths': [2, 6, 11],
      'energy': 'cooperation',
    },
    3: {
      'phase': 'Creative Growth',
      'description': 'Money flows through creative channels. Marketing, branding, and creative projects bring returns.',
      'peakMonths': [3, 7, 11],
      'energy': 'expansion',
    },
    4: {
      'phase': 'Foundation Building',
      'description': 'Focus on financial structure. Budget, save, invest conservatively. Build the foundation for lasting wealth.',
      'peakMonths': [4, 8, 12],
      'energy': 'consolidation',
    },
    5: {
      'phase': 'Dynamic Change',
      'description': 'Financial landscape shifts. Stay flexible, diversify, and be open to unexpected opportunities.',
      'peakMonths': [5, 9, 1],
      'energy': 'expansion',
    },
    6: {
      'phase': 'Responsibility',
      'description': 'Focus on family finances, real estate, home investments. Wealth through nurturing and service.',
      'peakMonths': [6, 10, 2],
      'energy': 'consolidation',
    },
    7: {
      'phase': 'Strategic Planning',
      'description': 'Step back and analyze. Research investments, study markets, plan major moves. Avoid impulsive spending.',
      'peakMonths': [7, 11, 3],
      'energy': 'consolidation',
    },
    8: {
      'phase': 'Harvest & Power',
      'description': 'Peak financial year! Reap what you\'ve sown. Major deals, promotions, and abundance flow. Your most prosperous cycle.',
      'peakMonths': [1, 5, 8],
      'energy': 'harvest',
    },
    9: {
      'phase': 'Completion',
      'description': 'Tie up loose ends. Settle debts, close old accounts, donate. Clear the way for the next 9-year cycle.',
      'peakMonths': [3, 9, 12],
      'energy': 'release',
    },
  };

  /// Risk appetite labels
  static const _riskLabels = ['Very Conservative', 'Conservative', 'Moderate', 'Aggressive', 'Very Aggressive'];

  /// Lucky colors for wealth
  static const _wealthColors = ['Gold', 'Green', 'Purple', 'Red', 'Blue', 'Silver', 'Orange', 'White'];

  /// Generate 3 lucky numbers for today.
  /// Derived from personal day + life path + expression number.
  static List<int> luckyNumbers(DateTime dob, String fullName, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: dt);
    final lifePath = NumerologyEngine.lifePathNumber(dob);
    final expression = NumerologyEngine.expressionNumber(fullName);

    // Seed from the date for daily variation
    final daySeed = dt.year * 10000 + dt.month * 100 + dt.day;

    // Number 1: personal day * life path, modulated
    final n1 = ((personalDay * lifePath + daySeed) % 99) + 1;

    // Number 2: expression * day of month, modulated
    final n2 = ((expression * dt.day + lifePath + daySeed ~/ 7) % 99) + 1;

    // Number 3: combination of all three core numbers
    final n3 = ((personalDay + lifePath + expression + dt.weekday + daySeed ~/ 13) % 99) + 1;

    // Ensure no duplicates
    final numbers = <int>{n1, n2, n3};
    while (numbers.length < 3) {
      numbers.add(((numbers.last * 7 + 13) % 99) + 1);
    }

    return numbers.toList()..sort();
  }

  /// Score a single day for investment/financial activity (0-100).
  static int investmentDayScore(DateTime dob, String fullName, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    int score = 50;

    // Numerology: personal day alignment
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: dt);
    // 8 = money/power, 1 = new starts, 3 = growth
    if (personalDay == 8) score += 20;
    else if (personalDay == 1) score += 12;
    else if (personalDay == 3 || personalDay == 5) score += 8;
    else if (personalDay == 4) score += 5; // stability
    else if (personalDay == 7) score -= 5; // introspection, not action
    else if (personalDay == 9) score -= 3; // endings

    // Master numbers
    if (NumerologyEngine.isMasterNumber(personalDay)) score += 10;

    // Lunar phase: waxing = growth (buy), full = peak, waning = sell/consolidate
    final moonPhase = LunarEngine.phaseName(date: dt);
    if (moonPhase == 'Waxing Gibbous') score += 12;
    else if (moonPhase == 'Full Moon') score += 8;
    else if (moonPhase == 'Waxing Crescent') score += 10;
    else if (moonPhase == 'New Moon') score += 5; // new starts
    else if (moonPhase == 'Waning Crescent') score -= 5;

    // Void of course: bad for financial decisions
    if (LunarEngine.isVoidOfCourse(date: dt)) score -= 10;

    // Planetary hours: Jupiter/Venus = wealth planets
    final dayRuler = PlanetaryHoursEngine.dayRulers[dt.weekday == 7 ? DateTime.sunday : dt.weekday] ?? 'Sun';
    if (dayRuler == 'Jupiter') score += 12; // Thursday = Jupiter's day
    else if (dayRuler == 'Venus') score += 8; // Friday = Venus
    else if (dayRuler == 'Saturn') score -= 5; // Saturday = restriction
    else if (dayRuler == 'Sun') score += 5; // Sunday = vitality

    // Chinese element cycle: certain elements favor wealth
    final yearElement = ChineseZodiacEngine.element(dt.year);
    if (yearElement == 'Metal') score += 5; // Metal = money
    else if (yearElement == 'Water') score += 3; // Water = flow
    else if (yearElement == 'Wood') score += 2; // growth

    // Day of week subtle variation
    score += (sin(dt.weekday * pi / 3.5) * 3).round();

    return score.clamp(0, 100);
  }

  /// 7-day financial forecast starting from a given date.
  static List<Map<String, dynamic>> weekForecast(DateTime dob, String fullName, {DateTime? startDate}) {
    final start = startDate ?? DateTime.now();
    final forecast = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final score = investmentDayScore(dob, fullName, date: day);

      String rating;
      String color;
      if (score >= 75) {
        rating = 'Excellent';
        color = 'green';
      } else if (score >= 60) {
        rating = 'Good';
        color = 'green';
      } else if (score >= 45) {
        rating = 'Neutral';
        color = 'amber';
      } else if (score >= 30) {
        rating = 'Caution';
        color = 'amber';
      } else {
        rating = 'Avoid';
        color = 'red';
      }

      forecast.add({
        'date': day,
        'score': score,
        'rating': rating,
        'color': color,
        'dayName': _weekdayName(day.weekday),
        'moonPhase': LunarEngine.phaseEmoji(date: day),
      });
    }

    return forecast;
  }

  /// Personal wealth cycle based on numerology personal year.
  static Map<String, dynamic> wealthCycle(DateTime dob, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final personalYear = NumerologyEngine.personalYearNumber(dob, now: dt);

    // Handle master numbers by reducing for cycle lookup
    int cycleKey = personalYear;
    if (cycleKey > 9) {
      int sum = 0;
      for (final c in cycleKey.toString().split('')) {
        sum += int.tryParse(c) ?? 0;
      }
      cycleKey = sum;
      if (cycleKey > 9) cycleKey = cycleKey % 9;
      if (cycleKey == 0) cycleKey = 9;
    }

    final cycle = _cyclePhases[cycleKey] ?? _cyclePhases[1]!;

    // Chinese element adds context
    final yearElement = ChineseZodiacEngine.element(dt.year);
    final yearAnimal = ChineseZodiacEngine.animal(dt.year);

    return {
      'personalYear': personalYear,
      'cycleYear': cycleKey,
      'phase': cycle['phase'],
      'description': cycle['description'],
      'peakMonths': cycle['peakMonths'],
      'energy': cycle['energy'],
      'chineseElement': yearElement,
      'chineseAnimal': yearAnimal,
      'isMasterYear': NumerologyEngine.isMasterNumber(personalYear),
    };
  }

  /// Best days this month for specific business activities.
  static Map<String, List<Map<String, dynamic>>> businessTiming(DateTime dob, String fullName, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final daysInMonth = DateTime(dt.year, dt.month + 1, 0).day;

    final categories = {
      'contracts': <Map<String, dynamic>>[],
      'launches': <Map<String, dynamic>>[],
      'negotiations': <Map<String, dynamic>>[],
      'raises': <Map<String, dynamic>>[],
    };

    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(dt.year, dt.month, day);
      if (d.isBefore(dt.subtract(const Duration(days: 1)))) continue;

      final personalDay = NumerologyEngine.personalDayNumber(dob, now: d);
      final moonPhase = LunarEngine.phaseName(date: d);
      final dayRuler = PlanetaryHoursEngine.dayRulers[d.weekday == 7 ? DateTime.sunday : d.weekday] ?? 'Sun';
      final isVoc = LunarEngine.isVoidOfCourse(date: d);

      if (isVoc) continue; // Skip void-of-course days for all activities

      final dayInfo = {
        'date': d,
        'dayName': _weekdayName(d.weekday),
        'dayNumber': day,
      };

      // Contracts: Saturn (binding) + personal day 4 or 8
      if ((dayRuler == 'Saturn' || personalDay == 4 || personalDay == 8) &&
          !moonPhase.contains('Waning')) {
        categories['contracts']!.add({...dayInfo, 'reason': _contractReason(personalDay, dayRuler)});
      }

      // Launches: waxing moon + personal day 1, 3, or 5
      if ((personalDay == 1 || personalDay == 3 || personalDay == 5) &&
          (moonPhase.contains('Waxing') || moonPhase == 'New Moon')) {
        categories['launches']!.add({...dayInfo, 'reason': _launchReason(personalDay, moonPhase)});
      }

      // Negotiations: Mercury day + personal day 5 or 6
      if ((dayRuler == 'Mercury' || personalDay == 5 || personalDay == 6) &&
          dayRuler != 'Mars') {
        categories['negotiations']!.add({...dayInfo, 'reason': _negotiationReason(personalDay, dayRuler)});
      }

      // Raises: Jupiter/Sun day + personal day 1 or 8
      if ((dayRuler == 'Jupiter' || dayRuler == 'Sun') &&
          (personalDay == 1 || personalDay == 8)) {
        categories['raises']!.add({...dayInfo, 'reason': _raiseReason(personalDay, dayRuler)});
      }
    }

    // Limit to top 5 per category
    for (final key in categories.keys) {
      if (categories[key]!.length > 5) {
        categories[key] = categories[key]!.sublist(0, 5);
      }
    }

    return categories;
  }

  /// Daily risk appetite score (0-4 index into _riskLabels).
  static Map<String, dynamic> riskAppetite(DateTime dob, String fullName, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final investScore = investmentDayScore(dob, fullName, date: dt);
    final moonPhase = LunarEngine.phaseName(date: dt);
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: dt);

    // Base from investment score
    int riskIndex;
    if (investScore >= 75) {
      riskIndex = 4; // Very Aggressive
    } else if (investScore >= 60) {
      riskIndex = 3; // Aggressive
    } else if (investScore >= 45) {
      riskIndex = 2; // Moderate
    } else if (investScore >= 30) {
      riskIndex = 1; // Conservative
    } else {
      riskIndex = 0; // Very Conservative
    }

    // Moon phase modifies
    if (moonPhase == 'Full Moon' && riskIndex < 4) riskIndex++;
    if (moonPhase.contains('Waning') && riskIndex > 0) riskIndex--;

    riskIndex = riskIndex.clamp(0, 4);

    String advice;
    switch (riskIndex) {
      case 4:
        advice = 'Cosmic alignment strongly favors bold financial moves. High-risk opportunities are supported.';
        break;
      case 3:
        advice = 'Good energy for calculated risks. Trust your instincts on investments today.';
        break;
      case 2:
        advice = 'Balanced day. Stick to your strategy, neither overly cautious nor reckless.';
        break;
      case 1:
        advice = 'Conservative approach recommended. Protect existing gains, avoid speculative moves.';
        break;
      default:
        advice = 'Defensive posture today. Avoid major financial decisions if possible. Wait for better alignment.';
    }

    return {
      'riskIndex': riskIndex,
      'label': _riskLabels[riskIndex],
      'investmentScore': investScore,
      'advice': advice,
      'moonPhase': moonPhase,
      'personalDay': personalDay,
    };
  }

  /// Lucky wealth color for today
  static String luckyWealthColor(DateTime dob, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: dt);
    final idx = (personalDay + dt.weekday + dt.day) % _wealthColors.length;
    return _wealthColors[idx];
  }

  // ── Helper methods ──

  static String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  static String _contractReason(int personalDay, String dayRuler) {
    if (personalDay == 8) return 'Power number 8 — binding agreements favored';
    if (personalDay == 4) return 'Stability number 4 — solid foundations';
    if (dayRuler == 'Saturn') return 'Saturn\'s day — binding commitments';
    return 'Favorable alignment for contracts';
  }

  static String _launchReason(int personalDay, String moonPhase) {
    if (personalDay == 1) return 'Number 1 + $moonPhase — perfect for new beginnings';
    if (personalDay == 3) return 'Creative number 3 + $moonPhase — launch with flair';
    return 'Number 5 + $moonPhase — dynamic launch energy';
  }

  static String _negotiationReason(int personalDay, String dayRuler) {
    if (dayRuler == 'Mercury') return 'Mercury\'s day — communication flows smoothly';
    if (personalDay == 5) return 'Number 5 — adaptable, persuasive energy';
    return 'Number 6 — harmony and compromise favored';
  }

  static String _raiseReason(int personalDay, String dayRuler) {
    if (dayRuler == 'Jupiter' && personalDay == 8) return 'Jupiter + Number 8 — ultimate abundance alignment!';
    if (dayRuler == 'Jupiter') return 'Jupiter\'s day — expansion and generosity';
    if (dayRuler == 'Sun') return 'Sun\'s day — authority figures are receptive';
    return 'Power alignment for salary discussions';
  }
}
