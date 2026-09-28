import '../../../../core/auth/models/medical_note.dart';

class PatientProfile {
const PatientProfile({
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

/// الملاحظة القديمة/التوافق مع البيانات السابقة.
final String? medicalNotes;

/// جميع الملاحظات الطبية، القديمة والجديدة.
final List<MedicalNote> medicalNotesHistory;
}
