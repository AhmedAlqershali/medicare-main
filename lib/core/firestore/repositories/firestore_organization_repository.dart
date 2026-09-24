import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/models/account_status.dart';
import '../../auth/models/organization.dart';
import '../../auth/repositories/organization_repository.dart';
import '../firestore_paths.dart';
import '../firestore_service.dart';

class FirestoreOrganizationRepository implements OrganizationRepository {
  FirestoreOrganizationRepository._({FirestoreService? service}) : _service = service ?? FirestoreService();

  static final instance = FirestoreOrganizationRepository._();

  final FirestoreService _service;

  @override
  Future<Organization?> currentOrganization({String? organizationId}) async {
    final normalizedOrganizationId = organizationId?.trim();
    if (normalizedOrganizationId != null && normalizedOrganizationId.isNotEmpty) {
      return fetchOrganizationById(normalizedOrganizationId);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return fetchOrganizationByUid(uid);
  }

  @override
  Future<List<Organization>> visibleOrganizations() => fetchOrganizations();

  Future<Organization?> fetchOrganizationById(String organizationId) async {
    final snapshot = await _service.organizationDocument(organizationId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Organization.fromMap(snapshot.data()!, snapshot.id);
  }

  Future<Organization?> fetchOrganizationByUid(String firebaseUid) async {
    final snapshot = await _service.firestore.collection(FirestorePaths.organizations).where('firebaseUid', isEqualTo: firebaseUid).limit(2).get();
    if (snapshot.docs.isEmpty) return null;
    if (snapshot.docs.length > 1) {
      throw StateError('تم العثور على أكثر من مؤسسة مرتبطة بنفس Firebase UID.');
    }
    final document = snapshot.docs.first;
    return Organization.fromMap(document.data(), document.id);
  }

  Future<Organization?> fetchOrganizationByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final snapshot = await _service.firestore.collection(FirestorePaths.organizations).where('email', isEqualTo: normalizedEmail).limit(2).get();
    if (snapshot.docs.isEmpty) return null;
    if (snapshot.docs.length > 1) {
      throw StateError('تم العثور على أكثر من مؤسسة بنفس البريد الإلكتروني.');
    }
    final document = snapshot.docs.first;
    return Organization.fromMap(document.data(), document.id);
  }

  Future<void> saveOrganization(Organization organization) async {
    if (organization.id.trim().isEmpty) {
      throw StateError('Organization id is required before saving to Firestore.');
    }
    await _service.organizationDocument(organization.id).set({
      'name': organization.name.trim(),
      'phone': organization.phone.trim(),
      'location': organization.location.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Organization> createOrganization({
    required String name,
    required String email,
    required String phone,
    required String location,
    AccountStatus status = AccountStatus.active,
    String? firebaseUid,
  }) async {
    final reference = _service.organizationCollection().doc();
    final organization = Organization(
      id: reference.id,
      name: name,
      email: email.trim().toLowerCase(),
      phone: phone,
      location: location,
      status: status,
      firebaseUid: firebaseUid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await reference.set(organization.toMap());
    return organization;
  }

  Future<void> linkFirebaseUid({required String organizationId, required String firebaseUid, required String email}) async {
    final organization = await fetchOrganizationById(organizationId);
    if (organization == null) {
      throw StateError('لم يتم العثور على المؤسسة المطلوبة.');
    }
    if (organization.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw StateError('البريد الإلكتروني للمؤسسة غير مطابق للسجل الموجود.');
    }
    if (organization.firebaseUid != null && organization.firebaseUid != firebaseUid) {
      throw StateError('هذه المؤسسة مرتبطة بالفعل بحساب Firebase مختلف ولا يمكن نقله.');
    }

    final updatedOrganization = Organization(
      id: organization.id,
      name: organization.name,
      email: organization.email,
      phone: organization.phone,
      location: organization.location,
      status: organization.status,
      firebaseUid: firebaseUid,
      createdAt: organization.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _service.organizationDocument(updatedOrganization.id).set({
      'firebaseUid': updatedOrganization.firebaseUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Organization>> fetchOrganizations() async {
    final snapshot = await _service.organizationCollection().get();
    return snapshot.docs
      .map((document) => Organization.fromMap(document.data(), document.id))
        .where((organization) => organization.status != AccountStatus.inactive)
        .toList();
  }
}
