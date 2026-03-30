import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepository {
  final SupabaseClient _supabase;

  ProjectRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProyectos() async {
    return await _supabase
        .from('proyecto')
        .select()
        .order('"No."', ascending: true);
  }

  Future<void> crearProyecto({
    required String numero,
    required String nombre,
    String? cliente,
    String? oc,
  }) async {
    await _supabase.from('proyecto').insert({
      'No.': numero,
      'NameProyect': nombre,
      'Client': cliente,
      'OC': oc,
    });
  }

  Future<void> editarProyecto({
    required String oldNumero,
    required String nuevoNumero,
    required String nuevoNombre,
    String? cliente,
    String? oc,
  }) async {
    await _supabase
        .from('proyecto')
        .update({
          'No.': nuevoNumero,
          'NameProyect': nuevoNombre,
          'Client': cliente,
          'OC': oc,
        })
        .eq('"No."', oldNumero);
  }

  Future<void> eliminarProyecto(String numero) async {
    await _supabase.from('proyecto').delete().eq('"No."', numero);
  }
}
