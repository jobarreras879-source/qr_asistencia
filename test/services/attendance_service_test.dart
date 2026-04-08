import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) {
    throw Exception('Simulated network error');
  }
}

void main() {
  test('registrarAsistencia returns error message when Supabase throws exception', () async {
    AttendanceService.supabaseClient = FakeSupabaseClient();

    final result = await AttendanceService.registrarAsistencia(
      '123/JUAN PEREZ',
      'Proyecto X',
      'admin',
      'Entrada',
    );

    expect(result, 'Ocurrió un error al registrar. Intenta de nuevo.');
  });
}
