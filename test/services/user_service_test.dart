import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/user_service.dart';

import 'user_service_test.mocks.dart';

// Create a simple fake for TransformBuilder to resolve the await issue cleanly
class _FakeTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T data;
  _FakeTransformBuilder(this.data);

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return Future.value(data).catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future.value(data).then(onValue, onError: onError);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future.value(data).whenComplete(action);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return Future.value(data).timeout(timeLimit, onTimeout: onTimeout);
  }
}

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    // Inyectar el cliente mock
    UserService.supabaseClient = mockSupabaseClient;
  });

  group('UserService.getUsuarios', () {
    test('returns empty list and logs error when Supabase throws exception', () async {
      // Configurar el mock para simular la cadena: .from(_tableName).select('...').order(...)
      // Since mock chaining with generic types in postgrest can be difficult with Mockito,
      // it's easier to mock PostgrestFilterBuilder with the proper generic type
      final mockFilterBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder = MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      // Because Supabase fluent API uses Futures deeply, mockito struggles sometimes with stubbing nested mocks.
      // Another approach is creating a fake `SupabaseClient` for getUsuarios, but mockito also allows throwing properly
      // when awaited if we return an answer.
      when(mockSupabaseClient.from(any)).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select(any)).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
          .thenThrow(Exception('Simulated Supabase error'));

      // Ejecutar la función a probar
      final result = await UserService.getUsuarios();

      // Verificar que retorna lista vacía
      expect(result, isEmpty);
    });

    test('returns correctly mapped users on success', () async {
      final mockData = [
        {'id': 1, 'usuario': 'admin', 'rol': 'ADMIN', 'activo': true},
        {'id': 2, 'usuario': 'user1', 'rol': null, 'activo': false},
      ];

      final mockFilterBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

      // Instead of relying on mockito stubs for complex generic types we can create a fake or use the type itself
      final fakeTransform = _FakeTransformBuilder<List<Map<String, dynamic>>>(mockData);
      when(mockSupabaseClient.from(any)).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select(any)).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
          .thenAnswer((_) => fakeTransform);

      final result = await UserService.getUsuarios();

      expect(result, hasLength(2));

      expect(result[0]['id'], '1');
      expect(result[0]['usuario'], 'admin');
      expect(result[0]['rol'], 'ADMIN');
      expect(result[0]['activo'], true);

      expect(result[1]['id'], '2');
      expect(result[1]['usuario'], 'user1');
      expect(result[1]['rol'], 'USUARIO'); // default value
      expect(result[1]['activo'], false);
    });
  });
}
