import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/services/cosmic_service.dart';
import 'package:cosmiq_guru/engines/lunar_engine.dart';

class LunarScreen extends StatefulWidget {
  const LunarScreen({super.key});

  @override
  State<LunarScreen> createState() => _LunarScreenState();
}

class _LunarScreenState extends State<LunarScreen> {
  String _moonPhaseEmoji = '🌔';
  String _moonPhaseName = 'Waxing Gibbous';
  String _moonSign = 'Pisces';
  bool _isVoidOfCourse = false;
  int _daysToFullMoon = 5;
  int _daysToNewMoon = 19;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late List<Map<String, dynamic>> _monthlyPhases;

  @override
  void initState() {
    super.initState();
    _moonPhaseEmoji = CosmicService.getMoonPhaseEmoji();
    _moonPhaseName = CosmicService.getMoonPhase();
    // Current transiting moon sign (not natal moon sign)
    _moonSign = LunarEngine.currentMoonSign();
    _isVoidOfCourse = CosmicService.isVoidOfCourse();
    _daysToFullMoon = CosmicService.getDaysUntilFullMoon();
    _daysToNewMoon = CosmicService.getDaysUntilNewMoon();
    _monthlyPhases = CosmicService.getMonthlyMoonPhases();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getMoonPhaseForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    for (final phase in _monthlyPhases) {
      final phaseDate = _normalizeDate(phase['date'] as DateTime);
      if (phaseDate == normalized) {
        return '${phase['emoji']} ${phase['name']}';
      }
    }
    DateTime? closestNewMoon;
    DateTime? closestFullMoon;
    for (final phase in _monthlyPhases) {
      final phaseDate = _normalizeDate(phase['date'] as DateTime);
      if (phase['type'] == 'new_moon') {
        closestNewMoon = phaseDate;
      } else if (phase['type'] == 'full_moon') {
        closestFullMoon = phaseDate;
      }
    }
    if (closestNewMoon != null && closestFullMoon != null) {
      final daysFromNew = normalized.difference(closestNewMoon).inDays;
      final daysFromFull = normalized.difference(closestFullMoon).inDays;
      if (daysFromNew >= 0 && daysFromNew < 7) return '🌒 Waxing Crescent';
      if (daysFromNew >= 7 && daysFromNew < 14) return '🌓 First Quarter';
      if (daysFromNew >= 14 && daysFromNew < 21) return '🌔 Waxing Gibbous';
      if (daysFromFull >= 0 && daysFromFull < 7) return '🌖 Waning Gibbous';
      if (daysFromFull >= 7 && daysFromFull < 14) return '🌗 Last Quarter';
      return '🌘 Waning Crescent';
    }
    return '🌙 Unknown Phase';
  }

  bool _isFullMoonDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _monthlyPhases.any((phase) =>
        phase['type'] == 'full_moon' &&
        _normalizeDate(phase['date'] as DateTime) == normalized);
  }

  bool _isNewMoonDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _monthlyPhases.any((phase) =>
        phase['type'] == 'new_moon' &&
        _normalizeDate(phase['date'] as DateTime) == normalized);
  }

  bool _isQuarterMoonDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _monthlyPhases.any((phase) =>
        (phase['type'] == 'first_quarter' ||
            phase['type'] == 'last_quarter') &&
        _normalizeDate(phase['date'] as DateTime) == normalized);
  }

  Widget _buildVoidOfCourseStatus() {
    final color =
        _isVoidOfCourse ? const Color(0xFF10B981) : const Color(0xFF6B7280);
    final label = _isVoidOfCourse ? '⚡ Void of Course' : '✓ Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(String label, int days, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$days',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'days to',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLunarCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: TableCalendar(
        firstDay:
            DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
        lastDay:
            DateTime(DateTime.now().year, DateTime.now().month + 2, 0),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          final phaseText = _getMoonPhaseForDate(selectedDay);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedDay.day}/${selectedDay.month}: $phaseText',
                style: const TextStyle(
                    fontFamily: 'Raleway', color: Colors.white),
              ),
              backgroundColor: const Color(0xFF241538),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white70,
          ),
          weekendTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white70,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF7C3AED),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          outsideTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white24,
          ),
          disabledTextStyle: const TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white24,
          ),
          cellMargin: const EdgeInsets.all(4),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 14,
            color: Colors.white,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: Colors.white70),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: Colors.white70),
          headerPadding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white54,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (_isFullMoonDate(day)) {
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }
            if (_isNewMoonDate(day)) {
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7C3AED),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        color: Color(0xFFB78BFA),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }
            if (_isQuarterMoonDate(day)) {
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B82F6)
                          .withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        color: Color(0xFF93C5FD),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Full Moon', const Color(0xFFF59E0B)),
        const SizedBox(width: 16),
        _buildLegendItem('New Moon', const Color(0xFF7C3AED)),
        const SizedBox(width: 16),
        _buildLegendItem('Quarter', const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseDescriptionCard() {
    final description =
        CosmicService.getMoonPhaseDescription(_moonPhaseName);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PHASE GUIDANCE',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 10,
              color: Colors.white54,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
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
          'Lunar Calendar',
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
                      // Moon Phase Hero
                      Center(
                        child: Text(
                          _moonPhaseEmoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _moonPhaseName,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Moon in $_moonSign',
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 15,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(child: _buildVoidOfCourseStatus()),
                      const SizedBox(height: 24),

                      // Countdown Badges
                      Row(
                        children: [
                          _buildCountdownBadge(
                            'Full Moon',
                            _daysToFullMoon,
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 12),
                          _buildCountdownBadge(
                            'New Moon',
                            _daysToNewMoon,
                            const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Phase Description
                      _buildPhaseDescriptionCard(),
                      const SizedBox(height: 24),

                      // Calendar Header
                      const Text(
                        'LUNAR CALENDAR',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 10,
                          color: Colors.white54,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Calendar
                      _buildLunarCalendar(),
                      const SizedBox(height: 12),

                      // Legend
                      _buildLegend(),
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
