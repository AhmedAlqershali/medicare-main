import '../models/account_role.dart';
import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';

abstract class AuthRepository {
  AuthSession get session;
  bool get isAuthenticated;
  AuthUser? get currentUser;
  AccountRole? get currentRole;
  Future<AuthResult> login({required AccountRole role, required String email, required String password});
  Future<AuthResult> activateInvitation({required AccountRole role, required String email, required String password});
  Future<AuthResult> activatePatientAccount({required String email, required String password});
  void logout();
}
