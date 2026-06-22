// lib/shared/dto/service_dto.dart
import '../../features/services/domain/entities/service_entity.dart';

class ServiceDto {
  final String id;
  final String yoerId;
  final String title;
  final String description;
  final String category;
  final List<String> specialties;
  final String serviceType;
  final String priceType;
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
  final Map<String, dynamic> availability;
  final List<String> requirements;
  final List<String> includedItems;
  final String createdAt;
  final String updatedAt;
  // Joins opcionales
  final Map<String, dynamic>? yoerProfile;

  const ServiceDto({
    required this.id,
    required this.yoerId,
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
    this.availability = const {},
    this.requirements = const [],
    this.includedItems = const [],
    required this.createdAt,
    required this.updatedAt,
    this.yoerProfile,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id'] as String,
      yoerId: json['yoer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      specialties: List<String>.from(json['specialties'] as List? ?? []),
      serviceType: json['service_type'] as String? ?? 'LOCAL',
      priceType: json['price_type'] as String? ?? 'PRECIO_FIJO',
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      images: List<String>.from(json['images'] as List? ?? []),
      videos: List<String>.from(json['videos'] as List? ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isPromoted: json['is_promoted'] as bool? ?? false,
      availability: json['availability'] as Map<String, dynamic>? ?? {},
      requirements: List<String>.from(json['requirements'] as List? ?? []),
      includedItems: List<String>.from(json['included_items'] as List? ?? []),
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      yoerProfile: json['profiles'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'yoer_id': yoerId,
    'title': title,
    'description': description,
    'category': category,
    'specialties': specialties,
    'service_type': serviceType,
    'price_type': priceType,
    'price': price,
    'currency': currency,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    'images': images,
    'videos': videos,
    'is_active': isActive,
    'is_promoted': isPromoted,
    'availability': availability,
    'requirements': requirements,
    'included_items': includedItems,
  };

  ServiceEntity toEntity() {
    return ServiceEntity(
      id: id,
      yoerId: yoerId,
      yoerName: yoerProfile?['full_name'] as String? ?? 'YOER',
      yoerImageUrl: yoerProfile?['profile_image_url'] as String?,
      title: title,
      description: description,
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => ServiceCategory.otros,
      ),
      specialties: specialties,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == serviceType,
        orElse: () => ServiceType.local,
      ),
      priceType: PriceType.values.firstWhere(
        (e) => e.name == priceType,
        orElse: () => PriceType.precioFijo,
      ),
      price: price,
      currency: currency,
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      images: images,
      videos: videos,
      rating: rating,
      totalReviews: totalReviews,
      viewsCount: viewsCount,
      isActive: isActive,
      isPromoted: isPromoted,
      requirements: requirements,
      includedItems: includedItems,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}

// ─── Booking DTO ─────────────────────────────────────────────────────────────
// lib/shared/dto/booking_dto.dart (se incluye en mismo archivo por brevedad)

class BookingDto {
  final String id;
  final String serviceId;
  final String yoerId;
  final String clientId;
  final String serviceName;
  final String status;
  final int scheduledDate;
  final String scheduledTime;
  final int duration;
  final double? latitude;
  final double? longitude;
  final String address;
  final String? notes;
  final double totalPrice;
  final String currency;
  final String paymentStatus;
  final String? paymentMethod;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancellationReason;

  const BookingDto({
    required this.id,
    required this.serviceId,
    required this.yoerId,
    required this.clientId,
    required this.serviceName,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.duration,
    this.latitude,
    this.longitude,
    required this.address,
    this.notes,
    required this.totalPrice,
    this.currency = 'MXN',
    required this.paymentStatus,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    return BookingDto(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      yoerId: json['yoer_id'] as String,
      clientId: json['client_id'] as String,
      serviceName: json['service_name'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDIENTE',
      scheduledDate: json['scheduled_date'] as int,
      scheduledTime: json['scheduled_time'] as String,
      duration: json['duration'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      paymentStatus: json['payment_status'] as String? ?? 'PENDIENTE',
      paymentMethod: json['payment_method'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      completedAt: json['completed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'yoer_id': yoerId,
    'client_id': clientId,
    'service_name': serviceName,
    'status': status,
    'scheduled_date': scheduledDate,
    'scheduled_time': scheduledTime,
    'duration': duration,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'address': address,
    if (notes != null) 'notes': notes,
    'total_price': totalPrice,
    'currency': currency,
    'payment_status': paymentStatus,
    if (paymentMethod != null) 'payment_method': paymentMethod,
  };
}

// ─── Payment DTO ──────────────────────────────────────────────────────────────
class PaymentDto {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String transactionType;
  final String status;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String? processedAt;
  final String? refundedAt;

  const PaymentDto({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'MXN',
    required this.paymentMethod,
    this.transactionType = 'PAGO',
    required this.status,
    this.transactionId,
    this.description,
    this.metadata = const {},
    required this.createdAt,
    this.processedAt,
    this.refundedAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      paymentMethod: json['payment_method'] as String,
      transactionType: json['transaction_type'] as String? ?? 'PAGO',
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String,
      processedAt: json['processed_at'] as String?,
      refundedAt: json['refunded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'user_id': userId,
    'amount': amount,
    'currency': currency,
    'payment_method': paymentMethod,
    'transaction_type': transactionType,
    'status': status,
    if (transactionId != null) 'transaction_id': transactionId,
    if (description != null) 'description': description,
    'metadata': metadata,
  };
}
