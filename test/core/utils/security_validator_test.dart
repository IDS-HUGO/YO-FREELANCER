import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/core/utils/security_validator.dart';

void main() {
  group('SecurityValidator Tests', () {
    test('Valida RFC de persona física y moral correctamente', () {
      expect(SecurityValidator.isValidRFC('GARM8501011A2'), isTrue); // Persona Física
      expect(SecurityValidator.isValidRFC('IMS421231I45'), isTrue);  // Persona Moral
      expect(SecurityValidator.isValidRFC('12345'), isFalse);
      expect(SecurityValidator.isValidRFC(null), isFalse);
    });

    test('Valida formato oficial de CURP', () {
      expect(SecurityValidator.isValidCURP('GARM850101HDFRNR02'), isTrue);
      expect(SecurityValidator.isValidCURP('INVALIDCURP'), isFalse);
      expect(SecurityValidator.isValidCURP(null), isFalse);
    });

    test('Valida CLABE interbancaria mexicana con dígito verificador Banxico', () {
      // CLABE real STP / Banxico válida: 032180000118359719
      expect(SecurityValidator.isValidCLABE('032180000118359719'), isTrue);
      expect(SecurityValidator.isValidCLABE('032180000118359710'), isFalse); // Dígito inválido
      expect(SecurityValidator.isValidCLABE('12345'), isFalse);
    });

    test('Valida número celular mexicano de 10 dígitos', () {
      expect(SecurityValidator.isValidMexicanPhone('5512345678'), isTrue);
      expect(SecurityValidator.isValidMexicanPhone('+52 55 1234 5678'), isTrue);
      expect(SecurityValidator.isValidMexicanPhone('12345'), isFalse);
    });

    test('Valida seguridad matemática y límites de pago Escrow', () {
      final valid = SecurityValidator.validatePaymentSecurity(
        serviceAmount: 1000.0,
        calculatedPlatformFee: 100.0,
        calculatedYoerNet: 900.0,
        platformFeeRate: 0.10,
      );
      expect(valid.isValid, isTrue);

      final invalid = SecurityValidator.validatePaymentSecurity(
        serviceAmount: 1000.0,
        calculatedPlatformFee: 50.0, // Alterado
        calculatedYoerNet: 900.0,
        platformFeeRate: 0.10,
      );
      expect(invalid.isValid, isFalse);
    });

    test('Sanea texto contra inyecciones', () {
      final input = '<script>alert("hack")</script> Pedro; DROP TABLE users;';
      final clean = SecurityValidator.sanitizeText(input);
      expect(clean.contains('<script>'), isFalse);
      expect(clean.contains(';'), isFalse);
    });
  });
}
