import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/engines/name_engine.dart';
import 'package:cosmiq_guru/engines/numerology_engine.dart';

class NameNumerologyScreen extends StatefulWidget {
  const NameNumerologyScreen({super.key});

  @override
  State<NameNumerologyScreen> createState() => _NameNumerologyScreenState();
}

class _NameNumerologyScreenState extends State<NameNumerologyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Name Scorer state
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _nameResult;

  // Baby Names state
  final TextEditingController _surnameController = TextEditingController();
  String _babyGender = 'all';
  String _babyOrigin = '';
  List<Map<String, dynamic>> _babyResults = [];
  bool _showBabyResults = false;

  // Business Name state
  final TextEditingController _bizNameController = TextEditingController();
  Map<String, dynamic>? _bizResult;

  int _userLifePath = 1;
  DateTime _userDob = DateTime(2000);
  String _userFullName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserProfileProvider>().profile;
      final dobStr = profile?.dateOfBirth ?? '2000-01-01';
      _userDob = DateTime.tryParse(dobStr) ?? DateTime(2000);
      _userFullName = profile?.fullName ?? '';
      _userLifePath = NumerologyEngine.lifePathNumber(_userDob);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _bizNameController.dispose();
    super.dispose();
  }

  void _scoreName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _nameResult = NameEngine.scoreName(name, _userLifePath);
    });
  }

  void _generateBabyNames() {
    final surname = _surnameController.text.trim();
    if (surname.isEmpty) return;
    final gender = _babyGender == 'all' ? null : _babyGender;
    final origin = _babyOrigin.isEmpty ? null : _babyOrigin;
    setState(() {
      _babyResults = NameEngine.generateBabyNames(
        surname: surname,
        parentDob1: _userDob,
        gender: gender,
        origin: origin,
      );
      _showBabyResults = true;
    });
  }

  void _scoreBusinessName() {
    final name = _bizNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _bizResult = NameEngine.scoreBusinessName(
        businessName: name,
        ownerDob: _userDob,
        ownerName: _userFullName,
      );
    });
  }

  Color _scoreColor(int score) {
    if (score < 40) return const Color(0xFFEF4444);
    if (score <= 70) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget _buildCard({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (borderColor ?? const Color(0xFF7C3AED)).withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }

  Widget _buildNumberBadge(String label, int number, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 10,
            color: Colors.white54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Tab 1: Name Scorer ──

  Widget _buildNameScorerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score Any Name',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Life Path: $_userLifePath',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF241538),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.text_fields, color: Color(0xFF7C3AED), size: 20),
                      hintText: 'Enter a name (person, business, etc.)',
                      hintStyle: TextStyle(fontFamily: 'Raleway', color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _scoreName(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scoreName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Score Name ✨',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_nameResult != null) ...[
            const SizedBox(height: 16),
            _buildNameResultCard(_nameResult!),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNameResultCard(Map<String, dynamic> result) {
    final score = result['score'] as int;
    final expr = result['expressionNumber'] as int;
    final soul = result['soulUrge'] as int;
    final personality = result['personality'] as int;
    final compat = result['compatibility'] as String;

    return _buildCard(
      borderColor: _scoreColor(score),
      child: Column(
        children: [
          // Score circle
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor(score),
                      ),
                    ),
                    const Text(
                      'Alignment',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Number badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberBadge('Expression', expr, const Color(0xFF7C3AED)),
              _buildNumberBadge('Soul Urge', soul, const Color(0xFFF59E0B)),
              _buildNumberBadge('Personality', personality, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            compat,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Baby Names ──

  Widget _buildBabyNamesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Baby Name Generator',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find names cosmically aligned with the parents',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                // Surname input
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF241538),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextField(
                    controller: _surnameController,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.family_restroom, color: Color(0xFF7C3AED), size: 20),
                      hintText: 'Family surname',
                      hintStyle: TextStyle(fontFamily: 'Raleway', color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Gender filter
                Row(
                  children: [
                    const Text(
                      'Gender:',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...['all', 'male', 'female', 'neutral'].map((g) {
                      final isSelected = _babyGender == g;
                      final labels = {'all': 'All', 'male': '♂', 'female': '♀', 'neutral': '⚧'};
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _babyGender = g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              labels[g]!,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                // Origin filter
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF241538),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextField(
                    onChanged: (v) => _babyOrigin = v,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.language, color: Color(0xFF7C3AED), size: 20),
                      hintText: 'Origin filter (e.g., Greek, Hebrew)',
                      hintStyle: TextStyle(fontFamily: 'Raleway', color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateBabyNames,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Find Cosmic Names 🌟',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showBabyResults && _babyResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'TOP COSMIC MATCHES',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_babyResults.length, (i) {
              final baby = _babyResults[i];
              final score = baby['score'] as int;
              final firstName = baby['name'] as String;
              final meaning = baby['meaning'] as String;
              final origin = baby['origin'] as String;
              final expr = baby['expressionNumber'] as int;
              final gender = baby['gender'] as String;
              final genderEmoji = gender == 'male' ? '♂' : gender == 'female' ? '♀' : '⚧';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1025),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _scoreColor(score).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 3
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: i < 3 ? const Color(0xFFF59E0B) : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                firstName,
                                style: const TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                genderEmoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$meaning · $origin · Expr: $expr',
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _scoreColor(score).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _scoreColor(score).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(score),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Tab 3: Business Name ──

  Widget _buildBusinessNameTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Name Scorer',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Life Path: $_userLifePath · Expression: ${NumerologyEngine.expressionNumber(_userFullName)}',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF241538),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextField(
                    controller: _bizNameController,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.business, color: Color(0xFFF59E0B), size: 20),
                      hintText: 'Enter business name',
                      hintStyle: TextStyle(fontFamily: 'Raleway', color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _scoreBusinessName(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scoreBusinessName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Score Business Name 💼',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_bizResult != null) ...[
            const SizedBox(height: 16),
            _buildBusinessResultCard(_bizResult!),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBusinessResultCard(Map<String, dynamic> result) {
    final score = result['score'] as int;
    final expr = result['expressionNumber'] as int;
    final soulUrge = result['soulUrge'] as int;
    final advice = result['advice'] as String;
    final luckyPricing = (result['luckyPricing'] as List).cast<int>();
    final launchDays = (result['luckyLaunchDays'] as List).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score + numbers card
        _buildCard(
          borderColor: _scoreColor(score),
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(score),
                          ),
                        ),
                        const Text(
                          'Business Fit',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumberBadge('Expression', expr, const Color(0xFFF59E0B)),
                  _buildNumberBadge('Soul Urge', soulUrge, const Color(0xFF7C3AED)),
                  _buildNumberBadge('Life Path', result['ownerLifePath'] as int, const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                advice,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Lucky pricing
        if (luckyPricing.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCard(
            borderColor: const Color(0xFFF59E0B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LUCKY PRICING',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Price points aligned with your business vibration',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: luckyPricing.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '\$$p',
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],

        // Lucky launch days
        if (launchDays.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCard(
            borderColor: const Color(0xFF10B981),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEST LAUNCH DAYS',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Top days to launch within the next 30 days',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 12),
                ...launchDays.map((day) {
                  final date = day['date'] as DateTime;
                  final dayScore = day['score'] as int;
                  final moonEmoji = day['moonEmoji'] as String;
                  final reason = day['reason'] as String;
                  final dateStr = '${_weekdayName(date.weekday)}, ${date.day}/${date.month}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF241538),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(moonEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                reason,
                                style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$dayScore',
                            style: const TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Name Numerology',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Score'),
            Tab(text: 'Baby Names'),
            Tab(text: 'Business'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const StarBackground(),
          TabBarView(
            controller: _tabController,
            children: [
              _buildNameScorerTab(),
              _buildBabyNamesTab(),
              _buildBusinessNameTab(),
            ],
          ),
        ],
      ),
    );
  }
}
