import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/models/account_role.dart';
import '../../../../core/auth/models/account_status.dart';
import '../../../../core/auth/models/invitation_status.dart';
import '../../../../core/auth/models/doctor.dart';
import '../../../../core/auth/models/invitation.dart';
import '../../../../core/auth/models/organization.dart';
import '../../../../core/auth/models/patient.dart';
import '../../../../core/auth/models/auth_session.dart';
import '../../../../core/auth/models/auth_user.dart';
import '../../../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../../../core/firestore/repositories/firestore_invitation_repository.dart';
import '../../../../core/firestore/repositories/firestore_organization_repository.dart';
import '../../../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../../../core/firestore/repositories/firestore_user_profile_repository.dart';
import '../../domain/entities/user_account.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirestoreOrganizationRepository? organizationRepository,
    FirestoreDoctorRepository? doctorRepository,
    FirestorePatientRepository? patientRepository,
    FirestoreInvitationRepository? invitationRepository,
    FirestoreUserProfileRepository? userProfileRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _organizationRepository = organizationRepository ?? FirestoreOrganizationRepository.instance,
        _doctorRepository = doctorRepository ?? FirestoreDoctorRepository.instance,
        _patientRepository = patientRepository ?? FirestorePatientRepository.instance,
        _invitationRepository = invitationRepository ?? FirestoreInvitationRepository.instance,
        _userProfileRepository = userProfileRepository ?? FirestoreUserProfileRepository();

  final FirebaseAuth _firebaseAuth;
  final FirestoreOrganizationRepository _organizationRepository;
  final FirestoreDoctorRepository _doctorRepository;
  final FirestorePatientRepository _patientRepository;
  final FirestoreInvitationRepository _invitationRepository;
  final FirestoreUserProfileRepository _userProfileRepository;

  AuthSession _session = const AuthSession.signedOut();

  AuthSession get session => _session;

  bool get isAuthenticated => _session.isAuthenticated;

  AuthUser? get currentUser => _session.currentUser;

  AccountRole? get currentRole => _session.currentRole;

  Future<AuthSession> _buildSession(User firebaseUser) async {
    final profile = await _userProfileRepository.fetchUserProfile(firebaseUser.uid);
    if (profile == null || profile.uid != firebaseUser.uid) {
      throw StateError('لم يتم العثور على ملف المستخدم المرتبط بحساب Firebase.');
    }

    switch (profile.role) {
      case AccountRole.organization:
        final organizationId = profile.organizationId;
        if (organizationId == null || organizationId.isEmpty) {
          throw StateError('ملف المؤسسة لا يحتوي على معرف مؤسسة صالح.');
        }
        final organization = await _organizationRepository.fetchOrganizationById(organizationId);
        if (organization == null ||
            organization.status != AccountStatus.active ||
            (organization.firebaseUid != null && organization.firebaseUid != firebaseUser.uid)) {
          throw StateError('تعذر التحقق من ملكية المؤسسة لحساب Firebase الحالي.');
        }
        return AuthSession(
          isAuthenticated: true,
          currentUser: AuthUser(
            id: firebaseUser.uid,
            name: organization.name,
            email: firebaseUser.email ?? profile.email,
            role: AccountRole.organization,
            organizationId: organization.id,
            clinicId: profile.clinicId,
          ),
          currentRole: AccountRole.organization,
          organizationId: organization.id,
          clinicId: profile.clinicId,
        );
      case AccountRole.doctor:
        final doctorId = profile.doctorId;
        if (doctorId == null || doctorId.isEmpty) {
          throw StateError('ملف الطبيب لا يحتوي على معرف طبيب صالح.');
        }
        final organizationId = profile.organizationId;
        if (organizationId == null || organizationId.isEmpty) {
          throw StateError('ملف الطبيب لا يحتوي على معرف مؤسسة صالح.');
        }
        final doctor = await _doctorRepository.fetchDoctorByIdForOrganization(organizationId, doctorId);
        if (doctor == null || doctor.status != AccountStatus.active || doctor.firebaseUid != firebaseUser.uid) {
          throw StateError('تعذر التحقق من عضوية الطبيب لحساب Firebase الحالي.');
        }
        return AuthSession(
          isAuthenticated: true,
          currentUser: AuthUser(
            id: firebaseUser.uid,
            name: doctor.name,
            email: firebaseUser.email ?? doctor.email,
            role: AccountRole.doctor,
            organizationId: doctor.organizationId,
            doctorId: doctor.id,
          ),
          currentRole: AccountRole.doctor,
          organizationId: doctor.organizationId,
          doctorId: doctor.id,
        );
      case AccountRole.patient:
        final patientId = profile.patientId;
        if (patientId == null || patientId.isEmpty) {
          throw StateError('ملف المريض لا يحتوي على معرف مريض صالح.');
        }
        final patient = await _patientRepository.fetchPatientById(patientId, organizationId: profile.organizationId);
        if (patient == null || !patient.accountActivated || patient.firebaseUid != firebaseUser.uid) {
          throw StateError('تعذر التحقق من ملكية سجل المريض لحساب Firebase الحالي.');
        }
        return AuthSession(
          isAuthenticated: true,
          currentUser: AuthUser(
            id: firebaseUser.uid,
            name: patient.name,
            email: firebaseUser.email ?? patient.email,
            role: AccountRole.patient,
            organizationId: patient.organizationId,
            doctorId: patient.doctorId,
            patientId: patient.id,
          ),
          currentRole: AccountRole.patient,
          organizationId: patient.organizationId,
          doctorId: patient.doctorId,
          patientId: patient.id,
        );
    }
  }

  Future<void> restoreSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      _session = const AuthSession.signedOut();
      return;
    }

    try {
      _session = await _buildSession(firebaseUser);
    } catch (_) {
      await _firebaseAuth.signOut();
      _session = const AuthSession.signedOut();
    }
  }

  Future<User?> createFirebaseAccountIfNeeded({required String email, required String password}) async {
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

  Future<User?> _createFirebaseAccount({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return credential.user;
    } on FirebaseAuthException catch (exception) {
      throw FirebaseAuthException(code: exception.code, message: _mapFirebaseAuthError(exception));
    }
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

    UserAccount _authUserForPatient(Patient patient, String firebaseUid) => UserAccount(
      id: firebaseUid,
        name: patient.name,
        email: patient.email,
        role: AccountRole.patient,
        organizationId: patient.organizationId,
        doctorId: patient.doctorId,
        patientId: patient.id,
      );

    UserAccount _authUserForDoctor(Doctor doctor, String firebaseUid) => UserAccount(
      id: firebaseUid,
        name: doctor.name,
        email: doctor.email,
        role: AccountRole.doctor,
        organizationId: doctor.organizationId,
        doctorId: doctor.id,
      );

    UserAccount _authUserForOrganization(Organization organization, String firebaseUid) => UserAccount(
      id: firebaseUid,
        name: organization.name,
        email: organization.email,
        role: AccountRole.organization,
        organizationId: organization.id,
      );

  Future<({bool success, String message, UserAccount? user, AccountRole? currentRole})> login({
    required AccountRole role,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return (success: false, message: 'أدخل البريد الإلكتروني وكلمة المرور.', user: null, currentRole: null);
    }

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
        final profile = await _userProfileRepository.fetchUserProfile(userCredential.user!.uid);
        if (profile != null && profile.role != role) {
          return (
            success: false,
            message: 'لا يمكن الدخول من شاشة دور مختلف عن دور الحساب.',
            user: null,
            currentRole: null,
          );
        }
      switch (role) {
        case AccountRole.organization:
            if (profile?.role == AccountRole.organization && profile?.organizationId != null) {
              final invitedOrganization = await _organizationRepository.fetchOrganizationById(profile!.organizationId!);
            if (invitedOrganization == null || invitedOrganization.status != AccountStatus.active) {
              return (success: false, message: 'المؤسسة المرتبطة بهذا الحساب غير موجودة أو غير نشطة.', user: null, currentRole: null);
            }
            final user = UserAccount(
              id: userCredential.user!.uid,
              name: invitedOrganization.name,
              email: normalizedEmail,
              role: AccountRole.organization,
              organizationId: invitedOrganization.id,
              clinicId: profile.clinicId,
            );
            _session = await _buildSession(userCredential.user!);
            return (success: true, message: 'تم تسجيل الدخول بنجاح.', user: user, currentRole: AccountRole.organization);
          }
          final organizationRecord = await _organizationRepository.fetchOrganizationByEmail(normalizedEmail);
          if (organizationRecord == null) {
            return (success: false, message: 'لا يوجد حساب مؤسسة مطابق لهذا البريد.', user: null, currentRole: null);
          }
          if (organizationRecord.firebaseUid != null && organizationRecord.firebaseUid != userCredential.user?.uid) {
            return (success: false, message: 'هذه المؤسسة مرتبطة بالفعل بحساب Firebase مختلف ولا يمكن استخدامها هنا.', user: null, currentRole: null);
          }
          await _organizationRepository.linkFirebaseUid(
            organizationId: organizationRecord.id,
            firebaseUid: userCredential.user!.uid,
            email: normalizedEmail,
          );
          await _userProfileRepository.linkOrganizationProfile(
            uid: userCredential.user!.uid,
            email: normalizedEmail,
            organizationId: organizationRecord.id,
          );
          final user = _authUserForOrganization(organizationRecord, userCredential.user!.uid);
          _session = await _buildSession(userCredential.user!);
          return (success: true, message: 'تم تسجيل الدخول بنجاح.', user: user, currentRole: AccountRole.organization);
        case AccountRole.doctor:
          if (profile?.role == AccountRole.doctor && profile?.doctorId != null && profile?.organizationId != null) {
            final doctor = await _doctorRepository.fetchDoctorByIdForOrganization(profile!.organizationId!, profile.doctorId!);
            if (doctor == null || doctor.status != AccountStatus.active || doctor.firebaseUid != userCredential.user!.uid) {
              return (success: false, message: 'تعذر التحقق من سجل الطبيب المرتبط بهذا الحساب.', user: null, currentRole: null);
            }
            _session = await _buildSession(userCredential.user!);
            return (success: true, message: 'تم تسجيل الدخول بنجاح.', user: _authUserForDoctor(doctor, userCredential.user!.uid), currentRole: AccountRole.doctor);
          }
          return (success: false, message: 'لا يوجد ملف مستخدم مرتبط بسجل طبيب.', user: null, currentRole: null);
        case AccountRole.patient:
            final patientRecord = profile?.patientId != null && profile?.organizationId != null
              ? await _patientRepository.fetchPatientById(profile!.patientId!, organizationId: profile.organizationId)
              : null;
          if (patientRecord == null) {
            return (success: false, message: 'لا يوجد سجل مريض مطابق لهذا البريد الإلكتروني.', user: null, currentRole: null);
          }
          if (!patientRecord.accountActivated) {
            return (success: false, message: 'هذا الحساب غير مفعّل بعد. استخدم تفعيل حساب المريض أولاً.', user: null, currentRole: null);
          }
          if (patientRecord.firebaseUid != null && patientRecord.firebaseUid != userCredential.user?.uid) {
            return (success: false, message: 'هذا المريض مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.', user: null, currentRole: null);
          }
          await _patientRepository.activatePatient(
            patientId: patientRecord.id,
            organizationId: patientRecord.organizationId,
            firebaseUid: userCredential.user!.uid,
            email: normalizedEmail,
          );
          await _userProfileRepository.linkPatientProfile(
            uid: userCredential.user!.uid,
            email: normalizedEmail,
            patientId: patientRecord.id,
            doctorId: patientRecord.doctorId,
            organizationId: patientRecord.organizationId,
          );
          final user = _authUserForPatient(patientRecord, userCredential.user!.uid);
          _session = await _buildSession(userCredential.user!);
          return (success: true, message: 'تم تسجيل الدخول بنجاح.', user: user, currentRole: AccountRole.patient);
      }
    } on FirebaseAuthException catch (exception) {
      return (success: false, message: _mapFirebaseAuthError(exception), user: null, currentRole: null);
    } on StateError catch (error) {
      return (success: false, message: error.message, user: null, currentRole: null);
      } on FormatException catch (error) {
        return (success: false, message: error.message, user: null, currentRole: null);
    }
  }

  Future<({bool success, String message, UserAccount? user, AccountRole? currentRole})> activateInvitation({
    required AccountRole role,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return (success: false, message: 'أدخل البريد الإلكتروني المدعو.', user: null, currentRole: null);
    if (password.length < 6) return (success: false, message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.', user: null, currentRole: null);

    if (role == AccountRole.organization) return _activateOrganizationInvitation(email: normalizedEmail, password: password);

    try {
      final userCredential = await createFirebaseAccountIfNeeded(email: normalizedEmail, password: password);
      if (userCredential == null) {
        return (success: false, message: 'تعذر إنشاء حساب المستخدم في Firebase.', user: null, currentRole: null);
      }

      final invitation = await _invitationRepository.fetchPendingInvitationForEmailAndRole(email: normalizedEmail, role: role);

      if (invitation == null) {
        return (success: false, message: 'لم نجد دعوة بهذا البريد الإلكتروني.', user: null, currentRole: null);
      }

      if (role == AccountRole.doctor) {
        final doctorRecord = invitation.doctorId == null
          ? null
          : await _doctorRepository.fetchDoctorByIdForOrganization(invitation.organizationId, invitation.doctorId!);
        if (doctorRecord == null) {
          return (success: false, message: 'لا يوجد سجل طبيب مطابق لهذا البريد الإلكتروني في العلاقة الموثوقة.', user: null, currentRole: null);
        }
        if (doctorRecord.organizationId != invitation.organizationId) {
          return (success: false, message: 'لا يملك هذا الطبيب صلاحية تسجيل الدخول في هذه المؤسسة.', user: null, currentRole: null);
        }
          if (invitation.doctorId != null && invitation.doctorId != doctorRecord.id) {
            return (success: false, message: 'الدعوة لا تطابق سجل الطبيب الموثوق.', user: null, currentRole: null);
          }
        if (doctorRecord.firebaseUid != null && doctorRecord.firebaseUid != userCredential.uid) {
          return (success: false, message: 'هذا الطبيب مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.', user: null, currentRole: null);
        }
        await _doctorRepository.linkFirebaseUidForOrganization(organizationId: invitation.organizationId, doctorId: doctorRecord.id, firebaseUid: userCredential.uid, email: normalizedEmail);
        await _userProfileRepository.linkDoctorProfile(uid: userCredential.uid, email: normalizedEmail, doctorId: doctorRecord.id, organizationId: doctorRecord.organizationId);
      } else {
        await _userProfileRepository.createOrUpdateUserProfile(
          uid: userCredential.uid,
          email: normalizedEmail,
          role: role,
          organizationId: invitation.organizationId,
        );
      }

      final updatedInvitation = invitation.copyWith(status: InvitationStatus.accepted, userId: userCredential.uid, acceptedAt: DateTime.now());
      await _invitationRepository.saveInvitation(organizationId: invitation.organizationId, invitation: updatedInvitation);

      final createdUser = UserAccount(
        id: userCredential.uid,
        name: role == AccountRole.doctor ? (await _doctorRepository.fetchDoctorByIdForOrganization(invitation.organizationId, invitation.doctorId!))?.name ?? normalizedEmail : normalizedEmail,
        email: normalizedEmail,
        role: role,
        organizationId: invitation.organizationId,
        doctorId: role == AccountRole.doctor ? invitation.doctorId : null,
      );

        _session = await _buildSession(userCredential);

      return (success: true, message: 'تم تفعيل الحساب بنجاح.', user: createdUser, currentRole: role);
    } on FirebaseAuthException catch (exception) {
      return (success: false, message: exception.message ?? _mapFirebaseAuthError(exception), user: null, currentRole: null);
    } on StateError catch (error) {
      return (success: false, message: error.message, user: null, currentRole: null);
      } on FormatException catch (error) {
        return (success: false, message: error.message, user: null, currentRole: null);
    }
  }

  Future<({bool success, String message, UserAccount? user, AccountRole? currentRole})> _activateOrganizationInvitation({
    required String email,
    required String password,
  }) async {
    User? firebaseUser;
    try {
      firebaseUser = await _createFirebaseAccount(email: email, password: password);
      if (firebaseUser == null) {
        return (success: false, message: 'تعذر إنشاء حساب المؤسسة في Firebase.', user: null, currentRole: null);
      }
      final invitation = await _invitationRepository.fetchPendingInvitationForAuthenticatedEmail(email);
      if (invitation == null) {
        await firebaseUser.delete();
        return (success: false, message: 'لم نجد دعوة مؤسسة صالحة بهذا البريد الإلكتروني.', user: null, currentRole: null);
      }
      final organization = await _organizationRepository.fetchOrganizationById(invitation.organizationId);
      if (organization == null || organization.status != AccountStatus.active) {
        await firebaseUser.delete();
        return (success: false, message: 'المؤسسة المرتبطة بالدعوة غير موجودة أو غير نشطة.', user: null, currentRole: null);
      }
      await _invitationRepository.acceptInvitationForUser(invitation: invitation, uid: firebaseUser.uid);

      final user = UserAccount(
        id: firebaseUser.uid,
        name: organization.name,
        email: email,
        role: AccountRole.organization,
        organizationId: invitation.organizationId,
        clinicId: invitation.clinicId,
      );
        await _userProfileRepository.linkOrganizationProfile(
          uid: firebaseUser.uid,
          email: email,
          organizationId: invitation.organizationId,
          clinicId: invitation.clinicId,
          invitationId: invitation.id,
        );
        final session = await _buildSession(firebaseUser);
        _session = session;
      return (success: true, message: 'تم إنشاء حساب المؤسسة بنجاح.', user: user, currentRole: AccountRole.organization);
    } on FirebaseAuthException catch (exception) {
      return (success: false, message: exception.message ?? _mapFirebaseAuthError(exception), user: null, currentRole: null);
    } on StateError catch (error) {
      return (success: false, message: error.message, user: null, currentRole: null);
      } on FormatException catch (error) {
        return (success: false, message: error.message, user: null, currentRole: null);
    }
  }

  Future<({bool success, String message, UserAccount? user, AccountRole? currentRole})> activatePatientAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return (success: false, message: 'أدخل البريد الإلكتروني الخاص بالمريض.', user: null, currentRole: null);
    if (password.length < 6) return (success: false, message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.', user: null, currentRole: null);

    try {
      final userCredential = await createFirebaseAccountIfNeeded(email: normalizedEmail, password: password);
      if (userCredential == null) {
        return (success: false, message: 'تعذر إنشاء حساب المريض في Firebase.', user: null, currentRole: null);
      }
      final profile = await _userProfileRepository.fetchUserProfile(userCredential.uid);
      final patientRecord = profile?.patientId != null && profile?.organizationId != null
          ? await _patientRepository.fetchPatientById(profile!.patientId!, organizationId: profile.organizationId)
          : null;
      if (patientRecord == null) {
        return (success: false, message: 'لا يوجد ملف مستخدم مرتبط بسجل مريض.', user: null, currentRole: null);
      }
      if (patientRecord.accountActivated) {
        return (success: false, message: 'هذا الحساب مفعّل بالفعل. استخدم تسجيل الدخول العادي.', user: null, currentRole: null);
      }
      if (patientRecord.firebaseUid != null && patientRecord.firebaseUid != userCredential.uid) {
        return (success: false, message: 'هذا المريض مرتبط بالفعل بحساب مستخدم آخر ولا يمكن استخدامه هنا.', user: null, currentRole: null);
      }
      await _patientRepository.activatePatient(patientId: patientRecord.id, organizationId: patientRecord.organizationId, firebaseUid: userCredential.uid, email: normalizedEmail);
      await _userProfileRepository.linkPatientProfile(
        uid: userCredential.uid,
        email: normalizedEmail,
        patientId: patientRecord.id,
        doctorId: patientRecord.doctorId,
        organizationId: patientRecord.organizationId,
      );

      final user = _authUserForPatient(patientRecord, userCredential.uid);
        _session = await _buildSession(userCredential);
      return (success: true, message: 'تم تفعيل حساب المريض بنجاح.', user: user, currentRole: AccountRole.patient);
    } on FirebaseAuthException catch (exception) {
      return (success: false, message: exception.message ?? _mapFirebaseAuthError(exception), user: null, currentRole: null);
    } on StateError catch (error) {
      return (success: false, message: error.message, user: null, currentRole: null);
      } on FormatException catch (error) {
        return (success: false, message: error.message, user: null, currentRole: null);
    }
  }

  void logout() {
    _firebaseAuth.signOut();
    _session = const AuthSession.signedOut();
  }
}
