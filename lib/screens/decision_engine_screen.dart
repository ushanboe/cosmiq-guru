import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/ai_advice_service.dart';
import 'package:cosmiq_guru/engines/archetype_engine.dart';

class DecisionEngineScreen extends StatefulWidget {
  const DecisionEngineScreen({super.key});

  @override
  State<DecisionEngineScreen> createState() => _DecisionEngineScreenState();
}

class _DecisionEngineScreenState extends State<DecisionEngineScreen>
    with SingleTickerProviderStateMixin {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedCategory = 'general';
  DateTime _targetDate = DateTime.now();
  bool _isCalculating = false;
  bool _isLoadingAiAdvice = false;
  Map<String, dynamic>? _result;
  List<DecisionHistoryEntry> _history = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _categories = <String, String>{
    'business': 'Business & Career',
    'investment': 'Money & Investment',
    'love': 'Love & Relationships',
    'travel': 'Travel',
    'health': 'Health & Wellness',
    'education': 'Education',
    'property': 'Property & Real Estate',
    'general': 'General',
  };

  static const _categoryIcons = <String, IconData>{
    'business': Icons.business_center,
    'investment': Icons.trending_up,
    'love': Icons.favorite,
    'travel': Icons.flight_takeoff,
    'health': Icons.spa,
    'education': Icons.school,
    'property': Icons.home_work,
    'general': Icons.auto_fix_high,
  };

  static const _goldColor = Color(0xFFF59E0B);
  static const _purpleColor = Color(0xFF7C3AED);
  static const _cardBg = Color(0xFF1A1025);
  static const _scaffoldBg = Color(0xFF0F0A1A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final profile = context.read<UserProfileProvider>().profile;
    if (profile == null) return;
    final history =
        await DatabaseService.instance.getDecisionHistory(profile.id);
    setState(() => _history = history);
  }

  Future<void> _consultCosmos() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your decision first')),
      );
      return;
    }

    final profile = context.read<UserProfileProvider>().profile;
    if (profile == null) return;

    setState(() {
      _isCalculating = true;
      _result = null;
    });
    _animController.reset();

    try {
      // Brief delay for dramatic effect
      await Future.delayed(const Duration(milliseconds: 1500));

      final result = CosmicService.getDecisionReading(
        category: _selectedCategory,
        targetDate: _targetDate,
        dob: profile.dateOfBirth,
        fullName: profile.fullName,
        birthTime: profile.birthTime,
        archetypeId: profile.archetypeId,
        questionText: question,
      );

      // Compose bestWindow from separate engine keys
      final bestWindow =
          '${result['bestWindowStart']} - ${result['bestWindowEnd']} (${result['bestWindowPlanet']})';
      result['bestWindow'] = bestWindow;

      final systemScores = result['systemScores'] as Map<String, int>;
      final fallbackAdvice = result['advice'] as String;

      // Show results immediately (advice loading separately)
      setState(() {
        _isCalculating = false;
        _isLoadingAiAdvice = true;
        _result = result;
      });
      _animController.forward();

      // Auto-scroll down to show the result card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });

      // Save to history with fallback advice first
      final entryId = DateTime.now().millisecondsSinceEpoch.toString();
      final entry = DecisionHistoryEntry(
        id: entryId,
        userId: profile.id,
        decisionText: question,
        category: _selectedCategory,
        targetDate: _targetDate.toIso8601String().split('T').first,
        score: result['score'] as int,
        riskLevel: result['riskLevel'] as String,
        luckyNumber: result['luckyNumber'] as int,
        bestWindow: bestWindow,
        scoresJson: jsonEncode(systemScores),
        advice: fallbackAdvice,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.instance.saveDecisionHistory(entry);
      _loadHistory();

      // Now fetch AI advice in the background (replaces advice text when ready)
      final archetype = ArchetypeEngine.archetypes[profile.archetypeId.clamp(0, 11)];
      final archetypeName = archetype['name'] as String;

      final aiAdvice = await AiAdviceService.generateAdvice(
        question: question,
        category: _categories[_selectedCategory] ?? 'General',
        score: result['score'] as int,
        riskLevel: result['riskLevel'] as String,
        moonPhase: result['moonPhase'] as String,
        personalDay: 0, // not exposed to UI, pass 0
        dasaPlanet: '',
        archetypeName: archetypeName,
        bestWindow: bestWindow,
        luckyColor: result['luckyColor'] as String,
        luckyDirection: result['luckyDirection'] as String,
        luckyNumber: result['luckyNumber'] as int,
        systemScores: systemScores,
        fallbackAdvice: fallbackAdvice,
      );

      if (mounted && aiAdvice.isNotEmpty && aiAdvice != fallbackAdvice) {
        setState(() {
          _result!['advice'] = aiAdvice;
          _isLoadingAiAdvice = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingAiAdvice = false);
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _isLoadingAiAdvice = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cosmic reading failed: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _purpleColor,
              surface: _cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          const StarBackground(),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                title: const Text(
                  'Lucky Decision Engine',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 20,
                    color: _goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),

              // Input section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Question field
                      _buildInputCard(),
                      const SizedBox(height: 12),
                      // Category selector
                      _buildCategorySelector(),
                      const SizedBox(height: 12),
                      // Date picker + consult button row
                      _buildDateAndConsultRow(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Loading indicator
              if (_isCalculating)
                SliverToBoxAdapter(
                  child: _buildLoadingIndicator(),
                ),

              // Result card
              if (_result != null && !_isCalculating)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildResultCard(),
                    ),
                  ),
                ),

              // History section
              if (_history.isNotEmpty && !_isCalculating)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      'Past Decisions',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_history.isNotEmpty && !_isCalculating)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildHistoryTile(_history[index]),
                    childCount: min(_history.length, 10),
                  ),
                ),

              // Bottom spacer
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What decision weighs on your mind?',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Start a business, Propose to Sarah...',
              hintStyle: TextStyle(
                fontFamily: 'Raleway',
                color: Colors.white.withValues(alpha: 0.3),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _purpleColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _purpleColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _goldColor),
              ),
              filled: true,
              fillColor: _scaffoldBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.entries.map((e) {
          final isSelected = _selectedCategory == e.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _purpleColor.withValues(alpha: 0.3)
                    : _scaffoldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _goldColor
                      : _purpleColor.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[e.key],
                    size: 16,
                    color: isSelected ? _goldColor : Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: isSelected ? _goldColor : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateAndConsultRow() {
    final isToday = _targetDate.year == DateTime.now().year &&
        _targetDate.month == DateTime.now().month &&
        _targetDate.day == DateTime.now().day;
    final dateLabel = isToday
        ? 'Today'
        : '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}';

    return Row(
      children: [
        // Date picker
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _purpleColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: _goldColor),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Consult button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isCalculating ? null : _consultCosmos,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purpleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_fix_high, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isCalculating ? 'Consulting...' : 'Consult the Cosmos',
                  style: const TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: _goldColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reading the cosmic energies...',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final score = _result!['score'] as int;
    final riskLevel = _result!['riskLevel'] as String;
    final bestWindow = _result!['bestWindow'] as String;
    final luckyNumber = _result!['luckyNumber'] as int;
    final luckyColor = _result!['luckyColor'] as String;
    final luckyDirection = _result!['luckyDirection'] as String;
    final systemScores = _result!['systemScores'] as Map<String, int>;
    final advice = _result!['advice'] as String;

    // Score color
    final scoreColor = score >= 75
        ? const Color(0xFF10B981)
        : score >= 50
            ? _goldColor
            : const Color(0xFFEF4444);

    // Risk color
    final riskColor = riskLevel == 'Low'
        ? const Color(0xFF10B981)
        : riskLevel == 'Medium'
            ? _goldColor
            : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _goldColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _purpleColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          const Text(
            'COSMIC VERDICT',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 18,
              color: _goldColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"${_questionController.text.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Score
          Text(
            '$score',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 56,
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: scoreColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _buildStatChip(Icons.schedule, 'Best Window', bestWindow),
              const SizedBox(width: 8),
              _buildStatChip(Icons.tag, 'Lucky #', '$luckyNumber'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(Icons.palette, 'Color', luckyColor),
              const SizedBox(width: 8),
              _buildStatChip(Icons.explore, 'Direction', luckyDirection),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(
                Icons.warning_amber,
                'Risk',
                riskLevel,
                valueColor: riskColor,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                _categoryIcons[_selectedCategory] ?? Icons.auto_fix_high,
                'Category',
                _categories[_selectedCategory] ?? 'General',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // System breakdown
          Container(
            decoration: BoxDecoration(
              color: _scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Breakdown',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildSystemBars(systemScores),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Advice
          Container(
            decoration: BoxDecoration(
              color: _scaffoldBg,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _goldColor.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cosmic Advice',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                    color: _goldColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingAiAdvice)
                  _buildAdviceShimmer()
                else
                  Text(
                    advice,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: _goldColor.withValues(alpha: 0.6),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Channelling cosmic wisdom...',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Shimmer lines
        for (int i = 0; i < 4; i++) ...[
          Container(
            height: 10,
            width: double.infinity,
            margin: EdgeInsets.only(right: i == 3 ? 80 : 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (i < 3) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _scaffoldBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _goldColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: valueColor ?? Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSystemBars(Map<String, int> scores) {
    const systemLabels = <String, String>{
      'Astrology': '♈ Astrology',
      'Numerology': '🔢 Numerology',
      'Chinese Zodiac': '🐉 Chinese',
      'Lunar': '🌙 Lunar',
      'Mahabote': '🔮 Mahabote',
      'Archetype': '🎭 Archetype',
      'Planetary Hours': '⏳ Planetary',
    };

    return scores.entries.map((e) {
      final label = systemLabels[e.key] ?? e.key;
      final val = e.value;
      final barColor = val >= 75
          ? const Color(0xFF10B981)
          : val >= 50
              ? _goldColor
              : const Color(0xFFEF4444);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: barColor,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text(
                '$val',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildHistoryTile(DecisionHistoryEntry entry) {
    final scoreColor = entry.score >= 75
        ? const Color(0xFF10B981)
        : entry.score >= 50
            ? _goldColor
            : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.red),
        ),
        onDismissed: (_) async {
          await DatabaseService.instance.deleteDecisionHistory(entry.id);
          _loadHistory();
        },
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _purpleColor.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.score}',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.decisionText,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_categories[entry.category] ?? entry.category}  •  ${entry.targetDate}',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Risk badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.riskLevel == 'Low'
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : entry.riskLevel == 'Medium'
                          ? _goldColor.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.riskLevel,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 10,
                    color: entry.riskLevel == 'Low'
                        ? const Color(0xFF10B981)
                        : entry.riskLevel == 'Medium'
                            ? _goldColor
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
