// Step 1: Inventory
// This file DEFINES:
//   - AstrologyScreen (StatefulWidget)
//   - _AstrologyScreenState — holds _sunSign, _moonSign, _risingSign, _transits, _horoscopeText
//   - _buildSignCard(String label, String sign, Color color) -> Widget
//   - _buildTransitTile(Map<String, dynamic> transit) -> Widget
//   - _buildHoroscopeCard() -> Widget
//
// This file USES from other files:
//   - CosmicService.getSunSign() -> String
//   - CosmicService.getMoonSign() -> String
//   - CosmicService.getRisingSign() -> String
//   - CosmicService.getPlanetaryTransits() -> List<Map<String, dynamic>>
//     (keys: 'planet', 'symbol', 'transit', 'influence', 'isPositive')
//   - CosmicService.getDailyHoroscope() -> String
//   - StarBackground widget
//
// Imports needed:
//   - package:flutter/material.dart
//   - package:cosmiq_guru/services/cosmic_service.dart
//   - package:cosmiq_guru/widgets/star_background.dart
//
// Step 2: Connections
// - LuckBreakdownScreen navigates TO AstrologyScreen via Navigator.push
// - AstrologyScreen navigates BACK via BackButton / Navigator.pop
// - CosmicService is called in initState to load all data synchronously
//
// Step 3: User Journey Trace
// - User arrives from LuckBreakdownScreen tapping "Western Astrology" card
// - Screen shows AppBar with "Western Astrology" title and back button
// - Body: Stack with StarBackground + CustomScrollView
// - CustomScrollView has three slivers:
//   1. SliverToBoxAdapter: Row of 3 sign cards + "Planetary Transits" heading
//   2. SliverList: transit ExpansionTiles (one per transit)
//   3. SliverToBoxAdapter: horoscope card with gold border
// - Tapping ExpansionTile expands to show influence text
// - Tapping back button returns to LuckBreakdownScreen
//
// Step 4: Layout Sanity
// - CustomScrollView inside Stack is fine — Stack fills Scaffold body
// - SliverList with ExpansionTiles — each tile is in a Padding widget
// - Sign cards: Row with 3 Expanded children — no overflow issues
// - Horoscope card: Container with gold border BoxDecoration
// - ExpansionTile initiallyExpanded: false (collapsed by default)
// - If _transits is empty, show "No active transits today" text in SliverList
// - TextStyle uses 'Cinzel' and 'Raleway' font families (registered in pubspec)
// - Colors: scaffold bg #0F0A1A, card bg #1A1025, gold #F59E0B
// - Transit tile: leading icon mapped from planet symbol, title = planet + transit, subtitle = influence type
// - getPlanetaryTransits() returns maps with keys: 'planet', 'symbol', 'transit', 'influence', 'isPositive'
// - isPositive (bool) used to color the leading icon: green if positive, red if negative

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';

class AstrologyScreen extends StatefulWidget {
  const AstrologyScreen({super.key});

  @override
  State<AstrologyScreen> createState() => _AstrologyScreenState();
}

class _AstrologyScreenState extends State<AstrologyScreen> {
  String _sunSign = 'Leo';
  String _moonSign = 'Scorpio';
  String _risingSign = 'Aquarius';
  List<Map<String, dynamic>> _transits = [];
  String _horoscopeText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserProfileProvider>().profile;
      final dob = profile?.dateOfBirth ?? '';
      final birthTime = profile?.birthTime ?? '12:00';
      setState(() {
        _sunSign = CosmicService.getSunSign(dob: dob);
        _moonSign = CosmicService.getMoonSign(dob: dob);
        _risingSign = CosmicService.getRisingSign(dob: dob, birthTime: birthTime);
        _transits = CosmicService.getPlanetaryTransits(dob: dob);
        _horoscopeText = CosmicService.getDailyHoroscope(dob: dob);
      });
    });
  }

  Widget _buildSignCard(String label, String sign, Color accentColor) {
    // Map label prefix to a unicode symbol for display
    final String symbol;
    if (label.startsWith('☉')) {
      symbol = '☉';
    } else if (label.startsWith('☽')) {
      symbol = '☽';
    } else {
      symbol = '↑';
    }

    // Map sign name to an emoji
    final String signEmoji = _signEmoji(sign);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 24,
                color: accentColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sign,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              signEmoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label.replaceAll(RegExp(r'^[^ ]+ '), ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: accentColor.withValues(alpha: 0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitTile(Map<String, dynamic> transit) {
    final String planet = transit['planet'] as String? ?? '';
    final String symbol = transit['symbol'] as String? ?? '';
    final String transitText = transit['transit'] as String? ?? '';
    final String influence = transit['influence'] as String? ?? '';
    final bool isPositive = transit['isPositive'] as bool? ?? true;

    final Color iconColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 18,
                  color: iconColor,
                ),
              ),
            ),
          ),
          title: Text(
            '$planet — $transitText',
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            isPositive ? 'Favorable influence' : 'Challenging influence',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 12,
              color: iconColor.withValues(alpha: 0.85),
            ),
          ),
          iconColor: const Color(0xFF7C3AED),
          collapsedIconColor: Colors.white54,
          children: [
            Text(
              influence,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 13,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoroscopeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                "Today's Horoscope",
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 16,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.8),
                  const Color(0xFFF59E0B).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _horoscopeText,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _signEmoji(String sign) {
    const Map<String, String> emojiMap = {
      'Aries': '♈',
      'Taurus': '♉',
      'Gemini': '♊',
      'Cancer': '♋',
      'Leo': '♌',
      'Virgo': '♍',
      'Libra': '♎',
      'Scorpio': '♏',
      'Sagittarius': '♐',
      'Capricorn': '♑',
      'Aquarius': '♒',
      'Pisces': '♓',
    };
    return emojiMap[sign] ?? '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        elevation: 0,
        title: const Text(
          'Western Astrology',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
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
              // ── Sign Cards Row + Transits Heading ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildSignCard(
                            '☉ Sun',
                            _sunSign,
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 12),
                          _buildSignCard(
                            '☽ Moon',
                            _moonSign,
                            const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 12),
                          _buildSignCard(
                            '↑ Rising',
                            _risingSign,
                            const Color(0xFF3B82F6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
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
                            'Planetary Transits',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Transit ExpansionTiles ──
              _transits.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Center(
                          child: Text(
                            'No active transits today',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.54),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: _buildTransitTile(_transits[i]),
                        ),
                        childCount: _transits.length,
                      ),
                    ),

              // ── Horoscope Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildHoroscopeCard(),
                ),
              ),

              // Bottom padding for safe area
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