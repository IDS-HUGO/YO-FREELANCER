// lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart
// Re-exporta desde el datasource donde está co-ubicado
export '../../data/datasources/notification_remote_datasource.dart'
    show
        NotificationViewModel,
        NotificationState,
        notificationViewModelProvider,
        notificationDataSourceProvider,
        notificationStreamProvider,
        NotificationEntity,
        NotificationType;
