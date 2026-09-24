import 'auth_session.dart';

class AuthResult {
  const AuthResult({required this.success, required this.message, this.session});

  final bool success;
  final String message;
  final AuthSession? session;
}
