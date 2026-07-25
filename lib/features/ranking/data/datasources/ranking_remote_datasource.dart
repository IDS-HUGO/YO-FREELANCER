// lib/features/ranking/data/datasources/ranking_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;

enum RankingMetric {
  rating, completedJobs, price;

  String get param {
    switch (this) {
      case RankingMetric.rating:        return 'rating';
      case RankingMetric.completedJobs: return 'completed_jobs';
      case RankingMetric.price:         return 'price';
    }
  }

  String get displayName {
    switch (this) {
      case RankingMetric.rating:        return 'Calidad';
      case RankingMetric.completedJobs: return 'Tareas';
      case RankingMetric.price:         return 'Precio';
    }
  }
}

class RankingEntryEntity {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final double rating;
  final int completedJobs;
  final String? city;
  final double avgPrice;

  const RankingEntryEntity({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    required this.rating,
    required this.completedJobs,
    this.city,
    required this.avgPrice,
  });

  factory RankingEntryEntity.fromJson(Map<String, dynamic> json) {
    return RankingEntryEntity(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'YOER',
      profileImageUrl: json['profile_image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      city: json['city'] as String?,
      avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RankingRemoteDataSource {
  final SupabaseClient _client;
  RankingRemoteDataSource(this._client);

  Future<List<RankingEntryEntity>> getRanking({ServiceCategory? category, RankingMetric metric = RankingMetric.rating}) async {
    final data = await _client.rpc('get_yoer_ranking', params: {
      'filter_category': category?.name,
      'metric': metric.param,
      'lim': 30,
    }) as List;

    return data.map((e) => RankingEntryEntity.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class RankingState {
  final bool isLoading;
  final List<RankingEntryEntity> entries;
  final ServiceCategory? category;
  final RankingMetric metric;
  final String? error;

  const RankingState({
    this.isLoading = false,
    this.entries = const [],
    this.category,
    this.metric = RankingMetric.rating,
    this.error,
  });

  RankingState copyWith({
    bool? isLoading,
    List<RankingEntryEntity>? entries,
    ServiceCategory? category,
    bool clearCategory = false,
    RankingMetric? metric,
    String? error,
    bool clearError = false,
  }) {
    return RankingState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      category: clearCategory ? null : (category ?? this.category),
      metric: metric ?? this.metric,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RankingViewModel extends StateNotifier<RankingState> {
  final RankingRemoteDataSource _ds;
  RankingViewModel(this._ds) : super(const RankingState());

  Future<void> load({ServiceCategory? category, RankingMetric? metric}) async {
    final cat = category ?? state.category;
    final met = metric ?? state.metric;
    state = state.copyWith(isLoading: true, clearError: true, metric: met);
    try {
      final entries = await _ds.getRanking(category: cat, metric: met);
      state = state.copyWith(
        isLoading: false,
        entries: entries,
        category: cat,
        clearCategory: cat == null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final rankingDataSourceProvider = Provider<RankingRemoteDataSource>((ref) {
  return RankingRemoteDataSource(Supabase.instance.client);
});

final rankingViewModelProvider = StateNotifierProvider<RankingViewModel, RankingState>((ref) {
  return RankingViewModel(ref.read(rankingDataSourceProvider));
});
