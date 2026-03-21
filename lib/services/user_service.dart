import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de usuarios del sistema.
/// Opera sobre la tabla [perfiles] en Supabase, ligada a auth.users.
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

  /// Crea un nuevo usuario mediante signUp estándar.
  /// Si el Admin está loggeado, guardamos su sesión temporalmente
  /// porque signUp auto-loguea al nuevo usuario, y luego la restauramos.
  static Future<String?> crearUsuario(String usuario, String password, String rol) async {
    try {
      final input = usuario.trim().toLowerCase();
      final email = input.contains('@') ? input : '$input@avsingenieria.com';
      final normalizedUsername = input.contains('@') ? input.split('@')[0] : input;

      // 1. Guardar la sesión actual (Admin)
      final adminSession = _supabase.auth.currentSession;
      if (adminSession == null) return 'No hay sesión de admin activa.';

      // 2. Registrar al nuevo usuario
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'usuario': normalizedUsername.toUpperCase(),
          'rol': rol,
        },
      );

      // 3. Como signUp() cierra la sesión del admin y abre la del nuevo,
      // cerramos la cuenta nueva y restauramos la del Admin.
      await _supabase.auth.signOut();
      await _supabase.auth.setSession(
        adminSession.refreshToken ?? '',
      );

      // 4. El trigger de la base de datos se encargará de insertar en la tabla perfiles
      return null;
    } on AuthException catch (e) {
      _logError('crearUsuario auth_err', e);
      return 'Error de Auth: ${e.message}';
    } catch (e) {
      _logError('crearUsuario', e);
      return 'No se pudo crear el usuario. Intenta de nuevo.';
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  /// En el modo simple (sin Edge Functions), la edición de roles se 
  /// hace modificando la tabla `perfiles` directamente.
  /// La contraseña NO se puede cambiar por seguridad desde aquí a menos 
  /// que usemos una Edge Function.
  static Future<String?> editarUsuario(
    String id,
    String nuevoUsuario,
    String? nuevoPassword,
    String nuevoRol,
  ) async {
    try {
      final normalizedUsername = _normalizeUsername(nuevoUsuario);

      // Actualizar datos en la tabla perfiles (nombre y rol)
      await _supabase.from('perfiles').update({
        'usuario': normalizedUsername.toUpperCase(),
        'rol': nuevoRol,
      }).eq('id', id);

      // Al no tener Admin API o Edge Function, no podemos cambiar
      // contraseñas de otros usuarios fácilmente desde el cliente.
      if (nuevoPassword != null && nuevoPassword.isNotEmpty) {
        return 'Nota: El perfil se actualizó, pero el cambio de contraseña requiere Edge Functions.';
      }

      return null;
    } catch (e) {
      _logError('editarUsuario', e);
      return 'Error al actualizar el perfil en la base de datos.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  /// En el modo simple, eliminamos de `perfiles`. 
  /// El usuario quedará huerfano en `auth.users` pero inactivo en el sistema.
  static Future<String?> eliminarUsuario(String id) async {
    try {
      await _supabase.from('perfiles').delete().eq('id', id);
      return null; // Éxito
    } catch (e) {
      _logError('eliminarUsuario', e);
      return 'Error al eliminar el usuario del sistema.';
    }
  }

  static String _normalizeUsername(String usuarioOrEmail) {
    final trimmed = usuarioOrEmail.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0) return trimmed;
    return trimmed.substring(0, atIndex);
  }
}
