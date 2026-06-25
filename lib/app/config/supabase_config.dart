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
  static const String supabaseUrl = 'https://qomlpwvnqqrvalzvkqqr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFvbWxwd3ZucXFydmFsenZra3FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyMTcyMTEsImV4cCI6MjA5Nzc5MzIxMX0.mKHosA4u8Qav5wkG8BKgZVw6EHxh9vf4yB7IhPQS5CA';

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
