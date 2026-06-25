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
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/services/presentation/screens/create_service_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'app_routes.dart';

// ── Notifier que escucha cambios de auth y refresca el router ─────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  _RouterNotifier(this._ref) {
    // Escucha cambios en el estado de auth y notifica al router
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

// ── Provider del router (se crea UNA sola vez) ─────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState      = ref.read(authViewModelProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading       = authState.isLoading;
      final user            = authState.user;
      final loc             = state.matchedLocation;

      // Durante carga inicial, quedarse en splash
      if (isLoading && loc != AppRoutes.splash) return AppRoutes.splash;

      // Rutas completamente públicas (sin autenticación)
      final publicRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
      ];

      // Rutas accesibles como "invitado" (sin cuenta)
      final guestRoutes = [
        AppRoutes.clientHome,
        AppRoutes.serviceDetail,
      ];

      // Si no está autenticado
      if (!isAuthenticated) {
        // Si está en una ruta pública o de invitado, dejar pasar
        if (publicRoutes.contains(loc)) return null;
        if (guestRoutes.any((r) => loc.startsWith(r.replaceAll(':id', '')))) {
          return null;
        }
        // Cualquier otra ruta protegida → welcome
        return AppRoutes.welcome;
      }

      // ── Usuario autenticado ───────────────────────────────────────────────

      // Si viene desde splash o rutas de auth → redirigir al home correcto
      if (publicRoutes.contains(loc) || loc == AppRoutes.splash) {
        if (user?.isYoer == true) return AppRoutes.yoerHome;
        return AppRoutes.clientHome;
      }

      // YOER intentando acceder a rutas exclusivas de cliente (excepto shared)
      if (user?.isYoer == true && loc.startsWith('/client')) {
        return AppRoutes.yoerHome;
      }
      // Cliente intentando acceder a rutas exclusivas de yoer
      if (user?.isClient == true && loc.startsWith('/yoer')) {
        return AppRoutes.clientHome;
      }

      return null;
    },
    routes: [
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

      // ── YOER shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainScaffold(userType: UserType.yoer, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.yoerHome,
            pageBuilder: (_, state) => _fadePage(const YoerHomeScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerVitrina,
            pageBuilder: (_, state) => _fadePage(const YoerVitrinaScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.yoerProfile,
            pageBuilder: (_, state) => _fadePage(const YoerProfileScreen(), state),
          ),
        ],
      ),

      // ── CLIENT shell (accesible como invitado) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainScaffold(userType: UserType.client, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            pageBuilder: (_, state) => _fadePage(const ClientHomeScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.clientBookings,
            pageBuilder: (_, state) => _fadePage(const ClientBookingsScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            pageBuilder: (_, state) => _fadePage(const ClientProfileScreen(), state),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Página no encontrada', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.welcome),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ── Transiciones ──────────────────────────────────────────────────────────────
CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}
