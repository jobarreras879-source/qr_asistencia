import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/password_hash_service.dart';

void main() {
  test('normalizeUsername trims and lowercases the input', () {
    expect(PasswordHashService.normalizeUsername('  JPerez  '), 'jperez');
  });

  test('hash is deterministic for the same password', () {
    final hashA = PasswordHashService.hash('admin123');
    final hashB = PasswordHashService.hash('admin123');

    expect(hashA, hashB);
    expect(hashA, isNotEmpty);
  });
}
