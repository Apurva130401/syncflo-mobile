import 'package:shared_preferences/shared_preferences.dart';

/// Reads the toggles saved by the Notification Settings screen.
/// Every kind defaults to on, matching the screen's defaults.
class NotificationPrefs {
  static Future<bool> _get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> pushEnabled() => _get('push_enabled');
  static Future<bool> messages() async => await pushEnabled() && await _get('notify_message');
  static Future<bool> escalations() async => await pushEnabled() && await _get('notify_escalation');
  static Future<bool> calls() async => await pushEnabled() && await _get('notify_calls');
  static Future<bool> sound() => _get('sound_enabled');
}
