import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_drive_service.dart';

class ApiService {
  static final _supabase = Supabase.instance.client;

  /// Genera un hash SHA-256 de la contraseña para no enviar texto plano
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Login: returns the user's role if valid, null if invalid
  /// NOTA: Intenta primero con hash SHA-256. Si no encuentra coincidencia,
  /// intenta con texto plano (para contraseñas antiguas aún no migradas)
  /// y las migra automáticamente al formato seguro.
  static Future<String?> loginConRol(String usuario, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      // 1. Intentar con contraseña hasheada (segura)
      var data = await _supabase
          .from('usuarios')
          .select('id, rol')
          .eq('usuario', usuario)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (data != null) {
        return (data['rol'] as String?) ?? 'USUARIO';
      }

      // 2. Fallback: intentar con contraseña en texto plano (legacy)
      data = await _supabase
          .from('usuarios')
          .select('id, rol')
          .eq('usuario', usuario)
          .eq('password', password)
          .maybeSingle();

      if (data != null) {
        // Migrar automáticamente la contraseña a formato hash
        try {
          await _supabase.from('usuarios')
              .update({'password': hashedPassword})
              .eq('id', data['id']);
          print('✅ Contraseña migrada a formato seguro para: $usuario');
        } catch (_) {}
        return (data['rol'] as String?) ?? 'USUARIO';
      }

      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Legacy login kept for backwards compatibility
  static Future<bool> login(String usuario, String password) async {
    final rol = await loginConRol(usuario, password);
    return rol != null;
  }

  /// Get the role for a specific user
  static Future<String> getRolUsuario(String usuario) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select('rol')
          .eq('usuario', usuario)
          .maybeSingle();

      if (data == null) return 'USUARIO';
      return (data['rol'] as String?) ?? 'USUARIO';
    } catch (e) {
      print('Error al obtener rol: $e');
      return 'USUARIO';
    }
  }

  // --- CRUD DE USUARIOS ---

  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select('id, usuario, rol')
          .order('id', ascending: true);

      return data.map((e) => <String, dynamic>{
        'id': e['id'],
        'usuario': e['usuario']?.toString() ?? '',
        'rol': (e['rol'] as String?) ?? 'USUARIO',
      }).toList();
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  static Future<bool> crearUsuario(String usuario, String password, String rol) async {
    try {
      await _supabase.from('usuarios').insert({
        'usuario': usuario.toUpperCase(),
        'password': _hashPassword(password),
        'rol': rol,
      });
      return true;
    } catch (e) {
      print('Error al crear usuario: $e');
      return false;
    }
  }

  static Future<bool> editarUsuario(int id, String nuevoUsuario, String? nuevoPassword, String nuevoRol) async {
    try {
      final updateData = <String, dynamic>{
        'usuario': nuevoUsuario.toUpperCase(),
        'rol': nuevoRol,
      };
      // Only update password if a new one was provided
      if (nuevoPassword != null && nuevoPassword.isNotEmpty) {
        updateData['password'] = _hashPassword(nuevoPassword);
      }

      await _supabase.from('usuarios')
          .update(updateData)
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error al editar usuario: $e');
      return false;
    }
  }

  static Future<bool> eliminarUsuario(int id) async {
    try {
      await _supabase.from('usuarios')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getProyectos() async {
    try {
      // Intentar cargar la tabla 'proyecto' (en singular, como está en la DB)
      // Se utiliza '"No."' con comillas dobles para que Supabase no confunda el punto (.) con una propiedad anidada
      final data = await _supabase.from('proyecto').select().order('"No."', ascending: true);

      // Mapear los datos al formato que espera la vista ({'numero', 'nombre'})
      return data.map((e) => <String, dynamic>{
        'numero': e['No.'].toString(),
        'nombre': e['NameProyect']?.toString() ?? 'Sin nombre',
      }).toList();
    } catch (e, stacktrace) {
      print('====================================================');
      print('❌ ERROR CRÍTICO AL OBTENER PROYECTOS DE SUPABASE ❌');
      print('Error tipo: ${e.runtimeType}');
      print('Detalle: $e');
      print('Stacktrace: $stacktrace');
      print('====================================================');
      // Datos por defecto (fallback)
      return [
        {'numero': '101', 'nombre': 'Proyecto Alpha'},
        {'numero': '102', 'nombre': 'Torre Central'},
        {'numero': '103', 'nombre': 'Mantenimiento Zona Sur'},
      ];
    }
  }

  /// Valida y sanitiza los datos del QR antes de procesarlos
  static String? _sanitizeQrInput(String raw) {
    // Rechaza si está vacío o es demasiado largo (posible ataque)
    if (raw.isEmpty || raw.length > 200) return null;

    // Eliminar caracteres potencialmente peligrosos (inyección Excel / fórmulas)
    // Los caracteres =, +, -, @ al inicio de una celda pueden ejecutar fórmulas en Excel
    String sanitized = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ''); // Control chars

    // Prevenir inyección de fórmulas en Google Sheets
    if (sanitized.startsWith('=') || sanitized.startsWith('+') ||
        sanitized.startsWith('-') || sanitized.startsWith('@')) {
      sanitized = "'$sanitized"; // Prefijo de escape de texto en Sheets
    }

    return sanitized;
  }

  static Future<String?> registrarAsistencia(String qr, String proyecto, String usuario, String tipo) async {
    try {
      // Sanitizar el input del QR
      final datosLimpios = _sanitizeQrInput(qr.trim());
      if (datosLimpios == null) {
        return '⚠️ Código QR inválido o demasiado largo.';
      }

      final separador = datosLimpios.lastIndexOf('/');

      String nombre = "Desconocido";
      String id = datosLimpios;

      if (separador >= 0) {
        // Formato del QR: ID/NOMBRE (ej: 2011704024923/OCTAVIO RAMON NARVAEZ)
        id = datosLimpios.substring(0, separador).trim();
        nombre = datosLimpios.substring(separador + 1).trim();
      }

      // Validar que el ID no esté vacío después de limpiar
      if (id.isEmpty) {
        return '⚠️ El código QR no contiene un ID válido.';
      }

      final now = DateTime.now();
      final fechaHoraString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

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
          await GoogleDriveService.appendAttendanceRow(infoSheets['id'], filaParaGoogleSheets);
        }
      }

      return '✅ $tipo registrado — Proyecto: $proyecto | ID: $id | $nombre';
    } catch (e) {
      print('registrarAsistencia error: $e');
      return 'Error de servidor: $e';
    }
  }

  // --- NUEVOS MÉTODOS CRUD DE PROYECTO ---

  static Future<bool> crearProyecto(String numero, String nombre) async {
    try {
      await _supabase.from('proyecto').insert({
        'No.': numero,
        'NameProyect': nombre,
        'creado_en': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error al crear proyecto: $e');
      // Si falla porque no existe 'creado_en', intentamos sin esa columna
      try {
        await _supabase.from('proyecto').insert({
          'No.': numero,
          'NameProyect': nombre,
        });
        return true;
      } catch (e2) {
        print('Error fallback al crear proyecto: $e2');
        return false;
      }
    }
  }

  static Future<bool> editarProyecto(String oldNumero, String nuevoNumero, String nuevoNombre) async {
    try {
      await _supabase.from('proyecto')
          .update({
            'No.': nuevoNumero,
            'NameProyect': nuevoNombre,
          })
          .eq('No.', oldNumero);
      return true;
    } catch (e) {
      print('Error al editar proyecto: $e');
      return false;
    }
  }

  static Future<bool> eliminarProyecto(String numero) async {
    try {
      await _supabase.from('proyecto')
          .delete()
          .eq('No.', numero);
      return true;
    } catch (e) {
      print('Error al eliminar proyecto: $e');
      return false;
    }
  }
}
