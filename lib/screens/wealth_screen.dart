import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cosmiq_guru/engines/wealth_engine.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  static const _scaffoldBg = Color(0xFF0F0A1A);
  static const _cardBg = Color(0xFF1A1025);
  static const _purpleAccent = Color(0xFF7C3AED);
  static const _goldColor = Color(0xFFF59E0B);
  static const _greenColor = Color(0xFF10B981);

  List<int> _luckyNumbers = [];
  List<Map<String, dynamic>> _weekForecast = [];
  Map<String, dynamic> _wealthCycle = {};
  Map<String, dynamic> _riskAppetite = {};
  Map<String, List<Map<String, dynamic>>> _businessTiming = {};
  String _luckyColor = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    try {
      final profile = context.read<UserProfileProvider>().profile;
      final dob = DateTime.tryParse(profile?.dateOfBirth ?? '') ?? DateTime(2000, 1, 1);
      final fullName = profile?.fullName ?? '';

      final luckyNumbers = WealthEngine.luckyNumbers(dob, fullName);
      final weekForecast = WealthEngine.weekForecast(dob, fullName);
      final wealthCycle = WealthEngine.wealthCycle(dob);
      final riskAppetite = WealthEngine.riskAppetite(dob, fullName);
      final businessTiming = WealthEngine.businessTiming(dob, fullName);
      final luckyColor = WealthEngine.luckyWealthColor(dob);

      if (!mounted) return;
      setState(() {
        _luckyNumbers = luckyNumbers;
        _weekForecast = weekForecast;
        _wealthCycle = wealthCycle;
        _riskAppetite = riskAppetite;
        _businessTiming = businessTiming;
        _luckyColor = luckyColor;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
          'Wealth & Money',
          style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          const StarBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _goldColor))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLuckyNumbersCard(),
                            const SizedBox(height: 16),
                            _buildRiskAppetiteCard(),
                            const SizedBox(height: 16),
                            _buildWeekForecastCard(),
                            const SizedBox(height: 16),
                            _buildWealthCycleCard(),
                            const SizedBox(height: 16),
                            _buildBusinessTimingCard(),
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

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Raleway', fontSize: 10, color: Colors.white54,
        letterSpacing: 1.5, fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLuckyNumbersCard() {
    return _buildCard(
      borderColor: _goldColor,
      child: Column(
        children: [
          _buildSectionHeader('TODAY\'S LUCKY NUMBERS'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _luckyNumbers.map((n) {
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _goldColor.withValues(alpha: 0.3),
                      _goldColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: _goldColor.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: const TextStyle(
                      fontFamily: 'Cinzel', fontSize: 24, color: _goldColor, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎨 Lucky Color: ', style: TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54)),
              Text(_luckyColor, style: const TextStyle(fontFamily: 'Raleway', fontSize: 12, color: _goldColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAppetiteCard() {
    final riskIndex = _riskAppetite['riskIndex'] as int? ?? 2;
    final label = _riskAppetite['label'] as String? ?? 'Moderate';
    final advice = _riskAppetite['advice'] as String? ?? '';
    final investScore = _riskAppetite['investmentScore'] as int? ?? 50;

    Color riskColor;
    IconData riskIcon;
    switch (riskIndex) {
      case 4:
        riskColor = const Color(0xFFEF4444);
        riskIcon = Icons.trending_up;
        break;
      case 3:
        riskColor = _goldColor;
        riskIcon = Icons.trending_up;
        break;
      case 2:
        riskColor = _purpleAccent;
        riskIcon = Icons.trending_flat;
        break;
      case 1:
        riskColor = const Color(0xFF3B82F6);
        riskIcon = Icons.trending_down;
        break;
      default:
        riskColor = const Color(0xFF6B7280);
        riskIcon = Icons.shield;
    }

    return _buildCard(
      borderColor: riskColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('INVESTMENT MOOD'),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: riskColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$investScore',
                    style: TextStyle(fontFamily: 'Cinzel', fontSize: 24, color: riskColor, fontWeight: FontWeight.bold),
                  ),
                  const Text('/100', style: TextStyle(fontFamily: 'Raleway', fontSize: 11, color: Colors.white38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Risk gauge
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: investScore / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            style: TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekForecastCard() {
    return _buildCard(
      borderColor: _greenColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('7-DAY INVESTMENT FORECAST'),
          const SizedBox(height: 16),
          ..._weekForecast.map((day) {
            final score = day['score'] as int;
            final dayName = day['dayName'] as String;
            final date = day['date'] as DateTime;
            final rating = day['rating'] as String;
            final colorStr = day['color'] as String;
            final moonEmoji = day['moonPhase'] as String;
            final isToday = date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;

            Color barColor;
            switch (colorStr) {
              case 'green':
                barColor = _greenColor;
                break;
              case 'red':
                barColor = const Color(0xFFEF4444);
                break;
              default:
                barColor = _goldColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontFamily: 'Raleway', fontSize: 12,
                        color: isToday ? _goldColor : Colors.white54,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(moonEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: score / 100.0,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$score',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Cinzel', fontSize: 13, color: barColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      rating,
                      style: TextStyle(fontFamily: 'Raleway', fontSize: 10, color: barColor),
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

  Widget _buildWealthCycleCard() {
    final phase = _wealthCycle['phase'] as String? ?? '';
    final description = _wealthCycle['description'] as String? ?? '';
    final energy = _wealthCycle['energy'] as String? ?? '';
    final cycleYear = _wealthCycle['cycleYear'] as int? ?? 1;
    final peakMonths = (_wealthCycle['peakMonths'] as List<dynamic>?)?.cast<int>() ?? [];
    final chineseElement = _wealthCycle['chineseElement'] as String? ?? '';
    final chineseAnimal = _wealthCycle['chineseAnimal'] as String? ?? '';
    final isMasterYear = _wealthCycle['isMasterYear'] as bool? ?? false;

    Color energyColor;
    String energyEmoji;
    switch (energy) {
      case 'harvest':
        energyColor = _goldColor;
        energyEmoji = '🌾';
        break;
      case 'expansion':
        energyColor = _greenColor;
        energyEmoji = '📈';
        break;
      case 'release':
        energyColor = const Color(0xFFEF4444);
        energyEmoji = '🔄';
        break;
      default:
        energyColor = _purpleAccent;
        energyEmoji = '🏗️';
    }

    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return _buildCard(
      borderColor: energyColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader('WEALTH CYCLE'),
              const Spacer(),
              if (isMasterYear)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _goldColor.withValues(alpha: 0.5)),
                  ),
                  child: const Text('MASTER YEAR', style: TextStyle(fontFamily: 'Raleway', fontSize: 9, color: _goldColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(energyEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Year $cycleYear — $phase',
                      style: TextStyle(fontFamily: 'Cinzel', fontSize: 16, color: energyColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$chineseElement $chineseAnimal Year',
                      style: const TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
          ),
          if (peakMonths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Peak months: ', style: TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white54)),
                ...peakMonths.map((m) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: energyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: energyColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    monthNames[m.clamp(1, 12)],
                    style: TextStyle(fontFamily: 'Raleway', fontSize: 11, color: energyColor, fontWeight: FontWeight.w600),
                  ),
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessTimingCard() {
    final categories = {
      'contracts': {'label': 'Sign Contracts', 'icon': Icons.description, 'color': _purpleAccent},
      'launches': {'label': 'Launch Products', 'icon': Icons.rocket_launch, 'color': _greenColor},
      'negotiations': {'label': 'Negotiate Deals', 'icon': Icons.handshake, 'color': _goldColor},
      'raises': {'label': 'Ask for Raise', 'icon': Icons.trending_up, 'color': const Color(0xFFEF4444)},
    };

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('BUSINESS TIMING THIS MONTH'),
          const SizedBox(height: 16),
          ...categories.entries.map((entry) {
            final key = entry.key;
            final meta = entry.value;
            final days = _businessTiming[key] ?? [];
            final label = meta['label'] as String;
            final icon = meta['icon'] as IconData;
            final color = meta['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontFamily: 'Cinzel', fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (days.isEmpty)
                    Text(
                      'No ideal days remaining this month',
                      style: TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: days.map((d) {
                        final dayNum = d['dayNumber'] as int;
                        final dayName = d['dayName'] as String;
                        return Tooltip(
                          message: d['reason'] as String? ?? '',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$dayName $dayNum',
                              style: TextStyle(fontFamily: 'Raleway', fontSize: 11, color: color, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
