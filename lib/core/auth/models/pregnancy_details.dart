import 'package:cloud_firestore/cloud_firestore.dart';

enum PregnancyDatingMethod {
  lastMenstrualPeriod,
  estimatedStartDate,
  gestationalAgeAtReference,
}

class PregnancyDetails {
  const PregnancyDetails({
    required this.datingMethod,
    required this.referenceDate,
    required this.gestationalWeeksAtReference,
    required this.gestationalDaysAtReference,
    required this.expectedDueDate,
    required this.archiveAt,
    this.outcome,
    this.endedAt,
  });

  final PregnancyDatingMethod datingMethod;
  final DateTime referenceDate;
  final int gestationalWeeksAtReference;
  final int gestationalDaysAtReference;
  final DateTime expectedDueDate;
  final DateTime archiveAt;
  final String? outcome;
  final DateTime? endedAt;

  int get baselineGestationalDays =>
      gestationalWeeksAtReference * 7 + gestationalDaysAtReference;

  bool get monthIsApproximate =>
      datingMethod != PregnancyDatingMethod.lastMenstrualPeriod;

  factory PregnancyDetails.fromReference({
    required PregnancyDatingMethod datingMethod,
    required DateTime referenceDate,
    required int gestationalWeeks,
    required int gestationalDays,
    String? outcome,
    DateTime? endedAt,
  }) {
    final reference = _calendarDate(referenceDate);
    final baselineDays = gestationalWeeks * 7 + gestationalDays;
    return PregnancyDetails(
      datingMethod: datingMethod,
      referenceDate: reference,
      gestationalWeeksAtReference: gestationalWeeks,
      gestationalDaysAtReference: gestationalDays,
      expectedDueDate: reference.add(Duration(days: 280 - baselineDays)),
      archiveAt: reference.add(Duration(days: 294 - baselineDays)),
      outcome: outcome,
      endedAt: endedAt == null ? null : _calendarDate(endedAt),
    );
  }

  factory PregnancyDetails.fromMap(Map<String, dynamic> map) {
    final datingMethod = PregnancyDatingMethod.values.firstWhere(
      (value) => value.name == map['datingMethod'],
      orElse: () => PregnancyDatingMethod.estimatedStartDate,
    );
    return PregnancyDetails.fromReference(
      datingMethod: datingMethod,
      referenceDate: _readDate(map['referenceDate']),
      gestationalWeeks:
          (map['gestationalWeeksAtReference'] as num?)?.toInt() ?? 0,
      gestationalDays:
          (map['gestationalDaysAtReference'] as num?)?.toInt() ?? 0,
        outcome: map['outcome'] as String?,
        endedAt: map['endedAt'] == null ? null : _readDate(map['endedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'datingMethod': datingMethod.name,
        'referenceDate': Timestamp.fromDate(_calendarDate(referenceDate)),
        'gestationalWeeksAtReference': gestationalWeeksAtReference,
        'gestationalDaysAtReference': gestationalDaysAtReference,
        'expectedDueDate': Timestamp.fromDate(_calendarDate(expectedDueDate)),
        'archiveAt': Timestamp.fromDate(_calendarDate(archiveAt)),
        if (outcome != null) 'outcome': outcome,
        if (endedAt != null) 'endedAt': Timestamp.fromDate(_calendarDate(endedAt!)),
      };

  PregnancyProgress progressAt(DateTime date) {
    final today = _calendarDate(date);
    final reference = _calendarDate(referenceDate);
    final elapsedDays = today.difference(reference).inDays;
    final totalDays = baselineGestationalDays + elapsedDays;
    final safeDays = totalDays < 0 ? 0 : totalDays;
    final estimatedStart = reference.subtract(
      Duration(days: baselineGestationalDays),
    );

    var elapsedMonths = (today.year - estimatedStart.year) * 12 +
        today.month -
        estimatedStart.month;
    if (today.day < estimatedStart.day) elapsedMonths--;

    return PregnancyProgress(
      weeks: safeDays ~/ 7,
      days: safeDays % 7,
      calendarMonth: (elapsedMonths + 1).clamp(1, 12).toInt(),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return _calendarDate(value.toDate().toUtc());
    if (value is DateTime) return _calendarDate(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return _calendarDate(parsed);
    }
    throw const FormatException('تاريخ تأريخ الحمل غير صالح أو مفقود.');
  }

  static DateTime _calendarDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

class PregnancyProgress {
  const PregnancyProgress({
    required this.weeks,
    required this.days,
    required this.calendarMonth,
  });

  final int weeks;
  final int days;
  final int calendarMonth;

  int get monthsUntilNinthMonth => (9 - calendarMonth).clamp(0, 8).toInt();
}