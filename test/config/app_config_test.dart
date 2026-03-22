import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('supabaseUrl returns the correct non-empty string', () {
      final url = AppConfig.supabaseUrl;
      expect(url, isA<String>());
      expect(url.isNotEmpty, true);
      expect(url, 'https://qwncrihpfckmuablqroa.supabase.co');
    });

    test('supabaseAnonKey returns the correct non-empty string', () {
      final key = AppConfig.supabaseAnonKey;
      expect(key, isA<String>());
      expect(key.isNotEmpty, true);
      expect(key, 'sb_publishable_vqFcmjd5oRX_4DpSYcWLVA_SZ0fEv2a');
    });

    test('googleServerClientId returns the correct non-empty string', () {
      final clientId = AppConfig.googleServerClientId;
      expect(clientId, isA<String>());
      expect(clientId.isNotEmpty, true);
      expect(clientId, '251002473484-dqdqeard4s68dbme5669g26ao7fv9g0l.apps.googleusercontent.com');
    });
  });
}
