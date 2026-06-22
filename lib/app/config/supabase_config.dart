// lib/app/config/supabase_config.dart

/// Configuración de Supabase para YO FREE-LANCER
///
/// 🔧 SETUP: Crea un proyecto en https://supabase.com y rellena estos valores.
///
/// En Supabase Dashboard → Project Settings → API:
///   - Project URL  → [SUPABASE_URL]
///   - anon public  → [SUPABASE_ANON_KEY]
class SupabaseConfig {
  // ────────────────────────────────────────────────────────────────────────
  // Reemplaza con tus credenciales reales de Supabase
  // ────────────────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://TU_PROYECTO.supabase.co';
  static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';

  // ── Nombres de tablas ────────────────────────────────────────────────────
  static const String usersTable       = 'users';
  static const String servicesTable    = 'services';
  static const String bookingsTable    = 'bookings';
  static const String paymentsTable    = 'payments';
  static const String reviewsTable     = 'reviews';
  static const String categoriesTable  = 'categories';
  static const String profilesTable    = 'profiles';

  // ── Storage buckets ──────────────────────────────────────────────────────
  static const String profileImagesBucket  = 'profile-images';
  static const String serviceImagesBucket  = 'service-images';
  static const String coverImagesBucket    = 'cover-images';

  // ── Edge Functions ────────────────────────────────────────────────────────
  static const String createCheckoutFn = 'create-checkout-session';
  static const String sendNotificationFn = 'send-notification';

  // ── Realtime channels ─────────────────────────────────────────────────────
  static const String bookingsChannel  = 'bookings-channel';
  static const String messagesChannel  = 'messages-channel';
}
