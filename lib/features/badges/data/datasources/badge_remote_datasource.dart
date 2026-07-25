// lib/features/badges/data/datasources/badge_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

class BadgeCatalogEntity {
  final String code;
  final String name;
  final String? description;
  final String? icon;

  const BadgeCatalogEntity({
    required this.code,
    required this.name,
    this.description,
    this.icon,
  });

  factory BadgeCatalogEntity.fromJson(Map<String, dynamic> json) {
    return BadgeCatalogEntity(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class EarnedBadgeEntity {
  final String id;
  final String userId;
  final String? badgeCode;
  final String name;
  final String? description;
  final String? iconUrl;
  final DateTime earnedAt;

  const EarnedBadgeEntity({
    required this.id,
    required this.userId,
    this.badgeCode,
    required this.name,
    this.description,
    this.iconUrl,
    required this.earnedAt,
  });

  factory EarnedBadgeEntity.fromJson(Map<String, dynamic> json) {
    return EarnedBadgeEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeCode: json['badge_code'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}

class BadgeRemoteDataSource {
  final SupabaseClient _client;
  BadgeRemoteDataSource(this._client);

  Future<List<BadgeCatalogEntity>> getCatalog() async {
    final data = await _client
        .from(SupabaseConfig.badgeCatalogTable)
        .select()
        .eq('is_active', true);

    return (data as List)
        .map((e) => BadgeCatalogEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EarnedBadgeEntity>> getEarnedForUser(String userId) async {
    final data = await _client
        .from(SupabaseConfig.badgesTable)
        .select()
        .eq('user_id', userId)
        .order('earned_at', ascending: false);

    return (data as List)
        .map((e) => EarnedBadgeEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class BadgeState {
  final bool isLoading;
  final List<BadgeCatalogEntity> catalog;
  final List<EarnedBadgeEntity> earned;
  final String? error;

  const BadgeState({
    this.isLoading = false,
    this.catalog = const [],
    this.earned = const [],
    this.error,
  });

  bool isEarned(String code) => earned.any((b) => b.badgeCode == code);

  BadgeState copyWith({
    bool? isLoading,
    List<BadgeCatalogEntity>? catalog,
    List<EarnedBadgeEntity>? earned,
    String? error,
    bool clearError = false,
  }) {
    return BadgeState(
      isLoading: isLoading ?? this.isLoading,
      catalog: catalog ?? this.catalog,
      earned: earned ?? this.earned,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BadgeViewModel extends StateNotifier<BadgeState> {
  final BadgeRemoteDataSource _ds;
  BadgeViewModel(this._ds) : super(const BadgeState());

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final catalog = await _ds.getCatalog();
      final earned = await _ds.getEarnedForUser(userId);
      state = state.copyWith(isLoading: false, catalog: catalog, earned: earned);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final badgeDataSourceProvider = Provider<BadgeRemoteDataSource>((ref) {
  return BadgeRemoteDataSource(Supabase.instance.client);
});

final badgeViewModelProvider = StateNotifierProvider<BadgeViewModel, BadgeState>((ref) {
  return BadgeViewModel(ref.read(badgeDataSourceProvider));
});
