import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/services/streak_service.dart';
import 'package:cosmiq_guru/services/notification_service.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/screens/luck_breakdown_screen.dart';
import 'package:cosmiq_guru/screens/wealth_screen.dart';
import 'package:cosmiq_guru/screens/rituals_screen.dart';
import 'package:cosmiq_guru/screens/name_numerology_screen.dart';
import 'package:cosmiq_guru/screens/journal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _luckScore = 0;
  double _relationshipEnergy = 0.0;
  double _moneyEnergy = 0.0;
  double _careerEnergy = 0.0;
  String _decisionWindowText = '';
  String _dailySummary = '';
  String _luckyColor = '';
  String _luckyDirection = '';
  String _profileName = '';
  int _streakCount = 0;
  bool _isReadingExpanded = false;
  bool _isLoading = true;
  bool _showMilestoneCelebration = false;

  late final AnimationController _milestoneController;
  late final Animation<double> _milestoneOpacity;

  @override
  void initState() {
    super.initState();

    _milestoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _milestoneOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _milestoneController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final provider = context.read<UserProfileProvider>();
      final fullName = provider.profile?.fullName ?? '';
      final firstName =
          fullName.isNotEmpty ? fullName.trim().split(' ').first : '';
      final dob = provider.profile?.dateOfBirth ?? '';
      final birthTime = provider.profile?.birthTime ?? '12:00';
      final archetypeId = provider.profile?.archetypeId ?? 0;

      final luckScore = CosmicService.getLuckScore(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      final relationshipEnergy = CosmicService.getRelationshipEnergy(
        dob: dob, fullName: fullName,
      ) / 100.0;
      final moneyEnergy = CosmicService.getMoneyEnergy(
        dob: dob, fullName: fullName,
      ) / 100.0;
      final careerEnergy = CosmicService.getCareerEnergy(
        dob: dob, birthTime: birthTime,
      ) / 100.0;
      final decisionWindowText = CosmicService.getDecisionWindowText();
      final dailySummary = CosmicService.getDailySummary(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      final luckyColor = CosmicService.getLuckyColor(dob: dob, birthTime: birthTime);
      final luckyDirection = CosmicService.getLuckyDirection(dob: dob, birthTime: birthTime);

      final streak = await StreakService.checkAndUpdateStreak();

      await _scheduleNotificationIfEnabled();

      if (!mounted) return;

      setState(() {
        _profileName = firstName.isNotEmpty ? firstName : 'Seeker';
        _luckScore = luckScore;
        _relationshipEnergy = relationshipEnergy;
        _moneyEnergy = moneyEnergy;
        _careerEnergy = careerEnergy;
        _decisionWindowText = decisionWindowText;
        _dailySummary = dailySummary;
        _luckyColor = luckyColor;
        _luckyDirection = luckyDirection;
        _streakCount = streak;
        _isLoading = false;
      });

      _checkMilestoneStreak(streak);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load cosmic readings. Pull to retry.'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  Future<void> _scheduleNotificationIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;
      if (notificationsEnabled) {
        final timeStr = prefs.getString('notification_time') ?? '08:00';
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final notificationTime = TimeOfDay(hour: hour, minute: minute);
        await NotificationService.instance.scheduleDaily(notificationTime);
      }
    } catch (_) {
      // Non-fatal — notifications are optional
    }
  }

  void _checkMilestoneStreak(int streak) {
    if (streak == 7 || streak == 30 || streak == 100) {
      setState(() => _showMilestoneCelebration = true);
      _milestoneController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() => _showMilestoneCelebration = false);
          _milestoneController.reset();
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final provider = context.read<UserProfileProvider>();
      final fullName = provider.profile?.fullName ?? '';
      final dob = provider.profile?.dateOfBirth ?? '';
      final birthTime = provider.profile?.birthTime ?? '12:00';
      final archetypeId = provider.profile?.archetypeId ?? 0;

      final luckScore = CosmicService.getLuckScore(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      final relationshipEnergy = CosmicService.getRelationshipEnergy(
        dob: dob, fullName: fullName,
      ) / 100.0;
      final moneyEnergy = CosmicService.getMoneyEnergy(
        dob: dob, fullName: fullName,
      ) / 100.0;
      final careerEnergy = CosmicService.getCareerEnergy(
        dob: dob, birthTime: birthTime,
      ) / 100.0;
      final decisionWindowText = CosmicService.getDecisionWindowText();
      final dailySummary = CosmicService.getDailySummary(
        dob: dob, birthTime: birthTime, fullName: fullName, archetypeId: archetypeId,
      );
      final luckyColor = CosmicService.getLuckyColor(dob: dob, birthTime: birthTime);
      final luckyDirection = CosmicService.getLuckyDirection(dob: dob, birthTime: birthTime);

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _luckScore = luckScore;
        _relationshipEnergy = relationshipEnergy;
        _moneyEnergy = moneyEnergy;
        _careerEnergy = careerEnergy;
        _decisionWindowText = decisionWindowText;
        _dailySummary = dailySummary;
        _luckyColor = luckyColor;
        _luckyDirection = luckyDirection;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh readings. Try again.'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  void _navigateToBreakdown() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LuckBreakdownScreen()),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  void _showEnergyBottomSheet({
    required String title,
    required String explanation,
    required Color color,
    required String emoji,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1025),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                explanation,
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
                    'Got it',
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
  }

  void _shareCosmicCard() {
    final timeOfDay = _getTimeOfDay();
    final text = '''✨ My cosmiq.guru Reading for Today

Good $timeOfDay! Here's my cosmic forecast:

🔮 Luck Score: $_luckScore/100
💜 Relationship Energy: ${(_relationshipEnergy * 100).round()}%
💰 Money Energy: ${(_moneyEnergy * 100).round()}%
🚀 Career Energy: ${(_careerEnergy * 100).round()}%

⏰ Best Decision Window: $_decisionWindowText
🎨 Lucky Color: $_luckyColor
🧭 Lucky Direction: $_luckyDirection
🔥 Current Streak: $_streakCount days

$_dailySummary

Discover your cosmic blueprint at cosmiq.guru''';

    Share.share(text, subject: 'My cosmiq.guru Daily Reading');
  }

  Widget _buildShimmerPlaceholder({
    double width = double.infinity,
    double height = 80,
    double borderRadius = 16,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1025),
            Color(0xFF241538),
            Color(0xFF1A1025),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildDecisionWindowCard() {
    if (_isLoading) {
      return _buildShimmerPlaceholder(height: 100);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEST DECISION WINDOW',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _decisionWindowText,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMeters() {
    if (_isLoading) {
      return _buildShimmerPlaceholder(height: 140);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENERGY METERS',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 10,
              color: Colors.white54,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildEnergyRow(
            label: 'Relationship',
            emoji: '💜',
            value: _relationshipEnergy,
            color: const Color(0xFF7C3AED),
            explanation:
                'Your relationship energy reflects the cosmic alignment of Venus and your natal chart today. High energy favors deep connections, heartfelt conversations, and romantic encounters.',
          ),
          const SizedBox(height: 12),
          _buildEnergyRow(
            label: 'Money',
            emoji: '💰',
            value: _moneyEnergy,
            color: const Color(0xFFF59E0B),
            explanation:
                'Your money energy is influenced by Jupiter\'s position and your numerological personal year. Strong energy indicates favorable timing for financial decisions and investments.',
          ),
          const SizedBox(height: 12),
          _buildEnergyRow(
            label: 'Career',
            emoji: '🚀',
            value: _careerEnergy,
            color: const Color(0xFF10B981),
            explanation:
                'Career energy reflects Mars\' influence and your Mahabote house position. Elevated energy supports bold professional moves, negotiations, and leadership opportunities.',
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyRow({
    required String label,
    required String emoji,
    required double value,
    required Color color,
    required String explanation,
  }) {
    final percent = (value * 100).round();
    return GestureDetector(
      onTap: () => _showEnergyBottomSheet(
        title: label,
        explanation: explanation,
        color: color,
        emoji: emoji,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$percent%',
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Explore →',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReadingCard() {
    if (_isLoading) {
      return _buildShimmerPlaceholder(height: 120);
    }

    final words = _dailySummary.split(' ');
    final shortText = words.take(20).join(' ') + (words.length > 20 ? '...' : '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'DAILY READING',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 10,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _shareCosmicCard,
                child: const Icon(
                  Icons.ios_share,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              shortText,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              _dailySummary,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            crossFadeState: _isReadingExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _isReadingExpanded = !_isReadingExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isReadingExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isReadingExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF7C3AED),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyDetailsCard() {
    if (_isLoading) {
      return _buildShimmerPlaceholder(height: 80);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🎨',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lucky Color',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _luckyColor,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.white12,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🧭',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lucky Direction',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _luckyDirection,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCelebration() {
    return AnimatedBuilder(
      animation: _milestoneOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _milestoneOpacity.value,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🌟',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_streakCount Day Streak!',
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 28,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cosmic milestone achieved! ✨',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF7C3AED),
            backgroundColor: const Color(0xFF1A1025),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF0D0618),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A0A2E),
                            Color(0xFF0D0618),
                          ],
                        ),
                      ),
                    ),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getTimeOfDay()}, $_profileName',
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_streakCount > 0)
                          Text(
                            '🔥 $_streakCount day streak',
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Luck Score Gauge
                      GestureDetector(
                        onTap: _navigateToBreakdown,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1025),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TODAY\'S LUCK SCORE',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: Colors.white54,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _isLoading
                                  ? _buildShimmerPlaceholder(
                                      width: 200, height: 200, borderRadius: 100)
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 180,
                                          height: 180,
                                          child: CircularProgressIndicator(
                                            value: _luckScore / 100.0,
                                            strokeWidth: 12,
                                            backgroundColor:
                                                Colors.white.withValues(alpha: 0.1),
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$_luckScore',
                                              style: const TextStyle(
                                                fontFamily: 'Cinzel',
                                                fontSize: 48,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const Text(
                                              'out of 100',
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
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to see full breakdown →',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Decision Window Card
                      _buildDecisionWindowCard(),
                      const SizedBox(height: 16),

                      // Energy Meters
                      _buildEnergyMeters(),
                      const SizedBox(height: 16),

                      // Lucky Details
                      _buildLuckyDetailsCard(),
                      const SizedBox(height: 16),

                      // Phase 2B Quick Access Cards
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildQuickAccessCard(
                                emoji: '💰',
                                title: 'Money Mode',
                                subtitle: 'Lucky numbers & timing',
                                color: const Color(0xFFF59E0B),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WealthScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAccessCard(
                                emoji: '🔮',
                                title: 'Rituals',
                                subtitle: 'Cosmic calendar',
                                color: const Color(0xFF7C3AED),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RitualsScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phase 2C & 2D Quick Access Cards
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildQuickAccessCard(
                                emoji: '🔤',
                                title: 'Name Scorer',
                                subtitle: 'Baby & business names',
                                color: const Color(0xFF3B82F6),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NameNumerologyScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAccessCard(
                                emoji: '📓',
                                title: 'Journal',
                                subtitle: 'Mood & cosmic log',
                                color: const Color(0xFF10B981),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const JournalScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily Reading Card
                      _buildDailyReadingCard(),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Milestone celebration overlay
          if (_showMilestoneCelebration)
            Positioned.fill(
              child: _buildMilestoneCelebration(),
            ),
        ],
      ),
    );
  }
}
