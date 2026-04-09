import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Exceptions thrown by DriveBackendService
class DriveBackendException implements Exception {
  final String message;
  const DriveBackendException(this.message);
  @override
  String toString() => 'DriveBackendException: $message';
}

/// Service that communicates with the backend Edge Functions for
/// all Google Drive operations. No client-side Google session is needed.
class DriveBackendService {
  static final _supabase = Supabase.instance.client;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, String> get _headers {
    final token = AuthService.sessionToken;
    if (token == null) throw const DriveBackendException('No hay sesión activa');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        functionName,
        body: body,
        headers: _headers,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['ok'] == false) {
        throw DriveBackendException(data['message'] ?? 'Error desconocido');
      }
      return data as Map<String, dynamic>;
    } on DriveBackendException {
      rethrow;
    } catch (e) {
      throw DriveBackendException(e.toString());
    }
  }

  static Future<Map<String, dynamic>> _get(String functionName) async {
    try {
      final response = await _supabase.functions.invoke(
        functionName,
        method: HttpMethod.get,
        headers: _headers,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['ok'] == false) {
        throw DriveBackendException(data['message'] ?? 'Error desconocido');
      }
      return data as Map<String, dynamic>;
    } on DriveBackendException {
      rethrow;
    } catch (e) {
      throw DriveBackendException(e.toString());
    }
  }

  // ── Drive Status ───────────────────────────────────────────────────────────

  /// Returns { linked, email, folderId, folderName, linkedAt }
  static Future<Map<String, dynamic>> getDriveStatus() async {
    return _get('drive-admin-status');
  }

  // ── Admin — Link/Unlink ────────────────────────────────────────────────────

  /// Links the admin's Google account using a server auth code.
  /// [serverAuthCode] is obtained from GoogleSignIn after requesting
  /// offline access + forceCodeForRefreshToken.
  static Future<Map<String, dynamic>> linkDrive(String serverAuthCode) async {
    return _post('drive-admin-link', {'serverAuthCode': serverAuthCode});
  }

  /// Removes all Drive credentials from the backend.
  static Future<bool> unlinkDrive() async {
    final result = await _post('drive-admin-unlink', {});
    return result['ok'] == true;
  }

  // ── Admin — Folders ────────────────────────────────────────────────────────

  /// Lists folders visible to the admin's Drive account.
  /// Returns list of { id, name }
  static Future<List<Map<String, String>>> listFolders() async {
    final result = await _get('drive-admin-list-folders');
    final raw = result['folders'] as List<dynamic>? ?? [];
    return raw
        .map((f) => {
              'id': (f['id'] as String?) ?? '',
              'name': (f['name'] as String?) ?? '',
            })
        .where((f) => f['id']!.isNotEmpty)
        .toList();
  }

  /// Creates a new folder in Drive and returns its { id, name }.
  static Future<Map<String, String>> createFolder(String name) async {
    final result = await _post('drive-admin-create-folder', {'name': name});
    final folder = result['folder'] as Map<String, dynamic>;
    return {
      'id': folder['id'] as String,
      'name': folder['name'] as String,
    };
  }

  /// Persists the selected folder to configuracion_global.
  static Future<bool> setFolder(String folderId, String folderName) async {
    final result = await _post('drive-admin-set-folder', {
      'folderId': folderId,
      'folderName': folderName,
    });
    return result['ok'] == true;
  }

  // ── Photo Upload ───────────────────────────────────────────────────────────

  /// Uploads a photo to the admin's configured Drive folder.
  /// [imageFile] is the local photo file.
  /// [nombreBase] is used as part of the filename (employee name / QR code).
  /// [usuario], [proyecto], [fechaHora] are metadata for the filename.
  ///
  /// Returns { ok, fileId, fileName, folderName }
  static Future<Map<String, dynamic>> uploadPhoto({
    required File imageFile,
    required String nombreBase,
    required String usuario,
    required String proyecto,
    required String fechaHora,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(bytes);

    return _post('drive-photo-upload', {
      'nombreBase': nombreBase,
      'imageBase64': imageBase64,
      'usuario': usuario,
      'proyecto': proyecto,
      'fechaHora': fechaHora,
    });
  }

  /// Uploads from raw bytes (alternative entry point).
  static Future<Map<String, dynamic>> uploadPhotoBytes({
    required Uint8List imageBytes,
    required String nombreBase,
    required String usuario,
    required String proyecto,
    required String fechaHora,
  }) async {
    final imageBase64 = base64Encode(imageBytes);

    return _post('drive-photo-upload', {
      'nombreBase': nombreBase,
      'imageBase64': imageBase64,
      'usuario': usuario,
      'proyecto': proyecto,
      'fechaHora': fechaHora,
    });
  }
}
