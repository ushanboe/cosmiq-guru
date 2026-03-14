import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/screens/trends_screen.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _scaffoldBg = Color(0xFF0F0A1A);
  static const _cardBg = Color(0xFF1A1025);
  static const _purpleAccent = Color(0xFF7C3AED);
  static const _goldColor = Color(0xFFF59E0B);
  static const _greenColor = Color(0xFF10B981);
  static const _blueColor = Color(0xFF3B82F6);

  static const _moodEmojis = ['😫', '😔', '😐', '🙂', '🤩'];
  static const _moodLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Amazing'];
  static const _availableTags = [
    'Good sleep', 'Bad sleep', 'Productive', 'Stressed', 'Lucky',
    'Social', 'Quiet day', 'Exercise', 'Travel',
  ];

  int _selectedMood = 2; // 0-4, default "Okay"
  final Set<String> _selectedTags = {};
  final TextEditingController _noteController = TextEditingController();
  List<JournalEntry> _history = [];
  bool _isLoading = true;
  bool _hasTodayEntry = false;
  String _userId = '';
  int _todayLuckScore = 0;
  String _todayMoonPhase = '';
  String _todayDominantSystem = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final profile = context.read<UserProfileProvider>().profile;
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      _userId = profile.id;

      // Get today's cosmic data
      final dob = profile.dateOfBirth;
      final fullName = profile.fullName;
      final birthTime = profile.birthTime;
      final archetypeId = profile.archetypeId;

      _todayLuckScore = CosmicService.getLuckScore(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      _todayMoonPhase = CosmicService.getMoonPhase();

      // Find dominant system via breakdown
      final breakdown = CosmicService.getSystemBreakdown(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      if (breakdown.isNotEmpty) {
        final best = breakdown.reduce((a, b) =>
            ((a['score'] as num?) ?? 0) >= ((b['score'] as num?) ?? 0) ? a : b);
        _todayDominantSystem = (best['name'] as String?) ?? '';
      }

      // Load history
      final db = DatabaseService.instance;
      final history = await db.getJournalEntries(_userId);
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final todayEntry = history.where((e) => e.date == todayStr).toList();

      if (todayEntry.isNotEmpty) {
        _selectedMood = todayEntry.first.mood;
        _selectedTags.addAll(todayEntry.first.tags);
        _noteController.text = todayEntry.first.note ?? '';
        _hasTodayEntry = true;
      }

      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntry() async {
    if (_userId.isEmpty) return;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final entry = JournalEntry(
      id: _hasTodayEntry
          ? _history.firstWhere((e) => e.date == todayStr).id
          : const Uuid().v4(),
      userId: _userId,
      date: todayStr,
      mood: _selectedMood,
      tagsJson: jsonEncode(_selectedTags.toList()),
      note: _noteController.text.isEmpty ? null : _noteController.text,
      luckScore: _todayLuckScore,
      moonPhase: _todayMoonPhase,
      dominantSystem: _todayDominantSystem,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.saveJournalEntry(entry);
    _hasTodayEntry = true;
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved'),
          backgroundColor: Color(0xFF7C3AED),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'COSMIC JOURNAL',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up, color: Color(0xFF7C3AED)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrendsScreen()),
            ),
            tooltip: 'View Trends',
          ),
        ],
      ),
      body: Stack(
        children: [
          const StarBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _purpleAccent))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Today's cosmic context
                          _buildCosmicContextCard(),
                          const SizedBox(height: 16),

                          // Mood picker
                          _buildMoodPicker(),
                          const SizedBox(height: 16),

                          // Tags
                          _buildTagsPicker(),
                          const SizedBox(height: 16),

                          // Note
                          _buildNoteField(),
                          const SizedBox(height: 16),

                          // Save button
                          _buildSaveButton(),
                          const SizedBox(height: 24),

                          // History header
                          if (_history.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text(
                                  'PAST ENTRIES',
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 14,
                                    color: Colors.white70,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_history.length} entries',
                                  style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // History list
                          ..._history.map((e) => _buildHistoryCard(e)),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildCosmicContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildContextChip('🎯', '$_todayLuckScore', 'Luck'),
          const SizedBox(width: 12),
          _buildContextChip('🌙', _todayMoonPhase.isEmpty ? '—' : _todayMoonPhase.split(' ').first, 'Moon'),
          const SizedBox(width: 12),
          _buildContextChip('⭐', _todayDominantSystem, 'Dominant'),
        ],
      ),
    );
  }

  Widget _buildContextChip(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 10,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW DO YOU FEEL?',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final isSelected = _selectedMood == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _goldColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _goldColor
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _moodEmojis[i],
                        style: TextStyle(fontSize: isSelected ? 32 : 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _moodLabels[i],
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 9,
                          color: isSelected ? _goldColor : Colors.white38,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blueColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK TAGS',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _blueColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _blueColor
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: isSelected ? _blueColor : Colors.white54,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'NOTE',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_noteController.text.length}/140',
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 10,
                  color: Colors.white30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 140,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Optional quick note...',
              hintStyle: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purpleAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          _hasTodayEntry ? 'UPDATE TODAY\'S ENTRY' : 'SAVE TODAY\'S ENTRY',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(JournalEntry entry) {
    final isToday = entry.date == DateTime.now().toIso8601String().split('T').first;
    final tags = entry.tags;
    final dateStr = _formatDate(entry.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? _goldColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _moodEmojis[entry.mood.clamp(0, 4)],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 13,
                          color: isToday ? _goldColor : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _moodLabels[entry.mood.clamp(0, 4)],
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                // Luck score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(entry.luckScore).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _scoreColor(entry.luckScore).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${entry.luckScore}',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 14,
                      color: _scoreColor(entry.luckScore),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                )).toList(),
              ),
            ],
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.note!,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 12,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '🌙 ${entry.moonPhase.isEmpty ? "—" : entry.moonPhase.split(" ").first}',
                  style: const TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white30),
                ),
                const SizedBox(width: 12),
                Text(
                  '⭐ ${entry.dominantSystem}',
                  style: const TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return _greenColor;
    if (score >= 50) return _goldColor;
    if (score >= 25) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entryDate = DateTime(date.year, date.month, date.day);
      final diff = today.difference(entryDate).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '$diff days ago';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
