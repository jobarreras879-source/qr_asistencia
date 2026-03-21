import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de usuarios del sistema.
/// Opera mediante la Edge Function [admin-manage-user], que usa
/// la service role key para gestionar auth.users con privilegios de Admin.
class UserService {
  static final _supabase = Supabase.instance.client;

  static void _logError(String action, Object error) {
    if (kDebugMode) {
      debugPrint('UserService $action: $error');
    }
  }

  // ─── Lectura ─────────────────────────────────────────────────────

  /// Obtiene todos los usuarios con su rol.
  /// Solo accesible por ADMIN (garantizado por RLS).
  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select('id, usuario, rol')
          .order('usuario', ascending: true);

      return data.map((e) => <String, dynamic>{
        'id': e['id'],
        'usuario': e['usuario']?.toString() ?? '',
        'rol': (e['rol'] as String?) ?? 'USUARIO',
      }).toList();
    } catch (e) {
      _logError('getUsuarios', e);
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  /// Crea un nuevo usuario mediante Edge Function (Admin API).
  /// El caller debe ser ADMIN. La Edge Function verifica el rol.
  static Future<String?> crearUsuario(String usuario, String password, String rol) async {
    try {
      final input = usuario.trim();
      // Normalizamos: si ya tiene @, lo usamos tal cual; si no, le ponemos el dominio
      final normalizedUsername = input.contains('@') ? input.split('@')[0] : input;

      final res = await _supabase.functions.invoke('admin-manage-user', body: {
        'action': 'create',
        'usuario': normalizedUsername,
        'password': password,
        'rol': rol,
        // Si el admin puso un correo real, se lo pasamos para recovery
        'emailReal': input.contains('@') ? input : null,
      });

      if (res.status == 200 && res.data['ok'] == true) return null;
      return res.data['message'] ?? 'Error al crear usuario en el servidor.';
    } on FunctionException catch (e) {
      _logError('crearUsuario func_err', e);
      if (e.details != null && e.details is Map) {
        return (e.details as Map)['message']?.toString() ?? 'Acceso denegado o error interno.';
      }
      return 'Error del servidor: ${e.toString()}';
    } catch (e) {
      _logError('crearUsuario', e);
      return 'No se pudo crear el usuario. Verifica tu conexión.';
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  /// Edita un usuario mediante Edge Function (Admin API).
  static Future<String?> editarUsuario(
    String id,
    String nuevoUsuario,
    String? nuevoPassword,
    String nuevoRol,
  ) async {
    try {
      final input = nuevoUsuario.trim();
      final normalizedUsername = input.contains('@') ? input.split('@')[0] : input;

      final res = await _supabase.functions.invoke('admin-manage-user', body: {
        'action': 'update',
        'targetId': id,
        'usuario': normalizedUsername,
        'password': nuevoPassword ?? '',
        'rol': nuevoRol,
        'emailReal': input.contains('@') ? input : null,
      });

      if (res.status == 200 && res.data['ok'] == true) return null;
      return res.data['message'] ?? 'Error al actualizar usuario en el servidor.';
    } on FunctionException catch (e) {
      _logError('editarUsuario func_err', e);
      if (e.details != null && e.details is Map) {
        return (e.details as Map)['message']?.toString() ?? 'Acceso denegado o error interno.';
      }
      return 'Error del servidor: ${e.toString()}';
    } catch (e) {
      _logError('editarUsuario', e);
      return 'No se pudo actualizar el usuario. Intenta de nuevo.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  /// Elimina un usuario de Auth mediante Edge Function.
  /// Esto borra tanto auth.users como public.perfiles (via CASCADE o trigger).
  static Future<String?> eliminarUsuario(String id) async {
    try {
      final res = await _supabase.functions.invoke('admin-manage-user', body: {
        'action': 'delete',
        'targetId': id,
      });

      if (res.status == 200 && res.data['ok'] == true) return null;
      return res.data['message'] ?? 'Error al eliminar usuario en el servidor.';
    } on FunctionException catch (e) {
      _logError('eliminarUsuario func_err', e);
      if (e.details != null && e.details is Map) {
        return (e.details as Map)['message']?.toString() ?? 'Acceso denegado o error interno.';
      }
      return 'Error del servidor: ${e.toString()}';
    } catch (e) {
      _logError('eliminarUsuario', e);
      return 'No se pudo eliminar el usuario. Intenta de nuevo.';
    }
  }
}
