import 'package:flutter/material.dart';

import '../../../../core/auth/models/doctor.dart';
import '../../../../core/auth/models/patient.dart';
import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_clinic_repository.dart';
import '../../../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../domain/repositories/organization_clinics_repository.dart';
import '../../models/organization_clinic.dart';

class OrganizationClinicsRepositoryImpl implements OrganizationClinicsRepository {
  const OrganizationClinicsRepositoryImpl();

  @override
  Future<List<OrganizationClinic>> getOrganizationClinics({bool includeRelatedData = true}) async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بجلسة المستخدم.');
    final clinics = await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
    final doctors = includeRelatedData ? await FirestoreDoctorRepository.instance.fetchDoctorsForOrganization(organizationId) : const <Doctor>[];
    final patients = includeRelatedData ? await FirestorePatientRepository.instance.fetchPatientsForOrganization(organizationId) : const <Patient>[];
    return clinics.map((clinic) => OrganizationClinic(
      id: clinic['id'] as String? ?? '',
      name: clinic['name'] as String? ?? '',
      location: clinic['location'] as String? ?? '',
      phone: clinic['phone'] as String? ?? '',
      description: clinic['description'] as String? ?? '',
      status: _statusLabel(clinic['status']),
      doctorsCount: _doctorsForClinic(doctors, clinic).length,
      departmentsCount: _strings(clinic['departments'] ?? clinic['specialties']).length,
      patientsCount: patients.where((patient) => _doctorsForClinic(doctors, clinic).any((doctor) => doctor.id == patient.doctorId)).length,
      icon: Icons.local_hospital_outlined,
      color: Colors.transparent,
      departments: _strings(clinic['departments'] ?? clinic['specialties']),
    )).toList();
  }

  List<String> _strings(Object? value) => value is List ? value.map((item) => item.toString()).toList() : const [];

  String _statusLabel(Object? value) => switch (value?.toString().trim().toLowerCase()) {
        'active' || 'نشط' || 'نشطة' => 'نشطة',
        'inactive' || 'غير متاح' || 'غير متاحة' => 'غير متاحة',
        'pending' || 'قيد الانتظار' => 'قيد الانتظار',
        _ => value?.toString() ?? '',
      };

  List<Doctor> _doctorsForClinic(List<Doctor> doctors, Map<String, dynamic> clinic) {
    final clinicId = clinic['id'] as String? ?? '';
    final clinicName = clinic['name'] as String? ?? '';
    return doctors.where((doctor) => doctor.clinicId == clinicId || (doctor.clinicId == null && (doctor.clinic == clinicId || doctor.clinic == clinicName))).toList();
  }
}
