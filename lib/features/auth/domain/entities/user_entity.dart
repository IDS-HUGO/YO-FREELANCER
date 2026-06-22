// lib/features/auth/domain/entities/user_entity.dart

enum UserType { yoer, client }
enum UserStatus { disponible, ocupado, noDisponible, warned }

extension UserTypeExt on UserType {
  String get name => this == UserType.yoer ? 'YOER' : 'CLIENT';
  bool get isYoer => this == UserType.yoer;
  bool get isClient => this == UserType.client;
}

extension UserStatusExt on UserStatus {
  String get name {
    switch (this) {
      case UserStatus.disponible: return 'DISPONIBLE';
      case UserStatus.ocupado: return 'OCUPADO';
      case UserStatus.noDisponible: return 'NO_DISPONIBLE';
      case UserStatus.warned: return 'WARNED';
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.disponible: return 'Disponible';
      case UserStatus.ocupado: return 'Ocupado';
      case UserStatus.noDisponible: return 'No disponible';
      case UserStatus.warned: return 'Amonestado';
    }
  }
}

class UserEntity {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final UserType userType;
  final UserStatus status;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final int? age;
  final String? gender;
  final String? bio;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final double weeklyBonus;
  final int? rankingPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.userType,
    required this.status,
    this.phoneNumber,
    this.profileImageUrl,
    this.coverImageUrl,
    this.age,
    this.gender,
    this.bio,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.state,
    this.country = 'MX',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedJobs = 0,
    this.weeklyBonus = 0.0,
    this.rankingPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get isYoer => userType == UserType.yoer;
  bool get isClient => userType == UserType.client;

  UserEntity copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    UserType? userType,
    UserStatus? status,
    String? phoneNumber,
    String? profileImageUrl,
    String? coverImageUrl,
    int? age,
    String? gender,
    String? bio,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    double? rating,
    int? totalReviews,
    int? completedJobs,
    double? weeklyBonus,
    int? rankingPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      weeklyBonus: weeklyBonus ?? this.weeklyBonus,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
