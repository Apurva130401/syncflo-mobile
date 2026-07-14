import 'package:flutter/material.dart';
import '../models/models.dart';
import 'push_notification_service.dart';
import 'supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  User? _user;
  Profile? _profile;
  bool _isLoading = true;
  String? _error;
  ThemeMode _themeMode = ThemeMode.system;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;

  AuthProvider() {
    _initAuthListener();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _initAuthListener() {
    // Listen for auth changes reactively
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Recover user payload from metadata
        final u = _supabaseService.currentUser;
        _user = u;
        _loadProfile();
      } else {
        _user = null;
        _profile = null;
      }
      _isLoading = false;
      notifyListeners();
    });
    
    // Perform initial check
    checkSession();
  }

  Future<void> _loadProfile() async {
    try {
      final prof = await _supabaseService.getMyProfile();
      _profile = prof;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error loading user profile: $e');
    }
  }

  Future<void> checkSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = _supabaseService.client.auth.currentSession;
      if (session != null) {
        _user = _supabaseService.currentUser;
        await _loadProfile();
      } else {
        _user = null;
        _profile = null;
      }
    } catch (e) {
      _user = null;
      _profile = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final u = await _supabaseService.signIn(email, password);
      _user = u;
      await _loadProfile();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String firstName, String lastName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.signUp(email, password, firstName, lastName);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await PushNotificationService().removeToken();
      await _supabaseService.signOut();
      _user = null;
      _profile = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
