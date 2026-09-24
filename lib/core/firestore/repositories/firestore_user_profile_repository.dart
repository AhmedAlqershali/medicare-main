import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../auth/models/account_role.dart';
import '../firestore_service.dart';
import '../models/user_profile.dart';

class FirestoreUserProfileRepository {
  FirestoreUserProfileRepository({FirestoreService? service}) : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final path = 'users/$uid';
    debugPrint('[FirestoreDiagnostic] user profile request: uid=$uid, projectId=${Firebase.apps.isEmpty ? 'unavailable' : Firebase.app().options.projectId}, path=$path, operation=document.get');
    try {
      final snapshot = await _service.userDocument(uid).get();
      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('[FirestoreDiagnostic] user profile result: exists=false, role=null, organizationId=null, clinicId=null');
        return null;
      }
      final profile = UserProfile.fromMap(snapshot.data()!);
      debugPrint('[FirestoreDiagnostic] user profile result: exists=true, role=${profile.role.name}, organizationId=${profile.organizationId}, clinicId=${profile.clinicId}, doctorId=${profile.doctorId}, patientId=${profile.patientId}');
      return profile;
    } on FirebaseException catch (error) {
      debugPrint('[FirestoreDiagnostic] user profile request failed: code=${error.code}, message=${error.message}');
      rethrow;
    }
  }

  Future<UserProfile> createOrUpdateUserProfile({
    required String uid,
    required String email,
    required AccountRole role,
    String? organizationId,
    String? clinicId,
    String? invitationId,
    String? doctorId,
    String? patientId,
  }) async {
    final now = DateTime.now();
    final existing = await fetchUserProfile(uid);
    final profile = UserProfile(
      uid: uid,
      email: email.trim().toLowerCase(),
      role: role,
      organizationId: organizationId,
      clinicId: clinicId,
      doctorId: doctorId,
      patientId: patientId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final profileMap = profile.toMap();
    if (invitationId != null) profileMap['invitationId'] = invitationId;
    await _service.userDocument(uid).set(profileMap, SetOptions(merge: true));
    return profile;
  }

  Future<void> linkPatientProfile({
    required String uid,
    required String email,
    required String patientId,
    required String doctorId,
    required String organizationId,
  }) async {
    await _service.userDocument(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'patientId': patientId,
      'doctorId': doctorId,
      'organizationId': organizationId,
      'role': AccountRole.patient.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> linkDoctorProfile({
    required String uid,
    required String email,
    required String doctorId,
    required String organizationId,
  }) async {
    await _service.userDocument(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'doctorId': doctorId,
      'organizationId': organizationId,
      'role': AccountRole.doctor.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> linkOrganizationProfile({
    required String uid,
    required String email,
    required String organizationId,
    String? clinicId,
    String? invitationId,
  }) async {
    final profile = <String, dynamic>{
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'organizationId': organizationId,
      'clinicId': clinicId,
      'role': AccountRole.organization.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (invitationId != null) profile['invitationId'] = invitationId;
    await _service.userDocument(uid).set(profile, SetOptions(merge: true));
  }
}
