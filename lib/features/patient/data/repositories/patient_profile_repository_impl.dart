
import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../domain/entities/patient_profile.dart';
import '../../domain/repositories/patient_profile_repository.dart';

class PatientProfileRepositoryImpl implements PatientProfileRepository {
  const PatientProfileRepositoryImpl();

  @override
  Future<PatientProfileEntity> getPatientProfile() async {
    final session = FirebaseAuthRepository.instance.session;

    final patientId = session.patientId;
    if (patientId == null || patientId.isEmpty) {
      throw StateError('لا توجد جلسة مريض نشطة.');
    }

    final organizationId = session.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      throw StateError('لا توجد مؤسسة مرتبطة بالمريض.');
    }

    final profile = await FirestorePatientRepository.instance
        .fetchPatientById(
      patientId,
      organizationId: organizationId,
    );

    if (profile == null) {
      throw StateError('لم يتم العثور على ملف المريض.');
    }

    // لا نجلب الملاحظات الطبية في واجهة المريض.
    return PatientProfileEntity(
      name: profile.name,
      phone: profile.phone ?? '',
      email: profile.email,
      birthDate: profile.birthDate ?? '',
      gender: profile.gender ?? '',
      problemLocation: profile.problemLocation,
      medicalNotes: null,
      medicalNotesHistory: const [],
    );
  }

  @override
  Future<void> updatePatientProfile(
      PatientProfileEntity profile,
      ) async {
    final session = FirebaseAuthRepository.instance.session;

    final patientId = session.patientId;
    if (patientId == null || patientId.isEmpty) {
      throw StateError('لا توجد جلسة مريض نشطة.');
    }

    final organizationId = session.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      throw StateError('لا توجد مؤسسة مرتبطة بالمريض.');
    }

    await FirestorePatientRepository.instance.updatePatientProfile(
      patientId: patientId,
      organizationId: organizationId,
      name: profile.name,
      phone: profile.phone,
      birthDate: profile.birthDate,
      gender: profile.gender,
    );
  }
}
