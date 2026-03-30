import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fakes for Supabase
class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T data;
  FakePostgrestFilterBuilder(this.data);

  @override
  Future<U> then<U>(FutureOr<U> Function(T value) onValue, {Function? onError}) async {
    return onValue(data);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> insertedRows;
  FakeSupabaseQueryBuilder(this.insertedRows);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(Object values, {bool defaultToNull = true}) {
    insertedRows.add(values as Map<String, dynamic>);
    return FakePostgrestFilterBuilder(<Map<String, dynamic>>[]);
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final List<Map<String, dynamic>> insertedRows = [];

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'registros') {
      return FakeSupabaseQueryBuilder(insertedRows);
    }
    throw UnimplementedError('Table $table is not mocked');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSupabaseClient fakeClient;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    AttendanceService.supabaseClient = fakeClient;
    SharedPreferences.setMockInitialValues({'sheets_auto_sync': false});
  });

  group('AttendanceService._sanitizeQrInput via registrarAsistencia', () {
    const proyecto = 'Proyecto Test';
    const usuario = 'admin';
    const tipo = 'Entrada';

    test('Rejects empty input', () async {
      final result = await AttendanceService.registrarAsistencia('', proyecto, usuario, tipo);
      expect(result, contains('Código QR inválido o demasiado largo.'));
      expect(fakeClient.insertedRows, isEmpty);
    });

    test('Rejects input longer than 200 characters', () async {
      final longInput = 'A' * 201;
      final result = await AttendanceService.registrarAsistencia(longInput, proyecto, usuario, tipo);
      expect(result, contains('Código QR inválido o demasiado largo.'));
      expect(fakeClient.insertedRows, isEmpty);
    });

    test('Removes control characters', () async {
      // 123/JOHN\x00 DOE
      final inputWithControlChars = '123/JOHN\x00 DOE\x1F';
      final result = await AttendanceService.registrarAsistencia(inputWithControlChars, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], '123');
      expect(insertedRow['nombre'], 'JOHN DOE'); // Control characters should be removed
    });

    test('Prevents Google Sheets formula injection (startsWith =)', () async {
      final input = '=/=JOHN';
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'=");
      expect(insertedRow['nombre'], '=JOHN');
    });

    test('Prevents Google Sheets formula injection (startsWith +)', () async {
      final input = '+123/NAME';
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'+123");
      expect(insertedRow['nombre'], 'NAME');
    });

    test('Prevents Google Sheets formula injection (startsWith -)', () async {
      final input = '-123/NAME';
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'-123");
      expect(insertedRow['nombre'], 'NAME');
    });

    test('Prevents Google Sheets formula injection (startsWith @)', () async {
      final input = '@123/NAME';
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'@123");
      expect(insertedRow['nombre'], 'NAME');
    });

    test('Correctly parses normal valid QR input', () async {
      final input = '123456/OCTAVIO NARVAEZ';
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "123456");
      expect(insertedRow['nombre'], 'OCTAVIO NARVAEZ');
      expect(insertedRow['proyecto'], proyecto);
      expect(insertedRow['usuario_logueado'], usuario);
      expect(insertedRow['tipo'], tipo);
      expect(insertedRow['fecha_hora'], isNotNull);
    });

    test('Handles QR input without a separator', () async {
      final input = '123456'; // No slash
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows, hasLength(1));

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "123456");
      expect(insertedRow['nombre'], 'Desconocido');
    });

    test('Rejects when ID is empty after split', () async {
      final input = '/OCTAVIO'; // ID is empty
      final result = await AttendanceService.registrarAsistencia(input, proyecto, usuario, tipo);

      expect(result, contains('El código QR no contiene un ID válido.'));
      expect(fakeClient.insertedRows, isEmpty);
    });
  });
}
