import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación centralizado usando Supabase Auth.
/// Centraliza el acceso a la sesión actual y al perfil autenticado.
class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _internalDomain = 'avsingenieria.com';
  static String? _lastErrorMessage;

  // ─── Estado de sesión ────────────────────────────────────────────

  /// Usuario actualmente autenticado, null si no hay sesión.
  static User? get currentUser => _supabase.auth.currentUser;

  /// Sesión actual, null si no hay sesión activa.
  static Session? get currentSession => _supabase.auth.currentSession;

  /// Stream de cambios de estado de autenticación.
  static Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// ID del usuario autenticado actual.
  static String? get currentUserId => currentUser?.id;
  static String? get lastErrorMessage => _lastErrorMessage;

  // ─── Login ───────────────────────────────────────────────────────

  /// Inicia sesión con email y contraseña usando Supabase Auth.
  /// Retorna el rol del usuario si el login es exitoso, null si falla.
  static Future<String?> signIn(String usuario, String password) async {
    try {
      _lastErrorMessage = null;
      final email = _normalizeLoginEmail(usuario);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      // Verificar que exista un perfil valido. Si no tiene perfil,
      // es una cuenta huerfana o mal configurada -> denegar acceso.
      final rolData = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (rolData == null) {
        await _supabase.auth.signOut();
        _lastErrorMessage = 'Esta cuenta no tiene perfil asignado. Contacta al administrador.';
        return null;
      }

      return (rolData['rol'] as String?) ?? 'USUARIO';
    } on AuthException catch (error) {
      _lastErrorMessage = error.message;
      if (kDebugMode) {
        debugPrint('AuthService signIn AuthException: ${error.message}');
      }
      return null;
    } catch (error) {
      _lastErrorMessage = error.toString();
      if (kDebugMode) {
        debugPrint('AuthService signIn error: $error');
      }
      return null;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────

  /// Cierra la sesión actual en Supabase y limpia el almacenamiento local.
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
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

      final username = data?['usuario'] as String?;
      if (username != null && username.trim().isNotEmpty) {
        return username;
      }

      final email = currentUser?.email;
      if (email == null || email.trim().isEmpty) return null;

      return _usernameFromEmail(email);
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

  static String getFriendlyLastError() {
    final raw = (_lastErrorMessage ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Credenciales inválidas. Verifica el usuario/correo y la contraseña.';
    }
    if (lower.contains('email not confirmed')) {
      return 'La cuenta existe, pero el correo no está confirmado en Supabase.';
    }
    if (lower.contains('error querying schema')) {
      return 'Supabase Auth rechazó este usuario. Normalmente pasa cuando fue creado manualmente en auth.users de forma incompleta.';
    }
    if (lower.contains('database')) {
      return 'Hubo un problema interno con la autenticación o el perfil del usuario.';
    }

    return 'No se pudo iniciar sesión: $raw';
  }

  static String _normalizeLoginEmail(String usuarioOrEmail) {
    final raw = usuarioOrEmail.trim().toLowerCase();
    if (raw.contains('@')) return raw; // Si ya es un email, lo dejamos así
    return '$raw@$_internalDomain';   // Si es solo un usuario, le ponemos el dominio interno
  }

  static String _usernameFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final atIndex = normalized.indexOf('@');
    if (atIndex <= 0) return normalized;
    return normalized.substring(0, atIndex);
  }
}
