import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'store/store.dart';
import 'sync/sync_service.dart';
import 'theme/app_theme.dart';
import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sync cloud optionnelle (no-op tant que Supabase n'est pas configuré).
  await SyncService.instance.init();
  final store = Store();
  await store.init();
  runApp(
    ChangeNotifierProvider.value(value: store, child: const RobertoApp()),
  );
}

class RobertoApp extends StatelessWidget {
  const RobertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeKey = context.select<Store, String>((s) => s.theme);
    final id = AppThemeIdX.fromKey(themeKey);
    final t = AppTokens.of(id);

    // Match system UI overlay to theme.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            id == AppThemeId.sportDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            id == AppThemeId.sportDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Programme 6 Mois',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: t.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: t.accent,
          brightness:
              id == AppThemeId.sportDark ? Brightness.dark : Brightness.light,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const AppShell(),
    );
  }
}
