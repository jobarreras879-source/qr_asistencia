import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/password_hash_service.dart';
import 'package:qr_asistencia/utils/date_formatter.dart';

void main() {
  test('normalizeUsername trims and lowercases the input', () {
    expect(PasswordHashService.normalizeUsername('  JPerez  '), 'jperez');
  });

  test('hash generates a valid bcrypt string and can be verified', () {
    final password = 'admin123';
    final hashA = PasswordHashService.hash(password);
    final hashB = PasswordHashService.hash(password);

    // Bcrypt hashes should be different even for the same password due to salting
    expect(hashA, isNot(equals(hashB)));

    // But both should be verifiable
    expect(PasswordHashService.verify(password, hashA), isTrue);
    expect(PasswordHashService.verify(password, hashB), isTrue);
  });

  test('verify returns false for incorrect passwords', () {
    final hash = PasswordHashService.hash('admin123');
    expect(PasswordHashService.verify('wrong_password', hash), isFalse);
  });

  test('formatDate returns DD/MM/YYYY for valid datetime strings', () {
    expect(DateFormatter.formatDate('2026-03-22 21:35:00'), '22/03/2026');
  });

  test('formatDate returns empty string for null or empty values', () {
    expect(DateFormatter.formatDate(null), '');
    expect(DateFormatter.formatDate(''), '');
  });

  test('formatTime returns HH:MM for valid datetime strings', () {
    expect(DateFormatter.formatTime('2026-03-22 05:07:00'), '05:07');
  });

  test('formatTime returns empty string for invalid values', () {
    expect(DateFormatter.formatTime('fecha-invalida'), '');
    expect(DateFormatter.formatTime(null), '');
  });

  test('toStorageString formats DateTime for persistence', () {
    final date = DateTime(2026, 3, 22, 9, 8, 7);

    expect(DateFormatter.toStorageString(date), '2026-03-22 09:08:07');
  });
}
