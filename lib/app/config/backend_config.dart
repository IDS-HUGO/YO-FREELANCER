// lib/app/config/backend_config.dart

/// Configuración del backend propio (Node/Express), usado cuando
/// `BackendModeConfig.current == BackendMode.ownBackend` (ver
/// `lib/app/config/backend_mode.dart` y docs/BACKEND_CONFIG.md).
///
/// Este backend es un proyecto standalone, separado de este repo
/// (`yofreelancer-backend`), desplegado y operado por su cuenta. La app solo
/// lo consume por HTTP — no hay ninguna otra relación de código con él.
class BackendConfig {
  /// URL base del backend propio. En desarrollo local (`npm run dev` /
  /// `docker-compose up` dentro del proyecto standalone), el valor por
  /// defecto funciona sin configuración adicional. En producción,
  /// sobreescribe con:
  ///   flutter run --dart-define=BACKEND_MODE=own_backend \
  ///               --dart-define=NODE_BACKEND_URL=https://tu-backend.example.com
  static const String nodeBaseUrl = String.fromEnvironment(
    'NODE_BACKEND_URL',
    defaultValue: 'http://localhost:4000',
  );

  static const Duration requestTimeout = Duration(seconds: 10);

  /// Endpoints del backend propio (ver su README para el contrato completo).
  static const String authRegisterPath = '/auth/register';
  static const String authLoginPath = '/auth/login';
  static const String authChangePasswordPath = '/auth/password';
  static const String authResetPasswordPath = '/auth/reset-password';
  static String profilePath(String userId) => '/profile/$userId';
  static String profileImagePath(String userId) => '/profile/$userId/image';
  static const String servicesPath = '/services';
  static String servicePath(String id) => '/services/$id';
  static String serviceToggleStatusPath(String id) => '/services/$id/toggle-status';
  static const String healthPath = '/health';
}
