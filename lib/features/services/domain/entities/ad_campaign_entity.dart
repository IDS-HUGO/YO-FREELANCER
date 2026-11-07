// lib/features/services/domain/entities/ad_campaign_entity.dart

enum AdPlanTier {
  spotlight,
  proWeekly,
  vipBiweekly;

  String get id {
    switch (this) {
      case AdPlanTier.spotlight:
        return 'CAMPANA_3D';
      case AdPlanTier.proWeekly:
        return 'CAMPANA_7D';
      case AdPlanTier.vipBiweekly:
        return 'CAMPANA_15D';
    }
  }

  String get title {
    switch (this) {
      case AdPlanTier.spotlight:
        return 'Campaña de 3 Días';
      case AdPlanTier.proWeekly:
        return 'Campaña de 7 Días';
      case AdPlanTier.vipBiweekly:
        return 'Campaña de 15 Días';
    }
  }

  String get durationLabel {
    switch (this) {
      case AdPlanTier.spotlight:
        return '3 días de alcance';
      case AdPlanTier.proWeekly:
        return '7 días (1 semana)';
      case AdPlanTier.vipBiweekly:
        return '15 días (2 semanas)';
    }
  }

  int get durationDays {
    switch (this) {
      case AdPlanTier.spotlight:
        return 3;
      case AdPlanTier.proWeekly:
        return 7;
      case AdPlanTier.vipBiweekly:
        return 15;
    }
  }

  double get priceMxn {
    switch (this) {
      case AdPlanTier.spotlight:
        return 99.0;
      case AdPlanTier.proWeekly:
        return 199.0;
      case AdPlanTier.vipBiweekly:
        return 399.0;
    }
  }

  String get estimatedImpressions {
    switch (this) {
      case AdPlanTier.spotlight:
        return '500 – 1,200 personas en tu zona';
      case AdPlanTier.proWeekly:
        return '2,500 – 5,000 personas en tu zona';
      case AdPlanTier.vipBiweekly:
        return '8,000 – 15,000 personas en tu zona';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AdPlanTier.spotlight:
        return 'Destacado';
      case AdPlanTier.proWeekly:
        return 'Recomendado';
      case AdPlanTier.vipBiweekly:
        return 'Patrocinado';
    }
  }

  List<String> get highlights {
    switch (this) {
      case AdPlanTier.spotlight:
        return [
          'Aparición prioritaria en búsquedas de tu categoría',
          'Etiqueta de servicio verificado y destacado',
          'Hasta 1,200 visualizaciones estimadas en tu ciudad',
        ];
      case AdPlanTier.proWeekly:
        return [
          'Inclusión en la sección de servicios recomendados',
          'Prioridad en el buscador local',
          'Mayor recepción de solicitudes y mensajes directos',
        ];
      case AdPlanTier.vipBiweekly:
        return [
          'Posición prioritaria constante en tu categoría',
          'Máxima exposición comercial para captar nuevos clientes',
          'Resumen de rendimiento de campaña disponible',
        ];
    }
  }

  String get icon {
    switch (this) {
      case AdPlanTier.spotlight:
        return '📌';
      case AdPlanTier.proWeekly:
        return '⭐';
      case AdPlanTier.vipBiweekly:
        return '🚀';
    }
  }
}

/// Campaña publicitaria activa de un servicio
class AdCampaignEntity {
  final String id;
  final String serviceId;
  final String yoerId;
  final AdPlanTier tier;
  final double amountPaid;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;
  final int impressions;
  final int clicks;
  final int inquiries;

  const AdCampaignEntity({
    required this.id,
    required this.serviceId,
    required this.yoerId,
    required this.tier,
    required this.amountPaid,
    required this.startedAt,
    required this.expiresAt,
    this.isActive = true,
    this.impressions = 0,
    this.clicks = 0,
    this.inquiries = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get remainingDays {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory AdCampaignEntity.fromJson(Map<String, dynamic> json) {
    final tierStr = json['plan_tier'] as String? ?? 'CAMPANA_3D';
    final tier = AdPlanTier.values.firstWhere(
      (t) => t.id == tierStr,
      orElse: () => AdPlanTier.spotlight,
    );

    return AdCampaignEntity(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      yoerId: json['yoer_id'] as String,
      tier: tier,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
      clicks: (json['clicks'] as num?)?.toInt() ?? 0,
      inquiries: (json['inquiries'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_id': serviceId,
    'yoer_id': yoerId,
    'plan_tier': tier.id,
    'amount_paid': amountPaid,
    'started_at': startedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'is_active': isActive,
    'impressions': impressions,
    'clicks': clicks,
    'inquiries': inquiries,
  };
}
