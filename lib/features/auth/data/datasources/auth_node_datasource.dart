// lib/features/auth/data/datasources/auth_node_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../app/config/backend_config.dart';
import '../../../../shared/dto/user_dto.dart';
import '../../domain/entities/user_entity.dart';

/// Cliente HTTP hacia el backend propio (Node/Express), usado cuando la app
/// se compila en modo `BackendMode.ownBackend` (ver
/// `lib/app/config/backend_mode.dart` y docs/BACKEND_CONFIG.md).
///
/// El backend propio es un proyecto standalone y separado (desplegado por su
/// cuenta) que maneja su propia autenticación de punta a punta — no depende
/// de Supabase para nada. Este datasource guarda el token de sesión
/// localmente vía `flutter_secure_storage`.
class AuthNodeDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'node_auth_token';
  static const _userIdKey = 'node_auth_user_id';

  AuthNodeDataSource({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: BackendConfig.nodeBaseUrl,
              connectTimeout: BackendConfig.requestTimeout,
              receiveTimeout: BackendConfig.requestTimeout,
            )),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> get _cachedToken => _storage.read(key: _tokenKey);
  Future<String?> get _cachedUserId => _storage.read(key: _userIdKey);

  /// Token de sesión vigente contra el backend propio. Usado por otros
  /// datasources del mismo modo (p. ej. `ServiceNodeDataSource`) que
  /// comparten la sesión.
  Future<String?> get currentToken => _cachedToken;

  Future<void> _persistSession(String token, String userId) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    final response = await _dio.post(BackendConfig.authRegisterPath, data: {
      'email': email,
      'password': password,
      'username': username,
      'full_name': fullName,
      'user_type': userType.name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    });

    final data = response.data as Map<String, dynamic>;
    final user = UserDto.fromJson(data['user'] as Map<String, dynamic>).toEntity();
    await _persistSession(data['token'] as String, user.id);
    return user;
  }

  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(BackendConfig.authLoginPath, data: {
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final user = UserDto.fromJson(data['user'] as Map<String, dynamic>).toEntity();
    await _persistSession(data['token'] as String, user.id);
    return user;
  }

  Future<void> signOut() => clearSession();

  Future<UserEntity?> getCurrentUser() async {
    final token = await _cachedToken;
    final userId = await _cachedUserId;
    if (token == null || userId == null) return null;

    final response = await _dio.get(
      BackendConfig.profilePath(userId),
      options: Options(headers: _authHeaders(token)),
    );
    return UserDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<UserEntity> updateProfile(UserEntity user) async {
    final token = await _cachedToken;
    if (token == null) {
      throw StateError('No hay sesión activa. Inicia sesión de nuevo.');
    }

    final response = await _dio.patch(
      BackendConfig.profilePath(user.id),
      options: Options(headers: _authHeaders(token)),
      data: {
        'full_name': user.fullName,
        'username': user.username,
        'status': user.status.name,
        if (user.phoneNumber != null) 'phone_number': user.phoneNumber,
        if (user.profileImageUrl != null) 'profile_image_url': user.profileImageUrl,
        if (user.coverImageUrl != null) 'cover_image_url': user.coverImageUrl,
        if (user.age != null) 'age': user.age,
        if (user.gender != null) 'gender': user.gender,
        if (user.bio != null) 'bio': user.bio,
        if (user.latitude != null) 'latitude': user.latitude,
        if (user.longitude != null) 'longitude': user.longitude,
        if (user.address != null) 'address': user.address,
        if (user.city != null) 'city': user.city,
        if (user.state != null) 'state': user.state,
      },
    );
    return UserDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<String?> uploadProfileImage(String filePath) async {
    final token = await _cachedToken;
    final userId = await _cachedUserId;
    if (token == null || userId == null) return null;

    final file = File(filePath);
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      BackendConfig.profileImagePath(userId),
      data: formData,
      options: Options(headers: _authHeaders(token)),
    );
    return (response.data as Map<String, dynamic>)['url'] as String?;
  }

  Future<void> changePassword(String newPassword) async {
    final token = await _cachedToken;
    if (token == null) {
      throw StateError('No hay sesión activa. Inicia sesión de nuevo.');
    }
    await _dio.patch(
      BackendConfig.authChangePasswordPath,
      options: Options(headers: _authHeaders(token)),
      data: {'new_password': newPassword},
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _dio.post(BackendConfig.authResetPasswordPath, data: {'email': email});
  }

  Future<bool> get isAuthenticated async => (await _cachedToken) != null;
  Future<String?> get currentUserId async => _cachedUserId;
}
