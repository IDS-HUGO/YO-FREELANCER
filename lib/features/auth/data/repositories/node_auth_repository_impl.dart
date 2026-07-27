// lib/features/auth/data/repositories/node_auth_repository_impl.dart
import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_node_datasource.dart';

/// Implementación de [AuthRepository] contra el backend propio (Node).
///
/// Se registra como el `AuthRepository` principal en `injection.dart` cuando
/// `BackendModeConfig.current == BackendMode.ownBackend` (ver
/// docs/BACKEND_CONFIG.md) — no es un mecanismo de respaldo, es una de las
/// dos fuentes de datos que la app puede usar según cómo se compiló.
class NodeAuthRepositoryImpl implements AuthRepository {
  final AuthNodeDataSource _dataSource;

  String? _cachedUserId;
  bool _cachedIsAuthenticated = false;

  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  NodeAuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    final user = await _dataSource.signUp(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
      userType: userType,
      phoneNumber: phoneNumber,
    );
    _cachedUserId = user.id;
    _cachedIsAuthenticated = true;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.signIn(email: email, password: password);
    _cachedUserId = user.id;
    _cachedIsAuthenticated = true;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
    _cachedUserId = null;
    _cachedIsAuthenticated = false;
    _authStateController.add(null);
  }

  @override
  Future<UserEntity?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<UserEntity> updateProfile(UserEntity user) =>
      _dataSource.updateProfile(user);

  @override
  Future<String?> uploadProfileImage(String filePath) =>
      _dataSource.uploadProfileImage(filePath);

  @override
  Future<void> changePassword(String newPassword) =>
      _dataSource.changePassword(newPassword);

  @override
  Future<void> resetPasswordForEmail(String email) =>
      _dataSource.resetPasswordForEmail(email);

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => _cachedIsAuthenticated;

  @override
  String? get currentUserId => _cachedUserId;
}
