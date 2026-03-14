/// Chinese Zodiac Calculation Engine
/// Based on the traditional Chinese lunisolar calendar cycle.
class ChineseZodiacEngine {
  ChineseZodiacEngine._();

  static const animals = [
    'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
    'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
  ];

  static const animalEmojis = [
    '🐀', '🐂', '🐅', '🐇', '🐉', '🐍',
    '🐎', '🐐', '🐒', '🐓', '🐕', '🐖',
  ];

  static const elements = ['Wood', 'Fire', 'Earth', 'Metal', 'Water'];

  static const elementColors = {
    'Wood': 0xFF22C55E,
    'Fire': 0xFFEF4444,
    'Earth': 0xFFF59E0B,
    'Metal': 0xFFC0C0C0,
    'Water': 0xFF3B82F6,
  };

  // Trine groups — animals with natural affinity
  static const trineGroups = {
    1: ['Rat', 'Dragon', 'Monkey'],     // First Trine — innovators
    2: ['Ox', 'Snake', 'Rooster'],      // Second Trine — thinkers
    3: ['Tiger', 'Horse', 'Dog'],       // Third Trine — protectors
    4: ['Rabbit', 'Goat', 'Pig'],       // Fourth Trine — peacemakers
  };

  // Compatibility: best friend pairs (secret friends)
  static const secretFriends = {
    'Rat': 'Ox', 'Ox': 'Rat',
    'Tiger': 'Pig', 'Pig': 'Tiger',
    'Rabbit': 'Dog', 'Dog': 'Rabbit',
    'Dragon': 'Rooster', 'Rooster': 'Dragon',
    'Snake': 'Monkey', 'Monkey': 'Snake',
    'Horse': 'Goat', 'Goat': 'Horse',
  };

  // Clash pairs (least compatible)
  static const clashPairs = {
    'Rat': 'Horse', 'Horse': 'Rat',
    'Ox': 'Goat', 'Goat': 'Ox',
    'Tiger': 'Monkey', 'Monkey': 'Tiger',
    'Rabbit': 'Rooster', 'Rooster': 'Rabbit',
    'Dragon': 'Dog', 'Dog': 'Dragon',
    'Snake': 'Pig', 'Pig': 'Snake',
  };

  // Inner animal (from birth month — Chinese lunar month approximation)
  static const monthAnimals = [
    'Ox',      // Jan (approx 12th lunar month)
    'Tiger',   // Feb (1st lunar month)
    'Rabbit',  // Mar
    'Dragon',  // Apr
    'Snake',   // May
    'Horse',   // Jun
    'Goat',    // Jul
    'Monkey',  // Aug
    'Rooster', // Sep
    'Dog',     // Oct
    'Pig',     // Nov
    'Rat',     // Dec
  ];

  // Secret animal (from birth hour — 2-hour blocks starting at 11pm)
  // Hour 0-1 = Rat, 1-3 = Ox, 3-5 = Tiger, etc.
  static const hourAnimals = [
    'Rat',     // 23:00 - 00:59
    'Ox',      // 01:00 - 02:59
    'Tiger',   // 03:00 - 04:59
    'Rabbit',  // 05:00 - 06:59
    'Dragon',  // 07:00 - 08:59
    'Snake',   // 09:00 - 10:59
    'Horse',   // 11:00 - 12:59
    'Goat',    // 13:00 - 14:59
    'Monkey',  // 15:00 - 16:59
    'Rooster', // 17:00 - 18:59
    'Dog',     // 19:00 - 20:59
    'Pig',     // 21:00 - 22:59
  ];

  static const luckyDirections = {
    'Rat': 'North', 'Ox': 'North-East', 'Tiger': 'North-East',
    'Rabbit': 'East', 'Dragon': 'South-East', 'Snake': 'South-East',
    'Horse': 'South', 'Goat': 'South-West', 'Monkey': 'South-West',
    'Rooster': 'West', 'Dog': 'North-West', 'Pig': 'North-West',
  };

  /// Get the zodiac animal index for a given year.
  /// The cycle starts with Rat at year 4 AD.
  static int _animalIndex(int year) => (year - 4) % 12;

  /// Get the zodiac animal for a given year.
  static String animal(int year) => animals[_animalIndex(year)];

  /// Get the emoji for a given year's animal.
  static String animalEmoji(int year) => animalEmojis[_animalIndex(year)];

  /// Get the element for a given year (10-year cycle, each element covers 2 years).
  static String element(int year) => elements[((year - 4) % 10) ~/ 2];

  /// Get Yin (odd year) or Yang (even year).
  static String yinYang(int year) => year % 2 == 0 ? 'Yang' : 'Yin';

  /// Get inner animal from birth month (1-12).
  static String innerAnimal(int month) => monthAnimals[(month - 1) % 12];

  /// Get secret animal from birth hour (0-23).
  static String secretAnimal(int hour) {
    // Shift by 1 because Rat hour starts at 23:00
    final idx = ((hour + 1) % 24) ~/ 2;
    return hourAnimals[idx % 12];
  }

  /// Get the trine group number (1-4) for an animal.
  static int trineGroup(String animalName) {
    for (final entry in trineGroups.entries) {
      if (entry.value.contains(animalName)) return entry.key;
    }
    return 1;
  }

  /// Get trine group name.
  static String trineGroupName(int group) {
    const names = {
      1: 'First Trine — Innovators',
      2: 'Second Trine — Thinkers',
      3: 'Third Trine — Protectors',
      4: 'Fourth Trine — Peacemakers',
    };
    return names[group] ?? 'Unknown';
  }

  /// Get compatible animals (same trine + secret friend).
  static List<String> compatibleAnimals(String animalName) {
    final trine = trineGroup(animalName);
    final friends = List<String>.from(trineGroups[trine] ?? []);
    friends.remove(animalName);
    final secret = secretFriends[animalName];
    if (secret != null && !friends.contains(secret)) friends.add(secret);
    return friends;
  }

  /// Get incompatible animals (clash + harm).
  static List<String> incompatibleAnimals(String animalName) {
    final clash = clashPairs[animalName];
    return clash != null ? [clash] : [];
  }

  /// Full profile for a given birth year, month, and hour.
  static Map<String, dynamic> profile(int year, int month, int hour) {
    final a = animal(year);
    final e = element(year);
    final yy = yinYang(year);
    final inner = innerAnimal(month);
    final secret = secretAnimal(hour);
    final tg = trineGroup(a);

    return {
      'animal': a,
      'emoji': animalEmoji(year),
      'element': e,
      'elementColor': elementColors[e] ?? 0xFFFFFFFF,
      'yinYang': yy,
      'innerAnimal': inner,
      'innerAnimalEmoji': animalEmojis[animals.indexOf(inner)],
      'secretAnimal': secret,
      'secretAnimalEmoji': animalEmojis[animals.indexOf(secret)],
      'trineGroup': tg,
      'trineGroupName': trineGroupName(tg),
      'trineAnimals': trineGroups[tg],
      'compatibleAnimals': compatibleAnimals(a),
      'incompatibleAnimals': incompatibleAnimals(a),
      'luckyDirection': luckyDirections[a] ?? 'North',
      'yearDescription': '$e $a ($year)',
    };
  }

  /// Daily score based on current year animal interaction with birth animal.
  static int dailyScore(int birthYear, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final birthAnimal = animal(birthYear);
    final yearAnimal = animal(today.year);
    final monthAnimal = monthAnimals[(today.month - 1) % 12];

    int score = 55; // baseline

    // Same trine as year animal = good year
    if (trineGroup(birthAnimal) == trineGroup(yearAnimal)) score += 20;

    // Clash with year animal = challenging year
    if (clashPairs[birthAnimal] == yearAnimal) score -= 20;

    // Secret friend with year animal
    if (secretFriends[birthAnimal] == yearAnimal) score += 15;

    // Monthly animal harmony
    if (trineGroup(birthAnimal) == trineGroup(monthAnimal)) score += 10;

    // Own year (Fan Tai Sui) — mixed energy
    if (birthAnimal == yearAnimal) score -= 5;

    return score.clamp(0, 100);
  }
}
