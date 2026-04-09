import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/perf_diagnostics.dart';

/// Servicio de autenticación centralizado.
/// El login se realiza contra la Edge Function `app-login`,
/// que valida la tabla `usuarios` y emite un token de sesión propio.
class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _defaultRole = 'USUARIO';
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _keyUserId = 'session_user_id';
  static const _keyUsername = 'session_username';
  static const _keyRole = 'session_role';
  static const _keyToken = 'session_token';
  static const _keyExpiresAt = 'session_expires_at';

  static String? _lastErrorMessage;
  static String? _currentUserId;
  static String? _currentUsername;
  static String? _currentRole;
  static String? _sessionToken;
  static DateTime? _sessionExpiresAt;

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ AuthService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  // ─── Estado de sesión ────────────────────────────────────────────

  static String? get currentUserId => _currentUserId;
  static String? get lastErrorMessage => _lastErrorMessage;

  /// Token de sesión para enviar a las Edge Functions como Bearer.
  static String? get sessionToken => _sessionToken;

  // ─── Login ───────────────────────────────────────────────────────

  /// Inicia sesión via la Edge Function `app-login`.
  /// Retorna el rol del usuario si el login es exitoso, null si falla.
  static Future<String?> signIn(String usuario, String password) async {
    try {
      _lastErrorMessage = null;
      final normalizedUser = usuario.trim().toLowerCase();

      final response = await _supabase.functions.invoke(
        'app-login',
        body: {'usuario': normalizedUser, 'password': password},
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['ok'] != true) {
        _lastErrorMessage = data?['message'] ?? 'Error desconocido en login';
        return null;
      }

      final token = data['token'] as String;
      final expiresAt = data['expiresAt'] as String;
      final user = data['user'] as Map<String, dynamic>;

      final userId = user['id'].toString();
      final username = user['usuario'] as String;
      final role = (user['rol'] as String).trim().toUpperCase();

      await _saveSession(
        userId: userId,
        username: username,
        role: role,
        token: token,
        expiresAt: expiresAt,
      );

      return role;
    } catch (error, stack) {
      _lastErrorMessage = error.toString();
      _logError('signIn', error, stack);
      return null;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────

  /// Revoca la sesión en backend (best effort) y limpia el storage local.
  static Future<void> signOut() async {
    // Best-effort backend logout
    if (_sessionToken != null) {
      try {
        await _supabase.functions.invoke(
          'app-logout',
          headers: {'Authorization': 'Bearer $_sessionToken'},
        );
      } catch (_) {}
    }

    _currentUserId = null;
    _currentUsername = null;
    _currentRole = null;
    _sessionToken = null;
    _sessionExpiresAt = null;

    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  // ─── Rol ─────────────────────────────────────────────────────────

  static Future<String> getCurrentUserRole() async {
    try {
      final session = await restoreSession();
      return session?['rol'] ?? _defaultRole;
    } catch (e, stack) {
      _logError('getCurrentUserRole', e, stack);
      return _defaultRole;
    }
  }

  static Future<String?> getCurrentUsername() async {
    try {
      final session = await restoreSession();
      return session?['usuario'];
    } catch (e, stack) {
      _logError('getCurrentUsername', e, stack);
      return null;
    }
  }

  // ─── Restaurar sesión ────────────────────────────────────────────

  /// Verifica si hay una sesión activa válida al iniciar la app.
  /// Retorna { id, usuario, rol } si hay sesión, null si no o si expiró.
  static Future<Map<String, String>?> restoreSession() async {
    final trace = PerfDiagnostics.startTrace('auth_restore_session');
    try {
      // In-memory cache hit
      if (_currentUserId != null &&
          _currentUsername != null &&
          _currentRole != null &&
          _sessionToken != null) {
        if (_sessionExpiresAt == null ||
            DateTime.now().isAfter(_sessionExpiresAt!)) {
          trace.mark('memory_session_expired');
          await signOut();
          trace.finish(data: {'source': 'memory', 'valid': false});
          return null;
        }
        trace.finish(data: {'source': 'memory', 'valid': true});
        return {
          'id': _currentUserId!,
          'usuario': _currentUsername!,
          'rol': _currentRole!,
        };
      }

      final userId = await _storage.read(key: _keyUserId);
      final usuario = await _storage.read(key: _keyUsername);
      final rol = await _storage.read(key: _keyRole);
      final token = await _storage.read(key: _keyToken);
      final expiresAtStr = await _storage.read(key: _keyExpiresAt);

      if (userId == null ||
          usuario == null ||
          rol == null ||
          token == null ||
          expiresAtStr == null) {
        trace.finish(data: {'source': 'storage', 'valid': false, 'reason': 'missing'});
        return null;
      }

      // Check token expiry locally
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        trace.mark('stored_session_expired');
        await signOut();
        trace.finish(data: {'source': 'storage', 'valid': false, 'reason': 'expired'});
        return null;
      }

      _currentUserId = userId;
      _currentUsername = usuario;
      _currentRole = rol;
      _sessionToken = token;
      _sessionExpiresAt = expiresAt;

      trace.finish(data: {'source': 'storage', 'valid': true});
      return {'id': userId, 'usuario': usuario, 'rol': rol};
    } catch (e, stack) {
      _logError('restoreSession', e, stack);
      trace.finish(data: {'source': 'error', 'valid': false, 'error': e.toString()});
      return null;
    }
  }

  static String getFriendlyLastError() {
    final raw = (_lastErrorMessage ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
    if (lower.contains('inválidas') || lower.contains('invalidas')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (lower.contains('inactivo')) {
      return 'El usuario está inactivo. Contacta al administrador.';
    }
    if (lower.contains('database') || lower.contains('base de datos')) {
      return 'Hubo un problema con la base de datos. Intenta más tarde.';
    }
    if (lower.contains('requested function was not found') ||
        (lower.contains('not_found') && lower.contains('functionexception')) ||
        lower.contains('status: 404')) {
      return 'El backend no tiene publicada la función de login. Debes desplegar las Edge Functions en el proyecto de Supabase que usa la app.';
    }

    return 'No se pudo iniciar sesión: $raw';
  }

  static Future<void> refreshLocalSession({
    required String userId,
    required String username,
    required String role,
  }) async {
    // Preserve token/expiry if already stored
    final token = _sessionToken ?? await _storage.read(key: _keyToken);
    final expiresAt = await _storage.read(key: _keyExpiresAt);
    if (token == null || expiresAt == null) return;

    await _saveSession(
      userId: userId,
      username: username.trim().toLowerCase(),
      role: role.trim().toUpperCase(),
      token: token,
      expiresAt: expiresAt,
    );
  }

  static Future<void> clearLocalSessionIfMatches(String userId) async {
    if (_currentUserId == userId) {
      await signOut();
    }
  }

  // ─── Private ─────────────────────────────────────────────────────

  static Future<void> _saveSession({
    required String userId,
    required String username,
    required String role,
    required String token,
    required String expiresAt,
  }) async {
    _currentUserId = userId;
    _currentUsername = username;
    _currentRole = role;
    _sessionToken = token;
    _sessionExpiresAt = DateTime.tryParse(expiresAt);

    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyExpiresAt, value: expiresAt);
  }
}
