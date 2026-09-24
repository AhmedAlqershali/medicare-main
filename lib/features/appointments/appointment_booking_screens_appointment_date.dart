part of 'appointment_booking_screens.dart';

class AppointmentDate {
  const AppointmentDate({required this.day, required this.number, required this.month, required this.label});
  final String day;
  final String number;
  final String month;
  final String label;

  factory AppointmentDate.fromFirebase(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) return AppointmentDate(day: parts[0], number: parts[1], month: parts.sublist(2).join(' '), label: value);
    return AppointmentDate(day: value, number: '', month: '', label: value);
  }
}
