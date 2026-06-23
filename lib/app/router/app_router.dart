// lib/app/router/app_router.dart
import 'dart:async';
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

// ── Rutas ─────────────────────────────────────────────────────────────────────
abstract class AppRoutes {
  static const splash         = '/splash';
  static const welcome        = '/welcome';
  static const login          = '/login';
  static const register       = '/register';

  // YOER
  static const yoerHome       = '/yoer/home';
  static const yoerVitrina    = '/yoer/vitrina';
  static const yoerProfile    = '/yoer/profile';
  static const yoerAgenda     = '/yoer/agenda';
  static const yoerRadar      = '/yoer/radar';

  // CLIENT
  static const clientHome     = '/client/home';
  static const clientBookings = '/client/bookings';
  static const clientProfile  = '/client/profile';
  static const clientPayments = '/client/payments';

  // Shared
  static const serviceDetail  = '/service/:id';
  static const createService  = '/service/create';
  static const bookingDetail  = '/booking/:id';
  static const payment        = '/payment/:bookingId';
}

// ── Provider del router ───────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authViewModelProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading       = authState.isLoading;
      final user            = authState.user;
      final loc             = state.matchedLocation;

      // Durante carga inicial, ir a splash
      if (isLoading && loc != AppRoutes.splash) return AppRoutes.splash;

      // Pantallas públicas
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
      ];

      if (!isAuthenticated) {
        if (publicRoutes.contains(loc)) return null;
        return AppRoutes.welcome;
      }

      // Redirigir según tipo de usuario
      if (publicRoutes.contains(loc)) {
        if (user?.isYoer == true) return AppRoutes.yoerHome;
        return AppRoutes.clientHome;
      }

      // YOER tratando de acceder a rutas de client o viceversa
      if (user?.isYoer == true && loc.startsWith('/client')) {
        return AppRoutes.yoerHome;
      }
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

      // ── CLIENT shell ──────────────────────────────────────────────────────
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

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
