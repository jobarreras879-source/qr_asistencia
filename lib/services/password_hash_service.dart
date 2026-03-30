import 'package:bcrypt/bcrypt.dart';

class PasswordHashService {
  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  static String hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verify(String password, String hashed) {
    return BCrypt.checkpw(password, hashed);
  }
}
