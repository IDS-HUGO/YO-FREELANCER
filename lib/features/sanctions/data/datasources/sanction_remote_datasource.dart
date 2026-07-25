// lib/features/sanctions/data/datasources/sanction_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

enum SanctionSeverity {
  warning, amonestacion, suspension, ban;

  static SanctionSeverity fromRaw(String raw) {
    const map = {
      'WARNING': warning,
      'AMONESTACION': amonestacion,
      'SUSPENSION': suspension,
      'BAN': ban,
    };
    return map[raw] ?? warning;
  }

  String get displayName {
    switch (this) {
      case SanctionSeverity.warning:      return 'Advertencia';
      case SanctionSeverity.amonestacion: return 'Amonestación';
      case SanctionSeverity.suspension:   return 'Suspensión';
      case SanctionSeverity.ban:          return 'Baneo';
    }
  }
}

enum AppealStatus {
  pendiente, aprobada, rechazada;

  static AppealStatus fromRaw(String raw) {
    const map = {'PENDIENTE': pendiente, 'APROBADA': aprobada, 'RECHAZADA': rechazada};
    return map[raw] ?? pendiente;
  }

  String get displayName {
    switch (this) {
      case AppealStatus.pendiente:  return 'En revisión';
      case AppealStatus.aprobada:   return 'Aprobada';
      case AppealStatus.rechazada:  return 'Rechazada';
    }
  }
}

class SanctionEntity {
  final String id;
  final String userId;
  final String reason;
  final String? description;
  final SanctionSeverity severity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<SanctionAppealEntity> appeals;

  const SanctionEntity({
    required this.id,
    required this.userId,
    required this.reason,
    this.description,
    required this.severity,
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
    this.appeals = const [],
  });

  factory SanctionEntity.fromJson(Map<String, dynamic> json) {
    final appealsJson = json['sanction_appeals'] as List? ?? [];
    return SanctionEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      severity: SanctionSeverity.fromRaw(json['severity'] as String? ?? 'WARNING'),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      appeals: appealsJson
          .map((e) => SanctionAppealEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SanctionAppealEntity {
  final String id;
  final String sanctionId;
  final String userId;
  final String message;
  final AppealStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const SanctionAppealEntity({
    required this.id,
    required this.sanctionId,
    required this.userId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SanctionAppealEntity.fromJson(Map<String, dynamic> json) {
    return SanctionAppealEntity(
      id: json['id'] as String,
      sanctionId: json['sanction_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      status: AppealStatus.fromRaw(json['status'] as String? ?? 'PENDIENTE'),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    );
  }
}

class SanctionRemoteDataSource {
  final SupabaseClient _client;
  SanctionRemoteDataSource(this._client);

  Future<List<SanctionEntity>> getForUser(String userId) async {
    final data = await _client
        .from(SupabaseConfig.sanctionsTable)
        .select('*, sanction_appeals(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => SanctionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> appeal(String sanctionId, String userId, String message) async {
    await _client.from(SupabaseConfig.sanctionAppealsTable).insert({
      'sanction_id': sanctionId,
      'user_id': userId,
      'message': message,
    });
  }

  Future<void> requestSupportCall(String userId, String reason, {String? message}) async {
    await _client.from(SupabaseConfig.supportRequestsTable).insert({
      'user_id': userId,
      'reason': reason,
      if (message != null) 'message': message,
    });
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class SanctionState {
  final bool isLoading;
  final List<SanctionEntity> sanctions;
  final String? error;
  final String? successMessage;

  const SanctionState({
    this.isLoading = false,
    this.sanctions = const [],
    this.error,
    this.successMessage,
  });

  SanctionState copyWith({
    bool? isLoading,
    List<SanctionEntity>? sanctions,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SanctionState(
      isLoading: isLoading ?? this.isLoading,
      sanctions: sanctions ?? this.sanctions,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SanctionViewModel extends StateNotifier<SanctionState> {
  final SanctionRemoteDataSource _ds;
  SanctionViewModel(this._ds) : super(const SanctionState());

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ds.getForUser(userId);
      state = state.copyWith(isLoading: false, sanctions: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> appeal(String sanctionId, String userId, String message) async {
    try {
      await _ds.appeal(sanctionId, userId, message);
      await load(userId);
      state = state.copyWith(successMessage: 'Apelación enviada, la revisaremos pronto.');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> requestSupportCall(String userId, String reason, {String? message}) async {
    try {
      await _ds.requestSupportCall(userId, reason, message: message);
      state = state.copyWith(successMessage: 'Solicitud enviada, te contactaremos pronto.');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

// Providers
final sanctionDataSourceProvider = Provider<SanctionRemoteDataSource>((ref) {
  return SanctionRemoteDataSource(Supabase.instance.client);
});

final sanctionViewModelProvider =
    StateNotifierProvider<SanctionViewModel, SanctionState>((ref) {
  return SanctionViewModel(ref.read(sanctionDataSourceProvider));
});
