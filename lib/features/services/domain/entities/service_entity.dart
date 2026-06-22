// lib/features/services/domain/entities/service_entity.dart

enum ServiceCategory {
  construccion, limpieza, reparacion, educacion,
  arte, musica, deportes, tecnologia, salud,
  belleza, transporte, otros;

  String get name {
    final names = {
      ServiceCategory.construccion: 'CONSTRUCCION',
      ServiceCategory.limpieza: 'LIMPIEZA',
      ServiceCategory.reparacion: 'REPARACION',
      ServiceCategory.educacion: 'EDUCACION',
      ServiceCategory.arte: 'ARTE',
      ServiceCategory.musica: 'MUSICA',
      ServiceCategory.deportes: 'DEPORTES',
      ServiceCategory.tecnologia: 'TECNOLOGIA',
      ServiceCategory.salud: 'SALUD',
      ServiceCategory.belleza: 'BELLEZA',
      ServiceCategory.transporte: 'TRANSPORTE',
      ServiceCategory.otros: 'OTROS',
    };
    return names[this]!;
  }

  String get displayName {
    final names = {
      ServiceCategory.construccion: 'Construcción',
      ServiceCategory.limpieza: 'Limpieza',
      ServiceCategory.reparacion: 'Reparación',
      ServiceCategory.educacion: 'Educación',
      ServiceCategory.arte: 'Arte',
      ServiceCategory.musica: 'Música',
      ServiceCategory.deportes: 'Deportes',
      ServiceCategory.tecnologia: 'Tecnología',
      ServiceCategory.salud: 'Salud',
      ServiceCategory.belleza: 'Belleza',
      ServiceCategory.transporte: 'Transporte',
      ServiceCategory.otros: 'Otros',
    };
    return names[this]!;
  }

  String get emoji {
    const emojis = {
      'CONSTRUCCION': '🏗️',
      'LIMPIEZA': '🧹',
      'REPARACION': '🔧',
      'EDUCACION': '📚',
      'ARTE': '🎨',
      'MUSICA': '🎵',
      'DEPORTES': '⚽',
      'TECNOLOGIA': '💻',
      'SALUD': '❤️',
      'BELLEZA': '💄',
      'TRANSPORTE': '🚚',
      'OTROS': '⭐',
    };
    return emojis[name] ?? '⭐';
  }
}

enum ServiceType {
  aDomicilio, local, remoto, hibrido;

  String get name {
    const names = {
      'aDomicilio': 'A_DOMICILIO',
      'local': 'LOCAL',
      'remoto': 'REMOTO',
      'hibrido': 'HIBRIDO',
    };
    return names[toString().split('.').last] ?? 'LOCAL';
  }

  String get displayName {
    switch (this) {
      case ServiceType.aDomicilio: return 'A Domicilio';
      case ServiceType.local: return 'Local';
      case ServiceType.remoto: return 'Remoto';
      case ServiceType.hibrido: return 'Híbrido';
    }
  }
}

enum PriceType {
  porHora, precioFijo, negociable;

  String get name {
    switch (this) {
      case PriceType.porHora: return 'POR_HORA';
      case PriceType.precioFijo: return 'PRECIO_FIJO';
      case PriceType.negociable: return 'NEGOCIABLE';
    }
  }

  String get displayName {
    switch (this) {
      case PriceType.porHora: return 'Por hora';
      case PriceType.precioFijo: return 'Precio fijo';
      case PriceType.negociable: return 'Negociable';
    }
  }
}

class ServiceEntity {
  final String id;
  final String yoerId;
  final String yoerName;
  final String? yoerImageUrl;
  final String title;
  final String description;
  final ServiceCategory category;
  final List<String> specialties;
  final ServiceType serviceType;
  final PriceType priceType;
  final double price;
  final String currency;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final List<String> images;
  final List<String> videos;
  final double rating;
  final int totalReviews;
  final int viewsCount;
  final bool isActive;
  final bool isPromoted;
  final List<String> requirements;
  final List<String> includedItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceEntity({
    required this.id,
    required this.yoerId,
    required this.yoerName,
    this.yoerImageUrl,
    required this.title,
    required this.description,
    required this.category,
    this.specialties = const [],
    required this.serviceType,
    required this.priceType,
    required this.price,
    this.currency = 'MXN',
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.images = const [],
    this.videos = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.viewsCount = 0,
    this.isActive = true,
    this.isPromoted = false,
    this.requirements = const [],
    this.includedItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get priceLabel {
    final formatted = price.toStringAsFixed(0);
    switch (priceType) {
      case PriceType.porHora: return '\$$formatted/hr';
      case PriceType.precioFijo: return '\$$formatted';
      case PriceType.negociable: return 'Desde \$$formatted';
    }
  }

  bool get hasImages => images.isNotEmpty;
  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;

  ServiceEntity copyWith({
    String? id,
    String? yoerId,
    String? yoerName,
    String? yoerImageUrl,
    String? title,
    String? description,
    ServiceCategory? category,
    List<String>? specialties,
    ServiceType? serviceType,
    PriceType? priceType,
    double? price,
    String? currency,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    List<String>? images,
    List<String>? videos,
    double? rating,
    int? totalReviews,
    int? viewsCount,
    bool? isActive,
    bool? isPromoted,
    List<String>? requirements,
    List<String>? includedItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      yoerId: yoerId ?? this.yoerId,
      yoerName: yoerName ?? this.yoerName,
      yoerImageUrl: yoerImageUrl ?? this.yoerImageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      specialties: specialties ?? this.specialties,
      serviceType: serviceType ?? this.serviceType,
      priceType: priceType ?? this.priceType,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      viewsCount: viewsCount ?? this.viewsCount,
      isActive: isActive ?? this.isActive,
      isPromoted: isPromoted ?? this.isPromoted,
      requirements: requirements ?? this.requirements,
      includedItems: includedItems ?? this.includedItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
