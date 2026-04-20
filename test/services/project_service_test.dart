import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/project_service.dart';

// Create fake classes that can easily be controlled without full mockito
class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeSupabaseQueryBuilder _queryBuilder;

  FakeSupabaseClient(this._queryBuilder);

  @override
  SupabaseQueryBuilder from(String? table) => _queryBuilder;
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final FakePostgrestFilterBuilder _filterBuilder;

  FakeSupabaseQueryBuilder(this._filterBuilder);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? columns = '*']) => _filterBuilder;
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  dynamic errorToThrow;
  List<Map<String, dynamic>>? dataToReturn;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(String? column, {bool? ascending = false, bool? nullsFirst = false, String? referencedTable}) {
    if (errorToThrow != null) {
      throw errorToThrow;
    }
    return FakePostgrestTransformBuilder(dataToReturn!);
  }
}

class FakePostgrestTransformBuilder extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;

  FakePostgrestTransformBuilder(this.data);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value)? onValue, {
    Function? onError,
  }) async {
    return onValue!(data);
  }
}

void main() {
  late FakeSupabaseClient fakeSupabase;
  late FakeSupabaseQueryBuilder fakeQueryBuilder;
  late FakePostgrestFilterBuilder fakeFilterBuilder;

  setUp(() {
    fakeFilterBuilder = FakePostgrestFilterBuilder();
    fakeQueryBuilder = FakeSupabaseQueryBuilder(fakeFilterBuilder);
    fakeSupabase = FakeSupabaseClient(fakeQueryBuilder);

    ProjectService.mockClient = fakeSupabase;
  });

  group('getProyectos', () {
    test('returns an empty list when an exception is thrown', () async {
      fakeFilterBuilder.errorToThrow = Exception('Simulated Supabase Error');

      final result = await ProjectService.getProyectos();

      expect(result, isEmpty);
    });

    test('returns mapped projects on successful fetch', () async {
      fakeFilterBuilder.dataToReturn = [
        {'No.': 1, 'NameProyect': 'Project A', 'Client': 'Client X', 'OC': 'OC1'},
        {'No.': 2, 'NameProyect': null, 'Client': null, 'OC': null},
      ];

      final result = await ProjectService.getProyectos();

      expect(result.length, 2);
      expect(result[0]['numero'], '1');
      expect(result[0]['nombre'], 'Project A');
      expect(result[0]['cliente'], 'Client X');
      expect(result[0]['oc'], 'OC1');

      expect(result[1]['numero'], '2');
      expect(result[1]['nombre'], 'Sin nombre');
      expect(result[1]['cliente'], '');
      expect(result[1]['oc'], '');
    });
  });
}
