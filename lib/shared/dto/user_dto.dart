// lib/shared/dto/user_dto.dart
import '../../features/auth/domain/entities/user_entity.dart';

class UserDto {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String userType;
  final String status;
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
  final String createdAt;
  final String updatedAt;

  const UserDto({
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      userType: json['user_type'] as String? ?? 'CLIENT',
      status: json['status'] as String? ?? 'NO_DISPONIBLE',
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'MX',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      weeklyBonus: (json['weekly_bonus'] as num?)?.toDouble() ?? 0.0,
      rankingPosition: json['ranking_position'] as int?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'user_type': userType,
    'status': status,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
    if (age != null) 'age': age,
    if (gender != null) 'gender': gender,
    if (bio != null) 'bio': bio,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    'country': country,
    'rating': rating,
    'total_reviews': totalReviews,
    'completed_jobs': completedJobs,
    'weekly_bonus': weeklyBonus,
    if (rankingPosition != null) 'ranking_position': rankingPosition,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      userType: UserType.values.firstWhere(
        (e) => e.name == userType,
        orElse: () => UserType.client,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => UserStatus.noDisponible,
      ),
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      coverImageUrl: coverImageUrl,
      age: age,
      gender: gender,
      bio: bio,
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      state: state,
      country: country,
      rating: rating,
      totalReviews: totalReviews,
      completedJobs: completedJobs,
      weeklyBonus: weeklyBonus,
      rankingPosition: rankingPosition,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
