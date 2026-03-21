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
        'cliente': e['Client']?.toString() ?? '',
        'oc': e['OC']?.toString() ?? '',
      }).toList();
    } catch (e) {
      print('ERROR getProyectos: $e');
      return [];
    }
  }

  // ─── Creación ────────────────────────────────────────────────────

  static Future<String?> crearProyecto(String numero, String nombre, String cliente, String oc) async {
    try {
      await _supabase.from('proyecto').insert({
        'No.': numero,
        'NameProyect': nombre,
        'Client': cliente.isEmpty ? null : cliente,
        'OC': oc.isEmpty ? null : oc,
      });
      return null;
    } catch (e) {
      print('ERROR crearProyecto: $e');
      return e.toString();
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
      print('ERROR editarProyecto: $e');
      return e.toString();
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<String?> eliminarProyecto(String numero) async {
    try {
      await _supabase.from('proyecto').delete().eq('"No."', numero);
      return null;
    } catch (e) {
      print('ERROR eliminarProyecto: $e');
      return e.toString();
    }
  }
}
