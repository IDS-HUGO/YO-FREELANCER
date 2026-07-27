// test/shared/utils/file_upload_validator_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/shared/utils/file_upload_validator.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('file_upload_validator_test');
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  Future<File> writeBytes(String name, List<int> bytes) async {
    final file = File('${tmpDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  test('acepta un JPEG válido', () async {
    final file = await writeBytes('a.jpg', [0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0]);
    await expectLater(FileUploadValidator.validateImageFile(file), completes);
  });

  test('acepta un PNG válido', () async {
    final file = await writeBytes(
      'a.png',
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0],
    );
    await expectLater(FileUploadValidator.validateImageFile(file), completes);
  });

  test('rechaza un archivo que no es imagen (magic bytes inválidos)', () async {
    final file = await writeBytes('fake.jpg', [0x25, 0x50, 0x44, 0x46]); // %PDF
    expect(
      FileUploadValidator.validateImageFile(file),
      throwsA(isA<FileValidationException>()),
    );
  });

  test('rechaza un archivo que excede el tamaño máximo', () async {
    final bytes = Uint8List(2000)..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
    final file = await writeBytes('big.jpg', bytes);
    expect(
      FileUploadValidator.validateImageFile(file, maxSizeBytes: 1000),
      throwsA(isA<FileValidationException>()),
    );
  });

  test('rechaza un archivo vacío', () async {
    final file = await writeBytes('empty.jpg', []);
    expect(
      FileUploadValidator.validateImageFile(file),
      throwsA(isA<FileValidationException>()),
    );
  });

  test('rechaza un archivo inexistente', () async {
    final file = File('${tmpDir.path}/no-existe.jpg');
    expect(
      FileUploadValidator.validateImageFile(file),
      throwsA(isA<FileValidationException>()),
    );
  });
}
