// lib/core/constants/app_constants.dart

abstract class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.mnp-touriste-arbre.mg/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── Sync ─────────────────────────────────────────────────────────────────
  /// Maximum delay (in hours) before an agent must sync after planting
  static const int syncMaxDelayHours = 3;
  static const int syncMaxRetries = 5;
  static const Duration syncRetryInterval = Duration(minutes: 15);

  // ── Photos ───────────────────────────────────────────────────────────────
  static const int photoMaxWidthPx = 1280;
  static const int photoMaxHeightPx = 960;
  static const int photoQuality = 75;
  static const String photoDirName = 'tree_photos';

  // ── Map (Mantadia) ───────────────────────────────────────────────────────
  static const double mantadiaLat = -18.8200;
  static const double mantadiaLng = 48.4200;
  static const double defaultZoom = 16.0;
  static const int mapMinZoom = 14;
  static const int mapMaxZoom = 18;
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapStoreName = 'mantadia_map';

  // ── Session ──────────────────────────────────────────────────────────────
  static const String sessionUserKey = 'session_user';
  static const String sessionTokenKey = 'session_token';

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int defaultPageSize = 50;

  // ── QR Code ──────────────────────────────────────────────────────────────
  /// Tourist page base URL — QR codes point here
  static const String qrBaseUrl = 'https://arbre.mnp.mg/t/';
}
