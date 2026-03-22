import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHashService {
  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  static String hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
