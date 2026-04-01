import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'password_hash_service.dart';

/// Servicio de autenticación centralizado usando Supabase Auth.
/// Centraliza el acceso a la sesión actual y al perfil autenticado.
class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _usersTableName = 'usuarios';
  static const _companiesTableName = 'empresas';
  static const _subscriptionTableName = 'config_suscripcion';
  static const _defaultRole = 'USUARIO';
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'session_user_id';
  static const _keyUsername = 'session_username';
  static const _keyRole = 'session_role';
  static const _keyCompanyId = 'session_company_id';
  static const _keyCompanyCode = 'session_company_code';
  static const _keyCompanyName = 'session_company_name';

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ AuthService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static String? _lastErrorMessage;
  static String? _currentUserId;
  static String? _currentUsername;
  static String? _currentRole;
  static String? _currentCompanyId;
  static String? _currentCompanyCode;
  static String? _currentCompanyName;

  // ─── Estado de sesión ────────────────────────────────────────────

  /// ID del usuario actualmente autenticado en la sesión local.
  static String? get currentUserId => _currentUserId;
  static String? get currentCompanyId => _currentCompanyId;
  static String? get lastErrorMessage => _lastErrorMessage;

  // ─── Login ───────────────────────────────────────────────────────

  /// Inicia sesión consultando la tabla local de usuarios.
  /// Retorna el rol del usuario si el login es exitoso, null si falla.
  static Future<String?> signIn(
    String empresaCodigo,
    String usuario,
    String password,
  ) async {
    try {
      _lastErrorMessage = null;
      final normalizedCompanyCode = empresaCodigo.trim().toLowerCase();
      final normalizedUser = PasswordHashService.normalizeUsername(usuario);
      final passwordHash = PasswordHashService.hash(password);

      final companyList = await _supabase
          .from(_companiesTableName)
          .select('id, codigo, nombre, activa')
          .ilike('codigo', normalizedCompanyCode)
          .limit(1);

      if (companyList.isEmpty) {
        _lastErrorMessage =
            'No existe una empresa con ese código: $normalizedCompanyCode.';
        return null;
      }

      final company = companyList.first;
      if (company['activa'] != true) {
        _lastErrorMessage = 'La empresa está inactiva.';
        return null;
      }

      final companyId = company['id'].toString();
      final companyName = company['nombre']?.toString().trim();
      final companyCode = company['codigo']?.toString().trim().toUpperCase();

      final subscriptionList = await _supabase
          .from(_subscriptionTableName)
          .select('activa, fecha_expiracion')
          .eq('empresa_id', int.parse(companyId))
          .limit(1);

      if (subscriptionList.isNotEmpty) {
        final subscription = subscriptionList.first;
        if (subscription['activa'] != true) {
          _lastErrorMessage = 'La suscripción de la empresa está inactiva.';
          return null;
        }

        final expirationRaw = subscription['fecha_expiracion']?.toString();
        if (expirationRaw != null && expirationRaw.isNotEmpty) {
          final expirationDate = DateTime.tryParse(expirationRaw)?.toUtc();
          if (expirationDate != null &&
              expirationDate.isBefore(DateTime.now().toUtc())) {
            _lastErrorMessage = 'La suscripción de la empresa ha expirado.';
            return null;
          }
        }
      }

      final dataList = await _supabase
          .from(_usersTableName)
          .select('id, usuario, password_hash, rol, activo')
          .eq('empresa_id', int.parse(companyId))
          .eq('usuario', normalizedUser);

      if (dataList.isEmpty) {
        _lastErrorMessage = 'Usuario o contraseña incorrectos.';
        return null;
      }

      final data = dataList.first;

      if (data['activo'] != true) {
        _lastErrorMessage = 'El usuario está inactivo.';
        return null;
      }

      final storedHash = data['password_hash'] as String?;
      final role = (data['rol'] as String?)?.trim().toUpperCase();
      if (storedHash == null ||
          storedHash != passwordHash ||
          role == null ||
          role.isEmpty) {
        _lastErrorMessage = 'Usuario o contraseña incorrectos.';
        return null;
      }

      await _saveSession(
        userId: data['id'].toString(),
        username: normalizedUser,
        role: role,
        companyId: companyId,
        companyCode: companyCode ?? normalizedCompanyCode.toUpperCase(),
        companyName: companyName?.isNotEmpty == true ? companyName! : 'Empresa',
      );

      try {
        await _supabase
            .from(_usersTableName)
            .update({
              'ultimo_acceso_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', int.parse(data['id'].toString()));
      } catch (error, stack) {
        _logError('updateLastAccess', error, stack);
      }

      return role;
    } catch (error, stack) {
      _lastErrorMessage = error.toString();
      _logError('signIn', error, stack);
      return null;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────

  /// Cierra la sesión actual en Supabase y limpia el almacenamiento local.
  static Future<void> signOut() async {
    try {
      _currentUserId = null;
      _currentUsername = null;
      _currentRole = null;
      _currentCompanyId = null;
      _currentCompanyCode = null;
      _currentCompanyName = null;
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyRole);
      await _storage.delete(key: _keyCompanyId);
      await _storage.delete(key: _keyCompanyCode);
      await _storage.delete(key: _keyCompanyName);
    } catch (e, stack) {
      _logError('signOut', e, stack);
    }
  }

  // ─── Rol ─────────────────────────────────────────────────────────

  /// Obtiene el rol del usuario actualmente autenticado.
  static Future<String> getCurrentUserRole() async {
    try {
      final session = await restoreSession();
      return session?['rol'] ?? _defaultRole;
    } catch (e, stack) {
      _logError('getCurrentUserRole', e, stack);
      return _defaultRole;
    }
  }

  /// Obtiene el nombre de usuario del perfil actual.
  static Future<String?> getCurrentUsername() async {
    try {
      final session = await restoreSession();
      return session?['usuario'];
    } catch (e, stack) {
      _logError('getCurrentUsername', e, stack);
      return null;
    }
  }

  static Future<String?> getCurrentCompanyId() async {
    try {
      final session = await restoreSession();
      return session?['empresaId'];
    } catch (e, stack) {
      _logError('getCurrentCompanyId', e, stack);
      return null;
    }
  }

  static Future<String?> getCurrentCompanyCode() async {
    try {
      final session = await restoreSession();
      return session?['empresaCodigo'];
    } catch (e, stack) {
      _logError('getCurrentCompanyCode', e, stack);
      return null;
    }
  }

  static Future<String?> getCurrentCompanyName() async {
    try {
      final session = await restoreSession();
      return session?['empresaNombre'];
    } catch (e, stack) {
      _logError('getCurrentCompanyName', e, stack);
      return null;
    }
  }

  // ─── Restaurar sesión ────────────────────────────────────────────

  /// Verifica si hay una sesión activa válida al iniciar la app.
  /// Retorna [usuario, rol] si hay sesión, null si no.
  static Future<Map<String, String>?> restoreSession() async {
    try {
      if (_currentUserId != null &&
          _currentUsername != null &&
          _currentRole != null &&
          _currentCompanyId != null &&
          _currentCompanyCode != null &&
          _currentCompanyName != null) {
        return {
          'id': _currentUserId!,
          'usuario': _currentUsername!,
          'rol': _currentRole!,
          'empresaId': _currentCompanyId!,
          'empresaCodigo': _currentCompanyCode!,
          'empresaNombre': _currentCompanyName!,
        };
      }

      final userId = await _storage.read(key: _keyUserId);
      final usuario = await _storage.read(key: _keyUsername);
      final rol = await _storage.read(key: _keyRole);
      final empresaId = await _storage.read(key: _keyCompanyId);
      final empresaCodigo = await _storage.read(key: _keyCompanyCode);
      final empresaNombre = await _storage.read(key: _keyCompanyName);

      if (userId == null ||
          usuario == null ||
          rol == null ||
          empresaId == null ||
          empresaCodigo == null ||
          empresaNombre == null) {
        return null;
      }

      _currentUserId = userId;
      _currentUsername = usuario;
      _currentRole = rol;
      _currentCompanyId = empresaId;
      _currentCompanyCode = empresaCodigo;
      _currentCompanyName = empresaNombre;

      return {
        'id': userId,
        'usuario': usuario,
        'rol': rol,
        'empresaId': empresaId,
        'empresaCodigo': empresaCodigo,
        'empresaNombre': empresaNombre,
      };
    } catch (e, stack) {
      _logError('restoreSession', e, stack);
      return null;
    }
  }

  static String getFriendlyLastError() {
    final raw = (_lastErrorMessage ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
    if (lower.contains('no existe una empresa')) {
      return 'No encontramos una empresa con ese código. Verifícalo e intenta de nuevo.';
    }
    if (lower.contains('suscripción')) {
      return raw;
    }
    if (lower.contains('inactivo')) {
      return raw;
    }
    if (lower.contains('incorrectos')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('timeout')) {
      return 'No se pudo conectar al servidor. Revisa tu internet e intenta de nuevo.';
    }
    if (lower.contains('database') ||
        lower.contains('postgrestexception') ||
        lower.contains('schema cache')) {
      return 'Hubo un problema al validar el acceso. Intenta de nuevo en unos minutos.';
    }

    return 'No se pudo iniciar sesión. Verifica tus datos e inténtalo nuevamente.';
  }

  static Future<void> refreshLocalSession({
    required String userId,
    required String username,
    required String role,
  }) async {
    final session = await restoreSession();
    if (session == null) return;

    await _saveSession(
      userId: userId,
      username: PasswordHashService.normalizeUsername(username),
      role: role.trim().toUpperCase(),
      companyId: session['empresaId']!,
      companyCode: session['empresaCodigo']!,
      companyName: session['empresaNombre']!,
    );
  }

  static Future<void> clearLocalSessionIfMatches(String userId) async {
    if (_currentUserId == userId) {
      await signOut();
    }
  }

  static Future<void> _saveSession({
    required String userId,
    required String username,
    required String role,
    required String companyId,
    required String companyCode,
    required String companyName,
  }) async {
    _currentUserId = userId;
    _currentUsername = username;
    _currentRole = role;
    _currentCompanyId = companyId;
    _currentCompanyCode = companyCode;
    _currentCompanyName = companyName;

    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyCompanyId, value: companyId);
    await _storage.write(key: _keyCompanyCode, value: companyCode);
    await _storage.write(key: _keyCompanyName, value: companyName);
  }
}
