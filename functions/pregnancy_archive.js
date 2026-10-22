'use strict';

const dayMilliseconds = 24 * 60 * 60 * 1000;
const validDatingMethods = new Set([
  'lastMenstrualPeriod',
  'estimatedStartDate',
  'gestationalAgeAtReference',
]);
const validOutcomes = new Set([
  'liveBirth',
  'stillbirth',
  'miscarriage',
  'ectopicPregnancy',
  'other',
]);

function pregnancyArchiveDates(pregnancy) {
  if (pregnancy == null || typeof pregnancy !== 'object') return null;
  const { datingMethod, referenceDate } = pregnancy;
  const weeks = pregnancy.gestationalWeeksAtReference;
  const days = pregnancy.gestationalDaysAtReference;
  if (!validDatingMethods.has(datingMethod) ||
      referenceDate == null || typeof referenceDate.toDate !== 'function' ||
      !Number.isInteger(weeks) || !Number.isInteger(days) ||
      weeks < 0 || weeks > 42 || days < 0 || days > 6 ||
      weeks * 7 + days > 294) {
    return null;
  }
  if (datingMethod === 'gestationalAgeAtReference') {
    if (weeks * 7 + days === 0) return null;
  } else if (weeks !== 0 || days !== 0) {
    return null;
  }

  const reference = referenceDate.toDate();
  const referenceDay = Date.UTC(
    reference.getUTCFullYear(),
    reference.getUTCMonth(),
    reference.getUTCDate(),
  );
  const baselineDays = weeks * 7 + days;
  return {
    archiveAt: referenceDay + (294 - baselineDays) * dayMilliseconds,
    expectedDueDate: referenceDay + (280 - baselineDays) * dayMilliseconds,
  };
}

function isPregnancyArchiveDue(data, nowMillis) {
  if (data == null || data.type !== 'pregnancy' || data.status !== 'completed') {
    return false;
  }
  const pregnancy = data.pregnancy;
  if (!validOutcomes.has(pregnancy?.outcome) ||
      pregnancy.endedAt == null || typeof pregnancy.endedAt.toDate !== 'function' ||
      pregnancy.endedAt.toDate().getTime() > nowMillis) {
    return false;
  }
  const dates = pregnancyArchiveDates(pregnancy);
  return dates != null && dates.archiveAt <= nowMillis;
}

module.exports = { isPregnancyArchiveDue, pregnancyArchiveDates };