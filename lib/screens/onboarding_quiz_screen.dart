// Step 1: Inventory
// This file DEFINES:
//   - OnboardingQuizScreen (StatefulWidget) — accepts name, dob, birthTime, location from constructor
//   - _OnboardingQuizScreenState — holds _currentQuestion, _selectedAnswers, _archetypeScores
//   - _questions: const List<Map<String, dynamic>> — 12 hardcoded questions with 4 options each
//   - _scoringMatrix: const List<List<int>> — 12x4 matrix mapping answer index to archetype bucket
//   - _archetypeNames: const List<String> — 12 Jungian archetype names
//   - _buildOptionCard(int i) — builds a GestureDetector card for each option
//   - _computeLeadArchetype() — returns argmax of _archetypeScores
//   - _onOptionTap(int i) — handles option selection, score update, navigation
//   - _onBack() — decrements question, reverses score
//
// This file USES from other files:
//   - StarBackground (from lib/widgets/star_background.dart)
//   - OnboardingLoadingScreen (from lib/screens/onboarding_loading_screen.dart)
//     Constructor: name, dob, birthTime, location, birthCountry, timezone, archetypeId, archetypeAnswers
//
// Step 2: Connections
// - OnboardingBirthScreen navigates TO this screen via Navigator.push with name, dob, birthTime, location
// - This screen navigates BACK to OnboardingBirthScreen via Navigator.pop when _currentQuestion == 0 and Back pressed
// - On question 11 answered: Navigator.pushReplacement to OnboardingLoadingScreen
// - OnboardingLoadingScreen constructor needs: name, dob, birthTime, location, birthCountry, timezone, archetypeId, archetypeAnswers
//   NOTE: OnboardingBirthScreen passes name, dob, birthTime, location — birthCountry and timezone not passed here
//   Looking at OnboardingLoadingScreen constructor: birthCountry and timezone are required
//   OnboardingQuizScreen only receives name, dob, birthTime, location from spec
//   I'll pass empty strings for birthCountry and timezone since they're not available here
//   Actually, let me check the wiring manifest: "OnboardingBirthScreen → OnboardingQuizScreen: Continue button onPressed: Navigator.push(OnboardingQuizScreen(name, dob, birthTime, location))"
//   So only 4 params. I'll pass '' for birthCountry and timezone.
//
// Step 3: User Journey Trace
// - User arrives at quiz screen with 12 questions
// - Sees question 1/12, progress bar at 1/12, 4 option cards in 2x2 grid
// - Taps option → card highlights purple+gold, after 300ms advances to next question
// - At question 12, taps option → after 300ms navigates to OnboardingLoadingScreen
// - Back button visible when _currentQuestion > 0 — tapping decrements and reverses score
// - When _currentQuestion == 0 and Back tapped → Navigator.pop (goes back to OnboardingBirthScreen)
//   Wait — spec says: "Back button onPressed when _currentQuestion == 0: Navigator.pop(context)"
//   But the widgetTree shows: "if (_currentQuestion > 0) OutlinedButton(onPressed: _onBack, ...)"
//   So Back button is only visible when _currentQuestion > 0, and _onBack decrements.
//   When _currentQuestion == 0, there's no back button shown... but the wiring manifest says:
//   "OnboardingQuizScreen → OnboardingBirthScreen: Back button onPressed when _currentQuestion == 0: Navigator.pop(context)"
//   I'll show the back button always and handle both cases in _onBack:
//   if _currentQuestion == 0: Navigator.pop, else decrement
//   Actually the widgetTree says "if (_currentQuestion > 0)" so I'll show it for > 0 only,
//   but also add a back button for question 0 that pops. Let me re-read...
//   The widgetTree shows: "if (_currentQuestion > 0) OutlinedButton(onPressed: _onBack...)"
//   The wiring manifest says: "Back button onPressed when _currentQuestion == 0: Navigator.pop"
//   I'll implement: show back button always, when question == 0 it pops, else it decrements.
//   This satisfies both the wiring manifest AND the spirit of the spec.
//
// Step 4: Layout Sanity
// - Expanded(child: GridView.count(...)) inside Column — Expanded handles the flex correctly
// - GridView.count with shrinkWrap could also work, but Expanded is better here
// - childAspectRatio: 1.8 means wider than tall — good for option cards
// - No unbounded height issues since GridView is inside Expanded
// - _scoringMatrix: 12 questions x 4 options, each int is the archetype INDEX (0-11) to score +1
//   Wait — re-reading spec: "adding _scoringMatrix[_currentQuestion][i] points to the corresponding archetype bucket"
//   So _scoringMatrix[q][option] = archetype_index to add a point to
//   I'll design it as: each cell = archetype index (0-11) that gets +1 point when that option chosen
//   Actually more flexible: make it so _scoringMatrix[q][i] = archetype_index to increment
//   _archetypeScores[_scoringMatrix[_currentQuestion][i]]++
//
// Scoring matrix design:
// 12 questions, each with 4 options mapping to one of 12 archetypes
// Archetypes: Hero(0), Sage(1), Explorer(2), Outlaw(3), Magician(4), Innocent(5),
//             Creator(6), Ruler(7), Caregiver(8), Lover(9), Jester(10), Everyman(11)
// Each question's 4 options map to 4 different archetypes

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/screens/onboarding_loading_screen.dart';

class OnboardingQuizScreen extends StatefulWidget {
  final String name;
  final String dob;
  final String birthTime;
  final String location;

  const OnboardingQuizScreen({
    super.key,
    required this.name,
    required this.dob,
    required this.birthTime,
    required this.location,
  });

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  int _currentQuestion = 0;
  late List<int> _selectedAnswers;
  late List<int> _archetypeScores;

  // 12 Jungian archetype names (indices 0-11)
  static const List<String> _archetypeNames = [
    'Hero',
    'Sage',
    'Explorer',
    'Outlaw',
    'Magician',
    'Innocent',
    'Creator',
    'Ruler',
    'Caregiver',
    'Lover',
    'Jester',
    'Everyman',
  ];

  // 12 hardcoded questions with 4 options each
  static const List<Map<String, dynamic>> _questions = [
    {
      'question': 'When faced with a great challenge, you are most likely to...',
      'options': [
        'Rise up and confront it head-on',
        'Seek knowledge and wisdom first',
        'Venture into unknown territory',
        'Break every rule that stands in your way',
      ],
    },
    {
      'question': 'Your deepest desire in life is to...',
      'options': [
        'Transform the world through inner power',
        'Experience paradise and pure happiness',
        'Bring something entirely new into existence',
        'Be in control and create lasting order',
      ],
    },
    {
      'question': 'People who know you would describe you as...',
      'options': [
        'Nurturing and deeply compassionate',
        'Passionate and intensely romantic',
        'Playful and endlessly witty',
        'Reliable, humble, and down-to-earth',
      ],
    },
    {
      'question': 'In a group setting, you naturally tend to...',
      'options': [
        'Lead the charge and inspire others',
        'Offer wisdom and thoughtful guidance',
        'Explore new ideas and push boundaries',
        'Challenge the status quo boldly',
      ],
    },
    {
      'question': 'When you imagine your ideal life, it looks like...',
      'options': [
        'Wielding unseen forces to create miracles',
        'Living in simple joy and perfect peace',
        'Building something truly original and lasting',
        'Commanding respect and shaping the future',
      ],
    },
    {
      'question': 'Your greatest strength is your ability to...',
      'options': [
        'Support and heal those around you',
        'Love deeply and forge soulful connections',
        'Make people laugh and lighten the mood',
        'Blend in and connect with anyone',
      ],
    },
    {
      'question': 'When you encounter injustice, you typically...',
      'options': [
        'Fight back with courage and conviction',
        'Analyze the root cause with clarity',
        'Seek freedom from the oppressive system',
        'Rebel and disrupt the established order',
      ],
    },
    {
      'question': 'Your creative energy is best expressed through...',
      'options': [
        'Channeling mystical or hidden forces',
        'Pursuing simple pleasures and gratitude',
        'Inventing, designing, or building new things',
        'Organizing and structuring grand visions',
      ],
    },
    {
      'question': 'In relationships, you are most known for being...',
      'options': [
        'Protective and fiercely loyal',
        'Devoted and emotionally giving',
        'Flirtatious, playful, and fun',
        'Steady, trustworthy, and grounded',
      ],
    },
    {
      'question': 'Your approach to personal growth is to...',
      'options': [
        'Overcome obstacles through sheer willpower',
        'Study, reflect, and accumulate wisdom',
        'Wander and discover who you truly are',
        'Shatter limitations others dare not touch',
      ],
    },
    {
      'question': 'The legacy you most want to leave behind is...',
      'options': [
        'A world transformed by invisible magic',
        'A life of love, light, and innocence',
        'A body of work that outlives you',
        'An empire built on strength and vision',
      ],
    },
    {
      'question': 'At your core, you believe that life is about...',
      'options': [
        'Giving back and caring for others',
        'Experiencing beauty and deep connection',
        'Laughter, play, and not taking it too seriously',
        'Living authentically among real people',
      ],
    },
  ];

  // Scoring matrix: _scoringMatrix[questionIndex][optionIndex] = archetypeIndex
  // Archetypes: Hero=0, Sage=1, Explorer=2, Outlaw=3, Magician=4, Innocent=5,
  //             Creator=6, Ruler=7, Caregiver=8, Lover=9, Jester=10, Everyman=11
  static const List<List<int>> _scoringMatrix = [
    [0, 1, 2, 3],   // Q1: Hero, Sage, Explorer, Outlaw
    [4, 5, 6, 7],   // Q2: Magician, Innocent, Creator, Ruler
    [8, 9, 10, 11], // Q3: Caregiver, Lover, Jester, Everyman
    [0, 1, 2, 3],   // Q4: Hero, Sage, Explorer, Outlaw
    [4, 5, 6, 7],   // Q5: Magician, Innocent, Creator, Ruler
    [8, 9, 10, 11], // Q6: Caregiver, Lover, Jester, Everyman
    [0, 1, 2, 3],   // Q7: Hero, Sage, Explorer, Outlaw
    [4, 5, 6, 7],   // Q8: Magician, Innocent, Creator, Ruler
    [0, 8, 10, 11], // Q9: Hero, Caregiver, Jester, Everyman
    [0, 1, 2, 3],   // Q10: Hero, Sage, Explorer, Outlaw
    [4, 5, 6, 7],   // Q11: Magician, Innocent, Creator, Ruler
    [8, 9, 10, 11], // Q12: Caregiver, Lover, Jester, Everyman
  ];

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(12, -1);
    _archetypeScores = List.filled(12, 0);
  }

  int _computeLeadArchetype() {
    int maxScore = -1;
    int maxIndex = 0;
    for (int i = 0; i < _archetypeScores.length; i++) {
      if (_archetypeScores[i] > maxScore) {
        maxScore = _archetypeScores[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  void _onOptionTap(int optionIndex) {
    // Ignore tap if already answered this question and animating
    if (_selectedAnswers[_currentQuestion] == optionIndex) return;

    // Reverse previous answer's score if re-answering
    final previousAnswer = _selectedAnswers[_currentQuestion];
    if (previousAnswer != -1) {
      final prevArchetype = _scoringMatrix[_currentQuestion][previousAnswer];
      setState(() {
        _archetypeScores[prevArchetype] =
            (_archetypeScores[prevArchetype] - 1).clamp(0, 99);
      });
    }

    // Apply new answer score
    final archetypeIndex = _scoringMatrix[_currentQuestion][optionIndex];
    setState(() {
      _selectedAnswers[_currentQuestion] = optionIndex;
      _archetypeScores[archetypeIndex] = _archetypeScores[archetypeIndex] + 1;
    });

    // Advance after 300ms delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_currentQuestion < 11) {
        setState(() {
          _currentQuestion++;
        });
      } else {
        // Last question answered — compute archetype and navigate
        final archetypeId = _computeLeadArchetype();
        final answersJson = jsonEncode(_selectedAnswers);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingLoadingScreen(
              name: widget.name,
              dob: widget.dob,
              birthTime: widget.birthTime,
              location: widget.location,
              birthCountry: '',
              timezone: '',
              archetypeId: archetypeId,
              archetypeAnswers: answersJson,
            ),
          ),
        );
      }
    });
  }

  void _onBack() {
    if (_currentQuestion == 0) {
      Navigator.pop(context);
      return;
    }
    // Reverse the score for the current question's answer before going back
    final currentAnswer = _selectedAnswers[_currentQuestion - 1];
    setState(() {
      if (currentAnswer != -1) {
        final archetypeIndex = _scoringMatrix[_currentQuestion - 1][currentAnswer];
        _archetypeScores[archetypeIndex] =
            (_archetypeScores[archetypeIndex] - 1).clamp(0, 99);
        _selectedAnswers[_currentQuestion - 1] = -1;
      }
      _currentQuestion--;
    });
  }

  Widget _buildOptionCard(int optionIndex) {
    final isSelected = _selectedAnswers[_currentQuestion] == optionIndex;
    final optionText =
        _questions[_currentQuestion]['options'][optionIndex] as String;

    return GestureDetector(
      onTap: () => _onOptionTap(optionIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : const Color(0xFF7C3AED).withValues(alpha: 0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              optionText,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontFamily: 'Raleway',
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadArchetype = _computeLeadArchetype();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(
        children: [
          const StarBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Counter row + lead archetype label
                  Row(
                    children: [
                      Text(
                        'Question ${_currentQuestion + 1}/12',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Raleway',
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _archetypeNames[leadArchetype],
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  LinearProgressIndicator(
                    value: (_currentQuestion + 1) / 12,
                    backgroundColor: const Color(0xFF241538),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 32),
                  // Question text
                  Text(
                    _questions[_currentQuestion]['question'] as String,
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // 2x2 GridView of option cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        4,
                        (i) => _buildOptionCard(i),
                      ),
                    ),
                  ),
                  // Back button row
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _onBack,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          _currentQuestion == 0 ? '← Exit' : '← Back',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}