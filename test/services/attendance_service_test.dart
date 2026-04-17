import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/attendance_service.dart';

// Fake implementation of SupabaseClient to intercept inserts
class FakeSupabaseClient extends Fake implements SupabaseClient {
  final List<Map<String, dynamic>> insertedRows = [];

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'registros') {
      return FakeSupabaseQueryBuilder(insertedRows);
    }
    throw UnimplementedError('Table $table not mocked');
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> insertedRows;
  FakeSupabaseQueryBuilder(this.insertedRows);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(Object values, {bool defaultToNull = true}) {
    if (values is Map<String, dynamic>) {
      insertedRows.add(values);
    } else if (values is List) {
      insertedRows.addAll(values.cast<Map<String, dynamic>>());
    }
    return FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T result;
  FakePostgrestFilterBuilder(this.result);

  Future<T> get _future => Future.value(result);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) => _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) => _future.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => _future.whenComplete(action);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSupabaseClient fakeClient;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    AttendanceService.supabaseClient = fakeClient;
    SharedPreferences.setMockInitialValues({});
  });

  group('AttendanceService.registrarAsistencia - Sanitization Tests', () {
    const defaultProject = 'Proyecto A';
    const defaultUser = 'admin';
    const defaultType = 'Entrada';

    test('Rejects empty QR input', () async {
      final result = await AttendanceService.registrarAsistencia('', defaultProject, defaultUser, defaultType);

      expect(result, contains('inválido o demasiado largo'));
      expect(fakeClient.insertedRows, isEmpty);
    });

    test('Rejects QR input longer than 200 characters', () async {
      final longQr = 'a' * 201;
      final result = await AttendanceService.registrarAsistencia(longQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('inválido o demasiado largo'));
      expect(fakeClient.insertedRows, isEmpty);
    });

    test('Strips control characters from QR input', () async {
      // String with \x00 (null), \x1F, and \x7F
      const dirtyQr = '123/JUAN\x00PEREZ\x1F\x7F';

      final result = await AttendanceService.registrarAsistencia(dirtyQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], '123');
      expect(insertedRow['nombre'], 'JUANPEREZ'); // Control chars removed
    });

    test('Prepends single quote to prevent formula injection starting with =', () async {
      const formulaQr = '=/MALICIOSO';

      final result = await AttendanceService.registrarAsistencia(formulaQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'=");
      expect(insertedRow['nombre'], 'MALICIOSO');
    });

    test('Prepends single quote to prevent formula injection starting with +', () async {
      const formulaQr = '+123/JUAN';

      final result = await AttendanceService.registrarAsistencia(formulaQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'+123");
      expect(insertedRow['nombre'], 'JUAN');
    });

    test('Prepends single quote to prevent formula injection starting with -', () async {
      const formulaQr = '-123/JUAN';

      final result = await AttendanceService.registrarAsistencia(formulaQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'-123");
      expect(insertedRow['nombre'], 'JUAN');
    });

    test('Prepends single quote to prevent formula injection starting with @', () async {
      const formulaQr = '@123/JUAN';

      final result = await AttendanceService.registrarAsistencia(formulaQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], "'@123");
      expect(insertedRow['nombre'], 'JUAN');
    });

    test('Processes a normal valid QR correctly', () async {
      const normalQr = '2011704024923/OCTAVIO NARVAEZ';

      final result = await AttendanceService.registrarAsistencia(normalQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('✅'));
      expect(result, contains('OCTAVIO NARVAEZ'));
      expect(result, contains('2011704024923'));
      expect(fakeClient.insertedRows.length, 1);

      final insertedRow = fakeClient.insertedRows.first;
      expect(insertedRow['DPI'], '2011704024923');
      expect(insertedRow['nombre'], 'OCTAVIO NARVAEZ');
      expect(insertedRow['proyecto'], defaultProject);
      expect(insertedRow['usuario_logueado'], defaultUser);
      expect(insertedRow['tipo'], defaultType);
    });

    test('Returns error if QR does not contain valid ID', () async {
      const invalidQr = '/SOLO NOMBRE';

      final result = await AttendanceService.registrarAsistencia(invalidQr, defaultProject, defaultUser, defaultType);

      expect(result, contains('El código QR no contiene un ID válido'));
      expect(fakeClient.insertedRows, isEmpty);
    });
  });
}
