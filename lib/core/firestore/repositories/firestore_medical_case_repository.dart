import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/models/account_role.dart';
import '../../auth/models/account_status.dart';
import '../../auth/models/clinical_follow_up.dart';
import '../../auth/models/doctor.dart';
import '../../auth/models/medical_case.dart';
import '../../auth/models/pregnancy_details.dart';
import '../../auth/services/firebase_auth_repository.dart';
import '../appointment_date_time.dart';
import '../firestore_service.dart';
import 'firestore_appointment_repository.dart';
import 'firestore_doctor_repository.dart';
import 'firestore_organization_repository.dart';
import 'firestore_patient_repository.dart';

class FirestoreMedicalCaseRepository {
  FirestoreMedicalCaseRepository._({FirestoreService? service})
      : _service = service ?? FirestoreService();

  static final instance = FirestoreMedicalCaseRepository._();

  final FirestoreService _service;

  Future<List<MedicalCase>> fetchCases({
    required String organizationId,
    required String patientId,
  }) async {
    Query<Map<String, dynamic>> query =
        _service.medicalCaseCollection(organizationId, patientId);
    final session = FirebaseAuthRepository.instance.session;
    if (session.currentRole == AccountRole.doctor) {
      final doctorId = session.doctorId;
      if (doctorId == null || doctorId.isEmpty) {
        throw StateError('لا توجد هوية طبيب مرتبطة بالجلسة الحالية.');
      }
      final doctor = await FirestoreDoctorRepository.instance
          .fetchDoctorByIdForOrganization(organizationId, doctorId);
      final clinicId = doctor?.clinicId;
      if (doctor == null || clinicId == null || clinicId.isEmpty) {
        throw StateError('لا توجد عيادة نشطة مرتبطة بالطبيب الحالي.');
      }
      query = query
          .where('doctorId', isEqualTo: doctorId)
          .where('clinicId', isEqualTo: clinicId);
    }
    final snapshot = await query.get();

    final cases = snapshot.docs.map((document) {
      final medicalCase = MedicalCase.fromMap(document.id, document.data());
      _validateCasePath(medicalCase, organizationId, patientId);
      return medicalCase;
    }).toList();
    cases.sort((first, second) => second.startedAt.compareTo(first.startedAt));
    return cases;
  }

  Future<MedicalCase?> fetchCase({
    required String organizationId,
    required String patientId,
    required String caseId,
  }) async {
    final snapshot = await _service
        .medicalCaseDocument(organizationId, patientId, caseId)
        .get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final medicalCase = MedicalCase.fromMap(snapshot.id, snapshot.data()!);
    _validateCasePath(medicalCase, organizationId, patientId);
    return medicalCase;
  }

  Future<List<ClinicalFollowUp>> fetchFollowUps({
    required MedicalCase medicalCase,
  }) async {
    final snapshot = await _service
        .clinicalFollowUpCollection(
          medicalCase.organizationId,
          medicalCase.patientId,
          medicalCase.id,
        )
      .where('doctorId', isEqualTo: medicalCase.doctorId)
        .get();

    final followUps = snapshot.docs.map((document) {
      final followUp = ClinicalFollowUp.fromMap(
        document.id,
        document.data(),
      );
      if (followUp.caseId != medicalCase.id ||
          followUp.patientId != medicalCase.patientId ||
          followUp.organizationId != medicalCase.organizationId ||
          followUp.doctorId != medicalCase.doctorId ||
          followUp.clinicId != medicalCase.clinicId) {
        throw StateError('سجل المتابعة لا يطابق الحالة الطبية المرتبطة به.');
      }
      return followUp;
    }).toList();
    followUps.sort((first, second) => first.visitAt.compareTo(second.visitAt));
    return followUps;
  }

  Future<MedicalCase> createCase({
    required String organizationId,
    required String patientId,
    required String title,
    required String type,
    required DateTime startedAt,
    required String diagnosis,
    required String assessment,
    required String notes,
    required String treatmentPlan,
    PregnancyDetails? pregnancyDetails,
  }) async {
    final doctor = await _requireCurrentDoctor(organizationId);
    final patient = await FirestorePatientRepository.instance.fetchPatientById(
      patientId,
      organizationId: organizationId,
    );
    if (patient == null ||
        patient.organizationId != organizationId ||
        doctor.clinicId == null ||
        doctor.clinicId!.isEmpty) {
      throw StateError('لا يمكن فتح حالة خارج مرضى وعيادة الطبيب الحالي.');
    }
    if (title.trim().isEmpty || type.trim().isEmpty) {
      throw StateError('أدخل عنوان الحالة ونوعها.');
    }
    if ((type.trim() == 'pregnancy') != (pregnancyDetails != null)) {
      throw StateError('بيانات تأريخ الحمل مطلوبة لحالة الحمل فقط.');
    }
    if (startedAt.isAfter(DateTime.now())) {
      throw StateError('لا يمكن أن يبدأ السجل الطبي بتاريخ مستقبلي.');
    }

    PregnancyDetails? normalizedPregnancy;
    if (pregnancyDetails != null) {
      final method = pregnancyDetails.datingMethod;
      final weeks = pregnancyDetails.gestationalWeeksAtReference;
      final days = pregnancyDetails.gestationalDaysAtReference;
      final hasValidAge = weeks >= 0 &&
          weeks <= 42 &&
          days >= 0 &&
          days <= 6 &&
          (weeks < 42 || days == 0);
      final usesAgeOnly =
          method == PregnancyDatingMethod.gestationalAgeAtReference;
      if (!hasValidAge ||
          (!usesAgeOnly && (weeks != 0 || days != 0)) ||
          (usesAgeOnly && weeks == 0 && days == 0) ||
          pregnancyDetails.referenceDate.isAfter(DateTime.now())) {
        throw StateError('بيانات تأريخ الحمل غير صالحة.');
      }
      normalizedPregnancy = PregnancyDetails.fromReference(
        datingMethod: method,
        referenceDate: pregnancyDetails.referenceDate,
        gestationalWeeks: weeks,
        gestationalDays: days,
      );
    }

    final reference = _service
        .medicalCaseCollection(organizationId, patientId)
        .doc();
    final data = <String, dynamic>{
      'id': reference.id,
      'patientId': patientId,
      'organizationId': organizationId,
      'doctorId': doctor.id,
      'clinicId': doctor.clinicId,
      'title': title.trim(),
      'type': type.trim(),
      'startedAt': Timestamp.fromDate(startedAt),
      'diagnosis': diagnosis.trim(),
      'assessment': assessment.trim(),
      'notes': notes.trim(),
      'treatmentPlan': treatmentPlan.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      if (normalizedPregnancy != null)
        'pregnancy': normalizedPregnancy.toMap(),
    };
    await reference.set(data);

    return MedicalCase.fromMap(reference.id, {
      ...data,
      'createdAt': DateTime.now(),
    });
  }

  Future<ClinicalFollowUp> createFollowUp({
    required MedicalCase medicalCase,
    required DateTime visitAt,
    required String assessment,
    required String notes,
    required String recommendations,
    required String nextPlan,
    String? appointmentId,
  }) async {
    final doctor = await _requireCurrentDoctor(medicalCase.organizationId);
    if (medicalCase.doctorId != doctor.id ||
      doctor.clinicId != medicalCase.clinicId ||
      medicalCase.isClosed) {
      throw StateError('الحالة غير نشطة أو لا تتبع الطبيب الحالي.');
    }
    if (visitAt.isAfter(DateTime.now())) {
      throw StateError('تاريخ المتابعة السريرية لا يمكن أن يكون مستقبليًا.');
    }

    final patient = await FirestorePatientRepository.instance.fetchPatientById(
      medicalCase.patientId,
      organizationId: medicalCase.organizationId,
    );
    if (patient == null ||
        patient.organizationId != medicalCase.organizationId) {
      throw StateError('تعذر التحقق من ربط الحالة بالمريض والطبيب والعيادة.');
    }

    final normalizedAppointmentId = appointmentId?.trim();
    if (normalizedAppointmentId != null && normalizedAppointmentId.isNotEmpty) {
      final appointment = await FirestoreAppointmentRepository.instance
          .fetchAppointmentById(
        medicalCase.organizationId,
        normalizedAppointmentId,
      );
      final appointmentAt = appointment == null
          ? null
          : parseAppointmentDateTime(appointment['date'], appointment['time']);
      if (appointment == null ||
          appointment['status'] != 'completed' ||
          appointment['date'] is! Timestamp ||
          appointmentAt == null ||
          appointmentAt.isAfter(DateTime.now()) ||
          appointmentAt.year != visitAt.year ||
          appointmentAt.month != visitAt.month ||
          appointmentAt.day != visitAt.day ||
          appointment['organizationId'] != medicalCase.organizationId ||
          appointment['patientId'] != medicalCase.patientId ||
          appointment['doctorId'] != medicalCase.doctorId ||
          appointment['clinicId'] != medicalCase.clinicId) {
        throw StateError('يمكن ربط المتابعة بموعد مكتمل سابق مطابق فقط.');
      }
    }

    final reference = _service
        .clinicalFollowUpCollection(
          medicalCase.organizationId,
          medicalCase.patientId,
          medicalCase.id,
        )
        .doc();
    final data = <String, dynamic>{
      'id': reference.id,
      'caseId': medicalCase.id,
      'patientId': medicalCase.patientId,
      'organizationId': medicalCase.organizationId,
      'doctorId': doctor.id,
      'clinicId': medicalCase.clinicId,
      'visitAt': Timestamp.fromDate(visitAt),
      'assessment': assessment.trim(),
      'notes': notes.trim(),
      'recommendations': recommendations.trim(),
      'nextPlan': nextPlan.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (normalizedAppointmentId != null && normalizedAppointmentId.isNotEmpty)
        'appointmentId': normalizedAppointmentId,
    };
    await reference.set(data);

    return ClinicalFollowUp.fromMap(reference.id, {
      ...data,
      'createdAt': DateTime.now(),
    });
  }

  Future<void> updateCaseStatus({
    required MedicalCase medicalCase,
    required String status,
  }) async {
    if (status != 'monitoring' &&
        status != 'completed' &&
        status != 'archived') {
      throw ArgumentError.value(status, 'status');
    }
    if (medicalCase.type == 'pregnancy' && status == 'archived') {
      throw StateError('تتم أرشفة حالة الحمل تلقائيًا بعد انتهاء الفترة المحددة.');
    }
    final doctor = await _requireCurrentDoctor(medicalCase.organizationId);
    final allowedTransition = switch (status) {
      'monitoring' => medicalCase.status == 'active',
      'completed' =>
        medicalCase.status == 'active' || medicalCase.status == 'monitoring',
      'archived' =>
        medicalCase.status == 'active' ||
            medicalCase.status == 'monitoring' ||
            medicalCase.status == 'completed',
      _ => false,
    };
    if (medicalCase.doctorId != doctor.id ||
      doctor.clinicId != medicalCase.clinicId ||
        !allowedTransition) {
      throw StateError('لا يمكن تغيير حالة هذا السجل.');
    }

    final updates = <String, dynamic>{
      'status': status,
      if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      if (status == 'archived') 'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _service
        .medicalCaseDocument(
          medicalCase.organizationId,
          medicalCase.patientId,
          medicalCase.id,
        )
        .update(updates);
  }

  Future<Doctor> _requireCurrentDoctor(String organizationId) async {
    final session = FirebaseAuthRepository.instance.session;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doctorId = session.doctorId;
    if (!session.isAuthenticated ||
        session.currentRole != AccountRole.doctor ||
        uid == null ||
        session.currentUser?.id != uid ||
        session.organizationId != organizationId ||
        doctorId == null ||
        doctorId.isEmpty) {
      throw StateError('يتطلب هذا الإجراء جلسة طبيب موثقة.');
    }

    final doctor = await FirestoreDoctorRepository.instance
        .fetchDoctorByIdForOrganization(organizationId, doctorId);
    final organization = await FirestoreOrganizationRepository.instance
      .fetchOrganizationById(organizationId);
    if (doctor == null ||
      organization == null ||
      organization.status != AccountStatus.active ||
        doctor.firebaseUid != uid ||
        doctor.organizationId != organizationId ||
        doctor.status != AccountStatus.active) {
      throw StateError('الطبيب أو المؤسسة غير نشطين.');
    }
    return doctor;
  }

  void _validateCasePath(
    MedicalCase medicalCase,
    String organizationId,
    String patientId,
  ) {
    if (medicalCase.patientId != patientId ||
        medicalCase.organizationId != organizationId ||
        medicalCase.id.isEmpty) {
      throw StateError('سجل الحالة لا يطابق مسار المريض والمؤسسة.');
    }
  }
}