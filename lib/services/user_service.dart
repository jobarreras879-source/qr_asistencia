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
    } catch (_) {
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  /// Crea un nuevo usuario en Supabase Auth y su perfil asociado.
  /// Solo ADMIN puede hacer esto (RLS en perfiles).
  static Future<bool> crearUsuario(String usuario, String password, String rol) async {
    try {
      final email = '${usuario.toLowerCase()}@avsingenieria.internal';

      // Crear en Supabase Auth
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {'usuario': usuario.toUpperCase(), 'rol': rol},
        ),
      );

      if (response.user == null) return false;

      // El trigger en Supabase crea el perfil automáticamente.
      // Si no hay trigger, crearlo manualmente:
      await _supabase.from('perfiles').upsert({
        'id': response.user!.id,
        'usuario': usuario.toUpperCase(),
        'rol': rol,
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  /// Edita el usuario y rol de un perfil existente.
  /// Si se proporciona [nuevoPassword], también actualiza la contraseña en Auth.
  static Future<bool> editarUsuario(
    String id,
    String nuevoUsuario,
    String? nuevoPassword,
    String nuevoRol,
  ) async {
    try {
      // Actualizar perfil
      await _supabase
          .from('perfiles')
          .update({'usuario': nuevoUsuario.toUpperCase(), 'rol': nuevoRol})
          .eq('id', id);

      // Actualizar contraseña si se proporcionó
      if (nuevoPassword != null && nuevoPassword.isNotEmpty) {
        await _supabase.auth.admin.updateUserById(
          id,
          attributes: AdminUserAttributes(password: nuevoPassword),
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  /// Elimina un usuario de Auth (el perfil se elimina en cascada).
  static Future<bool> eliminarUsuario(String id) async {
    try {
      await _supabase.auth.admin.deleteUser(id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
