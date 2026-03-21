import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de usuarios del sistema.
/// Opera sobre la tabla [perfiles] en Supabase, ligada a auth.users.
class UserService {
  static final _supabase = Supabase.instance.client;

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
      print('ERROR getUsuarios: $e');
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  /// Crea un nuevo usuario en Supabase Auth y su perfil asociado.
  /// Solo ADMIN puede hacer esto (RLS en perfiles).
  static Future<String?> crearUsuario(String usuario, String password, String rol) async {
    try {
      final email = '${usuario.toLowerCase()}@avsingenieria.internal';

      await _supabase.rpc('admin_create_user', params: {
        'email': email,
        'password': password,
        'usuario': usuario,
        'rol': rol,
      });

      return null;
    } catch (e) {
      print('ERROR crearUsuario: $e');
      return e.toString();
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  /// Edita el usuario y rol de un perfil existente.
  /// Si se proporciona [nuevoPassword], también actualiza la contraseña en Auth.
  static Future<String?> editarUsuario(
    String id,
    String nuevoUsuario,
    String? nuevoPassword,
    String nuevoRol,
  ) async {
    try {
      await _supabase.rpc('admin_update_user', params: {
        'target_id': id,
        'new_usuario': nuevoUsuario,
        'new_password': nuevoPassword ?? '',
        'new_rol': nuevoRol,
      });

      return null;
    } catch (e) {
      print('ERROR editarUsuario: $e');
      return e.toString();
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  /// Elimina un usuario de Auth (el perfil se elimina en cascada).
  static Future<String?> eliminarUsuario(String id) async {
    try {
      await _supabase.rpc('admin_delete_user', params: {'target_id': id});
      return null;
    } catch (e) {
      print('ERROR eliminarUsuario: $e');
      return e.toString();
    }
  }
}
