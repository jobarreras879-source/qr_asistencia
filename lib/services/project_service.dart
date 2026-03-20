import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para CRUD de proyectos.
/// Movido desde [ApiService] para separar responsabilidades.
class ProjectService {
  static final _supabase = Supabase.instance.client;

  // ─── Lectura ─────────────────────────────────────────────────────

  /// Obtiene todos los proyectos ordenados por número.
  static Future<List<Map<String, dynamic>>> getProyectos() async {
    try {
      final data = await _supabase
          .from('proyecto')
          .select()
          .order('"No."', ascending: true);

      return data.map((e) => <String, dynamic>{
        'numero': e['No.'].toString(),
        'nombre': e['NameProyect']?.toString() ?? 'Sin nombre',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  static Future<bool> crearProyecto(String numero, String nombre) async {
    try {
      await _supabase.from('proyecto').insert({
        'No.': numero,
        'NameProyect': nombre,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Edición ─────────────────────────────────────────────────────

  static Future<bool> editarProyecto(
    String oldNumero,
    String nuevoNumero,
    String nuevoNombre,
  ) async {
    try {
      await _supabase
          .from('proyecto')
          .update({'No.': nuevoNumero, 'NameProyect': nuevoNombre})
          .eq('No.', oldNumero);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<bool> eliminarProyecto(String numero) async {
    try {
      await _supabase.from('proyecto').delete().eq('No.', numero);
      return true;
    } catch (_) {
      return false;
    }
  }
}
