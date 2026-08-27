import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils Tests', () {
    test('Encrypt and decrypt should return original string', () {
      const String original = '+525512345678';
      final String encrypted = CryptoUtils.encrypt(original);
      
      expect(encrypted, startsWith('ENC:'));
      expect(encrypted, isNot(equals(original)));

      final String decrypted = CryptoUtils.decrypt(encrypted);
      expect(decrypted, equals(original));
    });

    test('Decrypting plaintext should return the plaintext (retrocompatibility)', () {
      const String plaintext = '5512345678';
      final String decrypted = CryptoUtils.decrypt(plaintext);
      expect(decrypted, equals(plaintext));
    });

    test('Masking phone number should hide all but last 4 digits', () {
      const String phone = '+525512345678';
      final String masked = CryptoUtils.maskPhoneNumber(phone);
      expect(masked, equals('*********5678'));

      final String encryptedPhone = CryptoUtils.encrypt(phone);
      final String maskedEncrypted = CryptoUtils.maskPhoneNumber(encryptedPhone);
      expect(maskedEncrypted, equals('*********5678'));
    });

    test('Masking short or empty phone number', () {
      expect(CryptoUtils.maskPhoneNumber(''), equals(''));
      expect(CryptoUtils.maskPhoneNumber('123'), equals('****'));
    });
  });
}
