// lib/screens/login/login_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../repositories/user_repository.dart';
import '../../services/session_service.dart';

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final _userRepo = UserRepository();

  LoginState _state    = LoginState.idle;
  String?    _errorMsg;

  LoginState get state    => _state;
  String?    get errorMsg => _errorMsg;
  bool       get isLoading => _state == LoginState.loading;

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
      final user = await _userRepo.login(email.trim(), password);

      if (user == null) {
        _errorMsg = 'Invalid email or password.';
        _state    = LoginState.error;
        notifyListeners();
        return false;
      }

      // Save session locally (token comes from API in production)
      await SessionService.instance.saveSession(user, 'local_token_${user.id}');

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

  void clearError() {
    _errorMsg = null;
    _state    = LoginState.idle;
    notifyListeners();
  }
}
