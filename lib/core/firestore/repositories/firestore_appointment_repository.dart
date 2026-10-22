import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../appointment_date_time.dart';
import '../firestore_service.dart';
import '../../auth/models/account_role.dart';
import '../../auth/services/firebase_auth_repository.dart';
import 'firestore_doctor_repository.dart';
import 'firestore_user_profile_repository.dart';

class FirestoreAppointmentRepository {
  FirestoreAppointmentRepository._({FirestoreService? service})
      : _service = service ?? FirestoreService();

  static final instance = FirestoreAppointmentRepository._();

  final FirestoreService _service;

  Future<Map<String, dynamic>?> fetchAppointmentById(
      String organizationId,
      String appointmentId,
      ) async {
    final snapshot = await _service
        .appointmentDocument(organizationId, appointmentId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final appointment = snapshot.data()!;

    if (appointment['organizationId'] != null &&
        appointment['organizationId'] != organizationId) {
      throw StateError(
        'This appointment belongs to a different organization and cannot be read here.',
      );
    }

    return {
      ...appointment,
      'id': snapshot.id,
    };
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(
      String organizationId,
      {String? clinicId,}
      ) async {
    Query<Map<String, dynamic>> query = _service
        .appointmentCollection(organizationId)
        .where(
      'organizationId',
      isEqualTo: organizationId,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (clinicId != null && clinicId.isNotEmpty) {
      query = query.where('clinicId', isEqualTo: clinicId);
    } else if (uid != null && uid.isNotEmpty) {
      final profile = await FirestoreUserProfileRepository().fetchUserProfile(uid);
      if (profile?.role.name == 'organization' &&
          profile?.clinicId != null &&
          profile!.clinicId!.isNotEmpty) {
        query = query.where('clinicId', isEqualTo: profile.clinicId);
      }
    }
    final snapshot = await query.get();

    return snapshot.docs
        .map(
          (document) => {
        ...document.data(),
        'id': document.id,
      },
    )
        .where(
          (appointment) =>
      appointment['organizationId'] == null ||
          appointment['organizationId'] == organizationId,
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForOrganization(
      String organizationId, {
      String? clinicId,
      }
      ) {
    return fetchAppointments(organizationId, clinicId: clinicId);
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForPatient({
    required String organizationId,
    required String patientId,
    required String patientUid,
  }) async {
    final snapshot = await _service
        .appointmentCollection(organizationId)
        .where(
      'organizationId',
      isEqualTo: organizationId,
    )
        .where(
      'patientId',
      isEqualTo: patientId,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => {
        ...document.data(),
        'id': document.id,
      },
    )
        .where(
          (appointment) =>
      appointment['organizationId'] == organizationId &&
          appointment['patientId'] == patientId &&
          (appointment['patientUid'] == null ||
              appointment['patientUid'] == patientUid),
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForDoctor({
    required String organizationId,
    required String doctorId,
  }) async {
    final session = FirebaseAuthRepository.instance.session;
    if (session.currentRole != AccountRole.doctor ||
        session.organizationId != organizationId ||
        session.doctorId != doctorId) {
      return const [];
    }
    final doctor = await FirestoreDoctorRepository.instance
        .fetchDoctorByIdForOrganization(organizationId, doctorId);
    final clinicId = doctor?.clinicId;
    if (doctor == null || clinicId == null || clinicId.trim().isEmpty) {
      return const [];
    }

    final snapshot = await _service
        .appointmentCollection(organizationId)
        .where(
      'organizationId',
      isEqualTo: organizationId,
    )
        .where(
      'doctorId',
      isEqualTo: doctorId,
    )
        .where(
      'clinicId',
      whereIn: [clinicId, null],
    )
        .get();

    return snapshot.docs
        .map(
          (document) => {
        ...document.data(),
        'id': document.id,
      },
    )
        .where((appointment) =>
          appointment['clinicId'] == null ||
          appointment['clinicId'] == clinicId)
        .toList();
  }

  Future<Map<String, dynamic>> createAppointment({
    required String organizationId,
    required Map<String, dynamic> appointment,
  }) async {
    final requestedOrganizationId =
        (appointment['organizationId'] as String?) ?? organizationId;

    if (requestedOrganizationId != organizationId) {
      throw StateError(
        'Appointment organization cannot be changed from the client.',
      );
    }

    final scheduledAt = parseAppointmentDateTime(
      appointment['date'],
      appointment['time'],
    );
    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
      throw StateError('يجب أن يكون الموعد بتاريخ ووقت قادمين.');
    }

    final reference =
    _service.appointmentCollection(organizationId).doc();

    final safeAppointment = <String, dynamic>{
      ...appointment,
      'id': reference.id,
      'organizationId': organizationId,
      'date': Timestamp.fromDate(scheduledAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await reference.set(safeAppointment);

    return safeAppointment;
  }

  Future<void> saveAppointment({
    required String organizationId,
    required Map<String, dynamic> appointment,
  }) async {
    final appointmentId =
    (appointment['id'] as String? ?? '').trim();

    if (appointmentId.isEmpty) {
      throw StateError(
        'Appointment id is required before saving to Firestore.',
      );
    }

    final requestedOrganizationId =
        (appointment['organizationId'] as String?) ?? organizationId;

    if (requestedOrganizationId != organizationId) {
      throw StateError(
        'Appointment organization cannot be changed from the client.',
      );
    }

    final safeAppointment = <String, dynamic>{
      ...appointment,
      'id': appointmentId,
      'organizationId': organizationId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (appointment.containsKey('date') || appointment.containsKey('time')) {
      final reference = _service.appointmentDocument(
        organizationId,
        appointmentId,
      );
      final current = await reference.get();
      final currentData = current.data();
      if (!current.exists || currentData == null) {
        throw StateError('لم يتم العثور على الموعد المطلوب لإعادة جدولته.');
      }

      final scheduledAt = parseAppointmentDateTime(
        appointment['date'] ?? currentData['date'],
        appointment['time'] ?? currentData['time'],
      );
      if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
        throw StateError('يجب أن يكون الموعد المعاد جدولته في المستقبل.');
      }

      safeAppointment['date'] = Timestamp.fromDate(scheduledAt);
      safeAppointment['time'] = appointment['time'] ?? currentData['time'];
      safeAppointment['status'] = 'upcoming';
    }

    if (safeAppointment['status'] == 'completed') {
      final current = await _service
          .appointmentDocument(organizationId, appointmentId)
          .get();
      final currentData = current.data();
      final scheduledAt = parseAppointmentDateTime(
        currentData?['date'],
        currentData?['time'],
      );
      if (currentData?['date'] is! Timestamp ||
          scheduledAt == null ||
          scheduledAt.isAfter(DateTime.now())) {
        throw StateError('لا يمكن إكمال موعد لم يحن وقته أو لم يتم التحقق من وقته.');
      }
    }

    await _service
        .appointmentDocument(
      organizationId,
      appointmentId,
    )
        .set(
      safeAppointment,
      SetOptions(merge: true),
    );
  }

  Future<void> updateAppointmentStatus({
    required String organizationId,
    required String appointmentId,
    required String status,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus != 'completed' &&
        normalizedStatus != 'cancelled' &&
        normalizedStatus != 'upcoming') {
      throw StateError(
        'حالة الموعد غير صالحة.',
      );
    }

    if (appointmentId.trim().isEmpty) {
      throw StateError(
        'معرّف الموعد مطلوب.',
      );
    }

    if (normalizedStatus == 'completed') {
      final appointment = await fetchAppointmentById(
        organizationId,
        appointmentId,
      );
      final scheduledAt = parseAppointmentDateTime(
        appointment?['date'],
        appointment?['time'],
      );
      if (appointment == null ||
          appointment['date'] is! Timestamp ||
          scheduledAt == null ||
          scheduledAt.isAfter(DateTime.now())) {
        throw StateError('لا يمكن إكمال موعد لم يحن وقته أو لم يتم التحقق من وقته.');
      }
    }

    await _service
        .appointmentDocument(
      organizationId,
      appointmentId,
    )
        .set(
      {
        'status': normalizedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markAppointmentCompleted({
    required String organizationId,
    required String appointmentId,
  }) {
    return updateAppointmentStatus(
      organizationId: organizationId,
      appointmentId: appointmentId,
      status: 'completed',
    );
  }

  Future<void> cancelAppointment({
    required String organizationId,
    required String appointmentId,
  }) {
    return updateAppointmentStatus(
      organizationId: organizationId,
      appointmentId: appointmentId,
      status: 'cancelled',
    );
  }

  Future<void> deleteAppointment({
    required String organizationId,
    required String appointmentId,
  }) async {
    await _service
        .appointmentDocument(
      organizationId,
      appointmentId,
    )
        .delete();
  }

  DocumentReference<Map<String, dynamic>> appointmentDocument(
      String organizationId,
      String appointmentId,
      ) {
    return _service.appointmentDocument(
      organizationId,
      appointmentId,
    );
  }

  DocumentReference<Map<String, dynamic>> appointmentDocumentForPaths(
      String organizationId,
      String appointmentId,
      ) {
    return _service.appointmentDocument(
      organizationId,
      appointmentId,
    );
  }
}