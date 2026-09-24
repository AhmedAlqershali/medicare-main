import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  const AppointmentsRepositoryImpl();

  @override
  Future<List<AppointmentEntity>> getAppointments() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بجلسة المريض.');
    final patientId = FirebaseAuthRepository.instance.session.patientId;
    final patientUid = FirebaseAuth.instance.currentUser?.uid;
    if (patientId == null || patientId.isEmpty || patientUid == null || patientUid.isEmpty) throw StateError('لا توجد هوية مريض مرتبطة بجلسة Firebase.');
    final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForPatient(
      organizationId: organizationId,
      patientId: patientId,
      patientUid: patientUid,
    );
    return appointments
        .map(_fromMap)
        .toList();
  }

  AppointmentEntity _fromMap(Map<String, dynamic> appointment) => AppointmentEntity(
      id: appointment['id'] as String? ?? '',
        doctorId: appointment['doctorId'] as String? ?? '',
        clinicId: appointment['clinicId'] as String?,
        doctorName: appointment['doctorName'] as String? ?? '',
        doctorInitials: appointment['doctorInitials'] as String? ?? '',
        specialty: appointment['specialty'] as String? ?? '',
        clinicName: appointment['clinicName'] as String? ?? '',
        location: appointment['location'] as String? ?? '',
        date: appointment['date'] as String? ?? '',
        time: appointment['time'] as String? ?? '',
        type: appointment['type'] as String? ?? '',
        status: _statusFromMap(appointment['status']),
        avatarColorValue: appointment['avatarColorValue'] as int? ?? Colors.transparent.value,
        notes: appointment['notes'] as String?,
      );

  AppointmentEntityStatus _statusFromMap(Object? value) => switch (value) {
        'completed' => AppointmentEntityStatus.completed,
        'cancelled' => AppointmentEntityStatus.cancelled,
        _ => AppointmentEntityStatus.upcoming,
      };

}
