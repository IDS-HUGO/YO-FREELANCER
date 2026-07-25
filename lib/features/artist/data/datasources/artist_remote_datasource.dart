// lib/features/artist/data/datasources/artist_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

enum ManagerType {
  self, managed;

  static ManagerType fromRaw(String raw) => raw == 'MANAGED' ? managed : self;
  String get name => this == self ? 'SELF' : 'MANAGED';
  String get displayName => this == self ? 'Yo mismo' : 'Vinculado a un manager';
}

class ArtistProfileEntity {
  final String userId;
  final String? stageName;
  final ManagerType managerType;
  final String? managerName;
  final String? managerContact;
  final bool isVerified;
  final DateTime? verificationRequestedAt;

  const ArtistProfileEntity({
    required this.userId,
    this.stageName,
    this.managerType = ManagerType.self,
    this.managerName,
    this.managerContact,
    this.isVerified = false,
    this.verificationRequestedAt,
  });

  factory ArtistProfileEntity.fromJson(Map<String, dynamic> json) {
    return ArtistProfileEntity(
      userId: json['user_id'] as String,
      stageName: json['stage_name'] as String?,
      managerType: ManagerType.fromRaw(json['manager_type'] as String? ?? 'SELF'),
      managerName: json['manager_name'] as String?,
      managerContact: json['manager_contact'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationRequestedAt: json['verification_requested_at'] != null
          ? DateTime.parse(json['verification_requested_at'] as String)
          : null,
    );
  }
}

class ArtistRemoteDataSource {
  final SupabaseClient _client;
  ArtistRemoteDataSource(this._client);

  Future<ArtistProfileEntity?> getForUser(String userId) async {
    final data = await _client
        .from(SupabaseConfig.artistProfilesTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return data == null ? null : ArtistProfileEntity.fromJson(data);
  }

  Future<ArtistProfileEntity> save({
    required String userId,
    String? stageName,
    required ManagerType managerType,
    String? managerName,
    String? managerContact,
  }) async {
    final data = await _client.from(SupabaseConfig.artistProfilesTable).upsert({
      'user_id': userId,
      'stage_name': stageName,
      'manager_type': managerType.name,
      'manager_name': managerName,
      'manager_contact': managerContact,
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return ArtistProfileEntity.fromJson(data);
  }

  Future<void> requestVerification(String userId) async {
    await _client
        .from(SupabaseConfig.artistProfilesTable)
        .update({'verification_requested_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId);
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class ArtistState {
  final bool isLoading;
  final ArtistProfileEntity? profile;
  final String? error;
  final String? successMessage;

  const ArtistState({this.isLoading = false, this.profile, this.error, this.successMessage});

  ArtistState copyWith({
    bool? isLoading,
    ArtistProfileEntity? profile,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ArtistState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ArtistViewModel extends StateNotifier<ArtistState> {
  final ArtistRemoteDataSource _ds;
  ArtistViewModel(this._ds) : super(const ArtistState());

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _ds.getForUser(userId);
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> save(String userId, {String? stageName, required ManagerType managerType, String? managerName, String? managerContact}) async {
    try {
      final profile = await _ds.save(
        userId: userId,
        stageName: stageName,
        managerType: managerType,
        managerName: managerName,
        managerContact: managerContact,
      );
      state = state.copyWith(profile: profile, successMessage: 'Perfil de artista actualizado');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> requestVerification(String userId) async {
    try {
      await _ds.requestVerification(userId);
      await load(userId);
      state = state.copyWith(successMessage: 'Solicitud de verificación enviada');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final artistDataSourceProvider = Provider<ArtistRemoteDataSource>((ref) {
  return ArtistRemoteDataSource(Supabase.instance.client);
});

final artistViewModelProvider = StateNotifierProvider<ArtistViewModel, ArtistState>((ref) {
  return ArtistViewModel(ref.read(artistDataSourceProvider));
});
