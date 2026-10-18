
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
    final organizationId =
        FirebaseAuthRepository.instance.session.organizationId;

    if (organizationId == null || organizationId.isEmpty) {
      throw StateError('لا توجد مؤسسة مرتبطة بجلسة المريض.');
    }

    final patientId = FirebaseAuthRepository.instance.session.patientId;
    final patientUid = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null ||
        patientId.isEmpty ||
        patientUid == null ||
        patientUid.isEmpty) {
      throw StateError('لا توجد هوية مريض مرتبطة بجلسة Firebase.');
    }

    final appointments =
    await FirestoreAppointmentRepository.instance.fetchAppointmentsForPatient(
      organizationId: organizationId,
      patientId: patientId,
      patientUid: patientUid,
    );

    final result = appointments.map(_fromMap).toList();

    result.sort((first, second) {
      final firstDate =
      parseAppointmentDateTime(first.date, first.time);
      final secondDate =
      parseAppointmentDateTime(second.date, second.time);

      if (firstDate == null) return secondDate == null ? 0 : 1;
      if (secondDate == null) return -1;

      if (first.status == AppointmentEntityStatus.previous &&
          second.status == AppointmentEntityStatus.previous) {
        return secondDate.compareTo(firstDate);
      }

      return firstDate.compareTo(secondDate);
    });

    return result;
  }

  AppointmentEntity _fromMap(Map<String, dynamic> appointment) {
    final date = appointment['date'];
    final time = appointment['time'];

    return AppointmentEntity(
      id: appointment['id'] as String? ?? '',
      doctorId: appointment['doctorId'] as String? ?? '',
      clinicId: appointment['clinicId'] as String?,
      doctorName: appointment['doctorName'] as String? ?? '',
      doctorInitials: appointment['doctorInitials'] as String? ?? '',
      specialty: appointment['specialty'] as String? ?? '',
      clinicName: appointment['clinicName'] as String? ?? '',
      location: appointment['location'] as String? ?? '',
      date: _dateString(date),
      time: time?.toString() ?? '',
      type: appointment['type'] as String? ?? '',
      status: _statusFromMap(appointment['status'], date, time),
      avatarColorValue:
      appointment['avatarColorValue'] as int? ??
          Colors.transparent.value,
      notes: appointment['notes'] as String?,
    );
  }

  AppointmentEntityStatus _statusFromMap(
      Object? value,
      Object? date,
      Object? time,
      ) {
    // الحالات النهائية المحفوظة في Firestore لها الأولوية.
    if (value == 'completed') {
      return AppointmentEntityStatus.completed;
    }

    if (value == 'cancelled') {
      return AppointmentEntityStatus.cancelled;
    }

    // الموعد غير المكتمل يصبح سابقًا بعد انتهاء يومه بالكامل.
    final appointmentDate = parseAppointmentDateTime(date, time);

    if (appointmentDate != null) {
      final now = DateTime.now();

      final appointmentDay = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );

      final today = DateTime(now.year, now.month, now.day);

      if (appointmentDay.isBefore(today)) {
        return AppointmentEntityStatus.previous;
      }
    }

    return AppointmentEntityStatus.upcoming;
  }

  String _dateString(Object? value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);

      // دعم التاريخ المخزن بصيغة يوم/شهر/سنة.
      if (date == null) {
        final parts = value.split('/');

        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);

          if (day != null && month != null && year != null) {
            try {
              final parsed = DateTime(year, month, day);

              if (parsed.year == year &&
                  parsed.month == month &&
                  parsed.day == day) {
                date = parsed;
              }
            } catch (_) {
              date = null;
            }
          }
        }
      }
    }

    if (date == null) {
      return value?.toString() ?? '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
