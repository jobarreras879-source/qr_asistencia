import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeSupabaseQueryBuilder queryBuilder = FakeSupabaseQueryBuilder();

  @override
  SupabaseQueryBuilder from(String table) {
    return queryBuilder;
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> insertedRows = [];

  @override
  PostgrestFilterBuilder<void> insert(Object values, {bool defaultToNull = true}) {
    if (values is Map<String, dynamic>) {
      insertedRows.add(values);
    } else if (values is List) {
      for (final value in values) {
        if (value is Map<String, dynamic>) {
          insertedRows.add(value);
        }
      }
    }
    return FakePostgrestFilterBuilder();
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<void> {
  // Mocktail was getting confused because PostgrestFilterBuilder implements Future,
  // so `thenReturn` was complaining. With a manual fake, we can just implement the methods needed by the test.

  // `await` calls `then`
  @override
  Future<S> then<S>(FutureOr<S> Function(void value) onValue, {Function? onError}) async {
    return onValue(null);
  }
}

void main() {
  late FakeSupabaseClient fakeClient;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    AttendanceService.supabaseClient = fakeClient;
    SharedPreferences.setMockInitialValues({'sheets_auto_sync': false});
  });

  group('AttendanceService._sanitizeQrInput via registrarAsistencia', () {
    test('returns error message for empty QR string', () async {
      final result = await AttendanceService.registrarAsistencia('', 'Proy1', 'User1', 'Entrada');
      expect(result, '⚠️ Código QR inválido o demasiado largo.');
      expect(fakeClient.queryBuilder.insertedRows, isEmpty);
    });

    test('returns error message for extremely long QR string', () async {
      final longString = 'A' * 201;
      final result = await AttendanceService.registrarAsistencia(longString, 'Proy1', 'User1', 'Entrada');
      expect(result, '⚠️ Código QR inválido o demasiado largo.');
      expect(fakeClient.queryBuilder.insertedRows, isEmpty);
    });

    test('strips control characters from QR string', () async {
      final qrWithControlChars = '123\x00456\x1F/John\x7FDoe';
      await AttendanceService.registrarAsistencia(qrWithControlChars, 'Proy1', 'User1', 'Entrada');

      expect(fakeClient.queryBuilder.insertedRows, isNotEmpty);
      final row = fakeClient.queryBuilder.insertedRows.first;
      expect(row['DPI'], '123456');
      expect(row['nombre'], 'JohnDoe');
    });

    test('prepends single quote to prevent formula injection in Google Sheets', () async {
      final payloads = [
        '=1+1/Jane',
        '+A1/Jane',
        '-5/Jane',
        '@sum/Jane',
      ];

      for (int i = 0; i < payloads.length; i++) {
        await AttendanceService.registrarAsistencia(payloads[i], 'Proy1', 'User1', 'Entrada');
        final row = fakeClient.queryBuilder.insertedRows[i];

        expect(row['DPI']?.toString().startsWith("'"), isTrue,
            reason: 'Payload starting with formula character should be escaped. Failed for: ${payloads[i]}');
      }
    });

    test('successfully registers valid QR in expected format', () async {
      final result = await AttendanceService.registrarAsistencia('123456789/Test User', 'Proy1', 'User1', 'Entrada');
      expect(result, contains('✅ Entrada registrado'));

      expect(fakeClient.queryBuilder.insertedRows, isNotEmpty);
      final row = fakeClient.queryBuilder.insertedRows.last;
      expect(row['DPI'], '123456789');
      expect(row['nombre'], 'Test User');
      expect(row['proyecto'], 'Proy1');
      expect(row['tipo'], 'Entrada');
      expect(row['usuario_logueado'], 'User1');
      expect(row['fecha_hora'], isNotNull);
    });
  });
}
