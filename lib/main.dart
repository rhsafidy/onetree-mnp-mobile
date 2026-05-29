// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/database_seeder.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:mobile_app/screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/sync_provider.dart';
import 'services/sync_service.dart';
import 'screens/login/login_screen.dart';
import 'screens/parcel_list/parcel_list_screen.dart';
import 'screens/trees_list/tree_list_screen.dart';
import 'screens/tree_details/tree_details_screen.dart';
import 'screens/tree_update/tree_update_form_screen.dart';
import 'screens/tree_update/tree_update_photo_screen.dart';
import 'screens/client_info_insert/qr_scanner_screen.dart';
import 'screens/client_info_insert/client_form_screen.dart';
import 'screens/sync/sync_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed local DB with initial data (no-op if already seeded)
  await DatabaseSeeder.seed();

  // CORRECTIF : init() supprimé (n'existe plus).
  // Le Dio et son intercepteur sont initialisés dans le constructeur de SyncService.
  // startListening() démarre l'écoute réseau pour le flush automatique.
  SyncService.instance.startListening();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncProvider()..init()),
      ],
      child: MaterialApp(
        title:                      'Un Touriste — Un Arbre',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.light,
        darkTheme:                  AppTheme.dark,
        themeMode:                  ThemeMode.system,

        initialRoute: AppRoutes.splash,

        routes: {
          AppRoutes.splash:      (_) => const SplashScreen(),
          AppRoutes.login:       (_) => const LoginScreen(),
          AppRoutes.parcelList:  (_) => const ParcelListScreen(),
          AppRoutes.treesList:   (_) => const TreesListScreen(),
          AppRoutes.treeDetail:  (_) => const TreeDetailsScreen(),
          AppRoutes.treeUpdate:  (_) => const TreeUpdateFormScreen(),
          AppRoutes.treePhoto:   (_) => const TreeUpdatePhotoScreen(),
          AppRoutes.qrScanner:   (_) => const QrScannerScreen(),
          AppRoutes.clientForm:  (_) => const ClientFormScreen(),
          AppRoutes.sync:        (_) => const SyncScreen(),
        },
      ),
    );
  }
}