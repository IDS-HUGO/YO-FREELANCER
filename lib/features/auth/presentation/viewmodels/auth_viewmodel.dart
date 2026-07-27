// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../app/di/injection.dart';

// ── Estado ────────────────────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;
  final String? successMessage;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.successMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
    String? successMessage,
    bool? isAuthenticated,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  String toString() =>
      'AuthState(isLoading: $isLoading, user: ${user?.email}, error: $error, successMessage: $successMessage, isAuthenticated: $isAuthenticated)';
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: user != null,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        userType: userType,
        phoneNumber: phoneNumber,
      );
      final isAuthed = _repository.isAuthenticated;
      state = state.copyWith(
        isLoading: false,
        user: isAuthed ? user : null,
        isAuthenticated: isAuthed,
        successMessage: isAuthed
            ? '¡Registro exitoso! Bienvenido a YO FREE-LANCER.'
            : '¡Registro exitoso! Por favor, verifica tu correo electrónico para activar tu cuenta.',
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e.toString()),
      );
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        successMessage: '¡Inicio de sesión exitoso! Bienvenido de vuelta.',
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e.toString()),
      );
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    // Limpia la sesión local aunque falle la llamada remota, para nunca
    // dejar al usuario atorado en una pantalla protegida sin poder salir.
    try {
      await _repository.signOut();
    } catch (_) {
      // ignore
    }
    state = const AuthState();
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile(UserEntity user) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final updated = await _repository.updateProfile(user);
      state = state.copyWith(
        isLoading: false,
        user: updated,
        successMessage: '¡Perfil actualizado con éxito!',
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e.toString()),
      );
      return false;
    }
  }

  // ── Upload Image ──────────────────────────────────────────────────────────
  Future<String?> uploadProfileImage(String filePath) async {
    try {
      return await _repository.uploadProfileImage(filePath);
    } catch (_) {
      return null;
    }
  }

  // ── Cambiar contraseña ────────────────────────────────────────────────────
  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.changePassword(newPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Contraseña actualizada con éxito.',
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e.toString()));
      return false;
    }
  }

  // ── Recuperar contraseña olvidada ─────────────────────────────────────────
  Future<bool> resetPasswordForEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.resetPasswordForEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Te hemos enviado un correo para restablecer tu contraseña.',
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e.toString()),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  String _parseError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'Este email ya está registrado.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    }
    if (raw.contains('perfil') || raw.contains('profile') || raw.contains('PGRST116')) {
      return 'No se encontró tu perfil. Contacta soporte.';
    }
    if (raw.contains('network') || raw.contains('connection') || raw.contains('SocketException')) {
      return 'Sin conexión. Verifica tu internet.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>();
});

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

// Shortcut providers
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authViewModelProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAuthenticated;
});
