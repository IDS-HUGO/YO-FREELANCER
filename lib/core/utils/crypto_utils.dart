import 'dart:convert';

/// Utilidad de encriptación y desencriptación simétrica para proteger datos sensibles
/// como el número de teléfono en la base de datos, manteniendo retrocompatibilidad.
class CryptoUtils {
  CryptoUtils._();

  // Clave de encriptación interna
  static const String _key = 'YO_FREELANCER_SECURE_KEY_2026';

  /// Encripta un texto usando XOR y codificación Base64.
  /// Añade el prefijo "ENC:" para identificar el estado del dato.
  static String encrypt(String text) {
    if (text.isEmpty) return text;
    // Si ya viene encriptado, no re-encriptar
    if (text.startsWith('ENC:')) return text;

    final List<int> textBytes = utf8.encode(text);
    final List<int> keyBytes = utf8.encode(_key);
    
    final List<int> encryptedBytes = List<int>.generate(textBytes.length, (i) {
      return textBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    final String base64Str = base64.encode(encryptedBytes);
    return 'ENC:$base64Str';
  }

  /// Desencripta un texto si tiene el prefijo "ENC:".
  /// Si no lo tiene, retorna el texto original (soporte retrocompatible).
  static String decrypt(String text) {
    if (!text.startsWith('ENC:')) return text;

    try {
      final String base64Str = text.substring(4);
      final List<int> encryptedBytes = base64.decode(base64Str);
      final List<int> keyBytes = utf8.encode(_key);

      final List<int> decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
        return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      });

      return utf8.decode(decryptedBytes);
    } catch (_) {
      // Retorna el texto original ante cualquier falla para no romper la app
      return text;
    }
  }

  /// Enmascara un número de teléfono mostrando solo los últimos 4 dígitos.
  /// Desencripta automáticamente antes de aplicar la máscara.
  static String maskPhoneNumber(String phone) {
    final String cleanPhone = decrypt(phone).trim();
    if (cleanPhone.isEmpty) return '';
    if (cleanPhone.length <= 4) return '****';
    
    final String visiblePart = cleanPhone.substring(cleanPhone.length - 4);
    return '${'*' * (cleanPhone.length - 4)}$visiblePart';
  }
}
