'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  isPregnancyArchiveDue,
  pregnancyArchiveDates,
} = require('../pregnancy_archive');

const timestamp = (milliseconds) => ({ toDate: () => new Date(milliseconds) });

function pregnancyData(overrides = {}) {
  const reference = Date.UTC(2026, 0, 1);
  return {
    type: 'pregnancy',
    status: 'completed',
    pregnancy: {
      datingMethod: 'lastMenstrualPeriod',
      referenceDate: timestamp(reference),
      gestationalWeeksAtReference: 0,
      gestationalDaysAtReference: 0,
      outcome: 'liveBirth',
      endedAt: timestamp(reference + 280 * 24 * 60 * 60 * 1000),
      ...overrides,
    },
  };
}

test('does not archive at or after week 42 without an explicit outcome', () => {
  const data = pregnancyData({ outcome: undefined, endedAt: undefined });
  const { archiveAt } = pregnancyArchiveDates(data.pregnancy);

  assert.equal(isPregnancyArchiveDue(data, archiveAt), false);
});

test('archives an ended pregnancy only after the configured archive date', () => {
  const data = pregnancyData();
  const { archiveAt } = pregnancyArchiveDates(data.pregnancy);

  assert.equal(isPregnancyArchiveDue(data, archiveAt - 1), false);
  assert.equal(isPregnancyArchiveDue(data, archiveAt), true);
});

test('does not archive an uncompleted, already archived, or future-ended pregnancy', () => {
  const data = pregnancyData();
  const { archiveAt } = pregnancyArchiveDates(data.pregnancy);

  assert.equal(isPregnancyArchiveDue({ ...data, status: 'monitoring' }, archiveAt), false);
  assert.equal(isPregnancyArchiveDue({ ...data, status: 'archived' }, archiveAt), false);
  assert.equal(isPregnancyArchiveDue({
    ...data,
    pregnancy: { ...data.pregnancy, endedAt: timestamp(archiveAt + 1) },
  }, archiveAt), false);
});