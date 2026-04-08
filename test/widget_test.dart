import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/password_hash_service.dart';
import 'package:qr_asistencia/utils/date_formatter.dart';

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

  test('formatDate returns DD/MM/YYYY for valid datetime strings', () {
    expect(DateFormatter.formatDate('2026-03-22 21:35:00'), '22/03/2026');
  });

  test('formatDate returns empty string for null or empty values', () {
    expect(DateFormatter.formatDate(null), '');
    expect(DateFormatter.formatDate(''), '');
  });

  test('formatDate returns original string for invalid values', () {
    expect(DateFormatter.formatDate('invalid-date'), 'invalid-date');
  });

  test('formatTime returns HH:MM for valid datetime strings', () {
    expect(DateFormatter.formatTime('2026-03-22 05:07:00'), '05:07');
  });

  test('formatTime returns empty string for invalid values', () {
    expect(DateFormatter.formatTime('fecha-invalida'), '');
    expect(DateFormatter.formatTime(''), '');
    expect(DateFormatter.formatTime(null), '');
  });

  test('toStorageString formats DateTime for persistence', () {
    final date = DateTime(2026, 3, 22, 9, 8, 7);

    expect(DateFormatter.toStorageString(date), '2026-03-22 09:08:07');
  });
}
