import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _notifyEscalation = true;
  bool _notifyMessage = true;
  bool _notifyTeam = true;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_enabled') ?? true;
      _notifyEscalation = prefs.getBool('notify_escalation') ?? true;
      _notifyMessage = prefs.getBool('notify_message') ?? true;
      _notifyTeam = prefs.getBool('notify_team') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
    });
  }

  void _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('GENERAL SETTINGS'),
          _buildToggle('Push Notifications', 'Enable or disable push notifications entirely', _pushEnabled, (v) {
            setState(() => _pushEnabled = v);
            _savePref('push_enabled', v);
          }),
          const SizedBox(height: 24),
          _buildHeader('NOTIFY ON'),
          _buildToggle('New Escalation', 'Get alerted when a bot hands over a conversation', _notifyEscalation, (v) {
            setState(() => _notifyEscalation = v);
            _savePref('notify_escalation', v);
          }),
          _buildToggle('New Message', 'Get alerted when a customer sends a message', _notifyMessage, (v) {
            setState(() => _notifyMessage = v);
            _savePref('notify_message', v);
          }),
          _buildToggle('Team Updates', 'Get alerted on assignment changes or closures', _notifyTeam, (v) {
            setState(() => _notifyTeam = v);
            _savePref('notify_team', v);
          }),
          const SizedBox(height: 24),
          _buildHeader('SYSTEM'),
          _buildToggle('Sounds', 'Play sound on incoming alerts', _soundEnabled, (v) {
            setState(() => _soundEnabled = v);
            _savePref('sound_enabled', v);
          }),
          _buildToggle('Haptics', 'Vibrate on notifications', _hapticsEnabled, (v) {
            setState(() => _hapticsEnabled = v);
            _savePref('haptics_enabled', v);
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.border,
      ),
    );
  }
}
