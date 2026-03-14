// Step 1: Inventory
// This file DEFINES:
//   - LuckBreakdownScreen (StatefulWidget)
//   - _LuckBreakdownScreenState — holds _systems List<Map<String,dynamic>>
//   - _buildStackedBarChart() -> Widget — Row of 7 colored segments proportional to weighted scores
//   - _buildSystemCard(Map<String,dynamic> system) -> Widget — tappable card with icon, name, score, chevron
//   - _navigateToSystem(String systemId) -> void — routes to correct detail screen
//
// State variables:
//   - _systems: List<Map<String,dynamic>> — loaded from CosmicService.getSystemBreakdown()
//     Keys per system: 'id', 'name', 'emoji', 'score', 'color', 'summary', 'detail'
//
// This file USES from other files:
//   - CosmicService.getSystemBreakdown() -> List<Map<String,dynamic>>
//     from package:cosmiq_guru/services/cosmic_service.dart
//   - StarBackground from package:cosmiq_guru/widgets/star_background.dart
//   - AstrologyScreen from package:cosmiq_guru/screens/astrology_screen.dart
//   - NumerologyScreen from package:cosmiq_guru/screens/numerology_screen.dart
//   - ChineseZodiacScreen from package:cosmiq_guru/screens/chinese_zodiac_screen.dart
//   - MahaboteScreen from package:cosmiq_guru/screens/mahabote_screen.dart
//   - LunarScreen from package:cosmiq_guru/screens/lunar_screen.dart
//
// Step 2: Connections
// - MainShell renders LuckBreakdownScreen in IndexedStack index 1 (Explore tab)
// - HomeScreen LuckGauge tap also navigates to LuckBreakdownScreen
// - Since this is in IndexedStack, AppBar back button should pop if pushed, but
//   when rendered as tab it won't have a back button. The spec says:
//   "leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))"
//   However when used as IndexedStack tab, Navigator.pop would pop the whole shell.
//   The spec explicitly shows the back button, so implement it as specified.
//   When used as a tab (not pushed), ModalRoute.of(context)?.canPop could guard this,
//   but spec says to implement it, so we'll include it. The back button will only
//   do something meaningful when pushed via Navigator.push from HomeScreen.
//
// Navigates TO:
//   - AstrologyScreen (id: 'astrology')
//   - NumerologyScreen (id: 'numerology')
//   - ChineseZodiacScreen (id: 'chinese_zodiac')
//   - MahaboteScreen (id: 'mahabote')
//   - LunarScreen (id: 'lunar')
//   - id: 'archetype' and 'ai_modifier' — no dedicated screens in manifest,
//     so show a SnackBar or modal with the detail text from the system map
//
// Step 3: User Journey Trace
// - Screen renders: StarBackground + CustomScrollView
// - CustomScrollView: SliverToBoxAdapter (composite score badge + stacked bar chart)
//   + SliverList (7 system cards)
// - Composite score badge: Row with "Composite Score" label + "73" gold + "/100"
// - Stacked bar chart: Row of 7 colored segments, each width proportional to score,
//   height 20dp, borderRadius 10dp on first and last segments
// - 7 system cards: each shows emoji icon, name, summary, score/100, weight%, chevron
// - Tapping astrology -> Navigator.push AstrologyScreen
// - Tapping numerology -> Navigator.push NumerologyScreen
// - Tapping chinese_zodiac -> Navigator.push ChineseZodiacScreen
// - Tapping mahabote -> Navigator.push MahaboteScreen
// - Tapping lunar -> Navigator.push LunarScreen
// - Tapping archetype/ai_modifier -> showModalBottomSheet with detail text
// - Back button -> Navigator.pop(context) — only effective when pushed
//
// Step 4: Layout Sanity
// - CustomScrollView inside Stack — Stack fills Scaffold body, correct
// - SliverList inside CustomScrollView — no unbounded scroll issues
// - Stacked bar chart: Row with 7 Flexible children weighted by score — no overflow
// - System card: Row with emoji + Column(name, summary) + Spacer + Column(score, weight) + chevron
//   Need to wrap the middle Column in Expanded to prevent overflow
// - All colors use Color(0xFF...) format
// - withValues(alpha:) not withOpacity()
// - Composite score shows 73 (from CosmicService.getLuckScore() or hardcoded as spec shows '73')
// - The spec widget tree shows Text('73') hardcoded — but we should use CosmicService.getLuckScore()
//   for consistency. Actually spec says Text('73') so we'll compute it from _systems weighted average
//   OR just call CosmicService.getLuckScore() which returns 73.
// - Weight for each system: 7 systems, equal weight = ~14.3% each, or we can compute
//   a weighted average from scores. Spec shows "weight%" in card. Since CosmicService
//   doesn't define weights, I'll assign reasonable weights: Astrology 20%, Numerology 15%,
//   Chinese 15%, Mahabote 10%, Lunar 15%, Archetype 15%, AI 10% = 100%
//   These weights are used for display and bar chart proportional sizing.
// - Bar chart segments: width proportional to (weight * score) normalized, or just proportional
//   to weight (so each segment's width = weight% of total bar width). The spec says
//   "proportional to weighted scores" — so width = weight * score / sum(weight*score).
//   Simpler: use Flexible with flex = (weight * score).round() for each segment.
// - Composite score = sum(weight_i * score_i) = computed from _systems

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/screens/astrology_screen.dart';
import 'package:cosmiq_guru/screens/numerology_screen.dart';
import 'package:cosmiq_guru/screens/chinese_zodiac_screen.dart';
import 'package:cosmiq_guru/screens/mahabote_screen.dart';
import 'package:cosmiq_guru/screens/lunar_screen.dart';
import 'package:cosmiq_guru/screens/archetype_screen.dart';
import 'package:cosmiq_guru/screens/planetary_hours_screen.dart';

class LuckBreakdownScreen extends StatefulWidget {
  const LuckBreakdownScreen({super.key});

  @override
  State<LuckBreakdownScreen> createState() => _LuckBreakdownScreenState();
}

class _LuckBreakdownScreenState extends State<LuckBreakdownScreen> {
  List<Map<String, dynamic>> _systems = [];
  int _compositeScore = 73;

  // Weights for each system id (must sum to 100)
  static const Map<String, int> _weights = {
    'astrology': 18,
    'numerology': 18,
    'chinese_zodiac': 13,
    'mahabote': 17,
    'lunar': 14,
    'archetype': 10,
    'planetary_hours': 10,
  };

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().profile;
    final dob = profile?.dateOfBirth ?? '';
    final birthTime = profile?.birthTime ?? '12:00';
    final fullName = profile?.fullName ?? '';
    final archetypeId = profile?.archetypeId ?? 0;
    _systems = CosmicService.getSystemBreakdown(
      dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
    );
    _compositeScore = _computeCompositeScore();
  }

  int _computeCompositeScore() {
    double total = 0;
    int weightSum = 0;
    for (final system in _systems) {
      final id = system['id'] as String? ?? '';
      final score = system['score'] as int? ?? 0;
      final weight = _weights[id] ?? 0;
      total += score * weight;
      weightSum += weight;
    }
    if (weightSum == 0) return 73;
    return (total / weightSum).round();
  }

  void _navigateToSystem(Map<String, dynamic> system) {
    final id = system['id'] as String? ?? '';
    switch (id) {
      case 'astrology':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AstrologyScreen()),
        );
        break;
      case 'numerology':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NumerologyScreen()),
        );
        break;
      case 'chinese_zodiac':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChineseZodiacScreen()),
        );
        break;
      case 'mahabote':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MahaboteScreen()),
        );
        break;
      case 'lunar':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LunarScreen()),
        );
        break;
      case 'archetype':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArchetypeScreen()),
        );
        break;
      case 'planetary_hours':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlanetaryHoursScreen()),
        );
        break;
      default:
        _showSystemDetailSheet(system);
    }
  }

  void _showSystemDetailSheet(Map<String, dynamic> system) {
    final name = system['name'] as String? ?? '';
    final emoji = system['emoji'] as String? ?? '✨';
    final detail = system['detail'] as String? ?? '';
    final colorValue = system['color'] as int? ?? 0xFF8B5CF6;
    final color = Color(colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1025),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
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
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: color.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
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

  Widget _buildStackedBarChart() {
    if (_systems.isEmpty) return const SizedBox.shrink();

    // Compute flex values: weight * score for proportional widths
    final List<int> flexValues = _systems.map((s) {
      final id = s['id'] as String? ?? '';
      final score = s['score'] as int? ?? 0;
      final weight = _weights[id] ?? 0;
      return (weight * score / 100).round().clamp(1, 100);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Distribution',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 13,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 20,
            child: Row(
              children: List.generate(_systems.length, (i) {
                final colorValue =
                    _systems[i]['color'] as int? ?? 0xFF7C3AED;
                final color = Color(colorValue);
                return Flexible(
                  flex: flexValues[i],
                  child: Container(
                    height: 20,
                    color: color,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend row
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: _systems.map((s) {
            final colorValue = s['color'] as int? ?? 0xFF7C3AED;
            final color = Color(colorValue);
            final emoji = s['emoji'] as String? ?? '';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> system) {
    final name = system['name'] as String? ?? '';
    final emoji = system['emoji'] as String? ?? '✨';
    final score = system['score'] as int? ?? 0;
    final colorValue = system['color'] as int? ?? 0xFF7C3AED;
    final color = Color(colorValue);
    final summary = system['summary'] as String? ?? '';
    final id = system['id'] as String? ?? '';
    final weight = _weights[id] ?? 0;

    final bool hasDetailScreen = [
      'astrology',
      'numerology',
      'chinese_zodiac',
      'mahabote',
      'lunar',
      'archetype',
      'planetary_hours',
    ].contains(id);

    return GestureDetector(
      onTap: () => _navigateToSystem(system),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Emoji icon in colored circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 11,
                      color: Colors.white54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Score + weight column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$score',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const TextSpan(
                        text: '/100',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$weight%',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              hasDetailScreen ? Icons.chevron_right : Icons.info_outline,
              color: color.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Cosmic Breakdown',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.0),
                  const Color(0xFF7C3AED).withValues(alpha: 0.6),
                  const Color(0xFF7C3AED).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const StarBackground(),
          CustomScrollView(
            slivers: [
              // ── Composite Score Badge + Bar Chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Composite score badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1025),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.1),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Composite Score',
                              style: TextStyle(
                                color: Colors.white54,
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '$_compositeScore',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontFamily: 'Cinzel',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                color: Colors.white38,
                                fontFamily: 'Raleway',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStackedBarChart(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Section Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Divination Systems',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 7 System Cards ──
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: _buildSystemCard(_systems[i]),
                  ),
                  childCount: _systems.length,
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}