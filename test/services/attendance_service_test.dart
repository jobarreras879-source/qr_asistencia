import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('AttendanceService Tests', () {
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      AttendanceService.supabaseClient = mockSupabase;
    });

    test('registrarAsistencia handles Supabase exception and returns error string', () async {
      // Arrange
      when(() => mockSupabase.from(any())).thenThrow(Exception('Supabase connection failed'));

      // Act
      final result = await AttendanceService.registrarAsistencia(
        '123456789/OCTAVIO',
        'Proyecto Alpha',
        'usuario1',
        'Entrada',
      );

      // Assert
      expect(result, 'Ocurrió un error al registrar. Intenta de nuevo.');
    });
  });
}
