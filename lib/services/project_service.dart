import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de proyectos.
/// Se apoya en RLS para validar qué usuarios pueden modificar proyectos.
class ProjectService {
  static final _supabase = Supabase.instance.client;

  static void _logError(String action, Object error) {
    if (kDebugMode) {
      debugPrint('ProjectService $action: $error');
    }
  }

  // ─── Lectura ─────────────────────────────────────────────────────

  /// Obtiene todos los proyectos ordenados por número.
  static Future<List<Map<String, dynamic>>> getProyectos() async {
    try {
      final data = await _supabase
          .from('proyecto')
          .select()
          .order('"No."', ascending: true);

      return data
          .map(
            (e) => <String, dynamic>{
              'numero': e['No.'].toString(),
              'nombre': e['NameProyect']?.toString() ?? 'Sin nombre',
              'cliente': e['Client']?.toString() ?? '',
              'oc': e['OC']?.toString() ?? '',
            },
          )
          .toList();
    } catch (e) {
      _logError('getProyectos', e);
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  static Future<String?> crearProyecto(
    String numero,
    String nombre,
    String cliente,
    String oc,
  ) async {
    try {
      await _supabase.from('proyecto').insert({
        'No.': numero,
        'NameProyect': nombre,
        'Client': cliente.isEmpty ? null : cliente,
        'OC': oc.isEmpty ? null : oc,
      });
      return null;
    } catch (e) {
      _logError('crearProyecto', e);
      return 'No se pudo crear el proyecto. Verifica los datos o tus permisos.';
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  static Future<String?> editarProyecto(
    String oldNumero,
    String nuevoNumero,
    String nuevoNombre,
    String cliente,
    String oc,
  ) async {
    try {
      await _supabase
          .from('proyecto')
          .update({
            'No.': nuevoNumero,
            'NameProyect': nuevoNombre,
            'Client': cliente.isEmpty ? null : cliente,
            'OC': oc.isEmpty ? null : oc,
          })
          .eq('"No."', oldNumero);
      return null;
    } catch (e) {
      _logError('editarProyecto', e);
      return 'No se pudo actualizar el proyecto. Intenta de nuevo.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<String?> eliminarProyecto(String numero) async {
    try {
      await _supabase.from('proyecto').delete().eq('"No."', numero);
      return null;
    } catch (e) {
      _logError('eliminarProyecto', e);
      return 'No se pudo eliminar el proyecto. Intenta de nuevo.';
    }
  }
}
