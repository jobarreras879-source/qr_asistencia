import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_drive_service.dart';
import 'auth_service.dart';
import '../utils/date_formatter.dart';
import '../utils/perf_diagnostics.dart';

/// Servicio para registro y consulta de asistencia.
/// Separa el flujo de registros del resto de servicios.
class AttendanceService {
  static final _supabase = Supabase.instance.client;

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ AttendanceService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  // ─── Sanitización ────────────────────────────────────────────────

  /// Valida y sanitiza los datos del QR antes de procesarlos.
  static String? _sanitizeQrInput(String raw) {
    if (raw.isEmpty || raw.length > 200) return null;

    // Eliminar caracteres de control
    String sanitized = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Prevenir inyección de fórmulas en Google Sheets
    if (sanitized.startsWith('=') ||
        sanitized.startsWith('+') ||
        sanitized.startsWith('-') ||
        sanitized.startsWith('@')) {
      sanitized = "'$sanitized";
    }

    return sanitized;
  }

  // ─── Registro ────────────────────────────────────────────────────

  /// Registra la asistencia de un empleado a partir del código QR.
  /// Formato esperado del QR: `ID/NOMBRE` (ej: 2011704024923/OCTAVIO NARVAEZ)
  static Future<String?> registrarAsistencia(
    String qr,
    String proyecto,
    String usuario,
    String tipo,
  ) async {
    try {
      final datosLimpios = _sanitizeQrInput(qr.trim());
      if (datosLimpios == null) {
        return '⚠️ Código QR inválido o demasiado largo.';
      }

      final separador = datosLimpios.lastIndexOf('/');

      String nombre = 'Desconocido';
      String id = datosLimpios;

      if (separador >= 0) {
        // Formato del QR: ID/NOMBRE
        id = datosLimpios.substring(0, separador).trim();
        nombre = datosLimpios.substring(separador + 1).trim();
      }

      if (id.isEmpty) {
        return '⚠️ El código QR no contiene un ID válido.';
      }

      final now = DateTime.now();
      final fechaHoraString = DateFormatter.toStorageString(now);

      final filaParaGoogleSheets = {
        'DPI': id,
        'nombre': nombre,
        'proyecto': proyecto,
        'tipo': tipo,
        'fecha_hora': fechaHoraString,
        'usuario_logueado': usuario,
      };

      await _supabase.from('registros').insert(filaParaGoogleSheets);

      // Sincronización automática con Google Sheets
      final autoSyncHabilitado = await GoogleDriveService.isAutoSyncEnabled();
      if (autoSyncHabilitado) {
        final infoSheets = await GoogleDriveService.getSheetsInfo();
        if (infoSheets != null && infoSheets['id'] != null) {
          await GoogleDriveService.appendAttendanceRow(
            infoSheets['id'],
            filaParaGoogleSheets,
          );
        }
      }

      return '✅ $tipo registrado — Proyecto: $proyecto | ID: $id | $nombre';
    } catch (e, stack) {
      _logError('registrarAsistencia', e, stack);
      return 'Ocurrió un error al registrar. Intenta de nuevo.';
    }
  }

  // ─── Historial ───────────────────────────────────────────────────

  /// Obtiene la cantidad de registros del día actual asociados al usuario.
  static Future<int> getTodayCount(String username) async {
    final trace = PerfDiagnostics.startTrace(
      'attendance_service.getTodayCount',
      context: {'usuario': username},
    );
    try {
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty) {
        trace.finish(data: {'count': 0, 'reason': 'empty_username'});
        return 0;
      }

      final role = await trace.measureAsync(
        'AuthService.getCurrentUserRole',
        AuthService.getCurrentUserRole,
      );

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var query = _supabase
          .from('registros')
          .count(CountOption.exact)
          .gte('fecha_hora', DateFormatter.toStorageString(startOfDay))
          .lt('fecha_hora', DateFormatter.toStorageString(endOfDay));

      if (role != 'ADMIN') {
        query = query.eq('usuario_logueado', normalizedUsername);
      }

      final count = await trace.measureAsync(
        'supabase_count_registros',
        () async => await query,
      );
      trace.finish(data: {'count': count, 'role': role});
      return count;
    } catch (e, stack) {
      _logError('getTodayCount', e, stack);
      trace.finish(data: {'count': 0, 'error': e.toString()});
      return 0;
    }
  }

  /// Obtiene los registros asociados al usuario activo de la sesión local.
  static Future<List<Map<String, dynamic>>> getCurrentUserHistory({
    int limit = 50,
  }) async {
    try {
      final username = await AuthService.getCurrentUsername();
      if (username == null || username.isEmpty) return [];

      final role = await AuthService.getCurrentUserRole();

      var query = _supabase
          .from('registros')
          .select();

      if (role != 'ADMIN') {
        query = query.eq('usuario_logueado', username);
      }

      final data = await query.order('fecha_hora', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e, stack) {
      _logError('getCurrentUserHistory', e, stack);
      return [];
    }
  }
}
