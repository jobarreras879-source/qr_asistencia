import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/services/auth_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return null;
        }
        if (methodCall.method == 'write') {
          return null;
        }
        if (methodCall.method == 'delete') {
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('signIn error without supabase', () async {
    final result = await AuthService.signIn('user', 'pass');
    expect(result, isNull);
    expect(AuthService.lastErrorMessage, isNotNull);
    expect(AuthService.lastErrorMessage, contains('You must initialize the supabase instance'));

    // reset lastErrorMessage
    await AuthService.signIn('user', 'pass');
  });

  test('signOut error without storage', () async {
    await AuthService.signOut();
  });

  test('getCurrentUserRole uses default role if fail', () async {
    final role = await AuthService.getCurrentUserRole();
    expect(role, 'USUARIO');
  });

  test('getCurrentUsername uses default null if fail', () async {
    final username = await AuthService.getCurrentUsername();
    expect(username, isNull);
  });

  test('restoreSession handles errors gracefully', () async {
     final session = await AuthService.restoreSession();
     expect(session, isNull);
  });

  test('getFriendlyLastError mapping', () async {
     // First mock the error string inside AuthService
     // Since _lastErrorMessage is private and only settable by methods,
     // we will test getFriendlyLastError by generating strings in it.

     // 1. the error message from the above test is 'You must initialize the supabase instance...'
     expect(AuthService.getFriendlyLastError(), contains('No se pudo iniciar sesión: \'package:supabase_flutter'));
  });
}
