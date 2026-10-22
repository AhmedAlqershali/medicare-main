import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/models/medical_catalog_entry.dart';
import '../firestore_service.dart';

class FirestoreMedicalCatalogRepository {
  FirestoreMedicalCatalogRepository._({FirestoreService? service})
      : _service = service ?? FirestoreService();

  static final instance = FirestoreMedicalCatalogRepository._();
  final FirestoreService _service;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _service.firestore.collection('medical_catalog');

  Future<List<MedicalCatalogEntry>> fetchEntries({
    MedicalCatalogKind? kind,
    bool includeInactive = false,
  }) async {
    Query<Map<String, dynamic>> query = _collection;
    if (kind != null) query = query.where('kind', isEqualTo: kind.name);
    final snapshot = await query.get();
    final entries = snapshot.docs
        .map((document) => MedicalCatalogEntry.fromMap(
              document.id,
              document.data(),
            ))
        .where((entry) =>
          includeInactive || (entry.active && !entry.archived))
        .toList();
    entries.sort((first, second) => first.displayName.compareTo(second.displayName));
    return entries;
  }

  Future<bool> isCurrentAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final snapshot = await _service.firestore.collection('admins').doc(uid).get();
    final data = snapshot.data();
    return snapshot.exists && data?['role'] == 'admin' && data?['active'] == true;
  }

  Future<void> saveEntry(MedicalCatalogEntry entry) async {
    if (entry.nameAr.trim().isEmpty && entry.nameEn.trim().isEmpty) {
      throw StateError('أدخل الاسم بالعربية أو الإنجليزية.');
    }
    if (entry.kind != MedicalCatalogKind.specialty && entry.specialtyIds.isEmpty) {
      throw StateError('اربط العنصر بتخصص واحد على الأقل.');
    }
    final data = <String, dynamic>{
      'id': entry.id,
      'kind': entry.kind.name,
      'nameAr': entry.nameAr.trim(),
      'nameEn': entry.nameEn.trim(),
      'specialtyIds': entry.specialtyIds,
      'active': entry.archived ? false : entry.active,
      'archived': entry.archived,
      'parentId': entry.parentId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(entry.id).set(data, SetOptions(merge: true));
  }

  String newId() => _collection.doc().id;
}
