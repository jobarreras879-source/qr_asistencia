import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

void main() {
  group('AttendanceService Tests', () {
    test('registrarAsistencia should return error string when an exception is thrown', () async {
      // Calling registrarAsistencia without initializing Supabase
      // will cause the lazy static `_supabase` variable to evaluate `Supabase.instance.client`,
      // which will throw an AssertionError. This exception will be caught by the catch block
      // in `registrarAsistencia` and return the specified error message.
      final result = await AttendanceService.registrarAsistencia(
        '123/John Doe',
        'Proyecto X',
        'test_user',
        'Entrada',
      );

      expect(result, 'Ocurrió un error al registrar. Intenta de nuevo.');
    });
  });
}
