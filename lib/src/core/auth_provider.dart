import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
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
  bool _mfaRequired = false;
  String? _mfaFactorId;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;
  bool get mfaRequired => _mfaRequired;
  String? get mfaFactorId => _mfaFactorId;

  AuthProvider() {
    _initAuthListener();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _initAuthListener() {
    // Listen for auth changes reactively
    _supabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        try {
          final aal = _supabaseService.client.auth.mfa.getAuthenticatorAssuranceLevel();
          if (aal.nextLevel == supabase.AuthenticatorAssuranceLevels.aal2 &&
              aal.currentLevel != supabase.AuthenticatorAssuranceLevels.aal2) {
            final factors = await _supabaseService.client.auth.mfa.listFactors();
            if (factors.totp.isNotEmpty) {
              final factor = factors.totp.firstWhere(
                (f) => f.status == supabase.FactorStatus.verified,
                orElse: () => factors.totp.first,
              );
              _mfaFactorId = factor.id;
              _mfaRequired = true;
              _user = null;
              _profile = null;
              _isLoading = false;
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('[AuthProvider] Auth listener MFA check error: $e');
        }

        // Recover user payload from metadata
        _mfaRequired = false;
        _mfaFactorId = null;
        final u = _supabaseService.currentUser;
        _user = u;
        _loadProfile();
      } else {
        _mfaRequired = false;
        _mfaFactorId = null;
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
        final aal = _supabaseService.client.auth.mfa.getAuthenticatorAssuranceLevel();
        if (aal.nextLevel == supabase.AuthenticatorAssuranceLevels.aal2 &&
            aal.currentLevel != supabase.AuthenticatorAssuranceLevels.aal2) {
          final factors = await _supabaseService.client.auth.mfa.listFactors();
          if (factors.totp.isNotEmpty) {
            final factor = factors.totp.firstWhere(
              (f) => f.status == supabase.FactorStatus.verified,
              orElse: () => factors.totp.first,
            );
            _mfaFactorId = factor.id;
            _mfaRequired = true;
            _user = null;
            _profile = null;
          }
        } else {
          _mfaRequired = false;
          _mfaFactorId = null;
          _user = _supabaseService.currentUser;
          await _loadProfile();
        }
      } else {
        _mfaRequired = false;
        _mfaFactorId = null;
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

      final aal = _supabaseService.client.auth.mfa.getAuthenticatorAssuranceLevel();
      if (aal.nextLevel == supabase.AuthenticatorAssuranceLevels.aal2 &&
          aal.currentLevel != supabase.AuthenticatorAssuranceLevels.aal2) {
        final factors = await _supabaseService.client.auth.mfa.listFactors();
        if (factors.totp.isNotEmpty) {
          final factor = factors.totp.firstWhere(
            (f) => f.status == supabase.FactorStatus.verified,
            orElse: () => factors.totp.first,
          );
          _mfaFactorId = factor.id;
          _mfaRequired = true;
          _user = null;
          _profile = null;
        }
      } else {
        _mfaRequired = false;
        _mfaFactorId = null;
        _user = u;
        await _loadProfile();
      }
    } catch (e) {
      _mfaRequired = false;
      _mfaFactorId = null;
      _user = null;
      _profile = null;
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyMfa(String code) async {
    if (_mfaFactorId == null) {
      _error = 'No MFA factor found';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final challenge = await _supabaseService.client.auth.mfa.challenge(factorId: _mfaFactorId!);
      await _supabaseService.client.auth.mfa.verify(
        factorId: _mfaFactorId!,
        challengeId: challenge.id,
        code: code,
      );
      _mfaRequired = false;
      _mfaFactorId = null;
      _user = _supabaseService.currentUser;
      await _loadProfile();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelMfa() async {
    _mfaRequired = false;
    _mfaFactorId = null;
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
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
