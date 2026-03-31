/// Configuración de la aplicación.
/// Las credenciales se inyectan en tiempo de compilación mediante --dart-define
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qwncrihpfckmuablqroa.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_vqFcmjd5oRX_4DpSYcWLVA_SZ0fEv2a',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '251002473484-dqdqeard4s68dbme5669g26ao7fv9g0l.apps.googleusercontent.com',
  );
}
