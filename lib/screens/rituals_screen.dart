import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/engines/ritual_engine.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';

class RitualsScreen extends StatefulWidget {
  const RitualsScreen({super.key});

  @override
  State<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends State<RitualsScreen> {
  static const _scaffoldBg = Color(0xFF0F0A1A);
  static const _cardBg = Color(0xFF1A1025);
  static const _purpleAccent = Color(0xFF7C3AED);
  static const _goldColor = Color(0xFFF59E0B);

  Map<String, dynamic> _todayRitual = {};
  List<Map<String, dynamic>> _monthCalendar = [];
  List<Map<String, dynamic>> _upcomingDates = [];
  int _displayMonth = DateTime.now().month;
  int _displayYear = DateTime.now().year;
  bool _isLoading = true;

  DateTime _dob = DateTime(2000, 1, 1);
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    try {
      final profile = context.read<UserProfileProvider>().profile;
      _dob = DateTime.tryParse(profile?.dateOfBirth ?? '') ?? DateTime(2000, 1, 1);
      _fullName = profile?.fullName ?? '';

      final todayRitual = RitualEngine.todayRitual(_dob, _fullName);
      final monthCalendar = RitualEngine.monthCalendar(_dob, _fullName, _displayMonth, _displayYear);
      final upcomingDates = RitualEngine.upcomingDates(_dob);

      if (!mounted) return;
      setState(() {
        _todayRitual = todayRitual;
        _monthCalendar = monthCalendar;
        _upcomingDates = upcomingDates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayMonth += delta;
      if (_displayMonth > 12) {
        _displayMonth = 1;
        _displayYear++;
      } else if (_displayMonth < 1) {
        _displayMonth = 12;
        _displayYear--;
      }
      _monthCalendar = RitualEngine.monthCalendar(_dob, _fullName, _displayMonth, _displayYear);
    });
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
          'Cosmic Rituals',
          style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          const StarBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _purpleAccent))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTodayRitualCard(),
                            const SizedBox(height: 16),
                            _buildRitualCalendar(),
                            const SizedBox(height: 16),
                            _buildLegend(),
                            const SizedBox(height: 16),
                            _buildUpcomingDatesCard(),
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

  Widget _buildCard({required Widget child, Color borderColor = _purpleAccent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildTodayRitualCard() {
    final label = _todayRitual['label'] as String? ?? '';
    final emoji = _todayRitual['emoji'] as String? ?? '⚪';
    final colorHex = _todayRitual['colorHex'] as int? ?? 0xFF6B7280;
    final score = _todayRitual['score'] as int? ?? 50;
    final suggestion = _todayRitual['suggestion'] as String? ?? '';
    final explanation = _todayRitual['explanation'] as String? ?? '';
    final moonEmoji = _todayRitual['moonEmoji'] as String? ?? '🌙';
    final moonPhase = _todayRitual['moonPhase'] as String? ?? '';
    final personalDay = _todayRitual['personalDay'] as int? ?? 0;
    final isVoc = _todayRitual['isVoidOfCourse'] as bool? ?? false;
    final color = Color(colorHex);

    return _buildCard(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY\'S RITUAL',
                style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 10, color: Colors.white54,
                  letterSpacing: 1.5, fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isVoc)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Void of Course', style: TextStyle(fontFamily: 'Raleway', fontSize: 9, color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Hero section
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$moonEmoji $moonPhase', style: const TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54)),
                        const SizedBox(width: 12),
                        Text('Day $personalDay', style: const TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('$score', style: TextStyle(fontFamily: 'Cinzel', fontSize: 22, color: color, fontWeight: FontWeight.bold)),
                  const Text('/100', style: TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Suggestion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('✨ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(fontFamily: 'Raleway', fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualCalendar() {
    const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // First day of month (1=Mon, 7=Sun)
    final firstDay = DateTime(_displayYear, _displayMonth, 1).weekday;
    final daysInMonth = _monthCalendar.length;

    return _buildCard(
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: () => _changeMonth(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${monthNames[_displayMonth]} $_displayYear',
                style: const TextStyle(fontFamily: 'Cinzel', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: () => _changeMonth(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday headers
          Row(
            children: weekDays.map((d) => Expanded(
              child: Center(
                child: Text(d, style: const TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (dow) {
                  final dayIndex = week * 7 + dow - (firstDay - 1);
                  if (dayIndex < 0 || dayIndex >= daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }
                  final dayData = _monthCalendar[dayIndex];
                  final dayNum = dayData['day'] as int;
                  final colorHex = dayData['colorHex'] as int;
                  final moonEmoji = dayData['moonEmoji'] as String;
                  final color = Color(colorHex);
                  final isToday = dayNum == DateTime.now().day &&
                      _displayMonth == DateTime.now().month &&
                      _displayYear == DateTime.now().year;
                  final isSpecialMoon = dayData['moonPhase'] == 'New Moon' || dayData['moonPhase'] == 'Full Moon';

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showDayDetail(dayData),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isToday
                              ? color.withValues(alpha: 0.3)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: _goldColor, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: isToday ? _goldColor : color,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            if (isSpecialMoon)
                              Text(moonEmoji, style: const TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDayDetail(Map<String, dynamic> dayData) {
    final dayNum = dayData['day'] as int;
    final label = dayData['label'] as String;
    final emoji = dayData['emoji'] as String;
    final colorHex = dayData['colorHex'] as int;
    final score = dayData['score'] as int;
    final moonPhase = dayData['moonPhase'] as String;
    final moonEmoji = dayData['moonEmoji'] as String;
    final personalDay = dayData['personalDay'] as int;
    final color = Color(colorHex);

    final date = DateTime(_displayYear, _displayMonth, dayNum);
    final ritual = RitualEngine.todayRitual(_dob, _fullName, date: date);
    final suggestion = ritual['suggestion'] as String? ?? '';
    final explanation = ritual['explanation'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label Day — ${_monthName(_displayMonth)} $dayNum',
                          style: TextStyle(fontFamily: 'Cinzel', fontSize: 16, color: color, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$moonEmoji $moonPhase • Day $personalDay • Score $score/100',
                          style: const TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(suggestion, style: TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                explanation,
                style: TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontFamily: 'Raleway', fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    final types = ['start', 'end', 'cleanse', 'reflect'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: types.map((type) {
        final data = RitualEngine.ritualTypes[type]!;
        final emoji = data['emoji'] as String;
        final label = data['label'] as String;
        final colorHex = data['colorHex'] as int;
        final color = Color(colorHex);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 4),
            Text(
              '$emoji $label',
              style: const TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white54),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingDatesCard() {
    return _buildCard(
      borderColor: _goldColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPCOMING KEY DATES',
            style: TextStyle(fontFamily: 'Raleway', fontSize: 10, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._upcomingDates.map((event) {
            final emoji = event['emoji'] as String;
            final eventName = event['event'] as String;
            final description = event['description'] as String;
            final daysAway = event['daysAway'] as int;
            final date = event['date'] as DateTime;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              eventName,
                              style: const TextStyle(fontFamily: 'Cinzel', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _goldColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daysAway == 0 ? 'Today' : daysAway == 1 ? 'Tomorrow' : 'in $daysAway days',
                                style: const TextStyle(fontFamily: 'Raleway', fontSize: 10, color: _goldColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_monthName(date.month)} ${date.day}',
                          style: const TextStyle(fontFamily: 'Raleway', fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white.withValues(alpha: 0.6), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month.clamp(1, 12)];
  }
}
