// lib/features/community/data/datasources/community_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;

class CommunityEventEntity {
  final String id;
  final String title;
  final String? description;
  final ServiceCategory? category;
  final String? address;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime? endsAt;

  const CommunityEventEntity({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.address,
    this.imageUrl,
    required this.startsAt,
    this.endsAt,
  });

  factory CommunityEventEntity.fromJson(Map<String, dynamic> json) {
    return CommunityEventEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] != null
          ? ServiceCategory.values.firstWhere((c) => c.name == json['category'], orElse: () => ServiceCategory.otros)
          : null,
      address: json['address'] as String?,
      imageUrl: json['image_url'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
    );
  }
}

/// Insignia otorgada a un YOER, mostrada en el feed público de Explorar.
/// (Los movimientos de wallet son privados por RLS, así que el feed de
/// "logros" solo muestra insignias, no montos de bonos/pagos.)
class BadgeFeedEntryEntity {
  final String id;
  final String userId;
  final String yoerName;
  final String? yoerImageUrl;
  final String badgeName;
  final String? badgeIcon;
  final DateTime earnedAt;

  const BadgeFeedEntryEntity({
    required this.id,
    required this.userId,
    required this.yoerName,
    this.yoerImageUrl,
    required this.badgeName,
    this.badgeIcon,
    required this.earnedAt,
  });

  factory BadgeFeedEntryEntity.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return BadgeFeedEntryEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      yoerName: profile?['full_name'] as String? ?? 'YOER',
      yoerImageUrl: profile?['profile_image_url'] as String?,
      badgeName: json['name'] as String,
      badgeIcon: json['icon_url'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}

class CommunityRemoteDataSource {
  final SupabaseClient _client;
  CommunityRemoteDataSource(this._client);

  Future<List<CommunityEventEntity>> getUpcomingEvents({int limit = 10}) async {
    final nowIso = DateTime.now().toIso8601String();
    final data = await _client
        .from(SupabaseConfig.communityEventsTable)
        .select()
        .eq('is_active', true)
        .or('ends_at.is.null,ends_at.gte.$nowIso')
        .order('starts_at', ascending: true)
        .limit(limit);

    return (data as List)
        .map((e) => CommunityEventEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BadgeFeedEntryEntity>> getRecentBadgeFeed({int limit = 10}) async {
    final data = await _client
        .from(SupabaseConfig.badgesTable)
        .select('*, profiles(full_name, profile_image_url)')
        .order('earned_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => BadgeFeedEntryEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final communityDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  return CommunityRemoteDataSource(Supabase.instance.client);
});

final upcomingEventsProvider = FutureProvider<List<CommunityEventEntity>>((ref) {
  return ref.read(communityDataSourceProvider).getUpcomingEvents();
});

final badgeFeedProvider = FutureProvider<List<BadgeFeedEntryEntity>>((ref) {
  return ref.read(communityDataSourceProvider).getRecentBadgeFeed();
});
