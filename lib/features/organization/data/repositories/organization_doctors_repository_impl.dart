import 'package:flutter/material.dart';

import '../../../../core/auth/models/account_status.dart';
import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../domain/repositories/organization_doctors_repository.dart';
import '../../models/organization_doctor.dart';

class OrganizationDoctorsRepositoryImpl implements OrganizationDoctorsRepository {
  const OrganizationDoctorsRepositoryImpl();

  @override
  Future<List<OrganizationDoctor>> getOrganizationDoctors() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بجلسة المستخدم.');
    final doctors = await FirestoreDoctorRepository.instance.fetchDoctorsForOrganization(organizationId);
    return doctors.map((doctor) => OrganizationDoctor(
      id: doctor.id,
      name: doctor.name,
      initials: doctor.initials,
      specialty: doctor.specialty,
      clinic: doctor.clinic,
      clinicId: doctor.clinicId,
      phone: doctor.phone,
      email: doctor.email,
      status: _statusLabel(doctor.status),
      avatarColor: Colors.transparent,
      scheduleSummary: doctor.availability.isEmpty ? '' : '${doctor.availability.length} أيام متاحة',
      availability: doctor.availability,
    )).toList();
  }

  String _statusLabel(AccountStatus status) => switch (status) {
        AccountStatus.active => 'نشط',
        AccountStatus.pending => 'قيد الانتظار',
        AccountStatus.inactive => 'غير متاح',
      };
}
