/// Configuración de la aplicación.
/// Las credenciales se ofuscan en partes para dificultar la extracción
/// automática por herramientas de análisis estático (decompiladores de APK).
/// 
/// NOTA IMPORTANTE: Esto NO es seguridad completa. Un atacante determinado
/// aún podría encontrarlas. La verdadera protección está en tener 
/// Row Level Security (RLS) bien configurado en Supabase.
class AppConfig {
  // Supabase URL ofuscada (dividida en partes)
  static String get supabaseUrl {
    const parts = [
      'https://qwnc',
      'rihpfckm',
      'uablqroa',
      '.supabase.co',
    ];
    return parts.join();
  }

  // Supabase Anon Key ofuscada (dividida en partes)
  static String get supabaseAnonKey {
    const parts = [
      'sb_publishable_',
      'vqFcmjd5oRX_',
      '4DpSYcWLVA_',
      'SZ0fEv2a',
    ];
    return parts.join();
  }

  // Google OAuth Server Client ID
  static String get googleServerClientId {
    const parts = [
      '251002473484-',
      'dqdqeard4s68dbme',
      '5669g26ao7fv9g0l',
      '.apps.googleusercontent.com',
    ];
    return parts.join();
  }
}
