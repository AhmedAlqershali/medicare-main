import '../../../../core/auth/models/medical_note.dart';

class PatientProfileEntity {
const PatientProfileEntity({
required this.name,
required this.phone,
required this.email,
required this.birthDate,
required this.gender,
this.problemLocation,
this.medicalNotes,
this.medicalNotesHistory = const [],
});

final String name;
final String phone;
final String email;
final String birthDate;
final String gender;
final String? problemLocation;

/// للتوافق مع الملاحظات القديمة.
final String? medicalNotes;

/// سجل جميع الملاحظات الطبية.
final List<MedicalNote> medicalNotesHistory;

bool get isValid =>
name.trim().isNotEmpty && email.contains('@');
}
