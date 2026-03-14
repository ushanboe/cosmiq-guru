/// Numerology Calculation Engine
/// All calculations use Pythagorean numerology system.
/// Master numbers (11, 22, 33) are preserved during reduction.
class NumerologyEngine {
  NumerologyEngine._();

  // Pythagorean letter-to-number mapping (A=1, B=2, ... I=9, J=1, ...)
  static const _letterValues = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8, 'I': 9,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'O': 6, 'P': 7, 'Q': 8, 'R': 9,
    'S': 1, 'T': 2, 'U': 3, 'V': 4, 'W': 5, 'X': 6, 'Y': 7, 'Z': 8,
  };

  static const _vowels = {'A', 'E', 'I', 'O', 'U'};

  /// Reduce a number to a single digit, preserving master numbers 11, 22, 33.
  static int _reduce(int n) {
    while (n > 9 && n != 11 && n != 22 && n != 33) {
      int sum = 0;
      int temp = n.abs();
      while (temp > 0) {
        sum += temp % 10;
        temp ~/= 10;
      }
      n = sum;
    }
    return n;
  }

  /// Sum all digits in a string of numbers, then reduce.
  static int _reduceDigitString(String digits) {
    int sum = 0;
    for (final c in digits.split('')) {
      final d = int.tryParse(c);
      if (d != null) sum += d;
    }
    return _reduce(sum);
  }

  /// Life Path Number — sum all digits of DOB (MM/DD/YYYY), reduce each group, then sum and reduce.
  /// Uses the 3-group method: reduce month, reduce day, reduce year, then sum and reduce.
  static int lifePathNumber(DateTime dob) {
    final month = _reduce(dob.month);
    final day = _reduce(dob.day);
    final year = _reduceDigitString(dob.year.toString());
    return _reduce(month + day + year);
  }

  /// Expression Number — full birth name, every letter → Pythagorean value, sum and reduce.
  static int expressionNumber(String fullName) {
    int sum = 0;
    for (final c in fullName.toUpperCase().split('')) {
      final v = _letterValues[c];
      if (v != null) sum += v;
    }
    return _reduce(sum);
  }

  /// Soul Urge Number — vowels only from full name, sum and reduce.
  static int soulUrgeNumber(String fullName) {
    int sum = 0;
    for (final c in fullName.toUpperCase().split('')) {
      if (_vowels.contains(c)) {
        final v = _letterValues[c];
        if (v != null) sum += v;
      }
    }
    return _reduce(sum);
  }

  /// Personality Number — consonants only from full name, sum and reduce.
  static int personalityNumber(String fullName) {
    int sum = 0;
    for (final c in fullName.toUpperCase().split('')) {
      if (!_vowels.contains(c) && _letterValues.containsKey(c)) {
        sum += _letterValues[c]!;
      }
    }
    return _reduce(sum);
  }

  /// Personal Year Number — birth month + birth day + current year, reduce.
  static int personalYearNumber(DateTime dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return _reduce(dob.month + dob.day + _reduceDigitString(today.year.toString()));
  }

  /// Personal Month Number — personal year + current month, reduce.
  static int personalMonthNumber(DateTime dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final py = personalYearNumber(dob, now: today);
    return _reduce(py + today.month);
  }

  /// Personal Day Number — personal month + current day, reduce.
  static int personalDayNumber(DateTime dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final pm = personalMonthNumber(dob, now: today);
    return _reduce(pm + today.day);
  }

  /// Check if a number is a master number.
  static bool isMasterNumber(int n) => n == 11 || n == 22 || n == 33;

  /// Generate a daily numerology score (0-100) based on personal day alignment.
  /// Higher score when personal day matches life path or expression number.
  static int dailyScore(DateTime dob, String fullName, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final lifePath = lifePathNumber(dob);
    final expression = expressionNumber(fullName);
    final personalDay = personalDayNumber(dob, now: today);
    final personalYear = personalYearNumber(dob, now: today);

    int score = 50; // baseline

    // Life path resonance with personal day
    if (personalDay == lifePath) {
      score += 25;
    } else if (_reduce(personalDay + lifePath) == lifePath) {
      score += 15;
    }

    // Expression harmony
    if (personalDay == _reduce(expression)) {
      score += 15;
    }

    // Master number bonus
    if (isMasterNumber(personalDay)) score += 10;

    // Personal year cycle alignment (year 1 = new beginnings, high energy)
    if (personalYear == 1 || personalYear == 9) score += 5;

    // Day-of-week numerology boost (1=Mon as action day, 5=Fri as social)
    final weekday = today.weekday;
    if (personalDay == weekday || personalDay == _reduce(weekday)) score += 5;

    return score.clamp(0, 100);
  }
}
