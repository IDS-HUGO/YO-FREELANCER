// lib/app/config/backend_mode.dart

/// Fuente de datos que usa la app para auth/perfil/"proyectos" (servicios).
///
/// Se elige por configuración de build, **nunca en runtime**: no hay
/// detección automática de caídas ni cambio de backend mientras la app
/// corre. Ver docs/BACKEND_CONFIG.md.
enum BackendMode {
  /// Habla directo con Supabase (Auth + Postgres + Storage). Requiere
  /// `SUPABASE_URL`/`SUPABASE_ANON_KEY` (ver `SupabaseConfig`).
  supabase,

  /// Habla con un backend propio (Node/Express, desplegado por separado —
  /// ver el proyecto standalone `yofreelancer-backend`). Ese backend maneja
  /// su propia autenticación; no se usa la anon key de Supabase para nada.
  ownBackend,
}

/// Traduce el valor crudo de `--dart-define=BACKEND_MODE=...` al enum.
/// Función pura (sin `String.fromEnvironment`) para poder probar ambas
/// ramas sin depender de cómo se invocó `flutter test`.
BackendMode parseBackendMode(String raw) {
  return raw == 'own_backend' ? BackendMode.ownBackend : BackendMode.supabase;
}

class BackendModeConfig {
  const BackendModeConfig._();

  /// Selecciona el modo con:
  ///   flutter run --dart-define=BACKEND_MODE=own_backend
  /// Cualquier otro valor (incluido "no especificado") usa Supabase, que es
  /// el comportamiento histórico de la app.
  static const String _raw = String.fromEnvironment('BACKEND_MODE', defaultValue: 'supabase');

  static final BackendMode current = parseBackendMode(_raw);
}
