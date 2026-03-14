// Step 1: Inventory
// This file DEFINES:
//   - NumerologyScreen (StatefulWidget)
//   - _NumerologyScreenState — holds AnimationController, animation, all state vars
//   - _buildLargeNumberCircle(int number, bool isMaster) -> Widget
//   - _buildSmallNumberCircle(int number, String label) -> Widget
//   - _buildCycleCard(String label, int number) -> Widget
//   - _showNumberSheet(int number, String type) -> void
//   - _isMasterNumber(int number) -> bool
//   - _typeToKey(String type) -> String (maps display type to CosmicService key)
//
// This file USES from other files:
//   - StarBackground (from lib/widgets/star_background.dart) — purely visual widget
//   - CosmicService (from lib/services/cosmic_service.dart) — static methods:
//     * getLifePathNumber() -> int
//     * getExpressionNumber() -> int
//     * getSoulUrgeNumber() -> int
//     * getPersonalityNumber() -> int
//     * getPersonalDayNumber() -> int
//     * getPersonalMonthNumber() -> int
//     * getPersonalYearNumber() -> int
//     * isMasterNumber(int) -> bool
//     * getNumberInterpretation(int number, String type) -> String
//
// Step 2: Connections
// - LuckBreakdownScreen navigates TO NumerologyScreen via Navigator.push
// - NumerologyScreen navigates BACK via AppBar BackButton (Navigator.pop)
// - No forward navigation from this screen
// - Uses StarBackground as first Stack child
// - Uses CosmicService for all number data and interpretations
//
// Step 3: User Journey Trace
// - User arrives from LuckBreakdownScreen
// - initState: loads all numbers from CosmicService, sets up AnimationController
// - AnimationController runs 1200ms, Tween<int>(0 -> _lifePathNumber)
//   drives _animatedLifePath via addListener + setState
// - Large circle shows animated count-up for life path number (gold border if master)
// - Three small circles show expression, soul urge, personality
// - Cycle cards row shows personal day/month/year
// - Tapping any circle calls _showNumberSheet -> showModalBottomSheet
// - Bottom sheet shows CosmicService.getNumberInterpretation(number, typeKey)
// - Back button -> Navigator.pop(context)
//
// Step 4: Layout Sanity
// - CustomScrollView inside Stack — fine, Stack fills Scaffold body
// - No ListView inside Column — using CustomScrollView with SliverToBoxAdapter
// - All TextEditingControllers: N/A — no text input
// - Scaffold has AppBar ✓
// - AnimationController disposed in dispose() ✓
// - _animatedLifePath updated via addListener ✓
// - Modal bottom sheet uses DraggableScrollableSheet for long text ✓
// - Type mapping: 'Life Path' -> 'life_path', 'Expression' -> 'expression',
//   'Soul Urge' -> 'soul_urge', 'Personality' -> 'personality',
//   'Personal Day' -> 'personal_day', 'Personal Month' -> 'personal_day' (reuse),
//   'Personal Year' -> 'personal_day' (reuse)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';

class NumerologyScreen extends StatefulWidget {
  const NumerologyScreen({super.key});

  @override
  State<NumerologyScreen> createState() => _NumerologyScreenState();
}

class _NumerologyScreenState extends State<NumerologyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _lifePathAnimation;

  int _lifePathNumber = 7;
  int _expressionNumber = 3;
  int _soulUrgeNumber = 9;
  int _personalityNumber = 5;
  int _personalDay = 4;
  int _personalMonth = 8;
  int _personalYear = 2;
  int _animatedLifePath = 0;

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _gold = Color(0xFFF59E0B);
  static const Color _bgColor = Color(0xFF0F0A1A);
  static const Color _cardBg = Color(0xFF1A1025);

  @override
  void initState() {
    super.initState();

    // Load all numbers from CosmicService using profile data
    final profile = context.read<UserProfileProvider>().profile;
    final dob = profile?.dateOfBirth ?? '';
    final fullName = profile?.fullName ?? '';
    _lifePathNumber = CosmicService.getLifePathNumber(dob: dob);
    _expressionNumber = CosmicService.getExpressionNumber(fullName: fullName);
    _soulUrgeNumber = CosmicService.getSoulUrgeNumber(fullName: fullName);
    _personalityNumber = CosmicService.getPersonalityNumber(fullName: fullName);
    _personalDay = CosmicService.getPersonalDayNumber(dob: dob);
    _personalMonth = CosmicService.getPersonalMonthNumber(dob: dob);
    _personalYear = CosmicService.getPersonalYearNumber(dob: dob);

    // Set up count-up animation for life path number
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _lifePathAnimation = IntTween(begin: 0, end: _lifePathNumber).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _lifePathAnimation.addListener(() {
      setState(() {
        _animatedLifePath = _lifePathAnimation.value;
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isMasterNumber(int number) {
    return CosmicService.isMasterNumber(number);
  }

  /// Maps display label to the key used in CosmicService.getNumberInterpretation
  String _typeToKey(String type) {
    switch (type) {
      case 'Life Path':
        return 'life_path';
      case 'Expression':
        return 'expression';
      case 'Soul Urge':
        return 'soul_urge';
      case 'Personality':
        return 'personality';
      case 'Personal Day':
        return 'personal_day';
      case 'Personal Month':
        return 'personal_day';
      case 'Personal Year':
        return 'personal_day';
      default:
        return 'life_path';
    }
  }

  void _showNumberSheet(int number, String type) {
    final interpretation =
        CosmicService.getNumberInterpretation(number, _typeToKey(type));
    final isMaster = _isMasterNumber(number);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1025),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isMaster
                      ? _gold.withValues(alpha: 0.5)
                      : _purple.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Number circle header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _cardBg,
                        border: Border.all(
                          color: isMaster ? _gold : _purple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isMaster ? _gold : _purple)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isMaster ? _gold : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Type label
                  Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 18,
                        color: isMaster ? _gold : Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (isMaster) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _gold.withValues(alpha: 0.5), width: 1),
                        ),
                        child: const Text(
                          '✦ Master Number ✦',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: _gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Divider
                  Divider(
                      color: (isMaster ? _gold : _purple)
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  // Interpretation text
                  Text(
                    interpretation,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isMaster ? _gold : _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLargeNumberCircle(int number, bool isMaster) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _cardBg,
        border: Border.all(
          color: isMaster ? _gold : _purple,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isMaster ? _gold : _purple).withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMaster)
            Icon(
              Icons.star,
              size: 12,
              color: _gold,
            ),
          Text(
            '$_animatedLifePath',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isMaster ? _gold : Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallNumberCircle(int number, String label) {
    final isMaster = _isMasterNumber(number);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cardBg,
            border: Border.all(
              color: isMaster ? _gold : _purple,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMaster ? _gold : _purple)
                    .withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isMaster ? _gold : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleCard(String label, int number) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _purple.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$number',
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMaster = _isMasterNumber(_lifePathNumber);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Numerology',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const StarBackground(),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large life path circle
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              _showNumberSheet(_lifePathNumber, 'Life Path'),
                          child:
                              _buildLargeNumberCircle(_lifePathNumber, isMaster),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Life Path Number',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Raleway',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Three smaller circles row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => _showNumberSheet(
                                _expressionNumber, 'Expression'),
                            child: _buildSmallNumberCircle(
                                _expressionNumber, 'Expression'),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showNumberSheet(_soulUrgeNumber, 'Soul Urge'),
                            child: _buildSmallNumberCircle(
                                _soulUrgeNumber, 'Soul Urge'),
                          ),
                          GestureDetector(
                            onTap: () => _showNumberSheet(
                                _personalityNumber, 'Personality'),
                            child: _buildSmallNumberCircle(
                                _personalityNumber, 'Personality'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Divider(
                        color: _purple.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Personal Cycles',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _showNumberSheet(_personalDay, 'Personal Day'),
                              child:
                                  _buildCycleCard('Personal Day', _personalDay),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showNumberSheet(
                                  _personalMonth, 'Personal Month'),
                              child: _buildCycleCard(
                                  'Personal Month', _personalMonth),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showNumberSheet(
                                  _personalYear, 'Personal Year'),
                              child: _buildCycleCard(
                                  'Personal Year', _personalYear),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Tap hint
                      Center(
                        child: Text(
                          'Tap any number to reveal its meaning',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}