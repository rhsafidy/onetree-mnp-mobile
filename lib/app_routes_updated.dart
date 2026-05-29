// lib/core/navigation/app_routes.dart

abstract class AppRoutes {
  // ── Startup ───────────────────────────────────────────────────────────────
  static const String splash     = '/';           // ← new entry point

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login      = '/login';

  // ── Main flows ────────────────────────────────────────────────────────────
  static const String parcelList = '/parcels';
  static const String treesList  = '/trees';
  static const String treeDetail = '/trees/detail';
  static const String treeUpdate = '/trees/update';
  static const String treePhoto  = '/trees/photo';

  // ── QR & client ───────────────────────────────────────────────────────────
  static const String qrScanner  = '/qr-scanner';
  static const String clientForm = '/client-form';

  // ── Sync ──────────────────────────────────────────────────────────────────
  static const String sync       = '/sync';
}
