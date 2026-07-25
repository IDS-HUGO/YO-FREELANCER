// lib/features/notifications/data/datasources/notification_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

enum NotificationType {
  bookingSolicitud,
  bookingConfirmada,
  bookingCancelada,
  bookingCompletada,
  nuevaPostulacion,
  postulacionAceptada,
  nuevaInsignia,
  amonestacion,
  apelacionResuelta,
  pagoRecibido,
  eventoCercano,
  sistema;

  static NotificationType fromRaw(String raw) {
    const map = {
      'BOOKING_SOLICITUD': bookingSolicitud,
      'BOOKING_CONFIRMADA': bookingConfirmada,
      'BOOKING_CANCELADA': bookingCancelada,
      'BOOKING_COMPLETADA': bookingCompletada,
      'NUEVA_POSTULACION': nuevaPostulacion,
      'POSTULACION_ACEPTADA': postulacionAceptada,
      'NUEVA_INSIGNIA': nuevaInsignia,
      'AMONESTACION': amonestacion,
      'APELACION_RESUELTA': apelacionResuelta,
      'PAGO_RECIBIDO': pagoRecibido,
      'EVENTO_CERCANO': eventoCercano,
      'SISTEMA': sistema,
    };
    return map[raw] ?? sistema;
  }

  String get icon {
    switch (this) {
      case NotificationType.bookingSolicitud:    return '📅';
      case NotificationType.bookingConfirmada:   return '✅';
      case NotificationType.bookingCancelada:    return '❌';
      case NotificationType.bookingCompletada:   return '🏁';
      case NotificationType.nuevaPostulacion:    return '📨';
      case NotificationType.postulacionAceptada: return '🎯';
      case NotificationType.nuevaInsignia:       return '🏅';
      case NotificationType.amonestacion:        return '⚠️';
      case NotificationType.apelacionResuelta:   return '⚖️';
      case NotificationType.pagoRecibido:        return '💰';
      case NotificationType.eventoCercano:       return '📍';
      case NotificationType.sistema:             return '🔔';
    }
  }
}

class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromRaw(json['type'] as String? ?? 'SISTEMA'),
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationRemoteDataSource {
  final SupabaseClient _client;
  NotificationRemoteDataSource(this._client);

  Future<List<NotificationEntity>> getForUser(String userId) async {
    final data = await _client
        .from(SupabaseConfig.notificationsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (data as List)
        .map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<NotificationEntity>> watchForUser(String userId) {
    return _client
        .from(SupabaseConfig.notificationsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['user_id'] == userId)
            .map((r) => NotificationEntity.fromJson(r))
            .toList());
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from(SupabaseConfig.notificationsTable)
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from(SupabaseConfig.notificationsTable)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class NotificationState {
  final bool isLoading;
  final List<NotificationEntity> notifications;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationEntity>? notifications,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationViewModel extends StateNotifier<NotificationState> {
  final NotificationRemoteDataSource _ds;
  NotificationViewModel(this._ds) : super(const NotificationState());

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ds.getForUser(userId);
      state = state.copyWith(isLoading: false, notifications: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _ds.markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == id
                ? NotificationEntity(
                    id: n.id, userId: n.userId, type: n.type, title: n.title,
                    body: n.body, data: n.data, isRead: true, createdAt: n.createdAt)
                : n)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _ds.markAllAsRead(userId);
      await load(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final notificationDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(Supabase.instance.client);
});

final notificationViewModelProvider =
    StateNotifierProvider<NotificationViewModel, NotificationState>((ref) {
  return NotificationViewModel(ref.read(notificationDataSourceProvider));
});

/// Stream en vivo usado para el contador de la campanita (no requiere loading manual).
final notificationStreamProvider =
    StreamProvider.family<List<NotificationEntity>, String>((ref, userId) {
  return ref.read(notificationDataSourceProvider).watchForUser(userId);
});
