// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app/config/supabase_config.dart';
import 'app/di/injection.dart';
import 'app/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija: portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setDefaultLocale('es');
  await initializeDateFormatting('es');

  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey, // ignore: deprecated_member_use
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Configurar DI
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: YoFreeLancerApp(),
    ),
  );
}

class YoFreeLancerApp extends ConsumerWidget {
  const YoFreeLancerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.read: el router es singleton y no cambia nunca,
    // ref.watch aquí causaría recostruir MaterialApp entero al cambiar auth.
    final router = ref.read(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'YO FREE-LANCER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
