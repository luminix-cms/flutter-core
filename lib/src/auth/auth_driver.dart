abstract class AuthDriver {
  bool get isAuthenticated;
  Map<String, dynamic>? get user;

  Future<void> attemptLogin(String email, String password);
  Future<void> logout();
}
