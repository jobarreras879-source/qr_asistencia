import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Servicio para CRUD de proyectos.
/// Se apoya en RLS para validar qué usuarios pueden modificar proyectos.
class ProjectService {
  static final _supabase = Supabase.instance.client;

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ ProjectService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static Future<int?> _getEmpresaId() async {
    final empresaId = await AuthService.getCurrentCompanyId();
    if (empresaId == null || empresaId.isEmpty) {
      return null;
    }
    return int.tryParse(empresaId);
  }

  // ─── Lectura ─────────────────────────────────────────────────────

  /// Obtiene todos los proyectos ordenados por número.
  static Future<List<Map<String, dynamic>>> getProyectos() async {
    try {
      final empresaId = await _getEmpresaId();
      if (empresaId == null) return [];

      final data = await _supabase
          .from('proyecto')
          .select()
          .eq('empresa_id', empresaId)
          .eq('activo', true)
          .order('"No."', ascending: true);

      return data
          .map(
            (e) => <String, dynamic>{
              'id': e['id'].toString(),
              'numero': e['No.'].toString(),
              'nombre': e['NameProyect']?.toString() ?? 'Sin nombre',
              'cliente': '',
              'oc': '',
            },
          )
          .toList();
    } catch (e, stack) {
      _logError('getProyectos', e, stack);
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  static Future<String?> crearProyecto(String numero, String nombre) async {
    try {
      final empresaId = await _getEmpresaId();
      if (empresaId == null) {
        return 'No se encontró la empresa activa de la sesión.';
      }

      await _supabase.from('proyecto').insert({
        'empresa_id': empresaId,
        'No.': numero,
        'NameProyect': nombre,
      });
      return null;
    } catch (e, stack) {
      _logError('crearProyecto', e, stack);
      return 'No se pudo crear el proyecto. Verifica los datos o tus permisos.';
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  static Future<String?> editarProyecto(
    String oldNumero,
    String nuevoNumero,
    String nuevoNombre,
  ) async {
    try {
      final empresaId = await _getEmpresaId();
      if (empresaId == null) {
        return 'No se encontró la empresa activa de la sesión.';
      }

      await _supabase
          .from('proyecto')
          .update({
            'No.': nuevoNumero,
            'NameProyect': nuevoNombre,
          })
          .eq('empresa_id', empresaId)
          .eq('"No."', oldNumero);
      return null;
    } catch (e, stack) {
      _logError('editarProyecto', e, stack);
      return 'No se pudo actualizar el proyecto. Intenta de nuevo.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<String?> eliminarProyecto(String numero) async {
    try {
      final empresaId = await _getEmpresaId();
      if (empresaId == null) {
        return 'No se encontró la empresa activa de la sesión.';
      }

      await _supabase
          .from('proyecto')
          .delete()
          .eq('empresa_id', empresaId)
          .eq('"No."', numero);
      return null;
    } catch (e, stack) {
      _logError('eliminarProyecto', e, stack);
      return 'No se pudo eliminar el proyecto. Intenta de nuevo.';
    }
  }
}
