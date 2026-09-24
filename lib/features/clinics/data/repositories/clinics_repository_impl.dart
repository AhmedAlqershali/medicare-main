import 'package:flutter/material.dart';

import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_clinic_repository.dart';
import '../../../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../domain/entities/clinic_entity.dart';
import '../../domain/repositories/clinics_repository.dart';

class ClinicsRepositoryImpl implements ClinicsRepository {
  const ClinicsRepositoryImpl();

  @override
  Future<List<ClinicEntity>> getClinics() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بجلسة المستخدم.');
    final clinics = await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
    final doctors = await FirestoreDoctorRepository.instance.fetchDoctorsForOrganization(organizationId);
    return clinics.map((clinic) => ClinicEntity(
      name: clinic['name'] as String? ?? '',
      category: clinic['category'] as String? ?? '',
      location: clinic['location'] as String? ?? '',
      description: clinic['description'] as String? ?? '',
      hours: clinic['hours'] as String? ?? '',
      specialties: _strings(clinic['specialties']),
      status: clinic['status'] as String? ?? '',
      icon: Icons.local_hospital_outlined,
      colorValue: Colors.transparent.value,
      doctors: doctors.where((doctor) => doctor.clinic == (clinic['name'] as String? ?? '') || doctor.clinic == (clinic['id'] as String? ?? '')).map((doctor) => ClinicDoctorEntity(
        id: doctor.id,
        initials: doctor.initials,
        name: doctor.name,
        specialty: doctor.specialty,
        rating: doctor.rating.toString(),
        reviews: doctor.reviews.toString(),
        experience: doctor.experience,
        bio: doctor.bio,
        services: doctor.services,
        colorValue: Colors.transparent.value,
      )).toList(),
    )).toList();
  }

  List<String> _strings(Object? value) => value is List ? value.map((item) => item.toString()).toList() : const [];
}
