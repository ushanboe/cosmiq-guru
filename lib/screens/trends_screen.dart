import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const _scaffoldBg = Color(0xFF0F0A1A);
  static const _cardBg = Color(0xFF1A1025);
  static const _purpleAccent = Color(0xFF7C3AED);
  static const _goldColor = Color(0xFFF59E0B);
  static const _greenColor = Color(0xFF10B981);
  static const _blueColor = Color(0xFF3B82F6);

  int _rangeDays = 7; // 7, 30, 90
  List<JournalEntry> _entries = [];
  List<_DailyData> _dailyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final profile = context.read<UserProfileProvider>().profile;
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final start = now.subtract(Duration(days: _rangeDays));
      final startStr = start.toIso8601String().split('T').first;
      final endStr = now.toIso8601String().split('T').first;

      final entries = await DatabaseService.instance
          .getJournalEntriesRange(profile.id, startStr, endStr);

      // Build daily data from journal entries only (engines use DateTime.now(), can't compute historical scores)
      final dailyData = entries.map((e) {
        final parts = e.date.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return _DailyData(
          date: date,
          luckScore: e.luckScore,
          mood: e.mood,
          moonPhase: e.moonPhase,
          dominantSystem: e.dominantSystem,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _dailyData = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeRange(int days) {
    setState(() {
      _rangeDays = days;
      _isLoading = true;
    });
    _loadData();
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
          'COSMIC TRENDS',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
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
                          // Range selector
                          _buildRangeSelector(),
                          const SizedBox(height: 16),

                          // Luck Score Trend
                          _buildLuckTrendChart(),
                          const SizedBox(height: 16),

                          // Mood vs Luck
                          if (_entries.isNotEmpty) ...[
                            _buildMoodVsLuckChart(),
                            const SizedBox(height: 16),
                          ],

                          // Stats cards
                          _buildStatsCards(),
                          const SizedBox(height: 16),

                          // Moon Phase Correlation
                          if (_entries.length >= 3) ...[
                            _buildMoonCorrelation(),
                            const SizedBox(height: 16),
                          ],

                          // System dominance
                          if (_entries.isNotEmpty) ...[
                            _buildSystemDominance(),
                            const SizedBox(height: 32),
                          ],

                          if (_entries.isEmpty)
                            _buildEmptyState(),

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

  Widget _buildRangeSelector() {
    return Row(
      children: [7, 30, 90].map((days) {
        final isSelected = _rangeDays == days;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: days == 7 ? 0 : 4,
              right: days == 90 ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () => _changeRange(days),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _purpleAccent.withValues(alpha: 0.2)
                      : _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _purpleAccent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  '$days Days',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: isSelected ? _purpleAccent : Colors.white54,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLuckTrendChart() {
    if (_dailyData.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < _dailyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyData[i].luckScore.toDouble()));
    }

    return _buildChartCard(
      title: 'LUCK SCORE TREND',
      emoji: '📈',
      borderColor: _purpleAccent,
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 9,
                    color: Colors.white30,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: _rangeDays <= 7 ? 1 : (_rangeDays <= 30 ? 7 : 15),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _dailyData.length) return const SizedBox.shrink();
                  final d = _dailyData[idx].date;
                  return Text(
                    '${d.day}/${d.month}',
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 8,
                      color: Colors.white30,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _purpleAccent,
              barWidth: 2.5,
              dotData: FlDotData(
                show: _rangeDays <= 14,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: _purpleAccent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _purpleAccent.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${s.y.toInt()}',
                const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodVsLuckChart() {
    final moodEntries = _entries.where((e) => e.mood >= 0 && e.mood <= 4).toList();
    if (moodEntries.isEmpty) return const SizedBox.shrink();

    final scatterSpots = moodEntries.map((e) {
      return ScatterSpot(
        e.luckScore.toDouble(),
        (e.mood + 1).toDouble(),
        dotPainter: FlDotCirclePainter(
          radius: 5,
          color: _goldColor.withValues(alpha: 0.7),
          strokeWidth: 1,
          strokeColor: _goldColor,
        ),
      );
    }).toList();

    return _buildChartCard(
      title: 'MOOD vs LUCK',
      emoji: '🎭',
      borderColor: _goldColor,
      height: 200,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: scatterSpots,
          minX: 0,
          maxX: 100,
          minY: 0.5,
          maxY: 5.5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const emojis = ['', '😫', '😔', '😐', '🙂', '🤩'];
                  final idx = value.toInt();
                  if (idx < 1 || idx > 5) return const SizedBox.shrink();
                  return Text(emojis[idx], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 9,
                    color: Colors.white30,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          scatterTouchData: ScatterTouchData(enabled: false),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    // Best/worst day of week
    final dayScores = <int, List<int>>{};
    for (final d in _dailyData) {
      dayScores.putIfAbsent(d.date.weekday, () => []).add(d.luckScore);
    }

    String bestDay = '—';
    String worstDay = '—';
    int bestAvg = 0;
    int worstAvg = 100;
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    dayScores.forEach((weekday, scores) {
      final avg = scores.reduce((a, b) => a + b) ~/ scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestDay = dayNames[weekday];
      }
      if (avg < worstAvg) {
        worstAvg = avg;
        worstDay = dayNames[weekday];
      }
    });

    // Average luck
    final avgLuck = _dailyData.isEmpty
        ? 0
        : _dailyData.map((d) => d.luckScore).reduce((a, b) => a + b) ~/ _dailyData.length;

    // Average mood (journal entries only)
    final moodEntries = _entries.where((e) => e.mood >= 0 && e.mood <= 4).toList();
    final avgMood = moodEntries.isEmpty
        ? -1.0
        : moodEntries.map((e) => e.mood).reduce((a, b) => a + b) / moodEntries.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('🏆', 'Luckiest Day', bestDay, 'avg $bestAvg', _greenColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('📉', 'Lowest Day', worstDay, 'avg $worstAvg', Colors.red)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('🎯', 'Avg Luck', '$avgLuck', 'out of 100', _purpleAccent)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                '😊',
                'Avg Mood',
                avgMood < 0 ? '—' : avgMood.toStringAsFixed(1),
                avgMood < 0 ? 'no entries' : 'out of 5',
                _goldColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 10,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 10,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCorrelation() {
    // Group entries by moon phase category
    final phaseMap = <String, List<int>>{};
    for (final e in _entries) {
      final phase = _simplifyMoonPhase(e.moonPhase);
      if (phase.isNotEmpty) {
        phaseMap.putIfAbsent(phase, () => []).add(e.mood + 1);
      }
    }

    if (phaseMap.isEmpty) return const SizedBox.shrink();

    return _buildChartCard(
      title: 'MOON PHASE & MOOD',
      emoji: '🌙',
      borderColor: _blueColor,
      height: null,
      child: Column(
        children: phaseMap.entries.map((e) {
          final avgMood = e.value.reduce((a, b) => a + b) / e.value.length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: avgMood / 5.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _blueColor.withValues(alpha: 0.7),
                      ),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  avgMood.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(' /5', style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 9, color: Colors.white30)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemDominance() {
    // Count dominant systems
    final systemCounts = <String, int>{};
    for (final e in _entries) {
      if (e.dominantSystem.isNotEmpty) {
        systemCounts[e.dominantSystem] = (systemCounts[e.dominantSystem] ?? 0) + 1;
      }
    }
    if (systemCounts.isEmpty) return const SizedBox.shrink();

    final sorted = systemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);
    final colors = [_purpleAccent, _goldColor, _greenColor, _blueColor, Colors.orange, Colors.pink];

    return _buildChartCard(
      title: 'DOMINANT SYSTEMS',
      emoji: '⭐',
      borderColor: _greenColor,
      height: null,
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final pct = (item.value / total * 100).round();
          final color = colors[idx % colors.length];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    item.key,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.value / total,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'No journal entries yet',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start logging your mood in the Cosmic Journal to see trends and correlations here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 13,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Log entries daily to build your cosmic trend data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String emoji,
    required Color borderColor,
    required double? height,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (height != null)
            SizedBox(height: height, child: child)
          else
            child,
        ],
      ),
    );
  }

  String _simplifyMoonPhase(String phase) {
    final lower = phase.toLowerCase();
    if (lower.contains('new')) return 'New Moon';
    if (lower.contains('full')) return 'Full Moon';
    if (lower.contains('waxing crescent')) return 'Waxing Crescent';
    if (lower.contains('first quarter')) return 'First Quarter';
    if (lower.contains('waxing gibbous')) return 'Waxing Gibbous';
    if (lower.contains('waning gibbous')) return 'Waning Gibbous';
    if (lower.contains('last quarter') || lower.contains('third quarter')) return 'Last Quarter';
    if (lower.contains('waning crescent')) return 'Waning Crescent';
    if (lower.contains('waxing')) return 'Waxing';
    if (lower.contains('waning')) return 'Waning';
    return phase.isEmpty ? '' : phase;
  }
}

class _DailyData {
  final DateTime date;
  final int luckScore;
  final int? mood;
  final String moonPhase;
  final String dominantSystem;

  const _DailyData({
    required this.date,
    required this.luckScore,
    this.mood,
    required this.moonPhase,
    required this.dominantSystem,
  });
}
