import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_service.dart';
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
        .get();

    return snapshot.docs
        .map(
          (document) => {
        ...document.data(),
        'id': document.id,
      },
    )
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

    final reference =
    _service.appointmentCollection(organizationId).doc();

    final safeAppointment = <String, dynamic>{
      ...appointment,
      'id': reference.id,
      'organizationId': organizationId,
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