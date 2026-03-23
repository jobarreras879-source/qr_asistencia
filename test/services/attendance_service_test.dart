import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'session_user_id': '123',
      'session_username': 'testuser',
      'session_role': 'USER',
    });

    // Initialize Supabase with an invalid URL to ensure requests fail
    // and trigger the catch block in AttendanceService methods.
    await Supabase.initialize(
      url: 'https://invalid.supabase.co',
      anonKey: 'dummy_key',
    );
  });

  group('AttendanceService Error Paths', () {
    test('registrarAsistencia returns error message on exception', () async {
      // Act
      final result = await AttendanceService.registrarAsistencia(
        '123/John Doe',
        'Proyecto A',
        'testuser',
        'Entrada',
      );

      // Assert
      expect(result, 'Ocurrió un error al registrar. Intenta de nuevo.');
    });

    test('getTodayCount returns 0 on error', () async {
      // Act
      final count = await AttendanceService.getTodayCount('testuser');

      // Assert
      expect(count, 0);
    });

    test('getCurrentUserHistory returns empty list on error', () async {
      // Act
      final history = await AttendanceService.getCurrentUserHistory();

      // Assert
      expect(history, isEmpty);
    });
  });
}
