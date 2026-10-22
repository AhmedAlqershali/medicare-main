import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_service.dart';

class MedicalServiceUsage {
  const MedicalServiceUsage({
    required this.lastServiceAt,
    required this.nextEligibleAt,
  });

  final DateTime? lastServiceAt;
  final DateTime? nextEligibleAt;
}

class FirestoreMedicalServiceRepository {
  FirestoreMedicalServiceRepository._({FirestoreService? service})
      : _service = service ?? FirestoreService();

  static final instance = FirestoreMedicalServiceRepository._();
  final FirestoreService _service;

  Future<MedicalServiceUsage> fetchUsage({
    required String organizationId,
    required String patientId,
    required String serviceId,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('getMedicalServiceUsage');
    final response = await callable.call(<String, Object?>{
      'organizationId': organizationId,
      'patientId': patientId,
      'serviceId': serviceId,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return MedicalServiceUsage(
      lastServiceAt: _date(data?['lastServiceAt']),
      nextEligibleAt: _date(data?['nextEligibleAt']),
    );
  }

  Future<bool> hasRepeatOverridePermission({
    required String organizationId,
    required String doctorId,
  }) async {
    final snapshot = await _service
        .medicalServiceOverridePermissionDocument(organizationId, doctorId)
        .get();
    return snapshot.data()?['active'] == true;
  }

  Future<bool> canManageRepeatOverride(String organizationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final admin = await _service.firestore.collection('admins').doc(uid).get();
    if (admin.data()?['role'] == 'admin' && admin.data()?['active'] == true) {
      return true;
    }
    final organization = await _service.organizationDocument(organizationId).get();
    final data = organization.data();
    return data?['status'] == 'active' &&
        (data?['firebaseUid'] == uid || data?['ownerUid'] == uid);
  }

  Future<void> completeAppointment({
    required String organizationId,
    required String appointmentId,
    String? overrideReason,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('completeAppointmentWithService');
    await callable.call(<String, Object?>{
      'organizationId': organizationId,
      'appointmentId': appointmentId,
      if (overrideReason != null && overrideReason.trim().isNotEmpty)
        'overrideReason': overrideReason.trim(),
    });
  }

  Future<void> setRepeatOverridePermission({
    required String organizationId,
    required String doctorId,
    required bool active,
    required String changedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || uid != changedBy ||
        !await canManageRepeatOverride(organizationId)) {
      throw StateError('إدارة استثناء تكرار الخدمة متاحة لمالك المؤسسة أو المسؤول فقط.');
    }
    await _service.medicalServiceOverridePermissionDocument(
      organizationId,
      doctorId,
    ).set({
      'doctorId': doctorId,
      'permission': 'service_repeat_override',
      'active': active,
      'changedBy': changedBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (active) 'grantedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DateTime? _date(Object? value) => switch (value) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime date => date,
      String date => DateTime.tryParse(date),
        _ => null,
      };
}
