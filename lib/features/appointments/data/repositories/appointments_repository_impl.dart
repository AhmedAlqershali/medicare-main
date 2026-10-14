import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../../../core/firestore/appointment_date_time.dart';
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
        .toList()
      ..sort((first, second) {
        final firstDate = parseAppointmentDateTime(first.date, first.time);
        final secondDate = parseAppointmentDateTime(second.date, second.time);
        if (firstDate == null) return secondDate == null ? 0 : 1;
        if (secondDate == null) return -1;
        if (first.status == AppointmentEntityStatus.previous && second.status == AppointmentEntityStatus.previous) {
          return secondDate.compareTo(firstDate);
        }
        return firstDate.compareTo(secondDate);
      });
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
        date: _dateString(appointment['date']),
        time: appointment['time']?.toString() ?? '',
        type: appointment['type'] as String? ?? '',
        status: _statusFromMap(appointment['status'], appointment['date'], appointment['time']),
        avatarColorValue: appointment['avatarColorValue'] as int? ?? Colors.transparent.value,
        notes: appointment['notes'] as String?,
      );

  AppointmentEntityStatus _statusFromMap(Object? value, Object? date, Object? time) {
    if (value == 'completed') return AppointmentEntityStatus.completed;
    if (value == 'cancelled') return AppointmentEntityStatus.cancelled;
    final appointmentDate = parseAppointmentDateTime(date, time);
    if (appointmentDate != null && appointmentDate.isBefore(DateTime.now())) {
      return AppointmentEntityStatus.previous;
    }
    return AppointmentEntityStatus.upcoming;
  }

  String _dateString(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      }
    }
    return value?.toString() ?? '';
  }

}
