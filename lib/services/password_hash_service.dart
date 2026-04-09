class PasswordHashService {
  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }
}
