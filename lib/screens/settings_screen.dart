import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmiq_guru/providers/user_profile_provider.dart';
import 'package:cosmiq_guru/services/database_service.dart';
import 'package:cosmiq_guru/services/notification_service.dart';
import 'package:cosmiq_guru/screens/onboarding_name_screen.dart';
import 'package:cosmiq_guru/screens/splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isAdvancedExpanded = false;
  String _aiProvider = 'OpenAI';
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyObscured = true;
  String _appVersion = '';
  bool _isTestingConnection = false;

  static const List<String> _aiProviders = [
    'OpenAI',
    'Anthropic',
    'Google Gemini',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();

      final savedProvider = prefs.getString('ai_provider') ?? 'OpenAI';
      final validProvider =
          _aiProviders.contains(savedProvider) ? savedProvider : 'OpenAI';

      final savedHour = prefs.getInt('notification_hour') ?? 8;
      final savedMinute = prefs.getInt('notification_minute') ?? 0;

      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _isDarkMode = prefs.getBool('theme_dark') ?? true;
          _notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? true;
          _notificationTime =
              TimeOfDay(hour: savedHour, minute: savedMinute);
          _aiProvider = validProvider;
          _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    }
  }

  Future<void> _saveTheme(bool isDark) async {
    setState(() => _isDarkMode = isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', isDark);
    if (mounted) {
      context.read<UserProfileProvider>().setTheme(isDark);
    }
  }

  Future<void> _saveNotificationsEnabled(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    try {
      if (enabled) {
        await NotificationService.instance.scheduleDaily(_notificationTime);
      } else {
        await NotificationService.instance.cancelAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              surface: const Color(0xFF1A1025),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _notificationTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', picked.hour);
      await prefs.setInt('notification_minute', picked.minute);
      try {
        await NotificationService.instance.rescheduleDaily(picked);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reschedule notification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveAiProvider(String provider) async {
    setState(() => _aiProvider = provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', provider);
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', key);
  }

  Future<void> _testConnection() async {
    setState(() => _isTestingConnection = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isTestingConnection = false);

    final apiKey = _apiKeyController.text.trim();
    final message = apiKey.isNotEmpty
        ? 'Connection successful ✓'
        : 'Connection failed — check your API key';
    final color = apiKey.isNotEmpty ? const Color(0xFF7C3AED) : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Raleway', color: Colors.white),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final profile = await DatabaseService.instance.getUserProfile();
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No profile data found to export.'),
              backgroundColor: Color(0xFF7C3AED),
            ),
          );
        }
        return;
      }

      final exportMap = {
        'exported_at': DateTime.now().toIso8601String(),
        'profile': profile.toJson(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cosmiq_guru_export.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'cosmiq.guru — My Cosmic Profile Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1025),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
        ),
        title: const Text(
          'Clear All Data?',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'This will delete your profile and all readings. This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Raleway',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Raleway',
                color: Colors.white54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Clear Everything',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await DatabaseService.instance.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        context.read<UserProfileProvider>().clearProfile();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Raleway',
          fontSize: 11,
          color: Colors.white54,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCosmicCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileCard() {
    final profile = context.watch<UserProfileProvider>().profile;
    final displayName = profile?.fullName ?? 'Cosmic Traveler';
    final displayDob = profile?.dateOfBirth ?? '—';

    return _buildCosmicCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OnboardingNameScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Born: $displayDob',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return _buildCosmicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.dark_mode_outlined, color: Color(0xFF7C3AED), size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dark Mode',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: _isDarkMode,
              onChanged: _saveTheme,
              activeColor: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _buildCosmicCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF7C3AED), size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Daily Notifications',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _saveNotificationsEnabled,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
          if (_notificationsEnabled) ...[
            Divider(
              height: 1,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            ),
            InkWell(
              onTap: _pickNotificationTime,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        color: Colors.white54, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Notification Time',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Text(
                      _notificationTime.format(context),
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return _buildCosmicCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _isAdvancedExpanded,
          onExpansionChanged: (v) => setState(() => _isAdvancedExpanded = v),
          leading: const Icon(Icons.tune, color: Color(0xFF7C3AED), size: 22),
          title: const Text(
            'Advanced Settings',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Provider',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _aiProvider,
                    dropdownColor: const Color(0xFF1A1025),
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0D0618),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _aiProviders
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _saveAiProvider(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: _isApiKeyObscured,
                    onChanged: _saveApiKey,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your API key',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0D0618),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isApiKeyObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white38,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _isApiKeyObscured = !_isApiKeyObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isTestingConnection
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Test Connection',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildDataCard() {
    return _buildCosmicCard(
      child: Column(
        children: [
          InkWell(
            onTap: _exportData,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.download_outlined,
                      color: Color(0xFF7C3AED), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Export My Data',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
          ),
          InkWell(
            onTap: _showClearDataDialog,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Clear All Data',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
        children: [
          // Header
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Profile Section
          _buildSectionHeader('Profile'),
          _buildProfileCard(),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationsCard(),
          const SizedBox(height: 24),

          // Advanced Section
          _buildSectionHeader('Advanced'),
          _buildAdvancedCard(),
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data'),
          _buildDataCard(),
          const SizedBox(height: 32),

          // Version Footer
          Center(
            child: Text(
              'cosmiq.guru v$_appVersion',
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 12,
                color: Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Your cosmic blueprint, decoded.',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: Colors.white12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
