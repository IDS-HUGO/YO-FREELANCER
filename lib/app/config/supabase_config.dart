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
  static const String supabaseUrl = 'https://gnznfgjejqzhsfsuykkk.supabase.co/rest/v1/';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imduem5mZ2planF6aHNmc3V5a2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MDc4OTAsImV4cCI6MjEwMDQ4Mzg5MH0.7cI4GPNmVpeRgnhqUK6VmqBMKxeS6YzwaexccUBgQu8';

  // ── Nombres de tablas ────────────────────────────────────────────────────
  static const String usersTable       = 'users';
  static const String servicesTable    = 'services';
  static const String bookingsTable    = 'bookings';
  static const String paymentsTable    = 'payments';
  static const String reviewsTable     = 'reviews';
  static const String categoriesTable  = 'categories';
  static const String profilesTable    = 'profiles';
  static const String urgentTasksTable = 'urgent_tasks';
  static const String sanctionsTable   = 'sanctions';
  static const String badgesTable      = 'badges';

  // ── Tablas del roadmap v2 (ver supabase_migration_v2.sql) ─────────────────
  static const String notificationsTable          = 'notifications';
  static const String taskRequestsTable           = 'task_requests';
  static const String taskApplicationsTable       = 'task_applications';
  static const String walletAccountsTable         = 'wallet_accounts';
  static const String walletTransactionsTable     = 'wallet_transactions';
  static const String badgeCatalogTable           = 'badge_catalog';
  static const String sanctionAppealsTable        = 'sanction_appeals';
  static const String supportRequestsTable        = 'support_requests';
  static const String volunteeringEventsTable     = 'volunteering_events';
  static const String volunteeringParticipantsTable = 'volunteering_participants';
  static const String communityEventsTable        = 'community_events';
  static const String artistProfilesTable         = 'artist_profiles';

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
