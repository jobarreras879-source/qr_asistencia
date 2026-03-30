import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/password_hash_service.dart';
import 'package:qr_asistencia/utils/date_formatter.dart';

void main() {
  group('PasswordHashService', () {
    group('normalizeUsername', () {
      test('trims and lowercases the input', () {
        expect(PasswordHashService.normalizeUsername('  JPerez  '), 'jperez');
      });

      test('handles empty strings', () {
        expect(PasswordHashService.normalizeUsername(''), '');
      });

      test('handles strings with only whitespace', () {
        expect(PasswordHashService.normalizeUsername('   '), '');
      });

      test('handles already normalized strings', () {
        expect(PasswordHashService.normalizeUsername('jperez'), 'jperez');
      });

      test('handles strings with mixed case and no surrounding whitespace', () {
        expect(PasswordHashService.normalizeUsername('MaRiA'), 'maria');
      });
    });

    group('hash', () {
      test('is deterministic for the same password', () {
        final hashA = PasswordHashService.hash('admin123');
        final hashB = PasswordHashService.hash('admin123');

        expect(hashA, hashB);
        expect(hashA, isNotEmpty);
      });

      test('produces different hashes for different passwords', () {
        final hashA = PasswordHashService.hash('admin123');
        final hashB = PasswordHashService.hash('Admin123');

        expect(hashA, isNot(equals(hashB)));
      });

      test('handles empty password', () {
        // sha256('') = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        expect(
          PasswordHashService.hash(''),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        );
      });

      test('produces correct SHA-256 hash', () {
        // sha256('password') = 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
        expect(
          PasswordHashService.hash('password'),
          '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8',
        );
      });
    });
  });

  group('DateFormatter', () {
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
  });
}
