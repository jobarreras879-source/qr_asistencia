import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio centralizado de almacenamiento seguro.
/// Usa el Android Keystore / iOS Keychain para encriptar los datos sensibles.
/// Esto previene que un usuario con root/jailbreak pueda leer roles o credenciales.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // --- Claves ---
  static const _keyUsuario = 'secure_usuario_actual';
  static const _keyRol = 'secure_rol_actual';

  // --- Usuario ---
  static Future<void> saveUsuario(String usuario) async {
    await _storage.write(key: _keyUsuario, value: usuario);
  }

  static Future<String?> getUsuario() async {
    return await _storage.read(key: _keyUsuario);
  }

  // --- Rol ---
  static Future<void> saveRol(String rol) async {
    await _storage.write(key: _keyRol, value: rol);
  }

  static Future<String?> getRol() async {
    return await _storage.read(key: _keyRol);
  }

  // --- Logout (borrar todo) ---
  static Future<void> clearAll() async {
    await _storage.delete(key: _keyUsuario);
    await _storage.delete(key: _keyRol);
  }
}
