// lib/features/auth/domain/repositories/auth_repository.dart
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  });

  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserEntity?> getCurrentUser();

  Future<UserEntity> updateProfile(UserEntity user);

  Future<String?> uploadProfileImage(String filePath);

  Stream<UserEntity?> get authStateChanges;

  bool get isAuthenticated;
  String? get currentUserId;
}

// ─── Implementación con Supabase ──────────────────────────────────────────────
// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../shared/dto/user_dto.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
      userType: userType,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  Future<UserEntity?> getCurrentUser() => _remoteDataSource.getCurrentUser();

  @override
  Future<UserEntity> updateProfile(UserEntity user) =>
      _remoteDataSource.updateProfile(user);

  @override
  Future<String?> uploadProfileImage(String filePath) =>
      _remoteDataSource.uploadProfileImage(filePath);

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges;

  @override
  bool get isAuthenticated => _remoteDataSource.isAuthenticated;

  @override
  String? get currentUserId => _remoteDataSource.currentUserId;
}
