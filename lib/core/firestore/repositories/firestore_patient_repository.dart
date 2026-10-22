import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
FirebaseFunctions? functions,
})  : _service = service ?? FirestoreService(),
_doctorRepository =
doctorRepository ?? FirestoreDoctorRepository.instance,
_functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

static final instance = FirestorePatientRepository._();

final FirestoreService _service;
final DoctorRepository _doctorRepository;
final FirebaseFunctions _functions;

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
if (doctor.id != doctorId ||
    (organizationId != null && organizationId != doctor.organizationId)) {
throw StateError('معرّف الطبيب أو المؤسسة غير مطابق للجلسة.');
}

final result = await _functions.httpsCallable('listPatientsForDoctor').call();
final resultData = Map<String, dynamic>.from(result.data as Map);
final records = resultData['patients'] as List<dynamic>? ?? const [];
return records
    .whereType<Map>()
    .map((record) => Patient.fromMap(Map<String, dynamic>.from(record)))
    .where((patient) => patient.organizationId == doctor.organizationId)
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
 final uid = FirebaseAuth.instance.currentUser?.uid;
 if (uid == null || uid.isEmpty) {
     throw StateError('يلزم تسجيل الدخول قبل قراءة المرضى.');
 }
 final profile = await FirestoreUserProfileRepository().fetchUserProfile(uid);
 if (profile?.role.name == 'organization' &&
         profile?.organizationId == organizationId &&
         profile?.clinicId != null &&
         profile!.clinicId!.isNotEmpty) {
     final result = await _functions.httpsCallable('listPatientsForClinic').call({
         'clinicId': profile.clinicId,
     });
     final resultData = Map<String, dynamic>.from(result.data as Map);
     final records = resultData['patients'] as List<dynamic>? ?? const [];
     return records
             .whereType<Map>()
             .map((record) => Patient.fromMap(Map<String, dynamic>.from(record)))
             .where((patient) => patient.organizationId == organizationId)
             .toList();
 }

 Query<Map<String, dynamic>> query =
                 _service.patientCollectionForOrganization(organizationId);

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

final appointmentDateTime = DateTime(
appointmentDate.year,
appointmentDate.month,
appointmentDate.day,
appointmentTime.hour,
appointmentTime.minute,
);
if (!appointmentDateTime.isAfter(DateTime.now())) {
throw StateError('يجب أن يكون الموعد الأول بتاريخ ووقت قادمين.');
}
try {
final result = await _functions.httpsCallable('registerPatientVisit').call({
  'name': normalizedName,
  'email': trimmedEmail,
  'problemLocation': problemLocation?.trim() ?? '',
  'medicalNotes': medicalNotes?.trim() ?? '',
  'appointmentAtMillis': appointmentDateTime.millisecondsSinceEpoch,
  'appointmentTime': _formatTime(appointmentTime),
});
final resultData = Map<String, dynamic>.from(result.data as Map);
final patientData = Map<String, dynamic>.from(resultData['patient'] as Map);
return Patient.fromMap(patientData);
} on FirebaseFunctionsException catch (error) {
final details = error.details is Map
    ? Map<String, dynamic>.from(error.details as Map)
    : const <String, dynamic>{};
final candidates = details['candidates'];
if (details['reason'] == 'name_review' && candidates is List) {
  final labels = candidates
      .whereType<Map>()
      .map((candidate) =>
          '${candidate['name'] ?? 'اسم غير متاح'} (${candidate['email'] ?? 'بريد غير متاح'})')
      .join('، ');
  throw StateError('يوجد سجل مشابه يحتاج مراجعة يدوية: $labels');
}
if (details['reason'] == 'duplicate_email' && candidates is List) {
  final labels = candidates
      .whereType<Map>()
      .map((candidate) =>
          '${candidate['name'] ?? 'اسم غير متاح'} (${candidate['email'] ?? 'بريد غير متاح'})')
      .join('، ');
  throw StateError('توجد سجلات بهذا البريد تحتاج مراجعة يدوية: $labels');
}
throw StateError(error.message ?? 'تعذر إنشاء زيارة المريض.');
}
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

try {
    final result = await _functions
            .httpsCallable('findPendingPatientActivation')
            .call({'email': normalizedEmail});
    final resultData = Map<String, dynamic>.from(result.data as Map);
    final patientData = Map<String, dynamic>.from(resultData['patient'] as Map);
    return Patient.fromMap(patientData);
} on FirebaseFunctionsException catch (error) {
    if (error.details is Map &&
            (error.details as Map)['reason'] == 'not_found') {
        return null;
    }
    throw StateError(error.message ?? 'تعذر التحقق من سجل تفعيل المريض.');
}
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

final emailIndexReference = _service.patientEmailIndexDocument(
    patient.organizationId,
    normalizedEmail,
);
final emailIndexSnapshot = await emailIndexReference.get();
final existingEmailIndex = emailIndexSnapshot.data();
if (emailIndexSnapshot.exists &&
        (existingEmailIndex?['email'] != normalizedEmail ||
                existingEmailIndex?['organizationId'] != patient.organizationId ||
                existingEmailIndex?['patientId'] != patient.id)) {
    throw StateError('هذا البريد مرتبط بالفعل بسجل مريض آخر.');
}

final emailIndexData = {
    'email': normalizedEmail,
    'organizationId': patient.organizationId,
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

String _formatTime(TimeOfDay time) {
final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
final minute = time.minute.toString().padLeft(2, '0');
final period = time.period == DayPeriod.am ? 'ص' : 'م';

return '$hour:$minute $period';
}

}
