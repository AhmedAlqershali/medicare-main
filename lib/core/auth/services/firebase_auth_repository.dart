import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/account_role.dart';
import '../models/account_status.dart';
import '../models/auth_result.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../models/doctor.dart';
import '../models/invitation.dart';
import '../models/invitation_status.dart';
import '../models/organization.dart';
import '../models/patient.dart';
import '../repositories/auth_repository.dart';
import '../../firestore/repositories/firestore_doctor_repository.dart';
import '../../firestore/repositories/firestore_invitation_repository.dart';
import '../../firestore/repositories/firestore_organization_repository.dart';
import '../../firestore/repositories/firestore_patient_repository.dart';
import '../../firestore/repositories/firestore_user_profile_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository._();

  static final instance = FirebaseAuthRepository._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreDoctorRepository _firestoreDoctorRepository = FirestoreDoctorRepository.instance;
  final FirestoreOrganizationRepository _firestoreOrganizationRepository = FirestoreOrganizationRepository.instance;
  final FirestorePatientRepository _firestorePatientRepository = FirestorePatientRepository.instance;
  final FirestoreInvitationRepository _firestoreInvitationRepository = FirestoreInvitationRepository.instance;
  final FirestoreUserProfileRepository _firestoreUserProfileRepository = FirestoreUserProfileRepository();
  AuthSession _session = const AuthSession.signedOut();

  @override
  AuthSession get session => _session;

  @override
  bool get isAuthenticated => _session.isAuthenticated;

  @override
  AuthUser? get currentUser => _session.currentUser;

  @override
  AccountRole? get currentRole => _session.currentRole;

  void adoptSession(AuthSession session) {
    _session = session;
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'user-not-found':
        return 'لا يوجد حساب مسجّل بهذا البريد.';
      case 'wrong-password':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة. استخدم ٦ أحرف أو أكثر.';
      case 'too-many-requests':
        return 'محاولات تسجيل الدخول كثيرة. حاول لاحقاً.';
      case 'network-request-failed':
        return 'فشل الاتصال. تأكد من اتصال الإنترنت.';
      default:
        return exception.message ?? 'حدث خطأ في المصادقة.';
    }
  }

  Future<User?> _createFirebaseAccountIfNeeded({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return credential.user;
    } on FirebaseAuthException catch (exception) {
      if (exception.code == 'email-already-in-use') {
        try {
          final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password);
          return credential.user;
        } on FirebaseAuthException catch (signInException) {
          throw FirebaseAuthException(code: signInException.code, message: _mapFirebaseAuthError(signInException));
        }
      }
      throw FirebaseAuthException(code: exception.code, message: _mapFirebaseAuthError(exception));
    }
  }

  Future<({User? user, bool created})> _createPatientFirebaseAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (user: credential.user, created: true);
    } on FirebaseAuthException catch (exception) {
      if (exception.code != 'email-already-in-use') rethrow;
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (user: credential.user, created: false);
    }
  }

    AuthUser _authUserForPatient(Patient patient, String firebaseUid) => AuthUser(
      id: firebaseUid,
        name: patient.name,
        email: patient.email,
        role: AccountRole.patient,
        organizationId: patient.organizationId,
        doctorId: patient.doctorId,
        patientId: patient.id,
      );

    AuthUser _authUserForDoctor(Doctor doctor, String firebaseUid) => AuthUser(
      id: firebaseUid,
        name: doctor.name,
        email: doctor.email,
        role: AccountRole.doctor,
        organizationId: doctor.organizationId,
        doctorId: doctor.id,
      );

    AuthUser _authUserForOrganization(Organization organization, String firebaseUid) => AuthUser(
      id: firebaseUid,
        name: organization.name,
        email: organization.email,
        role: AccountRole.organization,
        organizationId: organization.id,
      );

  @override
  Future<AuthResult> login({required AccountRole role, required String email, required String password}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult(success: false, message: 'أدخل البريد الإلكتروني وكلمة المرور.');
    }

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
      switch (role) {
        case AccountRole.organization:
          final organizationRecord = await _firestoreOrganizationRepository.fetchOrganizationByEmail(normalizedEmail);
          if (organizationRecord == null) {
            return const AuthResult(success: false, message: 'لا يوجد حساب مؤسسة مطابق لهذا البريد.');
          }
          if (organizationRecord.firebaseUid != null && organizationRecord.firebaseUid != userCredential.user?.uid) {
            return const AuthResult(success: false, message: 'هذه المؤسسة مرتبطة بالفعل بحساب Firebase مختلف ولا يمكن استخدامها هنا.');
          }
          await _firestoreOrganizationRepository.linkFirebaseUid(
            organizationId: organizationRecord.id,
            firebaseUid: userCredential.user!.uid,
            email: normalizedEmail,
          );
          await _firestoreUserProfileRepository.linkOrganizationProfile(
            uid: userCredential.user!.uid,
            email: normalizedEmail,
            organizationId: organizationRecord.id,
          );
          _session = AuthSession(
            isAuthenticated: true,
              currentUser: _authUserForOrganization(organizationRecord, userCredential.user!.uid),
            currentRole: AccountRole.organization,
            organizationId: organizationRecord.id,
          );
          return AuthResult(success: true, message: 'تم تسجيل الدخول بنجاح.', session: _session);
        case AccountRole.doctor:
          final profile = await _firestoreUserProfileRepository.fetchUserProfile(userCredential.user!.uid);
            final doctorRecord = profile?.doctorId != null && profile?.organizationId != null
              ? await _firestoreDoctorRepository.fetchDoctorByIdForOrganization(profile!.organizationId!, profile.doctorId!)
              : null;
          if (doctorRecord == null) {
            return const AuthResult(success: false, message: 'لا يوجد سجل طبيب مطابق لهذا البريد الإلكتروني.');
          }
          if (doctorRecord.firebaseUid != null && doctorRecord.firebaseUid != userCredential.user?.uid) {
            return const AuthResult(success: false, message: 'هذا الطبيب مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.');
          }
          await _firestoreDoctorRepository.linkFirebaseUidForOrganization(
            organizationId: doctorRecord.organizationId,
            doctorId: doctorRecord.id,
            firebaseUid: userCredential.user!.uid,
            email: normalizedEmail,
          );
          await _firestoreUserProfileRepository.linkDoctorProfile(
            uid: userCredential.user!.uid,
            email: normalizedEmail,
            doctorId: doctorRecord.id,
            organizationId: doctorRecord.organizationId,
          );
          _session = AuthSession(
            isAuthenticated: true,
              currentUser: _authUserForDoctor(doctorRecord, userCredential.user!.uid),
            currentRole: AccountRole.doctor,
            organizationId: doctorRecord.organizationId,
            doctorId: doctorRecord.id,
          );
          return AuthResult(success: true, message: 'تم تسجيل الدخول بنجاح.', session: _session);
        case AccountRole.patient:
            final profile = await _firestoreUserProfileRepository.fetchUserProfile(userCredential.user!.uid);
            final patientRecord = profile?.patientId != null && profile?.organizationId != null
              ? await _firestorePatientRepository.fetchPatientById(profile!.patientId!, organizationId: profile.organizationId)
              : null;
          if (patientRecord == null) {
            return const AuthResult(success: false, message: 'لا يوجد سجل مريض مطابق لهذا البريد الإلكتروني.');
          }
          if (!patientRecord.accountActivated) {
            return const AuthResult(success: false, message: 'هذا الحساب غير مفعّل بعد. استخدم تفعيل حساب المريض أولاً.');
          }
          if (patientRecord.firebaseUid != null && patientRecord.firebaseUid != userCredential.user?.uid) {
            return const AuthResult(success: false, message: 'هذا المريض مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.');
          }
          await _firestorePatientRepository.activatePatient(
            patientId: patientRecord.id,
            organizationId: patientRecord.organizationId,
            firebaseUid: userCredential.user!.uid,
            email: normalizedEmail,
          );
          await _firestoreUserProfileRepository.linkPatientProfile(
            uid: userCredential.user!.uid,
            email: normalizedEmail,
            patientId: patientRecord.id,
            doctorId: patientRecord.doctorId,
            organizationId: patientRecord.organizationId,
          );
          _session = AuthSession(
            isAuthenticated: true,
              currentUser: _authUserForPatient(patientRecord, userCredential.user!.uid),
            currentRole: AccountRole.patient,
            organizationId: patientRecord.organizationId,
            doctorId: patientRecord.doctorId,
            patientId: patientRecord.id,
          );
          return AuthResult(success: true, message: 'تم تسجيل الدخول بنجاح.', session: _session);
      }
    } on FirebaseAuthException catch (exception) {
      return AuthResult(success: false, message: _mapFirebaseAuthError(exception));
    } on StateError catch (error) {
      return AuthResult(success: false, message: error.message);
    }
  }

  Future<Invitation?> _findPendingInvitationForEmail({required AccountRole role, required String email}) async {
    return _firestoreInvitationRepository.fetchPendingInvitationForEmailAndRole(email: email, role: role);
  }

  @override
  Future<AuthResult> activateInvitation({required AccountRole role, required String email, required String password}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return const AuthResult(success: false, message: 'أدخل البريد الإلكتروني المدعو.');
    if (password.length < 6) return const AuthResult(success: false, message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.');

    try {
      final userCredential = await _createFirebaseAccountIfNeeded(email: normalizedEmail, password: password);
      if (userCredential == null) {
        return const AuthResult(success: false, message: 'تعذر إنشاء حساب المستخدم في Firebase.');
      }

      final invitation = await _findPendingInvitationForEmail(role: role, email: normalizedEmail);
      if (invitation == null) {
        return const AuthResult(success: false, message: 'لم نجد دعوة بهذا البريد الإلكتروني.');
      }

      if (role == AccountRole.doctor) {
          final doctorRecord = invitation.doctorId == null
            ? null
            : await _firestoreDoctorRepository.fetchDoctorByIdForOrganization(invitation.organizationId, invitation.doctorId!);
        if (doctorRecord == null) {
          return const AuthResult(success: false, message: 'لا يوجد سجل طبيب مطابق لهذا البريد الإلكتروني في العلاقة الموثوقة.');
        }
        if (doctorRecord.organizationId != invitation.organizationId) {
          return const AuthResult(success: false, message: 'لا يملك هذا الطبيب صلاحية تسجيل الدخول في هذه المؤسسة.');
        }
        if (doctorRecord.firebaseUid != null && doctorRecord.firebaseUid != userCredential.uid) {
          return const AuthResult(success: false, message: 'هذا الطبيب مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.');
        }
        await _firestoreDoctorRepository.linkFirebaseUidForOrganization(organizationId: invitation.organizationId, doctorId: doctorRecord.id, firebaseUid: userCredential.uid, email: normalizedEmail);
        await _firestoreUserProfileRepository.linkDoctorProfile(uid: userCredential.uid, email: normalizedEmail, doctorId: doctorRecord.id, organizationId: doctorRecord.organizationId);
      } else {
        await _firestoreUserProfileRepository.createOrUpdateUserProfile(
          uid: userCredential.uid,
          email: normalizedEmail,
          role: role,
          organizationId: invitation.organizationId,
        );
      }

      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.accepted,
        userId: userCredential.uid,
        acceptedAt: DateTime.now(),
      );
      await _firestoreInvitationRepository.saveInvitation(organizationId: invitation.organizationId, invitation: updatedInvitation);
      _session = AuthSession(
        isAuthenticated: true,
        currentUser: AuthUser(
            id: userCredential.uid,
          name: role == AccountRole.doctor ? (await _firestoreDoctorRepository.fetchDoctorByIdForOrganization(invitation.organizationId, invitation.doctorId!))?.name ?? normalizedEmail : normalizedEmail,
          email: normalizedEmail,
          role: role,
          organizationId: invitation.organizationId,
          doctorId: role == AccountRole.doctor ? invitation.doctorId : null,
        ),
        currentRole: role,
        organizationId: invitation.organizationId,
        doctorId: role == AccountRole.doctor ? invitation.doctorId : null,
      );
      return AuthResult(success: true, message: 'تم تفعيل الحساب بنجاح.', session: _session);
    } on FirebaseAuthException catch (exception) {
      return AuthResult(success: false, message: exception.message ?? _mapFirebaseAuthError(exception));
    } on StateError catch (error) {
      return AuthResult(success: false, message: error.message);
    }
  }

  @override
  Future<AuthResult> activatePatientAccount({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return const AuthResult(success: false, message: 'أدخل البريد الإلكتروني الخاص بالمريض.');
    if (password.length < 6) return const AuthResult(success: false, message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.');

    Patient? patientRecord;
    User? firebaseUser;
    var createdAuthAccount = false;
    var profileLinked = false;
    var commitOutcomeUnknown = false;

    try {
      patientRecord = await _firestorePatientRepository.fetchPendingPatientByEmail(normalizedEmail);
      if (patientRecord == null) {
        return const AuthResult(success: false, message: 'لا يوجد سجل مريض معلّق بهذا البريد الإلكتروني.');
      }
      if (patientRecord.email.trim().toLowerCase() != normalizedEmail ||
          patientRecord.id.isEmpty ||
          patientRecord.organizationId.isEmpty ||
          patientRecord.doctorId.isEmpty ||
          patientRecord.accountActivated ||
          patientRecord.firebaseUid != null) {
        return const AuthResult(success: false, message: 'بيانات سجل المريض غير صالحة للتفعيل.');
      }

      final account = await _createPatientFirebaseAccount(
        email: normalizedEmail,
        password: password,
      );
      firebaseUser = account.user;
      createdAuthAccount = account.created;
      if (firebaseUser == null) {
        return const AuthResult(success: false, message: 'تعذر إنشاء حساب المريض في Firebase.');
      }
      final profile = await _firestoreUserProfileRepository.fetchUserProfile(firebaseUser.uid);
      if (profile != null &&
          (profile.email.trim().toLowerCase() != normalizedEmail ||
            profile.role != AccountRole.patient ||
              (profile.patientId != null && profile.patientId != patientRecord.id) ||
              (profile.organizationId != null && profile.organizationId != patientRecord.organizationId) ||
              (profile.doctorId != null && profile.doctorId != patientRecord.doctorId))) {
        throw StateError('حساب Firebase مرتبط بسجل مريض أو دور مختلف.');
      }

      final activationBatch = FirebaseFirestore.instance.batch();
      await _firestorePatientRepository.activatePatient(
        patientId: patientRecord.id,
        organizationId: patientRecord.organizationId,
        firebaseUid: firebaseUser.uid,
        email: normalizedEmail,
        batch: activationBatch,
      );
      await _firestoreUserProfileRepository.linkPatientProfile(
        uid: firebaseUser.uid,
        email: normalizedEmail,
        patientId: patientRecord.id,
        doctorId: patientRecord.doctorId,
        organizationId: patientRecord.organizationId,
        batch: activationBatch,
      );
      try {
        await activationBatch.commit();
        profileLinked = true;
      } catch (_) {
        commitOutcomeUnknown = true;
        final persistedPatient = await _firestorePatientRepository.fetchPatientById(
          patientRecord.id,
          organizationId: patientRecord.organizationId,
        );
        final persistedProfile = await _firestoreUserProfileRepository.fetchUserProfile(firebaseUser.uid);
        profileLinked = persistedPatient?.accountActivated == true &&
            persistedPatient?.firebaseUid == firebaseUser.uid &&
            persistedProfile?.role == AccountRole.patient &&
            persistedProfile?.email.trim().toLowerCase() == normalizedEmail &&
            persistedProfile?.patientId == patientRecord.id &&
            persistedProfile?.doctorId == patientRecord.doctorId &&
            persistedProfile?.organizationId == patientRecord.organizationId;
        commitOutcomeUnknown = false;
        if (!profileLinked) rethrow;
      }

      final activatedPatient = await _firestorePatientRepository.fetchPatientById(
        patientRecord.id,
        organizationId: patientRecord.organizationId,
      );
      if (activatedPatient == null ||
          activatedPatient.firebaseUid != firebaseUser.uid ||
          !activatedPatient.accountActivated) {
        return const AuthResult(success: false, message: 'تعذر التحقق من ربط سجل المريض بعد التفعيل.');
      }

      _session = AuthSession(
        isAuthenticated: true,
        currentUser: _authUserForPatient(activatedPatient, firebaseUser.uid),
        currentRole: AccountRole.patient,
        organizationId: activatedPatient.organizationId,
        doctorId: activatedPatient.doctorId,
        patientId: activatedPatient.id,
      );
      return AuthResult(success: true, message: 'تم تفعيل حساب المريض بنجاح.', session: _session);
    } catch (error) {
      if (!profileLinked &&
          !commitOutcomeUnknown &&
          createdAuthAccount &&
          firebaseUser != null) {
          try {
            await firebaseUser.delete();
          } catch (_) {
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
      }
      final message = switch (error) {
        FirebaseAuthException exception => exception.message ?? _mapFirebaseAuthError(exception),
        StateError stateError => stateError.message,
        _ => error.toString(),
      };
      return AuthResult(success: false, message: message);
    }
  }

  @override
  void logout() {
    _firebaseAuth.signOut();
    _session = const AuthSession.signedOut();
  }
}
