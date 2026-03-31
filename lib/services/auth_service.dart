import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'password_hash_service.dart';

/// Servicio de autenticación centralizado usando Supabase Auth.
/// Centraliza el acceso a la sesión actual y al perfil autenticado.
class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _tableName = 'usuarios';
  static const _defaultRole = 'USUARIO';
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'session_user_id';
  static const _keyUsername = 'session_username';
  static const _keyRole = 'session_role';

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ AuthService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static String? _lastErrorMessage;
  static String? _currentUserId;
  static String? _currentUsername;
  static String? _currentRole;

  // ─── Estado de sesión ────────────────────────────────────────────

  /// ID del usuario actualmente autenticado en la sesión local.
  static String? get currentUserId => _currentUserId;
  static String? get lastErrorMessage => _lastErrorMessage;

  // ─── Login ───────────────────────────────────────────────────────

  /// Inicia sesión consultando la tabla local de usuarios.
  /// Retorna el rol del usuario si el login es exitoso, null si falla.
  static Future<String?> signIn(String usuario, String password) async {
    try {
      _lastErrorMessage = null;
      final normalizedUser = PasswordHashService.normalizeUsername(usuario);
      final passwordHash = PasswordHashService.hash(password);

      final dataList = await _supabase
          .from(_tableName)
          .select('id, usuario, password_hash, rol, activo')
          .eq('usuario', normalizedUser);

      if (dataList.isEmpty) {
        _lastErrorMessage =
            'Sin registros. Usr: $normalizedUser. URL activa: ${AppConfig.supabaseUrl}';
        return null;
      }

      final data = dataList.first;

      if (data['activo'] != true) {
        _lastErrorMessage = 'El usuario está inactivo.';
        return null;
      }

      final storedHash = data['password_hash'] as String?;
      final role = (data['rol'] as String?)?.trim().toUpperCase();
      if (storedHash == null ||
          storedHash != passwordHash ||
          role == null ||
          role.isEmpty) {
        _lastErrorMessage =
            'Usuario o contraseña incorrectos. (HashDB: ${storedHash?.substring(0, 5)}, HashTyped: ${passwordHash.substring(0, 5)}, Rol: $role)';
        return null;
      }

      await _saveSession(
        userId: data['id'].toString(),
        username: normalizedUser,
        role: role,
      );

      return role;
    } catch (error, stack) {
      _lastErrorMessage = error.toString();
      _logError('signIn', error, stack);
      return null;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────

  /// Cierra la sesión actual en Supabase y limpia el almacenamiento local.
  static Future<void> signOut() async {
    try {
      _currentUserId = null;
      _currentUsername = null;
      _currentRole = null;
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyRole);
    } catch (e, stack) {
      _logError('signOut', e, stack);
    }
  }

  // ─── Rol ─────────────────────────────────────────────────────────

  /// Obtiene el rol del usuario actualmente autenticado.
  static Future<String> getCurrentUserRole() async {
    try {
      final session = await restoreSession();
      return session?['rol'] ?? _defaultRole;
    } catch (e, stack) {
      _logError('getCurrentUserRole', e, stack);
      return _defaultRole;
    }
  }

  /// Obtiene el nombre de usuario del perfil actual.
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
  /// Retorna [usuario, rol] si hay sesión, null si no.
  static Future<Map<String, String>?> restoreSession() async {
    try {
      if (_currentUserId != null &&
          _currentUsername != null &&
          _currentRole != null) {
        return {
          'id': _currentUserId!,
          'usuario': _currentUsername!,
          'rol': _currentRole!,
        };
      }

      final userId = await _storage.read(key: _keyUserId);
      final usuario = await _storage.read(key: _keyUsername);
      final rol = await _storage.read(key: _keyRole);

      if (userId == null || usuario == null || rol == null) {
        return null;
      }

      _currentUserId = userId;
      _currentUsername = usuario;
      _currentRole = rol;

      return {'id': userId, 'usuario': usuario, 'rol': rol};
    } catch (e, stack) {
      _logError('restoreSession', e, stack);
      return null;
    }
  }

  static String getFriendlyLastError() {
    final raw = (_lastErrorMessage ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
    if (lower.contains('incorrectos')) {
      return raw; // Return raw diagnostic info for debugging
    }
    if (lower.contains('database')) {
      return 'Hubo un problema interno con la autenticación o la tabla de usuarios.';
    }

    return 'No se pudo iniciar sesión: $raw';
  }

  static Future<void> refreshLocalSession({
    required String userId,
    required String username,
    required String role,
  }) async {
    await _saveSession(
      userId: userId,
      username: PasswordHashService.normalizeUsername(username),
      role: role.trim().toUpperCase(),
    );
  }

  static Future<void> clearLocalSessionIfMatches(String userId) async {
    if (_currentUserId == userId) {
      await signOut();
    }
  }

  static Future<void> _saveSession({
    required String userId,
    required String username,
    required String role,
  }) async {
    _currentUserId = userId;
    _currentUsername = username;
    _currentRole = role;

    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyRole, value: role);
  }
}
