import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_asistencia/services/attendance_service.dart';
import 'package:qr_asistencia/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AttendanceService Tests', () {
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQueryBuilder;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();

      AttendanceService.mockClient = mockSupabase;
      AuthService.setMockSession('testId', 'testUser', 'USUARIO');
    });

    tearDown(() {
      AttendanceService.mockClient = null;
      AuthService.setMockSession(null, null, null);
    });

    group('sanitizeQrInput', () {
      test('returns null for empty string', () {
        expect(AttendanceService.sanitizeQrInput(''), isNull);
      });

      test('returns null for string longer than 200 characters', () {
        final longString = 'a' * 201;
        expect(AttendanceService.sanitizeQrInput(longString), isNull);
      });

      test('removes control characters', () {
        final input = 'valid\x00\x01\x1Finput\x7F';
        expect(AttendanceService.sanitizeQrInput(input), 'validinput');
      });

      test('escapes formulas', () {
        expect(AttendanceService.sanitizeQrInput('=SUM(A1:A2)'), "'=SUM(A1:A2)");
        expect(AttendanceService.sanitizeQrInput('+1+1'), "'+1+1");
        expect(AttendanceService.sanitizeQrInput('-1+1'), "'-1+1");
        expect(AttendanceService.sanitizeQrInput('@formula'), "'@formula");
      });

      test('leaves valid input unchanged', () {
        const input = '123456789/JOHN DOE';
        expect(AttendanceService.sanitizeQrInput(input), input);
      });
    });

    group('registrarAsistencia', () {
      test('fails with invalid QR', () async {
        final result = await AttendanceService.registrarAsistencia('', 'Proy1', 'testUser', 'ENTRADA');
        expect(result, contains('inválido o demasiado largo'));
      });

      test('fails with QR missing ID', () async {
        final result = await AttendanceService.registrarAsistencia('/', 'Proy1', 'testUser', 'ENTRADA');
        expect(result, contains('no contiene un ID válido'));
      });

      test('handles Supabase exception gracefully', () async {
        when(() => mockSupabase.from('registros')).thenThrow(Exception('DB Error'));

        final result = await AttendanceService.registrarAsistencia(
          '123456789/JOHN DOE',
          'ProyectoX',
          'user123',
          'ENTRADA',
        );

        expect(result, 'Ocurrió un error al registrar. Intenta de nuevo.');
      });
    });

    group('getTodayCount', () {
      test('returns 0 for empty username', () async {
        final count = await AttendanceService.getTodayCount('   ');
        expect(count, 0);
      });

      test('handles Supabase exception gracefully', () async {
        when(() => mockSupabase.from('registros')).thenThrow(Exception('DB Error'));

        final result = await AttendanceService.getTodayCount('testUser');

        expect(result, 0);
      });
    });

    group('getCurrentUserHistory', () {
      test('returns empty if no user logged in', () async {
        AuthService.setMockSession(null, null, null);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'read') {
                return null;
              }
              return null;
            },
          );

        final history = await AttendanceService.getCurrentUserHistory();
        expect(history, isEmpty);
      });

      test('handles Supabase exception gracefully', () async {
        when(() => mockSupabase.from('registros')).thenThrow(Exception('DB Error'));

        final result = await AttendanceService.getCurrentUserHistory();

        expect(result, isEmpty);
      });
    });
  });
}
