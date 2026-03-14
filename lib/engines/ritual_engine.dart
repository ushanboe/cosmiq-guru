/// Cosmic Rituals & Calendar Engine
/// Determines best days for starting, ending, cleansing, and reflection
/// based on lunar phases, numerology, and planetary hours.
import 'package:cosmiq_guru/engines/numerology_engine.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';
import 'package:cosmiq_guru/engines/planetary_hours_engine.dart';

class RitualEngine {
  RitualEngine._();

  /// Ritual types with metadata
  static const ritualTypes = {
    'start': {
      'label': 'START',
      'emoji': '🟢',
      'description': 'Best for starting new things',
      'colorHex': 0xFF10B981,
    },
    'end': {
      'label': 'END',
      'emoji': '🔴',
      'description': 'Best for ending or releasing',
      'colorHex': 0xFFEF4444,
    },
    'cleanse': {
      'label': 'CLEANSE',
      'emoji': '🟡',
      'description': 'Best for cleansing and clearing',
      'colorHex': 0xFFF59E0B,
    },
    'reflect': {
      'label': 'REFLECT',
      'emoji': '🔵',
      'description': 'Best for reflection and meditation',
      'colorHex': 0xFF3B82F6,
    },
    'neutral': {
      'label': 'NEUTRAL',
      'emoji': '⚪',
      'description': 'No strong ritual energy',
      'colorHex': 0xFF6B7280,
    },
  };

  /// Ritual suggestions by type
  static const _ritualSuggestions = {
    'start': [
      'Start a new habit or daily practice',
      'Begin a new project or creative endeavor',
      'Set fresh intentions and goals',
      'Open a new savings account or investment',
      'Start a new exercise routine',
      'Plant seeds — literally or metaphorically',
      'Launch a new initiative at work',
      'Begin learning something new',
    ],
    'end': [
      'Let go of a habit that no longer serves you',
      'End a commitment that drains your energy',
      'Close old accounts or subscriptions',
      'Forgive and release old grudges',
      'Declutter your physical space',
      'Complete unfinished tasks and projects',
      'Write a farewell letter to your old self',
      'Donate items you no longer need',
    ],
    'cleanse': [
      'Deep clean your living or work space',
      'Digital detox — clear your inbox and phone',
      'Energy clearing — sage, salt, or sound',
      'Take a detox bath with epsom salts',
      'Journal to release pent-up emotions',
      'Clear your diet — start a cleansing fast',
      'Organize your finances and budgets',
      'Meditate on releasing stagnant energy',
    ],
    'reflect': [
      'Meditate on your life\'s direction',
      'Journal about your accomplishments',
      'Practice gratitude — list 10 blessings',
      'Review your goals and adjust course',
      'Spend time in nature and contemplation',
      'Read or study something meaningful',
      'Plan your next steps mindfully',
      'Connect deeply with a loved one',
    ],
  };

  /// Determine the primary ritual type for a given day.
  static String _classifyDay(DateTime dob, String fullName, DateTime date) {
    final moonPhase = LunarEngine.phaseName(date: date);
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: date);
    final moonAge = LunarEngine.moonAge(date: date);
    final fraction = moonAge / LunarEngine.synodicMonth;

    // Strong classifications
    if (moonPhase == 'New Moon') return 'cleanse';
    if (moonPhase == 'Full Moon') return 'reflect';

    // Waxing phases favor starting
    if (fraction < 0.5) {
      if (personalDay == 1 || personalDay == 3 || personalDay == 5) return 'start';
      if (personalDay == 7) return 'reflect';
      if (personalDay == 9) return 'end'; // even during waxing, 9 is endings
      return 'start'; // default waxing = start energy
    }

    // Waning phases favor ending/cleansing
    if (personalDay == 9) return 'end';
    if (personalDay == 7) return 'reflect';
    if (personalDay == 4) return 'cleanse';
    if (moonPhase == 'Waning Crescent') return 'cleanse';
    if (moonPhase == 'Last Quarter') return 'end';

    return 'end'; // default waning = release energy
  }

  /// Score how strong the ritual energy is for a day (0-100).
  static int _ritualScore(DateTime dob, String fullName, DateTime date) {
    final moonPhase = LunarEngine.phaseName(date: date);
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: date);
    final isVoc = LunarEngine.isVoidOfCourse(date: date);
    int score = 50;

    // Key moon phases boost score
    if (moonPhase == 'New Moon' || moonPhase == 'Full Moon') score += 25;
    if (moonPhase == 'First Quarter' || moonPhase == 'Last Quarter') score += 10;

    // Master numbers
    if (NumerologyEngine.isMasterNumber(personalDay)) score += 15;

    // Alignment between moon phase and personal day
    final type = _classifyDay(dob, fullName, date);
    if (type == 'start' && (personalDay == 1 || personalDay == 3)) score += 10;
    if (type == 'end' && personalDay == 9) score += 10;
    if (type == 'cleanse' && personalDay == 4) score += 10;
    if (type == 'reflect' && personalDay == 7) score += 10;

    // Void of course penalty
    if (isVoc) score -= 15;

    // Planetary day alignment
    final dayRuler = PlanetaryHoursEngine.dayRulers[date.weekday == 7 ? DateTime.sunday : date.weekday] ?? 'Sun';
    if (dayRuler == 'Moon' && (type == 'reflect' || type == 'cleanse')) score += 8;
    if (dayRuler == 'Jupiter' && type == 'start') score += 8;
    if (dayRuler == 'Saturn' && type == 'end') score += 8;
    if (dayRuler == 'Sun' && type == 'start') score += 5;

    return score.clamp(0, 100);
  }

  /// Generate ritual calendar for a given month.
  /// Returns a map of day number → ritual info.
  static List<Map<String, dynamic>> monthCalendar(DateTime dob, String fullName, int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final calendar = <Map<String, dynamic>>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final type = _classifyDay(dob, fullName, date);
      final score = _ritualScore(dob, fullName, date);
      final typeData = ritualTypes[type]!;

      calendar.add({
        'day': day,
        'date': date,
        'type': type,
        'label': typeData['label'],
        'emoji': typeData['emoji'],
        'colorHex': typeData['colorHex'],
        'score': score,
        'moonPhase': LunarEngine.phaseName(date: date),
        'moonEmoji': LunarEngine.phaseEmoji(date: date),
        'personalDay': NumerologyEngine.personalDayNumber(dob, now: date),
      });
    }

    return calendar;
  }

  /// Today's ritual suggestion with full context.
  static Map<String, dynamic> todayRitual(DateTime dob, String fullName, {DateTime? date}) {
    final dt = date ?? DateTime.now();
    final type = _classifyDay(dob, fullName, dt);
    final score = _ritualScore(dob, fullName, dt);
    final typeData = ritualTypes[type]!;
    final moonPhase = LunarEngine.phaseName(date: dt);
    final personalDay = NumerologyEngine.personalDayNumber(dob, now: dt);

    // Pick a suggestion based on the day (deterministic per day)
    final suggestions = _ritualSuggestions[type] ?? _ritualSuggestions['reflect']!;
    final suggestionIndex = (dt.year * 366 + dt.month * 31 + dt.day) % suggestions.length;
    final suggestion = suggestions[suggestionIndex];

    // Build explanation
    final explanation = _buildExplanation(type, moonPhase, personalDay);

    return {
      'type': type,
      'label': typeData['label'],
      'emoji': typeData['emoji'],
      'colorHex': typeData['colorHex'],
      'score': score,
      'suggestion': suggestion,
      'explanation': explanation,
      'moonPhase': moonPhase,
      'moonEmoji': LunarEngine.phaseEmoji(date: dt),
      'personalDay': personalDay,
      'isVoidOfCourse': LunarEngine.isVoidOfCourse(date: dt),
    };
  }

  /// Upcoming key cosmic dates from today.
  static List<Map<String, dynamic>> upcomingDates(DateTime dob, {DateTime? from}) {
    final dt = from ?? DateTime.now();
    final dates = <Map<String, dynamic>>[];

    // Next new moon
    final daysToNew = LunarEngine.daysUntilNewMoon(date: dt);
    final nextNewMoon = dt.add(Duration(days: daysToNew));
    dates.add({
      'date': nextNewMoon,
      'event': 'New Moon',
      'emoji': '🌑',
      'description': 'Perfect for new beginnings, setting intentions, and cleansing rituals.',
      'daysAway': daysToNew,
    });

    // Next full moon
    final daysToFull = LunarEngine.daysUntilFullMoon(date: dt);
    final nextFullMoon = dt.add(Duration(days: daysToFull));
    dates.add({
      'date': nextFullMoon,
      'event': 'Full Moon',
      'emoji': '🌕',
      'description': 'Peak energy for manifestation, gratitude, and deep reflection.',
      'daysAway': daysToFull,
    });

    // Next personal year change (birthday month in next year cycle)
    final nextBirthday = DateTime(
      dob.month > dt.month || (dob.month == dt.month && dob.day > dt.day)
          ? dt.year
          : dt.year + 1,
      dob.month,
      dob.day,
    );
    final daysToPersonalYear = nextBirthday.difference(dt).inDays;
    final nextPersonalYear = NumerologyEngine.personalYearNumber(dob, now: nextBirthday);
    dates.add({
      'date': nextBirthday,
      'event': 'Personal Year Change',
      'emoji': '🔮',
      'description': 'Your personal year shifts to $nextPersonalYear. New cosmic cycle begins.',
      'daysAway': daysToPersonalYear,
    });

    // Next lucky day (score > 75 within 14 days)
    for (int i = 1; i <= 14; i++) {
      final d = dt.add(Duration(days: i));
      final score = _ritualScore(dob, '', d);
      if (score >= 75) {
        dates.add({
          'date': d,
          'event': 'High Energy Day',
          'emoji': '⭐',
          'description': 'Strong cosmic alignment (score $score). Ideal for important rituals.',
          'daysAway': i,
        });
        break;
      }
    }

    // Sort by days away
    dates.sort((a, b) => (a['daysAway'] as int).compareTo(b['daysAway'] as int));

    return dates;
  }

  // ── Helper methods ──

  static String _buildExplanation(String type, String moonPhase, int personalDay) {
    final buffer = StringBuffer('Today is ideal for ');

    switch (type) {
      case 'start':
        buffer.write('starting new things. ');
        if (moonPhase.contains('Waxing')) {
          buffer.write('The $moonPhase builds momentum for fresh beginnings. ');
        } else if (moonPhase == 'New Moon') {
          buffer.write('The New Moon is the ultimate seed-planting energy. ');
        }
        buffer.write('Your personal day $personalDay ');
        if (personalDay == 1) {
          buffer.write('amplifies leadership and initiative energy.');
        } else if (personalDay == 3) {
          buffer.write('adds creative spark to new ventures.');
        } else if (personalDay == 5) {
          buffer.write('brings dynamic, adventurous energy to new starts.');
        } else {
          buffer.write('supports forward movement and growth.');
        }
        break;

      case 'end':
        buffer.write('letting go and completing cycles. ');
        if (moonPhase.contains('Waning')) {
          buffer.write('The $moonPhase supports release and closure. ');
        }
        buffer.write('Your personal day $personalDay ');
        if (personalDay == 9) {
          buffer.write('is the ultimate completion number — endings lead to new beginnings.');
        } else {
          buffer.write('aligns with wrapping up and tying loose ends.');
        }
        break;

      case 'cleanse':
        buffer.write('cleansing and clearing energy. ');
        if (moonPhase == 'New Moon') {
          buffer.write('The New Moon strips away what no longer serves you. ');
        } else if (moonPhase == 'Waning Crescent') {
          buffer.write('The Waning Crescent is nature\'s detox phase. ');
        }
        buffer.write('Your personal day $personalDay ');
        if (personalDay == 4) {
          buffer.write('supports structural clearing and reorganization.');
        } else {
          buffer.write('favors purification of mind, body, and space.');
        }
        break;

      case 'reflect':
        buffer.write('deep reflection and inner work. ');
        if (moonPhase == 'Full Moon') {
          buffer.write('The Full Moon illuminates truth and amplifies intuition. ');
        }
        buffer.write('Your personal day $personalDay ');
        if (personalDay == 7) {
          buffer.write('is the seeker\'s number — perfect for contemplation and wisdom.');
        } else {
          buffer.write('supports introspection and mindful awareness.');
        }
        break;

      default:
        buffer.write('whatever feels right. Trust your intuition today.');
    }

    return buffer.toString();
  }
}
