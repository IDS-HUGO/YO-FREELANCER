// lib/shared/utils/file_upload_validator.dart
import 'dart:io';
import 'dart:typed_data';

/// Excepción de validación de archivos subidos, con mensaje ya listo para
/// mostrar al usuario (español, sin detalles técnicos).
class FileValidationException implements Exception {
  final String message;
  const FileValidationException(this.message);

  @override
  String toString() => message;
}

/// Formatos de imagen permitidos para fotos de perfil/servicio/KYC.
enum _ImageSignature { jpeg, png, webp }

/// Valida archivos de imagen antes de subirlos a Supabase Storage.
///
/// Hardening (SECURITY_REPORT.md): antes de esto, `uploadProfileImage` y
/// `uploadServiceImage` subían cualquier archivo sin validar tipo ni tamaño.
/// Esta validación revisa los primeros bytes del archivo (firma/"magic
/// bytes"), no solo la extensión, porque la extensión la controla quien sube
/// el archivo y no es confiable por sí sola.
class FileUploadValidator {
  const FileUploadValidator._();

  static const int defaultMaxSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Lanza [FileValidationException] si [file] no es una imagen jpg/png/webp
  /// válida o excede [maxSizeBytes]. No lanza nada si la validación pasa.
  static Future<void> validateImageFile(
    File file, {
    int maxSizeBytes = defaultMaxSizeBytes,
  }) async {
    if (!await file.exists()) {
      throw const FileValidationException('El archivo seleccionado no existe.');
    }

    final size = await file.length();
    if (size <= 0) {
      throw const FileValidationException('El archivo está vacío.');
    }
    if (size > maxSizeBytes) {
      final maxMb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      throw FileValidationException(
        'La imagen es demasiado grande (máximo ${maxMb}MB). Elige una imagen más ligera.',
      );
    }

    final header = await _readHeader(file);
    if (_detectSignature(header) == null) {
      throw const FileValidationException(
        'Formato de imagen no soportado. Usa JPG, PNG o WEBP.',
      );
    }
  }

  static Future<Uint8List> _readHeader(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(12);
    } finally {
      await raf.close();
    }
  }

  static _ImageSignature? _detectSignature(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return _ImageSignature.jpeg;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return _ImageSignature.png;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return _ImageSignature.webp;
    }
    return null;
  }
}
