import 'package:flutter/material.dart';

import '../../../../core/auth/services/firebase_auth_repository.dart';
import '../../../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../domain/repositories/doctor_appointments_repository.dart';
import '../../models/doctor_appointment.dart';

class DoctorAppointmentsRepositoryImpl implements DoctorAppointmentsRepository {
  const DoctorAppointmentsRepositoryImpl();

  @override
  Future<List<DoctorAppointment>> getDoctorAppointments() async {
    final session = FirebaseAuthRepository.instance.session;
    final organizationId = session.organizationId;
    final doctorId = session.doctorId;
    if (organizationId == null || doctorId == null || organizationId.isEmpty || doctorId.isEmpty) throw StateError('لا توجد هوية طبيب ومؤسسة مرتبطة بجلسة المستخدم.');
    final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: organizationId, doctorId: doctorId);
    return appointments.map(_fromMap).toList();
  }

  DoctorAppointment _fromMap(Map<String, dynamic> appointment) => DoctorAppointment(
      id: appointment['id'] as String? ?? '',
        organizationId: appointment['organizationId'] as String? ?? '',
        doctorId: appointment['doctorId'] as String? ?? '',
        patientId: appointment['patientId'] as String? ?? '',
        clinicId: appointment['clinicId'] as String?,
        patientName: appointment['patientName'] as String? ?? '',
        patientInitials: appointment['patientInitials'] as String? ?? '',
        age: appointment['age'] as String? ?? '',
        gender: appointment['gender'] as String? ?? '',
        date: appointment['date'] as String? ?? '',
        time: appointment['time'] as String? ?? '',
        type: appointment['type'] as String? ?? '',
        status: _statusFromMap(appointment['status'], appointment['date']),
        notes: appointment['notes'] as String? ?? '',
        avatarColor: Colors.transparent,
      );

  DoctorAppointmentFilter _statusFromMap(Object? value, Object? date) {
    if (value == 'completed') return DoctorAppointmentFilter.completed;
    if (value == 'cancelled') return DoctorAppointmentFilter.cancelled;
    final parsedDate = date is String ? DateTime.tryParse(date) : null;
    if (value == 'today' || date == _todayLabel || (parsedDate != null && _sameDate(parsedDate, DateTime.now()))) return DoctorAppointmentFilter.today;
    return DoctorAppointmentFilter.upcoming;
  }

  bool _sameDate(DateTime first, DateTime second) => first.year == second.year && first.month == second.month && first.day == second.day;

  String get _todayLabel => switch (DateTime.now().weekday) {
        DateTime.saturday => 'السبت',
        DateTime.sunday => 'الأحد',
        DateTime.monday => 'الاثنين',
        DateTime.tuesday => 'الثلاثاء',
        DateTime.wednesday => 'الأربعاء',
        DateTime.thursday => 'الخميس',
        _ => 'الجمعة',
      };
}
