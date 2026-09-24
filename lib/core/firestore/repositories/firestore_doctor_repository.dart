import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/account_role.dart';
import '../../auth/models/account_status.dart';
import '../../auth/models/doctor.dart';
import '../../auth/models/invitation.dart';
import '../../auth/models/invitation_status.dart';
import '../../auth/repositories/doctor_repository.dart';
import '../firestore_paths.dart';
import '../firestore_service.dart';

class FirestoreDoctorRepository implements DoctorRepository {
  FirestoreDoctorRepository._({FirestoreService? service}) : _service = service ?? FirestoreService();

  static final instance = FirestoreDoctorRepository._();

  final FirestoreService _service;

  @override
  Future<List<Doctor>> doctorsForOrganization(String organizationId) => fetchDoctorsForOrganization(organizationId);

  Future<List<Doctor>> fetchDoctorsForOrganization(String organizationId) async {
    final nestedSnapshot = await _service.doctorCollectionForOrganization(organizationId).get();
    return nestedSnapshot.docs
        .map((document) => Doctor.fromMap(document.data(), document.id))
        .where((doctor) => doctor.organizationId == organizationId)
        .toList();
  }

  Future<Doctor?> fetchDoctorByIdForOrganization(String organizationId, String doctorId) async {
    final snapshot = await _service.doctorDocumentForOrganization(organizationId, doctorId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final doctor = Doctor.fromMap(snapshot.data()!, snapshot.id);
    if (doctor.organizationId.isNotEmpty && doctor.organizationId != organizationId) {
      throw StateError('This doctor belongs to a different organization and cannot be read here.');
    }
    return doctor;
  }

  @override
  Future<Doctor?> doctorForId(String doctorId, {String? organizationId}) => fetchDoctorById(doctorId, organizationId: organizationId);

  @override
  Future<Doctor> inviteDoctor({required String organizationId, required String name, required String email, required String specialty, required String invitedBy, String? clinicId, String? clinicName}) async {
    final now = DateTime.now();
    final trimmedEmail = email.trim().toLowerCase();
    final doctor = Doctor(
      id: _service.doctorCollectionForOrganization(organizationId).doc().id,
      name: name.trim(),
      email: trimmedEmail,
      organizationId: organizationId,
      specialty: specialty.trim(),
      clinic: clinicName?.trim() ?? '',
      clinicId: clinicId,
      phone: '',
      status: AccountStatus.pending,
      initials: _initials(name),
      firebaseUid: null,
      availability: const {},
      createdAt: now,
      updatedAt: now,
    );
    final invitation = Invitation(
      id: doctor.id,
      email: trimmedEmail,
      role: AccountRole.doctor,
      invitedBy: invitedBy.trim(),
      organizationId: organizationId,
      status: InvitationStatus.pending,
      doctorId: doctor.id,
      clinicId: clinicId,
    );
    await _service.firestore.runTransaction((transaction) async {
      transaction.set(_service.doctorDocumentForOrganization(organizationId, doctor.id), doctor.toMap());
      transaction.set(_service.invitationDocument(organizationId, invitation.id), invitation.toMap());
    });
    return doctor;
  }

  Future<Doctor?> fetchDoctorById(String doctorId, {String? organizationId}) async {
    if (organizationId == null || organizationId.trim().isEmpty) return null;
    return fetchDoctorByIdForOrganization(organizationId, doctorId);
  }

  Future<void> saveDoctor(Doctor doctor) async {
    await _service.doctorDocumentForOrganization(doctor.organizationId, doctor.id).set(doctor.toMap(), SetOptions(merge: true));
  }

  Future<void> saveAvailability({required String organizationId, required String doctorId, required Map<String, List<String>> availability}) async {
    final doctor = await fetchDoctorByIdForOrganization(organizationId, doctorId);
    if (doctor == null) throw StateError('لم يتم العثور على ملف الطبيب.');
    await _service.doctorDocumentForOrganization(organizationId, doctorId).update({
      'availability': availability,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Doctor> linkFirebaseUidForOrganization({required String organizationId, required String doctorId, required String firebaseUid, required String email}) async {
    final doctor = await fetchDoctorByIdForOrganization(organizationId, doctorId);
    if (doctor == null) {
      throw StateError('لم يتم العثور على سجل الطبيب المطلوب داخل المؤسسة.');
    }
    if (doctor.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw StateError('البريد الإلكتروني للطبيب غير مطابق للسجل الموجود.');
    }
    if (doctor.firebaseUid != null && doctor.firebaseUid != firebaseUid) {
      throw StateError('هذا الطبيب مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.');
    }
    final updatedDoctor = Doctor(
      id: doctor.id,
      name: doctor.name,
      email: doctor.email,
      organizationId: doctor.organizationId,
      specialty: doctor.specialty,
      status: AccountStatus.active,
      initials: doctor.initials,
      firebaseUid: firebaseUid,
      availability: doctor.availability,
      clinic: doctor.clinic,
      clinicId: doctor.clinicId,
      phone: doctor.phone,
      location: doctor.location,
      rating: doctor.rating,
      reviews: doctor.reviews,
      experience: doctor.experience,
      bio: doctor.bio,
      services: doctor.services,
      createdAt: doctor.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveDoctor(updatedDoctor);
    return updatedDoctor;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
  }
}
