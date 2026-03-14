// Step 1: Inventory
// This file DEFINES:
//   - ChineseZodiacScreen (StatefulWidget)
//   - _ChineseZodiacScreenState with all state variables and builder methods
//   - _buildElementBadge(String element, Color color) -> Widget
//   - _buildYinYangPill(String yinYang) -> Widget
//   - _buildAnimalCard(String title, String animal, String emoji, String subtitle) -> Widget
//   - _buildTrineCard() -> Widget
//   - _buildLuckyRow() -> Widget
//   - _buildCompatibilityCard() -> Widget
//
// State variables from spec:
//   _animalName, _animalEmoji, _element, _elementColor, _yinYang,
//   _innerAnimal, _innerAnimalEmoji, _secretAnimal, _secretAnimalEmoji,
//   _luckyColor, _luckyDirection
// Additional from CosmicService profile map:
//   _trineAnimals (List), _trineGroup (String), _compatibleAnimals (List),
//   _overallFortune (String), _luckyColorHex (int), _yearDescription (String)
//
// This file USES from other files:
//   - StarBackground from package:cosmiq_guru/widgets/star_background.dart
//   - CosmicService from package:cosmiq_guru/services/cosmic_service.dart
//     -> getChineseZodiacProfile() -> Map<String,dynamic>
//
// Step 2: Connections
// - LuckBreakdownScreen navigates TO this screen via Navigator.push
// - Back button calls Navigator.pop(context)
// - No navigation FROM this screen
// - CosmicService.getChineseZodiacProfile() called in initState
//
// Step 3: User Journey Trace
// - User arrives from LuckBreakdownScreen tapping Chinese Zodiac card
// - initState loads all values from CosmicService.getChineseZodiacProfile()
// - Screen shows: large emoji, animal name, element badge + yin/yang pill
// - Row of inner animal card + secret animal card
// - Trine group card with 3 animals
// - Lucky row with color circle + direction
// - Compatibility note card
// - Back button pops to LuckBreakdownScreen
//
// Step 4: Layout Sanity
// - CustomScrollView inside Stack — correct, no unbounded scroll issues
// - StarBackground as first child in Stack — correct
// - Row with two Expanded cards — correct
// - All text uses Cinzel/Raleway as per spec
// - Element badge and yin/yang pill use withValues(alpha:) not withOpacity()

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';

class ChineseZodiacScreen extends StatefulWidget {
  const ChineseZodiacScreen({super.key});

  @override
  State<ChineseZodiacScreen> createState() => _ChineseZodiacScreenState();
}

class _ChineseZodiacScreenState extends State<ChineseZodiacScreen> {
  String _animalName = 'Dragon';
  String _animalEmoji = '🐉';
  String _element = 'Wood';
  Color _elementColor = const Color(0xFF10B981);
  String _yinYang = 'Yang';
  String _innerAnimal = 'Rabbit';
  String _innerAnimalEmoji = '🐰';
  String _secretAnimal = 'Tiger';
  String _secretAnimalEmoji = '🐯';
  String _luckyColor = 'Gold';
  String _luckyDirection = 'North-East';
  String _trineGroup = 'First Trine';
  List<String> _trineAnimals = ['Dragon', 'Monkey', 'Rat'];
  List<String> _compatibleAnimals = ['Rat', 'Monkey', 'Rooster'];
  String _overallFortune = '';
  String _yearDescription = '';
  int _luckyColorHex = 0xFFF59E0B;

  static const Map<String, String> _animalEmojis = {
    'Rat': '🐀',
    'Ox': '🐂',
    'Tiger': '🐯',
    'Rabbit': '🐰',
    'Dragon': '🐉',
    'Snake': '🐍',
    'Horse': '🐴',
    'Goat': '🐐',
    'Monkey': '🐒',
    'Rooster': '🐓',
    'Dog': '🐕',
    'Pig': '🐷',
  };

  static const Map<String, Color> _elementColors = {
    'Wood': Color(0xFF10B981),
    'Fire': Color(0xFFEF4444),
    'Earth': Color(0xFFF59E0B),
    'Metal': Color(0xFFD1D5DB),
    'Water': Color(0xFF3B82F6),
  };

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<UserProfileProvider>().profile;
    final dob = userProfile?.dateOfBirth ?? '';
    final birthTime = userProfile?.birthTime ?? '12:00';
    final profile = CosmicService.getChineseZodiacProfile(dob: dob, birthTime: birthTime);
    setState(() {
      _animalName = profile['animal'] as String? ?? 'Dragon';
      _animalEmoji = profile['emoji'] as String? ?? '🐉';
      _element = profile['element'] as String? ?? 'Wood';
      _elementColor = _elementColors[_element] ?? const Color(0xFF10B981);
      _yinYang = profile['yinYang'] as String? ?? 'Yang';
      _innerAnimal = profile['innerAnimal'] as String? ?? 'Rabbit';
      _innerAnimalEmoji = profile['innerAnimalEmoji'] as String? ?? '🐰';
      _secretAnimal = profile['secretAnimal'] as String? ?? 'Tiger';
      _secretAnimalEmoji = profile['secretAnimalEmoji'] as String? ?? '🐯';
      _luckyColor = profile['luckyColor'] as String? ?? 'Gold';
      _luckyDirection = profile['luckyDirection'] as String? ?? 'North-East';
      _trineGroup = profile['trineGroup'] as String? ?? 'First Trine';
      _trineAnimals = List<String>.from(profile['trineAnimals'] as List? ?? ['Dragon', 'Monkey', 'Rat']);
      _compatibleAnimals = List<String>.from(profile['compatibleAnimals'] as List? ?? ['Rat', 'Monkey', 'Rooster']);
      _overallFortune = profile['overallFortune'] as String? ?? '';
      _yearDescription = profile['yearDescription'] as String? ?? '';
      _luckyColorHex = profile['luckyColorHex'] as int? ?? 0xFFF59E0B;
    });
  }

  Widget _buildElementBadge(String element, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        '$element Element',
        style: TextStyle(
          color: color,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildYinYangPill(String yinYang) {
    final color = yinYang == 'Yang'
        ? const Color(0xFF7C3AED)
        : const Color(0xFFEC4899);
    final symbol = yinYang == 'Yang' ? '☯ Yang' : '☯ Yin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: color,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAnimalCard(
    String title,
    String animal,
    String emoji,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'Raleway',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 6),
          Text(
            animal,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cinzel',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'Raleway',
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Trine Group',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cinzel',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _trineGroup,
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontFamily: 'Raleway',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _trineAnimals.map((animal) {
              final emoji = _animalEmojis[animal] ?? '🐾';
              final isCurrentAnimal = animal == _animalName;
              return Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isCurrentAnimal
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.25)
                          : const Color(0xFF241538),
                      shape: BoxShape.circle,
                      border: isCurrentAnimal
                          ? Border.all(color: const Color(0xFF7C3AED), width: 2)
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    animal,
                    style: TextStyle(
                      color: isCurrentAnimal
                          ? const Color(0xFF7C3AED)
                          : Colors.white70,
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      fontWeight: isCurrentAnimal
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF7C3AED), height: 1),
          const SizedBox(height: 12),
          Text(
            'Animals in your trine share a fundamental understanding and natural affinity. Together you form an unstoppable alliance of complementary strengths.',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Raleway',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lucky Omens',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cinzel',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(_luckyColorHex),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lucky Color',
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Raleway',
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _luckyColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.navigation,
                color: Color(0xFF7C3AED),
                size: 16,
              ),
              const SizedBox(width: 10),
              const Text(
                'Lucky Direction',
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Raleway',
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _luckyDirection,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFFEC4899),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Compatibility',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cinzel',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Most Compatible With',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'Raleway',
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _compatibleAnimals.map((animal) {
              final emoji = _animalEmojis[animal] ?? '🐾';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      animal,
                      style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_overallFortune.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF241538), height: 1),
            const SizedBox(height: 16),
            Text(
              _overallFortune,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Raleway',
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
          if (_yearDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFF59E0B),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _yearDescription,
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        elevation: 0,
        title: const Text(
          'Chinese Zodiac',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          _animalEmoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _animalName,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildElementBadge(_element, _elementColor),
                          const SizedBox(width: 12),
                          _buildYinYangPill(_yinYang),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimalCard(
                              'Inner Animal',
                              _innerAnimal,
                              _innerAnimalEmoji,
                              'Birth Month',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnimalCard(
                              'Secret Animal',
                              _secretAnimal,
                              _secretAnimalEmoji,
                              'Birth Hour',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTrineCard(),
                      const SizedBox(height: 16),
                      _buildLuckyRow(),
                      const SizedBox(height: 16),
                      _buildCompatibilityCard(),
                      const SizedBox(height: 32),
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