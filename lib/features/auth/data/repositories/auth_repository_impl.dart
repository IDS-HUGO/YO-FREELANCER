// lib/features/auth/data/repositories/auth_repository_impl.dart
export '../../domain/repositories/auth_repository.dart'
    show SupabaseAuthRepositoryImpl;
import '../../domain/repositories/auth_repository.dart';

/// Alias retrocompatible: el impl de Supabase se renombró a
/// [SupabaseAuthRepositoryImpl] al agregar la implementación alterna del
/// backend propio (ver docs/BACKEND_CONFIG.md). Se mantiene este alias para
/// no romper imports existentes que usaban `AuthRepositoryImpl`.
typedef AuthRepositoryImpl = SupabaseAuthRepositoryImpl;
