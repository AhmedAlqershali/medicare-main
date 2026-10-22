import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/auth/models/account_role.dart';
import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../../../core/firestore/appointment_date_time.dart';
import '../../domain/repositories/doctor_appointments_repository.dart';
import '../../models/doctor_appointment.dart';

class DoctorAppointmentsRepositoryImpl
    implements DoctorAppointmentsRepository {
  const DoctorAppointmentsRepositoryImpl();

  @override
  Future<List<DoctorAppointment>> getDoctorAppointments() async {
    final session = FirebaseAuthRepository.instance.session;
    final organizationId = session.organizationId;
    final doctorId = session.doctorId;

    if (organizationId == null ||
        doctorId == null ||
        organizationId.isEmpty ||
      doctorId.isEmpty ||
      session.currentRole != AccountRole.doctor) {
      throw StateError(
        'لا توجد هوية طبيب ومؤسسة مرتبطة بجلسة المستخدم.',
      );
    }

    final appointments = await FirestoreAppointmentRepository.instance
        .fetchAppointmentsForDoctor(
      organizationId: organizationId,
      doctorId: doctorId,
    );

    return _sortAppointments(appointments.map(_fromMap).toList());
  }

  Stream<List<DoctorAppointment>> watchDoctorAppointments() {
    final session = FirebaseAuthRepository.instance.session;
    final organizationId = session.organizationId;
    final doctorId = session.doctorId;

    if (organizationId == null ||
        doctorId == null ||
        organizationId.isEmpty ||
        doctorId.isEmpty) {
      return Stream.error(
        StateError(
          'لا توجد هوية طبيب ومؤسسة مرتبطة بجلسة المستخدم.',
        ),
      );
    }

    return Stream.fromFuture(
      FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(
        organizationId,
        doctorId,
      ),
    ).asyncExpand((doctor) {
      final clinicId = doctor?.clinicId;
      if (doctor == null || clinicId == null || clinicId.trim().isEmpty) {
        return Stream.error(
          StateError('لا توجد عيادة نشطة مرتبطة بالطبيب الحالي.'),
        );
      }

      return FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('appointments')
          .where('organizationId', isEqualTo: organizationId)
          .where('doctorId', isEqualTo: doctorId)
          .where('clinicId', whereIn: [clinicId, null])
          .snapshots()
          .map(
            (snapshot) => _sortAppointments(
              snapshot.docs
                  .map(
                    (document) => _fromMap({
                      ...document.data(),
                      'id': document.id,
                    }),
                  )
                  .toList(),
            ),
          );
    });
  }

  DoctorAppointment _fromMap(Map<String, dynamic> appointment) {
    final rawDate = appointment['date'];

    return DoctorAppointment(
      id: _asString(appointment['id']),
      organizationId: _asString(appointment['organizationId']),
      doctorId: _asString(appointment['doctorId']),
      patientId: _asString(appointment['patientId']),
      clinicId: appointment['clinicId'] as String?,
      patientName: _asString(appointment['patientName']),
      patientInitials: _asString(appointment['patientInitials']),
      age: _asString(appointment['age']),
      gender: _asString(appointment['gender']),
      date: _formatDate(rawDate),
      time: _asString(appointment['time']),
      type: _asString(appointment['type']),
      status: _statusFromMap(
        appointment['status'],
        rawDate,
        appointment['time'],
      ),
      notes: _asString(appointment['notes']),
      avatarColor: Colors.transparent,
    );
  }

  String _asString(Object? value) {
    return value?.toString() ?? '';
  }

  String _formatDate(Object? date) {
    if (date is Timestamp) {
      return _formatDateTime(date.toDate());
    }

    if (date is DateTime) {
      return _formatDateTime(date);
    }

    if (date is String) {
      final parsed = _parseDate(date);
      return parsed == null ? date : _formatDateTime(parsed);
    }

    return '';
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  DoctorAppointmentFilter _statusFromMap(Object? value, Object? date, Object? time) {
    if (value == 'completed') {
      return DoctorAppointmentFilter.completed;
    }

    if (value == 'cancelled') {
      return DoctorAppointmentFilter.cancelled;
    }

    final appointmentDateTime = parseAppointmentDateTime(date, time);
    if (appointmentDateTime != null && appointmentDateTime.isBefore(DateTime.now())) {
      return DoctorAppointmentFilter.previous;
    }

    if (_isToday(date) || (value == 'today' && appointmentDateTime == null)) {
      return DoctorAppointmentFilter.today;
    }

    return DoctorAppointmentFilter.upcoming;
  }

  List<DoctorAppointment> _sortAppointments(List<DoctorAppointment> appointments) {
    appointments.sort((first, second) {
      final firstDate = parseAppointmentDateTime(first.date, first.time);
      final secondDate = parseAppointmentDateTime(second.date, second.time);
      if (firstDate == null) return secondDate == null ? 0 : 1;
      if (secondDate == null) return -1;
      if (first.status == DoctorAppointmentFilter.previous && second.status == DoctorAppointmentFilter.previous) {
        return secondDate.compareTo(firstDate);
      }
      return firstDate.compareTo(secondDate);
    });
    return appointments;
  }

  bool _isToday(Object? date) {
    final now = DateTime.now();

    if (date is Timestamp) {
      return _sameDate(date.toDate(), now);
    }

    if (date is DateTime) {
      return _sameDate(date, now);
    }

    if (date is String) {
      final normalizedDate = date.trim();

      if (normalizedDate == _todayLabel) {
        return true;
      }

      final parsedDate = _parseDate(normalizedDate);

      if (parsedDate != null) {
        return _sameDate(parsedDate, now);
      }
    }

    return false;
  }

  DateTime? _parseDate(String value) {
    final isoDate = DateTime.tryParse(value);

    if (isoDate != null) {
      return isoDate;
    }

    final parts = value.split('/');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime.tryParse(
          '$year-${month.toString().padLeft(2, '0')}-'
              '${day.toString().padLeft(2, '0')}',
        );
      }
    }

    return null;
  }

  bool _sameDate(
      DateTime first,
      DateTime second,
      ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String get _todayLabel {
    return switch (DateTime.now().weekday) {
      DateTime.saturday => 'السبت',
      DateTime.sunday => 'الأحد',
      DateTime.monday => 'الاثنين',
      DateTime.tuesday => 'الثلاثاء',
      DateTime.wednesday => 'الأربعاء',
      DateTime.thursday => 'الخميس',
      _ => 'الجمعة',
    };
  }
}