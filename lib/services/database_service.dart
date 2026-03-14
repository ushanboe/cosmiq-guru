import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: UserProfile
// ─────────────────────────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String fullName;
  final String dateOfBirth;
  final String birthTime;
  final String birthCity;
  final String birthCountry;
  final String timezone;
  final int archetypeId;
  final String archetypeAnswers;
  final String createdAt;
  final String updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.timezone,
    required this.archetypeId,
    required this.archetypeAnswers,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? dateOfBirth,
    String? birthTime,
    String? birthCity,
    String? birthCountry,
    String? timezone,
    int? archetypeId,
    String? archetypeAnswers,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      birthTime: birthTime ?? this.birthTime,
      birthCity: birthCity ?? this.birthCity,
      birthCountry: birthCountry ?? this.birthCountry,
      timezone: timezone ?? this.timezone,
      archetypeId: archetypeId ?? this.archetypeId,
      archetypeAnswers: archetypeAnswers ?? this.archetypeAnswers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'birth_time': birthTime,
      'birth_city': birthCity,
      'birth_country': birthCountry,
      'timezone': timezone,
      'archetype_id': archetypeId,
      'archetype_answers': archetypeAnswers,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      dateOfBirth: map['date_of_birth'] as String,
      birthTime: map['birth_time'] as String,
      birthCity: map['birth_city'] as String,
      birthCountry: map['birth_country'] as String,
      timezone: map['timezone'] as String,
      archetypeId: map['archetype_id'] as int,
      archetypeAnswers: map['archetype_answers'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      UserProfile.fromMap(json);

  @override
  String toString() =>
      'UserProfile(id: $id, fullName: $fullName, dateOfBirth: $dateOfBirth)';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: ZodiacProfile
// ─────────────────────────────────────────────────────────────────────────────

class ZodiacProfile {
  final String id;
  final String userId;
  final String sunSign;
  final String moonSign;
  final String risingSign;
  final String chineseAnimal;
  final String chineseElement;
  final String chineseYinYang;
  final String chineseInnerAnimal;
  final String chineseSecretAnimal;
  final String burmeseDay;
  final String burmeseAnimal;
  final String burmesePlanet;
  final String burmeseDirection;
  final int lifePathNumber;
  final int expressionNumber;
  final int soulUrgeNumber;
  final int personalityNumber;
  final int isMasterLifePath;
  final String createdAt;

  const ZodiacProfile({
    required this.id,
    required this.userId,
    required this.sunSign,
    required this.moonSign,
    required this.risingSign,
    required this.chineseAnimal,
    required this.chineseElement,
    required this.chineseYinYang,
    required this.chineseInnerAnimal,
    required this.chineseSecretAnimal,
    required this.burmeseDay,
    required this.burmeseAnimal,
    required this.burmesePlanet,
    required this.burmeseDirection,
    required this.lifePathNumber,
    required this.expressionNumber,
    required this.soulUrgeNumber,
    required this.personalityNumber,
    required this.isMasterLifePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'sun_sign': sunSign,
      'moon_sign': moonSign,
      'rising_sign': risingSign,
      'chinese_animal': chineseAnimal,
      'chinese_element': chineseElement,
      'chinese_yin_yang': chineseYinYang,
      'chinese_inner_animal': chineseInnerAnimal,
      'chinese_secret_animal': chineseSecretAnimal,
      'burmese_day': burmeseDay,
      'burmese_animal': burmeseAnimal,
      'burmese_planet': burmesePlanet,
      'burmese_direction': burmeseDirection,
      'life_path_number': lifePathNumber,
      'expression_number': expressionNumber,
      'soul_urge_number': soulUrgeNumber,
      'personality_number': personalityNumber,
      'is_master_life_path': isMasterLifePath,
      'created_at': createdAt,
    };
  }

  factory ZodiacProfile.fromMap(Map<String, dynamic> map) {
    return ZodiacProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sunSign: map['sun_sign'] as String,
      moonSign: map['moon_sign'] as String,
      risingSign: map['rising_sign'] as String,
      chineseAnimal: map['chinese_animal'] as String,
      chineseElement: map['chinese_element'] as String,
      chineseYinYang: map['chinese_yin_yang'] as String,
      chineseInnerAnimal: map['chinese_inner_animal'] as String,
      chineseSecretAnimal: map['chinese_secret_animal'] as String,
      burmeseDay: map['burmese_day'] as String,
      burmeseAnimal: map['burmese_animal'] as String,
      burmesePlanet: map['burmese_planet'] as String,
      burmeseDirection: map['burmese_direction'] as String,
      lifePathNumber: map['life_path_number'] as int,
      expressionNumber: map['expression_number'] as int,
      soulUrgeNumber: map['soul_urge_number'] as int,
      personalityNumber: map['personality_number'] as int,
      isMasterLifePath: map['is_master_life_path'] as int,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ZodiacProfile.fromJson(Map<String, dynamic> json) =>
      ZodiacProfile.fromMap(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: DailyReading
// ─────────────────────────────────────────────────────────────────────────────

class DailyReading {
  final String id;
  final String userId;
  final String date;
  final int compositeLuckScore;
  final int astrologyScore;
  final int numerologyScore;
  final int chineseScore;
  final int mahaboteScore;
  final int lunarScore;
  final int archetypeScore;
  final int aiModifier;
  final int relationshipEnergy;
  final int moneyEnergy;
  final int careerEnergy;
  final String bestHourStart;
  final String bestHourEnd;
  final String bestHourPlanet;
  final String luckyColor;
  final String luckyDirection;
  final String moonPhase;
  final String moonSign;
  final String dailySummary;
  final String? aiNarrative;
  final String createdAt;

  const DailyReading({
    required this.id,
    required this.userId,
    required this.date,
    required this.compositeLuckScore,
    required this.astrologyScore,
    required this.numerologyScore,
    required this.chineseScore,
    required this.mahaboteScore,
    required this.lunarScore,
    required this.archetypeScore,
    required this.aiModifier,
    required this.relationshipEnergy,
    required this.moneyEnergy,
    required this.careerEnergy,
    required this.bestHourStart,
    required this.bestHourEnd,
    required this.bestHourPlanet,
    required this.luckyColor,
    required this.luckyDirection,
    required this.moonPhase,
    required this.moonSign,
    required this.dailySummary,
    this.aiNarrative,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'composite_luck_score': compositeLuckScore,
      'astrology_score': astrologyScore,
      'numerology_score': numerologyScore,
      'chinese_score': chineseScore,
      'mahabote_score': mahaboteScore,
      'lunar_score': lunarScore,
      'archetype_score': archetypeScore,
      'ai_modifier': aiModifier,
      'relationship_energy': relationshipEnergy,
      'money_energy': moneyEnergy,
      'career_energy': careerEnergy,
      'best_hour_start': bestHourStart,
      'best_hour_end': bestHourEnd,
      'best_hour_planet': bestHourPlanet,
      'lucky_color': luckyColor,
      'lucky_direction': luckyDirection,
      'moon_phase': moonPhase,
      'moon_sign': moonSign,
      'daily_summary': dailySummary,
      'ai_narrative': aiNarrative,
      'created_at': createdAt,
    };
  }

  factory DailyReading.fromMap(Map<String, dynamic> map) {
    return DailyReading(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: map['date'] as String,
      compositeLuckScore: map['composite_luck_score'] as int,
      astrologyScore: map['astrology_score'] as int,
      numerologyScore: map['numerology_score'] as int,
      chineseScore: map['chinese_score'] as int,
      mahaboteScore: map['mahabote_score'] as int,
      lunarScore: map['lunar_score'] as int,
      archetypeScore: map['archetype_score'] as int,
      aiModifier: map['ai_modifier'] as int,
      relationshipEnergy: map['relationship_energy'] as int,
      moneyEnergy: map['money_energy'] as int,
      careerEnergy: map['career_energy'] as int,
      bestHourStart: map['best_hour_start'] as String,
      bestHourEnd: map['best_hour_end'] as String,
      bestHourPlanet: map['best_hour_planet'] as String,
      luckyColor: map['lucky_color'] as String,
      luckyDirection: map['lucky_direction'] as String,
      moonPhase: map['moon_phase'] as String,
      moonSign: map['moon_sign'] as String,
      dailySummary: map['daily_summary'] as String,
      aiNarrative: map['ai_narrative'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DailyReading.fromJson(Map<String, dynamic> json) =>
      DailyReading.fromMap(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: CompatibilityResult
// ─────────────────────────────────────────────────────────────────────────────

class CompatibilityResult {
  final String id;
  final String userId;
  final String partnerName;
  final String partnerDob;
  final String partnerBirthTime;
  final int overallScore;
  final String scoresJson;
  final String narrativeSummary;
  final String createdAt;

  const CompatibilityResult({
    required this.id,
    required this.userId,
    required this.partnerName,
    required this.partnerDob,
    required this.partnerBirthTime,
    required this.overallScore,
    required this.scoresJson,
    required this.narrativeSummary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'partner_name': partnerName,
      'partner_dob': partnerDob,
      'partner_birth_time': partnerBirthTime,
      'overall_score': overallScore,
      'scores_json': scoresJson,
      'narrative_summary': narrativeSummary,
      'created_at': createdAt,
    };
  }

  factory CompatibilityResult.fromMap(Map<String, dynamic> map) {
    return CompatibilityResult(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      partnerName: map['partner_name'] as String,
      partnerDob: map['partner_dob'] as String,
      partnerBirthTime: map['partner_birth_time'] as String,
      overallScore: map['overall_score'] as int,
      scoresJson: map['scores_json'] as String,
      narrativeSummary: map['narrative_summary'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) =>
      CompatibilityResult.fromMap(json);

  Map<String, int> get scoresMap {
    final decoded = jsonDecode(scoresJson) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: StreakRecord
// ─────────────────────────────────────────────────────────────────────────────

class StreakRecord {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final String lastOpenDate;
  final String updatedAt;

  const StreakRecord({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastOpenDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_open_date': lastOpenDate,
      'updated_at': updatedAt,
    };
  }

  factory StreakRecord.fromMap(Map<String, dynamic> map) {
    return StreakRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      lastOpenDate: map['last_open_date'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: DecisionHistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

class DecisionHistoryEntry {
  final String id;
  final String userId;
  final String decisionText;
  final String category;
  final String targetDate;
  final int score;
  final String riskLevel;
  final int luckyNumber;
  final String bestWindow;
  final String scoresJson;
  final String advice;
  final String createdAt;

  const DecisionHistoryEntry({
    required this.id,
    required this.userId,
    required this.decisionText,
    required this.category,
    required this.targetDate,
    required this.score,
    required this.riskLevel,
    required this.luckyNumber,
    required this.bestWindow,
    required this.scoresJson,
    required this.advice,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'decision_text': decisionText,
      'category': category,
      'target_date': targetDate,
      'score': score,
      'risk_level': riskLevel,
      'lucky_number': luckyNumber,
      'best_window': bestWindow,
      'scores_json': scoresJson,
      'advice': advice,
      'created_at': createdAt,
    };
  }

  factory DecisionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return DecisionHistoryEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      decisionText: map['decision_text'] as String,
      category: map['category'] as String,
      targetDate: map['target_date'] as String,
      score: map['score'] as int,
      riskLevel: map['risk_level'] as String,
      luckyNumber: map['lucky_number'] as int,
      bestWindow: map['best_window'] as String,
      scoresJson: map['scores_json'] as String,
      advice: map['advice'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DecisionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DecisionHistoryEntry.fromMap(json);

  Map<String, int> get scoresMap {
    final decoded = jsonDecode(scoresJson) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: JournalEntry
// ─────────────────────────────────────────────────────────────────────────────

class JournalEntry {
  final String id;
  final String userId;
  final String date;
  final int mood;
  final String tagsJson;
  final String? note;
  final int luckScore;
  final String moonPhase;
  final String dominantSystem;
  final String createdAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.tagsJson,
    this.note,
    required this.luckScore,
    required this.moonPhase,
    required this.dominantSystem,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'mood': mood,
      'tags_json': tagsJson,
      'note': note,
      'luck_score': luckScore,
      'moon_phase': moonPhase,
      'dominant_system': dominantSystem,
      'created_at': createdAt,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: map['date'] as String,
      mood: map['mood'] as int,
      tagsJson: map['tags_json'] as String,
      note: map['note'] as String?,
      luckScore: map['luck_score'] as int,
      moonPhase: map['moon_phase'] as String,
      dominantSystem: map['dominant_system'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  List<String> get tags {
    if (tagsJson.isEmpty || tagsJson == '[]') return [];
    final decoded = jsonDecode(tagsJson) as List<dynamic>;
    return decoded.cast<String>();
  }

  Map<String, dynamic> toJson() => toMap();

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      JournalEntry.fromMap(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE: DatabaseService
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'cosmiq_guru.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> init() async {
    await _database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        birth_time TEXT NOT NULL,
        birth_city TEXT NOT NULL,
        birth_country TEXT NOT NULL,
        timezone TEXT NOT NULL,
        archetype_id INTEGER NOT NULL DEFAULT 0,
        archetype_answers TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS zodiac_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        sun_sign TEXT NOT NULL,
        moon_sign TEXT NOT NULL,
        rising_sign TEXT NOT NULL,
        chinese_animal TEXT NOT NULL,
        chinese_element TEXT NOT NULL,
        chinese_yin_yang TEXT NOT NULL,
        chinese_inner_animal TEXT NOT NULL,
        chinese_secret_animal TEXT NOT NULL,
        burmese_day TEXT NOT NULL,
        burmese_animal TEXT NOT NULL,
        burmese_planet TEXT NOT NULL,
        burmese_direction TEXT NOT NULL,
        life_path_number INTEGER NOT NULL DEFAULT 0,
        expression_number INTEGER NOT NULL DEFAULT 0,
        soul_urge_number INTEGER NOT NULL DEFAULT 0,
        personality_number INTEGER NOT NULL DEFAULT 0,
        is_master_life_path INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_readings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        composite_luck_score INTEGER NOT NULL DEFAULT 0,
        astrology_score INTEGER NOT NULL DEFAULT 0,
        numerology_score INTEGER NOT NULL DEFAULT 0,
        chinese_score INTEGER NOT NULL DEFAULT 0,
        mahabote_score INTEGER NOT NULL DEFAULT 0,
        lunar_score INTEGER NOT NULL DEFAULT 0,
        archetype_score INTEGER NOT NULL DEFAULT 0,
        ai_modifier INTEGER NOT NULL DEFAULT 0,
        relationship_energy INTEGER NOT NULL DEFAULT 0,
        money_energy INTEGER NOT NULL DEFAULT 0,
        career_energy INTEGER NOT NULL DEFAULT 0,
        best_hour_start TEXT NOT NULL,
        best_hour_end TEXT NOT NULL,
        best_hour_planet TEXT NOT NULL,
        lucky_color TEXT NOT NULL,
        lucky_direction TEXT NOT NULL,
        moon_phase TEXT NOT NULL,
        moon_sign TEXT NOT NULL,
        daily_summary TEXT NOT NULL,
        ai_narrative TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS compatibility_results (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        partner_name TEXT NOT NULL,
        partner_dob TEXT NOT NULL,
        partner_birth_time TEXT NOT NULL,
        overall_score INTEGER NOT NULL DEFAULT 0,
        scores_json TEXT NOT NULL,
        narrative_summary TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS streak_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_open_date TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS decision_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        decision_text TEXT NOT NULL,
        category TEXT NOT NULL,
        target_date TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        risk_level TEXT NOT NULL,
        lucky_number INTEGER NOT NULL DEFAULT 0,
        best_window TEXT NOT NULL,
        scores_json TEXT NOT NULL,
        advice TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        mood INTEGER NOT NULL DEFAULT 3,
        tags_json TEXT NOT NULL DEFAULT '[]',
        note TEXT,
        luck_score INTEGER NOT NULL DEFAULT 0,
        moon_phase TEXT NOT NULL DEFAULT '',
        dominant_system TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add decision_history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS decision_history (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          decision_text TEXT NOT NULL,
          category TEXT NOT NULL,
          target_date TEXT NOT NULL,
          score INTEGER NOT NULL DEFAULT 0,
          risk_level TEXT NOT NULL,
          lucky_number INTEGER NOT NULL DEFAULT 0,
          best_window TEXT NOT NULL,
          scores_json TEXT NOT NULL,
          advice TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user_profiles (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      // v2 → v3: Add journal_entries table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          mood INTEGER NOT NULL DEFAULT 3,
          tags_json TEXT NOT NULL DEFAULT '[]',
          note TEXT,
          luck_score INTEGER NOT NULL DEFAULT 0,
          moon_phase TEXT NOT NULL DEFAULT '',
          dominant_system TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user_profiles (id)
        )
      ''');
    }
  }

  // ─────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await _database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await _database;
    final rows = await db.query(
      'user_profiles',
      limit: 1,
      orderBy: 'created_at DESC',
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await _database;
    await db.update(
      'user_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // ─────────────────────────────────────────────
  // ZODIAC PROFILE
  // ─────────────────────────────────────────────

  Future<void> saveZodiacProfile(ZodiacProfile zodiac) async {
    final db = await _database;
    await db.insert(
      'zodiac_profiles',
      zodiac.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ZodiacProfile?> getZodiacProfile(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'zodiac_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ZodiacProfile.fromMap(rows.first);
  }

  // ─────────────────────────────────────────────
  // DAILY READINGS
  // ─────────────────────────────────────────────

  Future<void> saveDailyReading(DailyReading reading) async {
    final db = await _database;
    await db.insert(
      'daily_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyReading?> getDailyReading(String userId, String date) async {
    final db = await _database;
    final rows = await db.query(
      'daily_readings',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyReading.fromMap(rows.first);
  }

  Future<List<DailyReading>> getDailyReadings(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'daily_readings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map((r) => DailyReading.fromMap(r)).toList();
  }

  // ─────────────────────────────────────────────
  // COMPATIBILITY RESULTS
  // ─────────────────────────────────────────────

  Future<void> saveCompatibilityResult(CompatibilityResult result) async {
    final db = await _database;
    await db.insert(
      'compatibility_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CompatibilityResult>> getCompatibilityResults(
      String userId) async {
    final db = await _database;
    final rows = await db.query(
      'compatibility_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => CompatibilityResult.fromMap(r)).toList();
  }

  Future<void> deleteCompatibilityResult(String id) async {
    final db = await _database;
    await db.delete(
      'compatibility_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────
  // STREAK RECORDS
  // ─────────────────────────────────────────────

  Future<StreakRecord?> getStreakRecord(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'streak_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StreakRecord.fromMap(rows.first);
  }

  Future<void> saveStreakRecord(StreakRecord record) async {
    final db = await _database;
    await db.insert(
      'streak_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────
  // DECISION HISTORY
  // ─────────────────────────────────────────────

  Future<void> saveDecisionHistory(DecisionHistoryEntry entry) async {
    final db = await _database;
    await db.insert(
      'decision_history',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DecisionHistoryEntry>> getDecisionHistory(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'decision_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => DecisionHistoryEntry.fromMap(r)).toList();
  }

  Future<void> deleteDecisionHistory(String id) async {
    final db = await _database;
    await db.delete(
      'decision_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────
  // JOURNAL ENTRIES
  // ─────────────────────────────────────────────

  Future<void> saveJournalEntry(JournalEntry entry) async {
    final db = await _database;
    await db.insert(
      'journal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<JournalEntry?> getJournalEntry(String userId, String date) async {
    final db = await _database;
    final rows = await db.query(
      'journal_entries',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return JournalEntry.fromMap(rows.first);
  }

  Future<List<JournalEntry>> getJournalEntries(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<List<JournalEntry>> getJournalEntriesRange(
      String userId, String startDate, String endDate) async {
    final db = await _database;
    final rows = await db.query(
      'journal_entries',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await _database;
    await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────
  // CLEAR ALL DATA
  // ─────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('user_profiles');
    await db.delete('zodiac_profiles');
    await db.delete('daily_readings');
    await db.delete('compatibility_results');
    await db.delete('app_settings');
    await db.delete('streak_records');
    await db.delete('decision_history');
    try { await db.delete('journal_entries'); } catch (_) {}
  }
}
