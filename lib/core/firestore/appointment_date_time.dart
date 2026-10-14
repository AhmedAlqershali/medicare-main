import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseAppointmentDateTime(Object? rawDate, [Object? rawTime]) {
  DateTime? date;
  if (rawDate is Timestamp) date = rawDate.toDate();
  if (rawDate is DateTime) date = rawDate;
  if (date != null && (date.hour != 0 || date.minute != 0 || date.second != 0)) {
    return date;
  }
  if (rawDate is String) {
    final value = rawDate.trim();
    date = DateTime.tryParse(value);
    if (date == null) {
      final parts = value.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          date = DateTime(year, month, day);
        }
      }
    }
    if (date != null && RegExp(r'T\d').hasMatch(value)) return date;
  }
  if (date == null) return null;

  final time = rawTime?.toString().trim() ?? '';
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([صم]|AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(time);
  if (match == null) return DateTime(date.year, date.month, date.day);

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)?.toUpperCase();
  if (period == 'م' || period == 'PM') {
    if (hour < 12) hour += 12;
  } else if (period == 'ص' || period == 'AM') {
    if (hour == 12) hour = 0;
  }
  if (hour > 23 || minute > 59) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}