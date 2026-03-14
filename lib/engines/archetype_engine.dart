/// Jungian Archetype Calculation Engine
/// Maps personality questionnaire answers to 12 archetypes.
import 'dart:convert';

class ArchetypeEngine {
  ArchetypeEngine._();

  static const archetypes = [
    {'id': 0,  'name': 'The Hero',       'emoji': '⚔️', 'motto': 'Where there\'s a will, there\'s a way'},
    {'id': 1,  'name': 'The Sage',       'emoji': '📚', 'motto': 'The truth will set you free'},
    {'id': 2,  'name': 'The Explorer',   'emoji': '🧭', 'motto': 'Don\'t fence me in'},
    {'id': 3,  'name': 'The Outlaw',     'emoji': '🔥', 'motto': 'Rules are made to be broken'},
    {'id': 4,  'name': 'The Magician',   'emoji': '✨', 'motto': 'I make things happen'},
    {'id': 5,  'name': 'The Innocent',   'emoji': '🕊️', 'motto': 'Free to be you and me'},
    {'id': 6,  'name': 'The Creator',    'emoji': '🎨', 'motto': 'If you can imagine it, it can be done'},
    {'id': 7,  'name': 'The Ruler',      'emoji': '👑', 'motto': 'Power isn\'t everything, it\'s the only thing'},
    {'id': 8,  'name': 'The Caregiver',  'emoji': '💝', 'motto': 'Love your neighbor as yourself'},
    {'id': 9,  'name': 'The Lover',      'emoji': '❤️', 'motto': 'You\'re the only one'},
    {'id': 10, 'name': 'The Jester',     'emoji': '🃏', 'motto': 'You only live once'},
    {'id': 11, 'name': 'The Everyman',   'emoji': '🤝', 'motto': 'All people are created equal'},
  ];

  // 12 questions, each with 4 options mapping to different archetypes.
  // Each option is [optionText, archetypeIndex1, archetypeIndex2]
  static const questions = [
    {
      'question': 'When facing a difficult challenge, you tend to:',
      'options': [
        {'text': 'Fight through it with determination', 'archetypes': [0, 7]},   // Hero, Ruler
        {'text': 'Research and analyze before acting', 'archetypes': [1, 4]},     // Sage, Magician
        {'text': 'Find a creative workaround', 'archetypes': [6, 3]},            // Creator, Outlaw
        {'text': 'Seek support from others', 'archetypes': [8, 11]},             // Caregiver, Everyman
      ],
    },
    {
      'question': 'Your ideal weekend looks like:',
      'options': [
        {'text': 'Exploring somewhere new', 'archetypes': [2, 3]},               // Explorer, Outlaw
        {'text': 'Creating something meaningful', 'archetypes': [6, 4]},          // Creator, Magician
        {'text': 'Relaxing with loved ones', 'archetypes': [9, 8]},              // Lover, Caregiver
        {'text': 'Learning something fascinating', 'archetypes': [1, 5]},         // Sage, Innocent
      ],
    },
    {
      'question': 'People come to you most often for:',
      'options': [
        {'text': 'Advice and wisdom', 'archetypes': [1, 7]},                     // Sage, Ruler
        {'text': 'A good laugh', 'archetypes': [10, 11]},                        // Jester, Everyman
        {'text': 'Emotional support', 'archetypes': [8, 9]},                     // Caregiver, Lover
        {'text': 'Bold ideas and inspiration', 'archetypes': [4, 0]},            // Magician, Hero
      ],
    },
    {
      'question': 'Your biggest fear is:',
      'options': [
        {'text': 'Being powerless or weak', 'archetypes': [0, 7]},               // Hero, Ruler
        {'text': 'Being ordinary or boring', 'archetypes': [4, 6]},              // Magician, Creator
        {'text': 'Being alone or unloved', 'archetypes': [9, 8]},                // Lover, Caregiver
        {'text': 'Being trapped or confined', 'archetypes': [2, 3]},             // Explorer, Outlaw
      ],
    },
    {
      'question': 'At a party, you\'re most likely to:',
      'options': [
        {'text': 'Be the center of attention', 'archetypes': [10, 7]},           // Jester, Ruler
        {'text': 'Have deep one-on-one conversations', 'archetypes': [1, 9]},    // Sage, Lover
        {'text': 'Make sure everyone is having fun', 'archetypes': [8, 11]},     // Caregiver, Everyman
        {'text': 'Observe from a comfortable corner', 'archetypes': [2, 5]},     // Explorer, Innocent
      ],
    },
    {
      'question': 'Your dream career involves:',
      'options': [
        {'text': 'Leading and making big decisions', 'archetypes': [7, 0]},       // Ruler, Hero
        {'text': 'Discovering new ideas or places', 'archetypes': [2, 1]},        // Explorer, Sage
        {'text': 'Helping and healing others', 'archetypes': [8, 5]},             // Caregiver, Innocent
        {'text': 'Disrupting the status quo', 'archetypes': [3, 4]},              // Outlaw, Magician
      ],
    },
    {
      'question': 'When things go wrong, your first instinct is:',
      'options': [
        {'text': 'Take control and fix it', 'archetypes': [0, 7]},               // Hero, Ruler
        {'text': 'Find humor in the situation', 'archetypes': [10, 5]},           // Jester, Innocent
        {'text': 'Think about what can be learned', 'archetypes': [1, 4]},        // Sage, Magician
        {'text': 'Rally others to help', 'archetypes': [11, 8]},                 // Everyman, Caregiver
      ],
    },
    {
      'question': 'You value most in life:',
      'options': [
        {'text': 'Freedom and independence', 'archetypes': [2, 3]},               // Explorer, Outlaw
        {'text': 'Love and connection', 'archetypes': [9, 8]},                   // Lover, Caregiver
        {'text': 'Knowledge and truth', 'archetypes': [1, 4]},                   // Sage, Magician
        {'text': 'Joy and simplicity', 'archetypes': [5, 10]},                   // Innocent, Jester
      ],
    },
    {
      'question': 'Your friends would describe you as:',
      'options': [
        {'text': 'Brave and determined', 'archetypes': [0, 3]},                  // Hero, Outlaw
        {'text': 'Creative and visionary', 'archetypes': [6, 4]},                // Creator, Magician
        {'text': 'Warm and dependable', 'archetypes': [11, 8]},                  // Everyman, Caregiver
        {'text': 'Fun and spontaneous', 'archetypes': [10, 2]},                  // Jester, Explorer
      ],
    },
    {
      'question': 'When you see injustice, you:',
      'options': [
        {'text': 'Stand up and fight for what\'s right', 'archetypes': [0, 3]},   // Hero, Outlaw
        {'text': 'Try to understand all perspectives', 'archetypes': [1, 11]},    // Sage, Everyman
        {'text': 'Comfort those affected', 'archetypes': [8, 9]},                // Caregiver, Lover
        {'text': 'Use your influence to create change', 'archetypes': [7, 4]},    // Ruler, Magician
      ],
    },
    {
      'question': 'Your approach to creativity is:',
      'options': [
        {'text': 'I need to express my inner vision', 'archetypes': [6, 4]},      // Creator, Magician
        {'text': 'I create to connect with others', 'archetypes': [9, 11]},       // Lover, Everyman
        {'text': 'I create to challenge conventions', 'archetypes': [3, 2]},      // Outlaw, Explorer
        {'text': 'I create beauty and harmony', 'archetypes': [5, 6]},            // Innocent, Creator
      ],
    },
    {
      'question': 'Your life motto would be:',
      'options': [
        {'text': 'Live boldly, leave a legacy', 'archetypes': [0, 7]},            // Hero, Ruler
        {'text': 'Seek truth, grow wise', 'archetypes': [1, 2]},                  // Sage, Explorer
        {'text': 'Love deeply, laugh often', 'archetypes': [9, 10]},              // Lover, Jester
        {'text': 'Transform the world', 'archetypes': [4, 3]},                    // Magician, Outlaw
      ],
    },
  ];

  /// Calculate archetype from quiz answers.
  /// [answers] is a list of 12 integers (0-3), each being the selected option index.
  /// Returns the archetype index with the highest score.
  static int calculateArchetype(List<int> answers) {
    final scores = List.filled(12, 0);

    for (int q = 0; q < answers.length && q < questions.length; q++) {
      final optionIndex = answers[q];
      final options = questions[q]['options'] as List;
      if (optionIndex >= 0 && optionIndex < options.length) {
        final option = options[optionIndex] as Map<String, dynamic>;
        final archetypeIndices = option['archetypes'] as List;
        for (final idx in archetypeIndices) {
          scores[idx as int] += 1;
        }
      }
    }

    // Find highest scoring archetype
    int maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  /// Get full archetype profile.
  static Map<String, dynamic> getProfile(int archetypeId) {
    final id = archetypeId.clamp(0, archetypes.length - 1);
    final archetype = archetypes[id];

    return {
      ...archetype,
      'strengths': _strengths(id),
      'challenges': _challenges(id),
      'lifeLesson': _lifeLesson(id),
      'shadowAspect': _shadow(id),
      'compatibleArchetypes': _compatible(id),
      'dailyAffirmation': _affirmation(id),
    };
  }

  /// Parse stored answers JSON string into a list of ints.
  static List<int> parseAnswers(String answersJson) {
    if (answersJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(answersJson);
      if (decoded is List) return decoded.cast<int>();
    } catch (_) {}
    return [];
  }

  /// Daily archetype score based on archetype alignment with current energy.
  static int dailyScore(int archetypeId, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    int score = 55;

    // Archetype resonance cycles (each archetype peaks every ~30 days, staggered)
    final peakDay = (archetypeId * 30 + 15) % 365;
    final distance = ((dayOfYear - peakDay).abs() % 365);
    final resonance = distance < 15 ? 15 : (distance < 30 ? 8 : 0);
    score += resonance;

    // Day of week alignment (certain archetypes thrive on certain days)
    final weekday = today.weekday;
    // Action archetypes (Hero, Ruler, Outlaw) peak on Tuesday/Thursday
    if ((archetypeId == 0 || archetypeId == 7 || archetypeId == 3) &&
        (weekday == 2 || weekday == 4)) score += 10;
    // Intellectual archetypes (Sage, Magician, Creator) peak on Wednesday
    if ((archetypeId == 1 || archetypeId == 4 || archetypeId == 6) &&
        weekday == 3) score += 10;
    // Social archetypes (Lover, Jester, Everyman) peak on Friday/Saturday
    if ((archetypeId == 9 || archetypeId == 10 || archetypeId == 11) &&
        (weekday == 5 || weekday == 6)) score += 10;
    // Nurturing archetypes (Caregiver, Innocent) peak on Sunday/Monday
    if ((archetypeId == 8 || archetypeId == 5) &&
        (weekday == 7 || weekday == 1)) score += 10;

    return score.clamp(0, 100);
  }

  static List<String> _strengths(int id) {
    const data = {
      0: ['Courage', 'Determination', 'Discipline', 'Competence'],
      1: ['Wisdom', 'Intelligence', 'Analytical', 'Thoughtful'],
      2: ['Autonomy', 'Ambition', 'Authenticity', 'Bravery'],
      3: ['Radical freedom', 'Revolution', 'Outrageousness', 'Disruption'],
      4: ['Vision', 'Transformation', 'Catalyst', 'Resourceful'],
      5: ['Optimism', 'Faith', 'Purity', 'Simplicity'],
      6: ['Creativity', 'Imagination', 'Innovation', 'Self-expression'],
      7: ['Leadership', 'Responsibility', 'Organization', 'Control'],
      8: ['Generosity', 'Compassion', 'Selflessness', 'Nurturing'],
      9: ['Passion', 'Commitment', 'Appreciation', 'Devotion'],
      10: ['Joy', 'Humor', 'Living in the moment', 'Fun'],
      11: ['Empathy', 'Realism', 'Common sense', 'Belonging'],
    };
    return data[id] ?? ['Unique', 'Gifted'];
  }

  static List<String> _challenges(int id) {
    const data = {
      0: ['Arrogance', 'Obsession with winning'],
      1: ['Overthinking', 'Detachment from emotions'],
      2: ['Aimlessness', 'Inability to commit'],
      3: ['Self-destruction', 'Crossing ethical lines'],
      4: ['Manipulation', 'Disconnection from reality'],
      5: ['Naivety', 'Denial of problems'],
      6: ['Perfectionism', 'Creative blocks'],
      7: ['Authoritarianism', 'Inability to delegate'],
      8: ['Martyrdom', 'Burnout from overgiving'],
      9: ['Jealousy', 'Loss of identity in relationships'],
      10: ['Irresponsibility', 'Using humor to avoid depth'],
      11: ['Losing individuality', 'Superficial connections'],
    };
    return data[id] ?? ['Balance', 'Growth'];
  }

  static String _lifeLesson(int id) {
    const data = {
      0: 'True strength comes from knowing when not to fight.',
      1: 'Wisdom means nothing if not shared with compassion.',
      2: 'The greatest journey is the one within.',
      3: 'Breaking rules loses meaning without something to build.',
      4: 'Power must serve a higher purpose than the self.',
      5: 'Innocence is strength, not naivety.',
      6: 'Creation is its own reward — let go of the outcome.',
      7: 'The best leaders serve those they lead.',
      8: 'You cannot pour from an empty cup.',
      9: 'Love begins with loving yourself.',
      10: 'Joy is a choice, even in darkness.',
      11: 'Belonging starts with accepting yourself.',
    };
    return data[id] ?? 'Every archetype holds a unique gift.';
  }

  static String _shadow(int id) {
    const data = {
      0: 'The Villain — using strength to dominate rather than protect.',
      1: 'The Cynic — knowledge without heart becomes cold judgment.',
      2: 'The Wanderer — endless seeking without finding.',
      3: 'The Criminal — rebellion without cause or conscience.',
      4: 'The Trickster — using gifts for manipulation.',
      5: 'The Child — refusing to grow up or face reality.',
      6: 'The Perfectionist — destroying work that isn\'t flawless.',
      7: 'The Tyrant — controlling others through fear.',
      8: 'The Martyr — sacrificing self to the point of destruction.',
      9: 'The Obsessive — love becoming possession.',
      10: 'The Fool — avoiding all responsibility through humor.',
      11: 'The Chameleon — changing so much you lose yourself.',
    };
    return data[id] ?? 'An unexplored shadow aspect.';
  }

  static List<String> _compatible(int id) {
    const data = {
      0: ['The Sage', 'The Magician', 'The Caregiver'],
      1: ['The Hero', 'The Explorer', 'The Creator'],
      2: ['The Outlaw', 'The Sage', 'The Jester'],
      3: ['The Explorer', 'The Magician', 'The Hero'],
      4: ['The Creator', 'The Sage', 'The Hero'],
      5: ['The Caregiver', 'The Everyman', 'The Sage'],
      6: ['The Magician', 'The Sage', 'The Explorer'],
      7: ['The Hero', 'The Caregiver', 'The Sage'],
      8: ['The Innocent', 'The Hero', 'The Ruler'],
      9: ['The Creator', 'The Jester', 'The Caregiver'],
      10: ['The Explorer', 'The Lover', 'The Everyman'],
      11: ['The Caregiver', 'The Jester', 'The Innocent'],
    };
    return data[id] ?? ['The Sage', 'The Hero'];
  }

  static String _affirmation(int id) {
    const data = {
      0: 'I am brave, strong, and capable of overcoming any obstacle.',
      1: 'I seek truth with an open mind and share wisdom with compassion.',
      2: 'I am free to chart my own path and discover new horizons.',
      3: 'I break barriers that no longer serve the greater good.',
      4: 'I am a powerful co-creator with the universe.',
      5: 'I trust in the goodness of life and choose hope over fear.',
      6: 'My creative vision brings beauty and meaning to the world.',
      7: 'I lead with integrity, strength, and service to others.',
      8: 'My compassion is a healing force that transforms lives.',
      9: 'I love deeply, authentically, and without reservation.',
      10: 'I choose joy and bring light to every moment.',
      11: 'I belong, I matter, and I connect with all of humanity.',
    };
    return data[id] ?? 'I embrace my unique cosmic blueprint.';
  }
}
