// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../shared/dto/user_dto.dart';
import '../../domain/entities/user_entity.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    print('[Supabase] 🚀 Iniciando registro manual para: $email');
    
    try {
      // 1. Crear el usuario en Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
          'user_type': userType.name,
        },
      );

      if (response.user == null) {
        throw Exception('No se pudo crear el usuario en Supabase Auth.');
      }

      final userId = response.user!.id;
      print('[Supabase] ✅ Usuario creado en Auth (ID: $userId). Creando perfil en tabla...');

      // 2. Crear el perfil MANUALMENTE (sin depender de triggers)
      final profileData = {
        'id': userId,
        'email': email,
        'username': username,
        'full_name': fullName,
        'user_type': userType.name, // 'YOER' o 'CLIENT'
        'status': 'NO_DISPONIBLE',
        'country': 'MX',
        'rating': 0.0,
        'total_reviews': 0,
        'completed_jobs': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profileResponse = await _client
          .from(SupabaseConfig.profilesTable)
          .insert(profileData)
          .select()
          .maybeSingle();

      if (profileResponse == null) {
        print('[Supabase] ❌ Error: Se creó el usuario pero no el perfil.');
        throw Exception('Usuario creado, pero hubo un problema con tu perfil. Intenta iniciar sesión.');
      }

      print('[Supabase] 🎉 Registro completado con éxito.');
      return UserDto.fromJson(profileResponse).toEntity();
    } catch (e) {
      print('[Supabase] 🔥 ERROR EN REGISTRO: $e');
      rethrow;
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    print('[Supabase] Intentando login para: $email');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('[Supabase] Login fallido: Usuario nulo');
        throw Exception('Email o contraseña incorrectos.');
      }

      print('[Supabase] Login exitoso para ID: ${response.user!.id}');
      
      // Reintenta hasta 3 veces en caso de que el trigger de Supabase
      // tarde en crear el perfil (más común justo después del registro)
      Exception? lastError;
      for (int i = 0; i < 3; i++) {
        try {
          return await _fetchProfile(response.user!.id);
        } catch (e) {
          print('[Supabase] Reintento ${i+1} cargando perfil...');
          lastError = Exception(e.toString());
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        }
      }
      throw lastError ?? Exception('No se pudo cargar tu perfil.');
    } catch (e) {
      print('[Supabase] Error en signIn: $e');
      rethrow;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() => _client.auth.signOut();

  // ── Get Current User ──────────────────────────────────────────────────────
  Future<UserEntity?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<UserEntity> updateProfile(UserEntity user) async {
    final data = {
      'full_name': user.fullName,
      'username': user.username,
      'status': user.status.name,
      'phone_number': user.phoneNumber,
      'profile_image_url': user.profileImageUrl,
      'cover_image_url': user.coverImageUrl,
      'age': user.age,
      'gender': user.gender,
      'bio': user.bio,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'address': user.address,
      'city': user.city,
      'state': user.state,
      'country': user.country,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((k, v) => v == null);

    final updated = await _client
        .from(SupabaseConfig.profilesTable)
        .update(data)
        .eq('id', user.id)
        .select()
        .single();

    return UserDto.fromJson(updated).toEntity();
  }

  // ── Upload Profile Image ──────────────────────────────────────────────────
  Future<String?> uploadProfileImage(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final file = File(filePath);
    final ext = filePath.split('.').last;
    final path = '${user.id}/profile.$ext';

    await _client.storage
        .from(SupabaseConfig.profileImagesBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage
        .from(SupabaseConfig.profileImagesBucket)
        .getPublicUrl(path);
  }

  // ── Auth State Stream ─────────────────────────────────────────────────────
  Stream<UserEntity?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        return await _fetchProfile(user.id);
      } catch (_) {
        return null;
      }
    });
  }

  bool get isAuthenticated => _client.auth.currentUser != null;
  String? get currentUserId => _client.auth.currentUser?.id;

  // ── Privado: fetch perfil desde DB ────────────────────────────────────────
  Future<UserEntity> _fetchProfile(String userId) async {
    final data = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', userId)
        .single();

    return UserDto.fromJson(data).toEntity();
  }
}
