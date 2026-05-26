// lib/services/session_service.dart
//
// Manages the authenticated agent session using flutter_secure_storage.
// The JWT token is stored securely; the User object is cached in memory.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // In-memory cache — cleared on logout
  User? _currentUser;
  String? _token;

  // ── Getters ───────────────────────────────────────────────────────────────

  User?   get currentUser => _currentUser;
  String? get token       => _token;
  bool    get isLoggedIn  => _currentUser != null && _token != null;

  // ── Save session after successful login ───────────────────────────────────

  Future<void> saveSession(User user, String token) async {
    _currentUser = user;
    _token       = token;

    await Future.wait([
      _storage.write(
        key:   AppConstants.sessionUserKey,
        value: jsonEncode(user.toMap()),
      ),
      _storage.write(
        key:   AppConstants.sessionTokenKey,
        value: token,
      ),
    ]);
  }

  // ── Restore session on app launch ─────────────────────────────────────────

  Future<bool> restoreSession() async {
    try {
      final userJson = await _storage.read(key: AppConstants.sessionUserKey);
      final token    = await _storage.read(key: AppConstants.sessionTokenKey);

      if (userJson == null || token == null) return false;

      _currentUser = User.fromMap(jsonDecode(userJson) as Map<String, dynamic>);
      _token       = token;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    _token       = null;
    await Future.wait([
      _storage.delete(key: AppConstants.sessionUserKey),
      _storage.delete(key: AppConstants.sessionTokenKey),
    ]);
  }

  // ── Dio interceptor helper ────────────────────────────────────────────────

  Map<String, String> get authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      };
}
