/// Name Numerology Engine
/// Scores names for cosmic alignment, generates baby name suggestions,
/// and evaluates business names with launch timing.
import 'package:cosmiq_guru/engines/numerology_engine.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';

class NameEngine {
  NameEngine._();

  /// Baby name database — ~200 names across cultures with meanings.
  static const _babyNames = {
    'male': [
      {'name': 'Alexander', 'meaning': 'Defender of the people', 'origin': 'Greek'},
      {'name': 'Benjamin', 'meaning': 'Son of the right hand', 'origin': 'Hebrew'},
      {'name': 'Caleb', 'meaning': 'Faithful, devoted', 'origin': 'Hebrew'},
      {'name': 'Daniel', 'meaning': 'God is my judge', 'origin': 'Hebrew'},
      {'name': 'Ethan', 'meaning': 'Strong, firm', 'origin': 'Hebrew'},
      {'name': 'Felix', 'meaning': 'Lucky, fortunate', 'origin': 'Latin'},
      {'name': 'Gabriel', 'meaning': 'God is my strength', 'origin': 'Hebrew'},
      {'name': 'Henry', 'meaning': 'Ruler of the home', 'origin': 'Germanic'},
      {'name': 'Isaac', 'meaning': 'He will laugh', 'origin': 'Hebrew'},
      {'name': 'James', 'meaning': 'Supplanter', 'origin': 'Hebrew'},
      {'name': 'Kai', 'meaning': 'Sea, ocean', 'origin': 'Hawaiian'},
      {'name': 'Leo', 'meaning': 'Lion', 'origin': 'Latin'},
      {'name': 'Marcus', 'meaning': 'Warlike, dedicated to Mars', 'origin': 'Latin'},
      {'name': 'Nathan', 'meaning': 'He gave', 'origin': 'Hebrew'},
      {'name': 'Oliver', 'meaning': 'Olive tree', 'origin': 'Latin'},
      {'name': 'Patrick', 'meaning': 'Nobleman', 'origin': 'Latin'},
      {'name': 'Quinn', 'meaning': 'Wise, intelligent', 'origin': 'Irish'},
      {'name': 'Ryan', 'meaning': 'Little king', 'origin': 'Irish'},
      {'name': 'Samuel', 'meaning': 'God has heard', 'origin': 'Hebrew'},
      {'name': 'Theodore', 'meaning': 'Gift of God', 'origin': 'Greek'},
      {'name': 'Aiden', 'meaning': 'Little fire', 'origin': 'Irish'},
      {'name': 'Sebastian', 'meaning': 'Venerable, revered', 'origin': 'Greek'},
      {'name': 'Lucas', 'meaning': 'Light, luminous', 'origin': 'Latin'},
      {'name': 'Noah', 'meaning': 'Rest, comfort', 'origin': 'Hebrew'},
      {'name': 'Liam', 'meaning': 'Strong-willed warrior', 'origin': 'Irish'},
      {'name': 'Ravi', 'meaning': 'Sun', 'origin': 'Sanskrit'},
      {'name': 'Arjun', 'meaning': 'Bright, shining', 'origin': 'Sanskrit'},
      {'name': 'Hiroshi', 'meaning': 'Generous, prosperous', 'origin': 'Japanese'},
      {'name': 'Mateo', 'meaning': 'Gift of God', 'origin': 'Spanish'},
      {'name': 'Omar', 'meaning': 'Flourishing, long-lived', 'origin': 'Arabic'},
      {'name': 'Yusuf', 'meaning': 'God increases', 'origin': 'Arabic'},
      {'name': 'Luca', 'meaning': 'Bringer of light', 'origin': 'Italian'},
      {'name': 'Hugo', 'meaning': 'Mind, intellect', 'origin': 'Germanic'},
      {'name': 'Axel', 'meaning': 'Father of peace', 'origin': 'Scandinavian'},
      {'name': 'Milan', 'meaning': 'Gracious, dear', 'origin': 'Slavic'},
      {'name': 'Zane', 'meaning': 'God is gracious', 'origin': 'Hebrew'},
      {'name': 'Dante', 'meaning': 'Enduring', 'origin': 'Italian'},
      {'name': 'Cyrus', 'meaning': 'Sun, throne', 'origin': 'Persian'},
      {'name': 'Jasper', 'meaning': 'Treasurer', 'origin': 'Persian'},
      {'name': 'Atlas', 'meaning': 'Bearer of the heavens', 'origin': 'Greek'},
      {'name': 'Rowan', 'meaning': 'Red-haired, little red one', 'origin': 'Irish'},
      {'name': 'Arlo', 'meaning': 'Fortified hill', 'origin': 'English'},
      {'name': 'Bodhi', 'meaning': 'Awakening, enlightenment', 'origin': 'Sanskrit'},
      {'name': 'Callum', 'meaning': 'Dove', 'origin': 'Scottish'},
      {'name': 'Declan', 'meaning': 'Full of goodness', 'origin': 'Irish'},
      {'name': 'Ezra', 'meaning': 'Helper', 'origin': 'Hebrew'},
      {'name': 'Finn', 'meaning': 'Fair, white', 'origin': 'Irish'},
      {'name': 'Gideon', 'meaning': 'Mighty warrior', 'origin': 'Hebrew'},
      {'name': 'Hector', 'meaning': 'Holding fast', 'origin': 'Greek'},
      {'name': 'Ivan', 'meaning': 'God is gracious', 'origin': 'Slavic'},
    ],
    'female': [
      {'name': 'Amara', 'meaning': 'Grace, eternal', 'origin': 'African'},
      {'name': 'Beatrice', 'meaning': 'She who brings happiness', 'origin': 'Latin'},
      {'name': 'Charlotte', 'meaning': 'Free woman', 'origin': 'French'},
      {'name': 'Diana', 'meaning': 'Divine, heavenly', 'origin': 'Latin'},
      {'name': 'Eleanor', 'meaning': 'Bright, shining one', 'origin': 'Greek'},
      {'name': 'Freya', 'meaning': 'Noble woman', 'origin': 'Norse'},
      {'name': 'Grace', 'meaning': 'Grace of God', 'origin': 'Latin'},
      {'name': 'Helena', 'meaning': 'Bright, shining light', 'origin': 'Greek'},
      {'name': 'Iris', 'meaning': 'Rainbow', 'origin': 'Greek'},
      {'name': 'Julia', 'meaning': 'Youthful', 'origin': 'Latin'},
      {'name': 'Kira', 'meaning': 'Beam of light', 'origin': 'Russian'},
      {'name': 'Luna', 'meaning': 'Moon', 'origin': 'Latin'},
      {'name': 'Maya', 'meaning': 'Illusion, dream', 'origin': 'Sanskrit'},
      {'name': 'Nadia', 'meaning': 'Hope', 'origin': 'Slavic'},
      {'name': 'Olivia', 'meaning': 'Olive tree', 'origin': 'Latin'},
      {'name': 'Penelope', 'meaning': 'Weaver', 'origin': 'Greek'},
      {'name': 'Rose', 'meaning': 'Rose flower', 'origin': 'Latin'},
      {'name': 'Sophia', 'meaning': 'Wisdom', 'origin': 'Greek'},
      {'name': 'Thea', 'meaning': 'Goddess, divine', 'origin': 'Greek'},
      {'name': 'Uma', 'meaning': 'Nation, splendor', 'origin': 'Sanskrit'},
      {'name': 'Violet', 'meaning': 'Purple flower', 'origin': 'Latin'},
      {'name': 'Willow', 'meaning': 'Willow tree', 'origin': 'English'},
      {'name': 'Aurora', 'meaning': 'Dawn', 'origin': 'Latin'},
      {'name': 'Zara', 'meaning': 'Princess, blooming flower', 'origin': 'Arabic'},
      {'name': 'Aria', 'meaning': 'Air, melody', 'origin': 'Italian'},
      {'name': 'Priya', 'meaning': 'Beloved', 'origin': 'Sanskrit'},
      {'name': 'Sakura', 'meaning': 'Cherry blossom', 'origin': 'Japanese'},
      {'name': 'Leila', 'meaning': 'Night', 'origin': 'Arabic'},
      {'name': 'Isla', 'meaning': 'Island', 'origin': 'Scottish'},
      {'name': 'Clara', 'meaning': 'Bright, clear', 'origin': 'Latin'},
      {'name': 'Emilia', 'meaning': 'Rival, eager', 'origin': 'Latin'},
      {'name': 'Chloe', 'meaning': 'Blooming, verdant', 'origin': 'Greek'},
      {'name': 'Stella', 'meaning': 'Star', 'origin': 'Latin'},
      {'name': 'Ivy', 'meaning': 'Faithfulness', 'origin': 'English'},
      {'name': 'Athena', 'meaning': 'Goddess of wisdom', 'origin': 'Greek'},
      {'name': 'Elara', 'meaning': 'Bright, shining', 'origin': 'Greek'},
      {'name': 'Celeste', 'meaning': 'Heavenly', 'origin': 'Latin'},
      {'name': 'Mila', 'meaning': 'Gracious, dear', 'origin': 'Slavic'},
      {'name': 'Sienna', 'meaning': 'Reddish-brown', 'origin': 'Italian'},
      {'name': 'Nova', 'meaning': 'New star', 'origin': 'Latin'},
      {'name': 'Jade', 'meaning': 'Precious stone', 'origin': 'Spanish'},
      {'name': 'Lyra', 'meaning': 'Lyre, harp', 'origin': 'Greek'},
      {'name': 'Esme', 'meaning': 'Esteemed, beloved', 'origin': 'French'},
      {'name': 'Dahlia', 'meaning': 'Valley flower', 'origin': 'Scandinavian'},
      {'name': 'Bianca', 'meaning': 'White, pure', 'origin': 'Italian'},
      {'name': 'Anaya', 'meaning': 'God answered', 'origin': 'Hebrew'},
      {'name': 'Cora', 'meaning': 'Maiden', 'origin': 'Greek'},
      {'name': 'Daphne', 'meaning': 'Laurel tree', 'origin': 'Greek'},
      {'name': 'Eloise', 'meaning': 'Healthy, wide', 'origin': 'French'},
      {'name': 'Fiona', 'meaning': 'Fair, white', 'origin': 'Irish'},
    ],
    'neutral': [
      {'name': 'Avery', 'meaning': 'Ruler of elves', 'origin': 'English'},
      {'name': 'Blake', 'meaning': 'Dark, fair', 'origin': 'English'},
      {'name': 'Casey', 'meaning': 'Brave in battle', 'origin': 'Irish'},
      {'name': 'Dakota', 'meaning': 'Friend, ally', 'origin': 'Native American'},
      {'name': 'Eden', 'meaning': 'Paradise, delight', 'origin': 'Hebrew'},
      {'name': 'Finley', 'meaning': 'Fair-haired hero', 'origin': 'Irish'},
      {'name': 'Harper', 'meaning': 'Harp player', 'origin': 'English'},
      {'name': 'Jordan', 'meaning': 'Flowing down', 'origin': 'Hebrew'},
      {'name': 'Morgan', 'meaning': 'Sea circle', 'origin': 'Welsh'},
      {'name': 'Phoenix', 'meaning': 'Dark red, reborn', 'origin': 'Greek'},
      {'name': 'Quinn', 'meaning': 'Wise, intelligent', 'origin': 'Irish'},
      {'name': 'Riley', 'meaning': 'Courageous', 'origin': 'Irish'},
      {'name': 'Sage', 'meaning': 'Wise one', 'origin': 'Latin'},
      {'name': 'Taylor', 'meaning': 'Tailor', 'origin': 'English'},
      {'name': 'River', 'meaning': 'Flowing body of water', 'origin': 'English'},
      {'name': 'Skyler', 'meaning': 'Scholar, eternal life', 'origin': 'Dutch'},
      {'name': 'Reese', 'meaning': 'Ardent, fiery', 'origin': 'Welsh'},
      {'name': 'Rowan', 'meaning': 'Red-haired', 'origin': 'Irish'},
      {'name': 'Indigo', 'meaning': 'Indian dye, deep blue', 'origin': 'Greek'},
      {'name': 'Wren', 'meaning': 'Small bird', 'origin': 'English'},
    ],
  };

  /// Score a name's numerological alignment with a person's life path.
  /// Returns: score (0-100), expressionNumber, soulUrge, personality, compatibility text.
  static Map<String, dynamic> scoreName(String name, int lifePathNumber) {
    if (name.trim().isEmpty) {
      return {
        'score': 0,
        'expressionNumber': 0,
        'soulUrge': 0,
        'personality': 0,
        'compatibility': 'Enter a name to score.',
      };
    }

    final expression = NumerologyEngine.expressionNumber(name);
    final soulUrge = NumerologyEngine.soulUrgeNumber(name);
    final personality = NumerologyEngine.personalityNumber(name);

    int score = 50;

    // Direct match with life path — strongest alignment
    if (expression == lifePathNumber) score += 25;
    else if (_reduce(expression + lifePathNumber) == lifePathNumber) score += 15;
    else if (_harmonious(expression, lifePathNumber)) score += 10;

    // Soul urge resonance
    if (soulUrge == lifePathNumber) score += 12;
    else if (_harmonious(soulUrge, lifePathNumber)) score += 6;

    // Personality alignment
    if (personality == lifePathNumber) score += 8;
    else if (_harmonious(personality, lifePathNumber)) score += 4;

    // Master number bonuses
    if (NumerologyEngine.isMasterNumber(expression)) score += 5;
    if (NumerologyEngine.isMasterNumber(soulUrge)) score += 3;

    // Name length harmony (names with letter count reducing to life path)
    final letterCount = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (_reduce(letterCount) == lifePathNumber) score += 5;

    score = score.clamp(0, 100);

    final compatibility = _buildNameCompatibility(name, expression, lifePathNumber, score);

    return {
      'score': score,
      'expressionNumber': expression,
      'soulUrge': soulUrge,
      'personality': personality,
      'compatibility': compatibility,
    };
  }

  /// Generate ranked baby name suggestions based on parent compatibility.
  /// [gender]: 'male', 'female', or 'neutral' (null = all)
  /// [origin]: filter by origin (null = all)
  static List<Map<String, dynamic>> generateBabyNames({
    required String surname,
    required DateTime parentDob1,
    DateTime? parentDob2,
    String? gender,
    String? origin,
  }) {
    final parentLP1 = NumerologyEngine.lifePathNumber(parentDob1);
    final parentLP2 = parentDob2 != null
        ? NumerologyEngine.lifePathNumber(parentDob2)
        : parentLP1;
    final combinedLP = _reduce(parentLP1 + parentLP2);

    // Collect candidate names
    final candidates = <Map<String, dynamic>>[];
    final genderKeys = gender != null && _babyNames.containsKey(gender)
        ? [gender]
        : ['male', 'female', 'neutral'];

    for (final gKey in genderKeys) {
      final names = _babyNames[gKey];
      if (names == null) continue;
      for (final entry in names) {
        final nameOrigin = entry['origin'] as String? ?? '';
        if (origin != null && origin.isNotEmpty &&
            !nameOrigin.toLowerCase().contains(origin.toLowerCase())) {
          continue;
        }
        candidates.add({...entry, 'gender': gKey});
      }
    }

    // Score each candidate
    final scored = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      final firstName = candidate['name'] as String;
      final fullName = '$firstName $surname';
      final result = scoreName(fullName, combinedLP);
      scored.add({
        ...candidate,
        'fullName': fullName,
        'score': result['score'],
        'expressionNumber': result['expressionNumber'],
        'soulUrge': result['soulUrge'],
        'compatibility': result['compatibility'],
      });
    }

    // Sort by score descending
    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return scored.take(20).toList();
  }

  /// Score a business name for cosmic alignment with the owner.
  /// Returns: score, expressionNumber, luckyLaunchDays, luckyPricing, advice.
  static Map<String, dynamic> scoreBusinessName({
    required String businessName,
    required DateTime ownerDob,
    required String ownerName,
  }) {
    if (businessName.trim().isEmpty) {
      return {
        'score': 0,
        'expressionNumber': 0,
        'luckyLaunchDays': <Map<String, dynamic>>[],
        'luckyPricing': <int>[],
        'advice': 'Enter a business name to score.',
      };
    }

    final ownerLP = NumerologyEngine.lifePathNumber(ownerDob);
    final ownerExpr = NumerologyEngine.expressionNumber(ownerName);
    final bizExpr = NumerologyEngine.expressionNumber(businessName);
    final bizSoul = NumerologyEngine.soulUrgeNumber(businessName);

    int score = 50;

    // Business expression alignment with owner life path
    if (bizExpr == ownerLP) score += 20;
    else if (_harmonious(bizExpr, ownerLP)) score += 10;
    else if (_reduce(bizExpr + ownerLP) == 8) score += 12; // 8 = money

    // Business expression alignment with owner expression
    if (bizExpr == ownerExpr) score += 12;
    else if (_harmonious(bizExpr, ownerExpr)) score += 6;

    // Business soul urge — what the business "wants"
    if (bizSoul == 8 || bizSoul == 1) score += 8; // Money/leadership energy
    if (bizSoul == ownerLP) score += 5;

    // Power numbers for business (1, 8, 9 are strong)
    if (bizExpr == 1 || bizExpr == 8 || bizExpr == 9) score += 5;

    // Master number bonus
    if (NumerologyEngine.isMasterNumber(bizExpr)) score += 8;

    score = score.clamp(0, 100);

    // Lucky launch days — next 30 days where personal day aligns
    final launchDays = _findLuckyLaunchDays(ownerDob, bizExpr);

    // Lucky pricing numbers
    final pricing = _generateLuckyPricing(bizExpr, ownerLP);

    // Build advice
    final advice = _buildBusinessAdvice(businessName, bizExpr, ownerLP, score);

    return {
      'score': score,
      'expressionNumber': bizExpr,
      'soulUrge': bizSoul,
      'ownerLifePath': ownerLP,
      'luckyLaunchDays': launchDays,
      'luckyPricing': pricing,
      'advice': advice,
    };
  }

  // ── Helpers ──

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

  /// Check if two numbers are harmonious in numerology.
  static bool _harmonious(int a, int b) {
    // Same number
    if (a == b) return true;
    // Complementary pairs
    const pairs = [
      {1, 9}, {2, 7}, {3, 6}, {4, 8},
      {1, 5}, {2, 4}, {3, 9}, {6, 9}, {1, 3},
    ];
    final set = {a, b};
    return pairs.any((p) => p.containsAll(set));
  }

  static String _buildNameCompatibility(String name, int expr, int lifePath, int score) {
    final buf = StringBuffer();
    if (score >= 80) {
      buf.write('Exceptional cosmic alignment! ');
    } else if (score >= 65) {
      buf.write('Strong cosmic harmony. ');
    } else if (score >= 50) {
      buf.write('Balanced energy. ');
    } else {
      buf.write('Growth-oriented vibration. ');
    }

    buf.write('The name "$name" carries expression number $expr');
    if (expr == lifePath) {
      buf.write(', which perfectly mirrors your life path $lifePath — a powerful resonance.');
    } else if (_harmonious(expr, lifePath)) {
      buf.write(', which harmonizes beautifully with your life path $lifePath.');
    } else {
      buf.write('. Combined with your life path $lifePath, it creates a dynamic of complementary energies.');
    }
    return buf.toString();
  }

  static List<Map<String, dynamic>> _findLuckyLaunchDays(DateTime ownerDob, int bizExpr) {
    final today = DateTime.now();
    final days = <Map<String, dynamic>>[];

    for (int i = 1; i <= 30; i++) {
      final date = today.add(Duration(days: i));
      final personalDay = NumerologyEngine.personalDayNumber(ownerDob, now: date);
      final isVoc = LunarEngine.isVoidOfCourse(date: date);
      final moonPhase = LunarEngine.phaseName(date: date);

      // Score the day for business launching
      int dayScore = 50;
      if (personalDay == bizExpr) dayScore += 20;
      if (personalDay == 1) dayScore += 15; // New beginnings
      if (personalDay == 8) dayScore += 12; // Money/business
      if (personalDay == 3) dayScore += 8; // Creative energy
      if (_harmonious(personalDay, bizExpr)) dayScore += 10;
      if (moonPhase.contains('Waxing') || moonPhase == 'New Moon') dayScore += 10;
      if (moonPhase == 'Full Moon') dayScore += 5;
      if (isVoc) dayScore -= 15;

      // Weekday bonus (Tuesday=Mars=action, Thursday=Jupiter=expansion)
      if (date.weekday == 2 || date.weekday == 4) dayScore += 5;

      dayScore = dayScore.clamp(0, 100);

      if (dayScore >= 70) {
        days.add({
          'date': date,
          'score': dayScore,
          'personalDay': personalDay,
          'moonPhase': moonPhase,
          'moonEmoji': LunarEngine.phaseEmoji(date: date),
          'reason': _launchDayReason(personalDay, moonPhase, bizExpr),
        });
      }
    }

    days.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return days.take(5).toList();
  }

  static String _launchDayReason(int personalDay, String moonPhase, int bizExpr) {
    final reasons = <String>[];
    if (personalDay == 1) reasons.add('Day of new beginnings');
    if (personalDay == 8) reasons.add('Strong business energy');
    if (personalDay == bizExpr) reasons.add('Aligned with business vibration');
    if (moonPhase.contains('Waxing')) reasons.add('$moonPhase builds momentum');
    if (moonPhase == 'New Moon') reasons.add('New Moon — ideal for launches');
    return reasons.isNotEmpty ? reasons.join('. ') : 'Favorable cosmic alignment';
  }

  static List<int> _generateLuckyPricing(int bizExpr, int ownerLP) {
    // Generate pricing numbers that reduce to lucky numbers
    final luckyDigits = {bizExpr, ownerLP, 8, 9}; // 8=money, 9=completion
    final prices = <int>[];

    // Common price points that reduce to lucky numbers
    for (final base in [9, 19, 29, 39, 49, 59, 69, 79, 89, 99, 149, 199, 249, 299, 399, 499]) {
      if (luckyDigits.contains(_reduce(base))) {
        prices.add(base);
      }
    }

    // If not enough, add multiples of the business expression
    if (prices.length < 5) {
      for (int mult = 1; mult <= 20; mult++) {
        final p = bizExpr * mult;
        if (p > 0 && p < 1000 && !prices.contains(p)) {
          prices.add(p);
          if (prices.length >= 8) break;
        }
      }
    }

    prices.sort();
    return prices.take(8).toList();
  }

  static String _buildBusinessAdvice(String name, int bizExpr, int ownerLP, int score) {
    final buf = StringBuffer();

    if (score >= 80) {
      buf.write('Excellent choice! "$name" vibrates at expression $bizExpr, ');
    } else if (score >= 65) {
      buf.write('"$name" carries solid business energy at expression $bizExpr, ');
    } else {
      buf.write('"$name" has expression number $bizExpr, ');
    }

    switch (bizExpr) {
      case 1:
        buf.write('the number of leadership and innovation. This name commands attention and projects authority.');
        break;
      case 2:
        buf.write('the number of partnership and diplomacy. This name attracts collaboration and harmonious deals.');
        break;
      case 3:
        buf.write('the number of creativity and communication. This name excels in marketing and brand recognition.');
        break;
      case 4:
        buf.write('the number of stability and structure. This name projects reliability and trustworthiness.');
        break;
      case 5:
        buf.write('the number of change and adaptability. This name suits dynamic, fast-moving ventures.');
        break;
      case 6:
        buf.write('the number of responsibility and service. This name attracts loyal customers and community.');
        break;
      case 7:
        buf.write('the number of analysis and expertise. This name positions you as an authority in your field.');
        break;
      case 8:
        buf.write('the ultimate money number! This name naturally attracts abundance and financial success.');
        break;
      case 9:
        buf.write('the number of completion and global reach. This name has potential for international success.');
        break;
      default:
        if (NumerologyEngine.isMasterNumber(bizExpr)) {
          buf.write('a master number ($bizExpr)! This carries exceptional vibrational power for visionary businesses.');
        } else {
          buf.write('carrying unique energy for your venture.');
        }
    }

    if (bizExpr == ownerLP) {
      buf.write(' Your life path $ownerLP perfectly matches — this name was cosmically meant for you.');
    } else if (_harmonious(bizExpr, ownerLP)) {
      buf.write(' The harmony with your life path $ownerLP amplifies your natural strengths.');
    }

    return buf.toString();
  }
}
