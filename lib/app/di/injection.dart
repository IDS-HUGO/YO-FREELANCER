// lib/app/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_mode.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_node_datasource.dart';
import '../../features/auth/data/datasources/kyc_remote_datasource.dart';
import '../../features/auth/data/repositories/node_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/kyc_repository.dart';
import '../../features/services/data/datasources/service_remote_datasource.dart';
import '../../features/services/data/datasources/service_node_datasource.dart';
import '../../features/services/data/repositories/node_service_repository_impl.dart';
import '../../features/services/domain/repositories/service_repository.dart';
import '../../features/bookings/data/datasources/booking_remote_datasource.dart';
import '../../features/payments/data/datasources/payment_remote_datasource.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final supabase = Supabase.instance.client;

  // ── Supabase ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<SupabaseClient>(supabase);

  // ── Auth + Services ("proyectos"): Supabase o backend propio ────────────
  // Elegido en tiempo de build por BackendModeConfig.current (--dart-define, ver
  // lib/app/config/backend_mode.dart y docs/BACKEND_CONFIG.md). Nunca cambia
  // en runtime — no hay detección de caídas ni failover automático. El
  // resto de la app siempre depende de las interfaces AuthRepository /
  // ServiceRepository, sin saber cuál de las dos implementaciones está activa.
  getIt.registerSingleton<AuthRemoteDataSource>(AuthRemoteDataSource(supabase));
  getIt.registerSingleton<ServiceRemoteDataSource>(ServiceRemoteDataSource(supabase));

  switch (BackendModeConfig.current) {
    case BackendMode.supabase:
      getIt.registerSingleton<AuthRepository>(
        SupabaseAuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
      );
      getIt.registerSingleton<ServiceRepository>(
        SupabaseServiceRepositoryImpl(getIt<ServiceRemoteDataSource>()),
      );
      break;

    case BackendMode.ownBackend:
      final authNodeDataSource = AuthNodeDataSource();
      getIt.registerSingleton<AuthNodeDataSource>(authNodeDataSource);
      getIt.registerSingleton<AuthRepository>(
        NodeAuthRepositoryImpl(authNodeDataSource),
      );
      getIt.registerSingleton<ServiceRepository>(
        NodeServiceRepositoryImpl(
          ServiceNodeDataSource(tokenProvider: () => authNodeDataSource.currentToken),
        ),
      );
      break;
  }

  // ── Verificación facial (KYC, Tarea 2) ───────────────────────────────────
  // Proyecto standalone separado (yofreelancer-kyc-service), llamado directo
  // desde la app por su propia URL, sin relación con BackendMode ni con el
  // backend propio — ver docs/KYC.md. Falla "cerrado" si no responde; no
  // aplica ningún tipo de conmutación.
  getIt.registerSingleton<KycRepository>(
    KycRepositoryImpl(KycRemoteDataSource()),
  );

  // ── Bookings ──────────────────────────────────────────────────────────────
  // Fuera de alcance de BackendMode (ver AUDIT.md / plan aprobado): siempre
  // llama a Supabase directamente, sin importar el modo elegido.
  getIt.registerSingleton<BookingRemoteDataSource>(
    BookingRemoteDataSource(supabase),
  );

  // ── Payments ──────────────────────────────────────────────────────────────
  // Fuera de alcance de BackendMode, ídem bookings.
  getIt.registerSingleton<PaymentRemoteDataSource>(
    PaymentRemoteDataSource(supabase),
  );
}
