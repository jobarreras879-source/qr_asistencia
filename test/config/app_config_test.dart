import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asistencia/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('supabaseUrl should return the correctly concatenated string', () {
      final url = AppConfig.supabaseUrl;
      expect(url, isNotEmpty);
      expect(url, startsWith('https://'));
      expect(url, endsWith('.supabase.co'));
      expect(url, 'https://qwncrihpfckmuablqroa.supabase.co');
    });

    test('supabaseAnonKey should return the correctly concatenated string', () {
      final key = AppConfig.supabaseAnonKey;
      expect(key, isNotEmpty);
      expect(key, startsWith('sb_publishable_'));
      expect(key, 'sb_publishable_vqFcmjd5oRX_4DpSYcWLVA_SZ0fEv2a');
    });

    test('googleServerClientId should return the correctly concatenated string', () {
      final clientId = AppConfig.googleServerClientId;
      expect(clientId, isNotEmpty);
      expect(clientId, endsWith('.apps.googleusercontent.com'));
      expect(clientId, '251002473484-dqdqeard4s68dbme5669g26ao7fv9g0l.apps.googleusercontent.com');
    });
  });
}
