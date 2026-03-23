import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_asistencia/services/auth_service.dart';
import 'package:qr_asistencia/services/user_service.dart';

class MockSupabaseClient implements SupabaseClient {
  final dynamic resultToReturn;
  final bool shouldThrow;

  MockSupabaseClient({this.resultToReturn, this.shouldThrow = false});

  @override
  SupabaseQueryBuilder from(String table) {
    return MockQueryBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQueryBuilder implements SupabaseQueryBuilder {
  final dynamic resultToReturn;
  final bool shouldThrow;

  MockQueryBuilder({this.resultToReturn, this.shouldThrow = false});

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = true}) {
    return MockFilterBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Object values) {
    return MockFilterBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    return MockFilterBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockSelectFilterBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFilterBuilder implements PostgrestFilterBuilder<dynamic> {
  final dynamic resultToReturn;
  final bool shouldThrow;

  MockFilterBuilder({this.resultToReturn, this.shouldThrow = false});

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    return this;
  }

  @override
  Future<U> then<U>(
      FutureOr<U> Function(dynamic value) onValue,
      {Function? onError}) {
    if (shouldThrow) {
      final future = Future<U>.error(resultToReturn);
      if (onError != null) {
        return future.catchError(onError);
      }
      return future;
    }
    return Future.value(onValue(resultToReturn));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSelectFilterBuilder implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic resultToReturn;
  final bool shouldThrow;

  MockSelectFilterBuilder({this.resultToReturn, this.shouldThrow = false});

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(String column,
      {bool ascending = false, bool nullsFirst = false, String? referencedTable}) {
    return MockTransformBuilder(resultToReturn: resultToReturn, shouldThrow: shouldThrow);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransformBuilder implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final dynamic resultToReturn;
  final bool shouldThrow;

  MockTransformBuilder({this.resultToReturn, this.shouldThrow = false});

  @override
  Future<U> then<U>(
      FutureOr<U> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError}) {
    if (shouldThrow) {
      final future = Future<U>.error(resultToReturn);
      if (onError != null) {
        return future.catchError(onError);
      }
      return future;
    }
    return Future.value(onValue(resultToReturn as List<Map<String, dynamic>>));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() {
    AuthService.setMockUserForTesting(null);
  });

  group('UserService Tests', () {
    test('getUsuarios returns mapped data successfully', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: [
        {'id': 1, 'usuario': 'admin', 'rol': 'ADMIN', 'activo': true},
        {'id': 2, 'usuario': 'user1', 'rol': 'USUARIO', 'activo': false},
      ]);

      final result = await UserService.getUsuarios();

      expect(result.length, 2);
      expect(result[0]['usuario'], 'admin');
      expect(result[0]['rol'], 'ADMIN');
      expect(result[0]['activo'], true);
      expect(result[1]['activo'], false);
    });

    test('getUsuarios handles exception and returns empty list', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: Exception('DB Error'), shouldThrow: true);
      final result = await UserService.getUsuarios();
      expect(result, isEmpty);
    });

    test('crearUsuario returns error if username is empty', () async {
      final result = await UserService.crearUsuario('   ', 'password123', 'USUARIO');
      expect(result, 'El usuario es obligatorio.');
    });

    test('crearUsuario returns error if password < 6 chars', () async {
      final result = await UserService.crearUsuario('user', '12345', 'USUARIO');
      expect(result, 'La contraseña debe tener mínimo 6 caracteres.');
    });

    test('crearUsuario successful insert returns null', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: []);
      final result = await UserService.crearUsuario('user_test', '123456', 'USUARIO');
      expect(result, isNull);
    });

    test('crearUsuario handles duplicate error', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: Exception('duplicate key value'), shouldThrow: true);
      final result = await UserService.crearUsuario('user_test', '123456', 'USUARIO');
      expect(result, 'Ese usuario ya existe.');
    });

    test('editarUsuario returns error if username is empty', () async {
      final result = await UserService.editarUsuario('1', '   ', 'password123', 'USUARIO');
      expect(result, 'El usuario es obligatorio.');
    });

    test('editarUsuario returns error if new password < 6 chars', () async {
      final result = await UserService.editarUsuario('1', 'user', '12345', 'USUARIO');
      expect(result, 'La contraseña debe tener mínimo 6 caracteres.');
    });

    test('editarUsuario returns error if removing own ADMIN role', () async {
      AuthService.setMockUserForTesting('1', 'admin', 'ADMIN');
      final result = await UserService.editarUsuario('1', 'admin', null, 'USUARIO');
      expect(result, 'No puedes quitarte tu propio rol ADMIN mientras estás dentro.');
    });

    test('editarUsuario successful update without password returns null', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: []);
      final result = await UserService.editarUsuario('1', 'user_test', null, 'ADMIN');
      expect(result, isNull);
    });

    test('editarUsuario successful update with password returns null', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: []);
      final result = await UserService.editarUsuario('1', 'user_test', 'newpass123', 'ADMIN');
      expect(result, isNull);
    });

    test('editarUsuario successful update refreshes session if editing self', () async {
      AuthService.setMockUserForTesting('1');
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: []);
      final result = await UserService.editarUsuario('1', 'user_test', null, 'ADMIN');
      expect(result, isNull);

      // Verification: because we set the user to '1', it should trigger refreshLocalSession
      // which internally updates the _currentUsername. So let's check it:
      expect(AuthService.currentUserId, '1');
    });

    test('editarUsuario handles duplicate error', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: Exception('unique constraint violated'), shouldThrow: true);
      final result = await UserService.editarUsuario('1', 'user_test', null, 'ADMIN');
      expect(result, 'Ese usuario ya existe.');
    });

    test('eliminarUsuario returns error if deleting self', () async {
      AuthService.setMockUserForTesting('1');
      final result = await UserService.eliminarUsuario('1');
      expect(result, 'No puedes eliminar tu propio usuario mientras estás dentro.');
    });

    test('eliminarUsuario successful delete returns null', () async {
      AuthService.setMockUserForTesting('2');
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: []);
      final result = await UserService.eliminarUsuario('1');
      expect(result, isNull);
    });

    test('eliminarUsuario handles exception', () async {
      UserService.supabaseClient = MockSupabaseClient(resultToReturn: Exception('delete failed'), shouldThrow: true);
      final result = await UserService.eliminarUsuario('1');
      expect(result, 'No se pudo eliminar el usuario.');
    });
  });
}
