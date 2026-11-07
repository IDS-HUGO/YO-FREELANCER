/// Configuración de Supabase para YO FREE-LANCER
///
/// URL y anon key se leen de --dart-define en tiempo de build:
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gnznfgjejqzhsfsuykkk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imduem5mZ2planF6aHNmc3V5a2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MDc4OTAsImV4cCI6MjEwMDQ4Mzg5MH0.7cI4GPNmVpeRgnhqUK6VmqBMKxeS6YzwaexccUBgQu8',
  );

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
  static const String paymentCardsTable = 'payment_cards';

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

  static const String profileImagesBucket  = 'profile-images';
  static const String serviceImagesBucket  = 'service-images';
  static const String coverImagesBucket    = 'cover-images';

  static const String createCheckoutFn = 'create-checkout-session';
  static const String sendNotificationFn = 'send-notification';

  static const String bookingsChannel  = 'bookings-channel';
  static const String messagesChannel  = 'messages-channel';
}