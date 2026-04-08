import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

void main() {
  group('AttendanceService._sanitizeQrInput', () {
    test('returns null for empty input', () {
      expect(AttendanceService.sanitizeQrInputForTest(''), isNull);
    });

    test('returns null for input longer than 200 characters', () {
      final longInput = 'a' * 201;
      expect(AttendanceService.sanitizeQrInputForTest(longInput), isNull);
    });

    test('strips control characters', () {
      final input = 'OCTAVIO\x00 NARVAEZ\x1F\x7F';
      expect(AttendanceService.sanitizeQrInputForTest(input), 'OCTAVIO NARVAEZ');
    });

    test('prefixes formulas starting with "=" to prevent Google Sheets injection', () {
      final input = '=cmd|...';
      expect(AttendanceService.sanitizeQrInputForTest(input), "'=cmd|...");
    });

    test('prefixes formulas starting with "+" to prevent Google Sheets injection', () {
      final input = '+1+1';
      expect(AttendanceService.sanitizeQrInputForTest(input), "'+1+1");
    });

    test('prefixes formulas starting with "-" to prevent Google Sheets injection', () {
      final input = '-1+1';
      expect(AttendanceService.sanitizeQrInputForTest(input), "'-1+1");
    });

    test('prefixes formulas starting with "@" to prevent Google Sheets injection', () {
      final input = '@SUM(A1:A2)';
      expect(AttendanceService.sanitizeQrInputForTest(input), "'@SUM(A1:A2)");
    });

    test('leaves valid input unmodified', () {
      final input = '2011704024923/OCTAVIO NARVAEZ';
      expect(AttendanceService.sanitizeQrInputForTest(input), input);
    });

    test('strips control characters AND prevents formula injection together', () {
      final input = '=\x001+1';
      // The control character \x00 is stripped first, making it start with '='
      // Then the formula injection prevention kicks in.
      expect(AttendanceService.sanitizeQrInputForTest(input), "'=1+1");
    });
  });
}
