import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_drive_service.dart';
import 'auth_service.dart';

/// Servicio para registro y consulta de asistencia.
/// Separa el flujo de registros del resto de servicios.
class AttendanceService {
  static final _supabase = Supabase.instance.client;

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
      final fechaHoraString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

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
              infoSheets['id'], filaParaGoogleSheets);
        }
      }

      return '✅ $tipo registrado — Proyecto: $proyecto | ID: $id | $nombre';
    } catch (_) {
      return 'Ocurrió un error al registrar. Intenta de nuevo.';
    }
  }

  // ─── Historial ───────────────────────────────────────────────────

  /// Obtiene los registros asociados al usuario activo de la sesión local.
  static Future<List<Map<String, dynamic>>> getCurrentUserHistory({
    int limit = 50,
  }) async {
    try {
      final username = await AuthService.getCurrentUsername();
      if (username == null || username.isEmpty) return [];

      final data = await _supabase
          .from('registros')
          .select()
          .eq('usuario_logueado', username)
          .order('fecha_hora', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }
}
