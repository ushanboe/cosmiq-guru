// Step 1: Inventory
// This file DEFINES:
//   - CompatibilityScreen (StatefulWidget)
//   - _CompatibilityScreenState with all state variables
//   - _buildInputCard() — text field card
//   - _buildTapCard() — tappable card for DOB/time
//   - _buildResults() — list of widgets: score circle + 5 system cards + share button
//   - _buildPastResultCard() — compact past result card
//   - _pickPartnerDob() — showDatePicker
//   - _pickPartnerTime() — showTimePicker
//   - _calculate() — CosmicService call + DB save + reload
//   - _shareResults() — screenshot capture + share_plus
//   - _updateCanCalculate() — checks all fields filled
//
// This file USES from other files:
//   - StarBackground from package:cosmiq_guru/widgets/star_background.dart
//   - DatabaseService, CompatibilityResult from package:cosmiq_guru/services/database_service.dart
//   - CosmicService from package:cosmiq_guru/services/cosmic_service.dart
//   - UserProfileProvider from package:cosmiq_guru/providers/user_profile_provider.dart
//   - screenshot package: ScreenshotController
//   - share_plus package: SharePlus, XFile
//   - uuid package for generating IDs
//   - dart:io for temp file writing
//   - path_provider for temp directory
//
// Step 2: Connections
// - MainShell renders CompatibilityScreen at IndexedStack index 2 (Match tab)
// - initState: load _pastResults from DatabaseService.instance.getCompatibilityResults(userId)
// - Calculate button: CosmicService.getCompatibilityScores(partnerName, partnerDob, partnerTime)
// - After calc: DatabaseService.instance.saveCompatibilityResult(result), reload _pastResults
// - Share button: screenshot _shareKey widget, SharePlus.instance.share(XFile(path))
// - userId: read from UserProfileProvider via context.read<UserProfileProvider>().profile?.id
//   BUT we're using setState not Riverpod — use Provider package context.read
//   Actually the project uses ChangeNotifierProvider (from provider package per wiring manifest)
//   So context.read<UserProfileProvider>() is correct here (Provider package, not Riverpod)
//
// Step 3: User Journey Trace
// - User lands on CompatibilityScreen (via MainShell IndexedStack)
// - initState loads past results from DB
// - User types partner name → _updateCanCalculate()
// - User taps DOB card → showDatePicker → setState _partnerDob, _partnerDobDisplay
// - User taps Time card → showTimePicker → setState _partnerTime, _partnerTimeDisplay
// - All 3 filled → _canCalculate = true → Calculate button enabled
// - User taps Calculate → _isCalculating = true → Future.delayed(2s) → CosmicService.getCompatibilityScores()
//   → setState scores → _showResults = true → save to DB → reload past results
// - User taps Share → screenshot widget → write to temp file → SharePlus.instance.share()
// - Past results shown below with compact cards
//
// Step 4: Layout Sanity
// - CustomScrollView inside Stack — correct (StarBackground fills Stack, CustomScrollView scrolls)
// - No unbounded ListView inside Column — using .map().toList() to generate list items inline
// - All TextEditingControllers disposed in dispose()
// - _shareKey is a GlobalKey for the Screenshot widget
// - ScreenshotController from screenshot package
// - SharePlus.instance.share(XFile(path)) — correct API for share_plus 10.x
// - DatabaseService.getCompatibilityResults() requires userId — use profile?.id ?? 'default'
// - CosmicService.getCompatibilityScores() takes (partnerName, partnerDob, partnerTime) as Strings
// - CompatibilityResult constructor: id, userId, partnerName, partnerDob, partnerBirthTime,
//   overallScore, scoresJson, narrativeSummary, createdAt
// - scoresJson: jsonEncode the scores map from CosmicService result
// - uuid: use const Uuid().v4() for generating IDs
// - path_provider: getTemporaryDirectory()
// - Score circle color: red if <40, yellow if 40-70, green if >70
// - 5 system score cards from _systemScores list
// - Share button: gold background ElevatedButton

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final TextEditingController _partnerNameController = TextEditingController();
  DateTime? _partnerDob;
  TimeOfDay? _partnerTime;
  String _partnerDobDisplay = 'Tap to select';
  String _partnerTimeDisplay = 'Tap to select';
  bool _canCalculate = false;
  bool _isCalculating = false;
  bool _showResults = false;
  int _overallScore = 0;
  List<Map<String, dynamic>> _systemScores = [];
  List<CompatibilityResult> _pastResults = [];

  // Business mode state
  bool _isBusinessMode = false;
  String _partnershipType = 'partner';
  static const _partnershipTypes = [
    {'id': 'cofounder', 'label': 'Co-Founder', 'emoji': '🤝'},
    {'id': 'employee', 'label': 'Employee', 'emoji': '👤'},
    {'id': 'partner', 'label': 'Partner', 'emoji': '🏢'},
    {'id': 'investor', 'label': 'Investor', 'emoji': '💰'},
  ];

  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _partnerNameController.addListener(_updateCanCalculate);
    _loadPastResults();
  }

  @override
  void dispose() {
    _partnerNameController.removeListener(_updateCanCalculate);
    _partnerNameController.dispose();
    super.dispose();
  }

  void _updateCanCalculate() {
    setState(() {
      _canCalculate = _partnerNameController.text.trim().isNotEmpty &&
          _partnerDob != null &&
          _partnerTime != null;
    });
  }

  Future<void> _loadPastResults() async {
    final profile = context.read<UserProfileProvider>().profile;
    final userId = profile?.id ?? 'default';
    try {
      final results =
          await DatabaseService.instance.getCompatibilityResults(userId);
      setState(() {
        _pastResults = results;
      });
    } catch (_) {
      // DB not yet initialized or empty — silently ignore
    }
  }

  Future<void> _pickPartnerDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1025),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _partnerDob = picked;
        _partnerDobDisplay =
            '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
      });
      _updateCanCalculate();
    }
  }

  Future<void> _pickPartnerTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1025),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _partnerTime = picked;
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        _partnerTimeDisplay = '$hour:$minute';
      });
      _updateCanCalculate();
    }
  }

  Future<void> _calculate() async {
    setState(() {
      _isCalculating = true;
      _showResults = false;
    });

    // Simulate calculation delay
    await Future.delayed(const Duration(seconds: 2));

    final partnerName = _partnerNameController.text.trim();
    final dobStr = _partnerDobDisplay;
    final timeStr = _partnerTimeDisplay;

    final profile = context.read<UserProfileProvider>().profile;
    final userDob = profile?.dateOfBirth ?? '';
    final userBirthTime = profile?.birthTime ?? '12:00';
    final userFullName = profile?.fullName ?? '';

    // Format partner DOB as ISO string for engine parsing
    final partnerDobIso = _partnerDob != null
        ? '${_partnerDob!.year}-${_partnerDob!.month.toString().padLeft(2, '0')}-${_partnerDob!.day.toString().padLeft(2, '0')}'
        : '';

    final Map<String, dynamic> scores;
    if (_isBusinessMode) {
      scores = CosmicService.getBusinessCompatibility(
        partnerName,
        partnerDobIso,
        timeStr,
        userDob: userDob,
        userBirthTime: userBirthTime,
        userFullName: userFullName,
        userArchetypeId: profile?.archetypeId ?? 0,
        partnershipType: _partnershipType,
      );
    } else {
      scores = CosmicService.getCompatibilityScores(
        partnerName,
        partnerDobIso,
        timeStr,
        userDob: userDob,
        userBirthTime: userBirthTime,
        userFullName: userFullName,
      );
    }

    final overallScore = scores['overallScore'] as int;
    final narrativeSummary = scores['narrativeSummary'] as String;

    // Build scoresJson from scores map
    final scoresMap = (scores['scores'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );

    final userId = profile?.id ?? 'default';

    final result = CompatibilityResult(
      id: const Uuid().v4(),
      userId: userId,
      partnerName: partnerName,
      partnerDob: dobStr,
      partnerBirthTime: timeStr,
      overallScore: overallScore,
      scoresJson: jsonEncode(scoresMap),
      narrativeSummary: narrativeSummary,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Build system scores list for display
    final systemDetailTexts = scores['systemDetails'] as Map<String, dynamic>;
    final systemScoresList = <Map<String, dynamic>>[];
    final systemEmojis = _isBusinessMode
        ? {'expression': '🔢', 'lifePath': '🛤️', 'chinese': '🐉', 'mahabote': '🇲🇲', 'archetype': '🎭'}
        : {'astrology': '♈', 'numerology': '🔢', 'chinese': '🐉', 'mahabote': '🇲🇲', 'lunar': '🌙'};
    final systemLabels = _isBusinessMode
        ? {'expression': 'Expression Numbers', 'lifePath': 'Life Path', 'chinese': 'Chinese Zodiac', 'mahabote': 'Mahabote', 'archetype': 'Archetype'}
        : {'astrology': 'Astrology', 'numerology': 'Numerology', 'chinese': 'Chinese Zodiac', 'mahabote': 'Mahabote', 'lunar': 'Lunar Phase'};
    scoresMap.forEach((system, score) {
      systemScoresList.add({
        'system': systemLabels[system] ?? system,
        'emoji': systemEmojis[system] ?? '✨',
        'score': score,
        'description': systemDetailTexts[system] ?? '',
      });
    });

    setState(() {
      _overallScore = overallScore;
      _systemScores = systemScoresList;
      _showResults = true;
      _isCalculating = false;
    });

    try {
      await DatabaseService.instance.saveCompatibilityResult(result);
      await _loadPastResults();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save result'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    }
  }

  Future<void> _shareResults() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/compatibility_result.png');
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'My compatibility with ${_partnerNameController.text.trim()} is $_overallScore% — powered by cosmiq.guru ✨',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share result'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    }
  }

  Color _scoreColor(int score) {
    if (score < 40) return const Color(0xFFEF4444);
    if (score <= 70) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Raleway',
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white54,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTapCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final bool isSelected = value != 'Tap to select';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.7)
                : const Color(0xFF7C3AED).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    color: isSelected ? Colors.white : Colors.white38,
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults() {
    return [
      const SizedBox(height: 32),
      // Score circle
      Screenshot(
        controller: _screenshotController,
        child: Container(
          key: _shareKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1025),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                '${_isBusinessMode ? 'Business Fit' : 'Compatibility'} with ${_partnerNameController.text.trim()}',
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Large score circle
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _overallScore / 100.0,
                          strokeWidth: 8,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _scoreColor(_overallScore),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_overallScore%',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(_overallScore),
                            ),
                          ),
                          const Text(
                            'Match',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 5 system score cards
              ...(_systemScores.map((system) {
                final systemName = system['system'] as String;
                final emoji = system['emoji'] as String;
                final score = system['score'] as int;
                final description = system['description'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241538),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _scoreColor(score).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              systemName,
                              style: const TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _scoreColor(score)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _scoreColor(score)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              '$score/100',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _scoreColor(score),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Share button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _shareResults,
          icon: const Icon(Icons.share, color: Colors.black, size: 18),
          label: const Text(
            'Share Result ✨',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildPastResultCard(CompatibilityResult result) {
    final date = DateTime.tryParse(result.createdAt);
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : result.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _scoreColor(result.overallScore).withValues(alpha: 0.15),
              border: Border.all(
                color: _scoreColor(result.overallScore).withValues(alpha: 0.6),
              ),
            ),
            child: Center(
              child: Text(
                '${result.overallScore}%',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _scoreColor(result.overallScore),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.partnerName,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.partnerDob,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: Colors.white38,
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
          'Compatibility',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                      // Mode toggle: Romantic | Business
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1025),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isBusinessMode = false;
                                  _showResults = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isBusinessMode
                                        ? const Color(0xFF7C3AED)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '❤️ Romantic',
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !_isBusinessMode
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isBusinessMode = true;
                                  _showResults = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isBusinessMode
                                        ? const Color(0xFFF59E0B)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '💼 Business',
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isBusinessMode
                                            ? Colors.black
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _isBusinessMode ? 'Enter Person Details' : 'Enter Partner Details',
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _isBusinessMode
                              ? 'Evaluate cosmic business compatibility'
                              : 'Discover your cosmic compatibility across all divination systems',
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_isBusinessMode) ...[
                        const SizedBox(height: 16),
                        // Partnership type selector
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _partnershipTypes.map((pt) {
                            final isSelected = _partnershipType == pt['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _partnershipType = pt['id'] as String),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                      : const Color(0xFF1A1025),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${pt['emoji']} ${pt['label']}',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? const Color(0xFFF59E0B) : Colors.white54,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildInputCard(
                        icon: _isBusinessMode ? Icons.business : Icons.person,
                        label: _isBusinessMode ? 'Person Name' : 'Partner Name',
                        controller: _partnerNameController,
                      ),
                      const SizedBox(height: 12),
                      _buildTapCard(
                        icon: Icons.calendar_today,
                        label: 'Date of Birth',
                        value: _partnerDobDisplay,
                        onTap: _pickPartnerDob,
                      ),
                      const SizedBox(height: 12),
                      _buildTapCard(
                        icon: Icons.access_time,
                        label: 'Birth Time',
                        value: _partnerTimeDisplay,
                        onTap: _pickPartnerTime,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canCalculate ? _calculate : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            disabledBackgroundColor:
                                const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isCalculating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isBusinessMode ? 'Analyze Business Fit 💼' : 'Calculate Compatibility ✨',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (_showResults) ..._buildResults(),
                      const SizedBox(height: 32),
                      const Text(
                        'Past Readings',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_pastResults.isEmpty)
                        const Text(
                          'No past readings yet',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        )
                      else
                        ..._pastResults.map(
                          (r) => _buildPastResultCard(r),
                        ),
                      const SizedBox(height: 40),
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