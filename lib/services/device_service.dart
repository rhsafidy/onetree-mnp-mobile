// lib/services/device_service.dart
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import 'session_service.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const _deviceTokenKey = 'device_token';
  static const _deviceIdKey    = 'device_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _deviceToken; // cache mémoire

  // ── Lire le device token (cache ou storage) ───────────────────────────────

  Future<String?> getDeviceToken() async {
    _deviceToken ??= await _storage.read(key: _deviceTokenKey);
    return _deviceToken;
  }

  Future<bool> hasDeviceToken() async {
    return (await getDeviceToken()) != null;
  }

  // ── Enregistrer l'appareil auprès du backend ──────────────────────────────
  // Appelé UNE SEULE FOIS après le premier login

  Future<void> registerDevice() async {
    final session = SessionService.instance;
    if (!session.isLoggedIn) throw Exception('Must be logged in first');

    final deviceId   = await _getOrCreateDeviceId();
    final deviceName = await _getDeviceName();

    final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

    final response = await dio.post(
      '/auth/device/register',
      data:    { 'deviceId': deviceId, 'deviceName': deviceName },
      options: Options(headers: session.authHeaders),
    );

    final token     = response.data['deviceToken'] as String;
    final expiresAt = response.data['expiresAt'] as String;

    // Sauvegarder de façon sécurisée
    await Future.wait([
      _storage.write(key: _deviceTokenKey, value: token),
      _storage.write(key: '${_deviceTokenKey}_expires', value: expiresAt),
    ]);

    _deviceToken = token;
  }

  // ── Révoquer (déconnexion définitive de l'appareil) ───────────────────────

  Future<void> revokeDevice() async {
    await Future.wait([
      _storage.delete(key: _deviceTokenKey),
      _storage.delete(key: '${_deviceTokenKey}_expires'),
      _storage.delete(key: _deviceIdKey),
    ]);
    _deviceToken = null;
  }

  // ── Headers pour les appels sync ──────────────────────────────────────────

  // CORRECTIF : suppression de l'opérateur `?token` invalide en Dart.
  // On lève une exception explicite si le device n'est pas encore enregistré.
  Future<Map<String, String>> getSyncHeaders() async {
  final token = await getDeviceToken();
  if (token == null) return {};
  return {
    'x-device-token': token,
    'Content-Type':   'application/json',
  };
  }

  // ── Privé ─────────────────────────────────────────────────────────────────

  Future<String> _getOrCreateDeviceId() async {
    var id = await _storage.read(key: _deviceIdKey);
    if (id != null) return id;

    // Utiliser device_info_plus en production
    // Pour l'instant : UUID stable généré une fois
    id = 'device_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<String> _getDeviceName() async {
    // En production : DeviceInfoPlugin().androidInfo.model
    return Platform.isAndroid ? 'Android Device' : 'iOS Device';
  }
}