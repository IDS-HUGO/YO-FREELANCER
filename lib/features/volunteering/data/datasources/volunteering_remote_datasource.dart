// lib/features/volunteering/data/datasources/volunteering_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

enum VolunteeringType {
  anual, temporada, emergencia;

  static VolunteeringType fromRaw(String raw) {
    const map = {'ANUAL': anual, 'TEMPORADA': temporada, 'EMERGENCIA': emergencia};
    return map[raw] ?? anual;
  }

  String get displayName {
    switch (this) {
      case VolunteeringType.anual:      return 'Anual';
      case VolunteeringType.temporada:  return 'De temporada';
      case VolunteeringType.emergencia: return 'Emergencia';
    }
  }

  String get icon {
    switch (this) {
      case VolunteeringType.anual:      return '🌍';
      case VolunteeringType.temporada:  return '🍂';
      case VolunteeringType.emergencia: return '🚨';
    }
  }
}

enum ParticipationStatus {
  interesado, confirmado;

  static ParticipationStatus fromRaw(String raw) => raw == 'CONFIRMADO' ? confirmado : interesado;
}

class VolunteeringEventEntity {
  final String id;
  final String title;
  final String description;
  final VolunteeringType type;
  final String? bannerImageUrl;
  final String? address;
  final DateTime startsAt;
  final DateTime? endsAt;

  const VolunteeringEventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.bannerImageUrl,
    this.address,
    required this.startsAt,
    this.endsAt,
  });

  factory VolunteeringEventEntity.fromJson(Map<String, dynamic> json) {
    return VolunteeringEventEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: VolunteeringType.fromRaw(json['type'] as String? ?? 'ANUAL'),
      bannerImageUrl: json['banner_image_url'] as String?,
      address: json['address'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
    );
  }
}

class VolunteeringRemoteDataSource {
  final SupabaseClient _client;
  VolunteeringRemoteDataSource(this._client);

  Future<List<VolunteeringEventEntity>> getActiveEvents() async {
    final nowIso = DateTime.now().toIso8601String();
    final data = await _client
        .from(SupabaseConfig.volunteeringEventsTable)
        .select()
        .eq('is_active', true)
        .or('ends_at.is.null,ends_at.gte.$nowIso')
        .order('starts_at', ascending: true);

    return (data as List)
        .map((e) => VolunteeringEventEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getJoinedEventIds(String yoerId) async {
    final data = await _client
        .from(SupabaseConfig.volunteeringParticipantsTable)
        .select('event_id')
        .eq('yoer_id', yoerId);

    return (data as List).map((e) => e['event_id'] as String).toList();
  }

  Future<void> joinEvent(String eventId, String yoerId) async {
    await _client.from(SupabaseConfig.volunteeringParticipantsTable).insert({
      'event_id': eventId,
      'yoer_id': yoerId,
    });
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class VolunteeringState {
  final bool isLoading;
  final List<VolunteeringEventEntity> events;
  final List<String> joinedEventIds;
  final String? error;
  final String? successMessage;

  const VolunteeringState({
    this.isLoading = false,
    this.events = const [],
    this.joinedEventIds = const [],
    this.error,
    this.successMessage,
  });

  bool hasJoined(String eventId) => joinedEventIds.contains(eventId);

  VolunteeringState copyWith({
    bool? isLoading,
    List<VolunteeringEventEntity>? events,
    List<String>? joinedEventIds,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VolunteeringState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      joinedEventIds: joinedEventIds ?? this.joinedEventIds,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class VolunteeringViewModel extends StateNotifier<VolunteeringState> {
  final VolunteeringRemoteDataSource _ds;
  VolunteeringViewModel(this._ds) : super(const VolunteeringState());

  Future<void> load(String yoerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _ds.getActiveEvents();
      final joined = await _ds.getJoinedEventIds(yoerId);
      state = state.copyWith(isLoading: false, events: events, joinedEventIds: joined);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> join(String eventId, String yoerId) async {
    try {
      await _ds.joinEvent(eventId, yoerId);
      state = state.copyWith(
        joinedEventIds: [...state.joinedEventIds, eventId],
        successMessage: '¡Listo! Quedaste registrado como interesado.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final volunteeringDataSourceProvider = Provider<VolunteeringRemoteDataSource>((ref) {
  return VolunteeringRemoteDataSource(Supabase.instance.client);
});

final volunteeringViewModelProvider =
    StateNotifierProvider<VolunteeringViewModel, VolunteeringState>((ref) {
  return VolunteeringViewModel(ref.read(volunteeringDataSourceProvider));
});
