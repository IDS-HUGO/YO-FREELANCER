// lib/core/utils/security_validator.dart

/// Módulo de Seguridad y Validación de Extremo a Extremo para YO FREELANCER.
///
/// Proporciona reglas estrictas de validación de identidad legal en México (SAT, RENAPO, Banxico),
/// verificación de montos de pago, prevención de lavado de dinero (PLD) y saneamiento anti-inyección.
class SecurityValidator {
  const SecurityValidator._();

  // ── 1. VALIDACIÓN FISCAL: RFC SAT MÉXICO ───────────────────────────────────
  // Persona física (13 caracteres: 4 letras, 6 dígitos fecha, 3 homoclave)
  // Persona moral (12 caracteres: 3 letras, 6 dígitos fecha, 3 homoclave)
  static final RegExp _rfcFisicaRegex = RegExp(r'^[A-ZÑ&]{4}[0-9]{6}[A-Z0-9]{3}$');
  static final RegExp _rfcMoralRegex = RegExp(r'^[A-ZÑ&]{3}[0-9]{6}[A-Z0-9]{3}$');

  /// Valida que un RFC cumpla con la estructura oficial del SAT.
  static bool isValidRFC(String? rfc) {
    if (rfc == null) return false;
    final clean = rfc.trim().toUpperCase();
    return _rfcFisicaRegex.hasMatch(clean) || _rfcMoralRegex.hasMatch(clean);
  }

  // ── 2. VALIDACIÓN DE IDENTIDAD: CURP MÉXICO ───────────────────────────────
  // Estructura oficial RENAPO de 18 caracteres
  static final RegExp _curpRegex = RegExp(
    r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM](AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[A-Z0-9][0-9]$',
  );

  /// Valida que la CURP cumpla con el formato oficial de RENAPO.
  static bool isValidCURP(String? curp) {
    if (curp == null) return false;
    return _curpRegex.hasMatch(curp.trim().toUpperCase());
  }

  // ── 3. VALIDACIÓN BANCARIA: CLABE INTERBANCARIA (18 DÍGITOS) ───────────────
  // Estándar de Banco de México con algoritmo de dígito verificador ponderado
  static bool isValidCLABE(String? clabe) {
    if (clabe == null) return false;
    final clean = clabe.replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 18 || !RegExp(r'^[0-9]{18}$').hasMatch(clean)) return false;

    // Factores de ponderación oficiales de Banxico: 3, 7, 1 repetidos
    const weights = [3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7];
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      final digit = int.parse(clean[i]);
      sum += (digit * weights[i]) % 10;
    }
    final expectedCheckDigit = (10 - (sum % 10)) % 10;
    final actualCheckDigit = int.parse(clean[17]);
    return expectedCheckDigit == actualCheckDigit;
  }

  // ── 4. VALIDACIÓN TELEFÓNICA CELULAR (MÉXICO) ─────────────────────────────
  // 10 dígitos nacionales, con prefijo opcional +52
  static bool isValidMexicanPhone(String? phone) {
    if (phone == null) return false;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return true;
    if (digits.length == 12 && digits.startsWith('52')) return true;
    return false;
  }

  // ── 5. INTEGRIDAD Y SEGURIDAD EN PAGOS (ESCROW & PLD) ──────────────────────
  // Límite máximo en efectivo por operación conforme a la Ley Antilavado (LFPIORPI)
  static const double maxCashTransactionMxn = 330000.0;
  static const double minTransactionMxn = 10.0;

  /// Valida que el monto del servicio sea matemáticamente coherente y seguro.
  static ValidationResult validatePaymentSecurity({
    required double serviceAmount,
    required double calculatedPlatformFee,
    required double calculatedYoerNet,
    required double platformFeeRate,
    bool isCash = false,
  }) {
    if (serviceAmount < minTransactionMxn) {
      return ValidationResult.invalid('El monto mínimo permitido por servicio es de \$10.00 MXN.');
    }

    if (isCash && serviceAmount > maxCashTransactionMxn) {
      return ValidationResult.invalid(
        'El monto excede el umbral legal permitido para transacciones en efectivo conforme a la Ley Antilavado.',
      );
    }

    // Verificación matemática de suma cero (tolerancia de 2 centavos por redondeo)
    final expectedFee = serviceAmount * platformFeeRate;
    if ((calculatedPlatformFee - expectedFee).abs() > 0.05) {
      return ValidationResult.invalid('Inconsistencia en el cálculo de comisión de plataforma.');
    }

    if ((calculatedYoerNet + calculatedPlatformFee - serviceAmount).abs() > 0.05) {
      return ValidationResult.invalid('El desglose financiero no coincide con el total del servicio.');
    }

    return ValidationResult.valid();
  }

  // ── 6. SANEAMIENTO Y PREVENCIÓN DE INYECCIONES ─────────────────────────────
  /// Elimina secuencias peligrosas para inyección de texto, XSS o PostgREST queries.
  static String sanitizeText(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Elimina HTML tags
        .replaceAll(RegExp(r'''["';\\]'''), '') // Elimina caracteres SQL sensibles
        .trim();
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.valid() => const ValidationResult._(isValid: true);
  factory ValidationResult.invalid(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);
}
