import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../auth/models/account_status.dart';
import '../../auth/repositories/doctor_repository.dart';
import '../../auth/models/patient.dart';
import '../../auth/repositories/patient_repository.dart';
import '../../auth/services/firebase_auth_repository.dart';
import '../firestore_service.dart';
import 'firestore_doctor_repository.dart';

class FirestorePatientRepository implements PatientRepository {
  FirestorePatientRepository._({
    FirestoreService? service,
    DoctorRepository? doctorRepository,
  })  : _service = service ?? FirestoreService(),
        _doctorRepository =
            doctorRepository ?? FirestoreDoctorRepository.instance;

  static final instance = FirestorePatientRepository._();

  final FirestoreService _service;
  final DoctorRepository _doctorRepository;

  @override
  Future<List<Patient>> patientsForDoctor(
      String doctorId, {
        String? organizationId,
      }) =>
      fetchPatientsForDoctor(
        doctorId,
        organizationId: organizationId,
      );

  Future<List<Patient>> fetchPatientsForDoctor(
      String doctorId, {
        String? organizationId,
      }) async {
    final doctor = await _doctorRepository.doctorForId(
      doctorId,
      organizationId: organizationId,
    );

    if (doctor == null || doctor.organizationId.isEmpty) {
      return [];
    }

    final snapshot = await _service
        .patientCollectionForOrganization(doctor.organizationId)
        .where(
      'organizationId',
      isEqualTo: doctor.organizationId,
    )
        .where(
      'doctorId',
      isEqualTo: doctor.id,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => Patient.fromMap({
        ...document.data(),
        'id': document.id,
      }),
    )
        .toList();
  }

  Future<List<Patient>> fetchPatientsForOrganization(
      String organizationId,
      ) async {
    if (organizationId.trim().isEmpty) {
      throw StateError('Organization id is required to read patients.');
    }

    final path = 'organizations/$organizationId/patients';

    debugPrint(
      '[FirestoreDiagnostic] patients request: '
          'uid=${FirebaseAuth.instance.currentUser?.uid}, '
          'projectId=${Firebase.apps.isEmpty ? 'unavailable' : Firebase.app().options.projectId}, '
          'organizationId=$organizationId, '
          'sessionRole=${FirebaseAuthRepository.instance.session.currentRole?.name}, '
          'path=$path, '
          'operation=collection.get',
    );

    try {
      final snapshot = await _service
          .patientCollectionForOrganization(organizationId)
          .get();

      return snapshot.docs
          .map(
            (document) => Patient.fromMap({
          ...document.data(),
          'id': document.id,
        }),
      )
          .toList();
    } on FirebaseException catch (error) {
      debugPrint(
        '[FirestoreDiagnostic] patients request failed: '
            'code=${error.code}, message=${error.message}',
      );
      rethrow;
    }
  }

  @override
  Future<Patient?> patientForId(
      String patientId, {
        String? organizationId,
      }) =>
      fetchPatientById(
        patientId,
        organizationId: organizationId,
      );

  @override
  Future<Patient> createPatient({
    required String doctorId,
    required String name,
    required String email,
    required String invitedBy,
    String? organizationId,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
  }) async {
    final doctor = await _doctorRepository.doctorForId(
      doctorId,
      organizationId: organizationId,
    );

    final trimmedEmail = email.trim().toLowerCase();

    if (doctor == null || doctor.organizationId.isEmpty) {
      throw StateError(
        'لم يتم العثور على مؤسسة الطبيب قبل إنشاء سجل المريض.',
      );
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null ||
        currentUid.isEmpty ||
        doctor.firebaseUid != currentUid) {
      throw StateError(
        'حساب الطبيب الحالي غير مرتبط بسجل الطبيب المطلوب.',
      );
    }

    if (organizationId != null &&
        organizationId.trim().isNotEmpty &&
        doctor.organizationId != organizationId.trim()) {
      throw StateError(
        'لا يمكن إنشاء المريض خارج مؤسسة الطبيب الحالية.',
      );
    }

    final now = DateTime.now();

    final patientReference = _service
        .patientCollectionForOrganization(doctor.organizationId)
        .doc();

    final appointmentReference = _service
        .appointmentCollection(doctor.organizationId)
        .doc();

    final patient = Patient(
      id: patientReference.id,
      name: name.trim(),
      email: trimmedEmail,
      doctorId: doctorId,
      organizationId: doctor.organizationId,
      clinicId: doctor.clinicId,
      status: AccountStatus.pending,
      accountActivated: false,
      initials: _initials(name),
      firebaseUid: null,
      createdAt: now,
      updatedAt: now,
    );

    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      appointmentTime.hour,
      appointmentTime.minute,
    );

    final appointment = <String, dynamic>{
      'id': appointmentReference.id,
      'organizationId': doctor.organizationId,
      'doctorId': doctorId,
      'patientId': patient.id,
      'patientUid': null,
      'patientName': patient.name,
      'patientInitials': patient.initials,
      'clinicId': doctor.clinicId,
      'date': _formatDate(appointmentDateTime),
      'time': _formatTime(appointmentTime),
      'type': 'زيارة',
      'status': 'upcoming',
      'notes': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': invitedBy,
    };

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      patientReference,
      patient.toMap(),
    );

    batch.set(
      appointmentReference,
      appointment,
    );

    await batch.commit();

    return patient;
  }

  Future<Patient?> fetchPatientById(
      String patientId, {
        String? organizationId,
      }) async {
    if (organizationId == null ||
        organizationId.trim().isEmpty) {
      return null;
    }

    final snapshot = await _service
        .patientDocumentForOrganization(
      organizationId,
      patientId,
    )
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return Patient.fromMap({
      ...snapshot.data()!,
      'id': snapshot.id,
    });
  }

  /// Finds the pending patient record that matches the supplied email.
  ///
  /// This is used during the first patient account activation, before
  /// users/{uid} exists.
  Future<Patient?> fetchPendingPatientByEmail(
      String email,
      ) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return null;
    }

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('patients')
        .where(
      'email',
      isEqualTo: normalizedEmail,
    )
        .where('status', isEqualTo: AccountStatus.pending.name)
        .where('accountActivated', isEqualTo: false)
        .where('firebaseUid', isEqualTo: null)
        .get();

    Patient? pendingPatient;

    for (final document in snapshot.docs) {
      final data = document.data();

      final accountActivated =
          data['accountActivated'] == true;
      final status = data['status']?.toString();

      final firebaseUid =
      data['firebaseUid']?.toString();

      if (status == AccountStatus.pending.name &&
          !accountActivated &&
          (firebaseUid == null || firebaseUid.isEmpty)) {
        final organizationId = document.reference.parent.parent?.id;
        if (organizationId == null ||
            data['organizationId'] != organizationId ||
            data['doctorId'] is! String ||
            (data['doctorId'] as String).isEmpty ||
            data['id'] != document.id) {
          throw StateError('بيانات سجل المريض غير مكتملة أو غير متطابقة.');
        }
        if (pendingPatient != null) {
          throw StateError(
            'يوجد أكثر من سجل مريض بنفس البريد الإلكتروني. '
                'يجب أن يكون البريد مرتبطًا بسجل مريض واحد فقط.',
          );
        }

        pendingPatient = Patient.fromMap({
          ...data,
          'id': document.id,
        });
      }
    }

    return pendingPatient;
  }

  Future<void> savePatient(Patient patient) async {
    await _service
        .patientDocumentForOrganization(
      patient.organizationId,
      patient.id,
    )
        .set(
      patient.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> updatePatientProfile({
    required String patientId,
    required String organizationId,
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
  }) async {
    if (patientId.trim().isEmpty) {
      throw StateError(
        'Patient id is required before saving the profile.',
      );
    }

    final patient = await fetchPatientById(
      patientId,
      organizationId: organizationId,
    );

    if (patient == null) {
      throw StateError(
        'لم يتم العثور على سجل المريض المطلوب.',
      );
    }

    await _service
        .patientDocumentForOrganization(
      patient.organizationId,
      patient.id,
    )
        .set(
      {
        'name': name.trim(),
        'phone': phone.trim(),
        'birthDate': birthDate.trim(),
        'gender': gender.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> activatePatient({
    required String patientId,
    required String organizationId,
    required String firebaseUid,
    required String email,
    WriteBatch? batch,
  }) async {
    final patient = await fetchPatientById(
      patientId,
      organizationId: organizationId,
    );

    if (patient == null) {
      throw StateError(
        'لم يتم العثور على سجل المريض المطلوب.',
      );
    }

    if (patient.email.trim().toLowerCase() !=
        email.trim().toLowerCase()) {
      throw StateError(
        'بريد المريض غير مطابق للسجل الموجود.',
      );
    }

    if (patient.accountActivated) {
      if (patient.firebaseUid != firebaseUid) {
        throw StateError(
          'هذا المريض مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.',
        );
      }
      return;
    }

    if (patient.status != AccountStatus.pending) {
      throw StateError('سجل المريض ليس في حالة انتظار التفعيل.');
    }

    if (patient.firebaseUid != null) {
      throw StateError(
        'هذا الحساب مربوط بالفعل بمستخدم Firebase آخر ولا يمكن نقله.',
      );
    }

    final now = DateTime.now();

    final updatedPatient = Patient(
      id: patient.id,
      name: patient.name,
      email: patient.email,
      doctorId: patient.doctorId,
      organizationId: patient.organizationId,
      clinicId: patient.clinicId,
      status: patient.status,
      accountActivated: true,
      initials: patient.initials,
      phone: patient.phone,
      birthDate: patient.birthDate,
      gender: patient.gender,
      firebaseUid: firebaseUid,
      createdAt: patient.createdAt ?? now,
      updatedAt: now,
    );

    final activationBatch = batch ?? FirebaseFirestore.instance.batch();

    final patientReference = _service
        .patientDocumentForOrganization(
      updatedPatient.organizationId,
      updatedPatient.id,
    );

    activationBatch.set(
      patientReference,
      updatedPatient.toMap(),
      SetOptions(merge: true),
    );

    final appointmentsSnapshot = await _service
        .appointmentCollection(
      updatedPatient.organizationId,
    )
        .where(
      'patientId',
      isEqualTo: updatedPatient.id,
    )
        .get();

    for (final document in appointmentsSnapshot.docs) {
      final appointmentUid = document.data()['patientUid'];
      if (appointmentUid == null) {
        activationBatch.set(
          document.reference,
          {
            'patientUid': firebaseUid,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else if (appointmentUid != firebaseUid) {
        throw StateError(
          'موعد المريض مرتبط بالفعل بحساب Firebase مختلف.',
        );
      }
    }

    if (batch == null) await activationBatch.commit();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    final hour =
    time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute
        .toString()
        .padLeft(2, '0');

    final period =
    time.period == DayPeriod.am ? 'ص' : 'م';

    return '$hour:$minute $period';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1).toUpperCase()}'
        '${parts.last.substring(0, 1).toUpperCase()}';
  }
}