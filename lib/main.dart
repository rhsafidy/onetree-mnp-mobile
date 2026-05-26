// lib/main.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/core/database/database_seeder.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/providers/sync_provider.dart';
import 'package:mobile_app/screens/client_info_insert/client_form_screen.dart';
import 'package:mobile_app/screens/client_info_insert/qr_scanner_screen.dart';
import 'package:mobile_app/screens/login/login_screen.dart';
import 'package:mobile_app/screens/parcel_list/parcel_list_screen.dart';
import 'package:mobile_app/screens/sync/sync_screen.dart';
import 'package:mobile_app/screens/tree_details/tree_details_screen.dart';
import 'package:mobile_app/screens/tree_update/tree_update_form_screen.dart';
import 'package:mobile_app/screens/tree_update/tree_update_photo_screen.dart';
import 'package:mobile_app/screens/trees_list/tree_list_screen.dart';
import 'package:mobile_app/services/session_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DatabaseSeeder.seed();
    final hasSession = await SessionService.instance.restoreSession();
    runApp(MyApp(
      initialRoute: hasSession ? AppRoutes.parcelList : AppRoutes.login,
    ));
  } catch (e, stack) {
    debugPrint('STARTUP ERROR: $e');
    debugPrint('$stack');
    runApp(MaterialApp(
      home: Scaffold(body: Center(child: Text('Error: $e'))),
    ));
  }
}
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncProvider()..init()),
      ],
      child: MaterialApp(
        title:                    'Un Touriste — Un Arbre',
        debugShowCheckedModeBanner: false,
        theme:                    AppTheme.light,
        darkTheme:                AppTheme.dark,
        themeMode:                ThemeMode.system,
        initialRoute:             initialRoute,
        routes: {
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