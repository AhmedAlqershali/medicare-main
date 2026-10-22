import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../auth/models/account_status.dart';
import '../../auth/repositories/doctor_repository.dart';
import '../../auth/models/patient.dart';
import '../../auth/models/medical_note.dart';
import '../../auth/repositories/patient_repository.dart';
import '../../auth/services/firebase_auth_repository.dart';
import '../firestore_service.dart';
import 'firestore_user_profile_repository.dart';
import 'firestore_doctor_repository.dart';

class FirestorePatientRepository implements PatientRepository {
FirestorePatientRepository._({
FirestoreService? service,
DoctorRepository? doctorRepository,
})  : _service = service ?? FirestoreService(),
_doctorRepository =
doctorRepository ?? FirestoreDoctorRepository.instance;

static final instance = FirestorePatientRepository._();

final FirestoreService _service;
final DoctorRepository _doctorRepository;

@override
Future<List<Patient>> patientsForDoctor(
String doctorId, {
String? organizationId,
}) =>
fetchPatientsForDoctor(
doctorId,
organizationId: organizationId,
);

Future<List<Patient>> fetchPatientsForDoctor(
String doctorId, {
String? organizationId,
}) async {
final doctor = await _doctorRepository.doctorForId(
doctorId,
organizationId: organizationId,
);

if (doctor == null || doctor.organizationId.isEmpty) {
return [];
}

final snapshot = await _service
    .patientCollectionForOrganization(doctor.organizationId)
    .where(
'organizationId',
isEqualTo: doctor.organizationId,
)
    .where(
'doctorId',
isEqualTo: doctor.id,
)
    .get();

return snapshot.docs
    .map(
(document) => Patient.fromMap({
...document.data(),
'id': document.id,
}),
)
    .toList();
}

Future<List<Patient>> fetchPatientsForOrganization(
String organizationId,
) async {
if (organizationId.trim().isEmpty) {
throw StateError('Organization id is required to read patients.');
}

final path = 'organizations/$organizationId/patients';

debugPrint(
'[FirestoreDiagnostic] patients request: '
'uid=${FirebaseAuth.instance.currentUser?.uid}, '
'projectId=${Firebase.apps.isEmpty ? 'unavailable' : Firebase.app().options.projectId}, '
'organizationId=$organizationId, '
'sessionRole=${FirebaseAuthRepository.instance.session.currentRole?.name}, '
'path=$path, '
'operation=collection.get',
);

try {
 Query<Map<String, dynamic>> query =
         _service.patientCollectionForOrganization(organizationId);
 final uid = FirebaseAuth.instance.currentUser?.uid;
 if (uid != null && uid.isNotEmpty) {
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
(document) => Patient.fromMap({
...document.data(),
'id': document.id,
}),
)
    .toList();
} on FirebaseException catch (error) {
debugPrint(
'[FirestoreDiagnostic] patients request failed: '
'code=${error.code}, message=${error.message}',
);
rethrow;
}
}

@override
Future<Patient?> patientForId(
String patientId, {
String? organizationId,
}) =>
fetchPatientById(
patientId,
organizationId: organizationId,
);

@override
Future<Patient> createPatient({
required String doctorId,
required String name,
required String email,
required String invitedBy,
String? organizationId,
required DateTime appointmentDate,
required TimeOfDay appointmentTime,
String? problemLocation,
String? medicalNotes,
}) async {
final normalizedName = name.trim();
final trimmedEmail = email.trim().toLowerCase();

if (normalizedName.isEmpty ||
    !RegExp(r'^[^@\s/]+@[^@\s/]+\.[^@\s/]+$')
        .hasMatch(trimmedEmail)) {
throw StateError('أدخل اسم المريض وبريداً إلكترونياً صحيحاً.');
}

final doctor = await _doctorRepository.doctorForId(
doctorId,
organizationId: organizationId,
);

if (doctor == null ||
    doctor.organizationId.isEmpty ||
    doctor.id != doctorId ||
    doctor.status != AccountStatus.active) {
throw StateError(
'لم يتم العثور على طبيب نشط مرتبط بمؤسسة صالحة.',
);
}

final currentUid = FirebaseAuth.instance.currentUser?.uid;

if (currentUid == null ||
currentUid.isEmpty ||
doctor.firebaseUid != currentUid ||
FirebaseAuth.instance.currentUser?.emailVerified != true) {
throw StateError(
'يجب تفعيل بريد الطبيب وربط حساب Firebase بسجل الطبيب المطلوب.',
);
}

if (organizationId != null &&
organizationId.trim().isNotEmpty &&
doctor.organizationId != organizationId.trim()) {
throw StateError(
'لا يمكن إنشاء المريض خارج مؤسسة الطبيب الحالية.',
);
}

final clinicId = doctor.clinicId?.trim();
if (clinicId == null || clinicId.isEmpty) {
throw StateError('يجب ربط الطبيب بعيادة قبل إضافة المرضى.');
}

final clinicSnapshot = await _service
    .clinicDocument(doctor.organizationId, clinicId)
    .get();
if (!clinicSnapshot.exists ||
    clinicSnapshot.data()?['organizationId'] != doctor.organizationId) {
throw StateError('عيادة الطبيب غير موجودة ضمن المؤسسة الحالية.');
}

final doctorPatients = await _service
    .patientCollectionForOrganization(doctor.organizationId)
    .where('doctorId', isEqualTo: doctor.id)
    .get();
if (doctorPatients.docs.any(
  (document) =>
      (document.data()['email'] as String?)?.trim().toLowerCase() ==
      trimmedEmail,
)) {
throw StateError('يوجد سجل للمريض بهذا البريد لدى الطبيب الحالي.');
}

final now = DateTime.now();

final patientReference = _service
    .patientCollectionForOrganization(doctor.organizationId)
    .doc();

final appointmentReference = _service
    .appointmentCollection(doctor.organizationId)
    .doc();

final patient = Patient(
id: patientReference.id,
name: normalizedName,
email: trimmedEmail,
doctorId: doctorId,
organizationId: doctor.organizationId,
clinicId: clinicId,
status: AccountStatus.pending,
accountActivated: false,
initials: _initials(normalizedName),
firebaseUid: null,
createdAt: now,
updatedAt: now,
problemLocation: problemLocation?.trim(),
);

final appointmentDateTime = DateTime(
appointmentDate.year,
appointmentDate.month,
appointmentDate.day,
appointmentTime.hour,
appointmentTime.minute,
);

final appointment = <String, dynamic>{
'id': appointmentReference.id,
'organizationId': doctor.organizationId,
'doctorId': doctorId,
'patientId': patient.id,
'patientUid': null,
'patientName': patient.name,
'patientInitials': patient.initials,
'clinicId': clinicId,
'date': _formatDate(appointmentDateTime),
'time': _formatTime(appointmentTime),
'type': 'زيارة',
'status': 'upcoming',
'notes': '',
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
'createdBy': invitedBy,
};

final emailIndexReference = _service.patientEmailIndexDocument(trimmedEmail);

await _service.firestore.runTransaction((transaction) async {
    final emailIndex = await transaction.get(emailIndexReference);
    if (emailIndex.exists) {
        throw StateError('يوجد سجل للمريض بهذا البريد ضمن المؤسسة الحالية.');
    }

    transaction.set(patientReference, patient.toMap());
    transaction.set(appointmentReference, appointment);
    transaction.set(emailIndexReference, {
        'email': trimmedEmail,
        'organizationId': doctor.organizationId,
        'doctorId': doctor.id,
        'clinicId': clinicId,
        'patientId': patient.id,
        'createdAt': FieldValue.serverTimestamp(),
    });

// Store the initial medical note in the permanent notes subcollection.
final initialNoteText = medicalNotes?.trim() ?? '';

if (initialNoteText.isNotEmpty) {
final noteReference = _service
    .medicalNotesCollection(patient.organizationId, patient.id)
    .doc();

        transaction.set(noteReference, {
            'text': initialNoteText,
            'createdAt': FieldValue.serverTimestamp(),
            'doctorUid': currentUid,
            'doctorName': doctor.name,
        });
    }
});
}

return patient;
}

Future<Patient?> fetchPatientById(
String patientId, {
String? organizationId,
}) async {
if (organizationId == null || organizationId.trim().isEmpty) {
return null;
}

final snapshot = await _service
    .patientDocumentForOrganization(
organizationId,
patientId,
)
    .get();

if (!snapshot.exists || snapshot.data() == null) {
return null;
}

return Patient.fromMap({
...snapshot.data()!,
'id': snapshot.id,
});
}

/// Finds the pending patient record that matches the supplied email.
///
/// This is used during the first patient account activation, before
/// users/{uid} exists.
Future<Patient?> fetchPendingPatientByEmail(String email) async {
final normalizedEmail = email.trim().toLowerCase();

if (normalizedEmail.isEmpty) {
return null;
}

final snapshot = await FirebaseFirestore.instance
    .collectionGroup('patients')
    .where('email', isEqualTo: normalizedEmail)
    .where('status', isEqualTo: AccountStatus.pending.name)
    .where('accountActivated', isEqualTo: false)
    .where('firebaseUid', isEqualTo: null)
    .get();

Patient? pendingPatient;

for (final document in snapshot.docs) {
final data = document.data();

final accountActivated = data['accountActivated'] == true;
final status = data['status']?.toString();
final firebaseUid = data['firebaseUid']?.toString();

if (status == AccountStatus.pending.name &&
!accountActivated &&
(firebaseUid == null || firebaseUid.isEmpty)) {
final organizationId = document.reference.parent.parent?.id;

if (organizationId == null ||
data['organizationId'] != organizationId ||
data['doctorId'] is! String ||
(data['doctorId'] as String).isEmpty ||
data['id'] != document.id) {
throw StateError(
'بيانات سجل المريض غير مكتملة أو غير متطابقة.',
);
}

if (pendingPatient != null) {
throw StateError(
'يوجد أكثر من سجل مريض بنفس البريد الإلكتروني. '
'يجب أن يكون البريد مرتبطًا بسجل مريض واحد فقط.',
);
}

pendingPatient = Patient.fromMap({
...data,
'id': document.id,
});
}
}

return pendingPatient;
}

Future<void> savePatient(Patient patient) async {
await _service
    .patientDocumentForOrganization(
patient.organizationId,
patient.id,
)
    .set(
patient.toMap(),
SetOptions(merge: true),
);
}

Future<MedicalNote> addMedicalNote({
required String patientId,
required String organizationId,
required String text,
required String doctorUid,
required String doctorName,
}) async {
final trimmedText = text.trim();

if (trimmedText.isEmpty) {
throw StateError('يجب إدخال نص الملاحظة الطبية.');
}

if (doctorUid.trim().isEmpty) {
throw StateError('يجب تحديد الطبيب الذي يضيف الملاحظة.');
}

final patient = await fetchPatientById(
patientId,
organizationId: organizationId,
);

if (patient == null) {
throw StateError('لم يتم العثور على سجل المريض المطلوب.');
}

final noteReference = _service
    .medicalNotesCollection(patient.organizationId, patient.id)
    .doc();

final note = MedicalNote(
id: noteReference.id,
text: trimmedText,
createdAt: DateTime.now(),
doctorUid: doctorUid.trim(),
doctorName: doctorName.trim(),
);

await noteReference.set({
'text': note.text,
'createdAt': FieldValue.serverTimestamp(),
'doctorUid': note.doctorUid,
'doctorName': note.doctorName,
});

return note;
}

Future<List<MedicalNote>> getMedicalNotes({
required String patientId,
required String organizationId,
}) async {
final patient = await fetchPatientById(
patientId,
organizationId: organizationId,
);

if (patient == null) {
return const [];
}

final snapshot = await _service
    .medicalNotesCollection(patient.organizationId, patient.id)
    .orderBy('createdAt', descending: true)
    .get();

final notes = snapshot.docs
    .map(
(document) => MedicalNote.fromMap(
document.id,
document.data(),
),
)
    .toList();

// Include an older legacy note without deleting or overwriting it.
if (patient.notes?.trim().isNotEmpty ?? false) {
notes.add(
MedicalNote(
id: 'legacy-${patient.id}',
text: patient.notes!.trim(),
createdAt: patient.updatedAt ??
patient.createdAt ??
DateTime.now(),
doctorUid: patient.doctorId,
doctorName: null,
),
);
}

return MedicalNote.sortNewestFirst(notes);
}

Future<void> updatePatientProfile({
required String patientId,
required String organizationId,
required String name,
required String phone,
required String birthDate,
required String gender,
}) async {
if (patientId.trim().isEmpty) {
throw StateError(
'Patient id is required before saving the profile.',
);
}

final patient = await fetchPatientById(
patientId,
organizationId: organizationId,
);

if (patient == null) {
throw StateError(
'لم يتم العثور على سجل المريض المطلوب.',
);
}

await _service
    .patientDocumentForOrganization(
patient.organizationId,
patient.id,
)
    .set(
{
'name': name.trim(),
'phone': phone.trim(),
'birthDate': birthDate.trim(),
'gender': gender.trim(),
'updatedAt': FieldValue.serverTimestamp(),
},
SetOptions(merge: true),
);
}

Future<void> activatePatient({
required String patientId,
required String organizationId,
required String firebaseUid,
required String email,
WriteBatch? batch,
}) async {
final normalizedEmail = email.trim().toLowerCase();

if (patientId.trim().isEmpty ||
organizationId.trim().isEmpty ||
firebaseUid.trim().isEmpty ||
normalizedEmail.isEmpty) {
throw StateError(
'بيانات تفعيل حساب المريض غير مكتملة.',
);
}

final patient = await fetchPatientById(
patientId,
organizationId: organizationId,
);

if (patient == null) {
throw StateError(
'لم يتم العثور على سجل المريض المطلوب.',
);
}

if (patient.email.trim().toLowerCase() != normalizedEmail) {
throw StateError(
'بريد المريض غير مطابق للسجل الموجود.',
);
}

final emailIndexReference = _service.patientEmailIndexDocument(normalizedEmail);
final emailIndexSnapshot = await emailIndexReference.get();
final existingEmailIndex = emailIndexSnapshot.data();
if (emailIndexSnapshot.exists &&
        (existingEmailIndex?['email'] != normalizedEmail ||
                existingEmailIndex?['organizationId'] != patient.organizationId ||
                existingEmailIndex?['doctorId'] != patient.doctorId ||
                existingEmailIndex?['patientId'] != patient.id)) {
    throw StateError('هذا البريد مرتبط بالفعل بسجل مريض آخر.');
}

final emailIndexData = {
    'email': normalizedEmail,
    'organizationId': patient.organizationId,
    'doctorId': patient.doctorId,
    'clinicId': patient.clinicId,
    'patientId': patient.id,
    'createdAt': existingEmailIndex?['createdAt'] ?? FieldValue.serverTimestamp(),
};

if (patient.accountActivated) {
if (patient.firebaseUid != firebaseUid) {
throw StateError(
'هذا المريض مرتبط بالفعل بحساب Firebase مختلف ولا يمكن نقله.',
);
}
if (patient.status == AccountStatus.inactive) {
    throw StateError('حساب المريض غير نشط ولا يمكن تسجيل الدخول.');
}
if (patient.status == AccountStatus.pending) {
    final activationBatch = batch ?? FirebaseFirestore.instance.batch();
    activationBatch.update(
        _service.patientDocumentForOrganization(organizationId, patientId),
        {
            'status': AccountStatus.active.name,
            'updatedAt': FieldValue.serverTimestamp(),
        },
    );
        if (!emailIndexSnapshot.exists) {
            activationBatch.set(emailIndexReference, emailIndexData);
        }
    if (batch == null) await activationBatch.commit();
} else if (!emailIndexSnapshot.exists) {
        final activationBatch = batch ?? FirebaseFirestore.instance.batch();
        activationBatch.set(emailIndexReference, emailIndexData);
        if (batch == null) await activationBatch.commit();
}
return;
}

if (patient.status != AccountStatus.pending) {
throw StateError(
'سجل المريض ليس في حالة انتظار التفعيل.',
);
}

if (patient.firebaseUid != null &&
patient.firebaseUid!.isNotEmpty) {
throw StateError(
'هذا الحساب مربوط بالفعل بمستخدم Firebase آخر ولا يمكن نقله.',
);
}

final activationBatch =
batch ?? FirebaseFirestore.instance.batch();

final patientReference = _service.patientDocumentForOrganization(
patient.organizationId,
patient.id,
);

activationBatch.update(patientReference, {
    'firebaseUid': firebaseUid,
    'accountActivated': true,
    'status': AccountStatus.active.name,
    'updatedAt': FieldValue.serverTimestamp(),
});
if (!emailIndexSnapshot.exists) {
    activationBatch.set(emailIndexReference, emailIndexData);
}

// Do not query appointments here: the current Firestore rules deny
// this query during activation. Appointment linking must be performed
// separately through a rule-authorized operation or trusted backend.
if (batch == null) {
await activationBatch.commit();
}
}

String _formatDate(DateTime date) {
return '${date.year.toString().padLeft(4, '0')}-'
'${date.month.toString().padLeft(2, '0')}-'
'${date.day.toString().padLeft(2, '0')}';
}

String _formatTime(TimeOfDay time) {
final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
final minute = time.minute.toString().padLeft(2, '0');
final period = time.period == DayPeriod.am ? 'ص' : 'م';

return '$hour:$minute $period';
}

String _initials(String name) {
final parts = name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .toList();

if (parts.isEmpty) {
return 'U';
}

if (parts.length == 1) {
return parts.first.substring(0, 1).toUpperCase();
}

return '${parts.first.substring(0, 1).toUpperCase()}'
'${parts.last.substring(0, 1).toUpperCase()}';
}
}
