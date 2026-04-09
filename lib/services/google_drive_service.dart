import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Maneja Google Sheets y la autenticación Google necesaria para ello.
///
/// ⚠️  Google Drive (carpeta + fotos) ya NO se gestiona aquí.
///     Toda la lógica de Drive vive en [DriveBackendService] vía Edge Functions,
///     usando las credenciales del admin almacenadas en el backend.
class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConfig.googleServerClientId : null,
    serverClientId: kIsWeb ? null : AppConfig.googleServerClientId,
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveMetadataReadonlyScope,
      sheets.SheetsApi.spreadsheetsScope,
    ],
  );

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ GoogleDriveService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static String _escapeDriveQueryValue(String value) {
    return value.replaceAll("'", "\\'");
  }

  /// Inicia sesión con Google (para Sheets).
  static Future<GoogleSignInAccount?> signIn({BuildContext? context}) async {
    try {
      if (currentUser != null) return currentUser;
      return await _googleSignIn.signIn();
    } catch (error, stack) {
      _logError('signIn', error, stack);
      if (context != null) {
        String message = 'No se pudo iniciar sesión con Google.';
        if (error.toString().contains('network_error')) {
          message = 'Error de red. Revisa tu conexión a internet.';
        } else if (error.toString().contains('access_denied')) {
          message = 'Acceso denegado. Se requieren permisos para continuar.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return null;
    }
  }

  /// Cierra sesión de Google.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      _logError('signOut', error);
    }
  }

  /// Silently checks for an active Google session (for Sheets background sync).
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      _logError('signInSilently', error);
      return null;
    }
  }

  // ============== MÉTODOS DE GOOGLE SHEETS ==============

  /// Crea una hoja de cálculo nueva con los encabezados.
  static Future<sheets.Spreadsheet?> createSpreadsheet(String title) async {
    try {
      final account = await signIn();
      if (account == null) return null;

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;

      final sheetsApi = sheets.SheetsApi(client);

      final sheet = sheets.Spreadsheet()
        ..properties = (sheets.SpreadsheetProperties()..title = title);

      final result = await sheetsApi.spreadsheets.create(sheet);

      if (result.spreadsheetId != null) {
        await _addHeaders(sheetsApi, result.spreadsheetId!);
      }

      return result;
    } catch (error) {
      _logError('createSpreadsheet', error);
      return null;
    }
  }

  /// Busca hojas de cálculo existentes en el Drive del usuario (para Sheets config).
  static Future<List<Map<String, String>>> searchSpreadsheets(
    String query,
  ) async {
    try {
      final account = await signInSilently() ?? await signIn();
      if (account == null) return [];

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return [];

      final driveApi = drive.DriveApi(client);

      String q =
          "(mimeType='application/vnd.google-apps.spreadsheet' or "
          "mimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or "
          "mimeType='application/vnd.ms-excel') and trashed=false";

      if (query.isNotEmpty) {
        final safeQuery = _escapeDriveQueryValue(query);
        q += " and name contains '$safeQuery'";
      }

      final fileList = await driveApi.files.list(
        q: q,
        spaces: 'drive',
        pageSize: 1000,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
        $fields: 'files(id, name, createdTime, webViewLink)',
        orderBy: 'name asc',
      );

      if (fileList.files == null) return [];

      return fileList.files!
          .map(
            (f) => {
              'id': f.id ?? '',
              'name': f.name ?? 'Documento sin título',
              'link': f.webViewLink ?? '',
            },
          )
          .toList();
    } catch (error) {
      _logError('searchSpreadsheets', error);
      return [];
    }
  }

  static Future<void> _addHeaders(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
  ) async {
    try {
      final valueRange = sheets.ValueRange()
        ..values = [
          [
            'ID',
            'Nombre',
            'Proyecto',
            'Fecha',
            'Hora',
            'Usuario',
            'Movimientos',
          ],
        ];

      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        'A1:G1',
        valueInputOption: 'USER_ENTERED',
      );
    } catch (error) {
      _logError('addHeaders', error);
    }
  }

  /// Agrega una fila de asistencia a Sheets.
  static Future<bool> appendAttendanceRow(
    String spreadsheetId,
    Map<String, dynamic> rowData,
  ) async {
    try {
      final account = await signInSilently() ?? await signIn();
      if (account == null) return false;

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return false;

      final sheetsApi = sheets.SheetsApi(client);

      final dpi = rowData['DPI'] ?? '';
      final nombre = rowData['nombre'] ?? '';
      final proyecto = rowData['proyecto'] ?? '';
      final tipo = rowData['tipo'] ?? '';
      final fechaHora = rowData['fecha_hora'] ?? '';
      final usuario = rowData['usuario_logueado'] ?? '';

      String fecha = '';
      String hora = '';
      if (fechaHora.contains(' ')) {
        final parts = fechaHora.split(' ');
        fecha = parts[0];
        hora = parts[1];
      } else {
        fecha = fechaHora;
      }

      final valueRange = sheets.ValueRange()
        ..values = [
          [dpi, nombre, proyecto, fecha, hora, usuario, tipo],
        ];

      await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        'A1:G',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      return true;
    } catch (error, stack) {
      _logError('appendAttendanceRow', error, stack);
      return false;
    }
  }

  // ============== PREFERENCIAS Y CONFIGURACIÓN GLOBAL (SHEETS) ==============

  static final _supabase = Supabase.instance.client;

  static Future<void> _ensureGlobalConfigExists() async {
    try {
      final data = await _supabase
          .from('configuracion_global')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (data == null) {
        await _supabase.from('configuracion_global').insert({'id': 1});
      }
    } catch (_) {}
  }

  static Future<String?> getSheetsId() async {
    try {
      final result = await _supabase
          .from('configuracion_global')
          .select('sheets_spreadsheet_id')
          .eq('id', 1)
          .maybeSingle();
      if (result != null && result['sheets_spreadsheet_id'] != null) {
        final id = result['sheets_spreadsheet_id'].toString();
        if (id.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('sheets_spreadsheet_id', id);
          return id;
        }
      }
    } catch (e) {
      _logError('getSheetsId_Supabase', e);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sheets_spreadsheet_id');
  }

  static Future<void> setSheetsInfo(String id, String name, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sheets_spreadsheet_id', id);
    await prefs.setString('sheets_spreadsheet_name', name);
    await prefs.setString('sheets_spreadsheet_url', url);
    await prefs.setBool('sheets_auto_sync', true);

    try {
      await _ensureGlobalConfigExists();
      await _supabase.from('configuracion_global').update({
        'sheets_spreadsheet_id': id,
        'sheets_spreadsheet_name': name,
        'sheets_spreadsheet_url': url,
        'sheets_auto_sync': true,
      }).eq('id', 1);
    } catch (e) {
      _logError('setSheetsInfo_Supabase', e);
    }
  }

  static Future<void> clearSheetsInfo({bool global = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sheets_spreadsheet_id');
    await prefs.remove('sheets_spreadsheet_name');
    await prefs.remove('sheets_spreadsheet_url');
    await prefs.remove('sheets_auto_sync');

    if (global) {
      try {
        await _supabase.from('configuracion_global').update({
          'sheets_spreadsheet_id': null,
          'sheets_spreadsheet_name': null,
          'sheets_spreadsheet_url': null,
          'sheets_auto_sync': false,
        }).eq('id', 1);
      } catch (e) {
        _logError('clearSheetsInfo_Supabase', e);
      }
    }
  }

  static Future<Map<String, dynamic>?> getSheetsInfo() async {
    try {
      final result = await _supabase
          .from('configuracion_global')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (result != null && result['sheets_spreadsheet_id'] != null) {
        final id = result['sheets_spreadsheet_id'].toString();
        if (id.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('sheets_spreadsheet_id', id);
          await prefs.setString(
            'sheets_spreadsheet_name',
            result['sheets_spreadsheet_name']?.toString() ?? 'Hoja',
          );
          await prefs.setString(
            'sheets_spreadsheet_url',
            result['sheets_spreadsheet_url']?.toString() ?? '',
          );

          final syncDb = result['sheets_auto_sync'];
          final autoSync = syncDb != null ? (syncDb as bool) : false;
          await prefs.setBool('sheets_auto_sync', autoSync);

          return {
            'id': id,
            'name':
                result['sheets_spreadsheet_name']?.toString() ??
                'Hoja de Asistencia',
            'url': result['sheets_spreadsheet_url']?.toString() ?? '',
            'autoSync': autoSync,
          };
        }
      }
    } catch (e) {
      _logError('getSheetsInfo_Supabase', e);
    }

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('sheets_spreadsheet_id');
    if (id == null || id.isEmpty) return null;

    return {
      'id': id,
      'name': prefs.getString('sheets_spreadsheet_name') ?? 'Hoja de Asistencia',
      'url': prefs.getString('sheets_spreadsheet_url') ?? '',
      'autoSync': prefs.getBool('sheets_auto_sync') ?? false,
    };
  }

  static Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sheets_auto_sync', value);

    try {
      await _ensureGlobalConfigExists();
      await _supabase.from('configuracion_global').update({
        'sheets_auto_sync': value,
      }).eq('id', 1);
    } catch (e) {
      _logError('setAutoSync_Supabase', e);
    }
  }

  static Future<bool> isAutoSyncEnabled() async {
    try {
      final result = await _supabase
          .from('configuracion_global')
          .select('sheets_auto_sync')
          .eq('id', 1)
          .maybeSingle();
      if (result != null && result['sheets_auto_sync'] != null) {
        final syncMode = result['sheets_auto_sync'] as bool;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sheets_auto_sync', syncMode);
        return syncMode;
      }
    } catch (e) {
      _logError('isAutoSyncEnabled_Supabase', e);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sheets_auto_sync') ?? false;
  }
}
