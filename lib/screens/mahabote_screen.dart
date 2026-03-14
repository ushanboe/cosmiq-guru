// Step 1: Inventory
// This file DEFINES:
//   - MahaboteScreen (StatefulWidget) — main screen
//   - _MahaboteScreenState — holds _dayAnimal, _dayAnimalEmoji, _birthDay, _planet, _direction
//   - MahaboteOctagonPainter (CustomPainter) — draws octagon with 8 segments, labels, center circle
//   - Helper methods: _buildPillBadge, _buildDasaCard, _buildHouseCard
//
// This file USES from other files:
//   - StarBackground from lib/widgets/star_background.dart
//
// Step 2: Connections
//   - LuckBreakdownScreen navigates TO this screen via Navigator.push
//   - Back button calls Navigator.pop(context)
//   - No navigation FROM this screen
//
// Step 3: User Journey Trace
//   - User arrives from LuckBreakdownScreen tapping Mahabote card
//   - Sees AppBar with back button, StarBackground, day animal row (emoji + name + planet/direction pills)
//   - Scrolls down: 'Birth Chart' label, 280x280 CustomPaint octagon
//   - Dasa period card below octagon
//   - 8 house cards at bottom
//   - Back button -> Navigator.pop(context)
//
// Step 4: Layout Sanity
//   - CustomScrollView with SliverToBoxAdapter wraps Column — no unbounded height issues
//   - Stack with StarBackground (SizedBox.expand) + CustomScrollView — correct
//   - 8 house cards generated via List.generate — each is a real card widget
//   - MahaboteOctagonPainter: draws octagon path, 8 radial lines, segment labels, center circle

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';

class MahaboteScreen extends StatefulWidget {
  const MahaboteScreen({super.key});

  @override
  State<MahaboteScreen> createState() => _MahaboteScreenState();
}

class _MahaboteScreenState extends State<MahaboteScreen> {
  String _dayAnimal = 'Garuda';
  String _dayAnimalEmoji = '🦅';
  String _birthDay = 'Wednesday (AM)';
  String _planet = 'Mercury';
  String _direction = 'North-East';
  String _dasaPeriod = 'Mercury Dasa';
  int _dasaYearsRemaining = 4;
  String _dasaDescription = '';

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().profile;
    final dob = profile?.dateOfBirth ?? '';
    final birthTime = profile?.birthTime ?? '12:00';
    final mahabote = CosmicService.getMahaboteProfile(dob: dob, birthTime: birthTime);
    _dayAnimal = mahabote['animal'] as String? ?? 'Garuda';
    _dayAnimalEmoji = mahabote['animalEmoji'] as String? ?? '🦅';
    _birthDay = mahabote['birthDay'] as String? ?? 'Wednesday';
    _planet = mahabote['planet'] as String? ?? 'Mercury';
    _direction = mahabote['direction'] as String? ?? 'North-East';
    _dasaPeriod = mahabote['dasaPeriod'] as String? ?? 'Mercury Dasa';
    _dasaYearsRemaining = mahabote['dasaYearsRemaining'] as int? ?? 4;
    _dasaDescription = mahabote['dasaDescription'] as String? ?? '';
  }

  static const List<String> _houseNames = [
    'Life',
    'Health',
    'Finance',
    'Love',
    'Travel',
    'Education',
    'Career',
    'Spirituality',
  ];

  static const List<String> _houseDescriptions = [
    'Your life force and vitality are strong this cycle.',
    'Physical wellbeing is favored — maintain balance.',
    'Financial opportunities arise from unexpected sources.',
    'Romantic energy is heightened; openness brings connection.',
    'Journeys — both physical and inner — are auspicious.',
    'Learning and knowledge acquisition are well-aspected.',
    'Professional growth is supported by planetary alignment.',
    'Spiritual insight deepens through quiet contemplation.',
  ];

  static const List<String> _houseIcons = [
    '☀️', '💚', '💰', '❤️', '✈️', '📚', '💼', '🔮',
  ];

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'Raleway',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDasaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Text(
                'Current Dasa Period',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 14,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _dasaPeriod,
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remaining: $_dasaYearsRemaining years',
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Raleway',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.62,
              backgroundColor: const Color(0xFF241538),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '62% elapsed',
            style: TextStyle(
              color: Colors.white38,
              fontFamily: 'Raleway',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF241538),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _houseIcons[index],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'House ${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontFamily: 'Raleway',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _houseNames[index],
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _houseDescriptions[index],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Raleway',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
          'Burmese Mahabote',
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
                      // Day animal row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayAnimalEmoji,
                            style: const TextStyle(fontSize: 56),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dayAnimal,
                                style: const TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Born on $_birthDay',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildPillBadge(
                                    '☿ $_planet',
                                    const Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildPillBadge(
                                    '↗ $_direction',
                                    const Color(0xFF3B82F6),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Birth Chart',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: CustomPaint(
                            painter: MahaboteOctagonPainter(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDasaCard(),
                      const SizedBox(height: 16),
                      const Text(
                        'House Positions',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(8, (i) => _buildHouseCard(i)),
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

class MahaboteOctagonPainter extends CustomPainter {
  static const List<String> _houseLabels = [
    'Life',
    'Health',
    'Finance',
    'Love',
    'Travel',
    'Education',
    'Career',
    'Spirituality',
  ];

  static const List<String> _houseValues = [
    '★★★',
    '★★☆',
    '★★★',
    '★☆☆',
    '★★☆',
    '★★★',
    '★★☆',
    '★★★',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const centerRadius = 40.0;

    // Compute the 8 vertices of the octagon
    final List<Offset> vertices = List.generate(8, (i) {
      final angle = (pi / 8) + (i * pi / 4); // offset by 22.5° so flat top
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });

    // Fill paint for octagon background
    final fillPaint = Paint()
      ..color = const Color(0xFF1A1025)
      ..style = PaintingStyle.fill;

    // Border paint
    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Radial line paint
    final radialPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw filled octagon
    final octagonPath = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < 8; i++) {
      octagonPath.lineTo(vertices[i].dx, vertices[i].dy);
    }
    octagonPath.close();
    canvas.drawPath(octagonPath, fillPaint);
    canvas.drawPath(octagonPath, borderPaint);

    // Draw 8 radial lines from center to each vertex
    for (final vertex in vertices) {
      canvas.drawLine(center, vertex, radialPaint);
    }

    // Draw center circle
    final centerFillPaint = Paint()
      ..color = const Color(0xFF241538)
      ..style = PaintingStyle.fill;
    final centerBorderPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, centerRadius, centerFillPaint);
    canvas.drawCircle(center, centerRadius, centerBorderPaint);

    // Draw 'Chart' text in center
    final centerTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Chart',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    centerTextPainter.layout();
    centerTextPainter.paint(
      canvas,
      Offset(
        center.dx - centerTextPainter.width / 2,
        center.dy - centerTextPainter.height / 2,
      ),
    );

    // Draw house labels and values in each segment
    // Label position: midpoint between center edge and octagon edge
    for (int i = 0; i < 8; i++) {
      final angle = (pi / 8) + (i * pi / 4);
      final labelRadius = centerRadius + (radius - centerRadius) * 0.58;
      final labelOffset = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      // House name
      final namePainter = TextPainter(
        text: TextSpan(
          text: _houseLabels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      namePainter.layout(maxWidth: 60);
      namePainter.paint(
        canvas,
        Offset(
          labelOffset.dx - namePainter.width / 2,
          labelOffset.dy - namePainter.height - 1,
        ),
      );

      // House value (star rating)
      final valuePainter = TextPainter(
        text: TextSpan(
          text: _houseValues[i],
          style: const TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      valuePainter.layout(maxWidth: 60);
      valuePainter.paint(
        canvas,
        Offset(
          labelOffset.dx - valuePainter.width / 2,
          labelOffset.dy + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(MahaboteOctagonPainter oldDelegate) => false;
}