import 'dart:async';

import '../../../../core/auth/models/account_role.dart';
import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/services/firebase_messaging_service.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl._({FirebaseAuthDataSource? dataSource}) : _dataSource = dataSource ?? FirebaseAuthDataSource();

  static final instance = AuthRepositoryImpl._();

  final FirebaseAuthDataSource _dataSource;

  @override
  UserAccount? get currentUser => _dataSource.currentUser == null ? null : UserAccount(
        id: _dataSource.currentUser!.id,
        name: _dataSource.currentUser!.name,
        email: _dataSource.currentUser!.email,
        role: _dataSource.currentUser!.role,
        organizationId: _dataSource.currentUser!.organizationId,
        clinicId: _dataSource.currentUser!.clinicId,
        doctorId: _dataSource.currentUser!.doctorId,
        patientId: _dataSource.currentUser!.patientId,
      );

  @override
  AccountRole? get currentRole => _dataSource.currentRole;

  @override
  bool get isAuthenticated => _dataSource.isAuthenticated;

  bool get isAwaitingEmailVerification =>
      _dataSource.isAwaitingEmailVerification;

  Future<void> restoreSession() async {
    await _dataSource.restoreSession();
    if (_dataSource.isAuthenticated) {
      FirebaseAuthRepository.instance.adoptSession(_dataSource.session);
    }
  }

  @override
  Future<AuthResult> login({required AccountRole role, required String email, required String password}) async {
    final result = await _dataSource.login(role: role, email: email, password: password);
    if (result.success) {
      FirebaseAuthRepository.instance.adoptSession(_dataSource.session);
      await FirebaseMessagingService.instance.initialize();
    }
    return AuthResult(success: result.success, message: result.message, user: result.user);
  }

  @override
  Future<AuthResult> activateInvitation({required AccountRole role, required String email, required String password}) async {
    final result = await _dataSource.activateInvitation(role: role, email: email, password: password);
    if (result.success) FirebaseAuthRepository.instance.adoptSession(_dataSource.session);
    return AuthResult(success: result.success, message: result.message, user: result.user);
  }

  @override
  Future<AuthResult> activatePatientAccount({required String email, required String password}) async {
    final result = await _dataSource.activatePatientAccount(email: email, password: password);
    if (result.success) {
      FirebaseAuthRepository.instance.adoptSession(_dataSource.session);
      await FirebaseMessagingService.instance.initialize();
    }
    return AuthResult(success: result.success, message: result.message, user: result.user);
  }

  Future<AuthResult> resumeActivation({
    required AccountRole role,
    required String email,
  }) async {
    final result = await _dataSource.resumeActivation(role: role, email: email);
    if (result.success) {
      FirebaseAuthRepository.instance.adoptSession(_dataSource.session);
      if (role == AccountRole.patient) {
        await FirebaseMessagingService.instance.initialize();
      }
    }
    return AuthResult(
      success: result.success,
      message: result.message,
      user: result.user,
    );
  }

  @override
  Future<void> logout() async {
    final uid = _dataSource.currentUser?.id;
    if (uid != null) {
      await FirebaseMessagingService.instance.removeCurrentTokenForUser(uid);
    }

    FirebaseMessagingService.instance.reset();
    _dataSource.logout();
    FirebaseAuthRepository.instance.logout();
  }
}
