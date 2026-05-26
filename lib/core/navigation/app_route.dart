// lib/core/navigation/app_routes.dart
//
// Centralised named routes. Use AppRoutes.X everywhere instead of raw strings.

abstract class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';

  // ── Main flows ────────────────────────────────────────────────────────────
  static const String parcelList    = '/parcels';
  static const String parcelDetail  = '/parcels/detail';
  static const String treesList     = '/trees';
  static const String treeDetail    = '/trees/detail';
  static const String treeUpdate    = '/trees/update';
  static const String treePhoto     = '/trees/photo';

  // ── QR & client (receptionist flow) ──────────────────────────────────────
  static const String qrScanner     = '/qr-scanner';
  static const String clientForm     = '/client-form';

  // ── Sync ──────────────────────────────────────────────────────────────────
  static const String sync          = '/sync';
}
