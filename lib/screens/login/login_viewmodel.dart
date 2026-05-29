// lib/screens/login/login_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../repositories/user_repository.dart';
import '../../services/device_service.dart';
import '../../services/session_service.dart';

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final _userRepo = UserRepository();

  LoginState _state    = LoginState.idle;
  String?    _errorMsg;

  LoginState get state     => _state;
  String?    get errorMsg  => _errorMsg;
  bool       get isLoading => _state == LoginState.loading;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMsg = 'Please fill in all fields.';
      _state    = LoginState.error;
      notifyListeners();
      return false;
    }

    _state    = LoginState.loading;
    _errorMsg = null;
    notifyListeners();

    try {
      // 1. Authentifier l'agent via l'API (ou la DB locale en fallback)
      final user = await _userRepo.login(email.trim(), password);

      if (user == null) {
        _errorMsg = 'Invalid email or password.';
        _state    = LoginState.error;
        notifyListeners();
        return false;
      }

      // 2. Sauvegarder la session JWT
      // En production : le token vient de l'API (POST /auth/login → accessToken)
      // Ici on utilise un token local provisoire qui sera remplacé au premier sync
      await SessionService.instance.saveSession(
        user,
        'local_token_${user.id}',
      );

      // 3. Enregistrer l'appareil si pas encore fait (obtenir le device token)
      // Non bloquant : si le réseau est absent, ça sera fait au prochain démarrage
      if (!await DeviceService.instance.hasDeviceToken()) {
        try {
          await DeviceService.instance.registerDevice();
        } catch (_) {
          // Pas de réseau au moment du login → sera réessayé au prochain splash
          // L'agent peut tout de même utiliser l'app en mode offline
        }
      }

      _state = LoginState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMsg = 'Connection error. Please try again.';
      _state    = LoginState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clearError() {
    _errorMsg = null;
    _state    = LoginState.idle;
    notifyListeners();
  }
}