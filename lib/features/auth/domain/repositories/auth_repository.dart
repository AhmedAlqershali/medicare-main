import '../../../../core/auth/models/account_role.dart';
import '../../domain/entities/user_account.dart';

abstract class AuthRepository {
  UserAccount? get currentUser;
  AccountRole? get currentRole;
  bool get isAuthenticated;

  Future<AuthResult> login({required AccountRole role, required String email, required String password});
  Future<AuthResult> activateInvitation({required AccountRole role, required String email, required String password});
  Future<AuthResult> activatePatientAccount({required String email, required String password});
  void logout();
}

class AuthResult {
  const AuthResult({required this.success, required this.message, this.user});

  final bool success;
  final String message;
  final UserAccount? user;
}
