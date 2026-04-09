import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return super.noSuchMethod(
      Invocation.method(#then, [onValue], {#onError: onError}),
    );
  }
}
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  @override
  Future<T> then<T>(
    FutureOr<T> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) {
    if (onError != null) {
      return Future<T>.error(Exception('Database connection failed')).catchError(onError);
    }
    return Future<T>.error(Exception('Database connection failed'));
  }
}

void main() {
  group('AuthService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder1;
    late MockPostgrestFilterBuilder mockFilterBuilder2;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder1 = MockPostgrestFilterBuilder();
      mockFilterBuilder2 = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();

      AuthService.setMockSupabase(mockSupabaseClient);
    });

    tearDown(() {
      AuthService.setMockSupabase(null);
    });

    test('signIn catches exceptions and sets lastErrorMessage', () async {
      final testException = Exception('Database connection failed');

      // from('usuarios')
      when(() => mockSupabaseClient.from('usuarios')).thenAnswer((_) => mockQueryBuilder);

      // select('id, usuario, password_hash, rol, activo')
      when(() => mockQueryBuilder.select('id, usuario, password_hash, rol, activo'))
          .thenAnswer((_) => mockFilterBuilder1); // Actually PostgrestFilterBuilder is not a Future

      // eq('usuario', normalizedUser) -> "jperez"
      when(() => mockFilterBuilder1.eq('usuario', 'jperez'))
          .thenAnswer((_) => mockFilterBuilder2); // PostgrestFilterBuilder

      // eq('activo', true)
      when(() => mockFilterBuilder2.eq('activo', true))
          .thenAnswer((_) => mockFilterBuilder2);

      // maybeSingle() returns a transform builder which is awaited
      when(() => mockFilterBuilder2.maybeSingle()).thenAnswer((_) => mockTransformBuilder);

      final result = await AuthService.signIn('jperez', 'password123');

      expect(result, isNull);
      expect(AuthService.lastErrorMessage, testException.toString());
    });
  });
}
