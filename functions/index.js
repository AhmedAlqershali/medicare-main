const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { initializeApp } = require('firebase-admin/app');
const { logger } = require('firebase-functions');
const { onSchedule } = require('firebase-functions/v2/scheduler');

initializeApp();
const db = getFirestore();
const pageSize = 250;
const workBatchSize = 25;
const dayMilliseconds = 24 * 60 * 60 * 1000;
const validDatingMethods = new Set([
  'lastMenstrualPeriod',
  'estimatedStartDate',
  'gestationalAgeAtReference',
]);

function pregnancyArchiveAt(pregnancy) {
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

async function archiveIfDue(reference, now) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return false;

    const data = snapshot.data();
    if (data.type !== 'pregnancy' ||
        !['active', 'monitoring', 'completed'].includes(data.status)) {
      return false;
    }

    const dates = pregnancyArchiveAt(data.pregnancy);
    if (dates == null || dates.archiveAt > now.toMillis()) return false;

    transaction.update(reference, {
      status: 'archived',
      completedAt: data.completedAt ?? FieldValue.serverTimestamp(),
      archivedAt: FieldValue.serverTimestamp(),
      archiveReason: 'pregnancy_period_elapsed',
      updatedAt: FieldValue.serverTimestamp(),
      'pregnancy.expectedDueDate': Timestamp.fromMillis(dates.expectedDueDate),
      'pregnancy.archiveAt': Timestamp.fromMillis(dates.archiveAt),
    });
    return true;
  });
}

exports.archiveEndedPregnancies = onSchedule({
  schedule: 'every day 01:15',
  timeZone: 'UTC',
  region: 'us-central1',
  timeoutSeconds: 540,
  memory: '512MiB',
  maxInstances: 1,
}, async () => {
  const now = Timestamp.now();
  const baseQuery = db.collectionGroup('medical_cases')
    .where('type', '==', 'pregnancy');
  let cursor = null;
  let scanned = 0;
  let archived = 0;

  while (true) {
    let query = baseQuery.limit(pageSize);
    if (cursor != null) query = baseQuery.startAfter(cursor).limit(pageSize);
    const page = await query.get();
    if (page.empty) break;

    for (let index = 0; index < page.docs.length; index += workBatchSize) {
      const work = page.docs.slice(index, index + workBatchSize);
      const results = await Promise.all(work.map(async (document) => {
        const path = document.ref.path.split('/');
        if (path.length !== 6 ||
            path[0] !== 'organizations' ||
            path[2] !== 'patients' ||
            path[4] !== 'medical_cases') {
          return false;
        }
        return archiveIfDue(document.ref, now);
      }));
      scanned += work.length;
      archived += results.filter(Boolean).length;
    }

    cursor = page.docs[page.docs.length - 1];
    if (page.size < pageSize) break;
  }

  logger.info('Pregnancy archive run completed', { scanned, archived });
});
