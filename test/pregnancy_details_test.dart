import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/core/auth/models/pregnancy_details.dart';

void main() {
  test('progress reaches month nine from the recorded calendar reference', () {
    final pregnancy = PregnancyDetails.fromReference(
      datingMethod: PregnancyDatingMethod.lastMenstrualPeriod,
      referenceDate: DateTime.utc(2026, 1, 15),
      gestationalWeeks: 0,
      gestationalDays: 0,
    );

    final eighthMonth = pregnancy.progressAt(DateTime.utc(2026, 9, 14));
    final ninthMonth = pregnancy.progressAt(DateTime.utc(2026, 9, 15));

    expect(eighthMonth.calendarMonth, 8);
    expect(eighthMonth.isApproachingNinthMonth, isTrue);
    expect(eighthMonth.isInNinthMonth, isFalse);
    expect(eighthMonth.monthsUntilNinthMonth, 1);
    expect(ninthMonth.calendarMonth, 9);
    expect(ninthMonth.isApproachingNinthMonth, isFalse);
    expect(ninthMonth.isInNinthMonth, isTrue);
    expect(ninthMonth.monthsUntilNinthMonth, 0);
    expect(pregnancy.expectedDueDate, DateTime.utc(2026, 10, 22));
  });

  test('gestational age rolls forward by calendar day and week', () {
    final pregnancy = PregnancyDetails.fromReference(
      datingMethod: PregnancyDatingMethod.gestationalAgeAtReference,
      referenceDate: DateTime.utc(2026, 10, 21),
      gestationalWeeks: 7,
      gestationalDays: 6,
    );

    final progress = pregnancy.progressAt(DateTime.utc(2026, 10, 22));

    expect(progress.weeks, 8);
    expect(progress.days, 0);
  });

  test('Firestore date-only timestamps retain their UTC calendar day', () {
    final pregnancy = PregnancyDetails.fromMap({
      'datingMethod': 'lastMenstrualPeriod',
      'referenceDate': Timestamp.fromDate(DateTime.utc(2026, 1, 31)),
      'gestationalWeeksAtReference': 0,
      'gestationalDaysAtReference': 0,
    });

    expect(pregnancy.referenceDate, DateTime.utc(2026, 1, 31));
    expect(pregnancy.progressAt(DateTime.utc(2026, 3, 1)).calendarMonth, 2);
  });

  test('pregnancy outcome and end date survive serialization', () {
    final pregnancy = PregnancyDetails.fromReference(
      datingMethod: PregnancyDatingMethod.estimatedStartDate,
      referenceDate: DateTime.utc(2026, 1, 1),
      gestationalWeeks: 0,
      gestationalDays: 0,
      outcome: 'liveBirth',
      endedAt: DateTime.utc(2026, 10, 1),
    );
    final restored = PregnancyDetails.fromMap(pregnancy.toMap());

    expect(restored.outcome, 'liveBirth');
    expect(restored.endedAt, DateTime.utc(2026, 10, 1));
  });
}