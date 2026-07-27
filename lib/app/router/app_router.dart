// lib/app/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/yoer/presentation/screens/yoer_home_screen.dart';
import '../../features/yoer/presentation/screens/yoer_vitrina_screen.dart';
import '../../features/yoer/presentation/screens/yoer_profile_screen.dart';
import '../../features/agenda/presentation/screens/agenda_screen.dart';
import '../../features/tasks/presentation/screens/radar_screen.dart';
import '../../features/tasks/presentation/screens/client_tasks_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/services/presentation/screens/create_service_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../features/payments/presentation/screens/payment_methods_screen.dart';
import '../../features/client/presentation/screens/client_home_screen.dart';
import '../../features/client/presentation/screens/client_bookings_screen.dart';
import '../../features/client/presentation/screens/client_profile_screen.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/kyc_consent_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/sanctions/presentation/screens/sanctions_screen.dart';
import '../../features/badges/presentation/screens/badges_screen.dart';
import '../../features/ranking/presentation/screens/ranking_screen.dart';
import '../../features/volunteering/presentation/screens/volunteering_screen.dart';
import '../../features/artist/presentation/screens/artist_mode_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'app_routes.dart';

// ── Notifier que escucha cambios de auth y refresca el router ─────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  _RouterNotifier(this._ref) {
    _sub = _ref.listen<AuthState>(
      authViewModelProvider,
      (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

// ── Singleton del GoRouter ────────────────────────────────────────────────────
// Se crea UNA sola vez. ref.read (no watch) para no invalidar este provider
// cuando cambia el notifier. El refreshListenable se encarga de re-evaluar
// el redirect sin recrear el router.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Mantener vivo el provider mientras la app viva
  ref.keepAlive();

  // Leer sin observar — el GoRouter NO se recrea cuando cambia auth
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState       = ref.read(authViewModelProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading       = authState.isLoading;
      final user            = authState.user;
      final loc             = state.matchedLocation;

      // Rutas públicas
      const publicRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.splash,
      ];

      // ── Cargando: mantener en splash si ya está ahí
      if (isLoading && loc == AppRoutes.splash) {
        return null;
      }

      // ── No autenticado ────────────────────────────────────────────────────
      if (!isAuthenticated) {
        // Si ya está en una ruta pública → no redirigir
        if (publicRoutes.contains(loc)) {
          // Salir del splash hacia welcome cuando terminó de cargar
          if (loc == AppRoutes.splash) return AppRoutes.welcome;
          return null;
        }
        // Si está en client/home puede explorar sin cuenta
        if (loc.startsWith('/client')) return null;
        // Cualquier otra ruta protegida → welcome
        return AppRoutes.welcome;
      }

      // ── Autenticado ───────────────────────────────────────────────────────

      // Verificación facial de identidad (Tarea 2, ver docs/KYC.md): aplica
      // a YOER y Cliente por igual. Mientras no esté 'verified', se fuerza
      // /kyc — salvo que ya esté ahí, para no crear un loop de redirect.
      if (user != null && !user.kycStatus.isVerified) {
        return loc == AppRoutes.kyc ? null : AppRoutes.kyc;
      }

      // Si está en una ruta de auth, en splash, o ya verificó KYC y sigue en
      // /kyc → mandar al home correcto
      if (publicRoutes.contains(loc) || loc == AppRoutes.kyc) {
        return user?.isYoer == true ? AppRoutes.yoerHome : AppRoutes.clientHome;
      }

      // YOER intentando entrar a rutas de cliente (excepto client/home público)
      if (user?.isYoer == true && loc.startsWith('/client') && loc != AppRoutes.clientHome) {
        return AppRoutes.yoerHome;
      }
      // Cliente intentando entrar a rutas de yoer
      if (user?.isClient == true && loc.startsWith('/yoer')) {
        return AppRoutes.clientHome;
      }

      return null; // Sin redirección: dejar pasar
    },
    routes: [
      // ── Auth / splash ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, state) => _slidePage(const WelcomeScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _slidePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, state) => _slidePage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.kyc,
        pageBuilder: (_, state) => _slidePage(const KycConsentScreen(), state),
      ),

      // ── YOER shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainScaffold(userType: UserType.yoer, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.yoerHome,
            pageBuilder: (_, state) =>
                _fadePage(const YoerHomeScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerVitrina,
            pageBuilder: (_, state) =>
                _fadePage(const YoerVitrinaScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerProfile,
            pageBuilder: (_, state) =>
                _fadePage(const YoerProfileScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerAgenda,
            pageBuilder: (_, state) =>
                _fadePage(const AgendaScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerRadar,
            pageBuilder: (_, state) =>
                _fadePage(const RadarScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerWallet,
            pageBuilder: (_, state) =>
                _fadePage(const WalletScreen(), state),
          ),
        ],
      ),

      // ── CLIENT shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainScaffold(userType: UserType.client, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            pageBuilder: (_, state) =>
                _fadePage(const ClientHomeScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.clientBookings,
            pageBuilder: (_, state) =>
                _fadePage(const ClientBookingsScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            pageBuilder: (_, state) =>
                _fadePage(const ClientProfileScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.clientTasks,
            pageBuilder: (_, state) =>
                _fadePage(const ClientTasksScreen(), state),
          ),
        ],
      ),

      // ── Pantallas compartidas ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.createService,
        builder: (_, __) => const CreateServiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingDetail,
        builder: (context, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) =>
            PaymentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (_, __) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.sanctions,
        builder: (_, __) => const SanctionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.badges,
        builder: (_, __) => const BadgesScreen(),
      ),
      GoRoute(
        path: AppRoutes.ranking,
        builder: (_, __) => const RankingScreen(),
      ),
      GoRoute(
        path: AppRoutes.volunteering,
        builder: (_, __) => const VolunteeringScreen(),
      ),
      GoRoute(
        path: AppRoutes.artistMode,
        builder: (_, __) => const ArtistModeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: context.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Ups!',
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Página no encontrada: ${state.matchedLocation}',
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.welcome),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ── Transiciones ──────────────────────────────────────────────────────────────
CustomTransitionPage<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}
