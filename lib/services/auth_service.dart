import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

/// Servicio de autenticación centralizado usando Supabase Auth.
/// Reemplaza la lógica de login de [ApiService] que consultaba
/// la tabla `usuarios` directamente con SHA-256.
class AuthService {
  static final _supabase = Supabase.instance.client;

  // ─── Estado de sesión ────────────────────────────────────────────

  /// Usuario actualmente autenticado, null si no hay sesión.
  static get currentUser => _supabase.auth.currentUser;

  /// Sesión actual, null si no hay sesión activa.
  static get currentSession => _supabase.auth.currentSession;

  /// Stream de cambios de estado de autenticación.
  static get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // ─── Login ───────────────────────────────────────────────────────

  /// Inicia sesión con email y contraseña usando Supabase Auth.
  /// Retorna el rol del usuario si el login es exitoso, null si falla.
  static Future<String?> signIn(String usuario, String password) async {
    try {
      // Los usuarios se almacenan con email ficticio: usuario@avsingenieria.internal
      final email = '${usuario.toLowerCase()}@avsingenieria.internal';

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      // Obtener rol desde tabla perfiles
      final rolData = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', response.user!.id)
          .maybeSingle();

      return (rolData?['rol'] as String?) ?? 'USUARIO';
    } on AuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────

  /// Cierra la sesión actual en Supabase y limpia el almacenamiento local.
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SecureStorageService.clearAll();
    } catch (_) {}
  }

  // ─── Rol ─────────────────────────────────────────────────────────

  /// Obtiene el rol del usuario actualmente autenticado.
  static Future<String> getCurrentUserRole() async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return 'USUARIO';

      final data = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', uid)
          .maybeSingle();

      return (data?['rol'] as String?) ?? 'USUARIO';
    } catch (_) {
      return 'USUARIO';
    }
  }

  /// Obtiene el nombre de usuario del perfil actual.
  static Future<String?> getCurrentUsername() async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return null;

      final data = await _supabase
          .from('perfiles')
          .select('usuario')
          .eq('id', uid)
          .maybeSingle();

      return data?['usuario'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Restaurar sesión ────────────────────────────────────────────

  /// Verifica si hay una sesión activa válida al iniciar la app.
  /// Retorna [usuario, rol] si hay sesión, null si no.
  static Future<Map<String, String>?> restoreSession() async {
    try {
      final session = currentSession;
      if (session == null) return null;

      // Verificar que el token no haya expirado
      if (session.isExpired) {
        await signOut();
        return null;
      }

      final usuario = await getCurrentUsername();
      final rol = await getCurrentUserRole();

      if (usuario == null) return null;
      return {'usuario': usuario, 'rol': rol};
    } catch (_) {
      return null;
    }
  }
}
