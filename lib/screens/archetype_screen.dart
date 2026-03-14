import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/engines/archetype_engine.dart';

class ArchetypeScreen extends StatefulWidget {
  const ArchetypeScreen({super.key});

  @override
  State<ArchetypeScreen> createState() => _ArchetypeScreenState();
}

class _ArchetypeScreenState extends State<ArchetypeScreen> {
  String _name = 'The Hero';
  String _emoji = '⚔️';
  String _motto = '';
  List<String> _strengths = [];
  List<String> _challenges = [];
  String _lifeLesson = '';
  String _shadowAspect = '';
  List<String> _compatibleArchetypes = [];
  String _affirmation = '';
  int _score = 65;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().profile;
    final archetypeId = profile?.archetypeId ?? 0;
    final archetype = ArchetypeEngine.getProfile(archetypeId);
    _score = ArchetypeEngine.dailyScore(archetypeId);
    setState(() {
      _name = archetype['name'] as String? ?? 'The Hero';
      _emoji = archetype['emoji'] as String? ?? '⚔️';
      _motto = archetype['motto'] as String? ?? '';
      _strengths = List<String>.from(archetype['strengths'] as List? ?? []);
      _challenges = List<String>.from(archetype['challenges'] as List? ?? []);
      _lifeLesson = archetype['lifeLesson'] as String? ?? '';
      _shadowAspect = archetype['shadowAspect'] as String? ?? '';
      _compatibleArchetypes = List<String>.from(archetype['compatibleArchetypes'] as List? ?? []);
      _affirmation = archetype['dailyAffirmation'] as String? ?? '';
    });
  }

  Widget _buildCard({required String title, required Widget child, Color borderColor = const Color(0xFF7C3AED)}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChipList(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            item,
            style: TextStyle(
              color: color,
              fontFamily: 'Raleway',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
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
          'Jungian Archetype',
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
                      // Large emoji
                      Center(
                        child: Text(_emoji, style: const TextStyle(fontSize: 80)),
                      ),
                      const SizedBox(height: 8),
                      // Archetype name
                      Center(
                        child: Text(
                          _name,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Motto
                      Center(
                        child: Text(
                          '"$_motto"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Score badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.5)),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Today\'s Resonance  ',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                                TextSpan(
                                  text: '$_score',
                                  style: const TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEC4899),
                                  ),
                                ),
                                const TextSpan(
                                  text: '/100',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Strengths
                      _buildCard(
                        title: 'Core Strengths',
                        child: _buildChipList(_strengths, const Color(0xFF10B981)),
                        borderColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),

                      // Challenges
                      _buildCard(
                        title: 'Shadow Challenges',
                        child: _buildChipList(_challenges, const Color(0xFFF59E0B)),
                        borderColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 16),

                      // Life Lesson
                      _buildCard(
                        title: 'Life Lesson',
                        child: Text(
                          _lifeLesson,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shadow Aspect
                      _buildCard(
                        title: 'Shadow Aspect',
                        borderColor: const Color(0xFFEF4444),
                        child: Text(
                          _shadowAspect,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Compatible Archetypes
                      _buildCard(
                        title: 'Compatible Archetypes',
                        borderColor: const Color(0xFFEC4899),
                        child: _buildChipList(_compatibleArchetypes, const Color(0xFFEC4899)),
                      ),
                      const SizedBox(height: 16),

                      // Daily Affirmation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              const Color(0xFFEC4899).withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Daily Affirmation',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 14,
                                color: Colors.white54,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '"$_affirmation"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
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
