import 'package:flutter/material.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/engines/planetary_hours_engine.dart';

class PlanetaryHoursScreen extends StatefulWidget {
  const PlanetaryHoursScreen({super.key});

  @override
  State<PlanetaryHoursScreen> createState() => _PlanetaryHoursScreenState();
}

class _PlanetaryHoursScreenState extends State<PlanetaryHoursScreen> {
  late Map<String, dynamic> _currentHour;
  late List<Map<String, dynamic>> _allHours;
  late List<Map<String, dynamic>> _bestWindows;
  late String _dayRuler;
  late int _score;

  static const Map<String, String> _planetEmojis = {
    'Sun': '☀️',
    'Moon': '🌙',
    'Mars': '♂️',
    'Mercury': '☿️',
    'Jupiter': '♃',
    'Venus': '♀️',
    'Saturn': '♄',
  };

  static const Map<String, Color> _planetColors = {
    'Sun': Color(0xFFF59E0B),
    'Moon': Color(0xFFC0C0C0),
    'Mars': Color(0xFFEF4444),
    'Mercury': Color(0xFF3B82F6),
    'Jupiter': Color(0xFF8B5CF6),
    'Venus': Color(0xFFEC4899),
    'Saturn': Color(0xFF6B7280),
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentHour = PlanetaryHoursEngine.currentPlanetaryHour(now: now);
    _allHours = PlanetaryHoursEngine.planetaryHours(now);
    _bestWindows = PlanetaryHoursEngine.bestWindows(date: now);
    _dayRuler = _currentHour['dayRuler'] as String? ?? 'Sun';
    _score = PlanetaryHoursEngine.dailyScore(now: now);
  }

  Widget _buildCurrentHourCard() {
    final planet = _currentHour['planet'] as String;
    final emoji = _planetEmojis[planet] ?? '⭐';
    final color = _planetColors[planet] ?? const Color(0xFF7C3AED);
    final props = _currentHour['properties'] as Map<String, dynamic>?;
    final keywords = (props?['keywords'] as List?)?.cast<String>() ?? [];
    final bestFor = props?['bestFor'] as String? ?? '';
    final avoid = props?['avoid'] as String? ?? '';
    final isBenefic = props?['benefic'] as bool? ?? false;
    final start = _currentHour['startHour'] as double;
    final end = _currentHour['endHour'] as double;
    final isDaytime = _currentHour['isDaytime'] as bool? ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$planet Hour',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 20,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isBenefic ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isBenefic ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          child: Text(
                            isBenefic ? 'Benefic' : 'Malefic',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isBenefic ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${PlanetaryHoursEngine.formatHour(start)} – ${PlanetaryHoursEngine.formatHour(end)}  •  ${isDaytime ? 'Day' : 'Night'}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF241538), height: 1),
          const SizedBox(height: 16),
          // Keywords
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: keywords.map((k) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  k,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Best for
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bestFor,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Avoid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  avoid,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(Map<String, dynamic> hour, bool isCurrent) {
    final planet = hour['planet'] as String;
    final emoji = _planetEmojis[planet] ?? '⭐';
    final color = _planetColors[planet] ?? const Color(0xFF7C3AED);
    final start = hour['startHour'] as double;
    final end = hour['endHour'] as double;
    final isDaytime = hour['isDaytime'] as bool? ?? true;
    final hourNum = hour['hourNumber'] as int? ?? 0;
    final props = PlanetaryHoursEngine.planetProperties[planet]!;
    final isBenefic = props['benefic'] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.15)
            : const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
            : Border.all(color: const Color(0xFF241538)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$hourNum',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: isCurrent ? Colors.white : Colors.white38,
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              planet,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: isCurrent ? Colors.white : Colors.white70,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${PlanetaryHoursEngine.formatHour(start)} – ${PlanetaryHoursEngine.formatHour(end)}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: isCurrent ? Colors.white70 : Colors.white38,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isBenefic ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isBenefic ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlanet = _currentHour['planet'] as String;
    final now = DateTime.now();
    final currentDecimalHour = now.hour + now.minute / 60.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        elevation: 0,
        title: const Text(
          'Planetary Hours',
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
                      // Day ruler badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _planetEmojis[_dayRuler] ?? '⭐',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Day of $_dayRuler',
                                style: const TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 14,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current hour card
                      _buildCurrentHourCard(),
                      const SizedBox(height: 24),

                      // Best windows section
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Best Windows Today',
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
                      ..._bestWindows.take(6).map((h) {
                        final planet = h['planet'] as String;
                        final start = h['startHour'] as double;
                        final end = h['endHour'] as double;
                        final emoji = _planetEmojis[planet] ?? '⭐';
                        final color = _planetColors[planet] ?? const Color(0xFF7C3AED);
                        final isDaytime = h['isDaytime'] as bool? ?? true;
                        final isPast = end < currentDecimalHour && isDaytime;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? const Color(0xFF1A1025).withValues(alpha: 0.5)
                                  : const Color(0xFF10B981).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPast
                                    ? const Color(0xFF241538)
                                    : const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(emoji, style: TextStyle(fontSize: 16, color: isPast ? Colors.white38 : null)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    planet,
                                    style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      color: isPast ? Colors.white38 : Colors.white70,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${PlanetaryHoursEngine.formatHour(start)} – ${PlanetaryHoursEngine.formatHour(end)}',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: isPast ? Colors.white24 : Colors.white54,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                                  size: 14,
                                  color: isPast ? Colors.white24 : (isDaytime ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // All hours - Daytime
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.wb_sunny, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Daytime Hours',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._allHours.sublist(0, 12).map((h) {
                        final planet = h['planet'] as String;
                        final start = h['startHour'] as double;
                        final end = h['endHour'] as double;
                        final isCurrent = planet == currentPlanet &&
                            currentDecimalHour >= start &&
                            currentDecimalHour < end;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildHourRow(h, isCurrent),
                        );
                      }),
                      const SizedBox(height: 20),

                      // All hours - Nighttime
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.nightlight_round, color: Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Nighttime Hours',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._allHours.sublist(12).map((h) {
                        final planet = h['planet'] as String;
                        final start = h['startHour'] as double;
                        final end = h['endHour'] as double;
                        final isCurrent = planet == currentPlanet &&
                            (end < start
                                ? (currentDecimalHour >= start || currentDecimalHour < end)
                                : (currentDecimalHour >= start && currentDecimalHour < end));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildHourRow(h, isCurrent),
                        );
                      }),
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
