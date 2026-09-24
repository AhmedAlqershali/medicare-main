import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../firestore_service.dart';

class FirestoreAppointmentRepository {
  FirestoreAppointmentRepository._({FirestoreService? service}) : _service = service ?? FirestoreService();

  static final instance = FirestoreAppointmentRepository._();

  final FirestoreService _service;

  Future<Map<String, dynamic>?> fetchAppointmentById(String organizationId, String appointmentId) async {
    final snapshot = await _service.appointmentDocument(organizationId, appointmentId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final appointment = snapshot.data()!;
    if (appointment['organizationId'] != null && appointment['organizationId'] != organizationId) {
      throw StateError('This appointment belongs to a different organization and cannot be read here.');
    }
    return {...appointment, 'id': snapshot.id};
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(String organizationId) async {
    final snapshot = await _service.appointmentCollection(organizationId).where('organizationId', isEqualTo: organizationId).get();
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .where((appointment) => appointment['organizationId'] == null || appointment['organizationId'] == organizationId)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForOrganization(String organizationId) => fetchAppointments(organizationId);

  Future<List<Map<String, dynamic>>> fetchAppointmentsForPatient({required String organizationId, required String patientId, required String patientUid}) async {
    final snapshot = await _service.appointmentCollection(organizationId)
        .where('organizationId', isEqualTo: organizationId)
        .where('patientId', isEqualTo: patientId)
        .where('patientUid', isEqualTo: patientUid)
        .get();
    return snapshot.docs.map((document) => {...document.data(), 'id': document.id}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForDoctor({required String organizationId, required String doctorId}) async {
    final snapshot = await _service.appointmentCollection(organizationId)
        .where('organizationId', isEqualTo: organizationId)
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs.map((document) => {...document.data(), 'id': document.id}).toList();
  }

  Future<Map<String, dynamic>> createAppointment({required String organizationId, required Map<String, dynamic> appointment}) async {
    final requestedOrganizationId = (appointment['organizationId'] as String?) ?? organizationId;
    if (requestedOrganizationId != organizationId) {
      throw StateError('Appointment organization cannot be changed from the client.');
    }

    final reference = _service.appointmentCollection(organizationId).doc();
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

  Future<void> saveAppointment({required String organizationId, required Map<String, dynamic> appointment}) async {
    final appointmentId = (appointment['id'] as String? ?? '').trim();
    if (appointmentId.isEmpty) {
      throw StateError('Appointment id is required before saving to Firestore.');
    }

    final requestedOrganizationId = (appointment['organizationId'] as String?) ?? organizationId;
    if (requestedOrganizationId != organizationId) {
      throw StateError('Appointment organization cannot be changed from the client.');
    }

    final safeAppointment = <String, dynamic>{
      ...appointment,
      'id': appointmentId,
      'organizationId': organizationId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _service.appointmentDocument(organizationId, appointmentId).set(safeAppointment, SetOptions(merge: true));
  }

  Future<void> deleteAppointment({required String organizationId, required String appointmentId}) async {
    await _service.appointmentDocument(organizationId, appointmentId).delete();
  }

  DocumentReference<Map<String, dynamic>> appointmentDocument(String organizationId, String appointmentId) =>
      _service.appointmentDocument(organizationId, appointmentId);

  DocumentReference<Map<String, dynamic>> appointmentDocumentForPaths(String organizationId, String appointmentId) =>
      _service.appointmentDocument(organizationId, appointmentId);
}
