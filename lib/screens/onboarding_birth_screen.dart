// Step 1: Inventory
// This file DEFINES:
//   - OnboardingBirthScreen (StatefulWidget) — accepts name from constructor
//   - _OnboardingBirthScreenState — holds _selectedDate, _selectedTime, _locationController,
//     _dobDisplay, _timeDisplay, _isNextEnabled
//   - _pickDate() — shows DatePicker, updates _selectedDate and _dobDisplay
//   - _pickTime() — shows TimePicker, updates _selectedTime and _timeDisplay
//   - _updateNextEnabled() — checks all 3 fields filled
//   - _onBack() — Navigator.pop
//   - _onNext() — Navigator.push to OnboardingQuizScreen
//   - _buildInputCard(...) — builds a tappable card or TextField card
//   - _buildProgressDot(int step, bool active) — builds a progress indicator dot
//
// This file USES from other files:
//   - StarBackground (from lib/widgets/star_background.dart) — no constructor params
//   - OnboardingQuizScreen (from lib/screens/onboarding_quiz_screen.dart)
//     Constructor: name (String), dob (String), birthTime (String), location (String)
//     NOTE: OnboardingQuizScreen takes String dob and String birthTime based on its generated code
//
// Step 2: Connections
// - OnboardingNameScreen navigates TO this screen via Navigator.push(OnboardingBirthScreen(name: ...))
// - This screen navigates BACK via Navigator.pop
// - This screen navigates FORWARD to OnboardingQuizScreen with name, dob (formatted string), birthTime (formatted string), location
// - OnboardingQuizScreen constructor: name, dob, birthTime, location — all Strings
//
// Step 3: User Journey Trace
// - User arrives with their name pre-filled from previous screen
// - Sees "Your Cosmic Coordinates" heading with 3 input cards
// - Taps DOB card → DatePicker opens → selects date → card updates to "January 1, 1990"
// - Taps Time card → TimePicker opens → selects time → card updates to "8:00 AM"
// - Types in Location field → text updates
// - Once all 3 filled, Continue button enables (purple background)
// - Taps Continue → navigates to OnboardingQuizScreen
// - Taps Back → Navigator.pop back to OnboardingNameScreen
//
// Step 4: Layout Sanity
// - Column with Spacer() before progress dots — no unbounded height issues since Column is inside SafeArea/Padding
// - TextEditingController declared as class field — correct
// - _locationController disposed in dispose() — correct
// - intl package used for DateFormat — need to check if it's available
//   The spec says: DateFormat('MMMM d, yyyy').format(date) — this requires intl package
//   Looking at the project, no explicit pubspec mention, but intl is commonly available
//   I'll use intl for DateFormat. If not available, fallback to manual formatting.
//   Actually, to be safe and avoid import issues, I'll format the date manually:
//   '${_monthName(_selectedDate!.month)} ${_selectedDate!.day}, ${_selectedDate!.year}'
//   This avoids the intl dependency entirely.
// - Back button uses OutlinedButton (1/3 width via Expanded), Continue uses ElevatedButton (2/3 via Expanded(flex:2))
// - The location card uses TextField inside the card structure — need to handle that carefully
//   The spec says isTextField: true uses TextField instead of Text for value
//   I'll build the location card with a TextField that has transparent decoration
// - Progress dots: step 1=false, 2=true (active), 3=false — dot 2 is active (current screen)
//   Actually looking at the widgetTree: _buildProgressDot(1, false), _buildProgressDot(2, true), _buildProgressDot(3, false)
//   So step 2 is active (this is screen 2 of 3)

import 'package:flutter/material.dart';
import 'package:cosmiq_guru/widgets/star_background.dart';
import 'package:cosmiq_guru/screens/onboarding_quiz_screen.dart';

class OnboardingBirthScreen extends StatefulWidget {
  final String name;

  const OnboardingBirthScreen({
    super.key,
    required this.name,
  });

  @override
  State<OnboardingBirthScreen> createState() => _OnboardingBirthScreenState();
}

class _OnboardingBirthScreenState extends State<OnboardingBirthScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _locationController = TextEditingController();
  String _dobDisplay = 'Tap to select';
  String _timeDisplay = 'Tap to select';
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_updateNextEnabled);
  }

  @override
  void dispose() {
    _locationController.removeListener(_updateNextEnabled);
    _locationController.dispose();
    super.dispose();
  }

  void _updateNextEnabled() {
    setState(() {
      _isNextEnabled = _selectedDate != null &&
          _selectedTime != null &&
          _locationController.text.trim().isNotEmpty;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time, BuildContext context) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1025),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F0A1A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobDisplay = _formatDate(picked);
      });
      _updateNextEnabled();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1025),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F0A1A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeDisplay = _formatTime(picked, context);
      });
      _updateNextEnabled();
    }
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onNext() {
    if (!_isNextEnabled) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingQuizScreen(
          name: widget.name,
          dob: _selectedDate!.toIso8601String().split('T').first,
          birthTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          location: _locationController.text.trim(),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int step, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF7C3AED)
            : const Color(0xFF7C3AED).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    bool isTextField = false,
    TextEditingController? controller,
  }) {
    return GestureDetector(
      onTap: isTextField ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 4),
                  isTextField
                      ? TextField(
                          controller: controller,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Raleway',
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'e.g. New York, USA',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          cursorColor: const Color(0xFF7C3AED),
                        )
                      : Text(
                          value ?? 'Tap to select',
                          style: TextStyle(
                            color: (value == null || value == 'Tap to select')
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 16,
                            fontFamily: 'Raleway',
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(
        children: [
          const StarBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Your Cosmic Coordinates',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The universe needs these to map your path',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputCard(
                    icon: Icons.calendar_today,
                    label: 'Date of Birth',
                    value: _dobDisplay,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  _buildInputCard(
                    icon: Icons.access_time,
                    label: 'Birth Time',
                    value: _timeDisplay,
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 12),
                  _buildInputCard(
                    icon: Icons.location_on,
                    label: 'Birth City & Country',
                    isTextField: true,
                    controller: _locationController,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressDot(1, false),
                      const SizedBox(width: 8),
                      _buildProgressDot(2, true),
                      const SizedBox(width: 8),
                      _buildProgressDot(3, false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onBack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '← Back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isNextEnabled ? _onNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            disabledBackgroundColor:
                                const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Continue →',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}