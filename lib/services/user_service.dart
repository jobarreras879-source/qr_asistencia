import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'password_hash_service.dart';

/// Servicio simple para CRUD de usuarios sobre una tabla propia.
class UserService {
  static final _supabase = Supabase.instance.client;
  static const _tableName = 'usuarios';
  static const _validRoles = {'ADMIN', 'USUARIO'};

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ UserService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static String _normalizeRole(String rol) {
    final normalized = rol.trim().toUpperCase();
    return _validRoles.contains(normalized) ? normalized : 'USUARIO';
  }

  // ─── Lectura ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select('id, usuario, rol, activo')
          .order('usuario', ascending: true);

      return data
          .map(
            (e) => <String, dynamic>{
              'id': e['id'].toString(),
              'usuario': e['usuario']?.toString() ?? '',
              'rol': (e['rol'] as String?) ?? 'USUARIO',
              'activo': e['activo'] == true,
            },
          )
          .toList();
    } catch (e, stack) {
      _logError('getUsuarios', e, stack);
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  static Future<String?> crearUsuario(
    String usuario,
    String password,
    String rol,
  ) async {
    try {
      final normalizedUsername = PasswordHashService.normalizeUsername(usuario);
      if (normalizedUsername.isEmpty) return 'El usuario es obligatorio.';
      if (password.length < 6)
        return 'La contraseña debe tener mínimo 6 caracteres.';

      await _supabase.from(_tableName).insert({
        'usuario': normalizedUsername,
        'password_hash': PasswordHashService.hash(password),
        'rol': _normalizeRole(rol),
        'activo': true,
      });

      return null;
    } catch (e, stack) {
      _logError('crearUsuario', e, stack);
      final lower = e.toString().toLowerCase();
      if (lower.contains('duplicate') || lower.contains('unique')) {
        return 'Ese usuario ya existe.';
      }
      return 'No se pudo crear el usuario. Verifica la tabla usuarios.';
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  static Future<String?> editarUsuario(
    String id,
    String nuevoUsuario,
    String? nuevoPassword,
    String nuevoRol,
  ) async {
    try {
      final normalizedRole = _normalizeRole(nuevoRol);
      final normalizedUsername = PasswordHashService.normalizeUsername(
        nuevoUsuario,
      );
      if (normalizedUsername.isEmpty) return 'El usuario es obligatorio.';
      if (nuevoPassword != null &&
          nuevoPassword.isNotEmpty &&
          nuevoPassword.length < 6) {
        return 'La contraseña debe tener mínimo 6 caracteres.';
      }
      if (AuthService.currentUserId == id && normalizedRole != 'ADMIN') {
        return 'No puedes quitarte tu propio rol ADMIN mientras estás dentro.';
      }

      final payload = <String, dynamic>{
        'usuario': normalizedUsername,
        'rol': normalizedRole,
      };

      if (nuevoPassword != null && nuevoPassword.isNotEmpty) {
        payload['password_hash'] = PasswordHashService.hash(nuevoPassword);
      }

      await _supabase.from(_tableName).update(payload).eq('id', int.parse(id));

      if (AuthService.currentUserId == id) {
        await AuthService.refreshLocalSession(
          userId: id,
          username: normalizedUsername,
          role: payload['rol'] as String,
        );
      }

      return null;
    } catch (e, stack) {
      _logError('editarUsuario', e, stack);
      final lower = e.toString().toLowerCase();
      if (lower.contains('duplicate') || lower.contains('unique')) {
        return 'Ese usuario ya existe.';
      }
      return 'No se pudo actualizar el usuario.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<String?> eliminarUsuario(String id) async {
    try {
      if (AuthService.currentUserId == id) {
        return 'No puedes eliminar tu propio usuario mientras estás dentro.';
      }

      await _supabase.from(_tableName).delete().eq('id', int.parse(id));
      await AuthService.clearLocalSessionIfMatches(id);
      return null;
    } catch (e, stack) {
      _logError('eliminarUsuario', e, stack);
      return 'No se pudo eliminar el usuario.';
    }
  }
}
