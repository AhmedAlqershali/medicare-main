import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/auth/models/account_role.dart';
import '../../../../core/auth/models/account_status.dart';
import '../../../../core/auth/models/invitation_status.dart';
import '../../../../core/auth/models/doctor.dart';
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
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _organizationRepository =
            organizationRepository ?? FirestoreOrganizationRepository.instance,
        _doctorRepository =
            doctorRepository ?? FirestoreDoctorRepository.instance,
        _patientRepository =
            patientRepository ?? FirestorePatientRepository.instance,
        _invitationRepository =
            invitationRepository ?? FirestoreInvitationRepository.instance,
        _userProfileRepository =
            userProfileRepository ?? FirestoreUserProfileRepository();

  final FirebaseAuth _firebaseAuth;
  final FirestoreOrganizationRepository _organizationRepository;
  final FirestoreDoctorRepository _doctorRepository;
  final FirestorePatientRepository _patientRepository;
  final FirestoreInvitationRepository _invitationRepository;
  final FirestoreUserProfileRepository _userProfileRepository;

  AuthSession _session = const AuthSession.signedOut();
  bool _awaitingEmailVerification = false;

  AuthSession get session => _session;

  bool get isAwaitingEmailVerification => _awaitingEmailVerification;

  bool get isAuthenticated => _session.isAuthenticated;

  AuthUser? get currentUser => _session.currentUser;

  AccountRole? get currentRole => _session.currentRole;

  Future<AuthSession> _buildSession(User firebaseUser) async {
    if (!firebaseUser.emailVerified) {
      throw StateError('يجب التحقق من البريد الإلكتروني قبل استخدام الحساب.');
    }

    final profile = await _userProfileRepository.fetchUserProfile(
      firebaseUser.uid,
    );

    if (profile == null ||
        profile.uid != firebaseUser.uid ||
        profile.email.trim().toLowerCase() !=
            (firebaseUser.email ?? '').trim().toLowerCase()) {
      throw StateError(
        'لم يتم العثور على ملف المستخدم المرتبط بحساب Firebase.',
      );
    }

    switch (profile.role) {
      case AccountRole.organization:
        final organizationId = profile.organizationId;

        if (organizationId == null || organizationId.isEmpty) {
          throw StateError('ملف المؤسسة لا يحتوي على معرف مؤسسة صالح.');
        }

        final organization = await _organizationRepository
            .fetchOrganizationById(organizationId);

        if (organization == null ||
            organization.status != AccountStatus.active ||
          (profile.invitationId == null
            ? organization.firebaseUid != firebaseUser.uid ||
              organization.email.trim().toLowerCase() !=
                profile.email.trim().toLowerCase()
            : !await _isAcceptedOrganizationInvitation(
              invitationId: profile.invitationId!,
              organizationId: organizationId,
              uid: firebaseUser.uid,
              email: profile.email,
              ))) {
          throw StateError(
            'تعذر التحقق من ملكية المؤسسة لحساب Firebase الحالي.',
          );
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

        final doctor = await _doctorRepository.fetchDoctorByIdForOrganization(
          organizationId,
          doctorId,
        );
        final organization = await _organizationRepository
          .fetchOrganizationById(organizationId);

        if (doctor == null ||
          organization == null ||
          organization.status != AccountStatus.active ||
            doctor.status != AccountStatus.active ||
          doctor.firebaseUid != firebaseUser.uid ||
          doctor.organizationId != organizationId ||
          doctor.email.trim().toLowerCase() !=
            profile.email.trim().toLowerCase()) {
          throw StateError(
            'تعذر التحقق من عضوية الطبيب لحساب Firebase الحالي.',
          );
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

        final patient = await _patientRepository.fetchPatientById(
          patientId,
          organizationId: profile.organizationId,
        );

        if (patient == null ||
            !patient.accountActivated ||
          patient.status != AccountStatus.active ||
          patient.firebaseUid != firebaseUser.uid ||
          patient.organizationId != profile.organizationId ||
          patient.doctorId != profile.doctorId ||
          patient.email.trim().toLowerCase() !=
            profile.email.trim().toLowerCase()) {
          throw StateError(
            'تعذر التحقق من ملكية سجل المريض لحساب Firebase الحالي.',
          );
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

  Future<bool> _isAcceptedOrganizationInvitation({
    required String invitationId,
    required String organizationId,
    required String uid,
    required String email,
  }) async {
    final invitation = await _invitationRepository.fetchInvitationById(
      organizationId,
      invitationId,
    );
    return invitation != null &&
        invitation.organizationId == organizationId &&
        invitation.role == AccountRole.organization &&
        invitation.status == InvitationStatus.accepted &&
        invitation.userId == uid &&
        invitation.email.trim().toLowerCase() == email.trim().toLowerCase();
  }

  Future<void> restoreSession() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      _session = const AuthSession.signedOut();
      return;
    }

    try {
      await firebaseUser.reload();

      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null) {
        _session = const AuthSession.signedOut();
        return;
      }

      if (!refreshedUser.emailVerified) {
        _session = const AuthSession.signedOut();
        return;
      }

      await refreshedUser.getIdToken(true);
      _session = await _buildSession(refreshedUser);
    } catch (_) {
      await _firebaseAuth.signOut();
      _session = const AuthSession.signedOut();
    }
  }

  Future<User?> _refreshVerifiedUser(
    User user, {
    bool sendVerificationEmail = false,
  }) async {
    await user.reload();
    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) {
      _awaitingEmailVerification = false;
      return null;
    }

    if (!refreshedUser.emailVerified) {
      _awaitingEmailVerification = false;
      if (sendVerificationEmail) {
        await refreshedUser.sendEmailVerification();
        _awaitingEmailVerification = true;
      }
      _session = const AuthSession.signedOut();
      return null;
    }

    _awaitingEmailVerification = false;
    await refreshedUser.getIdToken(true);
    return _firebaseAuth.currentUser;
  }

  Future<User?> createFirebaseAccountIfNeeded({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (exception) {
      if (exception.code == 'email-already-in-use') {
        try {
          final credential = await _firebaseAuth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

          return credential.user;
        } on FirebaseAuthException catch (signInException) {
          throw FirebaseAuthException(
            code: signInException.code,
            message: _mapFirebaseAuthError(signInException),
          );
        }
      }

      throw FirebaseAuthException(
        code: exception.code,
        message: _mapFirebaseAuthError(exception),
      );
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
      if (exception.code != 'email-already-in-use') {
        rethrow;
      }

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return (user: credential.user, created: false);
    }
  }

  Future<User?> _createFirebaseAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (exception) {
      throw FirebaseAuthException(
        code: exception.code,
        message: _mapFirebaseAuthError(exception),
      );
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
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      default:
        return exception.message ?? 'حدث خطأ في المصادقة.';
    }
  }

  UserAccount _authUserForPatient(Patient patient, String firebaseUid) {
    return UserAccount(
      id: firebaseUid,
      name: patient.name,
      email: patient.email,
      role: AccountRole.patient,
      organizationId: patient.organizationId,
      doctorId: patient.doctorId,
      patientId: patient.id,
    );
  }

  UserAccount _authUserForDoctor(Doctor doctor, String firebaseUid) {
    return UserAccount(
      id: firebaseUid,
      name: doctor.name,
      email: doctor.email,
      role: AccountRole.doctor,
      organizationId: doctor.organizationId,
      doctorId: doctor.id,
    );
  }

  UserAccount _authUserForOrganization(
      Organization organization,
      String firebaseUid,
      ) {
    return UserAccount(
      id: firebaseUid,
      name: organization.name,
      email: organization.email,
      role: AccountRole.organization,
      organizationId: organization.id,
    );
  }

  Future<
      ({
      bool success,
      String message,
      UserAccount? user,
      AccountRole? currentRole,
      })
  >
  login({
    required AccountRole role,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return (
      success: false,
      message: 'أدخل البريد الإلكتروني وكلمة المرور.',
      user: null,
      currentRole: null,
      );
    }

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      var firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return (
        success: false,
        message: 'تعذر الحصول على حساب Firebase الحالي.',
        user: null,
        currentRole: null,
        );
      }

      firebaseUser = await _refreshVerifiedUser(firebaseUser);
      if (firebaseUser == null) {
        return (
          success: false,
          message: 'تحقق من بريدك الإلكتروني عبر الرابط المرسل قبل تسجيل الدخول.',
          user: null,
          currentRole: null,
        );
      }

      final profile = await _userProfileRepository.fetchUserProfile(
        firebaseUser.uid,
      );

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
          if (profile?.role == AccountRole.organization &&
              profile?.organizationId != null) {
            final invitedOrganization = await _organizationRepository
                .fetchOrganizationById(profile!.organizationId!);

            if (invitedOrganization == null ||
                invitedOrganization.status != AccountStatus.active) {
              return (
              success: false,
              message: 'المؤسسة المرتبطة بهذا الحساب غير موجودة أو غير نشطة.',
              user: null,
              currentRole: null,
              );
            }

            final user = UserAccount(
              id: firebaseUser.uid,
              name: invitedOrganization.name,
              email: normalizedEmail,
              role: AccountRole.organization,
              organizationId: invitedOrganization.id,
              clinicId: profile.clinicId,
            );

            _session = await _buildSession(firebaseUser);

            return (
            success: true,
            message: 'تم تسجيل الدخول بنجاح.',
            user: user,
            currentRole: AccountRole.organization,
            );
          }

          final organizationRecord = await _organizationRepository
              .fetchOrganizationByEmail(normalizedEmail);

          if (organizationRecord == null) {
            return (
            success: false,
            message: 'لا يوجد حساب مؤسسة مطابق لهذا البريد.',
            user: null,
            currentRole: null,
            );
          }

          if (organizationRecord.status != AccountStatus.active) {
            return (
              success: false,
              message: 'لا يمكن تفعيل حساب مؤسسة غير نشطة.',
              user: null,
              currentRole: null,
            );
          }

          if (organizationRecord.firebaseUid != null &&
              organizationRecord.firebaseUid != firebaseUser.uid) {
            return (
            success: false,
            message:
            'هذه المؤسسة مرتبطة بالفعل بحساب Firebase مختلف ولا يمكن استخدامها هنا.',
            user: null,
            currentRole: null,
            );
          }

          final linkBatch = FirebaseFirestore.instance.batch();
          await _organizationRepository.linkFirebaseUid(
            organizationId: organizationRecord.id,
            firebaseUid: firebaseUser.uid,
            email: normalizedEmail,
            batch: linkBatch,
          );

          await _userProfileRepository.linkOrganizationProfile(
            uid: firebaseUser.uid,
            email: normalizedEmail,
            organizationId: organizationRecord.id,
            batch: linkBatch,
          );
          await linkBatch.commit();

          final user = _authUserForOrganization(
            organizationRecord,
            firebaseUser.uid,
          );

          _session = await _buildSession(firebaseUser);

          return (
          success: true,
          message: 'تم تسجيل الدخول بنجاح.',
          user: user,
          currentRole: AccountRole.organization,
          );

        case AccountRole.doctor:
          if (profile?.role == AccountRole.doctor &&
              profile?.doctorId != null &&
              profile?.organizationId != null) {
            final doctor = await _doctorRepository
                .fetchDoctorByIdForOrganization(
              profile!.organizationId!,
              profile.doctorId!,
            );

            if (doctor == null ||
                doctor.status != AccountStatus.active ||
                doctor.firebaseUid != firebaseUser.uid) {
              return (
              success: false,
              message: 'تعذر التحقق من سجل الطبيب المرتبط بهذا الحساب.',
              user: null,
              currentRole: null,
              );
            }

            _session = await _buildSession(firebaseUser);

            return (
            success: true,
            message: 'تم تسجيل الدخول بنجاح.',
            user: _authUserForDoctor(doctor, firebaseUser.uid),
            currentRole: AccountRole.doctor,
            );
          }

          return (
          success: false,
          message: 'لا يوجد ملف مستخدم مرتبط بسجل طبيب.',
          user: null,
          currentRole: null,
          );

        case AccountRole.patient:
          final patientRecord =
          profile?.patientId != null && profile?.organizationId != null
              ? await _patientRepository.fetchPatientById(
            profile!.patientId!,
            organizationId: profile.organizationId,
          )
              : null;

          if (patientRecord == null) {
            return (
            success: false,
            message: 'لا يوجد سجل مريض مطابق لهذا البريد الإلكتروني.',
            user: null,
            currentRole: null,
            );
          }

          if (!patientRecord.accountActivated) {
            return (
            success: false,
            message:
            'هذا الحساب غير مفعّل بعد. استخدم تفعيل حساب المريض أولاً.',
            user: null,
            currentRole: null,
            );
          }

          if (patientRecord.firebaseUid != null &&
              patientRecord.firebaseUid != firebaseUser.uid) {
            return (
            success: false,
            message:
            'هذا المريض مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.',
            user: null,
            currentRole: null,
            );
          }

          final user = _authUserForPatient(patientRecord, firebaseUser.uid);

          _session = await _buildSession(firebaseUser);

          return (
          success: true,
          message: 'تم تسجيل الدخول بنجاح.',
          user: user,
          currentRole: AccountRole.patient,
          );
      }
    } on FirebaseAuthException catch (exception) {
      return (
      success: false,
      message: _mapFirebaseAuthError(exception),
      user: null,
      currentRole: null,
      );
    } on StateError catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    } on FormatException catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    }
  }

  Future<
      ({
      bool success,
      String message,
      UserAccount? user,
      AccountRole? currentRole,
      })
  >
  activateInvitation({
    required AccountRole role,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return (
      success: false,
      message: 'أدخل البريد الإلكتروني المدعو.',
      user: null,
      currentRole: null,
      );
    }

    if (password.length < 6) {
      return (
      success: false,
      message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.',
      user: null,
      currentRole: null,
      );
    }

    if (role != AccountRole.doctor && role != AccountRole.organization) {
      return (
        success: false,
        message: 'نوع الدعوة غير صالح.',
        user: null,
        currentRole: null,
      );
    }

    if (role == AccountRole.organization) {
      return _activateOrganizationInvitation(
        email: normalizedEmail,
        password: password,
      );
    }

    try {
      var userCredential = await createFirebaseAccountIfNeeded(
        email: normalizedEmail,
        password: password,
      );

      if (userCredential == null) {
        return (
        success: false,
        message: 'تعذر إنشاء حساب المستخدم في Firebase.',
        user: null,
        currentRole: null,
        );
      }

      userCredential = await _refreshVerifiedUser(
        userCredential,
        sendVerificationEmail: true,
      );
      if (userCredential == null) {
        return (
          success: false,
          message: 'تحقق من بريدك الإلكتروني عبر الرابط المرسل لإكمال تفعيل الدعوة.',
          user: null,
          currentRole: null,
        );
      }

      final invitation = await _invitationRepository
          .fetchPendingInvitationForEmailAndRole(
        email: normalizedEmail,
        role: role,
      );

      if (invitation == null) {
        return (
        success: false,
        message: 'لم نجد دعوة بهذا البريد الإلكتروني.',
        user: null,
        currentRole: null,
        );
      }

      if (role == AccountRole.doctor) {
        final organization = await _organizationRepository.fetchOrganizationById(
          invitation.organizationId,
        );
        if (organization == null ||
            organization.status != AccountStatus.active) {
          throw StateError('المؤسسة المرتبطة بالدعوة غير نشطة.');
        }

        final doctorRecord = invitation.doctorId == null
            ? null
            : await _doctorRepository.fetchDoctorByIdForOrganization(
          invitation.organizationId,
          invitation.doctorId!,
        );

        if (doctorRecord == null) {
          return (
          success: false,
          message:
          'لا يوجد سجل طبيب مطابق لهذا البريد الإلكتروني في العلاقة الموثوقة.',
          user: null,
          currentRole: null,
          );
        }

        if (doctorRecord.organizationId != invitation.organizationId) {
          return (
          success: false,
          message: 'لا يملك هذا الطبيب صلاحية تسجيل الدخول في هذه المؤسسة.',
          user: null,
          currentRole: null,
          );
        }

        if (doctorRecord.email.trim().toLowerCase() != normalizedEmail ||
          (doctorRecord.status != AccountStatus.pending &&
            !(doctorRecord.status == AccountStatus.active &&
              doctorRecord.firebaseUid == userCredential.uid))) {
          throw StateError('الدعوة لا تطابق سجل طبيب معلّقًا وصالحًا.');
        }

        if (invitation.doctorId != null &&
            invitation.doctorId != doctorRecord.id) {
          return (
          success: false,
          message: 'الدعوة لا تطابق سجل الطبيب الموثوق.',
          user: null,
          currentRole: null,
          );
        }

        if (doctorRecord.firebaseUid != null &&
            doctorRecord.firebaseUid != userCredential.uid) {
          return (
          success: false,
          message:
          'هذا الطبيب مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.',
          user: null,
          currentRole: null,
          );
        }

        final existingProfile = await _userProfileRepository.fetchUserProfile(
          userCredential.uid,
        );
        if (existingProfile != null &&
            (existingProfile.email.trim().toLowerCase() != normalizedEmail ||
                existingProfile.role != AccountRole.doctor ||
                existingProfile.doctorId != doctorRecord.id ||
                existingProfile.organizationId != doctorRecord.organizationId)) {
          throw StateError('حساب Firebase مرتبط بملف أو مؤسسة أخرى.');
        }

        final activationBatch = FirebaseFirestore.instance.batch();
        await _doctorRepository.linkFirebaseUidForOrganization(
          organizationId: invitation.organizationId,
          doctorId: doctorRecord.id,
          firebaseUid: userCredential.uid,
          email: normalizedEmail,
          batch: activationBatch,
        );

        await _userProfileRepository.linkDoctorProfile(
          uid: userCredential.uid,
          email: normalizedEmail,
          doctorId: doctorRecord.id,
          organizationId: doctorRecord.organizationId,
          batch: activationBatch,
        );

        activationBatch.update(
          _invitationRepository.invitationDocument(
            invitation.organizationId,
            invitation.id,
          ),
          {
            'status': InvitationStatus.accepted.name,
            'userId': userCredential.uid,
            'acceptedAt': FieldValue.serverTimestamp(),
          },
        );
        await activationBatch.commit();
      } else {
        await _userProfileRepository.createOrUpdateUserProfile(
          uid: userCredential.uid,
          email: normalizedEmail,
          role: role,
          organizationId: invitation.organizationId,
        );
      }

      if (role != AccountRole.doctor) {
        final updatedInvitation = invitation.copyWith(
          status: InvitationStatus.accepted,
          userId: userCredential.uid,
          acceptedAt: DateTime.now(),
        );

        await _invitationRepository.saveInvitation(
          organizationId: invitation.organizationId,
          invitation: updatedInvitation,
        );
      }

      final createdUser = UserAccount(
        id: userCredential.uid,
        name: role == AccountRole.doctor
            ? (await _doctorRepository.fetchDoctorByIdForOrganization(
          invitation.organizationId,
          invitation.doctorId!,
        ))?.name ??
            normalizedEmail
            : normalizedEmail,
        email: normalizedEmail,
        role: role,
        organizationId: invitation.organizationId,
        doctorId: role == AccountRole.doctor ? invitation.doctorId : null,
      );

      _session = await _buildSession(userCredential);

      return (
      success: true,
      message: 'تم تفعيل الحساب بنجاح.',
      user: createdUser,
      currentRole: role,
      );
    } on FirebaseAuthException catch (exception) {
      return (
      success: false,
      message: exception.message ?? _mapFirebaseAuthError(exception),
      user: null,
      currentRole: null,
      );
    } on StateError catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    } on FormatException catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    }
  }

  Future<
      ({
      bool success,
      String message,
      UserAccount? user,
      AccountRole? currentRole,
      })
  >
  _activateOrganizationInvitation({
    required String email,
    required String password,
  }) async {
    User? firebaseUser;
    var createdAuthAccount = false;

    try {
      final account = await _createPatientFirebaseAccount(
        email: email,
        password: password,
      );
      firebaseUser = account.user;
      createdAuthAccount = account.created;

      if (firebaseUser == null) {
        return (
        success: false,
        message: 'تعذر إنشاء حساب المؤسسة في Firebase.',
        user: null,
        currentRole: null,
        );
      }

      firebaseUser = await _refreshVerifiedUser(
        firebaseUser,
        sendVerificationEmail: true,
      );
      if (firebaseUser == null) {
        return (
          success: false,
          message: 'تحقق من بريدك الإلكتروني عبر الرابط المرسل لإكمال تفعيل المؤسسة.',
          user: null,
          currentRole: null,
        );
      }

      final invitation = await _invitationRepository
          .fetchPendingInvitationForAuthenticatedEmail(email);

      if (invitation == null) {
        if (createdAuthAccount) await firebaseUser.delete();

        return (
        success: false,
        message: 'لم نجد دعوة مؤسسة صالحة بهذا البريد الإلكتروني.',
        user: null,
        currentRole: null,
        );
      }

      final organization = await _organizationRepository.fetchOrganizationById(
        invitation.organizationId,
      );

      if (organization == null || organization.status != AccountStatus.active) {
        if (createdAuthAccount) await firebaseUser.delete();

        return (
        success: false,
        message: 'المؤسسة المرتبطة بالدعوة غير موجودة أو غير نشطة.',
        user: null,
        currentRole: null,
        );
      }

      await _invitationRepository.acceptInvitationForUser(
        invitation: invitation,
        uid: firebaseUser.uid,
      );

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

      return (
      success: true,
      message: 'تم إنشاء حساب المؤسسة بنجاح.',
      user: user,
      currentRole: AccountRole.organization,
      );
    } on FirebaseAuthException catch (exception) {
      return (
      success: false,
      message: exception.message ?? _mapFirebaseAuthError(exception),
      user: null,
      currentRole: null,
      );
    } on StateError catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    } on FormatException catch (error) {
      return (
      success: false,
      message: error.message,
      user: null,
      currentRole: null,
      );
    }
  }

  Future<
      ({
      bool success,
      String message,
      UserAccount? user,
      AccountRole? currentRole,
      })
  >
  activatePatientAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return (
      success: false,
      message: 'أدخل البريد الإلكتروني الخاص بالمريض.',
      user: null,
      currentRole: null,
      );
    }

    if (password.length < 6) {
      return (
      success: false,
      message: 'استخدم ٦ أحرف أو أكثر لكلمة المرور.',
      user: null,
      currentRole: null,
      );
    }

    User? firebaseUser;
    Patient? patientRecord;
    var createdAuthAccount = false;
    var profileLinked = false;
    var commitOutcomeUnknown = false;
    var activationStage = 'بدء التفعيل';

    try {
      activationStage = 'إنشاء حساب Firebase';

      final account = await _createPatientFirebaseAccount(
        email: normalizedEmail,
        password: password,
      );

      firebaseUser = account.user;
      createdAuthAccount = account.created;

      if (firebaseUser == null) {
        throw StateError('تعذر إنشاء حساب المريض في Firebase.');
      }

      activationStage = 'التحقق من البريد الإلكتروني';

      firebaseUser = await _refreshVerifiedUser(
        firebaseUser,
        sendVerificationEmail: true,
      );
      if (firebaseUser == null) {
        return (
          success: false,
          message: 'تحقق من بريدك الإلكتروني عبر الرابط المرسل لإكمال تفعيل حساب المريض.',
          user: null,
          currentRole: null,
        );
      }

      final firebaseEmail = firebaseUser.email?.trim().toLowerCase();

      if (firebaseEmail != normalizedEmail) {
        throw StateError('تعذر التحقق من حساب Firebase المطابق للبريد.');
      }

      activationStage = 'البحث عن سجل المريض المعلّق';

      patientRecord = await _patientRepository.fetchPendingPatientByEmail(
        normalizedEmail,
      );

      if (patientRecord == null) {
        throw StateError('لا يوجد سجل مريض معلّق بهذا البريد الإلكتروني.');
      }

      if (patientRecord.email.trim().toLowerCase() != normalizedEmail) {
        throw StateError('البريد الإلكتروني غير مطابق لسجل المريض.');
      }

      if (patientRecord.id.isEmpty ||
          patientRecord.organizationId.isEmpty ||
          patientRecord.doctorId.isEmpty ||
          patientRecord.accountActivated ||
          patientRecord.firebaseUid != null) {
        throw StateError('بيانات سجل المريض غير صالحة للتفعيل.');
      }

      activationStage = 'التحقق من ملف المستخدم الموجود';

      final existingProfile = await _userProfileRepository.fetchUserProfile(
        firebaseUser.uid,
      );

      if (existingProfile != null &&
          (existingProfile.email.trim().toLowerCase() != normalizedEmail ||
              existingProfile.role != AccountRole.patient ||
            existingProfile.patientId != patientRecord.id ||
            existingProfile.organizationId !=
              patientRecord.organizationId ||
            existingProfile.doctorId != patientRecord.doctorId)) {
        throw StateError('حساب Firebase مرتبط بسجل مريض أو دور مختلف.');
      }

      activationStage = 'تجهيز تحديث سجل المريض والمواعيد';

      final activationBatch = FirebaseFirestore.instance.batch();

      await _patientRepository.activatePatient(
        patientId: patientRecord.id,
        organizationId: patientRecord.organizationId,
        firebaseUid: firebaseUser.uid,
        email: normalizedEmail,
        batch: activationBatch,
      );

      activationStage = 'تجهيز ملف المستخدم';

      await _userProfileRepository.linkPatientProfile(
        uid: firebaseUser.uid,
        email: normalizedEmail,
        patientId: patientRecord.id,
        doctorId: patientRecord.doctorId,
        organizationId: patientRecord.organizationId,
        batch: activationBatch,
      );

      activationStage = 'حفظ تغييرات Firestore';

      try {
        await activationBatch.commit();
        profileLinked = true;
      } catch (error) {
        if (error is FirebaseException &&
            error.code == 'permission-denied') {
          rethrow;
        }

        activationStage = 'التحقق من نتيجة حفظ Firestore';
        commitOutcomeUnknown = true;

        try {
          final persistedPatient =
          await _patientRepository.fetchPatientById(
            patientRecord.id,
            organizationId: patientRecord.organizationId,
          );

          final persistedProfile =
          await _userProfileRepository.fetchUserProfile(
            firebaseUser.uid,
          );

          profileLinked =
              persistedPatient?.accountActivated == true &&
                  persistedPatient?.firebaseUid == firebaseUser.uid &&
                  persistedProfile?.role == AccountRole.patient &&
                  persistedProfile?.email.trim().toLowerCase() ==
                      normalizedEmail &&
                  persistedProfile?.patientId == patientRecord.id &&
                  persistedProfile?.doctorId == patientRecord.doctorId &&
                  persistedProfile?.organizationId ==
                      patientRecord.organizationId;
        } catch (verificationError) {
          debugPrint(
            '[PatientActivation] Verification error: $verificationError',
          );
          rethrow;
        } finally {
          commitOutcomeUnknown = false;
        }

        if (!profileLinked) {
          rethrow;
        }
      }

      activationStage = 'التحقق من سجل المريض بعد التفعيل';

      final activatedPatient = await _patientRepository.fetchPatientById(
        patientRecord.id,
        organizationId: patientRecord.organizationId,
      );

      if (activatedPatient == null ||
          activatedPatient.firebaseUid != firebaseUser.uid ||
          !activatedPatient.accountActivated ||
          activatedPatient.status != AccountStatus.active) {
        throw StateError('تعذر التحقق من ربط سجل المريض بعد التفعيل.');
      }

      activationStage = 'التحقق من ملف المستخدم بعد التفعيل';

      final activatedProfile =
      await _userProfileRepository.fetchUserProfile(
        firebaseUser.uid,
      );

      if (activatedProfile == null ||
          activatedProfile.role != AccountRole.patient ||
          activatedProfile.email.trim().toLowerCase() != normalizedEmail ||
          activatedProfile.patientId != activatedPatient.id ||
          activatedProfile.organizationId !=
              activatedPatient.organizationId ||
          activatedProfile.doctorId != activatedPatient.doctorId ||
          activatedProfile.uid != firebaseUser.uid) {
        throw StateError('تعذر التحقق من ملف المستخدم بعد تفعيل المريض.');
      }

      activationStage = 'إنشاء جلسة المريض';

      final user = _authUserForPatient(
        activatedPatient,
        firebaseUser.uid,
      );

      _session = await _buildSession(firebaseUser);

      return (
      success: true,
      message: 'تم تفعيل حساب المريض بنجاح.',
      user: user,
      currentRole: AccountRole.patient,
      );
    } catch (error, stackTrace) {
      debugPrint('[PatientActivation] Failed stage: $activationStage');
      debugPrint('[PatientActivation] Error: $error');

      if (error is FirebaseException) {
        debugPrint('[PatientActivation] Firebase code: ${error.code}');
        debugPrint('[PatientActivation] Firebase message: ${error.message}');
      }

      debugPrint('[PatientActivation] Stack trace: $stackTrace');

      if (!profileLinked &&
          !commitOutcomeUnknown &&
          createdAuthAccount &&
          firebaseUser != null &&
          !(error is FirebaseException &&
              error.code == 'permission-denied')) {
        try {
          await firebaseUser.delete();
        } catch (deleteError) {
          debugPrint(
            '[PatientActivation] Account cleanup error: $deleteError',
          );

          try {
            await _firebaseAuth.signOut();
          } catch (signOutError) {
            debugPrint(
              '[PatientActivation] Sign-out error: $signOutError',
            );
          }
        }
      }

      final message = switch (error) {
        FirebaseAuthException exception =>
        exception.message ?? _mapFirebaseAuthError(exception),
        FirebaseException exception =>
        'فشل التفعيل في المرحلة: $activationStage '
            '(${exception.code}). ${exception.message ?? ''}',
        StateError stateError => stateError.message,
        FormatException formatException => formatException.message,
        _ => 'فشل تفعيل الحساب في المرحلة: $activationStage. $error',
      };

      return (
      success: false,
      message: message,
      user: null,
      currentRole: null,
      );
    }
  }

  void logout() {
    _firebaseAuth.signOut();
    _session = const AuthSession.signedOut();
  }
}