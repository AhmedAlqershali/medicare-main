import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get firestore => _firestore;

  String _organizationId(String organizationId) {
    return _documentId(organizationId, 'organizationId');
  }

  String _documentId(String value, String name) {
    final normalizedId = value.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(value, name, 'Document id must be non-empty.');
    }
    return normalizedId;
  }

  CollectionReference<Map<String, dynamic>> organizationCollection() => _firestore.collection('organizations');

  DocumentReference<Map<String, dynamic>> userDocument(String uid) => _firestore.collection('users').doc(_documentId(uid, 'uid'));

  CollectionReference<Map<String, dynamic>> doctorCollectionForOrganization(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('doctors');

  CollectionReference<Map<String, dynamic>> patientCollectionForOrganization(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('patients');

  CollectionReference<Map<String, dynamic>> clinicCollection(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('clinics');

  CollectionReference<Map<String, dynamic>> appointmentCollection(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('appointments');

  CollectionReference<Map<String, dynamic>> invitationCollection(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('invitations');

  DocumentReference<Map<String, dynamic>> organizationDocument(String organizationId) => _firestore.collection('organizations').doc(_organizationId(organizationId));

  DocumentReference<Map<String, dynamic>> clinicDocument(String organizationId, String clinicId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('clinics').doc(_documentId(clinicId, 'clinicId'));

  DocumentReference<Map<String, dynamic>> doctorDocumentForOrganization(String organizationId, String doctorId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('doctors').doc(_documentId(doctorId, 'doctorId'));

  DocumentReference<Map<String, dynamic>> patientDocumentForOrganization(String organizationId, String patientId) => _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('patients').doc(_documentId(patientId, 'patientId'));

  DocumentReference<Map<String, dynamic>> appointmentDocument(String organizationId, String appointmentId) =>
      _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('appointments').doc(_documentId(appointmentId, 'appointmentId'));

  DocumentReference<Map<String, dynamic>> invitationDocument(String organizationId, String invitationId) =>
      _firestore.collection('organizations').doc(_organizationId(organizationId)).collection('invitations').doc(_documentId(invitationId, 'invitationId'));
}
