/// Configuración del microservicio de verificación facial. Es un proyecto
/// standalone y separado (`yofreelancer-kyc-service`), llamado directo desde
/// la app móvil por su propia URL — nunca a través del backend propio como
/// proxy (ver docs/KYC.md).
///
/// No tiene ningún mecanismo de conmutación ni respaldo propio: si no
/// responde, la verificación simplemente no se completa (fail-closed) — es
/// el comportamiento correcto, no un caso a resolver con otro backend.
class KycConfig {
  /// Modo Sandbox / Pruebas para verificación biométrica.
  /// Si es true y el servidor remoto no responde o tiene error de red/SSL,
  /// permite la simulación de verificación para pruebas locales y demostraciones.
  /// En producción estricta, compilar con: --dart-define=KYC_SANDBOX=false
  static const bool isSandbox = bool.fromEnvironment(
    'KYC_SANDBOX',
    defaultValue: true,
  );

  /// URL base del microservicio. En desarrollo local con
  /// `uvicorn app.main:app` dentro del proyecto standalone, el valor por
  /// defecto funciona sin configuración adicional. En producción,
  /// sobreescribe con:
  ///   flutter run --dart-define=KYC_SERVICE_URL=https://tu-kyc.example.com
  static const String baseUrl = String.fromEnvironment(
    'KYC_SERVICE_URL',
    defaultValue: 'https://kyc.ferluna.online',
  );

  static const String verifyPath = '/verify';
  static const String healthPath = '/health';

  /// Tiempo máximo de espera antes de tratar la verificación como fallida
  /// (fail-closed): ver `KycRepository.verifyIdentity`.
  static const Duration requestTimeout = Duration(seconds: 60);
}
