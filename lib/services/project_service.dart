import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/perf_diagnostics.dart';

/// Servicio para CRUD de proyectos.
/// Se apoya en RLS para validar qué usuarios pueden modificar proyectos.
class ProjectService {
  static final _supabase = Supabase.instance.client;
  static const _cacheTtl = Duration(minutes: 2);
  static List<Map<String, dynamic>>? _cachedProjects;
  static DateTime? _cacheUpdatedAt;

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ ProjectService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  // ─── Lectura ─────────────────────────────────────────────────────

  /// Obtiene todos los proyectos ordenados por número.
  static Future<List<Map<String, dynamic>>> getProyectos({
    bool forceRefresh = false,
  }) async {
    final trace = PerfDiagnostics.startTrace(
      'project_service.getProyectos',
      context: {'forceRefresh': forceRefresh},
    );
    try {
      final cacheAge = _cacheUpdatedAt == null
          ? null
          : DateTime.now().difference(_cacheUpdatedAt!);
      final cacheValid = !forceRefresh &&
          _cachedProjects != null &&
          cacheAge != null &&
          cacheAge <= _cacheTtl;

      if (cacheValid) {
        final cachedProjects = _cachedProjects!;
        final cacheAgeMs = cacheAge.inMilliseconds;
        trace.finish(
          data: {
            'source': 'memory_cache',
            'count': cachedProjects.length,
            'cacheAgeMs': cacheAgeMs,
          },
        );
        return _cloneProjects(cachedProjects);
      }

      final data = await trace.measureAsync('supabase_select_proyecto', () {
        return _supabase
            .from('proyecto')
            .select()
            .order('"No."', ascending: true);
      });

      final projects = data
          .map(
            (e) => <String, dynamic>{
              'numero': e['No.'].toString(),
              'nombre': e['NameProyect']?.toString() ?? 'Sin nombre',
              'cliente': e['Client']?.toString() ?? '',
              'oc': e['OC']?.toString() ?? '',
            },
          )
          .toList();
      _cachedProjects = _cloneProjects(projects);
      _cacheUpdatedAt = DateTime.now();
      trace.finish(data: {'source': 'remote', 'count': projects.length});
      return _cloneProjects(projects);
    } catch (e, stack) {
      _logError('getProyectos', e, stack);
      trace.finish(data: {'error': e.toString()});
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
      _invalidateCache();
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
      _invalidateCache();
      return null;
    } catch (e, stack) {
      _logError('editarProyecto', e, stack);
      return 'No se pudo actualizar el proyecto. Intenta de nuevo.';
    }
  }

  // ─── Eliminación ─────────────────────────────────────────────────

  static Future<String?> eliminarProyecto(String numero) async {
    try {
      await _supabase.from('proyecto').delete().eq('"No."', numero);
      _invalidateCache();
      return null;
    } catch (e, stack) {
      _logError('eliminarProyecto', e, stack);
      return 'No se pudo eliminar el proyecto. Intenta de nuevo.';
    }
  }

  static void _invalidateCache() {
    _cachedProjects = null;
    _cacheUpdatedAt = null;
  }

  static List<Map<String, dynamic>> _cloneProjects(
    List<Map<String, dynamic>> projects,
  ) {
    return projects
        .map((project) => Map<String, dynamic>.from(project))
        .toList(growable: false);
  }
}
