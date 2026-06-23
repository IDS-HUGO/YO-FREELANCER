// lib/app/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/services/data/datasources/service_remote_datasource.dart';
import '../../features/bookings/data/datasources/booking_remote_datasource.dart';
import '../../features/payments/data/datasources/payment_remote_datasource.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final supabase = Supabase.instance.client;

  // ── Supabase ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<SupabaseClient>(supabase);

  // ── Auth ──────────────────────────────────────────────────────────────────
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(supabase),
  );
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  // ── Services ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<ServiceRemoteDataSource>(
    ServiceRemoteDataSource(supabase),
  );

  // ── Bookings ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<BookingRemoteDataSource>(
    BookingRemoteDataSource(supabase),
  );

  // ── Payments ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<PaymentRemoteDataSource>(
    PaymentRemoteDataSource(supabase),
  );
}
